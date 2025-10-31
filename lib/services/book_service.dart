import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:the_woodlands_series/admin_panel/models/book_model.dart';

class BookService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add a new book
  static Future<String> addBook(BookModel book) async {
    try {
      final docRef = await _firestore.collection('books').add(book.toFirestore());
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
          .map((doc) => BookModel.fromFirestore(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  // Get books by type
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
          .map((doc) => BookModel.fromFirestore(doc.id, doc.data() as Map<String, dynamic>))
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
      await _firestore.collection('books').doc(bookId).update(book.toFirestore());
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

  // Search books by title or author
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
          .map((doc) => BookModel.fromFirestore(doc.id, doc.data() as Map<String, dynamic>))
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
          .map((doc) => BookModel.fromFirestore(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    });
  }
}
