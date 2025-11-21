import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:the_woodlands_series/components/resource/app_colors.dart';
import 'package:the_woodlands_series/components/resource/app_textstyle.dart';
import 'package:the_woodlands_series/components/resource/app_assets.dart';
import 'package:the_woodlands_series/components/resource/app_routers.dart';
import 'package:the_woodlands_series/models/blog_model.dart';
import 'package:the_woodlands_series/models/user_model.dart';
import 'package:the_woodlands_series/screens/profile/profile_screen.dart';
import 'package:the_woodlands_series/bloc/auth/auth_bloc.dart';
import 'package:the_woodlands_series/bloc/auth/auth_state.dart';
import 'package:intl/intl.dart';

class BlogDetailScreen extends StatelessWidget {
  final BlogModel blog;

  const BlogDetailScreen({super.key, required this.blog});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM').format(blog.createdAt);

    return Scaffold(
      backgroundColor: AppColors.bgClr,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 20.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      Icons.arrow_back_ios,
                      color: Colors.white,
                      size: 20.sp,
                    ),
                  ),
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      final user = state is Authenticated ? state.user : null;
                      return GestureDetector(
                        onTap: () {
                          AppRouter.routeTo(
                            context,
                            ProfileScreen(
                              title: 'Profile',
                              image: AppAssets.profileImg,
                            ),
                          );
                        },
                        child: _buildUserAvatar(user),
                      );
                    },
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Blog tag
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          'BLOG',
                          style: AppTextStyles.medium.copyWith(
                            color: Colors.white,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    16.verticalSpace,
                    // Title
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: Text(
                        blog.title,
                        style: AppTextStyles.lufgaLarge.copyWith(
                          color: Colors.white,
                          fontSize: 28.sp,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                      ),
                    ),
                    16.verticalSpace,
                    // Author and date
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            color: Colors.white.withOpacity(0.6),
                            size: 16.sp,
                          ),
                          6.horizontalSpace,
                          Text(
                            'Posted by ${blog.author}',
                            style: AppTextStyles.medium.copyWith(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 14.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                    24.verticalSpace,
                    // Date indicator (left side)
                    Padding(
                      padding: EdgeInsets.only(left: 20.w),
                      child: Container(
                        width: 60.w,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        decoration: BoxDecoration(
                          color: AppColors.boxClr,
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(8.r),
                            bottomRight: Radius.circular(8.r),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            dateFormat.toUpperCase(),
                            style: AppTextStyles.medium.copyWith(
                              color: Colors.white,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    24.verticalSpace,
                    // Image
                    if (blog.imageUrl != null)
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12.r),
                          child: Image.network(
                            blog.imageUrl!,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 300.h,
                                color: AppColors.boxClr,
                                child: Icon(
                                  Icons.image_not_supported,
                                  color: Colors.white.withOpacity(0.3),
                                  size: 50.sp,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    32.verticalSpace,
                    // Content
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: Text(
                        blog.content,
                        style: AppTextStyles.medium.copyWith(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16.sp,
                          height: 1.8,
                        ),
                      ),
                    ),
                    40.verticalSpace,
                    // Social media icons
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: Row(
                        children: [
                          // Facebook
                          GestureDetector(
                            onTap: () async {
                              final url = Uri.parse(
                                'https://www.facebook.com/people/The-Woodlands-Series-LLC/61574936851241/',
                              );
                              if (await canLaunchUrl(url)) {
                                await launchUrl(
                                  url,
                                  mode: LaunchMode.externalApplication,
                                );
                              }
                            },
                            child: Container(
                              width: 40.w,
                              height: 40.h,
                              decoration: BoxDecoration(
                                color: Color(0xFF1877F2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.facebook,
                                color: Colors.white,
                                size: 20.sp,
                              ),
                            ),
                          ),
                          16.horizontalSpace,
                          // Instagram
                          GestureDetector(
                            onTap: () async {
                              final url = Uri.parse(
                                'https://www.instagram.com/thewoodlandsseries/',
                              );
                              if (await canLaunchUrl(url)) {
                                await launchUrl(
                                  url,
                                  mode: LaunchMode.externalApplication,
                                );
                              }
                            },
                            child: Container(
                              width: 40.w,
                              height: 40.h,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFFF58529),
                                    Color(0xFFDD2A7B),
                                    Color(0xFF8134AF),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 20.sp,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    40.verticalSpace,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserAvatar(UserModel? user) {
    // If user has a profile image, show it
    if (user?.profileImageUrl != null && user!.profileImageUrl!.isNotEmpty) {
      return Container(
        width: 37.h,
        height: 37.h,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.primaryColor.withOpacity(0.3),
            width: 2,
          ),
          image: DecorationImage(
            image: NetworkImage(user.profileImageUrl!),
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    // If user has no image, show avatar with initials
    if (user != null) {
      return Container(
        width: 37.h,
        height: 37.h,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryColor,
              AppColors.primaryColor.withOpacity(0.7),
            ],
          ),
        ),
        child: Center(
          child: Text(
            _getInitials(user.name),
            style: AppTextStyles.lufgaMedium.copyWith(
              color: Colors.white,
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    // Fallback to default image
    return Container(
      width: 37.h,
      height: 37.h,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        image: DecorationImage(
          image: AssetImage(AppAssets.profileImg),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return 'U';
  }
}
