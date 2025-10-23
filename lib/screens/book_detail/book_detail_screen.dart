import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:the_woodlands_series/Components/resource/app_routers.dart';
import 'package:the_woodlands_series/components/resource/size_constants.dart';
import 'package:the_woodlands_series/screens/reading/listen_screen.dart';

import '../../components/resource/app_colors.dart';
import '../../components/resource/app_textstyle.dart';
import '../reading/reading_screen.dart';
import '../reading/listen_screen.dart';

class BookDetailScreen extends StatelessWidget {
  final String title;
  final String author;
  final String imageAsset;
  final String listenTime;
  final String readTime;

  const BookDetailScreen({
    super.key,
    required this.title,
    required this.author,
    required this.imageAsset,
    required this.listenTime,
    required this.readTime,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: SizeCons.getHeight(context) * 0.9,
              child: Stack(
                children: [
                  // Blurred Background
                  Container(
                    height: 432.h,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(imageAsset),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.w,
                      vertical: 20.h,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () {
                            AppRouter.routeBack(context);
                          },
                          child: Icon(
                            Icons.arrow_back_ios,
                            color: Colors.white,
                            size: 20.sp,
                          ),
                        ),
                        Icon(
                          Icons.bookmark_outline,
                          color: Colors.white,
                          size: 20.sp,
                        ),
                      ],
                    ),
                  ),

                  // Book Cover and Info
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      height: SizeCons.getHeight(context) * 0.65,
                      decoration: BoxDecoration(
                        color: AppColors.bgClr,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(50.r),
                          topRight: Radius.circular(50.r),
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.only(top: 90.h),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 40.w),
                                child: Text(
                                  title,
                                  style: AppTextStyles.lufgaLarge.copyWith(
                                    color: Colors.white,
                                    fontSize: 18.sp,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              8.verticalSpace,
                              // Author
                              Text(
                                author,
                                style: AppTextStyles.regular.copyWith(
                                  color: Colors.grey[400],
                                  fontSize: 14.sp,
                                ),
                              ),
                              20.verticalSpace,
                              // Action Buttons
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      AppRouter.routeTo(
                                        context,
                                        ReadingScreen(
                                          title: title,
                                          author: author,
                                          imageAsset: imageAsset,
                                        ),
                                      );
                                    },
                                    child: _buildActionButton(
                                      icon: Icons.menu_book,
                                      text: 'Read Book',
                                    ),
                                  ),
                                  20.horizontalSpace,
                                  GestureDetector(
                                    onTap: () {
                                      AppRouter.routeTo(
                                        context,
                                        ListenScreen(
                                          title: title,
                                          author: author,
                                          imageAsset: imageAsset,
                                        ),
                                      );
                                    },
                                    child: _buildActionButton(
                                      icon: Icons.headphones,
                                      text: 'Listen Book',
                                    ),
                                  ),
                                ],
                              ),

                              // Content Sections
                              Padding(
                                padding: EdgeInsets.all(20.w),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Duration Section
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.access_time,
                                          color: AppColors.primaryColor,
                                          size: 18.sp,
                                        ),
                                        5.horizontalSpace,
                                        Text(
                                          '18 min',
                                          style: AppTextStyles.medium.copyWith(
                                            color: AppColors.primaryColor,
                                            fontSize: 14.sp,
                                          ),
                                        ),
                                      ],
                                    ),
                                    16.verticalSpace,

                                    // Project Management Section
                                    Text(
                                      'Project Management for the Unofficial Project Manager',
                                      style: AppTextStyles.lufgaLarge.copyWith(
                                        color: Colors.white,
                                        fontSize: 16.sp,
                                      ),
                                    ),
                                    8.verticalSpace,
                                    Text(
                                      'Kory Kogon, Suzette Blakemore, and James wood',
                                      style: AppTextStyles.regular.copyWith(
                                        color: Colors.white,
                                        fontSize: 14.sp,
                                      ),
                                    ),
                                    4.verticalSpace,
                                    Text(
                                      'A FranklinConvey Title',
                                      style: AppTextStyles.regular.copyWith(
                                        color: Colors.grey[400],
                                        fontSize: 12.sp,
                                      ),
                                    ),
                                    30.verticalSpace,

                                    // About this Book Section
                                    Text(
                                      'About this Book',
                                      style: AppTextStyles.lufgaLarge.copyWith(
                                        color: Colors.white,
                                        fontSize: 16.sp,
                                      ),
                                    ),
                                    8.verticalSpace,
                                    Text(
                                      'Getting Along (2022) describes the importance of workplace interactions and their effects on productivity and creativity.',
                                      style: AppTextStyles.regular.copyWith(
                                        color: Colors.grey[300],
                                        fontSize: 14.sp,
                                        height: 1.5,
                                      ),
                                    ),
                                    30.verticalSpace,

                                    // Similar Books Section
                                    Text(
                                      'Similar Books',
                                      style: AppTextStyles.lufgaLarge.copyWith(
                                        color: Colors.white,
                                        fontSize: 18.sp,
                                      ),
                                    ),
                                    16.verticalSpace,
                                    SizedBox(
                                      height: 200.h,
                                      child: ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: 3,
                                        itemBuilder: (context, index) {
                                          final books = [
                                            {
                                              'title': 'Glenn s duquette',
                                              'author': 'Mark mcallister',
                                              'image':
                                                  'assets/tempImg/temp1.png',
                                            },
                                            {
                                              'title': 'ODE TO SIR',
                                              'author': 'Mark mcallister',
                                              'image':
                                                  'assets/tempImg/temp2.png',
                                            },
                                            {
                                              'title': 'Sunflower',
                                              'author': 'Mark mcallister',
                                              'image':
                                                  'assets/tempImg/temp3.png',
                                            },
                                          ];
                                          final book = books[index];
                                          return Container(
                                            width: 140.w,
                                            margin: EdgeInsets.only(
                                              right: 16.w,
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Container(
                                                  height: 120.h,
                                                  decoration: BoxDecoration(
                                                    image: DecorationImage(
                                                      image: AssetImage(
                                                        book['image']!,
                                                      ),
                                                      fit: BoxFit.cover,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8.r,
                                                        ),
                                                  ),
                                                ),
                                                8.verticalSpace,
                                                Text(
                                                  book['title']!,
                                                  style: AppTextStyles.medium
                                                      .copyWith(
                                                        color: Colors.white,
                                                        fontSize: 12.sp,
                                                      ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                4.verticalSpace,
                                                Text(
                                                  book['author']!,
                                                  style: AppTextStyles.regular
                                                      .copyWith(
                                                        color: Colors.grey[400],
                                                        fontSize: 10.sp,
                                                      ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                8.verticalSpace,
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.headphones,
                                                      color: Colors.grey[400],
                                                      size: 10.sp,
                                                    ),
                                                    2.horizontalSpace,
                                                    Text(
                                                      '5m',
                                                      style: AppTextStyles
                                                          .regular
                                                          .copyWith(
                                                            color: Colors
                                                                .grey[400],
                                                            fontSize: 10.sp,
                                                          ),
                                                    ),
                                                    8.horizontalSpace,
                                                    Icon(
                                                      Icons.visibility,
                                                      color: Colors.grey[400],
                                                      size: 10.sp,
                                                    ),
                                                    2.horizontalSpace,
                                                    Text(
                                                      '8m',
                                                      style: AppTextStyles
                                                          .regular
                                                          .copyWith(
                                                            color: Colors
                                                                .grey[400],
                                                            fontSize: 10.sp,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    20.verticalSpace,
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: EdgeInsets.only(top: 120.h),
                      child: Container(
                        height: 159.h,
                        width: 159.w,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage(imageAsset),
                            fit: BoxFit.cover,
                          ),
                          borderRadius: BorderRadius.circular(12.r),
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

  Widget _buildActionButton({required IconData icon, required String text}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.boxClr,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18.sp),
          8.horizontalSpace,
          Text(
            text,
            style: AppTextStyles.regular.copyWith(
              color: Colors.white,
              fontSize: 14.sp,
            ),
          ),
        ],
      ),
    );
  }
}
