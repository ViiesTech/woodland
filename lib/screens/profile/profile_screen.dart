import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:the_woodlands_series/components/button/primary_button.dart';
import 'package:the_woodlands_series/components/resource/app_colors.dart';
import 'package:the_woodlands_series/components/resource/app_routers.dart';
import 'package:the_woodlands_series/components/resource/app_textstyle.dart';
import 'package:the_woodlands_series/components/card/global_card.dart';
import 'package:the_woodlands_series/components/utils/custom_toast.dart';
import 'package:the_woodlands_series/screens/login_screen/login_screen.dart';
import 'package:the_woodlands_series/bloc/auth/auth_bloc.dart';
import 'package:the_woodlands_series/bloc/auth/auth_event.dart';
import 'package:the_woodlands_series/bloc/auth/auth_state.dart';
import 'package:the_woodlands_series/models/user_model.dart';
import 'package:the_woodlands_series/screens/profile/edit_profile_screen.dart';
import 'package:the_woodlands_series/screens/bookmarks/bookmarks_screen.dart';
import 'package:the_woodlands_series/services/viewed_books_service.dart';
import 'package:the_woodlands_series/services/global_audio_service.dart';
import 'package:the_woodlands_series/services/book_service.dart';
import 'package:the_woodlands_series/services/listening_progress_service.dart';
import 'package:the_woodlands_series/admin_panel/models/book_model.dart';
import 'package:the_woodlands_series/screens/reading/listen_screen.dart';
import 'package:the_woodlands_series/screens/book_detail/book_detail_screen.dart';
import 'package:the_woodlands_series/screens/web_view/web_view_screen.dart';
import 'package:the_woodlands_series/screens/about_us/about_us_screen.dart';
import 'package:the_woodlands_series/screens/contact_us/contact_us_screen.dart';
import 'package:the_woodlands_series/screens/contact_us/admin_contact_list_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreen extends StatefulWidget {
  final String title;
  final String image;
  const ProfileScreen({super.key, required this.title, required this.image});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? currentUser;
  String? _currentUserId;
  bool _isAdmin = false;
  Map<String, Map<String, dynamic>> _viewedBooksProgress = {};
  List<BookModel> _allViewedBooks = []; // All viewed books (both types)
  BookModel? _latestListeningBook; // Latest book with listening progress
  Map<String, dynamic>? _latestListeningProgress; // Latest listening progress

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
        _currentUserId = authState.user.id;
        _isAdmin = authState.user.role == 'admin';
      });
      _loadViewedBooks();
      _loadLatestListeningProgress(); // Load saved listening progress
    }
  }

  void _loadViewedBooks() {
    if (_currentUserId == null) return;

    ViewedBooksService.getAllViewedBooks(_currentUserId!).listen((viewed) {
      if (mounted) {
        setState(() {
          _viewedBooksProgress = viewed;
        });
        _loadAllViewedBooks();
      }
    });
  }

  Future<void> _loadAllViewedBooks() async {
    if (_viewedBooksProgress.isEmpty || _currentUserId == null) {
      if (mounted) {
        setState(() {
          _allViewedBooks = [];
        });
      }
      return;
    }

    try {
      // Already sorted by lastViewed in the stream query
      List<BookModel> books = [];
      for (var entry in _viewedBooksProgress.entries.take(6)) {
        try {
          final book = await BookService.getBookById(entry.key);
          // Only show published books, or skip if book not found
          if (book != null && book.isPublished) {
            books.add(book);
          }
        } catch (e) {
          print('Error loading viewed book ${entry.key}: $e');
          // Skip books that are not found or have errors
        }
      }

      if (mounted) {
        setState(() {
          _allViewedBooks = books;
        });
      }
    } catch (e) {
      print('Error loading all viewed books: $e');
    }
  }

  void _loadLatestListeningProgress() {
    if (_currentUserId == null) return;

    // Listen to all listening progress for this user
    ListeningProgressService.getAllProgress(_currentUserId!).listen((
      progressMap,
    ) {
      if (progressMap.isEmpty || _currentUserId == null) {
        if (mounted) {
          setState(() {
            _latestListeningBook = null;
            _latestListeningProgress = null;
          });
        }
        return;
      }

      // Get the most recently updated progress
      MapEntry<String, Map<String, dynamic>>? latestEntry;
      Timestamp? latestTime;

      for (var entry in progressMap.entries) {
        final lastUpdated = entry.value['lastUpdated'] as Timestamp?;
        if (lastUpdated != null) {
          if (latestTime == null || lastUpdated.compareTo(latestTime) > 0) {
            latestTime = lastUpdated;
            latestEntry = entry;
          }
        }
      }

      if (latestEntry != null && mounted) {
        // Store in local variable for null safety
        final entry = latestEntry;
        // Load book details
        BookService.getBookById(entry.key)
            .then((book) {
              if (book != null && mounted) {
                setState(() {
                  _latestListeningBook = book;
                  _latestListeningProgress = entry.value;
                });
              }
            })
            .catchError((e) {
              print('Error loading latest listening book: $e');
            });
      }
    });
  }

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
            'Profile',
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

                      // Bookmarks Section
                      GestureDetector(
                        onTap: () {
                          AppRouter.routeTo(context, const BookmarksScreen());
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 16.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.boxClr,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.bookmark,
                                color: AppColors.primaryColor,
                                size: 24.sp,
                              ),
                              16.horizontalSpace,
                              Text(
                                'My Bookmarks',
                                style: AppTextStyles.lufgaLarge.copyWith(
                                  color: Colors.white,
                                  fontSize: 16.sp,
                                ),
                              ),
                              Spacer(),
                              Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.white.withOpacity(0.5),
                                size: 16.sp,
                              ),
                            ],
                          ),
                        ),
                      ),
                      16.verticalSpace,

                      // About Us Section
                      GestureDetector(
                        onTap: () {
                          AppRouter.routeTo(context, const AboutUsScreen());
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 16.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.boxClr,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: AppColors.primaryColor,
                                size: 24.sp,
                              ),
                              16.horizontalSpace,
                              Text(
                                'About Us',
                                style: AppTextStyles.lufgaLarge.copyWith(
                                  color: Colors.white,
                                  fontSize: 16.sp,
                                ),
                              ),
                              Spacer(),
                              Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.white.withOpacity(0.5),
                                size: 16.sp,
                              ),
                            ],
                          ),
                        ),
                      ),
                      16.verticalSpace,

                      // Articles Section
                      GestureDetector(
                        onTap: _showArticlesBottomSheet,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 16.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.boxClr,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.article,
                                color: AppColors.primaryColor,
                                size: 24.sp,
                              ),
                              16.horizontalSpace,
                              Text(
                                'Articles',
                                style: AppTextStyles.lufgaLarge.copyWith(
                                  color: Colors.white,
                                  fontSize: 16.sp,
                                ),
                              ),
                              Spacer(),
                              Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.white.withOpacity(0.5),
                                size: 16.sp,
                              ),
                            ],
                          ),
                        ),
                      ),
                      16.verticalSpace,

                      // Contact Us / View Contacts Section (conditional based on admin)
                      GestureDetector(
                        onTap: () {
                          if (_isAdmin) {
                            AppRouter.routeTo(
                              context,
                              const AdminContactListScreen(),
                            );
                          } else {
                            AppRouter.routeTo(context, const ContactUsScreen());
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 16.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.boxClr,
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                _isAdmin ? Icons.message : Icons.contact_mail,
                                color: AppColors.primaryColor,
                                size: 24.sp,
                              ),
                              16.horizontalSpace,
                              Text(
                                _isAdmin
                                    ? 'View Contact Messages'
                                    : 'Contact Us',
                                style: AppTextStyles.lufgaLarge.copyWith(
                                  color: Colors.white,
                                  fontSize: 16.sp,
                                ),
                              ),
                              Spacer(),
                              Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.white.withOpacity(0.5),
                                size: 16.sp,
                              ),
                            ],
                          ),
                        ),
                      ),
                      16.verticalSpace,

                      // Currently Playing (if any) - Show even if paused/stopped or app restarted
                      ListenableBuilder(
                        listenable: GlobalAudioService(),
                        builder: (context, _) {
                          final audioService = GlobalAudioService();
                          // Show if there's a current book in service, OR if there's saved progress
                          final bookToShow =
                              audioService.currentBook ?? _latestListeningBook;

                          if (bookToShow != null) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Currently Playing',
                                  style: AppTextStyles.lufgaLarge.copyWith(
                                    color: Colors.white,
                                    fontSize: 18.sp,
                                  ),
                                ),
                                16.verticalSpace,
                                audioService.currentBook != null
                                    ? _buildCurrentlyPlayingWidget(audioService)
                                    : _buildContinueListeningWidget(bookToShow),
                                26.verticalSpace,
                              ],
                            );
                          }
                          return SizedBox.shrink();
                        },
                      ),

                      // Viewed Books (all types - from book detail visits)
                      if (_viewedBooksProgress.isNotEmpty) ...[
                        Text(
                          'Viewed Books',
                          style: AppTextStyles.lufgaLarge.copyWith(
                            color: Colors.white,
                            fontSize: 18.sp,
                          ),
                        ),
                        16.verticalSpace,
                        if (_allViewedBooks.isEmpty)
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 20.h),
                            child: Center(
                              child: Text(
                                'No viewed books yet',
                                style: AppTextStyles.regular.copyWith(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 14.sp,
                                ),
                              ),
                            ),
                          )
                        else
                          GridView.builder(
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.zero,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 16.w,
                                  mainAxisSpacing: 16.h,
                                  childAspectRatio: 0.52,
                                ),
                            itemCount: _allViewedBooks.length,
                            itemBuilder: (context, index) {
                              final book = _allViewedBooks[index];
                              return GestureDetector(
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
                                  listenTime: '${book.listenTime}m',
                                  readTime: '${book.readTime}m',
                                  book: book,
                                ),
                              );
                            },
                          ),
                        26.verticalSpace,
                      ],

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

  Widget _buildCurrentlyPlayingWidget(GlobalAudioService audioService) {
    final book = audioService.currentBook!;
    final position = audioService.position;
    final duration = audioService.duration;
    final progress = duration.inMilliseconds > 0
        ? position.inMilliseconds / duration.inMilliseconds
        : 0.0;
    final chapters = book.chapters ?? [];
    final currentChapter = audioService.currentChapterIndex < chapters.length
        ? chapters[audioService.currentChapterIndex]
        : null;

    return GestureDetector(
      onTap: () {
        AppRouter.routeTo(context, ListenScreen(book: book));
      },
      child: Container(
        height: 114.h,
        decoration: BoxDecoration(
          color: AppColors.boxClr,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(10.r),
          child: Row(
            children: [
              Container(
                width: 105.w,
                height: 105.h,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: book.coverImageUrl.startsWith('http')
                        ? NetworkImage(book.coverImageUrl) as ImageProvider
                        : AssetImage(book.coverImageUrl),
                    fit: BoxFit.cover,
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentChapter?['chapterName'] ??
                                      'Chapter ${audioService.currentChapterIndex + 1}',
                                  style: AppTextStyles.medium.copyWith(
                                    color: AppColors.primaryColor,
                                    fontSize: 12.sp,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  book.title,
                                  style: AppTextStyles.lufgaLarge.copyWith(
                                    color: AppColors.whiteColor,
                                    fontSize: 16.sp,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  book.author,
                                  style: AppTextStyles.medium.copyWith(
                                    color: AppColors.whiteColor.withValues(
                                      alpha: 0.5,
                                    ),
                                    fontSize: 12.sp,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              audioService.playPause();
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xff1B252D),
                              ),
                              padding: EdgeInsets.all(8.r),
                              child: Icon(
                                audioService.isPlaying
                                    ? Icons.pause
                                    : Icons.play_arrow,
                                color: AppColors.primaryColor,
                                size: 24.sp,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '${_formatDuration(position)}/',
                                  style: AppTextStyles.medium.copyWith(
                                    color: AppColors.whiteColor,
                                    fontSize: 12.sp,
                                  ),
                                ),
                                TextSpan(
                                  text: ' ${_formatDuration(duration)}',
                                  style: AppTextStyles.medium.copyWith(
                                    color: AppColors.whiteColor.withValues(
                                      alpha: 0.5,
                                    ),
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          4.verticalSpace,
                          Stack(
                            children: [
                              Container(
                                width: double.infinity,
                                height: 4.h,
                                decoration: BoxDecoration(
                                  color: Color(0xff677078),
                                  borderRadius: BorderRadius.circular(50.r),
                                ),
                              ),
                              FractionallySizedBox(
                                widthFactor: progress.clamp(0.0, 1.0),
                                child: Container(
                                  height: 4.h,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryColor,
                                    borderRadius: BorderRadius.circular(50.r),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildContinueListeningWidget(BookModel book) {
    final progress = _latestListeningProgress;
    final chapters = book.chapters ?? [];
    final chapterIndex = progress?['chapterIndex'] as int? ?? 0;

    final currentChapter = chapterIndex < chapters.length
        ? chapters[chapterIndex]
        : null;

    return GestureDetector(
      onTap: () {
        AppRouter.routeTo(context, ListenScreen(book: book));
      },
      child: Container(
        height: 114.h,
        decoration: BoxDecoration(
          color: AppColors.boxClr,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(10.r),
          child: Row(
            children: [
              Container(
                width: 105.w,
                height: 105.h,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: book.coverImageUrl.startsWith('http')
                        ? NetworkImage(book.coverImageUrl) as ImageProvider
                        : AssetImage(book.coverImageUrl),
                    fit: BoxFit.cover,
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  currentChapter?['chapterName'] ??
                                      'Chapter ${chapterIndex + 1}',
                                  style: AppTextStyles.medium.copyWith(
                                    color: AppColors.primaryColor,
                                    fontSize: 12.sp,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  book.title,
                                  style: AppTextStyles.lufgaLarge.copyWith(
                                    color: AppColors.whiteColor,
                                    fontSize: 16.sp,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  book.author,
                                  style: AppTextStyles.medium.copyWith(
                                    color: AppColors.whiteColor.withValues(
                                      alpha: 0.5,
                                    ),
                                    fontSize: 12.sp,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              AppRouter.routeTo(
                                context,
                                ListenScreen(book: book),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xff1B252D),
                              ),
                              padding: EdgeInsets.all(8.r),
                              child: Icon(
                                Icons.play_arrow,
                                color: AppColors.primaryColor,
                                size: 24.sp,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tap to continue',
                            style: AppTextStyles.medium.copyWith(
                              color: AppColors.whiteColor.withValues(
                                alpha: 0.7,
                              ),
                              fontSize: 11.sp,
                            ),
                          ),
                        ],
                      ),
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

  void _showArticlesBottomSheet() {
    final articles = [
      {
        'name': 'Tumblr',
        'url':
            'https://www.tumblr.com/boundlessbookpublishers/793058895733129216/embark-on-a-thrilling-journey-of-survival-and?source=share',
      },
      {
        'name': 'Differ Blog',
        'url':
            'https://differ.blog/p/embark-on-a-thrilling-journey-of-survival-and-unity-in-nature-e2dfa3',
      },
      {
        'name': 'Boundless Substack',
        'url':
            'https://boundlesspublishers.substack.com/p/embark-on-a-thrilling-journey-of',
      },
      {
        'name': 'Blogspot',
        'url':
            'https://boundlessauthors.blogspot.com/2025/08/embark-on-thrilling-journey-of-survival.html',
      },
      {
        'name': 'Medium',
        'url':
            'https://medium.com/@harris.harrison/embark-on-a-thrilling-journey-of-survival-and-unity-in-nature-dg-videttos-unveils-the-impervious-f057c28cda09',
      },
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: AppColors.boxClr,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Padding(
                    padding: EdgeInsets.only(top: 12.h),
                    child: Container(
                      width: 40.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                  ),
                  // Title
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.w,
                      vertical: 20.h,
                    ),
                    child: Text(
                      'Articles',
                      style: AppTextStyles.lufgaLarge.copyWith(
                        color: Colors.white,
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Scrollable article list
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      itemCount: articles.length,
                      itemBuilder: (context, index) {
                        final article = articles[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            AppRouter.routeTo(
                              context,
                              WebViewScreen(
                                url: article['url']!,
                                title: article['name']!,
                              ),
                            );
                          },
                          child: Container(
                            margin: EdgeInsets.only(bottom: 12.h),
                            padding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 16.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.bgClr,
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    article['name']!,
                                    style: AppTextStyles.lufgaLarge.copyWith(
                                      color: Colors.white,
                                      fontSize: 16.sp,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.white.withOpacity(0.5),
                                  size: 16.sp,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  // Bottom padding
                  SizedBox(height: 20.h),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
