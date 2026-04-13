import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:the_woodlands_series/components/resource/app_assets.dart';
import 'package:the_woodlands_series/components/resource/app_colors.dart';
import 'package:the_woodlands_series/components/resource/app_routers.dart';
import 'package:the_woodlands_series/components/resource/app_textstyle.dart';
import 'package:the_woodlands_series/components/utils/three_dot_loader.dart';
import 'package:the_woodlands_series/screens/profile/profile_screen.dart';
import 'package:the_woodlands_series/bloc/auth/auth_bloc.dart';
import 'package:the_woodlands_series/bloc/auth/auth_state.dart';
import 'package:the_woodlands_series/models/user_model.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  UserModel? currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stats
  int totalUsers = 0;
  int totalBooks = 0;
  int activeToday = 0;
  int inactiveBooks = 0;
  bool isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadStats();
  }

  void _loadUserData() {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      setState(() {
        currentUser = authState.user;
      });
    }
  }

  Future<void> _loadStats() async {
    setState(() {
      isLoadingStats = true;
    });

    try {
      // Fetch total users (excluding admins)
      final usersSnapshot = await _firestore
          .collection('users')
          .where('role', isNotEqualTo: 'admin')
          .get();

      // Fetch total books
      final booksSnapshot = await _firestore.collection('books').get();

      // Fetch inactive books (assuming there's an 'isActive' field)
      final inactiveBooksSnapshot = await _firestore
          .collection('books')
          .where('isActive', isEqualTo: false)
          .get();

      // Calculate active users today (users who logged in today)
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final activeTodaySnapshot = await _firestore
          .collection('users')
          .where('role', isNotEqualTo: 'admin')
          .where('lastLoginAt', isGreaterThanOrEqualTo: startOfDay)
          .get();

      setState(() {
        totalUsers = usersSnapshot.docs.length;
        totalBooks = booksSnapshot.docs.length;
        inactiveBooks = inactiveBooksSnapshot.docs.length;
        activeToday = activeTodaySnapshot.docs.length;
        isLoadingStats = false;
      });
    } catch (e) {
      print('Error loading stats: $e');
      setState(() {
        isLoadingStats = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgClr,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    final user = state is Authenticated ? state.user : null;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Welcome back, Admin!',
                                style: AppTextStyles.lufgaLarge.copyWith(
                                  color: Colors.white,
                                  fontSize: 22.sp,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              8.verticalSpace,
                              Text(
                                user?.name ?? 'Administrator',
                                style: AppTextStyles.regular.copyWith(
                                  color: AppColors.primaryColor,
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        8.horizontalSpace,
                        GestureDetector(
                          onTap: () {
                            AppRouter.routeTo(
                              context,
                              ProfileScreen(
                                title: 'Profile',
                                image: AppAssets.profileImg,
                              ),
                            );
                          },
                          child: _buildUserAvatar(user),
                        ),
                      ],
                    );
                  },
                ),
                24.verticalSpace,

                // Stats Cards
                Text(
                  'Overview',
                  style: AppTextStyles.lufgaLarge.copyWith(
                    color: Colors.white,
                    fontSize: 20.sp,
                  ),
                ),
                16.verticalSpace,
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _showAllUsersDialog,
                        child: _buildStatCard(
                          'Total Users',
                          totalUsers.toString(),
                          Icons.people_outline,
                          Colors.blue,
                          isLoading: isLoadingStats,
                        ),
                      ),
                    ),
                    12.horizontalSpace,
                    Expanded(
                      child: _buildStatCard(
                        'Total Books',
                        totalBooks.toString(),
                        Icons.book_outlined,
                        Colors.green,
                        isLoading: isLoadingStats,
                      ),
                    ),
                  ],
                ),
                12.verticalSpace,
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Active Today',
                        activeToday.toString(),
                        Icons.online_prediction,
                        Colors.orange,
                        isLoading: isLoadingStats,
                      ),
                    ),
                    12.horizontalSpace,
                    Expanded(
                      child: _buildStatCard(
                        'Inactive Books',
                        inactiveBooks.toString(),
                        Icons.book_outlined,
                        Colors.red,
                        isLoading: isLoadingStats,
                      ),
                    ),
                  ],
                ),

                24.verticalSpace,

                // Graph Section
                Text(
                  'Analytics',
                  style: AppTextStyles.lufgaLarge.copyWith(
                    color: Colors.white,
                    fontSize: 20.sp,
                  ),
                ),
                16.verticalSpace,
                _buildChartCard(),

                24.verticalSpace,

                // Recent Activity
                Text(
                  'Recent Activity',
                  style: AppTextStyles.lufgaLarge.copyWith(
                    color: Colors.white,
                    fontSize: 20.sp,
                  ),
                ),
                16.verticalSpace,
                _buildRecentActivityList(),

                24.verticalSpace,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    bool isLoading = false,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.boxClr,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(icon, color: color, size: 24.sp),
          ),
          12.verticalSpace,
          isLoading
              ? ThreeDotLoader(color: Colors.white, size: 10.w, spacing: 6.w)
              : Text(
                  value,
                  style: AppTextStyles.lufgaLarge.copyWith(
                    color: Colors.white,
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
          4.verticalSpace,
          Text(
            title,
            style: AppTextStyles.regular.copyWith(
              color: Colors.white.withOpacity(0.6),
              fontSize: 12.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.boxClr,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'User Growth',
                style: AppTextStyles.lufgaMedium.copyWith(
                  color: Colors.white,
                  fontSize: 16.sp,
                ),
              ),
              Text(
                'Last 7 days',
                style: AppTextStyles.regular.copyWith(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
          20.verticalSpace,
          // Simple bar chart representation
          SizedBox(
            height: 180.h,
            child: isLoadingStats
                ? Center(
                    child: ThreeDotLoader(
                      color: AppColors.primaryColor,
                      size: 12.w,
                      spacing: 8.w,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _buildBar(80, 'Mon'),
                      _buildBar(120, 'Tue'),
                      _buildBar(90, 'Wed'),
                      _buildBar(150, 'Thu'),
                      _buildBar(110, 'Fri'),
                      _buildBar(140, 'Sat'),
                      _buildBar(170, 'Sun'),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBar(double height, String label) {
    final maxHeight = 150.0;
    final barHeight = (height / 170) * maxHeight;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 32.w,
          height: barHeight,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                AppColors.primaryColor,
                AppColors.primaryColor.withOpacity(0.6),
              ],
            ),
            borderRadius: BorderRadius.circular(8.r),
          ),
        ),
        8.verticalSpace,
        Text(
          label,
          style: AppTextStyles.regular.copyWith(
            color: Colors.white.withOpacity(0.6),
            fontSize: 10.sp,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentActivityList() {
    final activities = [
      {
        'user': 'Admin',
        'action': 'Updated user roles and permissions',
        'time': '5 min ago',
      },
      {
        'user': 'Admin',
        'action': 'Deleted inactive user accounts',
        'time': '15 min ago',
      },
      {
        'user': 'Admin',
        'action': 'Added new book category "Fantasy"',
        'time': '1 hour ago',
      },
      {
        'user': 'Admin',
        'action': 'Published monthly analytics report',
        'time': '2 hours ago',
      },
      {
        'user': 'Admin',
        'action': 'Updated system configuration',
        'time': '3 hours ago',
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.boxClr,
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: activities.length,
        separatorBuilder: (context, index) =>
            Divider(color: Colors.white.withOpacity(0.1), height: 1),
        itemBuilder: (context, index) {
          final activity = activities[index];
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Row(
              children: [
                Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primaryColor,
                        AppColors.primaryColor.withOpacity(0.7),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _getInitials(activity['user']!),
                      style: AppTextStyles.lufgaMedium.copyWith(
                        color: Colors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                12.horizontalSpace,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity['user']!,
                        style: AppTextStyles.lufgaMedium.copyWith(
                          color: Colors.white,
                          fontSize: 14.sp,
                        ),
                      ),
                      4.verticalSpace,
                      Text(
                        activity['action']!,
                        style: AppTextStyles.regular.copyWith(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  activity['time']!,
                  style: AppTextStyles.regular.copyWith(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildUserAvatar(UserModel? user) {
    // If user has a profile image, show it
    if (user?.profileImageUrl != null && user!.profileImageUrl!.isNotEmpty) {
      return Container(
        width: 44.h,
        height: 44.h,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.primaryColor.withOpacity(0.3),
            width: 2,
          ),
          image: DecorationImage(
            image: NetworkImage(user.profileImageUrl!),
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    // If user has no image, show avatar with initials
    if (user != null) {
      return Container(
        width: 44.h,
        height: 44.h,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryColor,
              AppColors.primaryColor.withOpacity(0.7),
            ],
          ),
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 2),
        ),
        child: Center(
          child: Text(
            _getInitials(user.name),
            style: AppTextStyles.lufgaMedium.copyWith(
              color: Colors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    // Fallback to default image
    return Container(
      width: 44.h,
      height: 44.h,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        image: DecorationImage(
          image: AssetImage(AppAssets.profileImg),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return 'A';
  }

  Future<void> _showAllUsersDialog() async {
    // Show loading dialog first
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: AppColors.boxClr,
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: AppColors.primaryColor),
              16.verticalSpace,
              Text(
                'Loading users...',
                style: AppTextStyles.regular.copyWith(
                  color: Colors.white,
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      // Fetch all users (excluding admins)
      QuerySnapshot usersSnapshot;
      try {
        usersSnapshot = await _firestore
            .collection('users')
            .where('role', isNotEqualTo: 'admin')
            .orderBy('createdAt', descending: true)
            .get();
      } catch (e) {
        // If orderBy fails (missing index), fetch without orderBy
        print('OrderBy failed, fetching without order: $e');
        usersSnapshot = await _firestore
            .collection('users')
            .where('role', isNotEqualTo: 'admin')
            .get();
      }

      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Convert to UserModel list and sort manually if needed
      List<UserModel> users = usersSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        // Handle Timestamp conversion if needed
        if (data['createdAt'] is Timestamp) {
          data['createdAt'] = (data['createdAt'] as Timestamp).millisecondsSinceEpoch;
        }
        return UserModel.fromFirestore(doc.id, data);
      }).toList();

      // Sort by createdAt descending if not already sorted
      users.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // Show users dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => _buildUsersDialog(users),
        );
      }
    } catch (e) {
      // Close loading dialog
      if (mounted) Navigator.pop(context);

      // Show error dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppColors.boxClr,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.r),
            ),
            title: Text(
              'Error',
              style: AppTextStyles.lufgaLarge.copyWith(
                color: Colors.white,
                fontSize: 18.sp,
              ),
            ),
            content: Text(
              'Failed to load users: $e',
              style: AppTextStyles.regular.copyWith(
                color: Colors.white.withOpacity(0.7),
                fontSize: 14.sp,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'OK',
                  style: TextStyle(
                    color: AppColors.primaryColor,
                    fontSize: 14.sp,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    }
  }

  Widget _buildUsersDialog(List<UserModel> users) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 24.h),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: BoxDecoration(
          color: AppColors.boxClr,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: EdgeInsets.all(20.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'All Users (${users.length})',
                    style: AppTextStyles.lufgaLarge.copyWith(
                      color: Colors.white,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24.sp,
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: Colors.white.withOpacity(0.1), height: 1),
            // Users List
            Flexible(
              child: users.isEmpty
                  ? Padding(
                      padding: EdgeInsets.all(40.w),
                      child: Center(
                        child: Text(
                          'No users found',
                          style: AppTextStyles.regular.copyWith(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 14.sp,
                          ),
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      itemCount: users.length,
                      separatorBuilder: (context, index) =>
                          Divider(color: Colors.white.withOpacity(0.1), height: 1),
                      itemBuilder: (context, index) {
                        final user = users[index];
                        return _buildUserListItem(user);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserListItem(UserModel user) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: 50.w,
            height: 50.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primaryColor,
                  AppColors.primaryColor.withOpacity(0.7),
                ],
              ),
            ),
            child: user.profileImageUrl != null &&
                    user.profileImageUrl!.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      user.profileImageUrl!,
                      width: 50.w,
                      height: 50.w,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Text(
                            _getInitials(user.name),
                            style: AppTextStyles.lufgaMedium.copyWith(
                              color: Colors.white,
                              fontSize: 18.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                  )
                : Center(
                    child: Text(
                      _getInitials(user.name),
                      style: AppTextStyles.lufgaMedium.copyWith(
                        color: Colors.white,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
          ),
          12.horizontalSpace,
          // User Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: AppTextStyles.lufgaMedium.copyWith(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                4.verticalSpace,
                Row(
                  children: [
                    Icon(
                      Icons.email_outlined,
                      size: 14.sp,
                      color: Colors.white.withOpacity(0.6),
                    ),
                    4.horizontalSpace,
                    Expanded(
                      child: Text(
                        user.email,
                        style: AppTextStyles.regular.copyWith(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12.sp,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty) ...[
                  4.verticalSpace,
                  Row(
                    children: [
                      Icon(
                        Icons.phone_outlined,
                        size: 14.sp,
                        color: Colors.white.withOpacity(0.6),
                      ),
                      4.horizontalSpace,
                      Text(
                        user.phoneNumber!,
                        style: AppTextStyles.regular.copyWith(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                ],
                4.verticalSpace,
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: user.role == 'admin'
                            ? Colors.red.withOpacity(0.2)
                            : Colors.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(
                          color: user.role == 'admin'
                              ? Colors.red
                              : Colors.blue,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        user.role.toUpperCase(),
                        style: AppTextStyles.regular.copyWith(
                          color: user.role == 'admin' ? Colors.red : Colors.blue,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    8.horizontalSpace,
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 12.sp,
                      color: Colors.white.withOpacity(0.5),
                    ),
                    4.horizontalSpace,
                    Text(
                      _formatDate(user.createdAt),
                      style: AppTextStyles.regular.copyWith(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 11.sp,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }
}
