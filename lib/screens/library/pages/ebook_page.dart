import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:the_woodlands_series/components/card/global_card.dart';
import 'package:the_woodlands_series/components/resource/app_assets.dart';
import 'package:the_woodlands_series/components/resource/app_colors.dart';
import 'package:the_woodlands_series/components/resource/app_textstyle.dart';
import 'package:the_woodlands_series/components/textfield/primary_textfield.dart';

class EbookPage extends StatelessWidget {
  EbookPage({super.key});

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
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: PrimaryTextField(
              hint: 'Title, author or keyword',
              prefixIcon: Icon(Icons.search, size: 20.sp),
              height: 55.h,
              verticalPad: 10.h,
            ),
          ),

          Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Searches',
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
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 16.w,
                    mainAxisSpacing: 16.h,
                    childAspectRatio: 0.45,
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
              ),
            ],
          ),
          26.verticalSpace,
        ],
      ),
    );
  }
}
