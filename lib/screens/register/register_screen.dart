import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:the_woodlands_series/components/button/primary_button.dart';
import 'package:the_woodlands_series/components/checkbox/primary_checkbox.dart';
import 'package:the_woodlands_series/components/resource/app_colors.dart';
import 'package:the_woodlands_series/components/resource/app_routers.dart';
import 'package:the_woodlands_series/components/resource/app_textstyle.dart';
import 'package:the_woodlands_series/components/textfield/primary_textfield.dart';
import 'package:the_woodlands_series/components/utils/custom_toast.dart';
import 'package:the_woodlands_series/screens/login_screen/login_screen.dart';
import 'package:the_woodlands_series/bloc/auth/auth_bloc.dart';
import 'package:the_woodlands_series/bloc/auth/auth_event.dart';
import 'package:the_woodlands_series/bloc/auth/auth_state.dart';
import '../../components/resource/size_constants.dart';
import '../dashboard_screen/dashboard_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool isAgreed = false;

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthLoading) {
          // Show loading dialog
          _showLoadingDialog(context);
        } else if (state is Authenticated) {
          // Dismiss loading dialog if showing
          try {
            Navigator.of(context, rootNavigator: true).pop();
          } catch (e) {
            // Dialog might not be showing
          }
          // Show success message
          CustomToast.showSuccess(context, 'Account created successfully!');
          // Navigate to dashboard
          Future.delayed(const Duration(milliseconds: 500), () {
            if (context.mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const DashboardScreen(),
                ),
              );
            }
          });
        } else if (state is AuthError) {
          // Dismiss loading dialog if showing
          try {
            Navigator.of(context, rootNavigator: true).pop();
          } catch (e) {
            // Dialog might not be showing
          }
          // Show error message
          CustomToast.showError(context, state.message);
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: SizeCons.getResponsiveWidth(24),
                vertical: SizeCons.getResponsiveHeight(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  20.verticalSpace,
                  Text(
                    'GlennVerse',
                    style: TextStyle(
                      fontFamily: 'cursive',
                      fontSize: SizeCons.getResponsiveFontSize(20),
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
                  ),
                  46.verticalSpace,
                  // Sign In Title
                  Text(
                    'Sign Up',
                    style: AppTextStyles.lufgaLarge.copyWith(
                      color: AppColors.primaryColor,
                    ),
                  ),
                  40.verticalSpace,

                  PrimaryTextField(
                    controller: _nameController,
                    hint: 'Name',
                    shadow: true,
                  ),
                  16.verticalSpace,
                  PrimaryTextField(
                    controller: _emailController,
                    hint: 'Email/Phone Number',
                    shadow: true,
                  ),
                  16.verticalSpace,
                  PrimaryTextField(
                    controller: _passwordController,
                    hint: 'Password',
                    isPassword: true,
                    shadow: true,
                  ),
                  16.verticalSpace,
                  PrimaryTextField(
                    controller: _confirmPasswordController,
                    hint: 'Confirm Password',
                    isPassword: true,
                    shadow: true,
                  ),
                  16.verticalSpace,
                  Row(
                    children: [
                      PrimaryCheckBox(
                        value: isAgreed,
                        onChanged: (val) {
                          setState(() {
                            isAgreed = !isAgreed;
                          });
                        },
                        keyId: "isAgreed",
                      ),
                      8.horizontalSpace,
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(text: "I agree to the "),
                              TextSpan(
                                text: "Terms of Service",
                                style: AppTextStyles.small.copyWith(
                                  color: AppColors.primaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              TextSpan(text: " and "),
                              TextSpan(
                                text: "Privacy Policy",
                                style: AppTextStyles.small.copyWith(
                                  color: AppColors.primaryColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  26.verticalSpace,
                  PrimaryButton(
                    title: 'Create Account',
                    onTap: _signIn,
                    shadow: true,
                  ),
                  18.verticalSpace,
                  // Sign Up Link
                  GestureDetector(
                    onTap: () {
                      AppRouter.routeTo(context, LoginScreen());
                    },
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: SizeCons.getResponsiveFontSize(14),
                          color: AppColors.greyColor,
                        ),
                        children: [
                          const TextSpan(text: "Already have an account? "),
                          TextSpan(
                            text: 'Sign In',
                            style: TextStyle(
                              color: AppColors.primaryColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: SizeCons.getResponsiveHeight(20)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _signIn() {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    // Validate input
    if (name.isEmpty) {
      CustomToast.showError(context, 'Please enter your name');
      return;
    }

    if (name.length < 3) {
      CustomToast.showError(context, 'Name must be at least 3 characters');
      return;
    }

    if (email.isEmpty) {
      CustomToast.showError(context, 'Please enter email');
      return;
    }

    // Simple email validation
    if (!email.contains('@') || !email.contains('.')) {
      CustomToast.showError(context, 'Please enter a valid email');
      return;
    }

    if (password.isEmpty) {
      CustomToast.showError(context, 'Please enter password');
      return;
    }

    if (password.length < 6) {
      CustomToast.showError(context, 'Password must be at least 6 characters');
      return;
    }

    if (confirmPassword.isEmpty) {
      CustomToast.showError(context, 'Please confirm your password');
      return;
    }

    if (password != confirmPassword) {
      CustomToast.showError(context, 'Passwords do not match');
      return;
    }

    if (!isAgreed) {
      CustomToast.showError(
        context,
        'Please agree to Terms of Service and Privacy Policy',
      );
      return;
    }

    // Dispatch register event to BLoC with Firebase authentication
    context.read<AuthBloc>().add(
      RegisterWithEmail(email: email, password: password, name: name),
    );
  }

  void _showLoadingDialog(BuildContext context) {
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
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: AppColors.boxClr,
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primaryColor,
                    ),
                  ),
                  20.verticalSpace,
                  Text(
                    'Creating account...',
                    style: AppTextStyles.lufgaMedium.copyWith(
                      color: Colors.white,
                      fontSize: 16.sp,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
