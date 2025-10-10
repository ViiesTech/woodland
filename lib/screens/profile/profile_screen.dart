import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:the_woodlands_series/components/button/primary_button.dart';
import 'package:the_woodlands_series/components/resource/app_assets.dart';
import 'package:the_woodlands_series/components/resource/app_colors.dart';
import 'package:the_woodlands_series/components/resource/app_routers.dart';
import 'package:the_woodlands_series/components/resource/app_textstyle.dart';
import 'package:the_woodlands_series/components/card/global_card.dart';
import 'package:the_woodlands_series/screens/library/widgets/continue_listening_widget.dart';
import 'package:the_woodlands_series/screens/login_screen/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String title;
  final String image;
  const ProfileScreen({super.key, required this.title, required this.image});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final List<Map<String, String>> trendingBooks = [
    {
      'title': 'A PIRATE SCENT OF A LADY ORCHARD 2',
      'author': 'Mark McAllister',
      'imageAsset': AppAssets.tempGame4,
      'listenTime': '5m',
      'readTime': '8m',
    },
    {
      'title': 'THE ENCHANTED FOREST ADVENTURE',
      'author': 'Sarah Johnson',
      'imageAsset': AppAssets.tempGame5,
      'listenTime': '7m',
      'readTime': '12m',
    },
    {
      'title': 'MYSTERY OF THE DARK WOODS',
      'author': 'David Wilson',
      'imageAsset': AppAssets.tempGame6,
      'listenTime': '4m',
      'readTime': '6m',
    },
    {
      'title': 'THE LOST TREASURE HUNT',
      'author': 'Emily Brown',
      'imageAsset': AppAssets.tempGame4,
      'listenTime': '9m',
      'readTime': '15m',
    },
    {
      'title': 'FANTASY REALM CHRONICLES',
      'author': 'Michael Davis',
      'imageAsset': AppAssets.tempGame5,
      'listenTime': '6m',
      'readTime': '10m',
    },
    {
      'title': 'ADVENTURE IN THE MOUNTAINS',
      'author': 'Lisa Anderson',
      'imageAsset': AppAssets.tempGame6,
      'listenTime': '8m',
      'readTime': '14m',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgClr,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
        ),
        centerTitle: true,
        title: Text(
          'Game Detail',
          style: AppTextStyles.lufgaLarge.copyWith(
            color: Colors.white,
            fontSize: 20.sp,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              AppRouter.clearStack(context, LoginScreen());
            },
            icon: Icon(Icons.logout, color: Colors.white),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: 400.h,
              child: Stack(
                children: [
                  // Blurred background for upper section
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage(AppAssets.profileImg1),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 2),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withOpacity(0.3),
                                Colors.black.withOpacity(0.5),
                                Colors.black.withOpacity(0.7),
                                AppColors.bgClr,
                                AppColors.bgClr,
                              ],
                              stops: [0.0, 0.2, 0.4, 0.7, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Main content
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 136.w,
                          height: 136.h,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(
                              image: AssetImage(AppAssets.profileImg1),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        16.verticalSpace,

                        // Game title
                        SizedBox(
                          width: 350.w,
                          child: Text(
                            'John Doe',
                            style: AppTextStyles.lufgaLarge.copyWith(
                              color: Colors.white,
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        8.verticalSpace,
                        SizedBox(
                          width: 350.w,
                          child: Text(
                            'john.doe@example.com',
                            style: AppTextStyles.lufgaMedium.copyWith(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                        16.verticalSpace,

                        PrimaryButton(
                          buttonWidth: 250.w,
                          title: 'Edit Profile',
                          onTap: () {},
                        ),
                        16.verticalSpace,
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Lower section with normal background
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Container(
                color: AppColors.bgClr,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    40.verticalSpace,

                    // Chapter 2
                    Text(
                      'Continue Listening',
                      style: AppTextStyles.lufgaLarge.copyWith(
                        color: Colors.white,
                        fontSize: 18.sp,
                      ),
                    ),
                    16.verticalSpace,
                    ContinueListeningWIdget(),
                    16.verticalSpace,

                    // Similar Games
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Similar Games',
                              style: AppTextStyles.lufgaLarge.copyWith(
                                color: Colors.white,
                                fontSize: 20.sp,
                              ),
                            ),
                          ],
                        ),
                        16.verticalSpace,
                        GridView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.zero,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: 16.w,
                                mainAxisSpacing: 16.h,
                                childAspectRatio: 0.43,
                              ),
                          itemCount: trendingBooks.length,
                          itemBuilder: (context, index) {
                            final book = trendingBooks[index];
                            return GlobalCard(
                              title: book['title']!,
                              author: book['author']!,
                              imageAsset: book['imageAsset']!,
                              listenTime: book['listenTime']!,
                              readTime: book['readTime']!,
                            );
                          },
                        ),
                      ],
                    ),

                    40.verticalSpace,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
