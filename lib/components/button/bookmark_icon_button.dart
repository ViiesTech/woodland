import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:the_woodlands_series/components/resource/app_colors.dart';
import 'package:the_woodlands_series/services/bookmark_service.dart';
import 'package:the_woodlands_series/admin_panel/models/book_model.dart';
import 'package:the_woodlands_series/components/utils/custom_toast.dart';

/// A bookmark icon button that manages its own state for instant UI updates
/// without causing parent widget rebuilds
class BookmarkIconButton extends StatefulWidget {
  final String userId;
  final BookModel book;

  const BookmarkIconButton({
    super.key,
    required this.userId,
    required this.book,
  });

  @override
  State<BookmarkIconButton> createState() => _BookmarkIconButtonState();
}

class _BookmarkIconButtonState extends State<BookmarkIconButton> {
  bool _isBookmarked = false;
  StreamSubscription<bool>? _bookmarkSubscription;

  @override
  void initState() {
    super.initState();
    _listenToBookmarkStatus();
  }

  void _listenToBookmarkStatus() {
    // Listen to bookmark status stream in background
    _bookmarkSubscription = BookmarkService.isBookmarkedStream(
      userId: widget.userId,
      bookId: widget.book.id,
    ).listen((isBookmarked) {
      if (mounted && _isBookmarked != isBookmarked) {
        setState(() {
          _isBookmarked = isBookmarked;
        });
      }
    });
  }

  Future<void> _toggleBookmark() async {
    // Optimistic update - instantly change local state
    final wasBookmarked = _isBookmarked;
    setState(() {
      _isBookmarked = !_isBookmarked;
    });

    try {
      // Update backend - stream will sync in background
      final newStatus = await BookmarkService.toggleBookmark(
        userId: widget.userId,
        bookId: widget.book.id,
        book: widget.book,
      );

      if (mounted) {
        CustomToast.showSuccess(
          context,
          newStatus ? 'Book added to bookmarks' : 'Book removed from bookmarks',
        );
      }
    } catch (e) {
      // Revert on error
      if (mounted) {
        setState(() {
          _isBookmarked = wasBookmarked;
        });
        CustomToast.showError(context, 'Error updating bookmark: $e');
      }
    }
  }

  @override
  void dispose() {
    _bookmarkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _toggleBookmark,
      child: Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          shape: BoxShape.circle,
        ),
        child: Icon(
          _isBookmarked ? Icons.bookmark : Icons.bookmark_outline,
          color: _isBookmarked ? AppColors.primaryColor : Colors.white,
          size: 16.sp,
        ),
      ),
    );
  }
}

