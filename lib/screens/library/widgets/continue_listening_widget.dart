import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:the_woodlands_series/components/resource/app_assets.dart';
import 'package:the_woodlands_series/components/resource/app_colors.dart';
import 'package:the_woodlands_series/components/resource/app_textstyle.dart';

class ContinueListeningWIdget extends StatelessWidget {
  const ContinueListeningWIdget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 114.h,

      decoration: BoxDecoration(
        color: AppColors.boxClr,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(10.r),
        child: Row(
          children: [
            Container(
              width: 105.w,
              height: 105.h,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(AppAssets.temp3),
                  fit: BoxFit.cover,
                ),
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Chapter 2',
                                style: AppTextStyles.medium.copyWith(
                                  color: AppColors.primaryColor,
                                  fontSize: 12.sp,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Glenn s duquette',
                                style: AppTextStyles.lufgaLarge.copyWith(
                                  color: AppColors.whiteColor,
                                  fontSize: 16.sp,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Mark mcallister',
                                style: AppTextStyles.medium.copyWith(
                                  color: AppColors.whiteColor.withValues(
                                    alpha: 0.5,
                                  ),
                                  fontSize: 12.sp,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xff1B252D),
                          ),
                          padding: EdgeInsets.all(8.r),
                          child: Icon(
                            Icons.play_arrow,
                            color: AppColors.primaryColor,
                            size: 24.sp,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '18:00/',
                                style: AppTextStyles.medium.copyWith(
                                  color: AppColors.whiteColor,
                                  fontSize: 12.sp,
                                ),
                              ),
                              TextSpan(
                                text: ' 88:00',
                                style: AppTextStyles.medium.copyWith(
                                  color: AppColors.whiteColor.withValues(
                                    alpha: 0.5,
                                  ),
                                  fontSize: 12.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                        4.verticalSpace,
                        Stack(
                          children: [
                            // Background (unused portion)
                            Container(
                              width: double.infinity,
                              height: 4.h,
                              decoration: BoxDecoration(
                                color: Color(0xff677078),
                                borderRadius: BorderRadius.circular(50.r),
                              ),
                            ),
                            // Progress (used portion)
                            FractionallySizedBox(
                              widthFactor: 0.2, // 18:00 / 88:00 ≈ 20%
                              child: Container(
                                height: 4.h,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryColor,
                                  borderRadius: BorderRadius.circular(50.r),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
