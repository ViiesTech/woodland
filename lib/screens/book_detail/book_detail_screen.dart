import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:the_woodlands_series/Components/resource/app_routers.dart';
import 'package:the_woodlands_series/components/resource/size_constants.dart';
import 'package:the_woodlands_series/admin_panel/models/book_model.dart';

import '../../components/resource/app_colors.dart';
import '../../components/resource/app_textstyle.dart';
import '../../bloc/auth/auth_bloc.dart';
import '../../bloc/auth/auth_state.dart';
import '../reading/reading_screen.dart';
import '../reading/listen_screen.dart';
import '../../admin_panel/screens/edit_book_screen.dart';
import '../../components/switch/custom_switch.dart';
import '../../services/book_service.dart';
import '../../components/utils/custom_toast.dart';
import '../../services/bookmark_service.dart';
import '../../services/viewed_books_service.dart';

class BookDetailScreen extends StatefulWidget {
  final BookModel book;

  const BookDetailScreen({super.key, required this.book});

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  late BookModel _book;
  bool _isUpdating = false;
  bool _isBookmarked = false;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _book = widget.book;
    _refreshBookData();
    _loadBookmarkStatus();
    _markBookAsViewed();
  }

  void _markBookAsViewed() {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      ViewedBooksService.markBookAsViewed(
        userId: authState.user.id,
        bookId: _book.id,
      ).then((_) {
        // Refresh book data to get updated view count
        if (mounted) {
          _refreshBookData();
        }
      });
    }
  }

  void _loadBookmarkStatus() {
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      _currentUserId = authState.user.id;
      // Listen to bookmark status changes
      BookmarkService.isBookmarkedStream(
        userId: _currentUserId!,
        bookId: _book.id,
      ).listen((isBookmarked) {
        if (mounted) {
          setState(() {
            _isBookmarked = isBookmarked;
          });
        }
      });
    }
  }

  Future<void> _toggleBookmark() async {
    if (_currentUserId == null) {
      CustomToast.showError(context, 'Please login to bookmark books');
      return;
    }

    try {
      final newStatus = await BookmarkService.toggleBookmark(
        userId: _currentUserId!,
        bookId: _book.id,
        book: _book,
      );

      if (mounted) {
        CustomToast.showSuccess(
          context,
          newStatus ? 'Book added to bookmarks' : 'Book removed from bookmarks',
        );
      }
    } catch (e) {
      if (mounted) {
        CustomToast.showError(context, 'Error updating bookmark: $e');
      }
    }
  }

  Future<void> _refreshBookData() async {
    try {
      final updatedBook = await BookService.getBookById(widget.book.id);
      if (updatedBook != null && mounted) {
        setState(() {
          _book = updatedBook;
        });
      }
    } catch (e) {
      print('Error refreshing book data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: SizeCons.getHeight(context) * 0.9,
              child: Stack(
                children: [
                  // Blurred Background
                  Container(
                    height: 432.h,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.boxClr,
                      image: _book.coverImageUrl.isNotEmpty
                          ? DecorationImage(
                              image: _book.coverImageUrl.startsWith('http')
                                  ? NetworkImage(_book.coverImageUrl)
                                        as ImageProvider
                                  : AssetImage(_book.coverImageUrl),
                              fit: BoxFit.cover,
                              onError: (exception, stackTrace) {
                                // Handle error silently
                              },
                            )
                          : null,
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.w,
                      vertical: 20.h,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () {
                            AppRouter.routeBack(context);
                          },
                          child: Icon(
                            Icons.arrow_back_ios,
                            color: Colors.white,
                            size: 20.sp,
                          ),
                        ),
                        BlocBuilder<AuthBloc, AuthState>(
                          builder: (context, state) {
                            final isAdmin =
                                state is Authenticated &&
                                state.user.role == 'admin';
                            if (isAdmin) {
                              // Show Edit button for admin
                              return GestureDetector(
                                onTap: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          EditBookScreen(book: _book),
                                    ),
                                  );
                                  // Refresh book data when returning from edit screen
                                  if (result == true || mounted) {
                                    await _refreshBookData();
                                  }
                                },
                                child: Icon(
                                  Icons.edit,
                                  color: Colors.white,
                                  size: 20.sp,
                                ),
                              );
                            } else {
                              // Show Bookmark for regular users
                              return GestureDetector(
                                onTap: _toggleBookmark,
                                child: Icon(
                                  _isBookmarked
                                      ? Icons.bookmark
                                      : Icons.bookmark_outline,
                                  color: _isBookmarked
                                      ? AppColors.primaryColor
                                      : Colors.white,
                                  size: 20.sp,
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),

                  // Book Cover and Info
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      height: SizeCons.getHeight(context) * 0.65,
                      decoration: BoxDecoration(
                        color: AppColors.bgClr,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(50.r),
                          topRight: Radius.circular(50.r),
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.only(top: 90.h),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding: EdgeInsets.symmetric(horizontal: 40.w),
                                child: Text(
                                  _book.title,
                                  style: AppTextStyles.lufgaLarge.copyWith(
                                    color: Colors.white,
                                    fontSize: 18.sp,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              8.verticalSpace,
                              // Author
                              Text(
                                _book.author,
                                style: AppTextStyles.regular.copyWith(
                                  color: Colors.grey[400],
                                  fontSize: 14.sp,
                                ),
                              ),
                              20.verticalSpace,
                              // Action Buttons - Show based on book type
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (_book.type == BookType.ebook)
                                    GestureDetector(
                                      onTap: () {
                                        AppRouter.routeTo(
                                          context,
                                          ReadingScreen(book: _book),
                                        );
                                      },
                                      child: _buildActionButton(
                                        icon: Icons.menu_book,
                                        text: 'Read Book',
                                      ),
                                    ),
                                  if (_book.type == BookType.audiobook)
                                    GestureDetector(
                                      onTap: () {
                                        AppRouter.routeTo(
                                          context,
                                          ListenScreen(book: _book),
                                        );
                                      },
                                      child: _buildActionButton(
                                        icon: Icons.headphones,
                                        text: 'Listen Book',
                                      ),
                                    ),
                                ],
                              ),

                              // Content Sections
                              Padding(
                                padding: EdgeInsets.all(20.w),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Duration Section
                                    BlocBuilder<AuthBloc, AuthState>(
                                      builder: (context, state) {
                                        final isAdmin =
                                            state is Authenticated &&
                                            state.user.role == 'admin';
                                        return Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Row(
                                              children: [
                                                Icon(
                                                  Icons.access_time,
                                                  color: AppColors.primaryColor,
                                                  size: 18.sp,
                                                ),
                                                5.horizontalSpace,
                                                Text(
                                                  '${_book.readTime} min',
                                                  style: AppTextStyles.medium
                                                      .copyWith(
                                                        color: AppColors
                                                            .primaryColor,
                                                        fontSize: 14.sp,
                                                      ),
                                                ),
                                              ],
                                            ),
                                            if (isAdmin)
                                              Row(
                                                children: [
                                                  Text(
                                                    'Published: ',
                                                    style: AppTextStyles.medium
                                                        .copyWith(
                                                          color: Colors.white,
                                                          fontSize: 14.sp,
                                                        ),
                                                  ),
                                                  8.horizontalSpace,
                                                  CustomSwitch(
                                                    value: _book.isPublished,
                                                    onChanged: _isUpdating
                                                        ? null
                                                        : (value) {
                                                            _handlePublishToggle(
                                                              value,
                                                              isAdmin,
                                                            );
                                                          },
                                                  ),
                                                ],
                                              ),
                                          ],
                                        );
                                      },
                                    ),
                                    16.verticalSpace,

                                    // About this Book Section
                                    Text(
                                      'About this Book',
                                      style: AppTextStyles.lufgaLarge.copyWith(
                                        color: Colors.white,
                                        fontSize: 16.sp,
                                      ),
                                    ),
                                    8.verticalSpace,
                                    Text(
                                      _book.description,
                                      style: AppTextStyles.regular.copyWith(
                                        color: Colors.grey[300],
                                        fontSize: 14.sp,
                                        height: 1.5,
                                      ),
                                    ),
                                    30.verticalSpace,

                                    // Similar Books Section
                                    Text(
                                      'Similar Books',
                                      style: AppTextStyles.lufgaLarge.copyWith(
                                        color: Colors.white,
                                        fontSize: 18.sp,
                                      ),
                                    ),
                                    16.verticalSpace,
                                    SizedBox(
                                      height: 200.h,
                                      child: ListView.builder(
                                        scrollDirection: Axis.horizontal,
                                        itemCount: 3,
                                        itemBuilder: (context, index) {
                                          final books = [
                                            {
                                              'title': 'Glenn s duquette',
                                              'author': 'Mark mcallister',
                                              'image':
                                                  'assets/tempImg/temp1.png',
                                            },
                                            {
                                              'title': 'ODE TO SIR',
                                              'author': 'Mark mcallister',
                                              'image':
                                                  'assets/tempImg/temp2.png',
                                            },
                                            {
                                              'title': 'Sunflower',
                                              'author': 'Mark mcallister',
                                              'image':
                                                  'assets/tempImg/temp3.png',
                                            },
                                          ];
                                          final book = books[index];
                                          return Container(
                                            width: 140.w,
                                            margin: EdgeInsets.only(
                                              right: 16.w,
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Container(
                                                  height: 120.h,
                                                  decoration: BoxDecoration(
                                                    image: DecorationImage(
                                                      image: AssetImage(
                                                        book['image']!,
                                                      ),
                                                      fit: BoxFit.cover,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8.r,
                                                        ),
                                                  ),
                                                ),
                                                8.verticalSpace,
                                                Text(
                                                  book['title']!,
                                                  style: AppTextStyles.medium
                                                      .copyWith(
                                                        color: Colors.white,
                                                        fontSize: 12.sp,
                                                      ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                4.verticalSpace,
                                                Text(
                                                  book['author']!,
                                                  style: AppTextStyles.regular
                                                      .copyWith(
                                                        color: Colors.grey[400],
                                                        fontSize: 10.sp,
                                                      ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                8.verticalSpace,
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.headphones,
                                                      color: Colors.grey[400],
                                                      size: 10.sp,
                                                    ),
                                                    2.horizontalSpace,
                                                    Text(
                                                      '5m',
                                                      style: AppTextStyles
                                                          .regular
                                                          .copyWith(
                                                            color: Colors
                                                                .grey[400],
                                                            fontSize: 10.sp,
                                                          ),
                                                    ),
                                                    8.horizontalSpace,
                                                    Icon(
                                                      Icons.visibility,
                                                      color: Colors.grey[400],
                                                      size: 10.sp,
                                                    ),
                                                    2.horizontalSpace,
                                                    Text(
                                                      '8m',
                                                      style: AppTextStyles
                                                          .regular
                                                          .copyWith(
                                                            color: Colors
                                                                .grey[400],
                                                            fontSize: 10.sp,
                                                          ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                    20.verticalSpace,
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: EdgeInsets.only(top: 120.h),
                      child: Container(
                        height: 159.h,
                        width: 159.w,
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: _book.coverImageUrl.startsWith('http')
                                ? NetworkImage(_book.coverImageUrl)
                                      as ImageProvider
                                : AssetImage(_book.coverImageUrl),
                            fit: BoxFit.fill,
                          ),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handlePublishToggle(bool newValue, bool isAdmin) {
    if (!isAdmin) return;

    final action = newValue ? 'publish' : 'unpublish';
    final actionCapitalized = newValue ? 'Publish' : 'Unpublish';

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.boxClr,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Text(
            '$actionCapitalized Book',
            style: AppTextStyles.lufgaLarge.copyWith(
              color: Colors.white,
              fontSize: 20.sp,
            ),
          ),
          content: Text(
            'Are you sure you want to $action "${_book.title}"?',
            style: AppTextStyles.lufgaMedium.copyWith(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14.sp,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'No',
                style: TextStyle(color: Colors.grey, fontSize: 14.sp),
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _updatePublishStatus(newValue);
              },
              child: Text(
                'Yes',
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

  Future<void> _updatePublishStatus(bool isPublished) async {
    setState(() {
      _isUpdating = true;
    });

    try {
      final updatedBook = BookModel(
        id: _book.id,
        title: _book.title,
        author: _book.author,
        description: _book.description,
        coverImageUrl: _book.coverImageUrl,
        content: _book.content,
        pdfUrl: _book.pdfUrl,
        audioFileUrl: _book.audioFileUrl,
        chapters: _book.chapters,
        category: _book.category,
        type: _book.type,
        readTime: _book.readTime,
        listenTime: _book.listenTime,
        listenCount: _book.listenCount,
        viewCount: _book.viewCount,
        readCount: _book.readCount,
        listenedUserCount: _book.listenedUserCount,
        isPublished: isPublished,
        hasEverBeenPublished: _book.hasEverBeenPublished,
        createdAt: _book.createdAt,
        updatedAt: DateTime.now(),
      );

      await BookService.updateBook(_book.id, updatedBook);

      setState(() {
        _book = updatedBook;
        _isUpdating = false;
      });

      CustomToast.showSuccess(
        context,
        isPublished
            ? 'Book published successfully!'
            : 'Book unpublished successfully!',
      );
    } catch (e) {
      setState(() {
        _isUpdating = false;
      });
      CustomToast.showError(context, 'Error updating book status: $e');
    }
  }

  Widget _buildActionButton({required IconData icon, required String text}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: AppColors.boxClr,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18.sp),
          8.horizontalSpace,
          Text(
            text,
            style: AppTextStyles.regular.copyWith(
              color: Colors.white,
              fontSize: 14.sp,
            ),
          ),
        ],
      ),
    );
  }
}
