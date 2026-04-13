import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:the_woodlands_series/models/blog_model.dart';

class BlogService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'blogs';

  /// Get all blogs
  static Stream<List<BlogModel>> getAllBlogs() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        // Convert Timestamp to Map for fromFirestore
        final dataMap = Map<String, dynamic>.from(data);
        if (data['createdAt'] is Timestamp) {
          dataMap['createdAt'] = (data['createdAt'] as Timestamp).millisecondsSinceEpoch;
        }
        return BlogModel.fromFirestore(doc.id, dataMap);
      }).toList();
    });
  }

  /// Get blog by ID
  static Future<BlogModel?> getBlogById(String blogId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(blogId).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final dataMap = Map<String, dynamic>.from(data);
        if (data['createdAt'] is Timestamp) {
          dataMap['createdAt'] = (data['createdAt'] as Timestamp).millisecondsSinceEpoch;
        }
        return BlogModel.fromFirestore(doc.id, dataMap);
      }
      return null;
    } catch (e) {
      print('Error getting blog: $e');
      return null;
    }
  }

  /// Create a new blog (admin only)
  static Future<bool> createBlog(BlogModel blog) async {
    try {
      final data = blog.toFirestore();
      // Convert createdAt to Timestamp
      data['createdAt'] = Timestamp.fromDate(blog.createdAt);
      await _firestore.collection(_collection).add(data);
      return true;
    } catch (e) {
      print('Error creating blog: $e');
      return false;
    }
  }

  /// Update blog
  static Future<bool> updateBlog(BlogModel blog) async {
    try {
      final data = blog.toFirestore();
      // Convert createdAt to Timestamp
      data['createdAt'] = Timestamp.fromDate(blog.createdAt);
      await _firestore
          .collection(_collection)
          .doc(blog.id)
          .update(data);
      return true;
    } catch (e) {
      print('Error updating blog: $e');
      return false;
    }
  }

  /// Delete blog
  static Future<bool> deleteBlog(String blogId) async {
    try {
      await _firestore.collection(_collection).doc(blogId).delete();
      return true;
    } catch (e) {
      print('Error deleting blog: $e');
      return false;
    }
  }
}

