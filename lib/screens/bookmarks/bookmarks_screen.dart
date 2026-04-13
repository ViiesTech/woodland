import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:the_woodlands_series/components/card/global_card.dart';
import 'package:the_woodlands_series/components/resource/app_colors.dart';
import 'package:the_woodlands_series/components/resource/app_textstyle.dart';
import 'package:the_woodlands_series/components/utils/three_dot_loader.dart';
import 'package:the_woodlands_series/admin_panel/models/book_model.dart';
import 'package:the_woodlands_series/services/book_service.dart';
import 'package:the_woodlands_series/services/bookmark_service.dart';
import 'package:the_woodlands_series/screens/book_detail/book_detail_screen.dart';
import 'package:the_woodlands_series/components/resource/app_routers.dart';
import 'package:the_woodlands_series/bloc/auth/auth_bloc.dart';
import 'package:the_woodlands_series/bloc/auth/auth_state.dart';
import 'package:the_woodlands_series/components/utils/custom_toast.dart';
import 'package:the_woodlands_series/screens/library/widgets/custom_tab_widget.dart';

class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  String? _currentUserId;
  final Map<String, BookModel> _bookmarkedBooks = {};
  bool _isLoading = true;
  int _selectedTabIndex = 0; // 0 for E-book, 1 for Audiobook

  @override
  void initState() {
    super.initState();
    _loadUserAndBookmarks();
  }

  void _loadUserAndBookmarks() {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      _currentUserId = authState.user.id;
      _listenToBookmarks();
    }
  }

  void _listenToBookmarks() {
    if (_currentUserId == null) return;

    BookmarkService.getUserBookmarks(_currentUserId!).listen((bookmarks) {
      if (mounted) {
        // Get list of bookmark IDs from stream
        final bookmarkIds = bookmarks
            .map((b) => b['bookId'] as String? ?? b['id'] as String)
            .toSet();

        // Handle removals instantly (synchronously) - no flash
        final removedIds = _bookmarkedBooks.keys
            .where((id) => !bookmarkIds.contains(id))
            .toList();

        // Handle additions - check if we have new bookmarks
        final newBookmarkIds = bookmarkIds
            .where((id) => !_bookmarkedBooks.containsKey(id))
            .toList();

        // Only show loader on first load (when list is empty)
        final isFirstLoad = _bookmarkedBooks.isEmpty && _isLoading;

        if (isFirstLoad) {
          // First load - fetch all book details
          _fetchBookDetailsForNewBookmarks(newBookmarkIds, showLoader: true);
        } else if (removedIds.isNotEmpty || newBookmarkIds.isNotEmpty) {
          // Handle removals instantly (synchronous update)
          if (removedIds.isNotEmpty) {
            setState(() {
              for (var id in removedIds) {
                _bookmarkedBooks.remove(id);
              }
            });
          }

          // Handle additions asynchronously (if any)
          if (newBookmarkIds.isNotEmpty) {
            _fetchBookDetailsForNewBookmarks(newBookmarkIds, showLoader: false);
          }
        }
      }
    });
  }

  Future<void> _fetchBookDetailsForNewBookmarks(
    List<String> bookmarkIds, {
    bool showLoader = false,
  }) async {
    if (showLoader) {
      setState(() {
        _isLoading = true;
      });
    }

    final Map<String, BookModel> newBooks = {};

    for (var bookId in bookmarkIds) {
      try {
        final book = await BookService.getBookById(bookId);
        if (book != null) {
          newBooks[bookId] = book;
        }
      } catch (e) {
        print('Error fetching book $bookId: $e');
      }
    }

    if (mounted && newBooks.isNotEmpty) {
      setState(() {
        _bookmarkedBooks.addAll(newBooks);
        _isLoading = false;
      });
    } else if (mounted && showLoader) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _removeBookmark(String bookId) async {
    if (_currentUserId == null) return;

    try {
      // Remove from Firebase - the stream will automatically update the UI
      await BookmarkService.removeBookmark(
        userId: _currentUserId!,
        bookId: bookId,
      );
      // Success toast will be shown after Firebase stream updates the UI
      // No need to manually update state - Firebase stream handles it
    } catch (e) {
      // Only show error if removal fails - stream will keep UI in sync
      if (mounted) {
        CustomToast.showError(context, 'Error removing bookmark: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgClr,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => AppRouter.routeBack(context),
          icon: Icon(Icons.arrow_back_ios, color: Colors.white, size: 20.sp),
        ),
        centerTitle: true,
        title: Text(
          'My Bookmarks',
          style: AppTextStyles.lufgaLarge.copyWith(
            color: Colors.white,
            fontSize: 20.sp,
          ),
        ),
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is! Authenticated) {
            return Center(
              child: Text(
                'Please login to view bookmarks',
                style: AppTextStyles.regular.copyWith(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 14.sp,
                ),
              ),
            );
          }

          if (_isLoading) {
            return Center(
              child: ThreeDotLoader(
                color: AppColors.primaryColor,
                size: 12.w,
                spacing: 8.w,
              ),
            );
          }

          final books = _bookmarkedBooks.values.toList();

          // Separate books by type - ensure proper filtering
          final ebooks = books.where((book) {
            final isEbook = book.type == BookType.ebook;
            return isEbook;
          }).toList();

          final audiobooks = books.where((book) {
            final isAudiobook = book.type == BookType.audiobook;
            return isAudiobook;
          }).toList();

          // Determine if we should show tabs (both types have at least one bookmark)
          final shouldShowTabs = ebooks.isNotEmpty && audiobooks.isNotEmpty;

          // Determine which books to show based on tab selection
          List<BookModel> booksToShow;
          String sectionTitle;

          if (shouldShowTabs) {
            // Show filtered books based on selected tab - ONLY show one type at a time
            if (_selectedTabIndex == 0) {
              // Show ONLY ebooks
              booksToShow = List<BookModel>.from(ebooks);
              sectionTitle = 'Bookmarked E-books (${ebooks.length})';
            } else {
              // Show ONLY audiobooks
              booksToShow = List<BookModel>.from(audiobooks);
              sectionTitle = 'Bookmarked Audiobooks (${audiobooks.length})';
            }
          } else if (ebooks.isNotEmpty) {
            // Only ebooks exist, show them (no tabs)
            booksToShow = List<BookModel>.from(ebooks);
            sectionTitle = 'Bookmarked E-books (${ebooks.length})';
          } else if (audiobooks.isNotEmpty) {
            // Only audiobooks exist, show them (no tabs)
            booksToShow = List<BookModel>.from(audiobooks);
            sectionTitle = 'Bookmarked Audiobooks (${audiobooks.length})';
          } else {
            // No bookmarks at all
            booksToShow = <BookModel>[];
            sectionTitle = '';
          }

          return Column(
            children: [
              // Custom Tab Widget - only show if both types have bookmarks
              if (shouldShowTabs) ...[
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: CustomTabWidget(
                    selectedIndex: _selectedTabIndex,
                    onTabChanged: (index) {
                      setState(() {
                        _selectedTabIndex = index;
                      });
                    },
                    tabs: ['E-book', 'Audiobook'],
                  ),
                ),
                20.verticalSpace,
              ],

              // Content
              if (booksToShow.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bookmark_border,
                          color: Colors.white.withOpacity(0.3),
                          size: 64.sp,
                        ),
                        16.verticalSpace,
                        Text(
                          shouldShowTabs
                              ? (_selectedTabIndex == 0
                                    ? 'No ebooks bookmarked yet'
                                    : 'No audiobooks bookmarked yet')
                              : 'No bookmarks yet',
                          style: AppTextStyles.lufgaLarge.copyWith(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 18.sp,
                          ),
                        ),
                        8.verticalSpace,
                        Text(
                          shouldShowTabs
                              ? 'Start bookmarking ${_selectedTabIndex == 0 ? 'ebooks' : 'audiobooks'} to see them here'
                              : 'Start bookmarking books to see them here',
                          style: AppTextStyles.regular.copyWith(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 14.sp,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sectionTitle,
                          style: AppTextStyles.lufgaLarge.copyWith(
                            color: Colors.white,
                            fontSize: 18.sp,
                          ),
                        ),
                        16.verticalSpace,
                        GridView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 16.w,
                                mainAxisSpacing: 16.h,
                                childAspectRatio: 0.45,
                              ),
                          itemCount: booksToShow.length,
                          itemBuilder: (context, index) {
                            final book = booksToShow[index];
                            return Stack(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    try {
                                      if (book.id.isEmpty) {
                                        print('Error: Book ID is empty');
                                        return;
                                      }
                                      AppRouter.routeTo(
                                        context,
                                        BookDetailScreen(book: book),
                                      );
                                    } catch (e) {
                                      print(
                                        'Error navigating to book detail: $e',
                                      );
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
                                // Remove bookmark button
                                Positioned(
                                  top: 4.h,
                                  right: 4.w,
                                  child: GestureDetector(
                                    onTap: () => _removeBookmark(book.id),
                                    child: Container(
                                      padding: EdgeInsets.all(4.w),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.6),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.bookmark,
                                        color: AppColors.primaryColor,
                                        size: 16.sp,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        26.verticalSpace,
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
