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

class AddBookScreen extends StatefulWidget {
  const AddBookScreen({super.key});

  @override
  State<AddBookScreen> createState() => _AddBookScreenState();
}

class _AddBookScreenState extends State<AddBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _coverImageController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _audioFileController = TextEditingController();
  final TextEditingController _readTimeController = TextEditingController();
  final TextEditingController _listenTimeController = TextEditingController();

  String _selectedCategory = 'Fiction';
  BookType _selectedType = BookType.ebook;
  bool _isPublished = false;
  bool _isLoading = false;

  // File selection (not uploaded until save)
  File? _coverImageFile;
  File? _pdfFile;
  String? _coverImageUrl; // Will be set after upload
  String? _pdfUrl; // Will be set after upload

  final List<String> _categories = [
    'Fiction',
    'Non-Fiction',
    'Fantasy',
    'Adventure',
    'Mystery',
    'Romance',
    'Science Fiction',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _descriptionController.dispose();
    _coverImageController.dispose();
    _contentController.dispose();
    _audioFileController.dispose();
    _readTimeController.dispose();
    _listenTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgClr,
      appBar: AppBar(
        backgroundColor: AppColors.boxClr,
        title: Text(
          'Add New Book',
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

                  PrimaryTextField(
                    controller: _titleController,
                    hint: 'Book Title',
                    validator: (value) =>
                        value?.isEmpty == true ? 'Title is required' : null,
                  ),
                  16.verticalSpace,

                  PrimaryTextField(
                    controller: _authorController,
                    hint: 'Author Name',
                    validator: (value) =>
                        value?.isEmpty == true ? 'Author is required' : null,
                  ),
                  16.verticalSpace,

                  PrimaryTextField(
                    controller: _descriptionController,
                    hint: 'Book Description',
                    validator: (value) => value?.isEmpty == true
                        ? 'Description is required'
                        : null,
                  ),
                  16.verticalSpace,

                  // Book Type Selection
                  Text(
                    'Book Type',
                    style: AppTextStyles.lufgaMedium.copyWith(
                      color: AppColors.primaryColor,
                      fontSize: 14.sp,
                    ),
                  ),
                  8.verticalSpace,
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedType = BookType.ebook;
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            decoration: BoxDecoration(
                              color: _selectedType == BookType.ebook
                                  ? AppColors.primaryColor
                                  : AppColors.boxClr,
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(
                                color: _selectedType == BookType.ebook
                                    ? AppColors.primaryColor
                                    : Colors.grey[800]!,
                              ),
                            ),
                            child: Text(
                              'E-book',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.medium.copyWith(
                                color: _selectedType == BookType.ebook
                                    ? Colors.black
                                    : Colors.white,
                                fontSize: 14.sp,
                              ),
                            ),
                          ),
                        ),
                      ),
                      16.horizontalSpace,
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedType = BookType.audiobook;
                            });
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(vertical: 12.h),
                            decoration: BoxDecoration(
                              color: _selectedType == BookType.audiobook
                                  ? AppColors.primaryColor
                                  : AppColors.boxClr,
                              borderRadius: BorderRadius.circular(8.r),
                              border: Border.all(
                                color: _selectedType == BookType.audiobook
                                    ? AppColors.primaryColor
                                    : Colors.grey[800]!,
                              ),
                            ),
                            child: Text(
                              'Audiobook',
                              textAlign: TextAlign.center,
                              style: AppTextStyles.medium.copyWith(
                                color: _selectedType == BookType.audiobook
                                    ? Colors.black
                                    : Colors.white,
                                fontSize: 14.sp,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  16.verticalSpace,

                  // Category Dropdown
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 12.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.boxClr,
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCategory,
                        isExpanded: true,
                        style: AppTextStyles.medium.copyWith(
                          color: Colors.white,
                        ),
                        dropdownColor: AppColors.boxClr,
                        items: _categories.map((category) {
                          return DropdownMenuItem<String>(
                            value: category,
                            child: Text(category),
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
                  24.verticalSpace,

                  // Media Files
                  _buildSectionTitle('Media Files'),
                  16.verticalSpace,

                  // Cover Image Upload
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
                                fit: BoxFit.cover,
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
                  16.verticalSpace,

                  // PDF Upload (for ebook)
                  if (_selectedType == BookType.ebook) ...[
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
                                crossAxisAlignment: CrossAxisAlignment.start,
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
                    16.verticalSpace,
                  ],

                  // Audio URL (for audiobook)
                  if (_selectedType == BookType.audiobook)
                    PrimaryTextField(
                      controller: _audioFileController,
                      hint: 'Audio File URL',
                      validator: (value) =>
                          _selectedType == BookType.audiobook &&
                              (value?.isEmpty ?? true)
                          ? 'Audio URL is required for audiobook'
                          : null,
                    ),
                  if (_selectedType == BookType.audiobook) 16.verticalSpace,

                  // Content (for ebook)
                  if (_selectedType == BookType.ebook) ...[
                    _buildSectionTitle('Content'),
                    16.verticalSpace,
                    PrimaryTextField(
                      controller: _contentController,
                      hint: 'Book Content (Text)',
                      minlines: 3,
                      maxlines: 5,
                    ),
                    24.verticalSpace,
                  ],

                  // Timing Information
                  _buildSectionTitle('Timing Information'),
                  16.verticalSpace,

                  _buildTimingFields(isMobile),
                  24.verticalSpace,

                  // Publishing Options
                  _buildSectionTitle('Publishing Options'),
                  16.verticalSpace,

                  Row(
                    children: [
                      Checkbox(
                        value: _isPublished,
                        onChanged: (value) {
                          setState(() {
                            _isPublished = value!;
                          });
                        },
                        activeColor: AppColors.primaryColor,
                      ),
                      Text(
                        'Publish immediately',
                        style: AppTextStyles.medium.copyWith(
                          color: Colors.white,
                          fontSize: 14.sp,
                        ),
                      ),
                    ],
                  ),
                  30.verticalSpace,

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

  Widget _buildTimingFields(bool isMobile) {
    if (isMobile) {
      // Mobile: Stack vertically
      return Column(
        children: [
          PrimaryTextField(
            controller: _readTimeController,
            hint: 'Read Time (minutes)',
            validator: (value) =>
                value?.isEmpty == true ? 'Read time is required' : null,
          ),
          16.verticalSpace,
          PrimaryTextField(
            controller: _listenTimeController,
            hint: 'Listen Time (minutes)',
          ),
        ],
      );
    } else {
      // Desktop/Tablet: Side by side
      return Row(
        children: [
          Expanded(
            child: PrimaryTextField(
              controller: _readTimeController,
              hint: 'Read Time (minutes)',
              validator: (value) =>
                  value?.isEmpty == true ? 'Read time is required' : null,
            ),
          ),
          16.horizontalSpace,
          Expanded(
            child: PrimaryTextField(
              controller: _listenTimeController,
              hint: 'Listen Time (minutes)',
            ),
          ),
        ],
      );
    }
  }

  Widget _buildActionButtons(bool isMobile) {
    if (isMobile) {
      // Mobile: Stack vertically
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(title: 'Save as Draft', onTap: _saveAsDraft),
          ),
          12.verticalSpace,
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              title: _isLoading ? 'Saving...' : 'Publish Book',
              onTap: _publishBook,
            ),
          ),
        ],
      );
    } else {
      // Desktop/Tablet: Side by side
      return Row(
        children: [
          Expanded(
            child: PrimaryButton(title: 'Save as Draft', onTap: _saveAsDraft),
          ),
          16.horizontalSpace,
          Expanded(
            child: PrimaryButton(
              title: _isLoading ? 'Saving...' : 'Publish Book',
              onTap: _publishBook,
            ),
          ),
        ],
      );
    }
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

  void _saveAsDraft() async {
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

      // Create book model
      final book = BookModel(
        id: '', // Will be set by Firestore
        title: _titleController.text.trim(),
        author: _authorController.text.trim(),
        description: _descriptionController.text.trim(),
        coverImageUrl: finalCoverImageUrl ?? '',
        content:
            _selectedType == BookType.ebook &&
                _contentController.text.isNotEmpty
            ? _contentController.text.trim()
            : null,
        pdfUrl: finalPdfUrl,
        audioFileUrl:
            _selectedType == BookType.audiobook &&
                _audioFileController.text.isNotEmpty
            ? _audioFileController.text.trim()
            : null,
        category: _selectedCategory,
        type: _selectedType,
        readTime: int.tryParse(_readTimeController.text) ?? 0,
        listenTime: int.tryParse(_listenTimeController.text) ?? 0,
        isPublished: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await BookService.addBook(book);
      CustomToast.showSuccess(context, 'Book saved as draft successfully!');
      Navigator.pop(context);
    } catch (e) {
      CustomToast.showError(context, 'Error saving book: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _publishBook() async {
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

      // Create book model
      final book = BookModel(
        id: '', // Will be set by Firestore
        title: _titleController.text.trim(),
        author: _authorController.text.trim(),
        description: _descriptionController.text.trim(),
        coverImageUrl: finalCoverImageUrl ?? '',
        content:
            _selectedType == BookType.ebook &&
                _contentController.text.isNotEmpty
            ? _contentController.text.trim()
            : null,
        pdfUrl: finalPdfUrl,
        audioFileUrl:
            _selectedType == BookType.audiobook &&
                _audioFileController.text.isNotEmpty
            ? _audioFileController.text.trim()
            : null,
        category: _selectedCategory,
        type: _selectedType,
        readTime: int.tryParse(_readTimeController.text) ?? 0,
        listenTime: int.tryParse(_listenTimeController.text) ?? 0,
        isPublished: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await BookService.addBook(book);
      CustomToast.showSuccess(context, 'Book published successfully!');
      Navigator.pop(context);
    } catch (e) {
      CustomToast.showError(context, 'Error publishing book: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickCoverImage() async {
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
