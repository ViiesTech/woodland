import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:the_woodlands_series/components/button/primary_button.dart';
import 'package:the_woodlands_series/components/checkbox/checkbox.dart';
import 'package:the_woodlands_series/components/checkbox/primary_checkbox.dart';
import 'package:the_woodlands_series/components/resource/app_assets.dart';
import 'package:the_woodlands_series/components/resource/app_colors.dart';
import 'package:the_woodlands_series/components/resource/app_routers.dart';
import 'package:the_woodlands_series/components/resource/app_textstyle.dart';
import 'package:the_woodlands_series/components/textfield/primary_textfield.dart';
import 'package:the_woodlands_series/screens/login_screen/login_screen.dart';
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

  bool isAgreed = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  'The Woodlands Series',
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
                // Social Login Buttons
                Row(
                  children: [
                    Expanded(
                      child: _buildSocialButton(
                        'Facebook',
                        AppAssets.fbIcon,
                        Colors.blue,
                      ),
                    ),
                    16.horizontalSpace,
                    Expanded(
                      child: _buildSocialButton(
                        'Google',
                        AppAssets.googleIcon,
                        Colors.red,
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
    );
  }

  Widget _buildSocialButton(String text, String icon, Color iconColor) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.boxClr,
        borderRadius: BorderRadius.circular(SizeCons.getResponsiveRadius(12)),
        boxShadow: [
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
        ],
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
    // Navigate to dashboard
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const DashboardScreen()),
    );
  }
}
