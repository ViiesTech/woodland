import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/book_model.dart';
import '../../models/library_youtube_video.dart';
import '../../models/mp3_model.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _booksCollection = 'books';
  static const String _videosCollection = 'youtube_videos';
  static const String _mp3Collection = 'mp3';

  // Add a new book
  static Future<String> addBook(BookModel book) async {
    try {
      final docRef = await _firestore.collection(_booksCollection).add(book.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add book: $e');
    }
  }

  // Add a new library video
  static Future<String> addLibraryVideo(LibraryYoutubeVideo video) async {
    try {
      final docRef = await _firestore.collection(_videosCollection).add(video.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add library video: $e');
    }
  }

  // Add a new MP3
  static Future<String> addMp3(Mp3Model mp3) async {
    try {
      final docRef = await _firestore.collection(_mp3Collection).add(mp3.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to add MP3: $e');
    }
  }

  // Get all MP3s
  static Future<List<Mp3Model>> getMp3s() async {
    try {
      final querySnapshot = await _firestore
          .collection(_mp3Collection)
          .orderBy('createdAt', descending: true)
          .get();
      return querySnapshot.docs.map((doc) {
        return Mp3Model.fromMap(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get MP3s: $e');
    }
  }

  // Update MP3 status
  static Future<void> updateMp3Status(String id, bool isPublished) async {
    try {
      await _firestore.collection(_mp3Collection).doc(id).update({
        'isPublished': isPublished,
      });
    } catch (e) {
      throw Exception('Failed to update MP3 status: $e');
    }
  }

  // Get all library videos
  static Future<List<LibraryYoutubeVideo>> getLibraryVideos() async {
    try {
      final querySnapshot = await _firestore.collection(_videosCollection).get();
      return querySnapshot.docs.map((doc) {
        return LibraryYoutubeVideo.fromMap(doc.data(), doc.id);
      }).toList();
    } catch (e) {
      throw Exception('Failed to get library videos: $e');
    }
  }

  // Update library video status
  static Future<void> updateVideoStatus(String id, bool isPublished) async {
    try {
      await _firestore.collection(_videosCollection).doc(id).update({
        'isPublished': isPublished,
      });
    } catch (e) {
      throw Exception('Failed to update video status: $e');
    }
  }

  // Get all books
  static Future<List<BookModel>> getAllBooks() async {
    try {
      final querySnapshot = await _firestore.collection(_booksCollection).get();
      final books = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return BookModel.fromMap(data);
      }).toList();

      // Fetch folders from separate collection
      final foldersSnapshot = await _firestore.collection('folders').get();
      final folders = foldersSnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return BookModel.fromMap(data);
      }).toList();

      final combined = [...books, ...folders];

      // Sort client-side: position ascending, fallback to createdAt descending
      combined.sort((a, b) {
        final posCompare = a.position.compareTo(b.position);
        if (posCompare != 0) {
          return posCompare;
        }
        return b.createdAt.compareTo(a.createdAt);
      });
      return combined;
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
      await _firestore.collection('folders').doc(bookId).delete();
    } catch (e) {
      throw Exception('Failed to delete: $e');
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
