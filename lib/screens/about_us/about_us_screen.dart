import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:the_woodlands_series/components/resource/app_colors.dart';
import 'package:the_woodlands_series/components/resource/app_textstyle.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgClr,
      appBar: AppBar(
        backgroundColor: AppColors.boxClr,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'About Us',
          style: AppTextStyles.lufgaLarge.copyWith(
            color: Colors.white,
            fontSize: 20.sp,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              30.verticalSpace,
              // Author Image
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16.r),
                  child: Image.asset(
                    'assets/tempImg/aurthor.png',
                    width: double.infinity,
                    height: 400.h,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 400.h,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppColors.boxClr,
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.person,
                            color: Colors.white.withOpacity(0.5),
                            size: 80.sp,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              40.verticalSpace,
              // Main Heading
              Text(
                'Discover the Magic of\nNature Through\nStorytelling',
                style: AppTextStyles.lufgaLarge.copyWith(
                  color: Colors.white,
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
              30.verticalSpace,
              // Paragraph 1
              Text(
                'Welcome to the official website for The Woodlands Series by DG Videtto —where wildlife, adventure, and heartfelt storytelling collide.',
                style: AppTextStyles.lufgaMedium.copyWith(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16.sp,
                  height: 1.6,
                ),
              ),
              20.verticalSpace,
              // Paragraph 2
              Text(
                'This captivating book series takes readers deep into the forests and lakes of New Hampshire, following the journeys of resilient chipmunks, daring squirrels, and the majestic loons of Loon Island. With themes of survival, friendship, and conservation, each book immerses readers in a world where nature\'s challenges become life-changing adventures.',
                style: AppTextStyles.lufgaMedium.copyWith(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16.sp,
                  height: 1.6,
                ),
              ),
              20.verticalSpace,
              // Paragraph 3
              Text(
                'Dive into the stories, connect with fellow nature enthusiasts, and explore the world of The Woodlands Series.',
                style: AppTextStyles.lufgaMedium.copyWith(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16.sp,
                  height: 1.6,
                ),
              ),
              40.verticalSpace,
            ],
          ),
        ),
      ),
    );
  }
}
