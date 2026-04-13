import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:the_woodlands_series/components/resource/app_colors.dart';
import 'package:the_woodlands_series/components/resource/app_textstyle.dart';
import 'package:the_woodlands_series/components/resource/app_routers.dart';
import 'package:the_woodlands_series/components/resource/app_assets.dart';
import 'package:the_woodlands_series/services/blog_service.dart';
import 'package:the_woodlands_series/models/blog_model.dart';
import 'package:the_woodlands_series/models/user_model.dart';
import 'package:the_woodlands_series/screens/blog/blog_detail_screen.dart';
import 'package:the_woodlands_series/screens/blog/add_blog_screen.dart';
import 'package:the_woodlands_series/screens/profile/profile_screen.dart';
import 'package:the_woodlands_series/bloc/auth/auth_bloc.dart';
import 'package:the_woodlands_series/bloc/auth/auth_state.dart';
import 'package:intl/intl.dart';

class BlogListScreen extends StatelessWidget {
  const BlogListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final isAdmin = authState is Authenticated && authState.user.role == 'admin';

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
                  Text(
                    'Blog',
                    style: AppTextStyles.lufgaLarge.copyWith(
                      color: Colors.white,
                      fontSize: 28.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      // Add Blog Icon (only for admin)
                      if (isAdmin)
                        GestureDetector(
                          onTap: () {
                            AppRouter.routeTo(context, const AddBlogScreen());
                          },
                          child: Container(
                            margin: EdgeInsets.only(right: 12.w),
                            padding: EdgeInsets.all(8.w),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.add,
                              color: Colors.black,
                              size: 20.sp,
                            ),
                          ),
                        ),
                      BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, state) {
                          final user = state is Authenticated
                              ? state.user
                              : null;
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
                ],
              ),
            ),
            // Blog List
            Expanded(
              child: StreamBuilder<List<BlogModel>>(
                stream: BlogService.getAllBlogs(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primaryColor,
                        ),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error loading blogs',
                        style: AppTextStyles.medium.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    );
                  }

                  final blogs = snapshot.data ?? [];

                  if (blogs.isEmpty) {
                    return Center(
                      child: Text(
                        'No blog posts yet',
                        style: AppTextStyles.medium.copyWith(
                          color: Colors.white.withOpacity(0.6),
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    itemCount: blogs.length,
                    itemBuilder: (context, index) {
                      final blog = blogs[index];
                      return _buildBlogCard(context, blog);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
      },
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

  Widget _buildBlogCard(BuildContext context, BlogModel blog) {
    final dateFormat = DateFormat('dd MMM').format(blog.createdAt);

    return GestureDetector(
      onTap: () {
        AppRouter.routeTo(context, BlogDetailScreen(blog: blog));
      },
      child: Container(
        margin: EdgeInsets.only(bottom: 24.h),
        decoration: BoxDecoration(
          color: AppColors.boxClr,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with date overlay
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
                  child: blog.imageUrl != null
                      ? Image.network(
                          blog.imageUrl!,
                          width: double.infinity,
                          height: 200.h,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 200.h,
                              color: AppColors.bgClr,
                              child: Icon(
                                Icons.image_not_supported,
                                color: Colors.white.withOpacity(0.3),
                                size: 50.sp,
                              ),
                            );
                          },
                        )
                      : Container(
                          height: 200.h,
                          color: AppColors.bgClr,
                          child: Icon(
                            Icons.article,
                            color: Colors.white.withOpacity(0.3),
                            size: 50.sp,
                          ),
                        ),
                ),
                // Date overlay
                Positioned(
                  top: 16.h,
                  left: 16.w,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 8.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      dateFormat.toUpperCase(),
                      style: AppTextStyles.medium.copyWith(
                        color: Colors.black,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Content
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Blog tag
                  Container(
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
                  12.verticalSpace,
                  // Title
                  Text(
                    blog.title,
                    style: AppTextStyles.lufgaLarge.copyWith(
                      color: Colors.white,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  12.verticalSpace,
                  // Author and comments
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        color: Colors.white.withOpacity(0.6),
                        size: 16.sp,
                      ),
                      6.horizontalSpace,
                      Text(
                        'By ${blog.author}',
                        style: AppTextStyles.medium.copyWith(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 14.sp,
                        ),
                      ),
                      16.horizontalSpace,
                      Icon(
                        Icons.comment_outlined,
                        color: Colors.white.withOpacity(0.6),
                        size: 16.sp,
                      ),
                      6.horizontalSpace,
                      Text(
                        '${blog.commentCount}',
                        style: AppTextStyles.medium.copyWith(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 14.sp,
                        ),
                      ),
                    ],
                  ),
                  16.verticalSpace,
                  // Preview text
                  Text(
                    blog.content.length > 150
                        ? '${blog.content.substring(0, 150)}...'
                        : blog.content,
                    style: AppTextStyles.medium.copyWith(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14.sp,
                      height: 1.5,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  16.verticalSpace,
                  // Continue reading button
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Center(
                      child: Text(
                        'CONTINUE READING',
                        style: AppTextStyles.medium.copyWith(
                          color: Colors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

