import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../components/resource/size_constants.dart';
import '../../components/resource/app_colors.dart';
import '../../components/resource/app_textstyle.dart';

class GamesScreen extends StatelessWidget {
  const GamesScreen({super.key});

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
                'Games & Quizzes',
                style: AppTextStyles.lufgaLarge.copyWith(color: Colors.white),
              ),
              SizedBox(height: SizeCons.getResponsiveHeight(8)),
              Text(
                'Test your knowledge and have fun!',
                style: AppTextStyles.regular.copyWith(color: Colors.grey[400]),
              ),
              SizedBox(height: SizeCons.getResponsiveHeight(24)),

              // Stats Cards
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Score',
                      '1,250',
                      Icons.star,
                      AppColors.primaryColor,
                    ),
                  ),
                  SizedBox(width: SizeCons.getResponsiveWidth(16)),
                  Expanded(
                    child: _buildStatCard(
                      'Level',
                      '12',
                      Icons.trending_up,
                      Colors.blue,
                    ),
                  ),
                ],
              ),
              SizedBox(height: SizeCons.getResponsiveHeight(24)),

              // Game Categories
              Text(
                'Choose Your Game',
                style: AppTextStyles.lufgaMedium.copyWith(color: Colors.white),
              ),
              SizedBox(height: SizeCons.getResponsiveHeight(16)),

              // Games Grid
              Expanded(
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: SizeCons.getResponsiveWidth(16),
                    mainAxisSpacing: SizeCons.getResponsiveHeight(16),
                    childAspectRatio: 1.1,
                  ),
                  itemCount: 6,
                  itemBuilder: (context, index) {
                    final games = [
                      {
                        'name': 'Quiz Master',
                        'icon': Icons.quiz,
                        'color': AppColors.primaryColor,
                      },
                      {
                        'name': 'Word Hunt',
                        'icon': Icons.search,
                        'color': Colors.orange,
                      },
                      {
                        'name': 'Story Builder',
                        'icon': Icons.edit,
                        'color': Colors.purple,
                      },
                      {
                        'name': 'Memory Game',
                        'icon': Icons.psychology,
                        'color': Colors.green,
                      },
                      {
                        'name': 'Trivia Time',
                        'icon': Icons.help_outline,
                        'color': Colors.red,
                      },
                      {
                        'name': 'Puzzle Quest',
                        'icon': Icons.extension,
                        'color': Colors.teal,
                      },
                    ];

                    final game = games[index];

                    return Container(
                      decoration: BoxDecoration(
                        color: AppColors.boxClr,
                        borderRadius: BorderRadius.circular(
                          SizeCons.getResponsiveRadius(16),
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
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: SizeCons.getResponsiveWidth(60),
                            height: SizeCons.getResponsiveHeight(60),
                            decoration: BoxDecoration(
                              color: (game['color'] as Color).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(
                                SizeCons.getResponsiveRadius(30),
                              ),
                            ),
                            child: Icon(
                              game['icon'] as IconData,
                              color: game['color'] as Color,
                              size: SizeCons.getResponsiveFontSize(30),
                            ),
                          ),
                          SizedBox(height: SizeCons.getResponsiveHeight(12)),
                          Text(
                            game['name'] as String,
                            style: AppTextStyles.medium.copyWith(
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: SizeCons.getResponsiveHeight(8)),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: SizeCons.getResponsiveWidth(12),
                              vertical: SizeCons.getResponsiveHeight(4),
                            ),
                            decoration: BoxDecoration(
                              color: (game['color'] as Color).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(
                                SizeCons.getResponsiveRadius(12),
                              ),
                            ),
                            child: Text(
                              'Play Now',
                              style: AppTextStyles.small.copyWith(
                                color: game['color'] as Color,
                                fontWeight: FontWeight.w600,
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

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(SizeCons.getResponsiveWidth(16)),
      decoration: BoxDecoration(
        color: AppColors.boxClr,
        borderRadius: BorderRadius.circular(SizeCons.getResponsiveRadius(12)),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                icon,
                color: color,
                size: SizeCons.getResponsiveFontSize(24),
              ),
              Text(
                title,
                style: AppTextStyles.small.copyWith(color: Colors.grey[400]),
              ),
            ],
          ),
          SizedBox(height: SizeCons.getResponsiveHeight(8)),
          Text(
            value,
            style: AppTextStyles.lufgaLarge.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}
