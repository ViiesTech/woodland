import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:the_woodlands_series/components/button/primary_button.dart';
import 'package:the_woodlands_series/components/resource/app_colors.dart';
import 'package:the_woodlands_series/components/resource/app_textstyle.dart';
import 'package:the_woodlands_series/components/textfield/primary_textfield.dart';
import 'package:the_woodlands_series/components/utils/custom_toast.dart';
import 'package:the_woodlands_series/services/cloudinary_service.dart';
import 'package:the_woodlands_series/services/game_service.dart';
import '../../models/game_model.dart';

class EditGameScreen extends StatefulWidget {
  final GameModel game;

  const EditGameScreen({super.key, required this.game});

  @override
  State<EditGameScreen> createState() => _EditGameScreenState();
}

class _EditGameScreenState extends State<EditGameScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _subtitleController;
  late TextEditingController _descriptionController;
  late TextEditingController _gameUrlController;

  late String _selectedCategory;
  late bool _isPublished;
  bool _isLoading = false;

  // File selection
  File? _coverImageFile;
  String? _existingImageUrl;

  final List<String> _categories = [
    'Trending',
    'Quick Games',
    'Simulation',
    'Action',
    'Adventure',
    'Puzzle',
    'Strategy',
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.game.title);
    _subtitleController = TextEditingController(text: widget.game.subtitle);
    _descriptionController = TextEditingController(text: widget.game.description);
    _gameUrlController = TextEditingController(text: widget.game.gameUrl);
    _selectedCategory = widget.game.category;
    _isPublished = widget.game.isPublished;
    _existingImageUrl = widget.game.imageUrl;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _descriptionController.dispose();
    _gameUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickCoverImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _coverImageFile = File(image.path);
          _existingImageUrl = null; // Clear existing URL when new image is selected
        });
      }
    } catch (e) {
      if (mounted) {
        CustomToast.showError(context, 'Error selecting image: $e');
      }
    }
  }

  Future<void> _updateGame() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String imageUrl = _existingImageUrl ?? '';

      // Upload new cover image if one was selected
      if (_coverImageFile != null) {
        CustomToast.showInfo(context, 'Uploading cover image...');
        final uploadResult = await CloudinaryService.uploadImage(
          _coverImageFile!,
          folder: 'game_covers',
        );

        if (uploadResult == null || uploadResult.url.isEmpty) {
          throw Exception('Failed to upload cover image');
        }

        imageUrl = uploadResult.url;
      }

      // Update game model
      final updatedGame = widget.game.copyWith(
        title: _titleController.text.trim(),
        subtitle: _subtitleController.text.trim(),
        imageUrl: imageUrl,
        gameUrl: _gameUrlController.text.trim(),
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        updatedAt: DateTime.now(),
        isPublished: _isPublished,
      );

      // Update in Firestore
      CustomToast.showInfo(context, 'Updating game...');
      await GameService.updateGame(updatedGame);

      if (mounted) {
        CustomToast.showSuccess(context, 'Game updated successfully!');
        Navigator.pop(context, updatedGame); // Return updated game
      }
    } catch (e) {
      if (mounted) {
        CustomToast.showError(context, 'Error updating game: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: AppTextStyles.lufgaMedium.copyWith(
        color: Colors.white,
        fontSize: 18.sp,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgClr,
      appBar: AppBar(
        backgroundColor: AppColors.boxClr,
        title: Text(
          'Edit Game',
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
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
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
                hint: 'Game Title',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter game title';
                  }
                  return null;
                },
              ),
              16.verticalSpace,

              PrimaryTextField(
                controller: _subtitleController,
                hint: 'Subtitle',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter subtitle';
                  }
                  return null;
                },
              ),
              16.verticalSpace,

              PrimaryTextField(
                controller: _descriptionController,
                hint: 'Description',
                maxlines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter description';
                  }
                  return null;
                },
              ),
              24.verticalSpace,

              // Game URL
              _buildSectionTitle('Game URL'),
              16.verticalSpace,

              PrimaryTextField(
                controller: _gameUrlController,
                hint: 'Game URL (e.g., https://yourgame.com)',
                keyboard: TextInputType.url,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter game URL';
                  }
                  final uri = Uri.tryParse(value);
                  if (uri == null || !uri.hasScheme) {
                    return 'Please enter a valid URL';
                  }
                  return null;
                },
              ),
              24.verticalSpace,

              // Category
              _buildSectionTitle('Category'),
              16.verticalSpace,

              Container(
                decoration: BoxDecoration(
                  color: AppColors.boxClr,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  dropdownColor: AppColors.boxClr,
                  style: AppTextStyles.medium.copyWith(
                    color: Colors.white,
                    fontSize: 14.sp,
                  ),
                  underline: SizedBox(),
                  items: _categories.map((String category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedCategory = newValue;
                      });
                    }
                  },
                ),
              ),
              24.verticalSpace,

              // Cover Image
              _buildSectionTitle('Cover Image'),
              16.verticalSpace,

              GestureDetector(
                onTap: _pickCoverImage,
                child: Container(
                  height: 200.h,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.boxClr,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: _coverImageFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12.r),
                          child: Image.file(
                            _coverImageFile!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : _existingImageUrl != null && _existingImageUrl!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12.r),
                              child: _existingImageUrl!.startsWith('http')
                                  ? Image.network(
                                      _existingImageUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.add_photo_alternate,
                                              color: Colors.grey,
                                              size: 48.sp,
                                            ),
                                            8.verticalSpace,
                                            Text(
                                              'Tap to select cover image',
                                              style: AppTextStyles.medium.copyWith(
                                                color: Colors.grey,
                                                fontSize: 14.sp,
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    )
                                  : Image.asset(
                                      _existingImageUrl!,
                                      fit: BoxFit.cover,
                                    ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate,
                                  color: Colors.grey,
                                  size: 48.sp,
                                ),
                                8.verticalSpace,
                                Text(
                                  'Tap to select cover image',
                                  style: AppTextStyles.medium.copyWith(
                                    color: Colors.grey,
                                    fontSize: 14.sp,
                                  ),
                                ),
                              ],
                            ),
                ),
              ),
              24.verticalSpace,

              // Publish Status
              Row(
                children: [
                  Checkbox(
                    value: _isPublished,
                    onChanged: (value) {
                      setState(() {
                        _isPublished = value ?? false;
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
              32.verticalSpace,

              // Update Button
              PrimaryButton(
                title: _isLoading ? 'Updating...' : 'Update Game',
                buttonWidth: double.infinity,
                onTap: _isLoading ? null : _updateGame,
              ),
              32.verticalSpace,
            ],
          ),
        ),
      ),
    );
  }
}

