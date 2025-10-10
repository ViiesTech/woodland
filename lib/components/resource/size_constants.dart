import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SizeCons {
  static double getWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  static double getHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  // ScreenUtil responsive methods
  static double getResponsiveWidth(double width) {
    return width.w;
  }

  static double getResponsiveHeight(double height) {
    return height.h;
  }

  static double getResponsiveFontSize(double fontSize) {
    return fontSize.sp;
  }

  static double getResponsiveRadius(double radius) {
    return radius.r;
  }

  // Common responsive values
  static double get screenWidth => 1.sw;
  static double get screenHeight => 1.sh;
  static double get statusBarHeight => ScreenUtil().statusBarHeight;
  static double get bottomBarHeight => ScreenUtil().bottomBarHeight;
}
