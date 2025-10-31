import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:the_woodlands_series/components/resource/app_routers.dart';
import 'package:the_woodlands_series/admin_panel/models/book_model.dart';
import '../../components/resource/app_colors.dart';
import '../../components/resource/app_textstyle.dart';
import '../../components/utils/three_dot_loader.dart';

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
  bool _isLoading = true;
  bool _useDemoText = false;

  @override
  void initState() {
    super.initState();
    print('🔵 ReadingScreen initialized');
    print('🔵 Book PDF URL: ${widget.book.pdfUrl}');

    // Set a timeout to show demo text if PDF doesn't load
    Future.delayed(Duration(seconds: 10), () {
      if (mounted && _isLoading) {
        print('⏰ PDF loading timeout - showing demo text');
        setState(() {
          _isLoading = false;
          _useDemoText = true;
        });
      }
    });
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
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 20.h, left: 20.w),
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
                          ),
                        ),
                        Text(
                          widget.book.author,
                          style: AppTextStyles.regular.copyWith(
                            color: Colors.grey[400],
                            fontSize: 12.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(
                    child: ThreeDotLoader(
                      color: AppColors.primaryColor,
                      size: 12.w,
                      spacing: 8.w,
                    ),
                  )
                : _useDemoText
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
            _isLoading = false;
            _useDemoText = true;
          });
        }
      });
      return _buildDemoTextPagination();
    }

    return Column(
      children: [
        Expanded(
          child: SfPdfViewer.network(
            widget.book.pdfUrl!,
            controller: _pdfViewerController,
            enableDoubleTapZooming: true,
            onDocumentLoaded: (PdfDocumentLoadedDetails details) {
              print(
                '✅ PDF loaded successfully! Total pages: ${details.document.pages.count}',
              );
              if (mounted) {
                setState(() {
                  _totalPages = details.document.pages.count;
                  _isLoading = false;
                  _useDemoText = false;
                });
              }
            },
            onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
              print('❌ PDF load failed: ${details.error}');
              print('❌ Error description: ${details.description}');
              print('❌ PDF URL was: ${widget.book.pdfUrl}');
              if (mounted) {
                setState(() {
                  _isLoading = false;
                  _useDemoText = true; // Use demo text on error
                  _currentPage = 1;
                  _totalPages = 2;
                });
              }
            },
            onPageChanged: (PdfPageChangedDetails details) {
              if (mounted) {
                setState(() {
                  _currentPage = details.newPageNumber;
                });
              }
            },
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
                    _pdfViewerController!.previousPage();
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
                    _pdfViewerController!.nextPage();
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
