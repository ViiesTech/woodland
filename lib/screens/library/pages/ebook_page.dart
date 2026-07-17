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
import 'package:the_woodlands_series/admin_panel/screens/add_edit_folder_screen.dart';

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
  bool _isReorderMode = false;
  List<BookModel> _localBooks = [];
  String _selectedLanguage = 'All';

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

  Widget _buildLanguageDropdown() {
    return Container(
      height: 55.h,
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: AppColors.boxClr,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedLanguage,
          dropdownColor: AppColors.boxClr,
          icon: Icon(Icons.keyboard_arrow_down, color: Colors.white.withOpacity(0.6), size: 20.sp),
          style: AppTextStyles.medium.copyWith(
            color: Colors.white,
            fontSize: 14.sp,
          ),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _selectedLanguage = newValue;
              });
            }
          },
          items: <String>['All', 'English', 'Spanish', 'German', 'Mandarin']
              .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    value == 'All' ? Icons.language : Icons.translate,
                    color: AppColors.primaryColor,
                    size: 16.sp,
                  ),
                  8.horizontalSpace,
                  Text(value),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildLanguageDropdownForModal(String currentLang, ValueSetter<String> onChanged) {
    return Container(
      height: 40.h,
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      decoration: BoxDecoration(
        color: AppColors.boxClr,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currentLang,
          dropdownColor: AppColors.boxClr,
          icon: Icon(Icons.keyboard_arrow_down, color: Colors.white.withOpacity(0.6), size: 16.sp),
          style: AppTextStyles.medium.copyWith(
            color: Colors.white,
            fontSize: 12.sp,
          ),
          onChanged: (String? newValue) {
            if (newValue != null) {
              onChanged(newValue);
            }
          },
          items: <String>['All', 'English', 'Spanish', 'German', 'Mandarin']
              .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    value == 'All' ? Icons.language : Icons.translate,
                    color: AppColors.primaryColor,
                    size: 14.sp,
                  ),
                  6.horizontalSpace,
                  Text(value),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

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
              child: Row(
                children: [
                  Expanded(
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
                  12.horizontalSpace,
                  _buildLanguageDropdown(),
                ],
              ),
            ),
            16.verticalSpace,
            Expanded(
              child: StreamBuilder<List<BookModel>>(
                stream: _searchQuery.isEmpty
                    ? BookService.getEbooksAndFoldersStream(isAdmin: isAdmin)
                    : BookService.searchEbooksAndFoldersStream(
                        _searchQuery,
                        isAdmin: isAdmin,
                      ),
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

                  var books = snapshot.data ?? [];
                  if (_selectedLanguage != 'All') {
                    books = books.where((book) => book.language == _selectedLanguage).toList();
                  }

                  if (_isReorderMode) {
                    if (_localBooks.isEmpty || _localBooks.length != books.length) {
                      _localBooks = List.from(books);
                    }
                  } else {
                    _localBooks = [];
                  }

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

                  if (_isReorderMode) {
                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Rearrange E-books',
                                  style: AppTextStyles.lufgaLarge.copyWith(
                                    color: Colors.white,
                                    fontSize: 20.sp,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.done,
                                    color: Colors.green,
                                    size: 24.sp,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isReorderMode = false;
                                    });
                                  },
                                  tooltip: 'Done Reordering',
                                ),
                              ],
                            ),
                          ),
                          ReorderableListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            buildDefaultDragHandles: false,
                            onReorder: (oldIndex, newIndex) async {
                              setState(() {
                                if (oldIndex < newIndex) {
                                  newIndex -= 1;
                                }
                                final item = _localBooks.removeAt(oldIndex);
                                _localBooks.insert(newIndex, item);
                              });
                              try {
                                await BookService.updateBookPositions(_localBooks);
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed to save order: $e')),
                                );
                              }
                            },
                            itemCount: _localBooks.length,
                            itemBuilder: (context, index) {
                              final book = _localBooks[index];
                              return _buildReorderableBookRow(book, index);
                            },
                          ),
                          26.verticalSpace,
                        ],
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
                                itemCount: _recentSearchBooks
                                    .where((book) => _selectedLanguage == 'All' || book.language == _selectedLanguage)
                                    .length,
                                padding: EdgeInsets.symmetric(horizontal: 16.w),
                                itemBuilder: (context, index) {
                                  final filteredRecent = _recentSearchBooks
                                      .where((book) => _selectedLanguage == 'All' || book.language == _selectedLanguage)
                                      .toList();
                                  final book = filteredRecent[index];
                                  return Container(
                                    margin: EdgeInsets.only(right: 16.w),
                                    child: _buildBookCard(book, isAdmin),
                                  );
                                },
                              ),
                            ),
                          26.verticalSpace,
                          // New Release Section
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'New Release',
                                  style: AppTextStyles.lufgaLarge.copyWith(
                                    color: Colors.white,
                                    fontSize: 20.sp,
                                  ),
                                ),
                                if (isAdmin) ...[
                                  IconButton(
                                    icon: Icon(
                                      Icons.swap_vert,
                                      color: AppColors.primaryColor,
                                      size: 24.sp,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isReorderMode = true;
                                        _localBooks = List.from(books);
                                      });
                                    },
                                    tooltip: 'Rearrange Books & Folders',
                                  ),
                                ],
                              ],
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
                              return _buildBookCard(book, isAdmin);
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

  void _showFolderBooksModal(BuildContext context, BookModel folder, bool isAdmin) {
    // Increment the view count for the folder
    BookService.incrementViewCount(folder.id);

    String localSelectedLanguage = _selectedLanguage;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgClr,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (context) {
        final bookIds = folder.bookIds ?? [];
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.4,
              maxChildSize: 0.95,
              expand: false,
              builder: (context, scrollController) {
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40.w,
                          height: 5.h,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                        ),
                      ),
                      16.verticalSpace,
                      Row(
                        children: [
                          Icon(
                            Icons.folder_open,
                            color: AppColors.primaryColor,
                            size: 28.sp,
                          ),
                          12.horizontalSpace,
                          Expanded(
                            child: Text(
                              folder.title,
                              style: AppTextStyles.lufgaLarge.copyWith(
                                color: Colors.white,
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          12.horizontalSpace,
                          _buildLanguageDropdownForModal(localSelectedLanguage, (newValue) {
                            setModalState(() {
                              localSelectedLanguage = newValue;
                            });
                          }),
                          if (isAdmin) ...[
                            IconButton(
                              icon: Icon(Icons.edit, color: AppColors.primaryColor, size: 20.sp),
                              tooltip: 'Edit Folder',
                              onPressed: () async {
                                Navigator.pop(context); // Close the sheet
                                await AppRouter.routeTo(
                                  context,
                                  AddEditFolderScreen(folder: folder),
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                      if (folder.description.isNotEmpty) ...[
                        8.verticalSpace,
                        Text(
                          folder.description,
                          style: AppTextStyles.regular.copyWith(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12.sp,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      16.verticalSpace,
                      Divider(color: Colors.white.withOpacity(0.1)),
                      16.verticalSpace,
                      Expanded(
                        child: bookIds.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.library_books,
                                      color: Colors.white.withOpacity(0.2),
                                      size: 48.sp,
                                    ),
                                    12.verticalSpace,
                                    Text(
                                      'This folder is empty',
                                      style: AppTextStyles.medium.copyWith(
                                        color: Colors.white.withOpacity(0.5),
                                        fontSize: 14.sp,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : StreamBuilder<List<BookModel>>(
                                stream: BookService.getAllPublishedBooks(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting &&
                                      !snapshot.hasData) {
                                    return const Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.orange,
                                      ),
                                    );
                                  }
                                  if (snapshot.hasError) {
                                    return Center(
                                      child: Text(
                                        'Error loading books',
                                        style: AppTextStyles.regular.copyWith(
                                          color: Colors.white.withOpacity(0.5),
                                          fontSize: 12.sp,
                                        ),
                                      ),
                                    );
                                  }
                                  
                                  final allBooks = snapshot.data ?? [];
                                  var folderBooks = allBooks
                                      .where((book) => bookIds.contains(book.id))
                                      .toList();

                                  if (localSelectedLanguage != 'All') {
                                    folderBooks = folderBooks
                                        .where((book) => book.language == localSelectedLanguage)
                                        .toList();
                                  }

                                  if (folderBooks.isEmpty) {
                                    return Center(
                                      child: Text(
                                        'No books available in this folder',
                                        style: AppTextStyles.regular.copyWith(
                                          color: Colors.white.withOpacity(0.5),
                                          fontSize: 12.sp,
                                        ),
                                      ),
                                    );
                                  }

                                  return GridView.builder(
                                    controller: scrollController,
                                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      crossAxisSpacing: 12.w,
                                      mainAxisSpacing: 16.h,
                                      childAspectRatio: 0.52,
                                    ),
                                    itemCount: folderBooks.length,
                                    itemBuilder: (context, index) {
                                      final book = folderBooks[index];
                                      return _buildBookCard(book, isAdmin);
                                    },
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildBookCard(BookModel book, bool isAdmin) {
    if (book.isFolder) {
      return GestureDetector(
        onTap: () => _showFolderBooksModal(context, book, isAdmin),
        child: GlobalCard(
          title: book.title,
          author: book.author,
          imageAsset: book.coverImageUrl,
          listenTime: '${book.listenTime}m',
          readTime: '${book.readTime}m',
          book: book,
        ),
      );
    }

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

  Widget _buildReorderableBookRow(BookModel book, int index) {
    return Container(
      key: ValueKey(book.id),
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.boxClr,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
        ),
      ),
      child: Row(
        children: [
          // Drag Handle
          ReorderableDragStartListener(
            index: index,
            child: Padding(
              padding: EdgeInsets.only(right: 12.w),
              child: Icon(
                Icons.drag_indicator,
                color: Colors.white.withOpacity(0.5),
                size: 24.sp,
              ),
            ),
          ),
          
          // Book cover
          Container(
            width: 45.w,
            height: 60.h,
            decoration: BoxDecoration(
              color: book.isFolder ? Colors.deepPurple.withOpacity(0.2) : AppColors.primaryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6.r),
            ),
            child: Icon(
              book.isFolder ? Icons.folder : Icons.book,
              color: book.isFolder ? Colors.deepPurpleAccent : AppColors.primaryColor,
              size: 20.sp,
            ),
          ),
          12.horizontalSpace,
          
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  style: AppTextStyles.lufgaMedium.copyWith(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                4.verticalSpace,
                Text(
                  book.isFolder ? 'Collection' : book.author,
                  style: AppTextStyles.regular.copyWith(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 11.sp,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          
          // Status Badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: book.isPublished ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: book.isPublished ? Colors.green.withOpacity(0.3) : Colors.orange.withOpacity(0.3),
              ),
            ),
            child: Text(
              book.isPublished ? 'Published' : 'Draft',
              style: AppTextStyles.small.copyWith(
                color: book.isPublished ? Colors.green : Colors.orange,
                fontSize: 10.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
