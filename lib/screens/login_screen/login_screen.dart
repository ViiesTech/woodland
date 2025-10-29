import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:the_woodlands_series/components/button/primary_button.dart';
import 'package:the_woodlands_series/components/checkbox/primary_checkbox.dart';
import 'package:the_woodlands_series/components/resource/app_assets.dart';
import 'package:the_woodlands_series/components/resource/app_colors.dart';
import 'package:the_woodlands_series/components/resource/app_routers.dart';
import 'package:the_woodlands_series/components/resource/app_textstyle.dart';
import 'package:the_woodlands_series/components/textfield/primary_textfield.dart';
import 'package:the_woodlands_series/components/utils/custom_toast.dart';
import 'package:the_woodlands_series/screens/register/register_screen.dart';
import 'package:the_woodlands_series/bloc/auth/auth_bloc.dart';
import 'package:the_woodlands_series/bloc/auth/auth_event.dart';
import 'package:the_woodlands_series/bloc/auth/auth_state.dart';
import '../../components/resource/size_constants.dart';
import '../dashboard_screen/dashboard_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool isAgreed = false;
  bool rememberMe = false;

  static const String _rememberMeKey = 'remember_me';
  static const String _savedEmailKey = 'saved_email';
  static const String _savedPasswordHashKey = 'saved_password_hash';

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Load saved credentials from cache
  Future<void> _loadSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedRememberMe = prefs.getBool(_rememberMeKey) ?? false;

      if (savedRememberMe) {
        final savedEmail = prefs.getString(_savedEmailKey);
        final savedPasswordHash = prefs.getString(_savedPasswordHashKey);

        if (savedEmail != null && savedPasswordHash != null) {
          final decodedPassword = _decodePassword(savedPasswordHash);
          setState(() {
            _emailController.text = savedEmail;
            _passwordController.text = decodedPassword;
            rememberMe = true;
          });
        }
      }
    } catch (e) {
      print('Error loading saved credentials: $e');
    }
  }

  // Save credentials to cache
  Future<void> _saveCredentials(String email, String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (rememberMe) {
        // Hash the password before saving
        final passwordHash = _hashPassword(password);
        await prefs.setBool(_rememberMeKey, true);
        await prefs.setString(_savedEmailKey, email);
        await prefs.setString(_savedPasswordHashKey, passwordHash);
      } else {
        // Clear saved credentials if remember me is not checked
        await prefs.remove(_rememberMeKey);
        await prefs.remove(_savedEmailKey);
        await prefs.remove(_savedPasswordHashKey);
      }
    } catch (e) {
      print('Error saving credentials: $e');
    }
  }

  // Encode password using base64 (reversible for remember me feature)
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return base64.encode(bytes);
  }

  // Decode password from base64
  String _decodePassword(String encodedPassword) {
    try {
      return utf8.decode(base64.decode(encodedPassword));
    } catch (e) {
      return '';
    }
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

          // Save credentials if remember me is checked and login was successful
          _saveCredentials(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );

          // Show success message
          CustomToast.showSuccess(context, 'Login successful!');
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
                    'Sign In',
                    style: AppTextStyles.lufgaLarge.copyWith(
                      color: AppColors.primaryColor,
                    ),
                  ),
                  40.verticalSpace,
                  // Social Login Buttons
                  Row(
                    children: [
                      // Expanded(
                      //   child: _buildSocialButton(
                      //     'Facebook',
                      //     AppAssets.fbIcon,
                      //     Colors.blue,
                      //     shadow: true,
                      //   ),
                      // ),
                      // 16.horizontalSpace,
                      Expanded(
                        child: GestureDetector(
                          onTap: _signInWithGoogle,
                          child: _buildSocialButton(
                            'Google',
                            AppAssets.googleIcon,
                            Colors.red,
                            shadow: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  16.verticalSpace,
                  Row(
                    children: [
                      Expanded(
                        child: Container(height: 1, color: Color(0xffE0E5EC)),
                      ),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: SizeCons.getResponsiveWidth(16),
                        ),
                        child: Text(
                          'Or',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: SizeCons.getResponsiveFontSize(16),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(height: 1, color: Color(0xffE0E5EC)),
                      ),
                    ],
                  ),
                  24.verticalSpace,
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
                  ),
                  14.verticalSpace,
                  // Remember Me and Forgot Password on same line
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Remember Me Checkbox
                      Expanded(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,

                          children: [
                            PrimaryCheckBox(
                              value: rememberMe,
                              onChanged: (val) {
                                setState(() {
                                  rememberMe = !rememberMe;
                                });
                              },
                              keyId: "rememberMe",
                            ),
                            8.horizontalSpace,
                            Expanded(
                              child: Text(
                                'Remember Me',
                                style: AppTextStyles.small.copyWith(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Forgot Password
                      TextButton(
                        onPressed: () {
                          // Handle forgot password
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(horizontal: 8.w),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Forgot Password?',
                          style: AppTextStyles.small.copyWith(
                            color: AppColors.primaryColor,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  26.verticalSpace,

                  // Terms Agreement
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
                  PrimaryButton(title: 'Sign In', onTap: _signIn, shadow: true),
                  16.verticalSpace,
                  // Sign Up Link
                  GestureDetector(
                    onTap: () {
                      AppRouter.routeTo(context, RegisterScreen());
                    },
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: SizeCons.getResponsiveFontSize(14),
                          color: Colors.grey[400],
                        ),
                        children: [
                          const TextSpan(text: "Don't have an account? "),
                          TextSpan(
                            text: 'Sign Up',
                            style: TextStyle(
                              color: Colors.green,
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

  Widget _buildSocialButton(
    String text,
    String icon,
    Color iconColor, {
    bool shadow = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.boxClr,
        borderRadius: BorderRadius.circular(SizeCons.getResponsiveRadius(12)),
        boxShadow: shadow
            ? [
                BoxShadow(
                  color: AppColors.boxClr.withOpacity(0.2),
                  blurRadius: 8.r,
                  offset: Offset(0, 4.h),
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4.r,
                  offset: Offset(0, 2.h),
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      padding: EdgeInsets.symmetric(vertical: 16.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(icon, height: 24.h),
          8.horizontalSpace,
          Text(
            text,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: SizeCons.getResponsiveFontSize(16),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _signIn() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // Validate input
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

    if (!isAgreed) {
      CustomToast.showError(
        context,
        'Please agree to Terms of Service and Privacy Policy',
      );
      return;
    }

    // Dispatch login event to BLoC with Firebase authentication
    context.read<AuthBloc>().add(
      LoginWithEmail(email: email, password: password),
    );
  }

  void _signInWithGoogle() {
    // Dispatch Google login event to BLoC
    context.read<AuthBloc>().add(const LoginWithGoogle());
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
                    'Signing in...',
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
