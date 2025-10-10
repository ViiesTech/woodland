import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:the_woodlands_series/components/card/global_card.dart';
import 'package:the_woodlands_series/components/resource/app_assets.dart';
import 'package:the_woodlands_series/screens/library/pages/ebook_page.dart';
import '../../components/resource/app_colors.dart';
import '../../components/resource/app_textstyle.dart';
import 'widgets/custom_tab_widget.dart';
import 'pages/audiobook_page.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  int selectedTabIndex = 0;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgClr,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            16.verticalSpace,
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Explore',
                    style: AppTextStyles.lufgaLarge.copyWith(
                      color: Colors.white,
                      fontSize: 20.sp,
                    ),
                  ),

                  Image.asset(AppAssets.profileImg, height: 37.h),
                ],
              ),
            ),
            16.verticalSpace,

            // Custom Tab Widget
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: CustomTabWidget(
                selectedIndex: selectedTabIndex,
                onTabChanged: (index) {
                  setState(() {
                    selectedTabIndex = index;
                  });
                },
                tabs: ['E-book', 'Audiobook'],
              ),
            ),
            20.verticalSpace,

            // Tab Content
            Expanded(
              child: selectedTabIndex == 0 ? EbookPage() : AudiobookPage(),
            ),
          ],
        ),
      ),
    );
  }
}
