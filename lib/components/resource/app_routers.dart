import 'package:flutter/material.dart';

class AppRouter {
  /// Push new page
  static void routeTo(BuildContext context, Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  /// Push and replace current page
  static void replace(BuildContext context, Widget page) {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => page));
  }

  /// Push and remove all previous routes
  static void clearStack(BuildContext context, Widget page) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => page),
      (route) => false,
    );
  }

  /// Go back (with optional result)
  static void routeBack(BuildContext context, [dynamic result]) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context, result);
    }
  }

  /// Push with slide animation
  static void routeWithSlideAnimation(
    BuildContext context,
    Widget page, {
    Offset begin = const Offset(1.0, 0.0),
    Curve curve = Curves.ease,
  }) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, animation, __, child) {
          final tween = Tween(
            begin: begin,
            end: Offset.zero,
          ).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }

  /// Push with fade animation
  static void routeWithfadeAnimation(
    BuildContext context,
    Widget page, {
    Curve curve = Curves.easeIn,
  }) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  /// Navigate to dashboard with specific tab index
  static void routeToDashboard(BuildContext context, {int index = 0}) {}

  /// Navigate to dashboard and replace current page
  static void replaceWithDashboard(BuildContext context, {int index = 0}) {}
}
