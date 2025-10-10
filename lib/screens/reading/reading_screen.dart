import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:the_woodlands_series/components/button/primary_button.dart';
import 'package:the_woodlands_series/components/resource/app_routers.dart';
import '../../components/resource/app_colors.dart';
import '../../components/resource/app_textstyle.dart';

class ReadingScreen extends StatelessWidget {
  final String title;
  final String author;
  final String imageAsset;

  const ReadingScreen({
    super.key,
    required this.title,
    required this.author,
    required this.imageAsset,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgClr,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 220.h,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30.r),
                bottomRight: Radius.circular(30.r),
              ),
            ),
            child: Stack(
              children: [
                // Blurred Background
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(imageAsset),
                        fit: BoxFit.cover,
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(30.r),
                        bottomRight: Radius.circular(30.r),
                      ),
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black26.withOpacity(0.2),
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(30.r),
                            bottomRight: Radius.circular(30.r),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 50.h,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => AppRouter.routeBack(context),
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
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 20.h, left: 20.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Chapter 2',
                          style: AppTextStyles.medium.copyWith(
                            color: AppColors.primaryColor,
                            fontSize: 12.sp,
                          ),
                        ),
                        Text(
                          'The good guy',
                          style: AppTextStyles.lufgaLarge.copyWith(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Mark mcallister',
                          style: AppTextStyles.regular.copyWith(
                            color: Colors.grey[400],
                            fontSize: 12.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    25.verticalSpace,
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section Heading
                        Text(
                          'What is in it for me? Learn how to become an effective unofficial project manager',
                          style: AppTextStyles.lufgaLarge.copyWith(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        24.verticalSpace,

                        // Body Text - First Paragraph
                        Text(
                          'Far far away, behind the word mountains, far from the countries Vokalia and Consonantia, there live the blind texts. Separated they live in Bookmarksgrove right at the coast of the Semantics, a large language ocean.',
                          style: AppTextStyles.regular.copyWith(
                            color: Colors.white,
                            fontSize: 14.sp,
                            height: 1.7,
                          ),
                          textAlign: TextAlign.justify,
                        ),
                        20.verticalSpace,

                        // Second Paragraph
                        Text(
                          'A small river named Duden flows by their place and supplies it with the necessary regelialia. It is a paradisematic country, in which roasted parts of sentences fly into your mouth.',
                          style: AppTextStyles.regular.copyWith(
                            color: Colors.white,
                            fontSize: 14.sp,
                            height: 1.7,
                          ),
                          textAlign: TextAlign.justify,
                        ),
                        20.verticalSpace,

                        // Third Paragraph
                        Text(
                          'Even the all-powerful Pointing has no control about the blind texts it is an almost unorthographic life One day however a small line of blind text by the name of Lorem Ipsum decided to leave for the far World of Grammar.',
                          style: AppTextStyles.regular.copyWith(
                            color: Colors.white,
                            fontSize: 14.sp,
                            height: 1.7,
                          ),
                          textAlign: TextAlign.justify,
                        ),
                        20.verticalSpace,

                        // Fourth Paragraph
                        Text(
                          'The Big Oxmox advised her not to do so, because there were thousands of bad Commas, wild Question Marks and devious Semikoli, but the Little Blind Text didn\'t listen.',
                          style: AppTextStyles.regular.copyWith(
                            color: Colors.white,
                            fontSize: 14.sp,
                            height: 1.7,
                          ),
                          textAlign: TextAlign.justify,
                        ),
                        20.verticalSpace,

                        // Fifth Paragraph
                        Text(
                          'She packed her seven versalia, put her initial into the belt and made herself on the way. When she reached the first hills of the Italic Mountains, she had a last view back on the skyline of her hometown Bookmarksgrove, the headline of Alphabet Village and the subline of her own road, the Line Lane.',
                          style: AppTextStyles.regular.copyWith(
                            color: Colors.white,
                            fontSize: 14.sp,
                            height: 1.7,
                          ),
                          textAlign: TextAlign.justify,
                        ),
                        20.verticalSpace,

                        // Sixth Paragraph
                        Text(
                          'Pityful a rethoric question ran over her cheek, then she continued her way. On her way she met a copy. The copy warned the Little Blind Text, that where it came from it would have been rewritten a thousand times and everything that was left from its origin would be the word "and" and the Little Blind Text should turn around and return to its own, safe country.',
                          style: AppTextStyles.regular.copyWith(
                            color: Colors.white,
                            fontSize: 14.sp,
                            height: 1.7,
                          ),
                          textAlign: TextAlign.justify,
                        ),

                        30.verticalSpace,
                      ],
                    ),

                    // Footer with Pagination and Next Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Pagination
                        Text(
                          'Page 1/20',
                          style: AppTextStyles.regular.copyWith(
                            color: AppColors.primaryColor,
                            fontSize: 14.sp,
                          ),
                        ),
                        20.verticalSpace,

                        // Next Page Button
                        PrimaryButton(title: 'Next Page'),
                      ],
                    ),
                    30.verticalSpace,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
