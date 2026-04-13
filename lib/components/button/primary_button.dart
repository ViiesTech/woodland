import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:the_woodlands_series/components/resource/app_colors.dart';
import 'package:the_woodlands_series/components/resource/app_textstyle.dart';

class PrimaryButton extends StatelessWidget {
  final String title;
  final Color? titleColor;
  final Color fillColor;
  final Color borderColor;
  final double? fontSize;
  final double? buttonWidth;
  final void Function()? onTap;
  final bool isLoading;
  final Widget? icon;
  final double? borderRadius;
  final double? verPadding;
  final double? horPadding;
  final double? borderWidth;
  final bool shadow;
  const PrimaryButton({
    super.key,
    required this.title,
    this.titleColor,
    this.fillColor = AppColors.primaryColor,
    this.borderColor = Colors.transparent,
    this.onTap,
    this.isLoading = false,
    this.icon,
    this.fontSize,
    this.buttonWidth,
    this.borderRadius,
    this.verPadding,
    this.horPadding,
    this.borderWidth,
    this.shadow = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: buttonWidth,
        padding: EdgeInsets.symmetric(
          horizontal: horPadding ?? (10.w),
          vertical: verPadding ?? (8.h),
        ),
        decoration: BoxDecoration(
          color: fillColor,
          border: Border.all(color: borderColor, width: borderWidth ?? 2.w),
          borderRadius: BorderRadius.circular(borderRadius ?? (8.r)),
          boxShadow: shadow
              ? [
                  BoxShadow(
                    color: fillColor.withOpacity(0.3),
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
                ]
              : null,
        ),
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Invisible content to maintain width
              Opacity(
                opacity: 0,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[icon!, SizedBox(width: 8.w)],
                    Text(
                      title,
                      style: AppTextStyles.regular.copyWith(
                        fontSize: fontSize ?? (14.sp),
                        fontWeight: FontWeight.w500,
                        color: titleColor ?? AppColors.bgClr,
                      ),
                    ),
                  ],
                ),
              ),
              // Visible content or loader
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: isLoading
                    ? SizedBox(
                        key: const ValueKey('loader'),
                        height: 20.h,
                        width: 20.h,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            titleColor ?? AppColors.bgClr,
                          ),
                          strokeWidth: 2.0,
                        ),
                      )
                    : Row(
                        key: const ValueKey('content'),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (icon != null) ...[icon!, SizedBox(width: 8.w)],
                          Text(
                            title,
                            style: AppTextStyles.regular.copyWith(
                              fontSize: fontSize ?? (14.sp),
                              fontWeight: FontWeight.w500,
                              color: titleColor ?? AppColors.bgClr,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
