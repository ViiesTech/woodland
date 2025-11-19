import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:the_woodlands_series/components/button/primary_button.dart';
import 'package:the_woodlands_series/components/resource/app_colors.dart';
import 'package:the_woodlands_series/components/resource/app_textstyle.dart';
import 'package:the_woodlands_series/components/resource/app_routers.dart';
import 'package:the_woodlands_series/services/reading_progress_service.dart';
import 'package:the_woodlands_series/services/book_service.dart';
import 'package:the_woodlands_series/admin_panel/models/book_model.dart';
import 'package:the_woodlands_series/screens/reading/reading_screen.dart';
import 'package:the_woodlands_series/bloc/auth/auth_bloc.dart';
import 'package:the_woodlands_series/bloc/auth/auth_state.dart';

class ContinueReadingWidget extends StatefulWidget {
  const ContinueReadingWidget({super.key});

  @override
  State<ContinueReadingWidget> createState() => _ContinueReadingWidgetState();
}

class _ContinueReadingWidgetState extends State<ContinueReadingWidget> {
  String? _getLatestBookId(Map<String, Map<String, dynamic>> progressData) {
    if (progressData.isEmpty) return null;

    // Filter out completed books (100% progress)
    final incompleteBooks = progressData.entries.where((entry) {
      final progress = entry.value;
      final currentPage = progress['currentPage'] as int? ?? 1;
      final totalPages = progress['totalPages'] as int? ?? 1;
      if (totalPages <= 0) return true; // Keep if total pages is invalid
      final progressPercent = (currentPage / totalPages) * 100;
      return progressPercent <
          100; // Only include books that are not 100% complete
    }).toList();

    if (incompleteBooks.isEmpty) return null;

    // Sort by last updated time (most recent first)
    incompleteBooks.sort((a, b) {
      final aTime = a.value['lastUpdated'];
      final bTime = b.value['lastUpdated'];
      if (aTime == null && bTime == null) return 0;
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      return (bTime as Comparable).compareTo(aTime);
    });

    return incompleteBooks.first.key;
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    if (authState is! Authenticated) {
      return SizedBox.shrink();
    }

    final userId = authState.user.id;

    return StreamBuilder<Map<String, Map<String, dynamic>>>(
      stream: ReadingProgressService.getAllProgress(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return SizedBox.shrink();
        }

        final latestBookId = _getLatestBookId(snapshot.data!);

        if (latestBookId == null) {
          return SizedBox.shrink();
        }

        // Get the latest progress for current book
        final latestProgress = snapshot.data![latestBookId];
        if (latestProgress == null) {
          return SizedBox.shrink();
        }

        // Use a separate widget that only rebuilds when bookId changes (via ValueKey)
        return _BookDisplayWidget(
          key: ValueKey(latestBookId),
          bookId: latestBookId,
          progress: latestProgress,
        );
      },
    );
  }
}

class _BookDisplayWidget extends StatefulWidget {
  final String bookId;
  final Map<String, dynamic> progress;

  const _BookDisplayWidget({
    required super.key,
    required this.bookId,
    required this.progress,
  });

  @override
  State<_BookDisplayWidget> createState() => _BookDisplayWidgetState();
}

class _BookDisplayWidgetState extends State<_BookDisplayWidget> {
  Future<BookModel?>? _bookFuture;
  BookModel? _cachedBook;

  @override
  void initState() {
    super.initState();
    _bookFuture = BookService.getBookById(widget.bookId);
  }

  @override
  void didUpdateWidget(_BookDisplayWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only reload if book ID changed
    if (oldWidget.bookId != widget.bookId) {
      _cachedBook = null;
      _bookFuture = BookService.getBookById(widget.bookId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<BookModel?>(
      future: _bookFuture,
      builder: (context, bookSnapshot) {
        if (bookSnapshot.hasData && bookSnapshot.data != null) {
          _cachedBook = bookSnapshot.data;
        }

        final book = _cachedBook;

        if (book == null) {
          return SizedBox.shrink();
        }

        final currentPage = widget.progress['currentPage'] as int? ?? 1;
        final totalPages = widget.progress['totalPages'] as int? ?? 1;
        final progressPercent = totalPages > 0
            ? ((currentPage / totalPages) * 100).round()
            : 0;

        return GestureDetector(
          onTap: () {
            AppRouter.routeTo(context, ReadingScreen(book: book));
          },
          child: SizedBox(
            height: 146.h,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 128.w,
                  height: 146.h,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: book.coverImageUrl.startsWith('http')
                          ? NetworkImage(book.coverImageUrl) as ImageProvider
                          : AssetImage(book.coverImageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 10.h),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              book.title,
                              style: AppTextStyles.lufgaMedium.copyWith(
                                color: Colors.white,
                                fontSize: 15.sp,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            5.verticalSpace,
                            Text(
                              book.author,
                              style: AppTextStyles.lufgaMedium.copyWith(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 12.sp,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 26.w,
                                  height: 26.h,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.primaryColor,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                5.horizontalSpace,
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$currentPage/$totalPages pages',
                                      style: AppTextStyles.lufgaMedium.copyWith(
                                        color: Colors.white,
                                        fontSize: 10.sp,
                                      ),
                                    ),
                                    Text(
                                      '$progressPercent%',
                                      style: AppTextStyles.lufgaMedium.copyWith(
                                        color: AppColors.primaryColor,
                                        fontSize: 10.sp,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            PrimaryButton(
                              title: 'Continue',
                              verPadding: 5.h,
                              fontSize: 10.sp,
                              onTap: () {
                                AppRouter.routeTo(
                                  context,
                                  ReadingScreen(book: book),
                                );
                              },
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
        );
      },
    );
  }
}
