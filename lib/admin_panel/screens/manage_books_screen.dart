import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:the_woodlands_series/components/resource/app_colors.dart';
import 'package:the_woodlands_series/components/resource/app_textstyle.dart';
import 'package:the_woodlands_series/components/textfield/primary_textfield.dart';
import 'package:the_woodlands_series/services/book_service.dart';
import '../models/book_model.dart';
import '../services/firebase_service.dart';
import 'add_book_screen.dart';
import 'edit_book_screen.dart';
import 'add_edit_folder_screen.dart';

class ManageBooksScreen extends StatefulWidget {
  const ManageBooksScreen({super.key});

  @override
  State<ManageBooksScreen> createState() => _ManageBooksScreenState();
}

class _ManageBooksScreenState extends State<ManageBooksScreen> {
  List<BookModel> _books = [];
  List<BookModel> _filteredBooks = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedFilter = 'All';

  final List<String> _filterOptions = ['All', 'Published', 'Draft'];

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final books = await FirebaseService.getAllBooks();
      setState(() {
        _books = books;
        _filteredBooks = books;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showSnackBar('Error loading books: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgClr,
      appBar: AppBar(
        backgroundColor: AppColors.boxClr,
        title: Text(
          'Manage Books',
          style: AppTextStyles.lufgaMedium.copyWith(
            color: Colors.white,
            fontSize: 18.sp,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadBooks,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 768;
          return _buildResponsiveBody(isMobile);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: AppColors.boxClr,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
            ),
            builder: (context) => Container(
              padding: EdgeInsets.all(20.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'What would you like to create?',
                    style: AppTextStyles.lufgaMedium.copyWith(
                      color: Colors.white,
                      fontSize: 16.sp,
                    ),
                  ),
                  20.verticalSpace,
                  ListTile(
                    leading: Icon(Icons.library_books, color: AppColors.primaryColor, size: 24.sp),
                    title: Text(
                      'Add New E-Book',
                      style: AppTextStyles.medium.copyWith(color: Colors.white),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AddBookScreen()),
                      ).then((_) => _loadBooks());
                    },
                  ),
                  Divider(color: Colors.white.withOpacity(0.1)),
                  ListTile(
                    leading: Icon(Icons.folder, color: AppColors.primaryColor, size: 24.sp),
                    title: Text(
                      'Add New Folder',
                      style: AppTextStyles.medium.copyWith(color: Colors.white),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AddEditFolderScreen()),
                      ).then((_) => _loadBooks());
                    },
                  ),
                ],
              ),
            ),
          );
        },
        backgroundColor: AppColors.primaryColor,
        child: Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildResponsiveBody(bool isMobile) {
    return Column(
      children: [
        // Search and Filter Bar
        Container(
          padding: EdgeInsets.all(isMobile ? 12.w : 16.w),
          color: AppColors.boxClr,
          child: Column(
            children: [
              // Search Bar
              PrimaryTextField(
                hint: 'Search books...',
                prefixIcon: Icon(Icons.search, color: AppColors.primaryColor),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                    _filterBooks();
                  });
                },
              ),
              12.verticalSpace,
              
              // Filter Options
              _buildFilterOptions(isMobile),
            ],
          ),
        ),

        // Books List
        Expanded(
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryColor,
                  ),
                )
              : _filteredBooks.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.library_books_outlined,
                            size: 64.sp,
                            color: Colors.white.withOpacity(0.3),
                          ),
                          16.verticalSpace,
                          Text(
                            'No books found',
                            style: AppTextStyles.medium.copyWith(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 16.sp,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _buildBooksList(isMobile),
        ),
      ],
    );
  }

  Widget _buildFilterOptions(bool isMobile) {
    if (isMobile) {
      // Mobile: Single row with scroll
      return SizedBox(
        height: 40.h,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _filterOptions.length,
          itemBuilder: (context, index) {
            final filter = _filterOptions[index];
            final isSelected = _selectedFilter == filter;
            return Container(
              margin: EdgeInsets.only(right: 8.w),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedFilter = filter;
                    _filterBooks();
                  });
                },
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 16.w),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primaryColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: isSelected ? AppColors.primaryColor : Colors.white.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    filter,
                    style: AppTextStyles.small.copyWith(
                      color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
                      fontSize: 12.sp,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    } else {
      // Desktop/Tablet: Row layout
      return Row(
        children: _filterOptions.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedFilter = filter;
                  _filterBooks();
                });
              },
              child: Container(
                margin: EdgeInsets.only(right: 8.w),
                padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: isSelected ? AppColors.primaryColor : Colors.white.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  filter,
                  style: AppTextStyles.small.copyWith(
                    color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
                    fontSize: 12.sp,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }).toList(),
      );
    }
  }

  Widget _buildBooksList(bool isMobile) {
    final bool canReorder = _searchQuery.isEmpty && _selectedFilter == 'All';

    if (canReorder) {
      return ReorderableListView.builder(
        buildDefaultDragHandles: false,
        padding: EdgeInsets.all(12.w),
        itemCount: _filteredBooks.length,
        onReorder: (oldIndex, newIndex) async {
          setState(() {
            if (oldIndex < newIndex) {
              newIndex -= 1;
            }
            final BookModel item = _filteredBooks.removeAt(oldIndex);
            _filteredBooks.insert(newIndex, item);

            // Only sync _books list if they are different instances in memory
            if (!identical(_books, _filteredBooks)) {
              final booksIndex = _books.indexOf(item);
              if (booksIndex != -1) {
                _books.removeAt(booksIndex);
                _books.insert(newIndex, item);
              }
            }
          });

          // Asynchronously save positions to Firestore in the background
          try {
            await BookService.updateBookPositions(_filteredBooks);
          } catch (e) {
            _showSnackBar('Failed to save order: $e');
          }
        },
        itemBuilder: (context, index) {
          final book = _filteredBooks[index];
          return _buildBookCard(book, isMobile, index: index, canReorder: canReorder);
        },
      );
    } else {
      if (isMobile) {
        return ListView.builder(
          padding: EdgeInsets.all(12.w),
          itemCount: _filteredBooks.length,
          itemBuilder: (context, index) {
            final book = _filteredBooks[index];
            return _buildBookCard(book, isMobile, index: index, canReorder: false);
          },
        );
      } else {
        // Desktop/Tablet: Grid layout when search/filters are active
        return GridView.builder(
          padding: EdgeInsets.all(16.w),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.2,
            crossAxisSpacing: 16.w,
            mainAxisSpacing: 16.h,
          ),
          itemCount: _filteredBooks.length,
          itemBuilder: (context, index) {
            final book = _filteredBooks[index];
            return _buildBookCard(book, isMobile, index: index, canReorder: false);
          },
        );
      }
    }
  }

  Widget _buildBookCard(BookModel book, bool isMobile, {required int index, required bool canReorder}) {
    return Container(
      key: ValueKey(book.id),
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.boxClr,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Row(
        children: [
          if (canReorder) ...[
            ReorderableDragStartListener(
              index: index,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                color: Colors.transparent, // Ensures the entire padded region is touch-sensitive
                child: Icon(
                  Icons.drag_indicator,
                  color: Colors.white.withOpacity(0.5),
                  size: 24.sp,
                ),
              ),
            ),
          ],

          // Book Cover Placeholder
          Container(
            width: 60.w,
            height: 80.h,
            decoration: BoxDecoration(
              color: book.isFolder ? Colors.deepPurple.withOpacity(0.2) : AppColors.primaryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(
              book.isFolder ? Icons.folder : Icons.book,
              color: book.isFolder ? Colors.deepPurpleAccent : AppColors.primaryColor,
              size: 24.sp,
            ),
          ),
          16.horizontalSpace,

          // Book Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  style: AppTextStyles.lufgaMedium.copyWith(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                4.verticalSpace,
                Text(
                  book.isFolder ? 'Collection' : book.author,
                  style: AppTextStyles.small.copyWith(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12.sp,
                  ),
                ),
                8.verticalSpace,
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                      decoration: BoxDecoration(
                        color: book.isPublished ? Colors.green : Colors.orange,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        book.isPublished ? 'Published' : 'Draft',
                        style: AppTextStyles.small.copyWith(
                          color: Colors.white,
                          fontSize: 10.sp,
                        ),
                      ),
                    ),
                    8.horizontalSpace,
                    if (book.isFolder) ...[
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          '${book.bookIds?.length ?? 0} Books',
                          style: AppTextStyles.small.copyWith(
                            color: Colors.white,
                            fontSize: 10.sp,
                          ),
                        ),
                      ),
                      8.horizontalSpace,
                    ],
                    Text(
                      book.category,
                      style: AppTextStyles.small.copyWith(
                        color: book.isFolder ? Colors.purpleAccent : AppColors.primaryColor,
                        fontSize: 10.sp,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Action Buttons
          Column(
            children: [
              IconButton(
                onPressed: () => _editBook(book),
                icon: Icon(Icons.edit, color: AppColors.primaryColor, size: 20.sp),
              ),
              IconButton(
                onPressed: () => _deleteBook(book),
                icon: Icon(Icons.delete, color: Colors.red, size: 20.sp),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _filterBooks() {
    setState(() {
      _filteredBooks = _books.where((book) {
        final matchesSearch = book.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                            book.author.toLowerCase().contains(_searchQuery.toLowerCase());
        
        final matchesFilter = _selectedFilter == 'All' ||
                            (_selectedFilter == 'Published' && book.isPublished) ||
                            (_selectedFilter == 'Draft' && !book.isPublished);
        
        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  void _editBook(BookModel book) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => book.isFolder
            ? AddEditFolderScreen(folder: book)
            : EditBookScreen(book: book),
      ),
    ).then((updated) {
      if (updated == true) {
        _loadBooks();
      }
    });
  }

  void _deleteBook(BookModel book) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.boxClr,
        title: Text(
          'Delete Book',
          style: AppTextStyles.lufgaMedium.copyWith(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete "${book.title}"?',
          style: AppTextStyles.regular.copyWith(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await FirebaseService.deleteBook(book.id);
                _showSnackBar('Book deleted successfully!');
                _loadBooks();
              } catch (e) {
                _showSnackBar('Error deleting book: $e');
              }
            },
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primaryColor,
      ),
    );
  }
}
