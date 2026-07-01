import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:the_woodlands_series/components/resource/app_colors.dart';
import 'package:the_woodlands_series/components/resource/app_textstyle.dart';
import 'package:the_woodlands_series/components/button/primary_button.dart';
import 'package:the_woodlands_series/bloc/auth/auth_bloc.dart';
import 'package:the_woodlands_series/bloc/auth/auth_state.dart';
import 'package:the_woodlands_series/services/leaderboard_service.dart';

enum WordSearchDifficulty { easy, medium, hard }

class WordSearchPlacement {
  final String word;
  final List<Point<int>> cells;

  WordSearchPlacement(this.word, this.cells);
}

enum WordDirection {
  horizontal,
  vertical,
  diagonalDownRight,
  diagonalUpRight,
  horizontalBackwards,
  verticalBackwards,
  diagonalDownRightBackwards,
  diagonalUpRightBackwards
}

class WordSearchScreen extends StatefulWidget {
  final String gameTitle;

  const WordSearchScreen({
    super.key,
    required this.gameTitle,
  });

  @override
  State<WordSearchScreen> createState() => _WordSearchScreenState();
}

class _WordSearchScreenState extends State<WordSearchScreen> {
  WordSearchDifficulty _difficulty = WordSearchDifficulty.easy;
  int _gridSize = 6;
  List<List<String>> _grid = [];
  List<String> _targetWords = [];
  List<WordSearchPlacement> _placements = [];
  
  final Set<String> _foundWords = {};
  final Set<Point<int>> _foundCells = {};
  
  Point<int>? _dragStartCell;
  List<Point<int>> _currentDragPath = [];
  
  int _score = 0;
  int _highScore = 0;
  int _consecutiveMatches = 0;
  bool _isVictory = false;
  bool _isGameOver = false;

  Timer? _timer;
  int _timeLeft = 0;
  int _totalTimeLimit = 0;

  final Random _random = Random();

  // Woodland theme vocabulary list
  final List<String> _vocabularyPool = [
    'BIRCH',
    'DRAKE',
    'LEAVITT',
    'SQUIRREL',
    'IVY',
    'LILLY',
    'DUCKLING',
    'SCAMPER',
    'FOREST',
    'WOODLAND',
    'ACORN',
    'LEAF',
  ];

  @override
  void initState() {
    super.initState();
    _loadHighScore().then((_) {
      _setupGame();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadHighScore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _highScore = prefs.getInt('word_search_high_score_${_difficulty.name}') ?? 0;
      });
    } catch (e) {
      debugPrint('Error loading high score: $e');
    }
  }

  Future<void> _saveHighScore() async {
    if (_score > _highScore) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('word_search_high_score_${_difficulty.name}', _score);
        setState(() {
          _highScore = _score;
        });
      } catch (e) {
        debugPrint('Error saving high score: $e');
      }
    }
  }

  void _submitScoreToLeaderboard() {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      final user = authState.user;
      LeaderboardService.addScore(
        user.id,
        user.name,
        user.profileImageUrl,
        _score,
      ).catchError((e) {
        debugPrint('Error updating leaderboard: $e');
      });
    }
  }

  void _setupGame() {
    int wordCount;
    int gridDimension;
    int timeLimit;

    switch (_difficulty) {
      case WordSearchDifficulty.easy:
        wordCount = 4;
        gridDimension = 6;
        timeLimit = 90;
        break;
      case WordSearchDifficulty.medium:
        wordCount = 6;
        gridDimension = 8;
        timeLimit = 75;
        break;
      case WordSearchDifficulty.hard:
        wordCount = 8;
        gridDimension = 10;
        timeLimit = 60;
        break;
    }

    // Pick random subset of words from vocabulary pool
    List<String> pool = List.from(_vocabularyPool)..shuffle();
    // Filter words that are longer than the grid dimension
    List<String> validWords = pool.where((word) => word.length <= gridDimension).toList();
    _targetWords = validWords.take(wordCount).toList();

    setState(() {
      _gridSize = gridDimension;
      _foundWords.clear();
      _foundCells.clear();
      _currentDragPath.clear();
      _dragStartCell = null;
      _score = 0;
      _consecutiveMatches = 0;
      _isVictory = false;
      _isGameOver = false;
      _timeLeft = timeLimit;
      _totalTimeLimit = timeLimit;
    });

    _generateGrid();
    _startTimer();
  }

  List<WordDirection> _getAllowedDirections() {
    switch (_difficulty) {
      case WordSearchDifficulty.easy:
        return [
          WordDirection.horizontal,
          WordDirection.vertical,
        ];
      case WordSearchDifficulty.medium:
        return [
          WordDirection.horizontal,
          WordDirection.vertical,
          WordDirection.diagonalDownRight,
        ];
      case WordSearchDifficulty.hard:
        return WordDirection.values;
    }
  }

  void _generateGrid() {
    // Try up to 15 times to generate a complete board
    for (int attempt = 0; attempt < 15; attempt++) {
      List<List<String>> tempGrid = List.generate(
        _gridSize,
        (_) => List.generate(_gridSize, (_) => ' '),
      );
      List<WordSearchPlacement> placements = [];
      bool success = true;

      for (String word in _targetWords) {
        bool wordPlaced = false;
        List<WordDirection> allowedDirs = _getAllowedDirections();
        allowedDirs.shuffle();

        for (int tryPlace = 0; tryPlace < 100; tryPlace++) {
          WordDirection dir = allowedDirs[tryPlace % allowedDirs.length];
          int startRow = _random.nextInt(_gridSize);
          int startCol = _random.nextInt(_gridSize);

          int dRow = 0;
          int dCol = 0;

          switch (dir) {
            case WordDirection.horizontal:
              dRow = 0; dCol = 1; break;
            case WordDirection.vertical:
              dRow = 1; dCol = 0; break;
            case WordDirection.diagonalDownRight:
              dRow = 1; dCol = 1; break;
            case WordDirection.diagonalUpRight:
              dRow = -1; dCol = 1; break;
            case WordDirection.horizontalBackwards:
              dRow = 0; dCol = -1; break;
            case WordDirection.verticalBackwards:
              dRow = -1; dCol = 0; break;
            case WordDirection.diagonalDownRightBackwards:
              dRow = -1; dCol = -1; break;
            case WordDirection.diagonalUpRightBackwards:
              dRow = 1; dCol = -1; break;
          }

          int endRow = startRow + dRow * (word.length - 1);
          int endCol = startCol + dCol * (word.length - 1);

          if (endRow < 0 || endRow >= _gridSize || endCol < 0 || endCol >= _gridSize) {
            continue;
          }

          // Check cell compatibility
          bool compatible = true;
          List<Point<int>> cells = [];
          for (int i = 0; i < word.length; i++) {
            int r = startRow + dRow * i;
            int c = startCol + dCol * i;
            String char = word[i];
            if (tempGrid[r][c] != ' ' && tempGrid[r][c] != char) {
              compatible = false;
              break;
            }
            cells.add(Point(r, c));
          }

          if (compatible) {
            for (int i = 0; i < word.length; i++) {
              tempGrid[cells[i].x][cells[i].y] = word[i];
            }
            placements.add(WordSearchPlacement(word, cells));
            wordPlaced = true;
            break;
          }
        }

        if (!wordPlaced) {
          success = false;
          break; // retry the whole grid
        }
      }

      if (success) {
        // Fill remaining empty slots with random uppercase letters
        const letters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
        for (int r = 0; r < _gridSize; r++) {
          for (int c = 0; c < _gridSize; c++) {
            if (tempGrid[r][c] == ' ') {
              tempGrid[r][c] = letters[_random.nextInt(letters.length)];
            }
          }
        }
        setState(() {
          _grid = tempGrid;
          _placements = placements;
        });
        return;
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        if (_isVictory || _isGameOver) {
          _timer?.cancel();
          return;
        }

        setState(() {
          if (_timeLeft > 0) {
            _timeLeft--;
          } else {
            _isGameOver = true;
            _timer?.cancel();
          }
        });
      }
    });
  }

  void _handleDragStart(Offset localPos, double gridWidth) {
    if (_isVictory || _isGameOver) return;

    final cellSize = gridWidth / _gridSize;
    final col = (localPos.dx / cellSize).floor();
    final row = (localPos.dy / cellSize).floor();

    if (row >= 0 && row < _gridSize && col >= 0 && col < _gridSize) {
      setState(() {
        _dragStartCell = Point(row, col);
        _currentDragPath = [Point(row, col)];
      });
    }
  }

  void _handleDragUpdate(Offset localPos, double gridWidth) {
    if (_dragStartCell == null || _isVictory || _isGameOver) return;

    final cellSize = gridWidth / _gridSize;
    final col = (localPos.dx / cellSize).floor();
    final row = (localPos.dy / cellSize).floor();

    if (row >= 0 && row < _gridSize && col >= 0 && col < _gridSize) {
      final currentCell = Point(row, col);
      if (currentCell != _currentDragPath.last) {
        final start = _dragStartCell!;
        final dRow = row - start.x;
        final dCol = col - start.y;

        // Check if path is horizontal, vertical, or diagonal
        if (dRow == 0 || dCol == 0 || dRow.abs() == dCol.abs()) {
          final List<Point<int>> newPath = [];
          final steps = max(dRow.abs(), dCol.abs());
          final stepRow = dRow == 0 ? 0 : dRow ~/ dRow.abs();
          final stepCol = dCol == 0 ? 0 : dCol ~/ dCol.abs();

          for (int i = 0; i <= steps; i++) {
            newPath.add(Point(start.x + stepRow * i, start.y + stepCol * i));
          }

          setState(() {
            _currentDragPath = newPath;
          });
        }
      }
    }
  }

  void _handleDragEnd() {
    if (_currentDragPath.isEmpty || _isVictory || _isGameOver) return;

    // Check if the current drag path matches any placements
    WordSearchPlacement? matchedPlacement;
    for (var placement in _placements) {
      if (_foundWords.contains(placement.word)) continue;

      // Check forward match
      bool forwardMatch = true;
      if (placement.cells.length == _currentDragPath.length) {
        for (int i = 0; i < placement.cells.length; i++) {
          if (placement.cells[i] != _currentDragPath[i]) {
            forwardMatch = false;
            break;
          }
        }
      } else {
        forwardMatch = false;
      }

      // Check backward match
      bool backwardMatch = true;
      if (placement.cells.length == _currentDragPath.length) {
        for (int i = 0; i < placement.cells.length; i++) {
          if (placement.cells[i] != _currentDragPath[_currentDragPath.length - 1 - i]) {
            backwardMatch = false;
            break;
          }
        }
      } else {
        backwardMatch = false;
      }

      if (forwardMatch || backwardMatch) {
        matchedPlacement = placement;
        break;
      }
    }

    if (matchedPlacement != null) {
      setState(() {
        _foundWords.add(matchedPlacement!.word);
        _foundCells.addAll(matchedPlacement.cells);
        _consecutiveMatches++;
        final pointsGained = 150 * _consecutiveMatches;
        final speedBonus = (_timeLeft > _totalTimeLimit / 2) ? 50 : 0;
        _score += (pointsGained + speedBonus);

        if (_foundWords.length == _targetWords.length) {
          _isVictory = true;
          _timer?.cancel();
          _saveHighScore();
          _submitScoreToLeaderboard();
        }
      });
    } else {
      setState(() {
        _consecutiveMatches = 0;
        if (_score >= 10) {
          _score -= 10;
        }
      });
    }

    setState(() {
      _currentDragPath.clear();
      _dragStartCell = null;
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F1E15),
              Color(0xFF070B08),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(context),

              // Difficulty Selector
              _buildDifficultySelector(),

              16.verticalSpace,

              // Stats Display Bar
              _buildStatsBar(),

              20.verticalSpace,

              // The Word Search Grid
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: _buildGameBoard(),
                ),
              ),

              20.verticalSpace,

              // Reset / Restart Button
              Padding(
                padding: EdgeInsets.only(bottom: 24.h),
                child: PrimaryButton(
                  buttonWidth: 200.w,
                  title: 'Reset Game',
                  onTap: _setupGame,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Text(
              widget.gameTitle,
              style: AppTextStyles.lufgaLarge.copyWith(
                color: Colors.white,
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            'High Score: $_highScore',
            style: AppTextStyles.medium.copyWith(
              color: AppColors.primaryColor,
              fontSize: 14.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultySelector() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: WordSearchDifficulty.values.map((diff) {
          final isSelected = _difficulty == diff;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (_difficulty != diff) {
                  setState(() {
                    _difficulty = diff;
                  });
                  _loadHighScore().then((_) => _setupGame());
                }
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 10.h),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Center(
                  child: Text(
                    diff.name.toUpperCase(),
                    style: AppTextStyles.medium.copyWith(
                      color: isSelected ? Colors.black : Colors.white.withOpacity(0.6),
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatsBar() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            Icons.timer_outlined, 
            _formatTime(_timeLeft), 
            'Time Left',
            valueColor: _timeLeft <= 10 ? Colors.redAccent : Colors.white,
          ),
          _buildStatItem(
            Icons.checklist_outlined, 
            '${_targetWords.length - _foundWords.length}', 
            'Words Left'
          ),
          _buildStatItem(Icons.stars_outlined, '$_score', 'Score'),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label, {Color? valueColor}) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primaryColor, size: 18.sp),
            6.horizontalSpace,
            Text(
              value,
              style: AppTextStyles.lufgaMedium.copyWith(
                color: valueColor ?? Colors.white,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        4.verticalSpace,
        Text(
          label,
          style: AppTextStyles.regular.copyWith(
            color: Colors.white.withOpacity(0.5),
            fontSize: 11.sp,
          ),
        ),
      ],
    );
  }

  Widget _buildGameBoard() {
    if (_isVictory) {
      return _buildVictoryScreen();
    }
    if (_isGameOver) {
      return _buildDefeatScreen();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth;
        return Column(
          children: [
            // The Grid
            GestureDetector(
              onPanStart: (details) => _handleDragStart(details.localPosition, size),
              onPanUpdate: (details) => _handleDragUpdate(details.localPosition, size),
              onPanEnd: (_) => _handleDragEnd(),
              child: Container(
                width: size,
                height: size,
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.02),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _gridSize,
                    crossAxisSpacing: 4.w,
                    mainAxisSpacing: 4.h,
                  ),
                  itemCount: _gridSize * _gridSize,
                  itemBuilder: (context, index) {
                    final r = index ~/ _gridSize;
                    final c = index % _gridSize;
                    final cellPoint = Point(r, c);

                    final isSelected = _currentDragPath.contains(cellPoint);
                    final isFound = _foundCells.contains(cellPoint);

                    Color cellBg = Colors.white.withOpacity(0.05);
                    Color borderCol = Colors.white.withOpacity(0.1);
                    if (isSelected) {
                      cellBg = AppColors.primaryColor.withOpacity(0.4);
                      borderCol = AppColors.primaryColor;
                    } else if (isFound) {
                      cellBg = Colors.amber.withOpacity(0.25);
                      borderCol = Colors.amber;
                    }

                    // Dynamically size font based on grid size
                    double letterSize = 18.sp;
                    if (_gridSize == 8) {
                      letterSize = 15.sp;
                    } else if (_gridSize == 10) {
                      letterSize = 13.sp;
                    }

                    return Container(
                      decoration: BoxDecoration(
                        color: cellBg,
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: borderCol, width: (isSelected || isFound) ? 1.5 : 1),
                      ),
                      child: Center(
                        child: Text(
                          _grid.isNotEmpty ? _grid[r][c] : '',
                          style: AppTextStyles.lufgaMedium.copyWith(
                            color: Colors.white,
                            fontSize: letterSize,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            16.verticalSpace,

            // Words List checklist
            Expanded(
              child: Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.02),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Wrap(
                    spacing: 10.w,
                    runSpacing: 8.h,
                    children: _targetWords.map((word) {
                      final found = _foundWords.contains(word);
                      return Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: found ? Colors.green.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(
                            color: found ? Colors.green.withOpacity(0.4) : Colors.white.withOpacity(0.1),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              word,
                              style: AppTextStyles.medium.copyWith(
                                color: found ? Colors.white.withOpacity(0.5) : Colors.white,
                                fontSize: 13.sp,
                                decoration: found ? TextDecoration.lineThrough : null,
                              ),
                            ),
                            if (found) ...[
                              6.horizontalSpace,
                              Icon(Icons.check, color: Colors.green, size: 14.sp),
                            ]
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildVictoryScreen() {
    final isNewHighScore = _score > _highScore;

    return Center(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 30,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_events_outlined, color: Colors.amber, size: 72.sp),
            16.verticalSpace,
            Text(
              'VICTORY!',
              style: AppTextStyles.lufgaLarge.copyWith(
                color: Colors.white,
                fontSize: 26.sp,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            8.verticalSpace,
            Text(
              isNewHighScore 
                  ? '🎉 New High Score Set!' 
                  : 'You found all the hidden words!',
              style: AppTextStyles.medium.copyWith(
                color: AppColors.primaryColor,
                fontSize: 14.sp,
              ),
            ),
            24.verticalSpace,
            
            // Victory Details Card
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Column(
                children: [
                  _buildVictoryStatRow('Difficulty', _difficulty.name.toUpperCase()),
                  const Divider(color: Colors.white24),
                  _buildVictoryStatRow('Score Obtained', '$_score'),
                  const Divider(color: Colors.white24),
                  _buildVictoryStatRow('Time Taken', _formatTime(_totalTimeLimit - _timeLeft)),
                  const Divider(color: Colors.white24),
                  _buildVictoryStatRow('Words Found', '${_foundWords.length}/${_targetWords.length}'),
                ],
              ),
            ),
            
            28.verticalSpace,
            PrimaryButton(
              buttonWidth: 180.w,
              title: 'Play Again',
              onTap: _setupGame,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefeatScreen() {
    return Center(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 30,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.hourglass_empty_rounded, color: Colors.redAccent, size: 72.sp),
            16.verticalSpace,
            Text(
              'GAME OVER',
              style: AppTextStyles.lufgaLarge.copyWith(
                color: Colors.white,
                fontSize: 26.sp,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            8.verticalSpace,
            Text(
              'Time ran out! Keep practicing!',
              style: AppTextStyles.medium.copyWith(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14.sp,
              ),
              textAlign: TextAlign.center,
            ),
            24.verticalSpace,
            
            // Defeat Details Card
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Column(
                children: [
                  _buildVictoryStatRow('Difficulty', _difficulty.name.toUpperCase()),
                  const Divider(color: Colors.white24),
                  _buildVictoryStatRow('Final Score', '$_score'),
                  const Divider(color: Colors.white24),
                  _buildVictoryStatRow('Words Found', '${_foundWords.length}/${_targetWords.length}'),
                ],
              ),
            ),
            
            28.verticalSpace,
            PrimaryButton(
              buttonWidth: 180.w,
              title: 'Try Again',
              onTap: _setupGame,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVictoryStatRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.regular.copyWith(
              color: Colors.white.withOpacity(0.6),
              fontSize: 14.sp,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.lufgaMedium.copyWith(
              color: Colors.white,
              fontSize: 15.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
