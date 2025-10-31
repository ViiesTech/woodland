import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:the_woodlands_series/components/resource/app_assets.dart';
import 'package:the_woodlands_series/components/resource/app_textstyle.dart';
import 'package:the_woodlands_series/screens/book_detail/book_detail_screen.dart';

class GlobalCard extends StatelessWidget {
  final String title;
  final String author;
  final String imageAsset;
  final String listenTime;
  final String readTime;
  final bool blur;

  const GlobalCard({
    super.key,
    required this.title,
    required this.author,
    required this.imageAsset,
    required this.listenTime,
    required this.readTime,
    this.blur = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: 122.w,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 119.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Stack(
                children: [
                  // Background Image - supports both asset and network
                  Container(
                    height: 119.h,
                    decoration: BoxDecoration(
                      image: imageAsset.startsWith('http')
                          ? DecorationImage(
                              image: NetworkImage(imageAsset),
                              fit: BoxFit.cover,
                              onError: (exception, stackTrace) {
                                // Handle error - show placeholder
                              },
                            )
                          : DecorationImage(
                              image: AssetImage(imageAsset),
                              fit: BoxFit.cover,
                            ),
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    child: imageAsset.startsWith('http')
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(14.r),
                            child: Image.network(
                              imageAsset,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[800],
                                  child: Icon(
                                    Icons.image_not_supported,
                                    color: Colors.grey[600],
                                    size: 40.sp,
                                  ),
                                );
                              },
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  color: Colors.grey[800],
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded /
                                              loadingProgress.expectedTotalBytes!
                                          : null,
                                      color: Colors.orange,
                                    ),
                                  ),
                                );
                              },
                            ),
                          )
                        : null,
                  ),
                  // Blur Overlay
                  if (blur)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14.r),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          height: 119.h,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0xFFFF8C42).withOpacity(0.3), // Orange
                                Color(
                                  0xFF8B4513,
                                ).withOpacity(0.5), // Dark Brown
                              ],
                              stops: [0.0, 1.0],
                            ),
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            8.verticalSpace,
            Text(
              title,
              style: AppTextStyles.medium.copyWith(
                color: Colors.white,
                fontSize: 10.sp,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            4.verticalSpace,
            Text(
              author,
              style: AppTextStyles.regular.copyWith(
                color: Colors.white,
                fontSize: 10.sp,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            8.verticalSpace,
            Row(
              children: [
                SvgPicture.asset(
                  AppAssets.headphoneIcon,
                  height: 12.h,
                  width: 12.w,
                ),
                2.horizontalSpace,
                Text(
                  listenTime,
                  style: AppTextStyles.regular.copyWith(
                    color: Colors.white,
                    fontSize: 10.sp,
                  ),
                ),
                8.horizontalSpace,
                SvgPicture.asset(
                  AppAssets.connectIcon,
                  height: 12.h,
                  width: 12.w,
                ),
                2.horizontalSpace,
                Text(
                  readTime,
                  style: AppTextStyles.regular.copyWith(
                    color: Colors.white,
                    fontSize: 10.sp,
                  ),
                ),
              ],
            ),
          ],
        ),
    );
  }
}
