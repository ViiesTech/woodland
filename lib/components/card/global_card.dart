import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:the_woodlands_series/components/resource/app_assets.dart';
import 'package:the_woodlands_series/components/resource/app_textstyle.dart';
import 'package:the_woodlands_series/components/resource/app_colors.dart';
import 'package:the_woodlands_series/admin_panel/models/book_model.dart';
import 'package:the_woodlands_series/bloc/auth/auth_bloc.dart';
import 'package:the_woodlands_series/bloc/auth/auth_state.dart';
import 'package:the_woodlands_series/components/switch/custom_switch.dart';
import 'package:the_woodlands_series/services/book_service.dart';
import 'package:the_woodlands_series/components/utils/custom_toast.dart';

class GlobalCard extends StatefulWidget {
  final String title;
  final String author;
  final String imageAsset;
  final String listenTime;
  final String readTime;
  final bool blur;
  final BookModel? book; // Optional book model for admin features
  final bool hideStatistics; // Hide view/read statistics

  const GlobalCard({
    super.key,
    required this.title,
    required this.author,
    required this.imageAsset,
    required this.listenTime,
    required this.readTime,
    this.blur = false,
    this.book,
    this.hideStatistics = false,
  });

  @override
  State<GlobalCard> createState() => _GlobalCardState();
}

class _GlobalCardState extends State<GlobalCard> {
  bool _isUpdating = false;
  late bool _isPublished;

  @override
  void initState() {
    super.initState();
    _isPublished = widget.book?.isPublished ?? false;
  }

  @override
  void didUpdateWidget(GlobalCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.book?.isPublished != oldWidget.book?.isPublished) {
      _isPublished = widget.book?.isPublished ?? false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine which time to show based on book type
    final showListenTime = widget.book?.type == BookType.audiobook;
    final showReadTime = widget.book?.type == BookType.ebook;

    return SizedBox(
      width: 122.w,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Container(
                height: 119.h,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Stack(
                  children: [
                    // Background Image - supports both asset and network
                    Container(
                      height: 119.h,
                      width: double.infinity,

                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color.fromARGB(31, 141, 141, 141),
                        ),
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      child: widget.imageAsset.startsWith('http')
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(14.r),
                              child: Image.network(
                                widget.imageAsset,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[800],
                                    child: Icon(
                                      Icons.image_not_supported,
                                      color: Colors.grey[600],
                                      size: 40.sp,
                                    ),
                                  );
                                },
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        color: Colors.grey[800],
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            value:
                                                loadingProgress
                                                        .expectedTotalBytes !=
                                                    null
                                                ? loadingProgress
                                                          .cumulativeBytesLoaded /
                                                      loadingProgress
                                                          .expectedTotalBytes!
                                                : null,
                                            color: Colors.orange,
                                          ),
                                        ),
                                      );
                                    },
                              ),
                            )
                          : null,
                    ),
                    // Blur Overlay
                    if (widget.blur)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14.r),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            height: 119.h,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Color(0xFFFF8C42).withOpacity(0.3), // Orange
                                  Color(
                                    0xFF8B4513,
                                  ).withOpacity(0.5), // Dark Brown
                                ],
                                stops: [0.0, 1.0],
                              ),
                              borderRadius: BorderRadius.circular(14.r),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              8.verticalSpace,
              Text(
                widget.title,
                style: AppTextStyles.medium.copyWith(
                  color: Colors.white,
                  fontSize: 10.sp,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              4.verticalSpace,
              Text(
                widget.author,
                style: AppTextStyles.regular.copyWith(
                  color: Colors.white,
                  fontSize: 10.sp,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              8.verticalSpace,
              // Show statistics based on book type
              if (widget.book != null && !widget.hideStatistics) ...[
                // For ebooks: show view count and read count
                if (widget.book!.type == BookType.ebook) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.visibility,
                        size: 10.sp,
                        color: Colors.grey[400],
                      ),
                      2.horizontalSpace,
                      Text(
                        '${widget.book!.viewCount} views',
                        style: AppTextStyles.regular.copyWith(
                          color: Colors.grey[400],
                          fontSize: 8.sp,
                        ),
                      ),
                      8.horizontalSpace,
                      Icon(
                        Icons.menu_book,
                        size: 10.sp,
                        color: Colors.grey[400],
                      ),
                      2.horizontalSpace,
                      Text(
                        '${widget.book!.readCount} read',
                        style: AppTextStyles.regular.copyWith(
                          color: Colors.grey[400],
                          fontSize: 8.sp,
                        ),
                      ),
                    ],
                  ),
                ],
                // For audiobooks: show view count and listen count
                if (widget.book!.type == BookType.audiobook) ...[
                  Row(
                    children: [
                      Icon(
                        Icons.visibility,
                        size: 10.sp,
                        color: Colors.grey[400],
                      ),
                      2.horizontalSpace,
                      Text(
                        '${widget.book!.viewCount}',
                        style: AppTextStyles.regular.copyWith(
                          color: Colors.grey[400],
                          fontSize: 8.sp,
                        ),
                      ),
                      8.horizontalSpace,
                      Icon(
                        Icons.headphones,
                        size: 10.sp,
                        color: Colors.grey[400],
                      ),
                      2.horizontalSpace,
                      Text(
                        '${widget.book!.listenCount}',
                        style: AppTextStyles.regular.copyWith(
                          color: Colors.grey[400],
                          fontSize: 8.sp,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ],
          ),
          // Show only relevant time based on book type, or show both if no book model

          // Admin publish/unpublish switch
          if (widget.book != null)
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                final isAdmin =
                    state is Authenticated && state.user.role == 'admin';
                if (!isAdmin) return const SizedBox.shrink();

                return Column(
                  children: [
                    if (!isAdmin)
                      Row(
                        children: [
                          if (showListenTime || widget.book == null) ...[
                            SvgPicture.asset(
                              AppAssets.headphoneIcon,
                              height: 12.h,
                              width: 12.w,
                            ),
                            2.horizontalSpace,
                            Text(
                              widget.listenTime,
                              style: AppTextStyles.regular.copyWith(
                                color: Colors.white,
                                fontSize: 10.sp,
                              ),
                            ),
                            if (showReadTime || widget.book == null)
                              8.horizontalSpace,
                          ],
                          if (showReadTime || widget.book == null) ...[
                            SvgPicture.asset(
                              AppAssets.connectIcon,
                              height: 12.h,
                              width: 12.w,
                            ),
                            2.horizontalSpace,
                            Text(
                              widget.readTime,
                              style: AppTextStyles.regular.copyWith(
                                color: Colors.white,
                                fontSize: 10.sp,
                              ),
                            ),
                          ],
                        ],
                      ),
                    Row(
                      children: [
                        Text(
                          'Published: ',
                          style: AppTextStyles.regular.copyWith(
                            color: Colors.white,
                            fontSize: 8.sp,
                          ),
                        ),
                        4.horizontalSpace,
                        CustomSwitch(
                          value: _isPublished,
                          onChanged: _isUpdating
                              ? null
                              : (value) {
                                  _handlePublishToggle(value, isAdmin);
                                },
                          width: 35.w,
                          height: 15.h,
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  void _handlePublishToggle(bool newValue, bool isAdmin) {
    if (!isAdmin || widget.book == null) return;

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
              fontSize: 18.sp,
            ),
          ),
          content: Text(
            'Are you sure you want to $action "${widget.book!.title}"?',
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
    if (widget.book == null) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      final updatedBook = BookModel(
        id: widget.book!.id,
        title: widget.book!.title,
        author: widget.book!.author,
        description: widget.book!.description,
        coverImageUrl: widget.book!.coverImageUrl,
        content: widget.book!.content,
        pdfUrl: widget.book!.pdfUrl,
        audioFileUrl: widget.book!.audioFileUrl,
        chapters: widget.book!.chapters,
        category: widget.book!.category,
        type: widget.book!.type,
        readTime: widget.book!.readTime,
        listenTime: widget.book!.listenTime,
        listenCount: widget.book!.listenCount,
        viewCount: widget.book!.viewCount,
        readCount: widget.book!.readCount,
        listenedUserCount: widget.book!.listenedUserCount,
        isPublished: isPublished,
        hasEverBeenPublished: widget.book!.hasEverBeenPublished,
        createdAt: widget.book!.createdAt,
        updatedAt: DateTime.now(),
      );

      await BookService.updateBook(widget.book!.id, updatedBook);

      setState(() {
        _isPublished = isPublished;
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
}
