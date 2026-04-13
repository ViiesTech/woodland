import 'package:flutter/material.dart';
import 'package:the_woodlands_series/components/resource/app_routers.dart';

class CustomBackButton extends StatelessWidget {
  final void Function()? ontap;
  final Color? color;
  const CustomBackButton({super.key, this.ontap, this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap:
          ontap ??
          () {
            AppRouter.routeBack(context);
          },
      child: Icon(Icons.arrow_back_ios),
    );
  }
}
