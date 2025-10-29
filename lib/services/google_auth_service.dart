import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

class GoogleAuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  /// Sign in with Google
  static Future<UserModel?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the credential
      final UserCredential userCredential = await _auth.signInWithCredential(
        credential,
      );

      final User? firebaseUser = userCredential.user;

      if (firebaseUser != null) {
        // Create UserModel from Firebase user
        final userModel = UserModel(
          id: firebaseUser.uid,
          name: firebaseUser.displayName ?? 'User',
          email: firebaseUser.email ?? '',
          phoneNumber: firebaseUser.phoneNumber,
          role: 'user',
          createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
        );

        return userModel;
      }

      return null;
    } catch (e) {
      print('Error signing in with Google: $e');
      return null;
    }
  }

  /// Sign out from Google
  static Future<void> signOutFromGoogle() async {
    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
    } catch (e) {
      print('Error signing out from Google: $e');
    }
  }

  /// Check if user is currently signed in
  static User? getCurrentUser() {
    return _auth.currentUser;
  }

  /// Get current Firebase user as UserModel
  static Future<UserModel?> getCurrentUserModel() async {
    try {
      final User? firebaseUser = _auth.currentUser;

      if (firebaseUser != null) {
        return UserModel(
          id: firebaseUser.uid,
          name: firebaseUser.displayName ?? 'User',
          email: firebaseUser.email ?? '',
          phoneNumber: firebaseUser.phoneNumber,
          role: 'user',
          createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
        );
      }

      return null;
    } catch (e) {
      print('Error getting current user: $e');
      return null;
    }
  }

  /// Sign in with email and password
  static Future<UserModel?> signInWithEmail(
    String email,
    String password,
  ) async {
    try {
      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(email: email, password: password);

      final User? firebaseUser = userCredential.user;

      if (firebaseUser != null) {
        return UserModel(
          id: firebaseUser.uid,
          name: firebaseUser.displayName ?? email.split('@')[0],
          email: firebaseUser.email ?? email,
          phoneNumber: firebaseUser.phoneNumber,
          role: 'user',
          createdAt: firebaseUser.metadata.creationTime ?? DateTime.now(),
        );
      }

      return null;
    } catch (e) {
      print('Error signing in with email: $e');
      throw e;
    }
  }

  /// Register with email and password
  static Future<UserModel?> registerWithEmail(
    String email,
    String password,
    String name,
  ) async {
    try {
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);

      final User? firebaseUser = userCredential.user;

      if (firebaseUser != null) {
        // Update display name
        await firebaseUser.updateDisplayName(name);

        return UserModel(
          id: firebaseUser.uid,
          name: name,
          email: email,
          phoneNumber: firebaseUser.phoneNumber,
          role: 'user',
          createdAt: DateTime.now(),
        );
      }

      return null;
    } catch (e) {
      print('Error registering with email: $e');
      throw e;
    }
  }
}

