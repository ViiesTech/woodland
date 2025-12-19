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
import 'package:the_woodlands_series/services/search_history_service.dart';
import 'package:the_woodlands_series/screens/book_detail/book_detail_screen.dart';
import 'package:the_woodlands_series/components/resource/app_routers.dart';
import 'package:the_woodlands_series/bloc/auth/auth_bloc.dart';
import 'package:the_woodlands_series/bloc/auth/auth_state.dart';
import 'package:the_woodlands_series/components/button/bookmark_icon_button.dart';
import 'package:the_woodlands_series/services/purchase_service.dart';

class EbookPage extends StatefulWidget {
  const EbookPage({super.key});

  @override
  State<EbookPage> createState() => _EbookPageState();
}

class _EbookPageState extends State<EbookPage>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _currentUserId;
  List<BookModel> _recentSearchBooks = [];
  bool _isLoadingRecentSearches = false;
  Map<String, bool> _ownedBooks = {}; // Map of bookId -> isOwned

  @override
  void initState() {
    super.initState();
    _getCurrentUserId();
    _loadRecentSearches();
    _loadOwnedBooks();
  }

  void _loadOwnedBooks() {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      _currentUserId = authState.user.id;
      PurchaseService.getPurchasedBooksStream(_currentUserId!).listen((
        bookIds,
      ) {
        if (mounted) {
          setState(() {
            _ownedBooks = {for (var id in bookIds) id: true};
          });
        }
      });
    }
  }

  void _getCurrentUserId() {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      _currentUserId = authState.user.id;
    }
  }

  Future<void> _loadRecentSearches() async {
    final searches = await SearchHistoryService.getRecentSearches();
    if (mounted && searches.isNotEmpty) {
      setState(() {
        _isLoadingRecentSearches = true;
      });
      // Load books from all recent searches and combine them
      await _loadBooksFromRecentSearches(searches);
    }
  }

  Future<void> _loadBooksFromRecentSearches(List<String> searchQueries) async {
    try {
      final authState = context.read<AuthBloc>().state;
      final isAdmin =
          authState is Authenticated && authState.user.role == 'admin';

      List<BookModel> allBooks = [];
      Set<String> addedBookIds = {}; // Track IDs to avoid duplicates

      // Load books from each search query in order (most recent first)
      for (String searchQuery in searchQueries) {
        if (allBooks.length >= 5) break; // Stop if we have 5 books

        try {
          final stream = isAdmin
              ? BookService.searchAllBooks(searchQuery, BookType.ebook)
              : BookService.searchBooks(searchQuery, BookType.ebook);

          final snapshot = await stream.first;

          // Add books from this search, avoiding duplicates
          for (var book in snapshot) {
            if (!addedBookIds.contains(book.id) && allBooks.length < 5) {
              allBooks.add(book);
              addedBookIds.add(book.id);
              if (allBooks.length >= 5) break;
            }
          }
        } catch (e) {
          print('Error loading books for search "$searchQuery": $e');
          // Continue with next search even if one fails
        }
      }

      if (mounted) {
        setState(() {
          _recentSearchBooks = allBooks;
          _isLoadingRecentSearches = false;
        });
      }
    } catch (e) {
      print('Error loading recent search books: $e');
      if (mounted) {
        setState(() {
          _isLoadingRecentSearches = false;
        });
      }
    }
  }

  Future<void> _clearRecentSearches() async {
    await SearchHistoryService.clearRecentSearches();
    if (mounted) {
      setState(() {
        _recentSearchBooks = [];
      });
    }
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
                  // Reload recent searches when search is cleared
                  if (value.trim().isEmpty) {
                    _loadRecentSearches();
                  }
                },
              ),
            ),
            16.verticalSpace,
            Expanded(
              child: StreamBuilder<List<BookModel>>(
                stream: _searchQuery.isEmpty
                    ? (isAdmin
                          ? BookService.getAllBooksByType(BookType.ebook)
                          : BookService.getBooksByType(BookType.ebook))
                    : (isAdmin
                          ? BookService.searchAllBooks(
                              _searchQuery,
                              BookType.ebook,
                            )
                          : BookService.searchBooks(
                              _searchQuery,
                              BookType.ebook,
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
                        'Error loading books',
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
                            ? 'No ebooks available'
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
                          // Recent Searches Section
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Recent Searches',
                                  style: AppTextStyles.lufgaLarge.copyWith(
                                    color: Colors.white,
                                    fontSize: 20.sp,
                                  ),
                                ),
                                if (_recentSearchBooks.isNotEmpty)
                                  GestureDetector(
                                    onTap: _clearRecentSearches,
                                    child: Text(
                                      'Clear',
                                      style: AppTextStyles.regular.copyWith(
                                        color: AppColors.primaryColor,
                                        fontSize: 14.sp,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          16.verticalSpace,
                          if (_isLoadingRecentSearches)
                            SizedBox(
                              height: 200.h,
                              child: Center(
                                child: ThreeDotLoader(
                                  color: AppColors.primaryColor,
                                  size: 12.w,
                                  spacing: 8.w,
                                ),
                              ),
                            )
                          else if (_recentSearchBooks.isEmpty)
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16.w),
                              child: Text(
                                'No recent searches',
                                style: AppTextStyles.regular.copyWith(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 14.sp,
                                ),
                              ),
                            )
                          else
                            SizedBox(
                              height: 200.h,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _recentSearchBooks.length,
                                padding: EdgeInsets.symmetric(horizontal: 16.w),
                                itemBuilder: (context, index) {
                                  final book = _recentSearchBooks[index];
                                  return Container(
                                    margin: EdgeInsets.only(right: 16.w),
                                    child: _buildBookCard(book),
                                  );
                                },
                              ),
                            ),
                          26.verticalSpace,
                          // New Release Section
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            child: Text(
                              'New Release',
                              style: AppTextStyles.lufgaLarge.copyWith(
                                color: Colors.white,
                                fontSize: 20.sp,
                              ),
                            ),
                          ),
                          16.verticalSpace,
                        ],
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
                                  childAspectRatio: isAdmin ? 0.48 : 0.52,
                                ),
                            itemCount: books.length,
                            itemBuilder: (context, index) {
                              final book = books[index];
                              return _buildBookCard(book);
                            },
                          ),
                        ),
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

  Widget _buildBookCard(BookModel book) {
    // Check if book is owned: either in owned list OR price is 0 (free)
    final isInOwnedList = _ownedBooks[book.id] == true;
    final isOwned = isInOwnedList || book.price == 0;

    return Stack(
      children: [
        GestureDetector(
          onTap: () async {
            try {
              if (book.id.isEmpty) {
                print('Error: Book ID is empty');
                return;
              }
              // Save search query to recent searches when user opens a book from search results
              final searchQueryToSave = _searchQuery.trim();
              if (searchQueryToSave.isNotEmpty) {
                await SearchHistoryService.addSearchQuery(searchQueryToSave);
                // Clear search field
                setState(() {
                  _searchQuery = '';
                  _searchController.clear();
                });
                // Reload recent searches to show updated list
                await _loadRecentSearches();
              }
              if (mounted) {
                AppRouter.routeTo(context, BookDetailScreen(book: book));
              }
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
        // Price overlay or OWNED badge
        if (isOwned)
          Positioned(
            left: 2.w,
            right: 2.w,
            top: 94.h,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(4.r),
              ),
              child: Text(
                'OWNED',
                style: AppTextStyles.small.copyWith(
                  color: AppColors.primaryColor,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          Positioned(
            left: 2.w,
            right: 2.w,
            top: 94.h,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(4.r),
              ),
              child: Text(
                '\$${book.price.toStringAsFixed(2)}',
                style: AppTextStyles.small.copyWith(
                  color: Colors.white,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
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
}
