import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../components/resource/size_constants.dart';
import '../../components/resource/app_colors.dart';
import '../../components/resource/app_textstyle.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key});

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
              Text(
                'My Library',
                style: AppTextStyles.lufgaLarge.copyWith(color: Colors.white),
              ),
              SizedBox(height: SizeCons.getResponsiveHeight(8)),
              Text(
                'Continue your reading journey',
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
                        'Search your library...',
                        style: AppTextStyles.regular.copyWith(
                          color: Colors.grey[400],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: SizeCons.getResponsiveHeight(24)),

              // Categories
              Row(
                children: [
                  _buildCategoryChip('All', true),
                  SizedBox(width: SizeCons.getResponsiveWidth(12)),
                  _buildCategoryChip('Reading', false),
                  SizedBox(width: SizeCons.getResponsiveWidth(12)),
                  _buildCategoryChip('Completed', false),
                  SizedBox(width: SizeCons.getResponsiveWidth(12)),
                  _buildCategoryChip('Favorites', false),
                ],
              ),
              SizedBox(height: SizeCons.getResponsiveHeight(24)),

              // Books Grid
              Expanded(
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: SizeCons.getResponsiveWidth(16),
                    mainAxisSpacing: SizeCons.getResponsiveHeight(16),
                    childAspectRatio: 0.7,
                  ),
                  itemCount: 6,
                  itemBuilder: (context, index) {
                    return Container(
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: AppColors.primaryColor.withOpacity(0.2),
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(
                                    SizeCons.getResponsiveRadius(12),
                                  ),
                                  topRight: Radius.circular(
                                    SizeCons.getResponsiveRadius(12),
                                  ),
                                ),
                              ),
                              child: Icon(
                                Icons.menu_book,
                                color: AppColors.primaryColor,
                                size: SizeCons.getResponsiveFontSize(40),
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Padding(
                              padding: EdgeInsets.all(
                                SizeCons.getResponsiveWidth(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Story ${index + 1}',
                                    style: AppTextStyles.medium.copyWith(
                                      color: Colors.white,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(
                                    height: SizeCons.getResponsiveHeight(4),
                                  ),
                                  Text(
                                    'Chapter ${index + 1}',
                                    style: AppTextStyles.small.copyWith(
                                      color: Colors.grey[400],
                                    ),
                                  ),
                                  SizedBox(
                                    height: SizeCons.getResponsiveHeight(8),
                                  ),
                                  LinearProgressIndicator(
                                    value: (index + 1) * 0.15,
                                    backgroundColor: Colors.grey[700],
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppColors.primaryColor,
                                    ),
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label, bool isSelected) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SizeCons.getResponsiveWidth(16),
        vertical: SizeCons.getResponsiveHeight(8),
      ),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryColor : AppColors.boxClr,
        borderRadius: BorderRadius.circular(SizeCons.getResponsiveRadius(20)),
      ),
      child: Text(
        label,
        style: AppTextStyles.small.copyWith(
          color: isSelected ? Colors.black : Colors.white,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }
}
