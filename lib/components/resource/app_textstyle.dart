import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:the_woodlands_series/components/resource/app_colors.dart';

class AppTextStyles {
  // Regular text styles - Inter (default)
  static TextStyle get large => GoogleFonts.inter(
    fontSize: 30.sp,
    fontWeight: FontWeight.bold,
    color: AppColors.blackColor,
  );

  static TextStyle get medium => GoogleFonts.inter(
    fontSize: 24.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.blackColor,
  );

  static TextStyle get regular => GoogleFonts.inter(
    fontSize: 16.sp,
    fontWeight: FontWeight.normal,
    color: AppColors.blackColor,
  );

  static TextStyle get small => GoogleFonts.inter(
    fontSize: 12.sp,
    fontWeight: FontWeight.w400,
    color: AppColors.blackColor,
  );

  // Lufga specific styles - uses Montserrat Alternates when explicitly called
  static TextStyle get lufgaLarge => GoogleFonts.montserratAlternates(
    fontSize: 30.sp,
    fontWeight: FontWeight.bold,
    color: AppColors.blackColor,
  );

  static TextStyle get lufgaMedium => GoogleFonts.montserratAlternates(
    fontSize: 24.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.blackColor,
  );

  static TextStyle get lufgaRegular => GoogleFonts.montserratAlternates(
    fontSize: 16.sp,
    fontWeight: FontWeight.normal,
    color: AppColors.blackColor,
  );

  // Additional heading styles with Montserrat Alternates (Lufga)
  static TextStyle get heading1 => GoogleFonts.montserratAlternates(
    fontSize: 32.sp,
    fontWeight: FontWeight.bold,
    color: AppColors.blackColor,
  );

  static TextStyle get heading2 => GoogleFonts.montserratAlternates(
    fontSize: 28.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.blackColor,
  );

  static TextStyle get heading3 => GoogleFonts.montserratAlternates(
    fontSize: 24.sp,
    fontWeight: FontWeight.w600,
    color: AppColors.blackColor,
  );

  // Body text styles with Inter (default)
  static TextStyle get bodyLarge => GoogleFonts.inter(
    fontSize: 18.sp,
    fontWeight: FontWeight.normal,
    color: AppColors.blackColor,
  );

  static TextStyle get bodyMedium => GoogleFonts.inter(
    fontSize: 16.sp,
    fontWeight: FontWeight.normal,
    color: AppColors.blackColor,
  );

  static TextStyle get bodySmall => GoogleFonts.inter(
    fontSize: 14.sp,
    fontWeight: FontWeight.normal,
    color: AppColors.blackColor,
  );
}
