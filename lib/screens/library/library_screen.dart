import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:the_woodlands_series/components/resource/app_assets.dart';
import 'package:the_woodlands_series/components/resource/app_routers.dart';
import 'package:the_woodlands_series/screens/library/pages/ebook_page.dart';
import 'package:the_woodlands_series/screens/profile/profile_screen.dart';
import 'package:the_woodlands_series/bloc/auth/auth_bloc.dart';
import 'package:the_woodlands_series/bloc/auth/auth_state.dart';
import '../../components/resource/app_colors.dart';
import '../../components/resource/app_textstyle.dart';
import '../../models/user_model.dart';
import 'widgets/custom_tab_widget.dart';
import 'pages/audiobook_page.dart';
import 'pages/library_videos_page.dart';
import 'pages/add_video_screen.dart';
import 'pages/add_mp3_screen.dart';
import 'pages/mp3_page.dart';
import 'add_book_screen.dart';
import 'pages/quiz_page.dart';
import 'pages/add_quiz_screen.dart';
import '../../admin_panel/screens/add_edit_folder_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  int selectedTabIndex = 0;
  bool isAdmin = false;
  final GlobalKey<LibraryVideosPageState> _videoPageKey = GlobalKey();
  final GlobalKey<Mp3PageState> _mp3PageKey = GlobalKey();
  final GlobalKey<QuizPageState> _quizPageKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  void _checkUserRole() {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      setState(() {
        isAdmin = authState.user.role == 'admin';
      });
    }
  }

  Future<void> _refreshVideoTab() async {
    final state = _videoPageKey.currentState;
    if (state != null) {
      await state.loadVideos();
    }
  }

  Future<void> _refreshMp3Tab() async {
    final state = _mp3PageKey.currentState;
    if (state != null) {
      await state.loadMp3s();
    }
  }

  Future<void> _refreshQuizTab() async {
    final state = _quizPageKey.currentState;
    if (state != null) {
      state.loadQuizzes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgClr,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            16.verticalSpace,
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Explore',
                    style: AppTextStyles.lufgaLarge.copyWith(
                      color: Colors.white,
                      fontSize: 20.sp,
                    ),
                  ),

                  Row(
                    children: [
                      // Add Book/Video Icon (only for admin)
                      if (isAdmin)
                        GestureDetector(
                          onTap: () async {
                            if (selectedTabIndex == 1) {
                              await AppRouter.routeTo(
                                context,
                                const AddVideoScreen(),
                              );
                              await _refreshVideoTab();
                            } else if (selectedTabIndex == 3) {
                              await AppRouter.routeTo(
                                context,
                                const AddMp3Screen(),
                              );
                              await _refreshMp3Tab();
                            } else if (selectedTabIndex == 4) {
                              await AppRouter.routeTo(
                                context,
                                const AddQuizScreen(),
                              );
                              await _refreshQuizTab();
                            } else if (selectedTabIndex == 0) {
                              // E-book tab: Show selector for E-book or Folder
                              showModalBottomSheet(
                                context: context,
                                backgroundColor: AppColors.boxClr,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
                                ),
                                builder: (context) => Container(
                                  padding: EdgeInsets.all(20.w),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'What would you like to create?',
                                        style: AppTextStyles.lufgaMedium.copyWith(
                                          color: Colors.white,
                                          fontSize: 16.sp,
                                        ),
                                      ),
                                      20.verticalSpace,
                                      ListTile(
                                        leading: Icon(Icons.library_books, color: AppColors.primaryColor, size: 24.sp),
                                        title: Text(
                                          'Add New E-Book',
                                          style: AppTextStyles.medium.copyWith(color: Colors.white),
                                        ),
                                        onTap: () async {
                                          Navigator.pop(context);
                                          await AppRouter.routeTo(
                                            context,
                                            const AddBookScreen(initialType: 'ebook'),
                                          );
                                        },
                                      ),
                                      Divider(color: Colors.white.withOpacity(0.1)),
                                      ListTile(
                                        leading: Icon(Icons.folder, color: AppColors.primaryColor, size: 24.sp),
                                        title: Text(
                                          'Add New Folder',
                                          style: AppTextStyles.medium.copyWith(color: Colors.white),
                                        ),
                                        onTap: () async {
                                          Navigator.pop(context);
                                          await AppRouter.routeTo(
                                            context,
                                            const AddEditFolderScreen(),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            } else {
                              await AppRouter.routeTo(
                                context,
                                AddBookScreen(
                                  initialType: selectedTabIndex == 2
                                      ? 'audiobook'
                                      : 'ebook',
                                ),
                              );
                            }
                          },
                          child: Container(
                            margin: EdgeInsets.only(right: 12.w),
                            padding: EdgeInsets.all(8.w),
                            decoration: BoxDecoration(
                              color: AppColors.primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.add,
                              color: Colors.black,
                              size: 20.sp,
                            ),
                          ),
                        ),
                      BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, state) {
                          final user = state is Authenticated ? state.user : null;
                          return GestureDetector(
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
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            16.verticalSpace,

            // Custom Tab Widget
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: CustomTabWidget(
                selectedIndex: selectedTabIndex,
                onTabChanged: (index) async {
                  setState(() {
                    selectedTabIndex = index;
                  });
                  if (index == 1) {
                    await _refreshVideoTab();
                  } else if (index == 3) {
                    await _refreshMp3Tab();
                  } else if (index == 4) {
                    await _refreshQuizTab();
                  }
                },
                tabs: ['E-book', 'Videos', 'Audiobook', 'Songs', 'Quiz'],
              ),
            ),
            20.verticalSpace,

            // Tab Content - Use IndexedStack to keep pages alive and prevent rebuilds
            Expanded(
              child: IndexedStack(
                index: selectedTabIndex,
                children: [
                  EbookPage(),
                  LibraryVideosPage(key: _videoPageKey),
                  AudiobookPage(),
                  Mp3Page(key: _mp3PageKey),
                  QuizPage(key: _quizPageKey),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserAvatar(UserModel? user) {
    // If user has a profile image, show it
    if (user?.profileImageUrl != null && user!.profileImageUrl!.isNotEmpty) {
      return Container(
        width: 37.h,
        height: 37.h,
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
        width: 37.h,
        height: 37.h,
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
            _getInitials(user.name),
            style: AppTextStyles.lufgaMedium.copyWith(
              color: Colors.white,
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    // Fallback to default image
    return Container(
      width: 37.h,
      height: 37.h,
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
    return 'U';
  }
}
