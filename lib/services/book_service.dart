import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:the_woodlands_series/admin_panel/models/book_model.dart';

class BookService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add a new book
  static Future<String> addBook(BookModel book) async {
    try {
      final docRef = await _firestore
          .collection('books')
          .add(book.toFirestore());
      return docRef.id;
    } catch (e) {
      print('Error adding book: $e');
      rethrow;
    }
  }

  // Get all books
  static Stream<List<BookModel>> getAllBooks() {
    return _firestore
        .collection('books')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => BookModel.fromFirestore(
                  doc.id,
                  doc.data() as Map<String, dynamic>,
                ),
              )
              .toList();
        });
  }

  // Get books by type (only published for regular users)
  static Stream<List<BookModel>> getBooksByType(BookType type) {
    final typeString = type == BookType.ebook ? 'ebook' : 'audiobook';
    return _firestore
        .collection('books')
        .where('type', isEqualTo: typeString)
        .where('isPublished', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => BookModel.fromFirestore(
                  doc.id,
                  doc.data() as Map<String, dynamic>,
                ),
              )
              .toList();
        });
  }

  // Get all books by type (including unpublished for admin)
  static Stream<List<BookModel>> getAllBooksByType(BookType type) {
    final typeString = type == BookType.ebook ? 'ebook' : 'audiobook';
    return _firestore
        .collection('books')
        .where('type', isEqualTo: typeString)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => BookModel.fromFirestore(
                  doc.id,
                  doc.data() as Map<String, dynamic>,
                ),
              )
              .toList();
        });
  }

  // Get a single book by ID
  static Future<BookModel?> getBookById(String bookId) async {
    try {
      final doc = await _firestore.collection('books').doc(bookId).get();
      if (doc.exists) {
        return BookModel.fromFirestore(doc.id, doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting book: $e');
      return null;
    }
  }

  // Update a book
  static Future<void> updateBook(String bookId, BookModel book) async {
    try {
      // Check if book is being published for the first time
      final doc = await _firestore.collection('books').doc(bookId).get();
      final currentData = doc.data();
      final currentIsPublished = currentData?['isPublished'] as bool? ?? false;
      final currentHasEverBeenPublished =
          currentData?['hasEverBeenPublished'] as bool? ?? false;

      // If book is being published and hasn't been published before, set hasEverBeenPublished
      final updateData = book.toFirestore();
      if (book.isPublished &&
          !currentIsPublished &&
          !currentHasEverBeenPublished) {
        updateData['hasEverBeenPublished'] = true;
      } else if (currentHasEverBeenPublished) {
        // Preserve hasEverBeenPublished if it was already true
        updateData['hasEverBeenPublished'] = true;
      }

      await _firestore.collection('books').doc(bookId).update(updateData);
    } catch (e) {
      print('Error updating book: $e');
      rethrow;
    }
  }

  // Delete a book
  static Future<void> deleteBook(String bookId) async {
    try {
      await _firestore.collection('books').doc(bookId).delete();
    } catch (e) {
      print('Error deleting book: $e');
      rethrow;
    }
  }

  // Search books by title or author (only published for regular users)
  static Stream<List<BookModel>> searchBooks(String query, BookType? type) {
    final queryLower = query.toLowerCase();

    Stream<QuerySnapshot> stream;
    if (type != null) {
      final typeString = type == BookType.ebook ? 'ebook' : 'audiobook';
      stream = _firestore
          .collection('books')
          .where('type', isEqualTo: typeString)
          .where('isPublished', isEqualTo: true)
          .snapshots();
    } else {
      stream = _firestore
          .collection('books')
          .where('isPublished', isEqualTo: true)
          .snapshots();
    }

    return stream.map((snapshot) {
      return snapshot.docs
          .map(
            (doc) => BookModel.fromFirestore(
              doc.id,
              doc.data() as Map<String, dynamic>,
            ),
          )
          .where((book) {
            return book.title.toLowerCase().contains(queryLower) ||
                book.author.toLowerCase().contains(queryLower);
          })
          .toList();
    });
  }

  // Search all books by title or author (including unpublished for admin)
  static Stream<List<BookModel>> searchAllBooks(String query, BookType? type) {
    final queryLower = query.toLowerCase();

    Stream<QuerySnapshot> stream;
    if (type != null) {
      final typeString = type == BookType.ebook ? 'ebook' : 'audiobook';
      stream = _firestore
          .collection('books')
          .where('type', isEqualTo: typeString)
          .snapshots();
    } else {
      stream = _firestore.collection('books').snapshots();
    }

    return stream.map((snapshot) {
      return snapshot.docs
          .map(
            (doc) => BookModel.fromFirestore(
              doc.id,
              doc.data() as Map<String, dynamic>,
            ),
          )
          .where((book) {
            return book.title.toLowerCase().contains(queryLower) ||
                book.author.toLowerCase().contains(queryLower);
          })
          .toList();
    });
  }

  // Get all published books (for admin or general listing)
  static Stream<List<BookModel>> getAllPublishedBooks() {
    return _firestore
        .collection('books')
        .where('isPublished', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(
                (doc) => BookModel.fromFirestore(
                  doc.id,
                  doc.data() as Map<String, dynamic>,
                ),
              )
              .toList();
        });
  }

  // Increment listen count for a book
  static Future<void> incrementListenCount(String bookId) async {
    try {
      await _firestore.collection('books').doc(bookId).update({
        'listenCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error incrementing listen count: $e');
      // If listenCount field doesn't exist, set it to 1
      try {
        await _firestore.collection('books').doc(bookId).set({
          'listenCount': 1,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e2) {
        print('Error setting listen count: $e2');
      }
    }
  }

  // Get top trending audiobooks by listen count (only published for regular users)
  static Stream<List<BookModel>> getTrendingAudiobooks({
    bool adminMode = false,
    int limit = 5,
  }) {
    // For admin mode, we can use a simple query
    // For regular users, we need to fetch all published audiobooks and sort in memory
    // to avoid needing a compound index
    Stream<QuerySnapshot> stream;
    if (adminMode) {
      stream = _firestore
          .collection('books')
          .where('type', isEqualTo: 'audiobook')
          .orderBy('listenCount', descending: true)
          .limit(limit)
          .snapshots();
    } else {
      stream = _firestore
          .collection('books')
          .where('type', isEqualTo: 'audiobook')
          .where('isPublished', isEqualTo: true)
          .snapshots();
    }

    return stream.map((snapshot) {
      List<BookModel> books = snapshot.docs
          .map(
            (doc) => BookModel.fromFirestore(
              doc.id,
              doc.data() as Map<String, dynamic>,
            ),
          )
          .toList();

      // Sort by listenCount in descending order and limit
      if (!adminMode) {
        books.sort((a, b) => b.listenCount.compareTo(a.listenCount));
        books = books.take(limit).toList();
      }

      return books;
    });
  }

  /// Increment view count (for unique users)
  static Future<void> incrementViewCount(String bookId) async {
    try {
      final docRef = _firestore.collection('books').doc(bookId);
      final doc = await docRef.get();

      if (doc.exists) {
        final currentCount = (doc.data()?['viewCount'] as num?)?.toInt() ?? 0;
        await docRef.update({
          'viewCount': currentCount + 1,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print(
          '✅ Incremented viewCount for book $bookId: ${currentCount} -> ${currentCount + 1}',
        );
      } else {
        print('⚠️ Book $bookId not found');
      }
    } catch (e) {
      print('❌ Error incrementing view count: $e');
      print('❌ Error stack: ${e.toString()}');
    }
  }

  /// Increment read count (for unique users)
  static Future<void> incrementReadCount(String bookId) async {
    try {
      print('🔄 Starting readCount increment for book: $bookId');
      final docRef = _firestore.collection('books').doc(bookId);
      final doc = await docRef.get();

      if (doc.exists) {
        final data = doc.data();
        final currentCount = (data?['readCount'] as num?)?.toInt() ?? 0;
        print('📊 Current readCount for book $bookId: $currentCount');

        final newCount = currentCount + 1;
        await docRef.update({
          'readCount': newCount,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Verify the update
        final updatedDoc = await docRef.get();
        final verifiedCount =
            (updatedDoc.data()?['readCount'] as num?)?.toInt() ?? 0;
        print(
          '✅ Incremented readCount for book $bookId: $currentCount -> $newCount (verified: $verifiedCount)',
        );

        if (verifiedCount != newCount) {
          print(
            '⚠️ WARNING: Verified count ($verifiedCount) does not match expected count ($newCount)',
          );
        }
      } else {
        print('⚠️ Book $bookId not found in database');
      }
    } catch (e, stackTrace) {
      print('❌ Error incrementing read count: $e');
      print('❌ Error stack: $stackTrace');
      rethrow; // Re-throw to let caller know it failed
    }
  }

  /// Increment listen count (for unique users) - uses existing listenCount field
  static Future<void> incrementListenCountForUser(String bookId) async {
    try {
      final docRef = _firestore.collection('books').doc(bookId);
      final doc = await docRef.get();

      if (doc.exists) {
        final currentCount = (doc.data()?['listenCount'] as num?)?.toInt() ?? 0;
        await docRef.update({
          'listenCount': currentCount + 1,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        print(
          '✅ Incremented listenCount for book $bookId: ${currentCount} -> ${currentCount + 1}',
        );
      } else {
        print('⚠️ Book $bookId not found');
      }
    } catch (e) {
      print('❌ Error incrementing listen count: $e');
      print('❌ Error stack: ${e.toString()}');
    }
  }

  /// Get top trending books (both ebook and audiobook combined)
  /// For audiobooks: uses listenCount, for ebooks: uses viewCount
  /// Returns top N books sorted by popularity
  static Stream<List<BookModel>> getTopTrendingBooks({
    bool adminMode = false,
    int limit = 10,
  }) {
    Stream<QuerySnapshot> stream;
    if (adminMode) {
      stream = _firestore
          .collection('books')
          .where('isPublished', isEqualTo: true)
          .snapshots();
    } else {
      stream = _firestore
          .collection('books')
          .where('isPublished', isEqualTo: true)
          .snapshots();
    }

    return stream.map((snapshot) {
      List<BookModel> allBooks = snapshot.docs
          .map(
            (doc) => BookModel.fromFirestore(
              doc.id,
              doc.data() as Map<String, dynamic>,
            ),
          )
          .toList();

      // Calculate popularity score for each book
      // For audiobooks: use listenCount
      // For ebooks: use viewCount
      allBooks.sort((a, b) {
        final aScore = a.type == BookType.audiobook
            ? a.listenCount
            : a.viewCount;
        final bScore = b.type == BookType.audiobook
            ? b.listenCount
            : b.viewCount;
        return bScore.compareTo(aScore);
      });

      return allBooks.take(limit).toList();
    });
  }

  /// Get new releases (both ebook and audiobook combined)
  /// Returns top N books sorted by createdAt (newest first)
  static Stream<List<BookModel>> getNewReleases({
    bool adminMode = false,
    int limit = 10,
  }) {
    Stream<QuerySnapshot> stream;
    if (adminMode) {
      stream = _firestore
          .collection('books')
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .snapshots();
    } else {
      stream = _firestore
          .collection('books')
          .where('isPublished', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .snapshots();
    }

    return stream.map((snapshot) {
      return snapshot.docs
          .map(
            (doc) => BookModel.fromFirestore(
              doc.id,
              doc.data() as Map<String, dynamic>,
            ),
          )
          .toList();
    });
  }

  /// Get "Coming Soon" books (unpublished books that have never been published)
  /// Returns books where isPublished == false AND hasEverBeenPublished == false
  /// Sorted by createdAt (newest first)
  static Stream<List<BookModel>> getComingSoonBooks({
    bool adminMode = false,
    int limit = 10,
  }) {
    // For both admin and regular users, we need to filter client-side
    // because Firestore doesn't support querying where isPublished == false AND hasEverBeenPublished == false
    Stream<QuerySnapshot> stream;
    if (adminMode) {
      stream = _firestore
          .collection('books')
          .where('isPublished', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .snapshots();
    } else {
      // For regular users, we still query unpublished books (admin feature, but might be visible)
      stream = _firestore
          .collection('books')
          .where('isPublished', isEqualTo: false)
          .orderBy('createdAt', descending: true)
          .snapshots();
    }

    return stream.map((snapshot) {
      List<BookModel> books = snapshot.docs
          .map(
            (doc) => BookModel.fromFirestore(
              doc.id,
              doc.data() as Map<String, dynamic>,
            ),
          )
          // Filter to only include books that have never been published
          .where((book) => !book.hasEverBeenPublished)
          .toList();

      // Sort by createdAt (newest first) and limit
      books.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return books.take(limit).toList();
    });
  }
}
