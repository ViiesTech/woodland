// import 'package:flutter/material.dart';

// class RoundedToggleButton extends StatelessWidget {
//   final String label;
//   final IconData? icon;
//   final bool isSelected;
//   final VoidCallback onTap;
//   final String image;

//   const RoundedToggleButton({
//     super.key,
//     required this.label,
//     this.icon,
//     required this.isSelected,
//     required this.onTap,
//     required this.image,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 200),
//         padding: const EdgeInsets.symmetric(horizontal: 20.5, vertical: 11.5),
//         decoration: BoxDecoration(
//           color: isSelected ? const Color(0xFF5A82E0) : Colors.white,
//           borderRadius: BorderRadius.circular(30),
//           boxShadow: [
//             if (!isSelected)
//               BoxShadow(
//                 color: Colors.grey.withValues(alpha: 0.1),
//                 blurRadius: 4,
//                 offset: const Offset(0, 2),
//               ),
//           ],
//         ),
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Image.asset(
//               image,
//               width: 18,
//               color: isSelected ? Colors.white : const Color(0xFF596275),
//             ),

//             const SizedBox(width: 8),
//             Text(
//               label,
//               style: TextStyle(
//                 fontWeight: FontWeight.w600,
//                 color: isSelected ? Colors.white : const Color(0xFF596275),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RoundedToggleButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;
  final String image;
  final Color? selectedFillColor;
  final Color? unselectedFillColor;
  final Color? selectedTextColor;
  final Color? unselectedTextColor;
  final Color? selectedIconColor;
  final Color? unselectedIconColor;
  final Color? borderColor;
  final double? borderWidth;

  const RoundedToggleButton({
    super.key,
    required this.label,
    this.icon,
    required this.isSelected,
    required this.onTap,
    required this.image,
    this.selectedFillColor,
    this.unselectedFillColor,
    this.selectedTextColor,
    this.unselectedTextColor,
    this.selectedIconColor,
    this.unselectedIconColor,
    this.borderColor,
    this.borderWidth,
  });

  @override
  Widget build(BuildContext context) {
    final bool isTablet = MediaQuery.of(context).size.width > 600;

    // Default colors
    final Color defaultSelectedFillColor = const Color(0xFF5A82E0);
    final Color defaultUnselectedFillColor = Colors.white;
    final Color defaultSelectedTextColor = Colors.white;
    final Color defaultUnselectedTextColor = const Color(0xFF596275);
    final Color defaultSelectedIconColor = Colors.white;
    final Color defaultUnselectedIconColor = const Color(0xFF596275);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isTablet ? 18.w : 20.5,
          vertical: isTablet ? 12.h : 8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? (selectedFillColor ?? defaultSelectedFillColor)
              : (unselectedFillColor ?? defaultUnselectedFillColor),
          borderRadius: BorderRadius.circular(30.r),
          border: borderColor != null
              ? Border.all(color: borderColor!, width: borderWidth ?? 1.0)
              : null,
          boxShadow: [
            if (!isSelected)
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              image,
              width: isTablet ? 12.w : 22.w,
              color: isSelected
                  ? (selectedIconColor ?? defaultSelectedIconColor)
                  : (unselectedIconColor ?? defaultUnselectedIconColor),
              fit: BoxFit.fill,
            ),
            isTablet ? 4.horizontalSpace : 2.horizontalSpace,
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: isTablet ? 10.sp : 14.sp,
                color: isSelected
                    ? (selectedTextColor ?? defaultSelectedTextColor)
                    : (unselectedTextColor ?? defaultUnselectedTextColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
