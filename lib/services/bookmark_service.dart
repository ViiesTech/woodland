import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:the_woodlands_series/admin_panel/models/book_model.dart';

class BookmarkService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Add a book to user's bookmarks
  static Future<void> addBookmark({
    required String userId,
    required String bookId,
    required BookModel book,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('bookmarks')
          .doc(bookId)
          .set({
            'bookId': bookId,
            'bookTitle': book.title,
            'bookAuthor': book.author,
            'bookCoverImageUrl': book.coverImageUrl,
            'bookType': book.type == BookType.ebook ? 'ebook' : 'audiobook',
            'bookReadTime': book.readTime,
            'bookListenTime': book.listenTime,
            'bookmarkedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (e) {
      print('Error adding bookmark: $e');
      rethrow;
    }
  }

  /// Remove a book from user's bookmarks
  static Future<void> removeBookmark({
    required String userId,
    required String bookId,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('bookmarks')
          .doc(bookId)
          .delete();
    } catch (e) {
      print('Error removing bookmark: $e');
      rethrow;
    }
  }

  /// Check if a book is bookmarked by a user
  static Future<bool> isBookmarked({
    required String userId,
    required String bookId,
  }) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('bookmarks')
          .doc(bookId)
          .get();
      return doc.exists;
    } catch (e) {
      print('Error checking bookmark status: $e');
      return false;
    }
  }

  /// Stream to listen to bookmark status changes for a specific book
  static Stream<bool> isBookmarkedStream({
    required String userId,
    required String bookId,
  }) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('bookmarks')
        .doc(bookId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  /// Get all bookmarked books for a user
  static Stream<List<Map<String, dynamic>>> getUserBookmarks(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('bookmarks')
        .orderBy('bookmarkedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();
    });
  }

  /// Get bookmarked book IDs for a user (useful for filtering)
  static Stream<List<String>> getBookmarkedBookIds(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('bookmarks')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
  }

  /// Toggle bookmark status (add if not bookmarked, remove if bookmarked)
  static Future<bool> toggleBookmark({
    required String userId,
    required String bookId,
    required BookModel book,
  }) async {
    try {
      final isCurrentlyBookmarked = await isBookmarked(
        userId: userId,
        bookId: bookId,
      );

      if (isCurrentlyBookmarked) {
        await removeBookmark(userId: userId, bookId: bookId);
        return false;
      } else {
        await addBookmark(userId: userId, bookId: bookId, book: book);
        return true;
      }
    } catch (e) {
      print('Error toggling bookmark: $e');
      rethrow;
    }
  }
}

