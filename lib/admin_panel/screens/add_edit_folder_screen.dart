import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:the_woodlands_series/components/button/primary_button.dart';
import 'package:the_woodlands_series/components/resource/app_colors.dart';
import 'package:the_woodlands_series/components/resource/app_textstyle.dart';
import 'package:the_woodlands_series/components/textfield/primary_textfield.dart';
import 'package:the_woodlands_series/components/utils/custom_toast.dart';
import 'package:the_woodlands_series/services/book_service.dart';
import '../models/book_model.dart';

class AddEditFolderScreen extends StatefulWidget {
  final BookModel? folder;

  const AddEditFolderScreen({super.key, this.folder});

  @override
  State<AddEditFolderScreen> createState() => _AddEditFolderScreenState();
}

class _AddEditFolderScreenState extends State<AddEditFolderScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  bool _isPublished = false;
  bool _isLoading = false;
  bool _isFetchingBooks = true;

  List<BookModel> _allBooks = [];
  List<BookModel> _filteredBooks = [];
  final Set<String> _selectedBookIds = {};
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    if (widget.folder != null) {
      _titleController.text = widget.folder!.title;
      _descriptionController.text = widget.folder!.description;
      _isPublished = widget.folder!.isPublished;
      if (widget.folder!.bookIds != null) {
        _selectedBookIds.addAll(widget.folder!.bookIds!);
      }
    }
    _fetchBooks();
  }

  Future<void> _fetchBooks() async {
    setState(() {
      _isFetchingBooks = true;
    });

    try {
      final querySnapshot = await FirebaseFirestore.instance.collection('books').get();
      final books = querySnapshot.docs.map((doc) {
        return BookModel.fromFirestore(doc.id, doc.data());
      }).toList();

      setState(() {
        // Only include e-books that are NOT folders, and exclude current folder document in case of edits
        _allBooks = books
            .where((book) =>
                book.type == BookType.ebook &&
                !book.isFolder &&
                book.id != widget.folder?.id)
            .toList();
        _filteredBooks = _allBooks;
        _isFetchingBooks = false;
      });
    } catch (e) {
      print('Error fetching books: $e');
      setState(() {
        _isFetchingBooks = false;
      });
      if (mounted) {
        CustomToast.showError(context, 'Error loading e-books: $e');
      }
    }
  }

  void _filterBooks(String query) {
    setState(() {
      _searchQuery = query;
      if (query.trim().isEmpty) {
        _filteredBooks = _allBooks;
      } else {
        _filteredBooks = _allBooks
            .where((book) =>
                book.title.toLowerCase().contains(query.toLowerCase()) ||
                book.author.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _saveFolder() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final folderData = BookModel(
        id: widget.folder?.id ?? '',
        title: _titleController.text.trim(),
        author: 'Woodlands Collection',
        description: _descriptionController.text.trim(),
        coverImageUrl: 'folder', // Special identifier for folder rendering
        category: 'Folder',
        type: BookType.ebook,
        readTime: 0,
        listenTime: 0,
        isPublished: _isPublished,
        isFolder: true,
        bookIds: _selectedBookIds.toList(),
        createdAt: widget.folder?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.folder == null) {
        await BookService.addFolder(folderData);
        if (mounted) {
          CustomToast.showSuccess(context, 'Folder created successfully!');
        }
      } else {
        await BookService.updateFolder(widget.folder!.id, folderData);
        if (mounted) {
          CustomToast.showSuccess(context, 'Folder updated successfully!');
        }
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        CustomToast.showError(context, 'Error saving folder: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.folder != null;

    return Scaffold(
      backgroundColor: AppColors.bgClr,
      appBar: AppBar(
        backgroundColor: AppColors.boxClr,
        title: Text(
          isEdit ? 'Edit Folder' : 'Add New Folder',
          style: AppTextStyles.lufgaMedium.copyWith(
            color: Colors.white,
            fontSize: 18.sp,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 768;

          return SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16.w : 20.w),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Folder Information'),
                  16.verticalSpace,

                  PrimaryTextField(
                    controller: _titleController,
                    hint: 'Folder Name',
                    validator: (value) =>
                        value?.isEmpty == true ? 'Folder Name is required' : null,
                  ),
                  16.verticalSpace,

                  PrimaryTextField(
                    controller: _descriptionController,
                    hint: 'Folder Description (Optional)',
                    minlines: 2,
                    maxlines: 4,
                  ),
                  24.verticalSpace,

                  _buildSectionTitle('Select E-books inside this Folder'),
                  8.verticalSpace,
                  Text(
                    'Search and select the e-books to include in this folder collection.',
                    style: AppTextStyles.regular.copyWith(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12.sp,
                    ),
                  ),
                  12.verticalSpace,

                  // Live Search Field
                  PrimaryTextField(
                    controller: _searchController,
                    hint: 'Search e-books...',
                    prefixIcon: Icon(Icons.search, color: AppColors.primaryColor, size: 20.sp),
                    onChanged: _filterBooks,
                  ),
                  12.verticalSpace,

                  // Ebooks List Container
                  Container(
                    height: 280.h,
                    decoration: BoxDecoration(
                      color: AppColors.boxClr,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: _isFetchingBooks
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Colors.orange,
                            ),
                          )
                        : _filteredBooks.isEmpty
                            ? Center(
                                child: Text(
                                  _searchQuery.isEmpty
                                      ? 'No e-books available'
                                      : 'No matching e-books found',
                                  style: AppTextStyles.regular.copyWith(
                                    color: Colors.white.withOpacity(0.5),
                                    fontSize: 14.sp,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                padding: EdgeInsets.symmetric(vertical: 8.h),
                                itemCount: _filteredBooks.length,
                                itemBuilder: (context, index) {
                                  final book = _filteredBooks[index];
                                  final isSelected = _selectedBookIds.contains(book.id);

                                  return CheckboxListTile(
                                    value: isSelected,
                                    activeColor: AppColors.primaryColor,
                                    checkColor: Colors.black,
                                    title: Text(
                                      book.title,
                                      style: AppTextStyles.medium.copyWith(
                                        color: Colors.white,
                                        fontSize: 14.sp,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Text(
                                      book.author,
                                      style: AppTextStyles.regular.copyWith(
                                        color: Colors.white.withOpacity(0.6),
                                        fontSize: 12.sp,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    onChanged: (checked) {
                                      setState(() {
                                        if (checked == true) {
                                          _selectedBookIds.add(book.id);
                                        } else {
                                          _selectedBookIds.remove(book.id);
                                        }
                                      });
                                    },
                                  );
                                },
                              ),
                  ),
                  16.verticalSpace,

                  // Selected books count indicator
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: AppColors.primaryColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.library_books, color: AppColors.primaryColor, size: 16.sp),
                        8.horizontalSpace,
                        Text(
                          '${_selectedBookIds.length} e-books selected for this folder',
                          style: AppTextStyles.medium.copyWith(
                            color: AppColors.primaryColor,
                            fontSize: 12.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  24.verticalSpace,

                  _buildSectionTitle('Publishing Options'),
                  12.verticalSpace,

                  Row(
                    children: [
                      Switch(
                        value: _isPublished,
                        onChanged: (value) {
                          setState(() {
                            _isPublished = value;
                          });
                        },
                        activeColor: AppColors.primaryColor,
                        activeTrackColor: AppColors.primaryColor.withOpacity(0.3),
                      ),
                      8.horizontalSpace,
                      Text(
                        'Publish folder (visible to users)',
                        style: AppTextStyles.medium.copyWith(
                          color: Colors.white,
                          fontSize: 14.sp,
                        ),
                      ),
                    ],
                  ),
                  32.verticalSpace,

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: PrimaryButton(
                      title: _isLoading ? 'Saving...' : 'Save Folder',
                      onTap: _isLoading ? () {} : _saveFolder,
                    ),
                  ),
                  20.verticalSpace,
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.lufgaMedium.copyWith(
        color: AppColors.primaryColor,
        fontSize: 16.sp,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}
