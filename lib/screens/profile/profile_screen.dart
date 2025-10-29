import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:the_woodlands_series/components/button/primary_button.dart';
import 'package:the_woodlands_series/components/resource/app_assets.dart';
import 'package:the_woodlands_series/components/resource/app_colors.dart';
import 'package:the_woodlands_series/components/resource/app_routers.dart';
import 'package:the_woodlands_series/components/resource/app_textstyle.dart';
import 'package:the_woodlands_series/components/card/global_card.dart';
import 'package:the_woodlands_series/components/utils/custom_toast.dart';
import 'package:the_woodlands_series/screens/library/widgets/continue_listening_widget.dart';
import 'package:the_woodlands_series/screens/login_screen/login_screen.dart';
import 'package:the_woodlands_series/bloc/auth/auth_bloc.dart';
import 'package:the_woodlands_series/bloc/auth/auth_event.dart';
import 'package:the_woodlands_series/bloc/auth/auth_state.dart';
import 'package:the_woodlands_series/models/user_model.dart';
import 'package:the_woodlands_series/screens/profile/edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String title;
  final String image;
  const ProfileScreen({super.key, required this.title, required this.image});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      setState(() {
        currentUser = authState.user;
      });
    }
  }

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
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthLoading) {
          // Show loading dialog
          _showLoadingDialog(context);
        } else if (state is Unauthenticated) {
          // Dismiss loading dialog
          Navigator.of(context, rootNavigator: true).pop();
          // Navigate to login screen after successful logout
          CustomToast.showSuccess(context, 'Logged out successfully!');
          Future.delayed(const Duration(milliseconds: 500), () {
            if (context.mounted) {
              AppRouter.clearStack(context, const LoginScreen());
            }
          });
        } else if (state is AuthError) {
          // Dismiss loading dialog if showing
          Navigator.of(context, rootNavigator: true).pop();
          // Show error message
          CustomToast.showError(context, state.message);
        }
      },
      child: Scaffold(
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
              onPressed: _handleLogout,
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
                    Positioned.fill(child: _buildBackground()),

                    // Main content
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildProfileAvatar(),
                          16.verticalSpace,

                          // User name
                          SizedBox(
                            width: 350.w,
                            child: Text(
                              currentUser?.name ?? 'User',
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
                              currentUser?.email ?? 'email@example.com',
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
                            onTap: _navigateToEditProfile,
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
      ),
    );
  }

  void _handleLogout() {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.boxClr,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Text(
            'Logout',
            style: AppTextStyles.lufgaLarge.copyWith(
              color: Colors.white,
              fontSize: 20.sp,
            ),
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: AppTextStyles.lufgaMedium.copyWith(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14.sp,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Cancel',
                style: TextStyle(color: Colors.grey, fontSize: 14.sp),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                // Dispatch logout event (loading will be shown via BlocListener)
                context.read<AuthBloc>().add(const LogoutUser());
              },
              child: Text(
                'Logout',
                style: TextStyle(
                  color: AppColors.primaryColor,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PopScope(
          canPop: false,
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: AppColors.boxClr,
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primaryColor,
                    ),
                  ),
                  20.verticalSpace,
                  Text(
                    'Logging out...',
                    style: AppTextStyles.lufgaMedium.copyWith(
                      color: Colors.white,
                      fontSize: 16.sp,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileAvatar() {
    if (currentUser?.profileImageUrl != null &&
        currentUser!.profileImageUrl!.isNotEmpty) {
      // Show network image
      return Container(
        width: 136.w,
        height: 136.h,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(
            image: NetworkImage(currentUser!.profileImageUrl!),
            fit: BoxFit.cover,
          ),
          border: Border.all(color: AppColors.primaryColor, width: 3),
        ),
      );
    } else {
      // Show avatar with initials
      return Container(
        width: 136.w,
        height: 136.h,
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
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 3),
        ),
        child: Center(
          child: Text(
            _getInitials(currentUser?.name ?? 'U'),
            style: AppTextStyles.lufgaLarge.copyWith(
              color: Colors.white,
              fontSize: 48.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return 'U';
  }

  Widget _buildBackground() {
    if (currentUser?.profileImageUrl != null &&
        currentUser!.profileImageUrl!.isNotEmpty) {
      // Show user's profile image with blur
      return Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(currentUser!.profileImageUrl!),
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
      );
    } else {
      // Show initials with dark gradient background
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.black.withOpacity(0.8),
              Colors.black.withOpacity(0.9),
            ],
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primaryColor.withOpacity(0.1),
                AppColors.primaryColor.withOpacity(0.05),
                Colors.transparent,
                AppColors.bgClr,
                AppColors.bgClr,
              ],
              stops: [0.0, 0.2, 0.4, 0.7, 1.0],
            ),
          ),
          child: Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 200.h),
              child: Text(
                _getInitials(currentUser?.name ?? 'U'),
                style: AppTextStyles.lufgaLarge.copyWith(
                  color: Colors.white.withOpacity(0.1),
                  fontSize: 120.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      );
    }
  }

  void _navigateToEditProfile() async {
    // Navigate to edit profile screen
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const EditProfileScreen()),
    );
    if (result == true) {
      // Reload user data
      _loadUserData();
    }
  }
}
