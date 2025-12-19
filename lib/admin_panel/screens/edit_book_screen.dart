import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:the_woodlands_series/components/button/primary_button.dart';
import 'package:the_woodlands_series/components/resource/app_colors.dart';
import 'package:the_woodlands_series/components/resource/app_textstyle.dart';
import 'package:the_woodlands_series/components/textfield/primary_textfield.dart';
import 'package:the_woodlands_series/components/utils/custom_toast.dart';
import 'package:the_woodlands_series/services/cloudinary_service.dart';
import 'package:the_woodlands_series/services/book_service.dart';
import '../models/book_model.dart';

class EditBookScreen extends StatefulWidget {
  final BookModel book;

  const EditBookScreen({super.key, required this.book});

  @override
  State<EditBookScreen> createState() => _EditBookScreenState();
}

class _EditBookScreenState extends State<EditBookScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _authorController;
  late TextEditingController _descriptionController;
  late TextEditingController _coverImageController;
  late TextEditingController _audioFileController;
  late TextEditingController _priceController;

  String _selectedCategory = 'Fiction';
  late BookType _selectedType;
  bool _isLoading = false;

  // File selection (not uploaded until save)
  File? _coverImageFile;
  File? _pdfFile;
  String? _coverImageUrl; // Will be set after upload
  String? _pdfUrl; // Will be set after upload

  late List<String> _categories;

  @override
  void initState() {
    super.initState();
    // Initialize categories list
    _categories = [
      'Fiction',
      'Non-Fiction',
      'Fantasy',
      'Adventure',
      'Mystery',
      'Romance',
      'Science Fiction',
    ];

    // Initialize controllers with existing book data
    _titleController = TextEditingController(text: widget.book.title);
    _authorController = TextEditingController(text: widget.book.author);
    _descriptionController = TextEditingController(
      text: widget.book.description,
    );
    _coverImageController = TextEditingController(
      text: widget.book.coverImageUrl,
    );
    _audioFileController = TextEditingController(
      text: widget.book.audioFileUrl ?? '',
    );
    _priceController = TextEditingController(
      text: widget.book.price.toStringAsFixed(2),
    );

    // Handle category - if book category is not in list, add it
    final bookCategory = widget.book.category.isNotEmpty
        ? widget.book.category
        : _categories[0];

    // If the book's category is not in the predefined list, add it
    if (!_categories.contains(bookCategory)) {
      _categories.add(bookCategory);
    }

    _selectedCategory = bookCategory;
    _selectedType = widget.book.type;
    _coverImageUrl = widget.book.coverImageUrl.isNotEmpty
        ? widget.book.coverImageUrl
        : null;
    _pdfUrl = widget.book.pdfUrl;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _descriptionController.dispose();
    _coverImageController.dispose();
    _audioFileController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgClr,
      appBar: AppBar(
        backgroundColor: AppColors.boxClr,
        title: Text(
          'Edit Book',
          style: AppTextStyles.lufgaMedium.copyWith(
            color: Colors.white,
            fontSize: 18.sp,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
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
                  // Basic Information
                  _buildSectionTitle('Basic Information'),
                  16.verticalSpace,

                  // Title Field
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Book Title *',
                        style: AppTextStyles.lufgaMedium.copyWith(
                          color: Colors.white,
                          fontSize: 14.sp,
                        ),
                      ),
                      8.verticalSpace,
                      PrimaryTextField(
                        controller: _titleController,
                        hint: 'Enter book title',
                        validator: (value) =>
                            value?.isEmpty == true ? 'Title is required' : null,
                      ),
                    ],
                  ),
                  16.verticalSpace,

                  // Author Field
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Author Name *',
                        style: AppTextStyles.lufgaMedium.copyWith(
                          color: Colors.white,
                          fontSize: 14.sp,
                        ),
                      ),
                      8.verticalSpace,
                      PrimaryTextField(
                        controller: _authorController,
                        hint: 'Enter author name',
                        validator: (value) => value?.isEmpty == true
                            ? 'Author is required'
                            : null,
                      ),
                    ],
                  ),
                  16.verticalSpace,

                  // Description Field
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Book Description *',
                        style: AppTextStyles.lufgaMedium.copyWith(
                          color: Colors.white,
                          fontSize: 14.sp,
                        ),
                      ),
                      8.verticalSpace,
                      PrimaryTextField(
                        controller: _descriptionController,
                        hint: 'Enter book description',
                        minlines: 5,
                        maxlines: 10,
                        validator: (value) => value?.isEmpty == true
                            ? 'Description is required'
                            : null,
                      ),
                    ],
                  ),
                  16.verticalSpace,

                  // Book Type Display (Read-only, cannot be changed)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Book Type',
                        style: AppTextStyles.lufgaMedium.copyWith(
                          color: Colors.white,
                          fontSize: 14.sp,
                        ),
                      ),
                      8.verticalSpace,
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        decoration: BoxDecoration(
                          color: AppColors.boxClr,
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(color: Colors.grey[800]!),
                        ),
                        child: Text(
                          _selectedType == BookType.ebook
                              ? 'E-book'
                              : 'Audiobook',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.medium.copyWith(
                            color: Colors.white,
                            fontSize: 14.sp,
                          ),
                        ),
                      ),
                    ],
                  ),
                  16.verticalSpace,

                  // Category Dropdown
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Category',
                        style: AppTextStyles.lufgaMedium.copyWith(
                          color: Colors.white,
                          fontSize: 14.sp,
                        ),
                      ),
                      8.verticalSpace,
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 0.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.boxClr,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedCategory,
                            isExpanded: true,
                            style: AppTextStyles.regular.copyWith(
                              color: Colors.white,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w400,
                            ),
                            dropdownColor: AppColors.boxClr,
                            items: _categories.map((category) {
                              return DropdownMenuItem<String>(
                                value: category,
                                child: Text(
                                  category,
                                  style: AppTextStyles.regular.copyWith(
                                    color: Colors.white,
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedCategory = value!;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  16.verticalSpace,

                  // Price Field
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Price (USD) *',
                        style: AppTextStyles.lufgaMedium.copyWith(
                          color: Colors.white,
                          fontSize: 14.sp,
                        ),
                      ),
                      8.verticalSpace,
                      PrimaryTextField(
                        controller: _priceController,
                        hint: 'Enter price in USD',
                        keyboard: TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Price is required';
                          }
                          final price = double.tryParse(value);
                          if (price == null || price < 0) {
                            return 'Please enter a valid price';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                  24.verticalSpace,

                  // Media Files
                  _buildSectionTitle('Media Files'),
                  16.verticalSpace,

                  // Cover Image Upload
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Cover Image *',
                        style: AppTextStyles.lufgaMedium.copyWith(
                          color: Colors.white,
                          fontSize: 14.sp,
                        ),
                      ),
                      8.verticalSpace,
                      GestureDetector(
                        onTap: _pickCoverImage,
                        child: Container(
                          height: 150.h,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.boxClr,
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(color: Colors.grey[800]!),
                          ),
                          child: _coverImageFile != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8.r),
                                  child: Image.file(
                                    _coverImageFile!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : _coverImageUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8.r),
                                  child: Image.network(
                                    _coverImageUrl!,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Center(
                                        child: Icon(
                                          Icons.image,
                                          color: Colors.grey,
                                        ),
                                      );
                                    },
                                  ),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_photo_alternate,
                                      color: Colors.grey,
                                      size: 40.sp,
                                    ),
                                    8.verticalSpace,
                                    Text(
                                      'Tap to upload cover image',
                                      style: AppTextStyles.regular.copyWith(
                                        color: Colors.grey,
                                        fontSize: 12.sp,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                  16.verticalSpace,

                  // PDF Upload (for ebook)
                  if (_selectedType == BookType.ebook) ...[
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PDF File *',
                          style: AppTextStyles.lufgaMedium.copyWith(
                            color: Colors.white,
                            fontSize: 14.sp,
                          ),
                        ),
                        8.verticalSpace,
                        GestureDetector(
                          onTap: _pickPDF,
                          child: Container(
                            height: 80.h,
                            width: double.infinity,
                            padding: EdgeInsets.all(16.w),
                            decoration: BoxDecoration(
                              color: AppColors.boxClr,
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(color: Colors.grey[800]!),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.picture_as_pdf,
                                  color: Colors.red,
                                  size: 32.sp,
                                ),
                                16.horizontalSpace,
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        _pdfFile != null
                                            ? _pdfFile!.path.split('/').last
                                            : _pdfUrl != null
                                            ? 'PDF uploaded'
                                            : 'Tap to select PDF file',
                                        style: AppTextStyles.medium.copyWith(
                                          color: Colors.white,
                                          fontSize: 14.sp,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (_pdfFile != null || _pdfUrl != null)
                                        Text(
                                          'Will upload when saving',
                                          style: AppTextStyles.small.copyWith(
                                            color: Colors.grey[400],
                                            fontSize: 10.sp,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                if (_pdfFile != null || _pdfUrl != null)
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                    size: 24.sp,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    16.verticalSpace,
                  ],

                  // Audio URL (for audiobook)
                  if (_selectedType == BookType.audiobook)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Audio File URL *',
                          style: AppTextStyles.lufgaMedium.copyWith(
                            color: Colors.white,
                            fontSize: 14.sp,
                          ),
                        ),
                        8.verticalSpace,
                        PrimaryTextField(
                          controller: _audioFileController,
                          hint: 'Enter audio file URL',
                          validator: (value) =>
                              _selectedType == BookType.audiobook &&
                                  (value?.isEmpty ?? true)
                              ? 'Audio URL is required for audiobook'
                              : null,
                        ),
                      ],
                    ),
                  if (_selectedType == BookType.audiobook) 16.verticalSpace,

                  // Action Buttons
                  _buildActionButtons(isMobile),
                  20.verticalSpace,
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButtons(bool isMobile) {
    return SizedBox(
      width: double.infinity,
      child: PrimaryButton(
        title: _isLoading ? 'Updating...' : 'Update Book',
        onTap: _updateBook,
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

  void _updateBook() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate files
    if (_coverImageFile == null &&
        _coverImageUrl == null &&
        _coverImageController.text.isEmpty) {
      CustomToast.showError(context, 'Please upload a cover image');
      return;
    }

    if (_selectedType == BookType.ebook &&
        _pdfFile == null &&
        _pdfUrl == null) {
      CustomToast.showError(context, 'Please upload a PDF file for ebook');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String? finalCoverImageUrl;
      String? finalPdfUrl;

      // Upload cover image if file is selected
      if (_coverImageFile != null) {
        CustomToast.showInfo(context, 'Uploading cover image...');
        final imageResult = await CloudinaryService.uploadImage(
          _coverImageFile!,
          folder: 'book_covers',
        );
        if (imageResult == null) {
          CustomToast.showError(context, 'Failed to upload cover image');
          setState(() {
            _isLoading = false;
          });
          return;
        }
        finalCoverImageUrl = imageResult.url;
        CustomToast.showSuccess(context, 'Cover image uploaded!');
      } else if (_coverImageUrl != null) {
        finalCoverImageUrl = _coverImageUrl;
      } else if (_coverImageController.text.isNotEmpty) {
        finalCoverImageUrl = _coverImageController.text;
      }

      // Upload PDF if file is selected
      if (_selectedType == BookType.ebook && _pdfFile != null) {
        CustomToast.showInfo(context, 'Uploading PDF...');
        final pdfResult = await CloudinaryService.uploadFile(
          _pdfFile!,
          folder: 'book_pdfs',
        );
        if (pdfResult == null) {
          CustomToast.showError(context, 'Failed to upload PDF');
          setState(() {
            _isLoading = false;
          });
          return;
        }
        finalPdfUrl = pdfResult.url;
        CustomToast.showSuccess(context, 'PDF uploaded!');
      } else if (_selectedType == BookType.ebook && _pdfUrl != null) {
        finalPdfUrl = _pdfUrl;
      }

      // Parse price
      final price = double.tryParse(_priceController.text.trim()) ?? 0.0;

      // Create updated book model
      final updatedBook = BookModel(
        id: widget.book.id, // Keep original ID
        title: _titleController.text.trim(),
        author: _authorController.text.trim(),
        description: _descriptionController.text.trim(),
        coverImageUrl: finalCoverImageUrl ?? '',
        content: widget.book.content, // Keep original content
        pdfUrl: finalPdfUrl,
        audioFileUrl:
            _selectedType == BookType.audiobook &&
                _audioFileController.text.isNotEmpty
            ? _audioFileController.text.trim()
            : null,
        chapters: widget.book.chapters, // Keep original chapters
        category: _selectedCategory,
        type: _selectedType,
        readTime: widget.book.readTime, // Keep original read time
        listenTime: widget.book.listenTime, // Keep original listen time
        listenCount: widget.book.listenCount, // Keep original listen count
        viewCount: widget.book.viewCount, // Keep original view count
        readCount: widget.book.readCount, // Keep original read count
        listenedUserCount: widget.book.listenedUserCount, // Keep original listened user count
        price: price,
        isPublished: widget.book.isPublished, // Keep original published status
        hasEverBeenPublished: widget.book.hasEverBeenPublished, // Keep original hasEverBeenPublished
        createdAt: widget.book.createdAt, // Keep original creation date
        updatedAt: DateTime.now(), // Update timestamp
      );

      await BookService.updateBook(widget.book.id, updatedBook);
      CustomToast.showSuccess(context, 'Book updated successfully!');
      Navigator.pop(context, true); // Return true to indicate successful update
    } catch (e) {
      CustomToast.showError(context, 'Error updating book: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickCoverImage() async {
    // Check if there's an existing cover image
    final hasExistingImage = _coverImageFile != null || _coverImageUrl != null;

    // Always show confirmation dialog
    final shouldChange = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.boxClr,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Text(
            hasExistingImage ? 'Change Cover Image' : 'Select Cover Image',
            style: AppTextStyles.lufgaLarge.copyWith(
              color: Colors.white,
              fontSize: 20.sp,
            ),
          ),
          content: Text(
            hasExistingImage
                ? 'Do you want to change the cover image?'
                : 'Do you want to select a cover image?',
            style: AppTextStyles.lufgaMedium.copyWith(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14.sp,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(
                'No',
                style: TextStyle(color: Colors.grey, fontSize: 14.sp),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(
                'Yes',
                style: TextStyle(
                  color: AppColors.primaryColor,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldChange != true) {
      return; // User cancelled
    }

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _coverImageFile = File(pickedFile.path);
        _coverImageUrl = null; // Clear URL if file is selected
      });
    }
  }

  Future<void> _pickPDF() async {
    try {
      // Check if there's an existing PDF
      final hasExistingPdf = _pdfFile != null || _pdfUrl != null;

      // Always show confirmation dialog
      final shouldChange = await showDialog<bool>(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            backgroundColor: AppColors.boxClr,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
            title: Text(
              hasExistingPdf ? 'Change PDF File' : 'Select PDF File',
              style: AppTextStyles.lufgaLarge.copyWith(
                color: Colors.white,
                fontSize: 20.sp,
              ),
            ),
            content: Text(
              hasExistingPdf
                  ? 'Do you want to change the PDF file?'
                  : 'Do you want to select a PDF file?',
              style: AppTextStyles.lufgaMedium.copyWith(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14.sp,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: Text(
                  'No',
                  style: TextStyle(color: Colors.grey, fontSize: 14.sp),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: Text(
                  'Yes',
                  style: TextStyle(
                    color: AppColors.primaryColor,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      );

      if (shouldChange != true) {
        return; // User cancelled
      }

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.path != null) {
          setState(() {
            _pdfFile = File(file.path!);
            _pdfUrl = null; // Clear URL if file is selected
          });
          if (mounted) {
            CustomToast.showSuccess(context, 'PDF file selected');
          }
        } else {
          if (mounted) {
            CustomToast.showError(context, 'Could not access PDF file path');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        CustomToast.showError(context, 'Error selecting PDF: $e');
      }
      print('Error in _pickPDF: $e');
    }
  }
}
