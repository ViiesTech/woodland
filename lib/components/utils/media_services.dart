// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:the_woodlands_series/components/resource/app_routers.dart';

class MediaServices {
  static Future<File?> showMediaPickerSheet(BuildContext context) async {
    final picker = ImagePicker();
    File? selectedImage;

    await showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 16.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30.r),
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // SvgPicture.asset(AppAssets.horizontal, width: 72.w),
            10.verticalSpace,
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a Photo'),
              onTap: () async {
                final picked = await picker.pickImage(
                  source: ImageSource.camera,
                );
                if (picked != null) {
                  selectedImage = File(picked.path);
                }
                AppRouter.routeBack(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () async {
                final picked = await picker.pickImage(
                  source: ImageSource.gallery,
                );
                if (picked != null) {
                  selectedImage = File(picked.path);
                }
                AppRouter.routeBack(context);
              },
            ),
          ],
        ),
      ),
    );

    return selectedImage;
  }
}
