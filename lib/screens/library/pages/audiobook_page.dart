import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:the_woodlands_series/components/card/global_card.dart';
import 'package:the_woodlands_series/components/resource/app_colors.dart';
import 'package:the_woodlands_series/components/resource/app_textstyle.dart';
import 'package:the_woodlands_series/components/textfield/primary_textfield.dart';
import 'package:the_woodlands_series/components/utils/three_dot_loader.dart';
import 'package:the_woodlands_series/admin_panel/models/book_model.dart';
import 'package:the_woodlands_series/services/book_service.dart';
import 'package:the_woodlands_series/screens/book_detail/book_detail_screen.dart';
import 'package:the_woodlands_series/components/resource/app_routers.dart';
import 'package:the_woodlands_series/bloc/auth/auth_bloc.dart';
import 'package:the_woodlands_series/bloc/auth/auth_state.dart';
import 'package:the_woodlands_series/services/listening_progress_service.dart';
import 'package:the_woodlands_series/components/button/bookmark_icon_button.dart';

class AudiobookPage extends StatefulWidget {
  const AudiobookPage({super.key});

  @override
  State<AudiobookPage> createState() => _AudiobookPageState();
}

class _AudiobookPageState extends State<AudiobookPage>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _currentUserId;
  Map<String, Map<String, dynamic>> _listeningProgress =
      {}; // Local state for progress

  @override
  void initState() {
    super.initState();
    // Get current user ID
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      _currentUserId = authState.user.id;
      _listenToProgress();
    }
  }

  void _listenToProgress() {
    if (_currentUserId == null) return;

    // Listen to stream in background - only update if different
    ListeningProgressService.getAllProgress(_currentUserId!).listen((progress) {
      if (mounted) {
        setState(() {
          _listeningProgress = progress;
        });
      }
    });
  }

  Map<String, dynamic>? _getBookProgress(String bookId) {
    return _listeningProgress[bookId];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        final isAdmin = state is Authenticated && state.user.role == 'admin';

        return Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: PrimaryTextField(
                controller: _searchController,
                hint: 'Title, author or keyword',
                prefixIcon: Icon(Icons.search, size: 20.sp),
                height: 55.h,
                verticalPad: 10.h,
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),
            16.verticalSpace,
            Expanded(
              child: StreamBuilder<List<BookModel>>(
                stream: _searchQuery.isEmpty
                    ? (isAdmin
                          ? BookService.getAllBooksByType(BookType.audiobook)
                          : BookService.getBooksByType(BookType.audiobook))
                    : (isAdmin
                          ? BookService.searchAllBooks(
                              _searchQuery,
                              BookType.audiobook,
                            )
                          : BookService.searchBooks(
                              _searchQuery,
                              BookType.audiobook,
                            )),
                builder: (context, snapshot) {
                  // Only show loader on initial load (no data yet)
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return Center(
                      child: ThreeDotLoader(
                        color: AppColors.primaryColor,
                        size: 12.w,
                        spacing: 8.w,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error loading audiobooks',
                        style: AppTextStyles.regular.copyWith(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 14.sp,
                        ),
                      ),
                    );
                  }

                  final books = snapshot.data ?? [];

                  if (books.isEmpty) {
                    return Center(
                      child: Text(
                        _searchQuery.isEmpty
                            ? 'No audiobooks available'
                            : 'No books found',
                        style: AppTextStyles.regular.copyWith(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 14.sp,
                        ),
                      ),
                    );
                  }

                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_searchQuery.isEmpty) ...[
                          // Trending Audio Books Section - Top 5 by listen count
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            child: Text(
                              'Trending Audio Books',
                              style: AppTextStyles.lufgaLarge.copyWith(
                                color: Colors.white,
                                fontSize: 18.sp,
                              ),
                            ),
                          ),
                          16.verticalSpace,
                          StreamBuilder<List<BookModel>>(
                            stream: BookService.getTrendingAudiobooks(
                              adminMode: isAdmin,
                              limit: 5,
                            ),
                            builder: (context, trendingSnapshot) {
                              // Only show loader on initial load (no data yet)
                              if (trendingSnapshot.connectionState ==
                                      ConnectionState.waiting &&
                                  !trendingSnapshot.hasData) {
                                return Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16.w,
                                  ),
                                  child: Center(
                                    child: ThreeDotLoader(
                                      color: AppColors.primaryColor,
                                      size: 12.w,
                                      spacing: 8.w,
                                    ),
                                  ),
                                );
                              }

                              final trendingBooks = trendingSnapshot.data ?? [];

                              if (trendingBooks.isEmpty) {
                                return SizedBox.shrink();
                              }

                              return Padding(
                                padding: EdgeInsets.symmetric(horizontal: 16.w),
                                child: GridView.builder(
                                  shrinkWrap: true,
                                  physics: NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 3,
                                        crossAxisSpacing: 16.w,
                                        mainAxisSpacing: 16.h,
                                        childAspectRatio: 0.52,
                                      ),
                                  itemCount: trendingBooks.length,
                                  itemBuilder: (context, index) {
                                    final book = trendingBooks[index];
                                    return _buildTrendingAudiobookCard(book);
                                  },
                                ),
                              );
                            },
                          ),
                          26.verticalSpace,
                        ],

                        // Audiobooks List
                        if (_searchQuery.isEmpty) ...[
                          16.verticalSpace,
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            child: Text(
                              'Suggested for you',
                              style: AppTextStyles.lufgaLarge.copyWith(
                                color: Colors.white,
                                fontSize: 20.sp,
                              ),
                            ),
                          ),
                          16.verticalSpace,
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            child: GridView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 3,
                                    crossAxisSpacing: 16.w,
                                    mainAxisSpacing: 16.h,
                                    childAspectRatio: 0.52,
                                  ),
                              itemCount: books.length > 6 ? 6 : books.length,
                              itemBuilder: (context, index) {
                                final book = books[index];
                                final progress = _getBookProgress(book.id);
                                return _buildBookCard(book, progress: progress);
                              },
                            ),
                          ),
                        ],
                        26.verticalSpace,
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTrendingAudiobookCard(BookModel book) {
    return Stack(
      children: [
        GestureDetector(
          onTap: () {
            try {
              if (book.id.isEmpty) {
                print('Error: Book ID is empty');
                return;
              }
              AppRouter.routeTo(context, BookDetailScreen(book: book));
            } catch (e) {
              print('Error navigating to book detail: $e');
            }
          },
          child: GlobalCard(
            title: book.title,
            author: book.author,
            imageAsset: book.coverImageUrl,
            listenTime: '${book.listenTime}m',
            readTime: '${book.readTime}m',
            book: book,
          ),
        ),
        // Bookmark button overlay
        if (_currentUserId != null)
          Positioned(
            top: 4.h,
            right: 4.w,
            child: BookmarkIconButton(userId: _currentUserId!, book: book),
          ),
      ],
    );
  }

  Widget _buildAudiobookItem(BookModel book, {Map<String, dynamic>? progress}) {
    final hasProgress = progress != null;
    final chapterIndex = progress?['chapterIndex'] as int? ?? 0;
    final chapters = book.chapters ?? [];
    final chapterName = chapters.isNotEmpty && chapterIndex < chapters.length
        ? chapters[chapterIndex]['chapterName'] ?? 'Chapter ${chapterIndex + 1}'
        : null;

    return Stack(
      children: [
        GestureDetector(
          onTap: () {
            try {
              if (book.id.isEmpty) {
                print('Error: Book ID is empty');
                return;
              }
              AppRouter.routeTo(context, BookDetailScreen(book: book));
            } catch (e) {
              print('Error navigating to book detail: $e');
            }
          },
          child: Container(
            margin: EdgeInsets.only(bottom: 16.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Book cover with progress indicator
                Stack(
                  children: [
                    Container(
                      width: 80.w,
                      height: 80.h,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: book.coverImageUrl.startsWith('http')
                              ? NetworkImage(book.coverImageUrl)
                                    as ImageProvider
                              : AssetImage(book.coverImageUrl),
                          fit: BoxFit.cover,
                        ),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                    ),
                    if (hasProgress)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 3.h,
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor.withOpacity(0.3),
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(8.r),
                              bottomRight: Radius.circular(8.r),
                            ),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: chapterIndex < chapters.length
                                ? (chapterIndex + 1) /
                                      (chapters.length > 0
                                          ? chapters.length
                                          : 1)
                                : 0.5,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.primaryColor,
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(8.r),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(width: 16.w),

                // Book details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '${book.listenTime} min',
                            style: AppTextStyles.regular.copyWith(
                              color: AppColors.primaryColor,
                              fontSize: 12.sp,
                            ),
                          ),
                          if (hasProgress && chapterName != null) ...[
                            8.horizontalSpace,
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6.w,
                                vertical: 2.h,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primaryColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                              child: Text(
                                'Resume',
                                style: AppTextStyles.small.copyWith(
                                  color: AppColors.primaryColor,
                                  fontSize: 8.sp,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      4.verticalSpace,
                      Text(
                        book.title,
                        style: AppTextStyles.lufgaMedium.copyWith(
                          color: Colors.white,
                          fontSize: 14.sp,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      4.verticalSpace,
                      Text(
                        book.author,
                        style: AppTextStyles.regular.copyWith(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 10.sp,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (hasProgress && chapterName != null) ...[
                        4.verticalSpace,
                        Text(
                          'Last: $chapterName',
                          style: AppTextStyles.small.copyWith(
                            color: Colors.grey[400],
                            fontSize: 9.sp,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                // Play button
                Container(
                  width: 40.w,
                  height: 40.h,
                  decoration: BoxDecoration(
                    color: AppColors.boxClr,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Icon(
                    hasProgress ? Icons.play_circle : Icons.play_arrow,
                    color: AppColors.primaryColor,
                    size: 24.sp,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Bookmark button overlay - independent widget that manages its own state
        if (_currentUserId != null)
          Positioned(
            top: 4.h,
            right: 4.w,
            child: BookmarkIconButton(userId: _currentUserId!, book: book),
          ),
      ],
    );
  }

  Widget _buildBookCard(BookModel book, {Map<String, dynamic>? progress}) {
    return Stack(
      children: [
        GestureDetector(
          onTap: () {
            try {
              if (book.id.isEmpty) {
                print('Error: Book ID is empty');
                return;
              }
              AppRouter.routeTo(context, BookDetailScreen(book: book));
            } catch (e) {
              print('Error navigating to book detail: $e');
            }
          },
          child: GlobalCard(
            title: book.title,
            author: book.author,
            imageAsset: book.coverImageUrl,
            listenTime: '${book.listenTime}m',
            readTime: '${book.readTime}m',
            book: book,
          ),
        ),
        // Progress indicator overlay
        if (progress != null)
          Padding(
            padding: EdgeInsets.only(left: 4.w, top: 6.h),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(4.r),
              ),
              child: Text(
                'Resume',
                style: AppTextStyles.small.copyWith(
                  color: AppColors.primaryColor,
                  fontSize: 10.sp,
                ),
              ),
            ),
          ),

        if (_currentUserId != null)
          Positioned(
            top: 4.h,
            right: 4.w,
            child: BookmarkIconButton(userId: _currentUserId!, book: book),
          ),
      ],
    );
  }
}
