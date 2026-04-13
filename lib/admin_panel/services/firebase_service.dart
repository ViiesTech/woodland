import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/book_model.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _booksCollection = 'books';

  // Add a new book
  static Future<String> addBook(BookModel book) async {
    try {
      final docRef = await _firestore.collection(_booksCollection).add(book.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add book: $e');
    }
  }

  // Get all books
  static Future<List<BookModel>> getAllBooks() async {
    try {
      final querySnapshot = await _firestore.collection(_booksCollection).get();
      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return BookModel.fromMap(data);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get books: $e');
    }
  }

  // Update a book
  static Future<void> updateBook(String bookId, BookModel book) async {
    try {
      await _firestore.collection(_booksCollection).doc(bookId).update(book.toMap());
    } catch (e) {
      throw Exception('Failed to update book: $e');
    }
  }

  // Delete a book
  static Future<void> deleteBook(String bookId) async {
    try {
      await _firestore.collection(_booksCollection).doc(bookId).delete();
    } catch (e) {
      throw Exception('Failed to delete book: $e');
    }
  }

  // Get book by ID
  static Future<BookModel?> getBookById(String bookId) async {
    try {
      final doc = await _firestore.collection(_booksCollection).doc(bookId).get();
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return BookModel.fromMap(data);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get book: $e');
    }
  }
}
