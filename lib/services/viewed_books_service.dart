import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:the_woodlands_series/services/book_service.dart';

class ViewedBooksService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Mark a book as viewed (for any book type - ebook or audiobook)
  /// Only increments count for unique users (first time viewing)
  static Future<void> markBookAsViewed({
    required String userId,
    required String bookId,
  }) async {
    try {
      // Check if this is the first time this user views this book
      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('viewedBooks')
          .doc(bookId);
      
      final doc = await docRef.get();
      final isNewView = !doc.exists;
      
      print('📖 Checking view for book $bookId, user $userId - Document exists: ${doc.exists}');
      
      // Save/update the viewed book document first
      await docRef.set({
        'bookId': bookId,
        'userId': userId,
        'lastViewed': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      // Increment view count ONLY if this is a new view (unique user)
      // Same user viewing multiple times should NOT increase count
      if (isNewView) {
        print('📖 ✅ NEW unique user view detected! Incrementing viewCount for book $bookId...');
        await BookService.incrementViewCount(bookId);
      } else {
        print('📖 ⏭️ Same user ($userId) viewing book $bookId again - NOT incrementing count');
      }
    } catch (e) {
      print('❌ Error marking book as viewed: $e');
      print('❌ Error stack: ${e.toString()}');
    }
  }

  /// Get all viewed books for a user
  static Stream<Map<String, Map<String, dynamic>>> getAllViewedBooks(
    String userId,
  ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('viewedBooks')
        .snapshots()
        .map((snapshot) {
      final viewedMap = <String, Map<String, dynamic>>{};
      final viewedList = <MapEntry<String, Map<String, dynamic>>>[];

      for (var doc in snapshot.docs) {
        if (doc.data().isNotEmpty) {
          viewedList.add(MapEntry(doc.id, doc.data()));
        }
      }

      // Sort by lastViewed in memory (descending - most recent first)
      viewedList.sort((a, b) {
        final aTime = a.value['lastViewed'] as Timestamp?;
        final bTime = b.value['lastViewed'] as Timestamp?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });

      // Convert back to map
      for (var entry in viewedList) {
        viewedMap[entry.key] = entry.value;
      }

      return viewedMap;
    });
  }

  /// Clear viewed books history
  static Future<void> clearViewedBooks(String userId) async {
    try {
      final batch = _firestore.batch();
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('viewedBooks')
          .get();

      for (var doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      print('Error clearing viewed books: $e');
    }
  }
}

