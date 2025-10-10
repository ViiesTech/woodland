import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:the_woodlands_series/components/resource/app_assets.dart';
import 'package:the_woodlands_series/components/resource/app_colors.dart';
import 'package:the_woodlands_series/components/resource/app_textstyle.dart';

class PrimaryTextField extends StatefulWidget {
  final bool? hasError, readOnly, isEnabled;
  final bool isPassword;
  final bool shadow;

  final Color? fillColor, fborder, eborder, bordercolor, textColor;

  final double? width;
  final double? height;
  final double? fontsize, borderRadius;
  final double? horizontalPad, verticalPad;

  final int? maxlines, minlines, maxCount;

  final String? label;
  final String? hint, hintLabel;

  final FocusNode? focus;
  final TextInputType? keyboard;
  final TextInputAction? textInputAction;

  final TextEditingController? controller;

  final void Function()? onTap;
  final void Function(String)? submit, onChanged;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;

  final Widget? icon, suffixIcon, prefixIcon, labelIcon;
  final double? hintFontSize;

  const PrimaryTextField({
    super.key,
    this.inputFormatters,
    this.readOnly = false,
    this.submit,
    this.maxCount,
    this.onChanged,
    this.controller,
    this.fillColor,
    this.fontsize,
    this.hintLabel,
    this.label,
    this.hint,
    this.bordercolor,
    this.validator,
    this.icon,
    this.suffixIcon,
    this.width,
    this.isPassword = false,
    this.prefixIcon,
    this.labelIcon,
    this.height,
    this.hasError,
    this.maxlines,
    this.fborder,
    this.eborder,
    this.keyboard,
    this.focus,
    this.isEnabled,
    this.onTap,
    this.textInputAction,
    this.minlines,
    this.borderRadius,
    this.textColor,
    this.shadow = false,
    this.horizontalPad,
    this.verticalPad,
    this.hintFontSize,
  });

  @override
  State<PrimaryTextField> createState() => _PrimaryTextFieldState();
}

class _PrimaryTextFieldState extends State<PrimaryTextField> {
  bool isObsure = true;
  ScrollController? _scrollController;

  @override
  void initState() {
    super.initState();
    if (widget.maxlines != null && widget.maxlines! > 4) {
      _scrollController = ScrollController();
    }
  }

  @override
  void dispose() {
    _scrollController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isTablet = MediaQuery.of(context).size.width > 600;

    double effectiveBorderRadius =
        widget.borderRadius ?? (isTablet ? 10.r : 10.r);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null)
          Padding(
            padding: EdgeInsets.only(bottom: 5.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Padding(
                  padding: EdgeInsets.only(
                    left: isTablet ? 8.w : 5.w,
                    right: isTablet ? 14.w : 10.w,
                  ),
                  child: Text(
                    widget.label!,
                    style: AppTextStyles.small.copyWith(
                      fontSize: isTablet ? 12.sp : 16.sp,
                    ),
                  ),
                ),
                widget.labelIcon ?? const SizedBox(),
              ],
            ),
          ),
        Container(
          width: widget.width,
          height: widget.height,
          constraints: widget.maxlines != null && widget.maxlines! > 4
              ? BoxConstraints(
                  maxHeight: 4 * 20.h, // Max height for 4 lines
                  minHeight: 20.h, // Min height for 1 line
                )
              : null,
          decoration: BoxDecoration(
            boxShadow: [
              widget.shadow
                  ? BoxShadow(
                      offset: Offset(0, isTablet ? 6.r : 6.r),
                      blurRadius: isTablet ? 14.r : 10.r,
                      color: AppColors.blackColor.withValues(alpha: .08.r),
                    )
                  : const BoxShadow(
                      offset: Offset(0, 0),
                      blurRadius: 0,
                      color: Colors.transparent,
                    ),
            ],
          ),
          child: TextFormField(
            maxLength: widget.maxCount,
            inputFormatters: widget.inputFormatters,
            validator: widget.validator,
            textInputAction: widget.textInputAction,
            readOnly: widget.readOnly ?? false,
            controller: widget.controller,
            onTap: widget.onTap,
            onChanged: widget.onChanged,
            onTapOutside: (_) => FocusScope.of(context).unfocus(),
            focusNode: widget.focus,
            maxLines: widget.maxlines != null && widget.maxlines! > 4
                ? null
                : widget.maxlines ?? 1,
            minLines: widget.minlines ?? 1,
            obscureText: widget.isPassword ? isObsure : false,
            cursorColor: AppColors.whiteColor,
            keyboardType: widget.keyboard,
            style: AppTextStyles.regular.copyWith(
              fontSize: widget.fontsize ?? (isTablet ? 12.sp : 14.sp),
              color: widget.textColor ?? AppColors.whiteColor,
              fontWeight: FontWeight.w400,
            ),
            decoration: InputDecoration(
              counterText: "",
              floatingLabelBehavior: FloatingLabelBehavior.always,
              filled: true,
              fillColor: widget.fillColor ?? AppColors.boxClr,
              prefixIcon: widget.prefixIcon,
              prefixIconConstraints: BoxConstraints(
                minWidth: 40.w,
                minHeight: 40.h,
              ),
              hintText: widget.hint,
              labelStyle: AppTextStyles.small,
              hintStyle: AppTextStyles.regular.copyWith(
                fontSize: widget.hintFontSize ?? (14.sp),
                color: AppColors.greyColor,
                fontWeight: FontWeight.w500,
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: widget.horizontalPad ?? (15.w),
                vertical: widget.verticalPad ?? (8.h),
              ),

              border: OutlineInputBorder(
                borderSide: BorderSide(
                  color: widget.bordercolor ?? AppColors.boxClr,
                  width: isTablet ? 1.5.w : 1.w,
                ),
                borderRadius: BorderRadius.all(
                  Radius.circular(effectiveBorderRadius),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: widget.bordercolor ?? AppColors.boxClr,
                  width: isTablet ? 1.5.w : 1.w,
                ),
                borderRadius: BorderRadius.all(
                  Radius.circular(effectiveBorderRadius),
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: AppColors.boxClr,
                  width: isTablet ? 1.5.w : 1.w,
                ),
                borderRadius: BorderRadius.all(
                  Radius.circular(effectiveBorderRadius),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(
                  color: widget.bordercolor ?? AppColors.boxClr,
                  width: isTablet ? 1.5.w : 1.w,
                ),
                borderRadius: BorderRadius.all(
                  Radius.circular(effectiveBorderRadius),
                ),
              ),
              suffixIcon: widget.isPassword
                  ? GestureDetector(
                      onTap: () {
                        setState(() {
                          isObsure = !isObsure;
                        });
                      },
                      child: isObsure
                          ? Icon(
                              Icons.visibility_off_outlined,
                              color: AppColors.greyColor,
                            )
                          : Icon(
                              Icons.visibility_outlined,
                              color: AppColors.greyColor,
                            ),
                    )
                  : widget.suffixIcon,
            ),
          ),
        ),
        if (widget.hintLabel != null)
          Padding(
            padding: EdgeInsets.only(
              right: isTablet ? 14.w : 10.w,
              top: isTablet ? 12.h : 10.h,
            ),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                widget.hintLabel!,
                style: AppTextStyles.small.copyWith(
                  fontSize: isTablet ? 12.sp : 10.sp,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
