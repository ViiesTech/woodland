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
  final TextEditingController _categoryController = TextEditingController();

  BookType _selectedType = BookType.ebook;
  File? _coverImageFile;
  File? _pdfFile;
  String? _coverImageUrl;
  String? _pdfUrl; // Will be set after upload

  // Chapters for audiobook: List of {chapterName: String, audioFile: File?, audioUrl: String?}
  List<Map<String, dynamic>> _chapters = [];

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

    // Initialize with one chapter if audiobook
    if (_selectedType == BookType.audiobook) {
      _chapters.add({
        'controller': TextEditingController(text: 'Chapter 1'),
        'audioFile': null,
        'audioUrl': null,
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    // Dispose chapter controllers
    for (var chapter in _chapters) {
      if (chapter['controller'] != null) {
        (chapter['controller'] as TextEditingController).dispose();
      }
    }
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

  Future<void> _pickAudioFile(int chapterIndex) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'wav', 'm4a', 'aac'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.path != null) {
          setState(() {
            _chapters[chapterIndex]['audioFile'] = File(file.path!);
            _chapters[chapterIndex]['audioUrl'] =
                null; // Clear URL if file is selected
          });
          if (mounted) {
            CustomToast.showSuccess(context, 'Audio file selected');
          }
        } else {
          if (mounted) {
            CustomToast.showError(context, 'Could not access audio file path');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        CustomToast.showError(context, 'Error selecting audio file: $e');
      }
      print('Error in _pickAudioFile: $e');
    }
  }

  void _addChapter() {
    setState(() {
      _chapters.add({
        'controller': TextEditingController(
          text: 'Chapter ${_chapters.length + 1}',
        ),
        'audioFile': null,
        'audioUrl': null,
      });
    });
  }

  void _removeChapter(int index) {
    setState(() {
      if (_chapters[index]['controller'] != null) {
        (_chapters[index]['controller'] as TextEditingController).dispose();
      }
      _chapters.removeAt(index);
    });
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

    // If audiobook and no chapters provided
    if (_selectedType == BookType.audiobook) {
      if (_chapters.isEmpty) {
        CustomToast.showError(
          context,
          'Please add at least one chapter for audiobook',
        );
        return;
      }
      // Check if all chapters have audio files
      for (var i = 0; i < _chapters.length; i++) {
        final chapter = _chapters[i];
        final chapterName = (chapter['controller'] as TextEditingController)
            .text
            .trim();
        if (chapterName.isEmpty) {
          CustomToast.showError(
            context,
            'Chapter ${i + 1} name cannot be empty',
          );
          return;
        }
        if (chapter['audioFile'] == null && chapter['audioUrl'] == null) {
          CustomToast.showError(
            context,
            'Please select audio file for ${chapterName.isEmpty ? "Chapter ${i + 1}" : chapterName}',
          );
          return;
        }
      }
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

      // Upload audio files for audiobook chapters
      List<Map<String, String>>? chaptersData;
      if (_selectedType == BookType.audiobook) {
        chaptersData = [];
        for (var i = 0; i < _chapters.length; i++) {
          final chapter = _chapters[i];
          final chapterName = (chapter['controller'] as TextEditingController)
              .text
              .trim();
          String? audioUrl = chapter['audioUrl'] as String?;

          // Upload audio file if file is selected
          if (chapter['audioFile'] != null) {
            CustomToast.showInfo(
              context,
              'Uploading audio for $chapterName...',
            );
            final audioResult = await CloudinaryService.uploadFile(
              chapter['audioFile'] as File,
              folder: 'book_audios',
            );
            if (audioResult == null) {
              CustomToast.showError(
                context,
                'Failed to upload audio for $chapterName',
              );
              setState(() {
                _isLoading = false;
              });
              return;
            }
            audioUrl = audioResult.url;
          }

          if (audioUrl != null) {
            chaptersData.add({
              'chapterName': chapterName,
              'audioUrl': audioUrl,
            });
          }
        }
      }

      final book = BookModel(
        id: '', // Will be set by Firestore
        title: _titleController.text.trim(),
        author: _authorController.text.trim(),
        description: _descriptionController.text.trim(),
        coverImageUrl: finalCoverImageUrl ?? '',
        pdfUrl: finalPdfUrl,
        audioFileUrl: null, // Keep null, use chapters instead
        chapters: chaptersData,
        category: _categoryController.text.trim().isEmpty
            ? _categories[0]
            : _categoryController.text.trim(),
        type: _selectedType,
        readTime: 0, // No longer used
        listenTime: 0, // No longer used
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
                          // Clear chapters when switching to ebook
                          for (var chapter in _chapters) {
                            if (chapter['controller'] != null) {
                              (chapter['controller'] as TextEditingController)
                                  .dispose();
                            }
                          }
                          _chapters.clear();
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
                          // Initialize with one chapter if empty
                          if (_chapters.isEmpty) {
                            _chapters.add({
                              'controller': TextEditingController(
                                text: 'Chapter 1',
                              ),
                              'audioFile': null,
                              'audioUrl': null,
                            });
                          }
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

              // Chapters (for audiobook)
              if (_selectedType == BookType.audiobook) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Chapters *',
                      style: AppTextStyles.lufgaMedium.copyWith(
                        color: Colors.white,
                        fontSize: 14.sp,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _addChapter,
                      icon: Icon(
                        Icons.add,
                        color: AppColors.primaryColor,
                        size: 20.sp,
                      ),
                      label: Text(
                        'Add Chapter',
                        style: AppTextStyles.medium.copyWith(
                          color: AppColors.primaryColor,
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                  ],
                ),
                8.verticalSpace,
                if (_chapters.isEmpty) ...[
                  Text(
                    'No chapters added. Click "Add Chapter" to add one.',
                    style: AppTextStyles.regular.copyWith(
                      color: Colors.grey[400],
                      fontSize: 12.sp,
                    ),
                  ),
                  16.verticalSpace,
                ] else ...[
                  ...List.generate(_chapters.length, (index) {
                    final chapter = _chapters[index];
                    final controller =
                        chapter['controller'] as TextEditingController;
                    final audioFile = chapter['audioFile'] as File?;
                    final audioUrl = chapter['audioUrl'] as String?;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: PrimaryTextField(
                                controller: controller,
                                hint: 'Chapter Name *',
                              ),
                            ),
                            if (_chapters.length > 1)
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _removeChapter(index),
                              ),
                          ],
                        ),
                        8.verticalSpace,
                        GestureDetector(
                          onTap: () => _pickAudioFile(index),
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
                                  Icons.audiotrack,
                                  color: AppColors.primaryColor,
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
                                        audioFile != null
                                            ? audioFile.path.split('/').last
                                            : audioUrl != null
                                            ? 'Audio URL set'
                                            : 'Tap to select audio file',
                                        style: AppTextStyles.medium.copyWith(
                                          color: Colors.white,
                                          fontSize: 14.sp,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (audioFile != null)
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
                                if (audioFile != null || audioUrl != null)
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                    size: 24.sp,
                                  ),
                              ],
                            ),
                          ),
                        ),
                        if (index < _chapters.length - 1) 16.verticalSpace,
                      ],
                    );
                  }),
                  16.verticalSpace,
                ],
              ],

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
