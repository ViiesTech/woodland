import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/user_firestore_service.dart';
import '../services/firebase_auth_service.dart';

class AuthRepository {
  static const String _userKey = 'user_data';
  static const String _isLoggedInKey = 'is_logged_in';

  // Save user data to both cache and Firestore
  Future<bool> saveUser(UserModel user, {bool saveToFirestore = true}) async {
    try {
      // Save to local cache
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, user.toJsonString());
      await prefs.setBool(_isLoggedInKey, true);

      // Save to Firestore
      if (saveToFirestore) {
        final firestoreSuccess = await UserFirestoreService.saveUser(user);
        if (!firestoreSuccess) {
          print(
            'Warning: Failed to save user to Firestore, but cached locally',
          );
        }
      }

      return true;
    } catch (e) {
      print('Error saving user: $e');
      return false;
    }
  }

  // Get user data from cache, optionally sync with Firestore
  Future<UserModel?> getUser({bool syncWithFirestore = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString(_userKey);

      if (userString != null) {
        final cachedUser = UserModel.fromJsonString(userString);

        // Optionally sync with Firestore to get latest data
        if (syncWithFirestore) {
          final firestoreUser = await UserFirestoreService.getUser(
            cachedUser.id,
          );
          if (firestoreUser != null) {
            // Update cache with Firestore data
            await prefs.setString(_userKey, firestoreUser.toJsonString());
            return firestoreUser;
          }
        }

        return cachedUser;
      }
      return null;
    } catch (e) {
      print('Error getting user: $e');
      return null;
    }
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_isLoggedInKey) ?? false;
    } catch (e) {
      print('Error checking login status: $e');
      return false;
    }
  }

  // Clear user data (logout)
  Future<bool> clearUser({bool deleteFromFirestore = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Optionally delete from Firestore
      if (deleteFromFirestore) {
        final userString = prefs.getString(_userKey);
        if (userString != null) {
          final user = UserModel.fromJsonString(userString);
          await UserFirestoreService.deleteUser(user.id);
        }
      }

      // Sign out from Firebase and Google
      await FirebaseAuthService.signOut();

      // Clear all SharedPreferences cache
      await prefs.clear();

      return true;
    } catch (e) {
      print('Error clearing user: $e');
      return false;
    }
  }

  // Update user data in both cache and Firestore
  Future<bool> updateUser(
    UserModel user, {
    bool updateInFirestore = true,
  }) async {
    print('🔄 AuthRepository.updateUser called');
    print('   User ID: ${user.id}');
    print('   Update Firestore: $updateInFirestore');

    try {
      // Update in cache
      print('💾 Updating cache...');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, user.toJsonString());
      print('✅ Cache updated successfully');

      // Update in Firestore
      if (updateInFirestore) {
        print('☁️  Updating Firestore...');
        final firestoreSuccess = await UserFirestoreService.updateUser(user);
        if (firestoreSuccess) {
          print('✅ Firestore updated successfully');
        } else {
          print('⚠️  Failed to update user in Firestore, but cached locally');
        }
      }

      print('✅ AuthRepository.updateUser completed successfully');
      return true;
    } catch (e, stackTrace) {
      print('❌ Error in AuthRepository.updateUser: $e');
      print('Stack trace: $stackTrace');
      return false;
    }
  }

  // Get user from Firestore by ID
  Future<UserModel?> getUserFromFirestore(String userId) async {
    return await UserFirestoreService.getUser(userId);
  }

  // Get user by email from Firestore
  Future<UserModel?> getUserByEmail(String email) async {
    return await UserFirestoreService.getUserByEmail(email);
  }

  // Delete user account completely (Firestore, Firebase Auth, and cache)
  Future<bool> deleteUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userString = prefs.getString(_userKey);
      
      if (userString != null) {
        final user = UserModel.fromJsonString(userString);
        
        // Delete from Firestore
        await UserFirestoreService.deleteUser(user.id);
        
        // Delete from Firebase Auth
        await FirebaseAuthService.deleteUser();
        
        // Clear all SharedPreferences cache
        await prefs.clear();
        
        return true;
      }
      
      // If no cached user, still try to delete from Firebase Auth
      await FirebaseAuthService.deleteUser();
      await prefs.clear();
      
      return true;
    } catch (e) {
      print('Error deleting user: $e');
      return false;
    }
  }
}
