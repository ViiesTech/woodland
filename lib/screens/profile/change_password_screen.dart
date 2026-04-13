import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:the_woodlands_series/components/button/primary_button.dart';
import 'package:the_woodlands_series/components/resource/app_colors.dart';
import 'package:the_woodlands_series/components/resource/app_textstyle.dart';
import 'package:the_woodlands_series/components/textfield/primary_textfield.dart';
import 'package:the_woodlands_series/components/utils/custom_toast.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    // Validate input
    if (_currentPasswordController.text.trim().isEmpty) {
      CustomToast.showError(context, 'Please enter your current password');
      return;
    }

    if (_newPasswordController.text.trim().isEmpty) {
      CustomToast.showError(context, 'Please enter a new password');
      return;
    }

    if (_newPasswordController.text.trim().length < 6) {
      CustomToast.showError(
        context,
        'New password must be at least 6 characters',
      );
      return;
    }

    if (_confirmPasswordController.text.trim().isEmpty) {
      CustomToast.showError(context, 'Please confirm your new password');
      return;
    }

    if (_newPasswordController.text.trim() !=
        _confirmPasswordController.text.trim()) {
      CustomToast.showError(context, 'Passwords do not match');
      return;
    }

    if (_currentPasswordController.text.trim() ==
        _newPasswordController.text.trim()) {
      CustomToast.showError(
        context,
        'New password must be different from current password',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null || user.email == null) {
        CustomToast.showError(context, 'User not logged in');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Re-authenticate user with current password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _currentPasswordController.text.trim(),
      );

      await user.reauthenticateWithCredential(credential);

      // Update password
      await user.updatePassword(_newPasswordController.text.trim());

      // Success
      if (mounted) {
        CustomToast.showSuccess(context, 'Password changed successfully!');
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'wrong-password':
          errorMessage = 'Current password is incorrect';
          break;
        case 'weak-password':
          errorMessage = 'New password is too weak';
          break;
        case 'requires-recent-login':
          errorMessage = 'Please log out and log in again to change password';
          break;
        default:
          errorMessage = 'Failed to change password: ${e.message}';
      }
      CustomToast.showError(context, errorMessage);
    } catch (e) {
      CustomToast.showError(context, 'An error occurred: ${e.toString()}');
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
    return Scaffold(
      backgroundColor: AppColors.bgClr,
      appBar: AppBar(
        backgroundColor: AppColors.bgClr,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
        ),
        centerTitle: true,
        title: Text(
          'Change Password',
          style: AppTextStyles.lufgaLarge.copyWith(
            color: Colors.white,
            fontSize: 20.sp,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              40.verticalSpace,

              // Info Text
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: AppColors.primaryColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.primaryColor,
                      size: 20.sp,
                    ),
                    12.horizontalSpace,
                    Expanded(
                      child: Text(
                        'Enter your current password to set a new one',
                        style: AppTextStyles.lufgaMedium.copyWith(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 13.sp,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              40.verticalSpace,

              // Current Password Field
              Text(
                'Current Password',
                style: AppTextStyles.lufgaMedium.copyWith(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              12.verticalSpace,
              PrimaryTextField(
                controller: _currentPasswordController,
                hint: 'Enter current password',
                isPassword: true,
                shadow: true,
              ),
              24.verticalSpace,

              // New Password Field
              Text(
                'New Password',
                style: AppTextStyles.lufgaMedium.copyWith(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              12.verticalSpace,
              PrimaryTextField(
                controller: _newPasswordController,
                hint: 'Enter new password (min 6 characters)',
                isPassword: true,
                shadow: true,
              ),
              24.verticalSpace,

              // Confirm New Password Field
              Text(
                'Confirm New Password',
                style: AppTextStyles.lufgaMedium.copyWith(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              12.verticalSpace,
              PrimaryTextField(
                controller: _confirmPasswordController,
                hint: 'Re-enter new password',
                isPassword: true,
                shadow: true,
              ),

              40.verticalSpace,

              // Change Password Button
              PrimaryButton(
                title: _isLoading ? 'Changing Password...' : 'Change Password',
                onTap: _isLoading ? () {} : _changePassword,
                shadow: true,
              ),

              40.verticalSpace,

              // Security Tips
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: AppColors.boxClr,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Password Tips',
                      style: AppTextStyles.lufgaMedium.copyWith(
                        color: Colors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    12.verticalSpace,
                    _buildTipItem('Use at least 6 characters'),
                    _buildTipItem('Include numbers and special characters'),
                    _buildTipItem('Avoid common words or patterns'),
                    _buildTipItem('Don\'t reuse old passwords'),
                  ],
                ),
              ),

              40.verticalSpace,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            color: AppColors.primaryColor,
            size: 16.sp,
          ),
          8.horizontalSpace,
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.lufgaMedium.copyWith(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
