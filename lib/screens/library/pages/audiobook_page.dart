import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:the_woodlands_series/components/card/global_card.dart';
import 'package:the_woodlands_series/components/resource/app_assets.dart';
import 'package:the_woodlands_series/components/resource/app_colors.dart';
import 'package:the_woodlands_series/components/resource/app_textstyle.dart';
import 'package:the_woodlands_series/components/textfield/primary_textfield.dart';
import 'package:the_woodlands_series/screens/library/widgets/continue_listening_widget.dart';

class AudiobookPage extends StatelessWidget {
  AudiobookPage({super.key});

  // Audiobook specific data
  final List<Map<String, String>> audiobooks = const [
    {
      'chapter': '5 Chapters',
      'title': 'A Love Story Beneath The Rain That Healed Us',
      'author': 'Mark mcallister',
      'imageAsset': AppAssets.temp5,
    },
    {
      'chapter': '5 Chapters',
      'title': 'A Love Story Beneath The Rain That Healed Us',
      'author': 'Mark mcallister',
      'imageAsset': AppAssets.temp5,
    },
    {
      'chapter': '5 Chapters',
      'title': 'A Love Story Beneath The Rain That Healed Us',
      'author': 'Mark mcallister',
      'imageAsset': AppAssets.temp5,
    },
  ];

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
    return Column(
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
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Text(
                    'Trending Audio Books',
                    style: AppTextStyles.lufgaLarge.copyWith(
                      color: Colors.white,
                      fontSize: 18.sp,
                    ),
                  ),
                ),
                16.verticalSpace,
                // Audiobooks List
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  itemCount: audiobooks.length,
                  itemBuilder: (context, index) {
                    final book = audiobooks[index];
                    return Container(
                      margin: EdgeInsets.only(bottom: 16.h),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Book cover
                          Container(
                            width: 80.w,
                            height: 80.h,
                            decoration: BoxDecoration(
                              image: DecorationImage(
                                image: AssetImage(book['imageAsset']!),
                                fit: BoxFit.cover,
                              ),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                          ),
                          SizedBox(width: 16.w),

                          // Book details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  book['chapter']!,
                                  style: AppTextStyles.regular.copyWith(
                                    color: AppColors.primaryColor,
                                    fontSize: 12.sp,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                4.verticalSpace,
                                Text(
                                  book['title']!,
                                  style: AppTextStyles.lufgaMedium.copyWith(
                                    color: AppColors.whiteColor,
                                    fontSize: 14.sp,
                                  ),
                                ),
                                4.verticalSpace,
                                Text(
                                  book['author']!,
                                  style: AppTextStyles.regular.copyWith(
                                    color: AppColors.whiteColor.withValues(
                                      alpha: 0.5,
                                    ),
                                    fontSize: 10.sp,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),

                          // Play button
                          Container(
                            width: 40.w,
                            height: 40.h,
                            decoration: BoxDecoration(
                              color: AppColors.boxClr,
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: Icon(
                              Icons.play_arrow,
                              color: AppColors.primaryColor,
                              size: 24.sp,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Suggested for you',
                        style: AppTextStyles.lufgaLarge.copyWith(
                          color: Colors.white,
                          fontSize: 20.sp,
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
          ),
        ),
      ],
    );
  }
}
