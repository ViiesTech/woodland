import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:file_picker/file_picker.dart';
import 'package:the_woodlands_series/components/button/primary_button.dart';
import 'package:the_woodlands_series/components/resource/app_colors.dart';
import 'package:the_woodlands_series/components/resource/app_textstyle.dart';
import 'package:the_woodlands_series/components/textfield/primary_textfield.dart';
import 'package:the_woodlands_series/components/resource/app_routers.dart';
import 'package:the_woodlands_series/components/utils/custom_toast.dart';
import 'package:the_woodlands_series/admin_panel/services/firebase_service.dart';
import 'package:the_woodlands_series/models/mp3_model.dart';
import 'package:the_woodlands_series/services/cloudinary_service.dart';

class AddMp3Screen extends StatefulWidget {
  const AddMp3Screen({super.key});

  @override
  State<AddMp3Screen> createState() => _AddMp3ScreenState();
}

class _AddMp3ScreenState extends State<AddMp3Screen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  File? _audioFile;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickAudioFile() async {
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
            _audioFile = File(file.path!);
          });
          CustomToast.showSuccess(context, 'Audio file selected');
        }
      }
    } catch (e) {
      CustomToast.showError(context, 'Error selecting audio file: $e');
    }
  }

  Future<void> _saveMp3() async {
    if (!_formKey.currentState!.validate()) return;
    if (_audioFile == null) {
      CustomToast.showError(context, 'Please select an MP3 file');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      CustomToast.showInfo(context, 'Uploading MP3...');
      final uploadResult = await CloudinaryService.uploadFile(
        _audioFile!,
        folder: 'mp3_uploads',
      );

      if (uploadResult == null) {
        CustomToast.showError(context, 'Failed to upload MP3');
        return;
      }

      final mp3 = Mp3Model(
        id: '',
        title: _titleController.text.trim(),
        url: uploadResult.url,
        isPublished: true,
        createdAt: DateTime.now(),
      );

      await FirebaseService.addMp3(mp3);
      CustomToast.showSuccess(context, 'MP3 added successfully!');
      AppRouter.routeBack(context);
    } catch (e) {
      CustomToast.showError(context, 'Error adding MP3: $e');
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
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => AppRouter.routeBack(context),
        ),
        title: Text(
          'Add New Song',
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
              Text(
                'Song Information',
                style: AppTextStyles.lufgaMedium.copyWith(
                  color: AppColors.primaryColor,
                  fontSize: 16.sp,
                ),
              ),
              24.verticalSpace,

              // Title
              PrimaryTextField(
                controller: _titleController,
                hint: 'Song Title *',
                prefixIcon: const Icon(Icons.title, color: AppColors.primaryColor),
                validator: (value) =>
                    value?.isEmpty == true ? 'Title is required' : null,
              ),
              16.verticalSpace,

              // File Picker
              GestureDetector(
                onTap: _pickAudioFile,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: AppColors.boxClr,
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(
                      color: _audioFile != null
                          ? AppColors.primaryColor
                          : Colors.white.withOpacity(0.1),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _audioFile != null ? Icons.audiotrack : Icons.upload_file,
                        color: _audioFile != null
                            ? AppColors.primaryColor
                            : Colors.white.withOpacity(0.5),
                        size: 40.sp,
                      ),
                      8.verticalSpace,
                      Text(
                        _audioFile != null
                            ? 'File: ${_audioFile!.path.split('/').last}'
                            : 'Tap to select Song file',
                        style: AppTextStyles.regular.copyWith(
                          color: Colors.white,
                          fontSize: 14.sp,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
              32.verticalSpace,

              // Add Button
              _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primaryColor))
                  : PrimaryButton(
                      onTap: _saveMp3,
                      title: 'Publish',
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
