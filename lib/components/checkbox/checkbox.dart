import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:the_woodlands_series/components/checkbox/primary_checkbox.dart';
import 'package:the_woodlands_series/components/resource/app_colors.dart';
import 'package:the_woodlands_series/components/resource/app_textstyle.dart';

class CustomCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final String label;
  final double? lableFontSize;
  final bool isExpanded;

  const CustomCheckbox({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.lableFontSize,
    this.isExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isTablet = MediaQuery.of(context).size.width > 600;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        PrimaryCheckBox(
          keyId: label,
          value: value,
          onChanged: (val) => onChanged(!value),
        ),
        SizedBox(width: isTablet ? 4.w : 5.w),
        if (!isExpanded)
          Text(
            label,
            style: AppTextStyles.medium.copyWith(
              fontSize: lableFontSize ?? (isTablet ? 12.sp : 14.sp),
              color: AppColors.hintTextColor,
            ),
          ),
        if (isExpanded)
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.medium.copyWith(
                fontSize: lableFontSize ?? (isTablet ? 12.sp : 12.sp),
                color: AppColors.hintTextColor,
              ),
            ),
          ),
      ],
    );
  }
}
