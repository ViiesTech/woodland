import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:the_woodlands_series/components/button/primary_button.dart';
import 'package:the_woodlands_series/components/resource/app_assets.dart';
import 'package:the_woodlands_series/admin_panel/models/book_model.dart';
import '../../components/resource/app_colors.dart';
import '../../components/resource/app_textstyle.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_state.dart';
import '../../services/listening_progress_service.dart';
import '../../services/book_service.dart';
import '../../services/global_audio_service.dart';

class ListenScreen extends StatefulWidget {
  final BookModel book;

  const ListenScreen({super.key, required this.book});

  @override
  State<ListenScreen> createState() => _ListenScreenState();
}

class _ListenScreenState extends State<ListenScreen> {
  late AudioPlayer _audioPlayer;
  final GlobalAudioService _globalAudioService = GlobalAudioService();
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  int _currentChapterIndex = 0;
  bool _isLoading = false;
  String? _currentUserId;
  late BookModel _book; // Track book with updated listen count
  DateTime? _lastSaveTime;
  bool _isReusingExistingPlayer = false;

  List<Map<String, String>> get _chapters {
    // Get chapters from book model, fallback to single audioFileUrl if chapters not available
    if (widget.book.chapters != null && widget.book.chapters!.isNotEmpty) {
      return widget.book.chapters!;
    } else if (widget.book.audioFileUrl != null &&
        widget.book.audioFileUrl!.isNotEmpty) {
      // Legacy support: convert single audioFileUrl to chapters format
      return [
        {
          'chapterName': widget.book.title,
          'audioUrl': widget.book.audioFileUrl!,
        },
      ];
    }
    return [];
  }

  @override
  void initState() {
    super.initState();
    _book = widget.book;

    // Get current user ID
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      _currentUserId = authState.user.id;
    }

    // Check if this book is already playing in global service
    final isSameBook = _globalAudioService.currentBook?.id == widget.book.id;
    final isAlreadyPlaying = isSameBook && _globalAudioService.isPlaying;

    if (isSameBook && _globalAudioService.audioPlayer != null) {
      // Use the existing audio player from global service
      _audioPlayer = _globalAudioService.audioPlayer!;
      _isReusingExistingPlayer = true;
      // Update state from global service
      setState(() {
        _currentChapterIndex = _globalAudioService.currentChapterIndex;
        _isPlaying = _globalAudioService.isPlaying;
        _position = _globalAudioService.position;
        _duration = _globalAudioService.duration;
      });
    } else {
      // Create new audio player
      _audioPlayer = AudioPlayer();
      _isReusingExistingPlayer = false;
      // Enable background audio
      _audioPlayer.setReleaseMode(ReleaseMode.stop);
      // Set audio player in global service
      _globalAudioService.setAudioPlayer(_audioPlayer);
      // Load saved progress if not already playing
      if (_currentUserId != null && !isAlreadyPlaying) {
        _loadProgress();
      }
    }

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
        // Update global audio service
        _globalAudioService.updatePlayingState(_isPlaying);
        _globalAudioService.updateChapterIndex(_currentChapterIndex);
      }
    });

    _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() {
          _duration = duration;
        });
        // Update global service
        _globalAudioService.updateChapterIndex(_currentChapterIndex);
      }
    });

    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() {
          _position = position;
        });

        // Save progress periodically (debounced)
        _saveProgressDebounced();

        // Auto-play next chapter when current one finishes
        if (_duration.inMilliseconds > 0 &&
            position.inMilliseconds >= _duration.inMilliseconds - 100 &&
            _isPlaying) {
          _playNextChapter();
        }
      }
    });

    // Auto-play first chapter only if not already playing
    if (_chapters.isNotEmpty && !isAlreadyPlaying) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_currentChapterIndex == 0 && _position == Duration.zero) {
          _playChapter(0);
        } else if (_position.inMilliseconds > 0) {
          // Resume from saved position
          _playChapter(_currentChapterIndex, seekTo: _position);
        }
      });
    } else if (isAlreadyPlaying) {
      // Update global service with current book info
      _globalAudioService.setCurrentBook(widget.book, _currentChapterIndex);
    }
  }

  Future<void> _loadProgress() async {
    if (_currentUserId == null) return;

    try {
      final progress = await ListeningProgressService.getProgress(
        userId: _currentUserId!,
        bookId: widget.book.id,
      );

      if (progress != null && mounted) {
        final savedChapterIndex = progress['chapterIndex'] as int? ?? 0;
        final savedPositionMs = progress['positionMs'] as int? ?? 0;

        if (savedChapterIndex >= 0 && savedChapterIndex < _chapters.length) {
          setState(() {
            _currentChapterIndex = savedChapterIndex;
            _position = Duration(milliseconds: savedPositionMs);
          });

          // Resume from saved position
          if (savedPositionMs > 0) {
            _playChapter(
              savedChapterIndex,
              seekTo: Duration(milliseconds: savedPositionMs),
            );
          }
        }
      }
    } catch (e) {
      print('Error loading progress: $e');
    }
  }

  Future<void> _refreshBookData() async {
    try {
      final updatedBook = await BookService.getBookById(widget.book.id);
      if (updatedBook != null && mounted) {
        setState(() {
          _book = updatedBook;
        });
      }
    } catch (e) {
      print('Error refreshing book data: $e');
    }
  }

  void _saveProgressDebounced() {
    final now = DateTime.now();
    // Save progress every 5 seconds
    if (_lastSaveTime == null ||
        now.difference(_lastSaveTime!).inSeconds >= 5) {
      _lastSaveTime = now;
      _saveProgress();
    }
  }

  Future<void> _saveProgress() async {
    if (_currentUserId == null) return;

    try {
      await ListeningProgressService.saveProgress(
        userId: _currentUserId!,
        bookId: widget.book.id,
        chapterIndex: _currentChapterIndex,
        positionMs: _position.inMilliseconds,
      );
    } catch (e) {
      print('Error saving progress: $e');
    }
  }

  @override
  void dispose() {
    // Save final progress before disposing
    if (_currentUserId != null) {
      _saveProgress();
    }
    // Only dispose audio player if we created it (not reusing from global service)
    if (!_isReusingExistingPlayer) {
      // Don't dispose - let it continue in background via global service
      // _audioPlayer.dispose();
    }
    super.dispose();
  }

  Future<void> _playChapter(int index, {Duration? seekTo}) async {
    if (index < 0 || index >= _chapters.length) return;

    setState(() {
      _currentChapterIndex = index;
      _isLoading = true;
      _isPlaying = false;
    });

    try {
      await _audioPlayer.play(UrlSource(_chapters[index]['audioUrl']!));

      // Seek to saved position if provided
      if (seekTo != null && seekTo.inMilliseconds > 0) {
        await _audioPlayer.seek(seekTo);
      }

      setState(() {
        _isLoading = false;
        _isPlaying = true;
      });

      // Update global audio service
      _globalAudioService.setCurrentBook(widget.book, index);

      // Save progress (service will check if it's a new listen and increment listenCount)
      if (_currentUserId != null) {
        _saveProgress();
      }

      // Refresh book data to get updated counts after a delay to allow DB update
      Future.delayed(Duration(milliseconds: 500), () {
        if (mounted) {
          _refreshBookData();
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error playing audio: $e')));
      }
    }
  }

  Future<void> _playPause() async {
    if (_isLoading) return;

    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      if (_position.inMilliseconds > 0) {
        await _audioPlayer.resume();
      } else if (_chapters.isNotEmpty) {
        await _playChapter(_currentChapterIndex);
      }
    }
  }

  Future<void> _playPreviousChapter() async {
    if (_currentChapterIndex > 0) {
      await _playChapter(_currentChapterIndex - 1);
    }
  }

  Future<void> _playNextChapter() async {
    if (_currentChapterIndex < _chapters.length - 1) {
      await _playChapter(_currentChapterIndex + 1);
    }
  }

  Future<void> _seek(Duration position) async {
    await _audioPlayer.seek(position);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  String _formatListenCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M Users';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K Users';
    } else {
      return '$count Users Listened';
    }
  }

  void _showChaptersBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: AppColors.bgClr,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20.r),
            topRight: Radius.circular(20.r),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: EdgeInsets.only(top: 12.h, bottom: 8.h),
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            // Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'All Chapters (${_chapters.length})',
                    style: AppTextStyles.lufgaLarge.copyWith(
                      color: Colors.white,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(Icons.close, color: Colors.white, size: 24.sp),
                  ),
                ],
              ),
            ),
            Divider(color: Colors.grey[800], thickness: 0.5),
            // Chapters List
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                itemCount: _chapters.length,
                itemBuilder: (context, index) {
                  final chapter = _chapters[index];
                  final isCurrentChapter = index == _currentChapterIndex;
                  return Container(
                    margin: EdgeInsets.only(bottom: 12.h),
                    padding: EdgeInsets.all(16.w),
                    decoration: BoxDecoration(
                      color: isCurrentChapter
                          ? AppColors.primaryColor.withOpacity(0.3)
                          : AppColors.boxClr,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: isCurrentChapter
                            ? AppColors.primaryColor
                            : Colors.grey[800]!,
                        width: isCurrentChapter ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Chapter Number
                        Container(
                          width: 44.w,
                          height: 44.h,
                          decoration: BoxDecoration(
                            color: isCurrentChapter
                                ? AppColors.primaryColor
                                : Colors.grey[800],
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: AppTextStyles.medium.copyWith(
                                color: Colors.white,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        16.horizontalSpace,
                        // Chapter Name
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                chapter['chapterName'] ??
                                    'Chapter ${index + 1}',
                                style: AppTextStyles.medium.copyWith(
                                  color: Colors.white,
                                  fontSize: 16.sp,
                                  fontWeight: isCurrentChapter
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              if (isCurrentChapter)
                                Padding(
                                  padding: EdgeInsets.only(top: 4.h),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.play_circle_filled,
                                        color: AppColors.primaryColor,
                                        size: 14.sp,
                                      ),
                                      4.horizontalSpace,
                                      Text(
                                        'Now Playing',
                                        style: AppTextStyles.small.copyWith(
                                          color: AppColors.primaryColor,
                                          fontSize: 12.sp,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // Play Button
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            if (isCurrentChapter) {
                              _playPause();
                            } else {
                              _playChapter(index);
                            }
                          },
                          child: Container(
                            width: 44.w,
                            height: 44.h,
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isCurrentChapter && _isPlaying
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              color: Colors.black,
                              size: 24.sp,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.bgClr,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Icon(Icons.arrow_back_ios, color: Colors.white, size: 20.sp),
        ),
        title: Text(
          'Now Listening',
          style: AppTextStyles.lufgaLarge.copyWith(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        // actions: [
        //   Icon(Icons.bookmark_outline, color: Colors.white, size: 24.sp),
        //   SizedBox(width: 12.w),
        //   BlocBuilder<AuthBloc, AuthState>(
        //     builder: (context, state) {
        //       final user = state is Authenticated ? state.user : null;
        //       return Padding(
        //         padding: EdgeInsets.only(right: 16.w),
        //         child: _buildUserAvatar(user),
        //       );
        //     },
        //   ),
        // ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                15.verticalSpace,
                // Headphone Icon and Listener Count
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      AppAssets.headphoneIcon,
                      colorFilter: ColorFilter.mode(
                        AppColors.primaryColor,
                        BlendMode.srcIn,
                      ),
                    ),
                    8.horizontalSpace,
                    Text(
                      _formatListenCount(_book.listenCount),
                      style: AppTextStyles.regular.copyWith(
                        color: Colors.white,
                        fontSize: 14.sp,
                      ),
                    ),
                  ],
                ),

                20.verticalSpace,

                // Large Audiobook Cover Card
                Center(
                  child: Container(
                    height: 280.h,
                    width: 200.w,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: widget.book.coverImageUrl.startsWith('http')
                            ? NetworkImage(widget.book.coverImageUrl)
                                  as ImageProvider
                            : AssetImage(widget.book.coverImageUrl),
                        fit: BoxFit.cover,
                      ),
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16.r),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                24.verticalSpace,

                // Audiobook Title
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Text(
                    widget.book.title,
                    style: AppTextStyles.lufgaLarge.copyWith(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                8.verticalSpace,
                // Author
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Text(
                    widget.book.author,
                    style: AppTextStyles.regular.copyWith(
                      color: Colors.grey[400],
                      fontSize: 14.sp,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                30.verticalSpace,

                // Progress Bar and Time
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Column(
                    children: [
                      // Current Chapter Name
                      if (_chapters.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(bottom: 8.h),
                          child: Text(
                            _chapters[_currentChapterIndex]['chapterName'] ??
                                'Chapter ${_currentChapterIndex + 1}',
                            style: AppTextStyles.medium.copyWith(
                              color: AppColors.primaryColor,
                              fontSize: 14.sp,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(_position),
                            style: AppTextStyles.regular.copyWith(
                              color: Colors.white,
                              fontSize: 14.sp,
                            ),
                          ),
                          Expanded(
                            child: SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: AppColors.primaryColor,
                                inactiveTrackColor: Colors.grey[600],
                                thumbColor: Colors.white,
                                thumbShape: RoundSliderThumbShape(
                                  enabledThumbRadius: 8.r,
                                ),
                                trackHeight: 4.h,
                              ),
                              child: Slider(
                                value: _duration.inMilliseconds > 0
                                    ? _position.inMilliseconds /
                                          _duration.inMilliseconds
                                    : 0.0,
                                onChanged: (value) {
                                  final newPosition = Duration(
                                    milliseconds:
                                        (value * _duration.inMilliseconds)
                                            .toInt(),
                                  );
                                  _seek(newPosition);
                                },
                              ),
                            ),
                          ),
                          Text(
                            _formatDuration(_duration),
                            style: AppTextStyles.regular.copyWith(
                              color: Colors.white,
                              fontSize: 14.sp,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                15.verticalSpace,

                // Playback Controls
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Shuffle
                      // Icon(Icons.shuffle, color: Colors.grey[400], size: 24.sp),
                      // Previous Chapter
                      GestureDetector(
                        onTap: _currentChapterIndex > 0
                            ? _playPreviousChapter
                            : null,
                        child: Icon(
                          Icons.skip_previous,
                          color: _currentChapterIndex > 0
                              ? Colors.white
                              : Colors.grey[600],
                          size: 28.sp,
                        ),
                      ),
                      // Play/Pause Button
                      GestureDetector(
                        onTap: _isLoading ? null : _playPause,
                        child: Container(
                          width: 60.w,
                          height: 60.h,
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: _isLoading
                              ? SizedBox(
                                  width: 20.w,
                                  height: 20.h,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.black,
                                    ),
                                  ),
                                )
                              : Icon(
                                  _isPlaying ? Icons.pause : Icons.play_arrow,
                                  color: Colors.black,
                                  size: 30.sp,
                                ),
                        ),
                      ),
                      // Next Chapter
                      GestureDetector(
                        onTap: _currentChapterIndex < _chapters.length - 1
                            ? _playNextChapter
                            : null,
                        child: Icon(
                          Icons.skip_next,
                          color: _currentChapterIndex < _chapters.length - 1
                              ? Colors.white
                              : Colors.grey[600],
                          size: 28.sp,
                        ),
                      ),
                      // Repeat
                      // Icon(Icons.repeat, color: Colors.grey[400], size: 24.sp),
                    ],
                  ),
                ),

                20.verticalSpace,

                // Current Playing Chapter Section
                if (_chapters.length > 1 && _chapters.isNotEmpty) ...[
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 20.w),
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: AppColors.boxClr,
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Now Playing',
                              style: AppTextStyles.lufgaLarge.copyWith(
                                color: Colors.white,
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_chapters.length > 1)
                              GestureDetector(
                                onTap: _showChaptersBottomSheet,
                                child: Text(
                                  'See More',
                                  style: AppTextStyles.medium.copyWith(
                                    color: AppColors.primaryColor,
                                    fontSize: 14.sp,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        16.verticalSpace,
                        // Current Chapter Card
                        Container(
                          padding: EdgeInsets.all(16.w),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: AppColors.primaryColor,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Play/Pause Icon
                              GestureDetector(
                                onTap: _playPause,
                                child: Container(
                                  width: 50.w,
                                  height: 50.h,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _isPlaying ? Icons.pause : Icons.play_arrow,
                                    color: Colors.black,
                                    size: 24.sp,
                                  ),
                                ),
                              ),
                              16.horizontalSpace,
                              // Chapter Name and Info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _chapters[_currentChapterIndex]['chapterName'] ??
                                          'Chapter ${_currentChapterIndex + 1}',
                                      style: AppTextStyles.medium.copyWith(
                                        color: Colors.white,
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    4.verticalSpace,
                                    Text(
                                      'Chapter ${_currentChapterIndex + 1} of ${_chapters.length}',
                                      style: AppTextStyles.small.copyWith(
                                        color: AppColors.primaryColor,
                                        fontSize: 12.sp,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  20.verticalSpace,
                ],

                // Readings Section
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 20.w),
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: AppColors.boxClr,
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Readings Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Readings',
                            style: AppTextStyles.lufgaLarge.copyWith(
                              color: Colors.white,
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SvgPicture.asset(AppAssets.fullIcon),
                        ],
                      ),
                      16.verticalSpace,

                      // Text Content
                      Text(
                        widget.book.description,
                        style: AppTextStyles.regular.copyWith(
                          color: Colors.white,
                          fontSize: 14.sp,
                          height: 1.6,
                        ),
                        textAlign: TextAlign.justify,
                      ),
                      20.verticalSpace,

                      // Share Button
                      Align(
                        alignment: Alignment.bottomRight,
                        child: PrimaryButton(
                          buttonWidth: 100.w,
                          verPadding: 6.h,
                          title: 'Share',
                          icon: Icon(Icons.share_outlined, color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                ),

                40.verticalSpace,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
