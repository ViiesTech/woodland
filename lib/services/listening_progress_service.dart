import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:the_woodlands_series/services/book_service.dart';

class ListeningProgressService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Save or update listening progress for a user
  /// Progress includes: bookId, chapterIndex, position (in milliseconds), lastUpdated
  /// Only increments listenCount for unique users (first time listening)
  static Future<void> saveProgress({
    required String userId,
    required String bookId,
    required int chapterIndex,
    required int positionMs,
  }) async {
    try {
      // Check if this is the first time this user listens to this book
      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('listeningProgress')
          .doc(bookId);
      
      final doc = await docRef.get();
      final isNewListen = !doc.exists;
      
      print('🎧 Checking listen progress for book $bookId, user $userId - Document exists: ${doc.exists}');
      
      // Save/update the listening progress document first
      await docRef.set({
        'bookId': bookId,
        'userId': userId,
        'chapterIndex': chapterIndex,
        'positionMs': positionMs,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      // Increment listen count ONLY if this is a new listen (unique user)
      // Same user listening multiple times should NOT increase count (uses existing listenCount field)
      if (isNewListen) {
        print('🎧 ✅ NEW unique user listen detected! Incrementing listenCount for book $bookId...');
        await BookService.incrementListenCountForUser(bookId);
      } else {
        print('🎧 ⏭️ Same user ($userId) listening to book $bookId again - NOT incrementing count');
      }
    } catch (e) {
      print('❌ Error saving listening progress: $e');
      print('❌ Error stack: ${e.toString()}');
    }
  }

  /// Get listening progress for a specific book
  static Future<Map<String, dynamic>?> getProgress({
    required String userId,
    required String bookId,
  }) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('listeningProgress')
          .doc(bookId)
          .get();

      if (doc.exists && doc.data() != null) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('Error getting listening progress: $e');
      return null;
    }
  }

  /// Get all listening progress for a user (to show in audiobook page)
  static Stream<Map<String, Map<String, dynamic>>> getAllProgress(
    String userId,
  ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('listeningProgress')
        .snapshots()
        .map((snapshot) {
          final progressMap = <String, Map<String, dynamic>>{};
          for (var doc in snapshot.docs) {
            if (doc.data().isNotEmpty) {
              progressMap[doc.id] = doc.data();
            }
          }
          return progressMap;
        });
  }

  /// Clear progress for a book (when user finishes or wants to reset)
  static Future<void> clearProgress({
    required String userId,
    required String bookId,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('listeningProgress')
          .doc(bookId)
          .delete();
    } catch (e) {
      print('Error clearing listening progress: $e');
    }
  }
}
