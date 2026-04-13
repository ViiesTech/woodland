import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:the_woodlands_series/services/book_service.dart';

class ReadingProgressService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Save or update reading progress for an ebook
  /// Only increments readCount for unique users (first time reading)
  /// Limits to 5 most recent books to prevent flickering
  static Future<void> saveProgress({
    required String userId,
    required String bookId,
    required int currentPage,
    required int totalPages,
    int? timeSpentMinutes, // Time spent reading in minutes
  }) async {
    try {
      // Check if this is the first time this user reads this book
      final docRef = _firestore
          .collection('users')
          .doc(userId)
          .collection('readingProgress')
          .doc(bookId);
      
      final doc = await docRef.get();
      final isNewRead = !doc.exists;
      
      print('📚 Checking read progress for book $bookId, user $userId - Document exists: ${doc.exists}');
      
      final updateData = <String, dynamic>{
        'bookId': bookId,
        'userId': userId,
        'currentPage': currentPage,
        'totalPages': totalPages,
        'lastUpdated': FieldValue.serverTimestamp(),
      };
      
      // Increment time spent if provided
      if (timeSpentMinutes != null && timeSpentMinutes > 0) {
        updateData['timeSpentMinutes'] = FieldValue.increment(timeSpentMinutes);
      }
      
      // Increment read count FIRST (before creating document) if this is a new read
      // This ensures count is incremented even if document creation has issues
      if (isNewRead) {
        print('📚 ✅ NEW unique user read detected! Incrementing readCount for book $bookId...');
        try {
          await BookService.incrementReadCount(bookId);
          print('📚 ✅ ReadCount increment initiated for book $bookId');
        } catch (e) {
          print('❌ Error incrementing read count: $e');
        }
      } else {
        print('📚 ⏭️ Same user ($userId) reading book $bookId again - NOT incrementing count');
      }
      
      // Save/update the reading progress document (after increment to ensure order)
      await docRef.set(updateData, SetOptions(merge: true));
      print('📚 ✅ Reading progress document saved for book $bookId, user $userId');
      
      // If book is completed (100%), delete it immediately
      final progressPercent = (currentPage / totalPages) * 100;
      if (progressPercent >= 100 && totalPages > 0) {
        print('📚 ✅ Book $bookId is 100% complete - deleting progress');
        await docRef.delete();
        return;
      }
      
      // Keep only the most recent incomplete book - delete all other incomplete books
      await _keepOnlyMostRecentIncompleteBook(userId, currentBookId: bookId);
    } catch (e) {
      print('❌ Error saving reading progress: $e');
      print('❌ Error stack: ${e.toString()}');
    }
  }

  /// Keep only the most recent incomplete book, delete all other incomplete books
  static Future<void> _keepOnlyMostRecentIncompleteBook(
    String userId, {
    required String currentBookId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('readingProgress')
          .get();
      
      if (snapshot.docs.isEmpty) {
        return;
      }
      
      // Filter out completed books (100%) and the current book
      final otherIncompleteBooks = snapshot.docs.where((doc) {
        if (doc.id == currentBookId) return false; // Don't delete current book
        
        final data = doc.data();
        final currentPage = data['currentPage'] as int? ?? 1;
        final totalPages = data['totalPages'] as int? ?? 1;
        if (totalPages <= 0) return true; // Keep if invalid, but we'll delete it
        
        final progressPercent = (currentPage / totalPages) * 100;
        return progressPercent < 100; // Only delete incomplete books
      }).toList();
      
      // Delete all other incomplete books (keep only the current one)
      for (var doc in otherIncompleteBooks) {
        await doc.reference.delete();
        print('🗑️ Deleted other incomplete book progress: ${doc.id}');
      }
    } catch (e) {
      print('❌ Error keeping only most recent book: $e');
    }
  }

  /// Get reading progress for a specific book
  static Future<Map<String, dynamic>?> getProgress({
    required String userId,
    required String bookId,
  }) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('readingProgress')
          .doc(bookId)
          .get();

      if (doc.exists && doc.data() != null) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('Error getting reading progress: $e');
      return null;
    }
  }

  /// Get all reading progress for a user (for viewed books)
  static Stream<Map<String, Map<String, dynamic>>> getAllProgress(
    String userId,
  ) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('readingProgress')
        .snapshots()
        .map((snapshot) {
      final progressMap = <String, Map<String, dynamic>>{};
      final progressList = <MapEntry<String, Map<String, dynamic>>>[];
      
      for (var doc in snapshot.docs) {
        if (doc.data().isNotEmpty) {
          progressList.add(MapEntry(doc.id, doc.data()));
        }
      }
      
      // Sort by lastUpdated in memory (descending)
      progressList.sort((a, b) {
        final aTime = a.value['lastUpdated'] as Timestamp?;
        final bTime = b.value['lastUpdated'] as Timestamp?;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });
      
      // Convert back to map
      for (var entry in progressList) {
        progressMap[entry.key] = entry.value;
      }
      
      return progressMap;
    });
  }

  /// Clear progress for a book
  static Future<void> clearProgress({
    required String userId,
    required String bookId,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('readingProgress')
          .doc(bookId)
          .delete();
    } catch (e) {
      print('Error clearing reading progress: $e');
    }
  }
}

