import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/auth_repository.dart';
import '../../services/firebase_auth_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository}) : super(const AuthInitial()) {
    // Check authentication status
    on<CheckAuthStatus>(_onCheckAuthStatus);

    // Login with email and password
    on<LoginWithEmail>(_onLoginWithEmail);

    // Register with email and password
    on<RegisterWithEmail>(_onRegisterWithEmail);

    // Login with Google
    on<LoginWithGoogle>(_onLoginWithGoogle);

    // Login user (legacy)
    on<LoginUser>(_onLoginUser);

    // Register user (legacy)
    on<RegisterUser>(_onRegisterUser);

    // Logout user
    on<LogoutUser>(_onLogoutUser);

    // Load user from cache
    on<LoadUserFromCache>(_onLoadUserFromCache);

    // Update user profile
    on<UpdateUser>(_onUpdateUser);
  }

  // Check if user is already logged in
  Future<void> _onCheckAuthStatus(
    CheckAuthStatus event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      // Check Firebase auth state first
      final firebaseUser = FirebaseAuthService.getCurrentUser();

      if (firebaseUser != null) {
        // User is logged in Firebase, get user model
        final userModel = await FirebaseAuthService.getCurrentUserModel();
        if (userModel != null) {
          // Save to cache
          await authRepository.saveUser(userModel, saveToFirestore: false);
          emit(Authenticated(userModel));
          return;
        }
      }

      // Check local cache if Firebase auth fails
      final isLoggedIn = await authRepository.isLoggedIn();
      if (isLoggedIn) {
        final user = await authRepository.getUser();
        if (user != null) {
          emit(Authenticated(user));
        } else {
          emit(const Unauthenticated());
        }
      } else {
        emit(const Unauthenticated());
      }
    } catch (e) {
      emit(AuthError('Error checking auth status: ${e.toString()}'));
    }
  }

  // Login with email and password
  Future<void> _onLoginWithEmail(
    LoginWithEmail event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      // Authenticate with Firebase Auth
      final authUser = await FirebaseAuthService.signInWithEmail(
        event.email,
        event.password,
      );

      // Get user data from Firestore to preserve role and other details
      final firestoreUser = await authRepository.getUserFromFirestore(
        authUser.id,
      );

      // Use Firestore data if exists (to preserve role), otherwise use auth data
      final finalUser = firestoreUser ?? authUser;

      // Save to cache only (don't overwrite Firestore)
      final success = await authRepository.saveUser(
        finalUser,
        saveToFirestore: false,
      );

      if (success) {
        emit(Authenticated(finalUser));
      } else {
        emit(const AuthError('Failed to save user data'));
      }
    } catch (e) {
      emit(AuthError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  // Register with email and password
  Future<void> _onRegisterWithEmail(
    RegisterWithEmail event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      // Create account in Firebase
      final user = await FirebaseAuthService.registerWithEmail(
        event.email,
        event.password,
        event.name,
      );

      // Save to cache and Firestore
      final success = await authRepository.saveUser(
        user,
        saveToFirestore: true,
      );

      if (success) {
        emit(Authenticated(user));
      } else {
        emit(const AuthError('Failed to save user data'));
      }
    } catch (e) {
      emit(AuthError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  // Login with Google
  Future<void> _onLoginWithGoogle(
    LoginWithGoogle event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      // Authenticate with Google
      final authUser = await FirebaseAuthService.signInWithGoogle();

      // Check if user exists in Firestore
      final firestoreUser = await authRepository.getUserFromFirestore(
        authUser.id,
      );

      if (firestoreUser != null) {
        // Existing user - use Firestore data to preserve role
        final success = await authRepository.saveUser(
          firestoreUser,
          saveToFirestore: false,
        );

        if (success) {
          emit(Authenticated(firestoreUser));
        } else {
          emit(const AuthError('Failed to save user data'));
        }
      } else {
        // New user - save to both cache and Firestore
        final success = await authRepository.saveUser(
          authUser,
          saveToFirestore: true,
        );

        if (success) {
          emit(Authenticated(authUser));
        } else {
          emit(const AuthError('Failed to save user data'));
        }
      }
    } catch (e) {
      emit(AuthError(e.toString().replaceAll('Exception: ', '')));
    }
  }

  // Login user
  Future<void> _onLoginUser(LoginUser event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      // For login, we don't create a new Firestore entry, just cache locally
      // In real app, you would verify credentials with backend first
      final success = await authRepository.saveUser(
        event.user,
        saveToFirestore: false,
      );
      if (success) {
        emit(Authenticated(event.user));
      } else {
        emit(const AuthError('Failed to save user data'));
      }
    } catch (e) {
      emit(AuthError('Login error: ${e.toString()}'));
    }
  }

  // Register user - Save to both cache and Firestore
  Future<void> _onRegisterUser(
    RegisterUser event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      // Save to both cache and Firestore with saveToFirestore: true
      final success = await authRepository.saveUser(
        event.user,
        saveToFirestore: true,
      );
      if (success) {
        emit(Authenticated(event.user));
      } else {
        emit(const AuthError('Failed to save user data'));
      }
    } catch (e) {
      emit(AuthError('Registration error: ${e.toString()}'));
    }
  }

  // Logout user
  Future<void> _onLogoutUser(LogoutUser event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());
    try {
      final success = await authRepository.clearUser();
      if (success) {
        emit(const Unauthenticated());
      } else {
        emit(const AuthError('Failed to logout'));
      }
    } catch (e) {
      emit(AuthError('Logout error: ${e.toString()}'));
    }
  }

  // Load user from cache
  Future<void> _onLoadUserFromCache(
    LoadUserFromCache event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());
    try {
      final user = await authRepository.getUser();
      if (user != null) {
        emit(Authenticated(user));
      } else {
        emit(const Unauthenticated());
      }
    } catch (e) {
      emit(AuthError('Error loading user: ${e.toString()}'));
    }
  }

  // Update user profile
  Future<void> _onUpdateUser(UpdateUser event, Emitter<AuthState> emit) async {
    try {
      // Emit updated user state immediately
      emit(Authenticated(event.user));
    } catch (e) {
      emit(AuthError('Error updating user: ${e.toString()}'));
    }
  }
}
