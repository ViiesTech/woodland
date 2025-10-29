import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ThreeDotLoader extends StatefulWidget {
  final Color? color;
  final double? size;
  final double? spacing;

  const ThreeDotLoader({super.key, this.color, this.size, this.spacing});

  @override
  State<ThreeDotLoader> createState() => _ThreeDotLoaderState();
}

class _ThreeDotLoaderState extends State<ThreeDotLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dotColor = widget.color ?? Colors.white;
    final dotSize = widget.size ?? 8.w;
    final dotSpacing = widget.spacing ?? 4.w;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDot(0, dotColor, dotSize),
          SizedBox(width: dotSpacing),
          _buildDot(1, dotColor, dotSize),
          SizedBox(width: dotSpacing),
          _buildDot(2, dotColor, dotSize),
        ],
      ),
    );
  }

  Widget _buildDot(int index, Color color, double size) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Each dot starts at a different time (0, 0.33, 0.66)
        final delay = index * 0.33;
        final value = (_controller.value - delay) % 1.0;

        // Create smooth up and down motion
        final offset = value < 0.5
            ? Curves.easeInOut.transform(value * 2) * -6.h
            : Curves.easeInOut.transform((1 - value) * 2) * -6.h;

        return Transform.translate(
          offset: Offset(0, offset),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
        );
      },
    );
  }
}
