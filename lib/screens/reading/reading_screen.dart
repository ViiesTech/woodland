import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:the_woodlands_series/components/resource/app_routers.dart';
import 'package:the_woodlands_series/admin_panel/models/book_model.dart';
import '../../components/resource/app_colors.dart';
import '../../components/resource/app_textstyle.dart';
import '../../components/utils/three_dot_loader.dart';
import '../../services/global_audio_service.dart';
import '../../services/reading_progress_service.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_state.dart';

class ReadingScreen extends StatefulWidget {
  final BookModel book;

  const ReadingScreen({super.key, required this.book});

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen> {
  PdfViewerController? _pdfViewerController;
  int _currentPage = 1;
  int _totalPages = 2; // Default to 2 pages for demo text
  bool _useDemoText = false;
  bool _isNavigatingViaButton =
      false; // Track if navigation is from button press
  bool _isPdfLoading = true; // Track PDF loading state

  String? _currentUserId;
  DateTime? _readingStartTime;
  Timer? _timeTrackingTimer;

  @override
  void initState() {
    super.initState();
    print('🔵 ReadingScreen initialized');
    print('🔵 Book PDF URL: ${widget.book.pdfUrl}');

    // Get current user ID
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      _currentUserId = authState.user.id;
      print('🔵 User ID: $_currentUserId');
      print('🔵 Book ID: ${widget.book.id}');

      // Save progress IMMEDIATELY to increment readCount if first time (don't wait for PDF load)
      // This ensures unique user count is incremented right away
      if (_currentUserId != null && widget.book.id.isNotEmpty) {
        print('🔵 Saving initial reading progress immediately...');
        _saveProgress();
      }

      // Load existing progress separately (async, won't block)
      _loadProgress();
    } else {
      print('⚠️ User not authenticated, cannot save reading progress');
    }

    // Pause any currently playing audio
    final audioService = GlobalAudioService();
    if (audioService.isPlaying && audioService.audioPlayer != null) {
      audioService.audioPlayer!.pause();
    }

    // Start tracking reading time
    _readingStartTime = DateTime.now();
    _startTimeTracking();

    // Validate PDF URL and check if it's accessible
    if (widget.book.pdfUrl != null && widget.book.pdfUrl!.isNotEmpty) {
      _validatePdfUrl();
    } else {
      // No PDF URL, show demo text immediately
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _useDemoText = true;
          });
        }
      });
    }
  }

  Future<void> _loadProgress() async {
    if (_currentUserId == null) {
      print('⚠️ Cannot load reading progress: user ID is null');
      return;
    }

    try {
      print('📖 Loading reading progress for book ${widget.book.id}...');
      final progress = await ReadingProgressService.getProgress(
        userId: _currentUserId!,
        bookId: widget.book.id,
      );

      if (progress != null && mounted) {
        final savedPage = progress['currentPage'] as int? ?? 1;
        final savedTotalPages = progress['totalPages'] as int? ?? 2;
        print('📖 Loaded progress: Page $savedPage/$savedTotalPages');
        setState(() {
          _currentPage = savedPage;
          _totalPages = savedTotalPages;
        });

        // Jump to saved page if using PDF
        if (_pdfViewerController != null && savedPage > 1) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _pdfViewerController != null) {
              _pdfViewerController!.jumpToPage(savedPage);
            }
          });
        }
      } else {
        print('📖 No existing progress found - will create new progress');
      }
    } catch (e) {
      print('❌ Error loading reading progress: $e');
      print('❌ Error stack: ${e.toString()}');
    }
  }

  void _startTimeTracking() {
    // Save progress every minute
    _timeTrackingTimer = Timer.periodic(Duration(minutes: 1), (timer) {
      if (_currentUserId != null) {
        _saveProgress(timeSpentMinutes: 1);
      }
    });
  }

  Future<void> _saveProgress({int? timeSpentMinutes}) async {
    if (_currentUserId == null) {
      print('⚠️ Cannot save reading progress: user ID is null');
      return;
    }

    if (widget.book.id.isEmpty) {
      print('⚠️ Cannot save reading progress: book ID is empty');
      return;
    }

    // Ensure we have valid page values
    final validCurrentPage = _currentPage > 0 ? _currentPage : 1;
    final validTotalPages = _totalPages > 0 ? _totalPages : 2;

    print('💾 Saving reading progress for book ${widget.book.id}');
    print('💾 User: $_currentUserId, Page: $validCurrentPage/$validTotalPages');

    try {
      await ReadingProgressService.saveProgress(
        userId: _currentUserId!,
        bookId: widget.book.id,
        currentPage: validCurrentPage,
        totalPages: validTotalPages,
        timeSpentMinutes: timeSpentMinutes,
      );
      print('✅ Reading progress saved successfully');
    } catch (e) {
      print('❌ Error saving reading progress: $e');
      print('❌ Error stack: ${e.toString()}');
    }
  }

  @override
  void dispose() {
    // Save final progress and time spent
    if (_currentUserId != null && _readingStartTime != null) {
      final timeSpent = DateTime.now().difference(_readingStartTime!);
      final minutesSpent = timeSpent.inMinutes;
      if (minutesSpent > 0) {
        _saveProgress(timeSpentMinutes: minutesSpent);
      } else {
        // Save progress without time if less than a minute
        _saveProgress();
      }
    }

    _timeTrackingTimer?.cancel();
    _pdfViewerController?.dispose();
    super.dispose();
  }

  Future<void> _validatePdfUrl() async {
    // Try to make a HEAD request to verify the URL is accessible
    try {
      print('🔍 Validating PDF URL...');
      final client = HttpClient();
      final uri = Uri.parse(widget.book.pdfUrl!);
      final request = await client.headUrl(uri);
      request.headers.set('User-Agent', 'Flutter-App');

      final response = await request.close();
      print('🔍 PDF URL validation response: ${response.statusCode}');

      if (response.statusCode == 200 ||
          response.statusCode == 403 ||
          response.statusCode == 304) {
        // URL is accessible (200 = OK, 403 might be CORS but file exists, 304 = Not Modified)
        print('✅ PDF URL is accessible');
      } else {
        print('⚠️ PDF URL returned status code: ${response.statusCode}');
      }
      client.close();
    } catch (e) {
      print('⚠️ Error validating PDF URL: $e');
      // Continue anyway - SfPdfViewer will handle the error
    }
  }

  // Demo text content for 2 pages
  final List<String> _demoPages = [
    '''Chapter 1: The Beginning

Lorem ipsum dolor sit amet, consectetur adipiscing elit. Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.

Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.

Sed ut perspiciatis unde omnis iste natus error sit voluptatem accusantium doloremque laudantium, totam rem aperiam, eaque ipsa quae ab illo inventore veritatis et quasi architecto beatae vitae dicta sunt explicabo.''',
    '''Chapter 2: The Journey Continues

Nemo enim ipsam voluptatem quia voluptas sit aspernatur aut odit aut fugit, sed quia consequuntur magni dolores eos qui ratione voluptatem sequi nesciunt. Neque porro quisquam est, qui dolorem ipsum quia dolor sit amet.

At vero eos et accusamus et iusto odio dignissimos ducimus qui blanditiis praesentium voluptatum deleniti atque corrupti quos dolores et quas molestias excepturi sint occaecati cupiditate non provident.

Similique sunt in culpa qui officia deserunt mollitia animi, id est laborum et dolorum fuga. Et harum quidem rerum facilis est et expedita distinctio. Nam libero tempore, cum soluta nobis est eligendi optio cumque nihil impedit quo minus id quod maxime placeat facere possimus.''',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgClr,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 220.h,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30.r),
                bottomRight: Radius.circular(30.r),
              ),
            ),
            child: Stack(
              children: [
                // Blurred Background
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: widget.book.coverImageUrl.startsWith('http')
                            ? NetworkImage(widget.book.coverImageUrl)
                                  as ImageProvider
                            : AssetImage(widget.book.coverImageUrl),
                        fit: BoxFit.cover,
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(30.r),
                        bottomRight: Radius.circular(30.r),
                      ),
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black26.withOpacity(0.2),
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(30.r),
                            bottomRight: Radius.circular(30.r),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 50.h,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => AppRouter.routeBack(context),
                        child: Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white,
                          size: 20.sp,
                        ),
                      ),
                      Icon(
                        Icons.bookmark_outline,
                        color: Colors.white,
                        size: 20.sp,
                      ),
                    ],
                  ),
                ),
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Container(
                    margin: EdgeInsets.only(bottom: 20.h, left: 20.w),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.r),
                      color: Colors.black.withOpacity(
                        0.4,
                      ), // Dark smoky background
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12.r),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: 10,
                          sigmaY: 10,
                        ), // Blur effect
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 12.h,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.book.title,
                                style: AppTextStyles.lufgaLarge.copyWith(
                                  color: Colors.white,
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.5),
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                              4.verticalSpace,
                              Text(
                                widget.book.author,
                                style: AppTextStyles.regular.copyWith(
                                  color: Colors.grey[300],
                                  fontSize: 12.sp,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.5),
                                      blurRadius: 3,
                                      offset: Offset(0, 1),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _useDemoText
                ? _buildDemoTextPagination()
                : widget.book.pdfUrl != null && widget.book.pdfUrl!.isNotEmpty
                ? _buildPDFViewer()
                : _buildTextContentView(),
          ),
        ],
      ),
    );
  }

  Widget _buildPDFViewer() {
    _pdfViewerController ??= PdfViewerController();

    print('📄 Building PDF viewer widget');
    print('📄 PDF URL: ${widget.book.pdfUrl}');
    print('📄 Controller: $_pdfViewerController');

    // If no PDF URL, show demo text immediately
    if (widget.book.pdfUrl == null || widget.book.pdfUrl!.isEmpty) {
      print('⚠️ No PDF URL - showing demo text');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _useDemoText = true;
          });
        }
      });
      return _buildDemoTextPagination();
    }

    return Column(
      children: [
        Expanded(
          child: Container(
            color: const Color(0xff1B252D), // #1B252D background color
            child: Stack(
              children: [
                // Dark background layer to cover everything
                Container(color: const Color(0xff1B252D)),
                // PDF Viewer
                SfPdfViewerTheme(
                  data: SfPdfViewerThemeData(
                    backgroundColor: Colors
                        .transparent, // Transparent so dark background shows through
                    progressBarColor:
                        Colors.transparent, // Hide default PDF loader
                  ),
                  child: Container(
                    color: const Color(0xff1B252D), // Dark background container
                    child: ColorFiltered(
                      // Invert colors to convert white pages to dark and black text to white
                      colorFilter: const ColorFilter.matrix([
                        -1.0, 0.0, 0.0, 0.0, 255.0, // Red channel inverted
                        0.0, -1.0, 0.0, 0.0, 255.0, // Green channel inverted
                        0.0, 0.0, -1.0, 0.0, 255.0, // Blue channel inverted
                        0.0, 0.0, 0.0, 1.0, 0.0, // Alpha channel unchanged
                      ]),
                      child: Opacity(
                        opacity: _isPdfLoading
                            ? 0
                            : 1, // Hide PDF while loading
                        child: SfPdfViewer.network(
                          maxZoomLevel: 1,
                          widget.book.pdfUrl!,
                          controller: _pdfViewerController,
                          enableDoubleTapZooming: true,
                          pageLayoutMode: PdfPageLayoutMode
                              .single, // Show only 1 page at a time
                          scrollDirection: PdfScrollDirection
                              .horizontal, // Horizontal for single page mode
                          canShowScrollHead:
                              false, // Hide side page numbers/indicators
                          canShowScrollStatus: false,

                          onDocumentLoaded: (PdfDocumentLoadedDetails details) {
                            print('✅ PDF loaded successfully!');
                            print(
                              '✅ Total pages: ${details.document.pages.count}',
                            );
                            print('✅ PDF URL: ${widget.book.pdfUrl}');
                            if (mounted) {
                              setState(() {
                                _totalPages = details.document.pages.count;
                                _useDemoText = false;
                                _isPdfLoading = false; // PDF loaded
                              });
                              // Save initial progress with total pages
                              _saveProgress();
                            }
                          },
                          onDocumentLoadFailed:
                              (PdfDocumentLoadFailedDetails details) {
                                print('❌ PDF load failed!');
                                print('❌ Error: ${details.error}');
                                print(
                                  '❌ Error description: ${details.description}',
                                );
                                print('❌ PDF URL was: ${widget.book.pdfUrl}');

                                // Only show demo text if there's a real error
                                if (mounted) {
                                  setState(() {
                                    _useDemoText = true;
                                    _currentPage = 1;
                                    _totalPages = 2;
                                    _isPdfLoading = false; // Stop loading
                                  });
                                }
                              },
                          onPageChanged: (PdfPageChangedDetails details) {
                            print('📄 Page changed: ${details.newPageNumber}');
                            // Only update page if navigation was via button, otherwise revert
                            if (mounted) {
                              if (_isNavigatingViaButton) {
                                setState(() {
                                  _currentPage = details.newPageNumber;
                                  _isNavigatingViaButton = false; // Reset flag
                                });
                                // Save progress when page changes
                                _saveProgress();
                              } else {
                                // Revert to previous page if changed via scroll
                                Future.delayed(Duration.zero, () {
                                  if (_pdfViewerController != null && mounted) {
                                    _pdfViewerController!.jumpToPage(
                                      _currentPage,
                                    );
                                  }
                                });
                              }
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                // Custom Loader
                if (_isPdfLoading)
                  Container(
                    color: const Color(0xff1B252D), // Match background color
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ThreeDotLoader(
                            color: AppColors.primaryColor,
                            size: 12.w,
                            spacing: 8.w,
                          ),
                          16.verticalSpace,
                          Text(
                            'Loading PDF...',
                            style: AppTextStyles.medium.copyWith(
                              color: Colors.white70,
                              fontSize: 14.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        // Pagination Controls
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: AppColors.boxClr,
            border: Border(
              top: BorderSide(color: Colors.grey[800]!, width: 0.5),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Previous Button
              GestureDetector(
                onTap: () {
                  if (_currentPage > 1 && _pdfViewerController != null) {
                    _isNavigatingViaButton =
                        true; // Mark that navigation is from button
                    _pdfViewerController!.previousPage();
                    _saveProgress();
                  }
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: _currentPage > 1
                        ? AppColors.primaryColor
                        : Colors.grey[800],
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    'Previous',
                    style: AppTextStyles.medium.copyWith(
                      color: _currentPage > 1 ? Colors.black : Colors.grey[600],
                      fontSize: 14.sp,
                    ),
                  ),
                ),
              ),
              // Page Info
              Text(
                _totalPages > 0
                    ? 'Page $_currentPage/$_totalPages'
                    : 'Loading...',
                style: AppTextStyles.medium.copyWith(
                  color: AppColors.primaryColor,
                  fontSize: 14.sp,
                ),
              ),
              // Next Button
              GestureDetector(
                onTap: () {
                  if (_currentPage < _totalPages &&
                      _pdfViewerController != null) {
                    _isNavigatingViaButton =
                        true; // Mark that navigation is from button
                    _pdfViewerController!.nextPage();
                    _saveProgress();
                  }
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: _currentPage < _totalPages
                        ? AppColors.primaryColor
                        : Colors.grey[800],
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    'Next',
                    style: AppTextStyles.medium.copyWith(
                      color: _currentPage < _totalPages
                          ? Colors.black
                          : Colors.grey[600],
                      fontSize: 14.sp,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDemoTextPagination() {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(20.w),
              child: Text(
                _demoPages[_currentPage - 1],
                style: AppTextStyles.regular.copyWith(
                  color: Colors.white,
                  fontSize: 16.sp,
                  height: 1.8,
                ),
                textAlign: TextAlign.justify,
              ),
            ),
          ),
        ),
        // Pagination Controls
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: AppColors.boxClr,
            border: Border(
              top: BorderSide(color: Colors.grey[800]!, width: 0.5),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Previous Button
              GestureDetector(
                onTap: () {
                  if (_currentPage > 1) {
                    setState(() {
                      _currentPage--;
                    });
                    _saveProgress();
                  }
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: _currentPage > 1
                        ? AppColors.primaryColor
                        : Colors.grey[800],
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    'Previous',
                    style: AppTextStyles.medium.copyWith(
                      color: _currentPage > 1 ? Colors.black : Colors.grey[600],
                      fontSize: 14.sp,
                    ),
                  ),
                ),
              ),
              // Page Info
              Text(
                'Page $_currentPage/$_totalPages',
                style: AppTextStyles.medium.copyWith(
                  color: AppColors.primaryColor,
                  fontSize: 14.sp,
                ),
              ),
              // Next Button
              GestureDetector(
                onTap: () {
                  if (_currentPage < _totalPages) {
                    setState(() {
                      _currentPage++;
                    });
                    _saveProgress();
                  }
                },
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: _currentPage < _totalPages
                        ? AppColors.primaryColor
                        : Colors.grey[800],
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    'Next',
                    style: AppTextStyles.medium.copyWith(
                      color: _currentPage < _totalPages
                          ? Colors.black
                          : Colors.grey[600],
                      fontSize: 14.sp,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextContentView() {
    // Show text content if PDF is not available
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            25.verticalSpace,
            if (widget.book.content != null && widget.book.content!.isNotEmpty)
              Text(
                widget.book.content!,
                style: AppTextStyles.regular.copyWith(
                  color: Colors.white,
                  fontSize: 14.sp,
                  height: 1.7,
                ),
                textAlign: TextAlign.justify,
              )
            else
              Center(
                child: Padding(
                  padding: EdgeInsets.all(32.w),
                  child: Column(
                    children: [
                      Icon(
                        Icons.book_outlined,
                        size: 64.sp,
                        color: Colors.grey[600],
                      ),
                      16.verticalSpace,
                      Text(
                        'No content available',
                        style: AppTextStyles.medium.copyWith(
                          color: Colors.grey[400],
                          fontSize: 16.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            30.verticalSpace,
          ],
        ),
      ),
    );
  }
}
