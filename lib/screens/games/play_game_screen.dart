import 'dart:async';
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

enum GameDifficulty { easy, medium, hard }

class MemoryCard {
  final int id;
  final IconData icon;
  final Color color;
  bool isFaceUp;
  bool isMatched;

  MemoryCard({
    required this.id,
    required this.icon,
    required this.color,
    this.isFaceUp = false,
    this.isMatched = false,
  });
}

class PlayGameScreen extends StatefulWidget {
  final String gameUrl;
  final String gameTitle;

  const PlayGameScreen({
    super.key,
    required this.gameUrl,
    required this.gameTitle,
  });

  @override
  State<PlayGameScreen> createState() => _PlayGameScreenState();
}

class _PlayGameScreenState extends State<PlayGameScreen> {
  GameDifficulty _difficulty = GameDifficulty.easy;
  List<MemoryCard> _cards = [];
  List<int> _selectedCardIndices = [];
  bool _isChecking = false;
  bool _isVictory = false;
  bool _isGameOver = false;
  int _moves = 0;
  int _score = 0;
  int _highScore = 0;
  int _consecutiveMatches = 0;
  int _cols = 3;

  Timer? _timer;
  int _timeLeft = 0;
  int _totalTimeLimit = 0;

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
        _highScore = prefs.getInt('memory_game_high_score_${_difficulty.name}') ?? 0;
      });
    } catch (e) {
      debugPrint('Error loading high score: $e');
    }
  }

  Future<void> _saveHighScore() async {
    if (_score > _highScore) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('memory_game_high_score_${_difficulty.name}', _score);
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
    int pairsCount;
    int gridCols;
    int timeLimit;
    switch (_difficulty) {
      case GameDifficulty.easy:
        pairsCount = 6;
        gridCols = 3;
        timeLimit = 90; // generous time (1:30)
        break;
      case GameDifficulty.medium:
        pairsCount = 8;
        gridCols = 4;
        timeLimit = 60; // normal time (1:00)
        break;
      case GameDifficulty.hard:
        pairsCount = 10;
        gridCols = 4;
        timeLimit = 40; // challenging time (0:40)
        break;
    }

    // Curated premium icons matching a Woodland theme
    final availableIcons = [
      Icons.pets,            // Animals
      Icons.park,            // Trees
      Icons.flutter_dash,    // Birds
      Icons.eco,             // Leaves
      Icons.star,            // Night Sky
      Icons.bug_report,      // Forest Bugs
      Icons.wb_sunny,        // Sunrise
      Icons.water_drop,      // Morning Dew
      Icons.terrain,         // Hills/Mountains
      Icons.local_florist,   // Flowers
    ];

    final availableColors = [
      Colors.orangeAccent,
      Colors.greenAccent,
      Colors.lightBlueAccent,
      Colors.pinkAccent,
      Colors.amberAccent,
      Colors.redAccent,
      Colors.purpleAccent,
      Colors.tealAccent,
      Colors.cyanAccent,
      Colors.indigoAccent,
    ];

    List<MemoryCard> newCards = [];
    for (int i = 0; i < pairsCount; i++) {
      final icon = availableIcons[i];
      final color = availableColors[i];
      
      newCards.add(MemoryCard(id: i * 2, icon: icon, color: color));
      newCards.add(MemoryCard(id: i * 2 + 1, icon: icon, color: color));
    }

    newCards.shuffle();

    setState(() {
      _cards = newCards;
      _cols = gridCols;
      _moves = 0;
      _score = 0;
      _consecutiveMatches = 0;
      _selectedCardIndices.clear();
      _isChecking = false;
      _isVictory = false;
      _isGameOver = false;
      _timeLeft = timeLimit;
      _totalTimeLimit = timeLimit;
    });

    _startTimer();
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

  void _onCardTap(int index) {
    if (_isChecking || _isGameOver || _cards[index].isFaceUp || _cards[index].isMatched) return;

    setState(() {
      _cards[index].isFaceUp = true;
      _selectedCardIndices.add(index);
    });

    if (_selectedCardIndices.length == 2) {
      _isChecking = true;
      _moves++;

      final card1 = _cards[_selectedCardIndices[0]];
      final card2 = _cards[_selectedCardIndices[1]];

      if (card1.icon == card2.icon) {
        // Match found!
        _consecutiveMatches++;
        final pointsGained = 100 * _consecutiveMatches;
        
        // Bonus for fast matching (more than 50% time remaining)
        final speedBonus = (_timeLeft > _totalTimeLimit / 2) ? 50 : 0;
        
        setState(() {
          _score += (pointsGained + speedBonus);
        });

        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() {
              card1.isMatched = true;
              card2.isMatched = true;
              _selectedCardIndices.clear();
              _isChecking = false;

              if (_cards.every((card) => card.isMatched)) {
                _isVictory = true;
                _timer?.cancel();
                _saveHighScore();
                _submitScoreToLeaderboard();
              }
            });
          }
        });
      } else {
        // No match
        _consecutiveMatches = 0;
        if (_score >= 10) {
          setState(() {
            _score -= 10;
          });
        }

        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted) {
            setState(() {
              card1.isFaceUp = false;
              card2.isFaceUp = false;
              _selectedCardIndices.clear();
              _isChecking = false;
            });
          }
        });
      }
    }
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
              // Header & Back button
              _buildHeader(context),
              
              // Difficulty tabs selector
              _buildDifficultySelector(),

              16.verticalSpace,

              // Stats Display Bar
              _buildStatsBar(),

              20.verticalSpace,

              // The Memory Grid
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: _buildGrid(),
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
              'Mind Game',
              style: AppTextStyles.lufgaLarge.copyWith(
                color: Colors.white,
                fontSize: 22.sp,
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
        children: GameDifficulty.values.map((diff) {
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
          _buildStatItem(Icons.touch_app_outlined, '$_moves', 'Moves'),
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

  Widget _buildGrid() {
    if (_isVictory) {
      return _buildVictoryScreen();
    }
    if (_isGameOver) {
      return _buildDefeatScreen();
    }

    final rows = (_cards.length / _cols).ceil();

    return LayoutBuilder(
      builder: (context, constraints) {
        final gridWidth = constraints.maxWidth;
        final gridHeight = constraints.maxHeight;

        final hSpacing = 12.w * (_cols - 1);
        final vSpacing = 12.h * (rows - 1);

        final cardWidth = (gridWidth - hSpacing) / _cols;
        final cardHeight = (gridHeight - vSpacing) / rows;

        // Calculate aspect ratio dynamically so that all rows fit exactly within height
        double aspectRatio = cardWidth / cardHeight;

        // Clamp values to keep cards looking like nice proportioned rectangles/squares
        if (aspectRatio < 0.65) {
          aspectRatio = 0.65;
        } else if (aspectRatio > 1.25) {
          aspectRatio = 1.25;
        }

        return GridView.builder(
          physics: const BouncingScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _cols,
            crossAxisSpacing: 12.w,
            mainAxisSpacing: 12.h,
            childAspectRatio: aspectRatio,
          ),
          itemCount: _cards.length,
          itemBuilder: (context, index) {
            final card = _cards[index];
            return GestureDetector(
              onTap: () => _onCardTap(index),
              child: FlipCard(
                isFaceUp: card.isFaceUp || card.isMatched,
                front: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: card.isMatched 
                          ? Colors.amber.withOpacity(0.6) 
                          : Colors.white.withOpacity(0.2),
                      width: card.isMatched ? 2 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: card.isMatched 
                            ? Colors.amber.withOpacity(0.2) 
                            : Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                      )
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      card.icon,
                      color: card.color,
                      size: 36.sp,
                    ),
                  ),
                ),
                back: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF1B3527),
                        Color(0xFF0B1710),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.forest,
                          color: AppColors.primaryColor.withOpacity(0.6),
                          size: 28.sp,
                        ),
                        4.verticalSpace,
                        Text(
                          'WOODLAND',
                          style: AppTextStyles.regular.copyWith(
                            color: Colors.white.withOpacity(0.3),
                            fontSize: 8.sp,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildVictoryScreen() {
    final isNewHighScore = _score > _highScore;

    return Center(
      child: Container(
        margin: EdgeInsets.all(16.w),
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
                  : 'You have cleared the board!',
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
                  _buildVictoryStatRow('Total Time', _formatTime(_totalTimeLimit - _timeLeft)),
                  const Divider(color: Colors.white24),
                  _buildVictoryStatRow('Total Moves', '$_moves'),
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
        margin: EdgeInsets.all(16.w),
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
              'Time ran out! Keep training your mind!',
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
                  _buildVictoryStatRow('Total Moves', '$_moves'),
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

class FlipCard extends StatelessWidget {
  final bool isFaceUp;
  final Widget front;
  final Widget back;

  const FlipCard({
    super.key,
    required this.isFaceUp,
    required this.front,
    required this.back,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (Widget child, Animation<double> animation) {
        final rotate = Tween<double>(begin: 3.14, end: 0.0).animate(animation);
        return AnimatedBuilder(
          animation: rotate,
          child: child,
          builder: (context, child) {
            final isFront = ValueKey(isFaceUp) == child!.key;
            // 3D Tilt perspective effect
            var tilt = (animation.value - 0.5).abs() * 0.003;
            tilt = isFront ? -tilt : tilt;
            final rotationValue = isFront ? rotate.value : rotate.value + 3.14;
            return Transform(
              transform: Matrix4.identity()
                ..setEntry(3, 2, tilt)
                ..rotateY(rotationValue),
              alignment: Alignment.center,
              child: child,
            );
          },
        );
      },
      child: isFaceUp
          ? Container(key: const ValueKey(true), child: front)
          : Container(key: const ValueKey(false), child: back),
    );
  }
}
