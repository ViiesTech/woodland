import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:the_woodlands_series/components/resource/app_colors.dart';
import 'package:the_woodlands_series/components/resource/app_textstyle.dart';

class CustomTabWidget extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onTabChanged;
  final List<String> tabs;

  const CustomTabWidget({
    super.key,
    required this.selectedIndex,
    required this.onTabChanged,
    required this.tabs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.boxClr,
        borderRadius: BorderRadius.circular(10.r),
      ),
      padding: EdgeInsets.all(5.w),
      child: Row(
        children: tabs.asMap().entries.map((entry) {
          final index = entry.key;
          final tab = entry.value;
          final isSelected = selectedIndex == index;

          return Expanded(
            child: GestureDetector(
              onTap: () => onTabChanged(index),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primaryColor
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                padding: EdgeInsets.symmetric(vertical: 12.h),
                child: Center(
                  child: Text(
                    tab,
                    style: AppTextStyles.lufgaMedium.copyWith(
                      fontSize: 14.sp,
                      color: isSelected
                          ? AppColors.blackColor
                          : AppColors.whiteColor,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
