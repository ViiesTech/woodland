import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserFirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _usersCollection = 'users';

  /// Save user to Firestore with document ID same as user ID
  static Future<bool> saveUser(UserModel user) async {
    try {
      await _firestore
          .collection(_usersCollection)
          .doc(user.id) // Document ID is same as user ID
          .set(user.toFirestore());
      return true;
    } catch (e) {
      print('Error saving user to Firestore: $e');
      return false;
    }
  }

  /// Get user from Firestore by ID
  static Future<UserModel?> getUser(String userId) async {
    try {
      final doc = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromFirestore(doc.id, doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting user from Firestore: $e');
      return null;
    }
  }

  /// Update user in Firestore
  static Future<bool> updateUser(UserModel user) async {
    print('🔥 UserFirestoreService.updateUser called');
    print('   Collection: $_usersCollection');
    print('   Document ID: ${user.id}');

    try {
      // Convert to Firestore format
      final firestoreData = user.toFirestore();

      print('📝 Data to update:');
      firestoreData.forEach((key, value) {
        if (key == 'profileImageDeleteToken' && value != null) {
          print('   $key: (${value.toString().length} characters)');
        } else {
          print('   $key: $value');
        }
      });

      print('📤 Sending update to Firestore...');
      await _firestore
          .collection(_usersCollection)
          .doc(user.id)
          .update(firestoreData);

      print('✅ Firestore update completed successfully!');
      return true;
    } catch (e, stackTrace) {
      print('❌ Error updating user in Firestore!');
      print('Error: $e');
      print('Error type: ${e.runtimeType}');
      print('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Delete user from Firestore
  static Future<bool> deleteUser(String userId) async {
    try {
      await _firestore.collection(_usersCollection).doc(userId).delete();
      return true;
    } catch (e) {
      print('Error deleting user from Firestore: $e');
      return false;
    }
  }

  /// Check if user exists in Firestore
  static Future<bool> userExists(String userId) async {
    try {
      final doc = await _firestore
          .collection(_usersCollection)
          .doc(userId)
          .get();
      return doc.exists;
    } catch (e) {
      print('Error checking user existence in Firestore: $e');
      return false;
    }
  }

  /// Get user by email
  static Future<UserModel?> getUserByEmail(String email) async {
    try {
      final querySnapshot = await _firestore
          .collection(_usersCollection)
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        return UserModel.fromFirestore(doc.id, doc.data());
      }
      return null;
    } catch (e) {
      print('Error getting user by email from Firestore: $e');
      return null;
    }
  }

  /// Get all users (admin functionality)
  static Future<List<UserModel>> getAllUsers() async {
    try {
      final querySnapshot = await _firestore.collection(_usersCollection).get();
      return querySnapshot.docs
          .map((doc) => UserModel.fromFirestore(doc.id, doc.data()))
          .toList();
    } catch (e) {
      print('Error getting all users from Firestore: $e');
      return [];
    }
  }

  /// Get users by role
  static Future<List<UserModel>> getUsersByRole(String role) async {
    try {
      final querySnapshot = await _firestore
          .collection(_usersCollection)
          .where('role', isEqualTo: role)
          .get();
      return querySnapshot.docs
          .map((doc) => UserModel.fromFirestore(doc.id, doc.data()))
          .toList();
    } catch (e) {
      print('Error getting users by role from Firestore: $e');
      return [];
    }
  }
}
