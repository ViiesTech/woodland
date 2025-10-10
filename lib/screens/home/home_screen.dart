import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:the_woodlands_series/Components/textfield/primary_textfield.dart';
import 'package:the_woodlands_series/components/card/global_card.dart';
import 'package:the_woodlands_series/components/resource/app_assets.dart';
import 'package:the_woodlands_series/components/resource/app_textstyle.dart';
import 'package:the_woodlands_series/screens/home/widgets/continue_reading_widget.dart';

import '../../components/resource/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedCategoryIndex = 0;

  final List<Map<String, String>> categories = [
    {'title': 'Trending', 'icon': AppAssets.fireIcon},
    {'title': '5-Minutes Read', 'icon': AppAssets.readIcon},
    {'title': 'Quick Listen', 'icon': AppAssets.headphoneIcon},
  ];

  // JSON-like data for trending books
  final List<Map<String, String>> trendingBooks = [
    {
      'title': 'A PIRATE SCENT OF A LADY ORCHARD 2',
      'author': 'Mark McAllister',
      'imageAsset': AppAssets.temp1,
      'listenTime': '5m',
      'readTime': '8m',
    },
    {
      'title': 'THE ENCHANTED FOREST ADVENTURE',
      'author': 'Sarah Johnson',
      'imageAsset': AppAssets.temp2,
      'listenTime': '7m',
      'readTime': '12m',
    },
    {
      'title': 'MYSTERY OF THE DARK WOODS',
      'author': 'David Wilson',
      'imageAsset': AppAssets.temp3,
      'listenTime': '4m',
      'readTime': '6m',
    },
    {
      'title': 'THE LOST TREASURE HUNT',
      'author': 'Emily Brown',
      'imageAsset': AppAssets.temp4,
      'listenTime': '9m',
      'readTime': '15m',
    },
    {
      'title': 'FANTASY REALM CHRONICLES',
      'author': 'Michael Davis',
      'imageAsset': AppAssets.temp5,
      'listenTime': '6m',
      'readTime': '10m',
    },
    {
      'title': 'ADVENTURE IN THE MOUNTAINS',
      'author': 'Lisa Anderson',
      'imageAsset': AppAssets.temp6,
      'listenTime': '8m',
      'readTime': '14m',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgClr,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  16.verticalSpace,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hi, Robby!',
                            style: AppTextStyles.lufgaLarge.copyWith(
                              color: Colors.white,
                              fontSize: 20.sp,
                            ),
                          ),
                          8.verticalSpace,
                          Text(
                            'What book do you wanna read today?',
                            style: AppTextStyles.regular.copyWith(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 14.sp,
                            ),
                          ),
                        ],
                      ),
                      Image.asset(AppAssets.profileImg, height: 37.h),
                    ],
                  ),
                  16.verticalSpace,
                  PrimaryTextField(
                    hint: 'Title, author or keyword',
                    prefixIcon: Icon(Icons.search, size: 20.sp),
                    height: 55.h,
                    verticalPad: 10.h,
                  ),
                  15.verticalSpace,
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    15.verticalSpace,

                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Continue Reading',
                            style: AppTextStyles.lufgaLarge.copyWith(
                              color: Colors.white,
                              fontSize: 20.sp,
                            ),
                          ),
                          20.verticalSpace,
                          ContinueReadingWidget(),
                          40.verticalSpace,
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 45.h,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: categories.length,
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        itemBuilder: (context, index) {
                          final isSelected = selectedCategoryIndex == index;
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedCategoryIndex = index;
                              });
                            },
                            child: Container(
                              margin: EdgeInsets.only(right: 12.w),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.boxClr
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10.r),
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 10.h,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SvgPicture.asset(
                                    categories[index]['icon']!,
                                    height: 18.h,
                                    colorFilter: ColorFilter.mode(
                                      isSelected ? Colors.white : Colors.white,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                  5.horizontalSpace,
                                  Text(
                                    categories[index]['title']!,
                                    style: AppTextStyles.medium.copyWith(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.white,
                                      fontSize: 14.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    40.verticalSpace,
                    Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Top Trending',
                                style: AppTextStyles.lufgaLarge.copyWith(
                                  color: Colors.white,
                                  fontSize: 20.sp,
                                ),
                              ),
                              Text(
                                'View all',
                                style: AppTextStyles.medium.copyWith(
                                  color: AppColors.primaryColor,
                                  fontSize: 12.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                        16.verticalSpace,
                        SizedBox(
                          height: 200.h,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: trendingBooks.length,
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            itemBuilder: (context, index) {
                              final book = trendingBooks[index];
                              return Container(
                                margin: EdgeInsets.only(right: 16.w),
                                child: GlobalCard(
                                  title: book['title']!,
                                  author: book['author']!,
                                  imageAsset: book['imageAsset']!,
                                  listenTime: book['listenTime']!,
                                  readTime: book['readTime']!,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    26.verticalSpace,
                    Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'New Release',
                                style: AppTextStyles.lufgaLarge.copyWith(
                                  color: Colors.white,
                                  fontSize: 20.sp,
                                ),
                              ),
                              Text(
                                'View all',
                                style: AppTextStyles.medium.copyWith(
                                  color: AppColors.primaryColor,
                                  fontSize: 12.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                        16.verticalSpace,
                        SizedBox(
                          height: 200.h,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: trendingBooks.length,
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            itemBuilder: (context, index) {
                              final book = trendingBooks[index];
                              return Container(
                                margin: EdgeInsets.only(right: 16.w),
                                child: GlobalCard(
                                  title: book['title']!,
                                  author: book['author']!,
                                  imageAsset: book['imageAsset']!,
                                  listenTime: book['listenTime']!,
                                  readTime: book['readTime']!,
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    26.verticalSpace,
                    Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Coming Soon',
                                style: AppTextStyles.lufgaLarge.copyWith(
                                  color: Colors.white,
                                  fontSize: 20.sp,
                                ),
                              ),
                              Text(
                                'View all',
                                style: AppTextStyles.medium.copyWith(
                                  color: AppColors.primaryColor,
                                  fontSize: 12.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                        16.verticalSpace,
                        SizedBox(
                          height: 200.h,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: trendingBooks.length,
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            itemBuilder: (context, index) {
                              final book = trendingBooks[index];
                              return Container(
                                margin: EdgeInsets.only(right: 16.w),
                                child: GlobalCard(
                                  title: book['title']!,
                                  author: book['author']!,
                                  imageAsset: book['imageAsset']!,
                                  listenTime: book['listenTime']!,
                                  readTime: book['readTime']!,
                                  blur: true, // First card has blur
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    26.verticalSpace,
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
