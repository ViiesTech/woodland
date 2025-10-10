import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:the_woodlands_series/components/resource/app_colors.dart';

class PrimaryCheckBox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final String keyId;

  const PrimaryCheckBox({
    super.key,
    required this.value,
    required this.onChanged,
    required this.keyId,
  });

  @override
  Widget build(BuildContext context) {
    double size = 16.sp;
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        height: size,
        width: size,
        decoration: BoxDecoration(
          color: value ? AppColors.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(2.r),
          border: Border.all(color: AppColors.primaryColor),
        ),
        child: value
            ? Center(
                child: Icon(Icons.done, color: AppColors.bgClr, size: 14.sp),
              )
            : null,
      ),
    );
  }
}
