import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:the_woodlands_series/Components/textfield/primary_textfield.dart';
import 'package:the_woodlands_series/components/card/global_card.dart';
import 'package:the_woodlands_series/components/resource/app_assets.dart';
import 'package:the_woodlands_series/components/resource/app_routers.dart';
import 'package:the_woodlands_series/components/resource/app_textstyle.dart';
import 'package:the_woodlands_series/screens/home/widgets/continue_reading_widget.dart';
import 'package:the_woodlands_series/screens/profile/profile_screen.dart';
import 'package:the_woodlands_series/bloc/auth/auth_bloc.dart';
import 'package:the_woodlands_series/bloc/auth/auth_state.dart';
import 'package:the_woodlands_series/models/user_model.dart';
import 'package:the_woodlands_series/services/book_service.dart';
import 'package:the_woodlands_series/services/reading_progress_service.dart';
import 'package:the_woodlands_series/admin_panel/models/book_model.dart';
import 'package:the_woodlands_series/screens/book_detail/book_detail_screen.dart';
import 'package:the_woodlands_series/components/utils/three_dot_loader.dart';
import 'package:the_woodlands_series/components/button/bookmark_icon_button.dart';
import 'package:the_woodlands_series/screens/search/search_screen.dart';

import '../../components/resource/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedCategoryIndex = 0;
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

  final List<Map<String, String>> categories = [
    {'title': 'Trending', 'icon': AppAssets.fireIcon},
    {'title': '5-Minutes Read', 'icon': AppAssets.readIcon},
    {'title': 'Quick Listen', 'icon': AppAssets.headphoneIcon},
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
                                  'Hi, ${user?.name ?? 'Guest'}!',
                                  style: AppTextStyles.lufgaLarge.copyWith(
                                    color: Colors.white,
                                    fontSize: 20.sp,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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
                  16.verticalSpace,
                  PrimaryTextField(
                    hint: 'Title, author or keyword',
                    prefixIcon: Icon(Icons.search, size: 20.sp),
                    height: 55.h,
                    verticalPad: 10.h,
                    readOnly: true,
                    isEnabled: false,
                    onTap: () {
                      AppRouter.routeTo(context, const SearchScreen());
                    },
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

                    // Continue Reading Section - only show heading if there's data
                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, authState) {
                        if (authState is! Authenticated) {
                          return SizedBox.shrink();
                        }

                        return StreamBuilder<Map<String, Map<String, dynamic>>>(
                          stream: ReadingProgressService.getAllProgress(
                            authState.user.id,
                          ),
                          builder: (context, progressSnapshot) {
                            if (!progressSnapshot.hasData ||
                                progressSnapshot.data!.isEmpty) {
                              return SizedBox.shrink();
                            }

                            // Check if there are any incomplete books (not 100% complete)
                            final hasIncompleteBooks = progressSnapshot
                                .data!
                                .entries
                                .any((entry) {
                                  final progress = entry.value;
                                  final currentPage =
                                      progress['currentPage'] as int? ?? 1;
                                  final totalPages =
                                      progress['totalPages'] as int? ?? 1;
                                  if (totalPages <= 0) {
                                    return true; // Keep if total pages is invalid
                                  }
                                  final progressPercent =
                                      (currentPage / totalPages) * 100;
                                  return progressPercent <
                                      100; // Only include books that are not 100% complete
                                });

                            if (!hasIncompleteBooks) {
                              return SizedBox.shrink();
                            }

                            return Padding(
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
                            );
                          },
                        );
                      },
                    ),
                    // SizedBox(
                    //   height: 45.h,
                    //   child: ListView.builder(
                    //     scrollDirection: Axis.horizontal,
                    //     itemCount: categories.length,
                    //     padding: EdgeInsets.symmetric(horizontal: 16.w),
                    //     itemBuilder: (context, index) {
                    //       final isSelected = selectedCategoryIndex == index;
                    //       return GestureDetector(
                    //         onTap: () {
                    //           setState(() {
                    //             selectedCategoryIndex = index;
                    //           });
                    //         },
                    //         child: Container(
                    //           margin: EdgeInsets.only(right: 12.w),
                    //           decoration: BoxDecoration(
                    //             color: isSelected
                    //                 ? AppColors.boxClr
                    //                 : Colors.transparent,
                    //             borderRadius: BorderRadius.circular(10.r),
                    //           ),
                    //           padding: EdgeInsets.symmetric(
                    //             horizontal: 16.w,
                    //             vertical: 10.h,
                    //           ),
                    //           child: Row(
                    //             mainAxisSize: MainAxisSize.min,
                    //             children: [
                    //               SvgPicture.asset(
                    //                 categories[index]['icon']!,
                    //                 height: 18.h,
                    //                 colorFilter: ColorFilter.mode(
                    //                   isSelected ? Colors.white : Colors.white,
                    //                   BlendMode.srcIn,
                    //                 ),
                    //               ),
                    //               5.horizontalSpace,
                    //               Text(
                    //                 categories[index]['title']!,
                    //                 style: AppTextStyles.medium.copyWith(
                    //                   color: isSelected
                    //                       ? Colors.white
                    //                       : Colors.white,
                    //                   fontSize: 14.sp,
                    //                 ),
                    //               ),
                    //             ],
                    //           ),
                    //         ),
                    //       );
                    //     },
                    //   ),
                    // ),
                    // 40.verticalSpace,
                    // Top Trending Section
                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        final isAdmin =
                            state is Authenticated &&
                            state.user.role == 'admin';
                        final userId = state is Authenticated
                            ? state.user.id
                            : null;

                        return Column(
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16.w),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Top Trending',
                                    style: AppTextStyles.lufgaLarge.copyWith(
                                      color: Colors.white,
                                      fontSize: 20.sp,
                                    ),
                                  ),
                                  // Text(
                                  //   'View all',
                                  //   style: AppTextStyles.medium.copyWith(
                                  //     color: AppColors.primaryColor,
                                  //     fontSize: 12.sp,
                                  //   ),
                                  // ),
                                ],
                              ),
                            ),
                            16.verticalSpace,
                            StreamBuilder<List<BookModel>>(
                              stream: BookService.getTopTrendingBooks(
                                adminMode: isAdmin,
                                limit: 10,
                              ),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                        ConnectionState.waiting &&
                                    !snapshot.hasData) {
                                  return SizedBox(
                                    height: 200.h,
                                    child: Center(
                                      child: ThreeDotLoader(
                                        color: AppColors.primaryColor,
                                        size: 12.w,
                                        spacing: 8.w,
                                      ),
                                    ),
                                  );
                                }

                                final books = snapshot.data ?? [];
                                if (books.isEmpty) {
                                  return SizedBox.shrink();
                                }

                                return SizedBox(
                                  height: 220.h,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: books.length,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16.w,
                                    ),
                                    itemBuilder: (context, index) {
                                      final book = books[index];
                                      return Container(
                                        margin: EdgeInsets.only(right: 16.w),
                                        child: Stack(
                                          children: [
                                            GestureDetector(
                                              onTap: () {
                                                AppRouter.routeTo(
                                                  context,
                                                  BookDetailScreen(book: book),
                                                );
                                              },
                                              child: GlobalCard(
                                                title: book.title,
                                                author: book.author,
                                                imageAsset: book.coverImageUrl,
                                                listenTime:
                                                    '${book.listenTime}m',
                                                readTime: '${book.readTime}m',
                                                book: book,
                                              ),
                                            ),
                                            if (userId != null)
                                              Positioned(
                                                top: 4.h,
                                                right: 4.w,
                                                child: BookmarkIconButton(
                                                  userId: userId,
                                                  book: book,
                                                ),
                                              ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          ],
                        );
                      },
                    ),
                    26.verticalSpace,
                    // New Release Section
                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        final isAdmin =
                            state is Authenticated &&
                            state.user.role == 'admin';
                        final userId = state is Authenticated
                            ? state.user.id
                            : null;

                        return Column(
                          children: [
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16.w),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'New Release',
                                    style: AppTextStyles.lufgaLarge.copyWith(
                                      color: Colors.white,
                                      fontSize: 20.sp,
                                    ),
                                  ),
                                  // Text(
                                  //   'View all',
                                  //   style: AppTextStyles.medium.copyWith(
                                  //     color: AppColors.primaryColor,
                                  //     fontSize: 12.sp,
                                  //   ),
                                  // ),
                                ],
                              ),
                            ),
                            16.verticalSpace,
                            StreamBuilder<List<BookModel>>(
                              stream: BookService.getNewReleases(
                                adminMode: isAdmin,
                                limit: 10,
                              ),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                        ConnectionState.waiting &&
                                    !snapshot.hasData) {
                                  return SizedBox(
                                    height: 220.h,
                                    child: Center(
                                      child: ThreeDotLoader(
                                        color: AppColors.primaryColor,
                                        size: 12.w,
                                        spacing: 8.w,
                                      ),
                                    ),
                                  );
                                }

                                final books = snapshot.data ?? [];
                                if (books.isEmpty) {
                                  return SizedBox.shrink();
                                }

                                return SizedBox(
                                  height: 200.h,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: books.length,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16.w,
                                    ),
                                    itemBuilder: (context, index) {
                                      final book = books[index];
                                      return Container(
                                        margin: EdgeInsets.only(right: 16.w),
                                        child: Stack(
                                          children: [
                                            GestureDetector(
                                              onTap: () {
                                                AppRouter.routeTo(
                                                  context,
                                                  BookDetailScreen(book: book),
                                                );
                                              },
                                              child: GlobalCard(
                                                title: book.title,
                                                author: book.author,
                                                imageAsset: book.coverImageUrl,
                                                listenTime:
                                                    '${book.listenTime}m',
                                                readTime: '${book.readTime}m',
                                                book: book,
                                              ),
                                            ),
                                            if (userId != null)
                                              Positioned(
                                                top: 4.h,
                                                right: 4.w,
                                                child: BookmarkIconButton(
                                                  userId: userId,
                                                  book: book,
                                                ),
                                              ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                            ),
                          ],
                        );
                      },
                    ),
                    26.verticalSpace,
                    // Coming Soon Section
                    BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        final isAdmin =
                            state is Authenticated &&
                            state.user.role == 'admin';

                        return StreamBuilder<List<BookModel>>(
                          stream: BookService.getComingSoonBooks(
                            adminMode: isAdmin,
                            limit: 10,
                          ),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                    ConnectionState.waiting &&
                                !snapshot.hasData) {
                              return SizedBox(
                                height: 200.h,
                                child: Center(
                                  child: ThreeDotLoader(
                                    color: AppColors.primaryColor,
                                    size: 12.w,
                                    spacing: 8.w,
                                  ),
                                ),
                              );
                            }

                            final books = snapshot.data ?? [];
                            if (books.isEmpty) {
                              return SizedBox.shrink();
                            }

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16.w,
                                  ),
                                  child: Text(
                                    'Coming Soon',
                                    style: AppTextStyles.lufgaLarge.copyWith(
                                      color: Colors.white,
                                      fontSize: 20.sp,
                                    ),
                                  ),
                                ),
                                16.verticalSpace,
                                SizedBox(
                                  height: 200.h,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: books.length,
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 16.w,
                                    ),
                                    itemBuilder: (context, index) {
                                      final book = books[index];
                                      return Container(
                                        margin: EdgeInsets.only(right: 16.w),
                                        child: GlobalCard(
                                          title: book.title,
                                          author: book.author,
                                          imageAsset: book.coverImageUrl,
                                          listenTime: '${book.listenTime}m',
                                          readTime: '${book.readTime}m',
                                          book: book,
                                          blur: true, // Blur for coming soon
                                          hideStatistics:
                                              true, // Hide view/read counts
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            );
                          },
                        );
                      },
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
