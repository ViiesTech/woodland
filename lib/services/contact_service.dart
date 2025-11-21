import 'package:cloud_firestore/cloud_firestore.dart';

class ContactService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'contacts';

  /// Submit a contact form
  static Future<bool> submitContact({
    required String name,
    required String subject,
    required String? message,
    String? userId,
    String? userEmail,
  }) async {
    try {
      await _firestore.collection(_collection).add({
        'name': name,
        'subject': subject,
        'message': message ?? '',
        'userId': userId,
        'userEmail': userEmail,
        'createdAt': FieldValue.serverTimestamp(),
        'read': false,
      });
      return true;
    } catch (e) {
      print('Error submitting contact form: $e');
      return false;
    }
  }

  /// Get all contacts (admin only)
  static Stream<List<Map<String, dynamic>>> getAllContacts() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();
            return {'id': doc.id, ...data};
          }).toList();
        });
  }

  /// Mark contact as read
  static Future<void> markAsRead(String contactId) async {
    try {
      await _firestore.collection(_collection).doc(contactId).update({
        'read': true,
      });
    } catch (e) {
      print('Error marking contact as read: $e');
    }
  }

  /// Delete contact
  static Future<void> deleteContact(String contactId) async {
    try {
      await _firestore.collection(_collection).doc(contactId).delete();
    } catch (e) {
      print('Error deleting contact: $e');
    }
  }
}
