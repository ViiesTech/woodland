import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:the_woodlands_series/models/quiz_model.dart';

class QuizService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'quizzes';

  /// Get a real-time stream of all quizzes (sorted by newest first)
  static Stream<List<QuizModel>> getAllQuizzes() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        final dataMap = Map<String, dynamic>.from(data);
        if (data['createdAt'] is Timestamp) {
          dataMap['createdAt'] = (data['createdAt'] as Timestamp).millisecondsSinceEpoch;
        }
        return QuizModel.fromFirestore(doc.id, dataMap);
      }).toList();
    });
  }

  /// Create a new quiz (Admin only)
  static Future<bool> createQuiz(QuizModel quiz) async {
    try {
      final data = quiz.toFirestore();
      data['createdAt'] = FieldValue.serverTimestamp();
      await _firestore.collection(_collection).add(data);
      return true;
    } catch (e) {
      print('Error creating quiz: $e');
      return false;
    }
  }

  /// Update an existing quiz (Admin only)
  static Future<bool> updateQuiz(QuizModel quiz) async {
    try {
      final data = quiz.toFirestore();
      // Keep existing createdAt or update
      data['createdAt'] = Timestamp.fromDate(quiz.createdAt);
      await _firestore
          .collection(_collection)
          .doc(quiz.id)
          .update(data);
      return true;
    } catch (e) {
      print('Error updating quiz: $e');
      return false;
    }
  }

  /// Toggle or update the published status of a quiz
  static Future<bool> updateQuizStatus(String id, bool isPublished) async {
    try {
      await _firestore.collection(_collection).doc(id).update({
        'isPublished': isPublished,
      });
      return true;
    } catch (e) {
      print('Error updating quiz status: $e');
      return false;
    }
  }

  /// Delete a quiz (Admin only)
  static Future<bool> deleteQuiz(String quizId) async {
    try {
      await _firestore.collection(_collection).doc(quizId).delete();
      return true;
    } catch (e) {
      print('Error deleting quiz: $e');
      return false;
    }
  }
}
