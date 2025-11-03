import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../resource/app_colors.dart';

class CustomSwitch extends StatefulWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  final double? width;
  final double? height;

  const CustomSwitch({
    super.key,
    required this.value,
    this.onChanged,
    this.width,
    this.height,
  });

  @override
  State<CustomSwitch> createState() => _CustomSwitchState();
}

class _CustomSwitchState extends State<CustomSwitch>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    if (widget.value) {
      _animationController.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(CustomSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      if (widget.value) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final switchWidth = widget.width ?? 50.w;
    final switchHeight = widget.height ?? 28.h;

    return GestureDetector(
      onTap: widget.onChanged != null
          ? () {
              widget.onChanged!(!widget.value);
            }
          : null,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Container(
            width: switchWidth,
            height: switchHeight,
            decoration: BoxDecoration(
              color: widget.value
                  ? AppColors.primaryColor
                  : AppColors.boxClr,
              borderRadius: BorderRadius.circular(switchHeight / 2),
              border: Border.all(
                color: widget.value
                    ? AppColors.primaryColor
                    : Colors.grey[700]!,
                width: 1,
              ),
            ),
            child: Stack(
              children: [
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  left: widget.value
                      ? switchWidth - switchHeight + 2
                      : 2,
                  top: 2,
                  bottom: 2,
                  child: Container(
                    width: switchHeight - 4,
                    height: switchHeight - 4,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

