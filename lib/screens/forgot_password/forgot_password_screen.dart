import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:the_woodlands_series/components/button/primary_button.dart';
import 'package:the_woodlands_series/components/resource/app_colors.dart';
import 'package:the_woodlands_series/components/resource/app_routers.dart';
import 'package:the_woodlands_series/components/resource/app_textstyle.dart';
import 'package:the_woodlands_series/components/resource/size_constants.dart';
import 'package:the_woodlands_series/components/textfield/primary_textfield.dart';
import 'package:the_woodlands_series/components/utils/custom_toast.dart';
import 'package:the_woodlands_series/services/user_firestore_service.dart';
import '../login_screen/login_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final email = _emailController.text.trim();

    setState(() {
      _isLoading = true;
    });

    try {
      // Check if email exists in Firestore and role is 'user'
      final user = await UserFirestoreService.getUserByEmail(email);

      if (user == null) {
        if (mounted) {
          CustomToast.showError(
            context,
            'No account found with this email address.',
          );
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Check if role is 'user' (not admin)
      if (user.role != 'user') {
        if (mounted) {
          CustomToast.showError(
            context,
            'Password reset is only available for regular users.',
          );
        }
        setState(() {
          _isLoading = false;
        });
        return;
      }

      // Send password reset email
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showSuccessDialog();
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _isLoading = false;
      });

      String errorMessage;
      switch (e.code) {
        case 'invalid-email':
          errorMessage = 'The email address is not valid.';
          break;
        case 'user-not-found':
          errorMessage = 'No account found with this email address.';
          break;
        case 'user-disabled':
          errorMessage = 'This account has been disabled.';
          break;
        case 'too-many-requests':
          errorMessage = 'Too many requests. Please try again later.';
          break;
        case 'network-request-failed':
          errorMessage = 'Network error. Please check your internet connection.';
          break;
        default:
          errorMessage = e.message ?? 'An error occurred. Please try again.';
      }

      if (mounted) {
        CustomToast.showError(context, errorMessage);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        CustomToast.showError(
          context,
          'An unexpected error occurred. Please try again.',
        );
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(
                color: AppColors.boxClr,
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Success Icon
                  Container(
                    width: 64.w,
                    height: 64.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryColor.withOpacity(0.2),
                    ),
                    child: Icon(
                      Icons.check_circle,
                      color: AppColors.primaryColor,
                      size: 40.sp,
                    ),
                  ),
                  24.verticalSpace,
                  // Title
                  Text(
                    'Reset Email Sent!',
                    style: AppTextStyles.lufgaLarge.copyWith(
                      color: Colors.white,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  16.verticalSpace,
                  // Guidance Message
                  Text(
                    'We\'ve sent a password reset link to:\n${_emailController.text.trim()}',
                    style: AppTextStyles.regular.copyWith(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14.sp,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  16.verticalSpace,
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(
                        color: AppColors.primaryColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'What to do next:',
                          style: AppTextStyles.medium.copyWith(
                            color: AppColors.primaryColor,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        8.verticalSpace,
                        _buildGuidanceItem(
                          '1. Check your email inbox',
                        ),
                        _buildGuidanceItem(
                          '2. Click the reset link in the email',
                        ),
                        _buildGuidanceItem(
                          '3. Create your new password',
                        ),
                        _buildGuidanceItem(
                          '4. Sign in with your new password',
                        ),
                      ],
                    ),
                  ),
                  24.verticalSpace,
                  // Login Button
                  PrimaryButton(
                    title: 'Back to Login',
                    onTap: () {
                      Navigator.of(context).pop(); // Close dialog
                      AppRouter.replace(
                        context,
                        const LoginScreen(),
                      );
                    },
                    shadow: true,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGuidanceItem(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(top: 6.h, right: 8.w),
            width: 4.w,
            height: 4.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.small.copyWith(
                color: Colors.white.withOpacity(0.7),
                fontSize: 11.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgClr,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: SizeCons.getResponsiveWidth(24),
              vertical: SizeCons.getResponsiveHeight(20),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  20.verticalSpace,
                  // Back Button
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: AppColors.boxClr,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 20.sp,
                      ),
                    ),
                  ),
                  40.verticalSpace,
                  // Title
                  Text(
                    'Forgot Password?',
                    style: AppTextStyles.lufgaLarge.copyWith(
                      color: AppColors.primaryColor,
                      fontSize: 28.sp,
                    ),
                  ),
                  8.verticalSpace,
                  Text(
                    'Don\'t worry! Enter your email address and we\'ll send you a link to reset your password.',
                    style: AppTextStyles.regular.copyWith(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14.sp,
                    ),
                  ),
                  40.verticalSpace,
                  // Email Field
                  PrimaryTextField(
                    controller: _emailController,
                    hint: 'Email Address',
                    keyboard: TextInputType.emailAddress,
                    shadow: true,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your email address';
                      }
                      if (!value.contains('@') || !value.contains('.')) {
                        return 'Please enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  32.verticalSpace,
                  // Send Reset Email Button
                  PrimaryButton(
                    title: _isLoading ? 'Sending...' : 'Send Reset Link',
                    onTap: _isLoading ? null : _sendResetEmail,
                    shadow: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

