import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:the_woodlands_series/components/resource/app_colors.dart';
import 'package:the_woodlands_series/components/resource/app_textstyle.dart';
import 'add_book_screen.dart';
import 'manage_books_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardHomeScreen(),
    const ManageBooksScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgClr,
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Responsive breakpoints
          final isMobile = constraints.maxWidth < 768;
          final isTablet = constraints.maxWidth >= 768 && constraints.maxWidth < 1024;
          final isDesktop = constraints.maxWidth >= 1024;
          
          if (isMobile) {
            // Mobile layout with bottom navigation
            return _buildMobileLayout();
          } else {
            // Desktop/Tablet layout with sidebar
            return _buildDesktopLayout(isTablet, isDesktop);
          }
        },
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        // Mobile header
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: AppColors.boxClr,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4.r,
                offset: Offset(0, 1.h),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.admin_panel_settings,
                color: AppColors.primaryColor,
                size: 20.sp,
              ),
              8.horizontalSpace,
              Text(
                'Admin Panel',
                style: AppTextStyles.lufgaMedium.copyWith(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Spacer(),
              IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: Icon(Icons.logout, color: Colors.red, size: 18.sp),
                padding: EdgeInsets.zero,
                constraints: BoxConstraints(),
              ),
            ],
          ),
        ),
        
        // Mobile navigation tabs
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          child: Row(
            children: [
              Expanded(
                child: _buildMobileNavItem(0, Icons.dashboard, 'Dashboard'),
              ),
              6.horizontalSpace,
              Expanded(
                child: _buildMobileNavItem(1, Icons.library_books, 'Books'),
              ),
            ],
          ),
        ),
        
        // Content
        Expanded(child: _screens[_selectedIndex]),
      ],
    );
  }

  Widget _buildDesktopLayout(bool isTablet, bool isDesktop) {
    return Row(
      children: [
        // Sidebar Navigation
        Container(
          width: isTablet ? 200.w : 250.w,
          decoration: BoxDecoration(
            color: AppColors.boxClr,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10.r,
                offset: Offset(2.w, 0),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(20.w),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor,
                  borderRadius: BorderRadius.only(
                    bottomRight: Radius.circular(20.r),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.admin_panel_settings,
                      color: Colors.white,
                      size: isTablet ? 32.sp : 40.sp,
                    ),
                    10.verticalSpace,
                    Text(
                      'Admin Panel',
                      style: AppTextStyles.lufgaLarge.copyWith(
                        color: Colors.white,
                        fontSize: isTablet ? 16.sp : 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              20.verticalSpace,

              // Navigation Items
              _buildNavItem(0, Icons.dashboard, 'Dashboard'),
              _buildNavItem(1, Icons.library_books, 'Manage Books'),
              20.verticalSpace,

              // Logout Button
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                child: GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.r),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: Colors.red, size: 20.sp),
                        10.horizontalSpace,
                        Text(
                          'Logout',
                          style: AppTextStyles.medium.copyWith(
                            color: Colors.red,
                            fontSize: 14.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Main Content
        Expanded(
          child: _screens[_selectedIndex],
        ),
      ],
    );
  }

  Widget _buildMobileNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(6.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
              size: 16.sp,
            ),
            6.horizontalSpace,
            Text(
              label,
              style: AppTextStyles.medium.copyWith(
                color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
                fontSize: 12.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String title) {
    final isSelected = _selectedIndex == index;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
              size: 20.sp,
            ),
            12.horizontalSpace,
            Text(
              title,
              style: AppTextStyles.medium.copyWith(
                color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardHomeScreen extends StatelessWidget {
  const DashboardHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 768;
        final isTablet = constraints.maxWidth >= 768 && constraints.maxWidth < 1024;
        
        return SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 12.w : 16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dashboard',
                style: AppTextStyles.lufgaLarge.copyWith(
                  color: Colors.white,
                  fontSize: isMobile ? 20.sp : 24.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              16.verticalSpace,

              // Quick Stats - Responsive grid
              _buildStatsGrid(isMobile, isTablet),
              20.verticalSpace,

              // Quick Actions
              Text(
                'Quick Actions',
                style: AppTextStyles.lufgaMedium.copyWith(
                  color: Colors.white,
                  fontSize: isMobile ? 14.sp : 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              12.verticalSpace,

              _buildActionsGrid(isMobile, isTablet, context),
              20.verticalSpace,
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsGrid(bool isMobile, bool isTablet) {
    if (isMobile) {
      // Mobile: 2x2 grid to save space
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildStatCard('Total Books', '24', Icons.library_books, AppColors.primaryColor)),
              8.horizontalSpace,
              Expanded(child: _buildStatCard('Published', '18', Icons.published_with_changes, Colors.green)),
            ],
          ),
          8.verticalSpace,
          Row(
            children: [
              Expanded(child: _buildStatCard('Draft', '6', Icons.edit, Colors.orange)),
              8.horizontalSpace,
              Expanded(child: _buildStatCard('Categories', '5', Icons.category, Colors.purple)),
            ],
          ),
        ],
      );
    } else if (isTablet) {
      // Tablet: 2x2 grid
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildStatCard('Total Books', '24', Icons.library_books, AppColors.primaryColor)),
              12.horizontalSpace,
              Expanded(child: _buildStatCard('Published', '18', Icons.published_with_changes, Colors.green)),
            ],
          ),
          12.verticalSpace,
          Row(
            children: [
              Expanded(child: _buildStatCard('Draft', '6', Icons.edit, Colors.orange)),
              12.horizontalSpace,
              Expanded(child: _buildStatCard('Categories', '5', Icons.category, Colors.purple)),
            ],
          ),
        ],
      );
    } else {
      // Desktop: 2x2 grid with more spacing
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildStatCard('Total Books', '24', Icons.library_books, AppColors.primaryColor)),
              16.horizontalSpace,
              Expanded(child: _buildStatCard('Published', '18', Icons.published_with_changes, Colors.green)),
            ],
          ),
          16.verticalSpace,
          Row(
            children: [
              Expanded(child: _buildStatCard('Draft', '6', Icons.edit, Colors.orange)),
              16.horizontalSpace,
              Expanded(child: _buildStatCard('Categories', '5', Icons.category, Colors.purple)),
            ],
          ),
        ],
      );
    }
  }

  Widget _buildActionsGrid(bool isMobile, bool isTablet, BuildContext context) {
    if (isMobile) {
      // Mobile: Single column
      return Column(
        children: [
          _buildActionCard(
            'Add New Book',
            Icons.add_circle,
            AppColors.primaryColor,
            () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddBookScreen()),
              );
            },
          ),
          12.verticalSpace,
          _buildActionCard(
            'Manage Books',
            Icons.edit,
            Colors.blue,
            () {
              // Navigate to manage books
            },
          ),
        ],
      );
    } else {
      // Tablet/Desktop: Row layout
      return Row(
        children: [
          Expanded(
            child: _buildActionCard(
              'Add New Book',
              Icons.add_circle,
              AppColors.primaryColor,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddBookScreen()),
                );
              },
            ),
          ),
          isTablet ? 12.horizontalSpace : 16.horizontalSpace,
          Expanded(
            child: _buildActionCard(
              'Manage Books',
              Icons.edit,
              Colors.blue,
              () {
                // Navigate to manage books
              },
            ),
          ),
        ],
      );
    }
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.boxClr,
        borderRadius: BorderRadius.circular(8.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24.sp),
          4.verticalSpace,
          Text(
            value,
            style: AppTextStyles.lufgaLarge.copyWith(
              color: Colors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          2.verticalSpace,
          Text(
            title,
            style: AppTextStyles.small.copyWith(
              color: Colors.white.withOpacity(0.7),
              fontSize: 10.sp,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: AppColors.boxClr,
          borderRadius: BorderRadius.circular(8.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4.r,
              offset: Offset(0, 2.h),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24.sp),
            8.verticalSpace,
            Text(
              title,
              style: AppTextStyles.medium.copyWith(
                color: Colors.white,
                fontSize: 12.sp,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
