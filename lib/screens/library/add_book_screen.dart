import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:the_woodlands_series/components/button/primary_button.dart';
import 'package:the_woodlands_series/components/resource/app_colors.dart';
import 'package:the_woodlands_series/components/resource/app_textstyle.dart';
import 'package:the_woodlands_series/components/textfield/primary_textfield.dart';
import 'package:the_woodlands_series/components/resource/app_routers.dart';
import 'package:the_woodlands_series/admin_panel/models/book_model.dart';
import 'package:the_woodlands_series/services/book_service.dart';
import 'package:the_woodlands_series/services/cloudinary_service.dart';
import 'package:the_woodlands_series/components/utils/custom_toast.dart';

class AddBookScreen extends StatefulWidget {
  final String initialType; // 'ebook' or 'audiobook'

  const AddBookScreen({super.key, this.initialType = 'ebook'});

  @override
  State<AddBookScreen> createState() => _AddBookScreenState();
}

class _AddBookScreenState extends State<AddBookScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _readTimeController = TextEditingController();
  final TextEditingController _listenTimeController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();

  BookType _selectedType = BookType.ebook;
  File? _coverImageFile;
  File? _pdfFile;
  String? _coverImageUrl;
  String? _pdfUrl; // Will be set after upload
  String? _audioUrl;
  bool _isPublished = true;
  bool _isLoading = false;

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
  void initState() {
    super.initState();
    _selectedType = widget.initialType == 'ebook'
        ? BookType.ebook
        : BookType.audiobook;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _descriptionController.dispose();
    _readTimeController.dispose();
    _listenTimeController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _coverImageFile = File(pickedFile.path);
      });
      await _uploadCoverImage();
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

  Future<void> _uploadCoverImage() async {
    if (_coverImageFile == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await CloudinaryService.uploadImage(_coverImageFile!);
      if (result != null) {
        setState(() {
          _coverImageUrl = result.url;
        });
        CustomToast.showSuccess(context, 'Cover image uploaded!');
      } else {
        CustomToast.showError(context, 'Failed to upload cover image');
      }
    } catch (e) {
      CustomToast.showError(context, 'Error uploading image: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveBook() async {
    if (!_formKey.currentState!.validate()) return;
    if (_coverImageUrl == null && _coverImageFile == null) {
      CustomToast.showError(context, 'Please upload a cover image');
      return;
    }

    // If ebook and no PDF provided
    if (_selectedType == BookType.ebook &&
        _pdfFile == null &&
        _pdfUrl == null) {
      CustomToast.showError(context, 'Please select a PDF file for ebook');
      return;
    }

    // If audiobook and no audio provided
    if (_selectedType == BookType.audiobook && _audioUrl == null) {
      CustomToast.showError(context, 'Please provide audio URL for audiobook');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String? finalCoverImageUrl = _coverImageUrl;
      String? finalPdfUrl = _pdfUrl;

      // Upload cover image if file is selected (not already uploaded)
      if (_coverImageFile != null && _coverImageUrl == null) {
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
      }

      final book = BookModel(
        id: '', // Will be set by Firestore
        title: _titleController.text.trim(),
        author: _authorController.text.trim(),
        description: _descriptionController.text.trim(),
        coverImageUrl: finalCoverImageUrl ?? '',
        pdfUrl: finalPdfUrl,
        audioFileUrl: _audioUrl,
        category: _categoryController.text.trim().isEmpty
            ? _categories[0]
            : _categoryController.text.trim(),
        type: _selectedType,
        readTime: int.tryParse(_readTimeController.text) ?? 0,
        listenTime: int.tryParse(_listenTimeController.text) ?? 0,
        isPublished: _isPublished,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await BookService.addBook(book);
      CustomToast.showSuccess(context, 'Book added successfully!');
      AppRouter.routeBack(context);
    } catch (e) {
      CustomToast.showError(context, 'Error adding book: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgClr,
      appBar: AppBar(
        backgroundColor: AppColors.boxClr,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => AppRouter.routeBack(context),
        ),
        title: Text(
          'Add New Book',
          style: AppTextStyles.lufgaMedium.copyWith(
            color: Colors.white,
            fontSize: 18.sp,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Book Type Selection
              Text(
                'Book Type',
                style: AppTextStyles.lufgaMedium.copyWith(
                  color: AppColors.primaryColor,
                  fontSize: 16.sp,
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
              24.verticalSpace,

              // Title
              PrimaryTextField(
                controller: _titleController,
                hint: 'Book Title *',
                validator: (value) =>
                    value?.isEmpty == true ? 'Title is required' : null,
              ),
              16.verticalSpace,

              // Author
              PrimaryTextField(
                controller: _authorController,
                hint: 'Author Name *',
                validator: (value) =>
                    value?.isEmpty == true ? 'Author is required' : null,
              ),
              16.verticalSpace,

              // Description
              PrimaryTextField(
                controller: _descriptionController,
                hint: 'Description *',
                minlines: 3,
                maxlines: 5,
                validator: (value) =>
                    value?.isEmpty == true ? 'Description is required' : null,
              ),
              16.verticalSpace,

              // Category
              PrimaryTextField(
                controller: _categoryController,
                hint: 'Category (default: ${_categories[0]})',
              ),
              16.verticalSpace,

              // Cover Image
              Text(
                'Cover Image *',
                style: AppTextStyles.lufgaMedium.copyWith(
                  color: Colors.white,
                  fontSize: 14.sp,
                ),
              ),
              8.verticalSpace,
              GestureDetector(
                onTap: _pickImage,
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
                                child: Icon(Icons.image, color: Colors.grey),
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
              24.verticalSpace,

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
              if (_selectedType == BookType.audiobook) ...[
                PrimaryTextField(
                  controller: TextEditingController(text: _audioUrl ?? ''),
                  hint: 'Audio File URL *',
                  onChanged: (value) {
                    setState(() {
                      _audioUrl = value;
                    });
                  },
                  validator: (value) =>
                      _selectedType == BookType.audiobook &&
                          (value?.isEmpty ?? true)
                      ? 'Audio URL is required for audiobook'
                      : null,
                ),
                16.verticalSpace,
              ],

              // Timing
              Row(
                children: [
                  Expanded(
                    child: PrimaryTextField(
                      controller: _readTimeController,
                      hint: 'Read Time (min)',
                      keyboard: TextInputType.number,
                    ),
                  ),
                  16.horizontalSpace,
                  Expanded(
                    child: PrimaryTextField(
                      controller: _listenTimeController,
                      hint: 'Listen Time (min)',
                      keyboard: TextInputType.number,
                    ),
                  ),
                ],
              ),
              24.verticalSpace,

              // Published checkbox
              Row(
                children: [
                  Checkbox(
                    value: _isPublished,
                    onChanged: (value) {
                      setState(() {
                        _isPublished = value ?? true;
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
              24.verticalSpace,

              // Save Button
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  title: _isLoading ? 'Saving...' : 'Add Book',
                  onTap: _isLoading ? null : _saveBook,
                ),
              ),
              20.verticalSpace,
            ],
          ),
        ),
      ),
    );
  }
}
