import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:the_woodlands_series/components/resource/app_colors.dart';
import 'package:the_woodlands_series/components/resource/app_textstyle.dart';
import 'package:the_woodlands_series/components/button/primary_button.dart';
import 'package:the_woodlands_series/components/utils/custom_toast.dart';
import 'package:the_woodlands_series/services/blog_service.dart';
import 'package:the_woodlands_series/services/cloudinary_service.dart';
import 'package:the_woodlands_series/models/blog_model.dart';
import 'package:the_woodlands_series/bloc/auth/auth_bloc.dart';
import 'package:the_woodlands_series/bloc/auth/auth_state.dart';

class AddBlogScreen extends StatefulWidget {
  const AddBlogScreen({super.key});

  @override
  State<AddBlogScreen> createState() => _AddBlogScreenState();
}

class _AddBlogScreenState extends State<AddBlogScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      CustomToast.showError(context, 'Failed to pick image: ${e.toString()}');
    }
  }

  Future<void> _saveBlog() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedImage == null) {
      CustomToast.showError(context, 'Please select an image');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Upload image to Cloudinary
      CustomToast.showInfo(context, 'Uploading image...');
      final uploadResult = await CloudinaryService.uploadImage(
        _selectedImage!,
        folder: 'blog_images',
      );

      if (uploadResult == null || uploadResult.url.isEmpty) {
        throw Exception('Failed to upload image');
      }

      // Get current user
      final authState = context.read<AuthBloc>().state;
      final author = authState is Authenticated
          ? authState.user.name
          : 'Admin';

      // Create blog model
      final blog = BlogModel(
        id: '', // Will be set by Firestore
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        author: author,
        imageUrl: uploadResult.url,
        createdAt: DateTime.now(),
        commentCount: 0,
      );

      // Save to Firestore
      CustomToast.showInfo(context, 'Saving blog...');
      final success = await BlogService.createBlog(blog);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (success) {
          CustomToast.showSuccess(context, 'Blog created successfully!');
          Navigator.pop(context);
        } else {
          CustomToast.showError(context, 'Failed to create blog');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        CustomToast.showError(context, 'Error: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgClr,
      appBar: AppBar(
        backgroundColor: AppColors.boxClr,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Add Blog',
          style: AppTextStyles.lufgaLarge.copyWith(
            color: Colors.white,
            fontSize: 20.sp,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image picker
              Text(
                'Blog Image',
                style: AppTextStyles.lufgaLarge.copyWith(
                  color: Colors.white,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              12.verticalSpace,
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: double.infinity,
                  height: 200.h,
                  decoration: BoxDecoration(
                    color: AppColors.boxClr,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: AppColors.primaryColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: _selectedImage != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12.r),
                          child: Image.file(
                            _selectedImage!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate,
                              color: AppColors.primaryColor,
                              size: 50.sp,
                            ),
                            12.verticalSpace,
                            Text(
                              'Tap to select image',
                              style: AppTextStyles.medium.copyWith(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 14.sp,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              30.verticalSpace,

              // Title field
              Text(
                'Title',
                style: AppTextStyles.lufgaLarge.copyWith(
                  color: Colors.white,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              12.verticalSpace,
              TextFormField(
                controller: _titleController,
                style: AppTextStyles.lufgaMedium.copyWith(
                  color: Colors.white,
                  fontSize: 16.sp,
                ),
                decoration: InputDecoration(
                  hintText: 'Enter blog title',
                  hintStyle: AppTextStyles.lufgaMedium.copyWith(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 16.sp,
                  ),
                  filled: true,
                  fillColor: AppColors.boxClr,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(
                      color: AppColors.primaryColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(
                      color: AppColors.primaryColor,
                      width: 2,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              30.verticalSpace,

              // Content field
              Text(
                'Description',
                style: AppTextStyles.lufgaLarge.copyWith(
                  color: Colors.white,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              12.verticalSpace,
              TextFormField(
                controller: _contentController,
                style: AppTextStyles.lufgaMedium.copyWith(
                  color: Colors.white,
                  fontSize: 16.sp,
                ),
                maxLines: 15,
                decoration: InputDecoration(
                  hintText: 'Enter blog description/content',
                  hintStyle: AppTextStyles.lufgaMedium.copyWith(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 16.sp,
                  ),
                  filled: true,
                  fillColor: AppColors.boxClr,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(
                      color: AppColors.primaryColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(
                      color: AppColors.primaryColor,
                      width: 2,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter blog content';
                  }
                  return null;
                },
              ),
              40.verticalSpace,

              // Save button
              PrimaryButton(
                buttonWidth: double.infinity,
                title: _isLoading ? 'SAVING...' : 'SAVE BLOG',
                onTap: _isLoading ? null : _saveBlog,
              ),
              40.verticalSpace,
            ],
          ),
        ),
      ),
    );
  }
}

