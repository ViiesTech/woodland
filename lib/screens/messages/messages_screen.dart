import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../components/resource/size_constants.dart';
import '../../components/resource/app_colors.dart';
import '../../components/resource/app_textstyle.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgClr,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(SizeCons.getResponsiveWidth(20)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Messages',
                    style: AppTextStyles.lufgaLarge.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.all(SizeCons.getResponsiveWidth(8)),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      borderRadius: BorderRadius.circular(
                        SizeCons.getResponsiveRadius(8),
                      ),
                    ),
                    child: Icon(
                      Icons.add,
                      color: Colors.black,
                      size: SizeCons.getResponsiveFontSize(20),
                    ),
                  ),
                ],
              ),
              SizedBox(height: SizeCons.getResponsiveHeight(8)),
              Text(
                'Connect with other readers',
                style: AppTextStyles.regular.copyWith(color: Colors.grey[400]),
              ),
              SizedBox(height: SizeCons.getResponsiveHeight(24)),

              // Search Bar
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: SizeCons.getResponsiveWidth(16),
                  vertical: SizeCons.getResponsiveHeight(12),
                ),
                decoration: BoxDecoration(
                  color: AppColors.boxClr,
                  borderRadius: BorderRadius.circular(
                    SizeCons.getResponsiveRadius(12),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search,
                      color: Colors.grey[400],
                      size: SizeCons.getResponsiveFontSize(20),
                    ),
                    SizedBox(width: SizeCons.getResponsiveWidth(12)),
                    Expanded(
                      child: Text(
                        'Search conversations...',
                        style: AppTextStyles.regular.copyWith(
                          color: Colors.grey[400],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: SizeCons.getResponsiveHeight(24)),

              // Messages List
              Expanded(
                child: ListView.builder(
                  itemCount: 8,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: EdgeInsets.only(
                        bottom: SizeCons.getResponsiveHeight(12),
                      ),
                      padding: EdgeInsets.all(SizeCons.getResponsiveWidth(16)),
                      decoration: BoxDecoration(
                        color: AppColors.boxClr,
                        borderRadius: BorderRadius.circular(
                          SizeCons.getResponsiveRadius(12),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8.r,
                            offset: Offset(0, 2.h),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Avatar
                          Container(
                            width: SizeCons.getResponsiveWidth(50),
                            height: SizeCons.getResponsiveHeight(50),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor,
                              borderRadius: BorderRadius.circular(
                                SizeCons.getResponsiveRadius(25),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'U${index + 1}',
                                style: AppTextStyles.medium.copyWith(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: SizeCons.getResponsiveWidth(16)),

                          // Message Content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'User ${index + 1}',
                                      style: AppTextStyles.medium.copyWith(
                                        color: Colors.white,
                                      ),
                                    ),
                                    Text(
                                      '${index + 1}m ago',
                                      style: AppTextStyles.small.copyWith(
                                        color: Colors.grey[400],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(
                                  height: SizeCons.getResponsiveHeight(4),
                                ),
                                Text(
                                  index % 3 == 0
                                      ? 'Hey! Did you finish reading Chapter ${index + 1}?'
                                      : index % 3 == 1
                                      ? 'What do you think about the plot twist?'
                                      : 'Can we discuss the ending?',
                                  style: AppTextStyles.regular.copyWith(
                                    color: Colors.grey[300],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),

                          // Unread indicator
                          if (index < 3)
                            Container(
                              width: SizeCons.getResponsiveWidth(8),
                              height: SizeCons.getResponsiveHeight(8),
                              decoration: BoxDecoration(
                                color: AppColors.primaryColor,
                                borderRadius: BorderRadius.circular(
                                  SizeCons.getResponsiveRadius(4),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
