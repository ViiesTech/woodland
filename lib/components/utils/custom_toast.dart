import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomToast {
  static OverlayEntry? _currentToast;

  static void showSuccess(BuildContext context, String message) {
    _showToast(context, message, Colors.green, Icons.check_circle);
  }

  static void showError(BuildContext context, String message) {
    _showToast(context, message, Colors.red, Icons.error);
  }

  static void showInfo(BuildContext context, String message) {
    _showToast(context, message, Colors.blue, Icons.info);
  }

  static void _showToast(
    BuildContext context,
    String message,
    Color backgroundColor,
    IconData icon,
  ) {
    // Remove existing toast if any
    _currentToast?.remove();
    _currentToast = null;

    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _AnimatedToast(
        message: message,
        backgroundColor: backgroundColor,
        icon: icon,
        onDismiss: () {
          overlayEntry.remove();
          _currentToast = null;
        },
      ),
    );

    _currentToast = overlayEntry;
    overlay.insert(overlayEntry);
  }
}

class _AnimatedToast extends StatefulWidget {
  final String message;
  final Color backgroundColor;
  final IconData icon;
  final VoidCallback onDismiss;

  const _AnimatedToast({
    required this.message,
    required this.backgroundColor,
    required this.icon,
    required this.onDismiss,
  });

  @override
  State<_AnimatedToast> createState() => _AnimatedToastState();
}

class _AnimatedToastState extends State<_AnimatedToast>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();

    // Auto dismiss after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _dismiss();
      }
    });
  }

  void _dismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slideAnimation,
        child: SafeArea(
          child: Container(
            margin: EdgeInsets.only(top: 8.h, left: 16.w, right: 16.w),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10.r),
              color: widget.backgroundColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 10.r,
                  offset: Offset(0, 4.h),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, color: Colors.white, size: 20.sp),
                SizedBox(width: 10.w),
                Flexible(
                  child: Text(
                    widget.message,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
