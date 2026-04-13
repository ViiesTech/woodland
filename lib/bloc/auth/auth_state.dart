import 'package:equatable/equatable.dart';
import '../../models/user_model.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

// Initial state
class AuthInitial extends AuthState {
  const AuthInitial();
}

// Checking authentication status
class AuthLoading extends AuthState {
  const AuthLoading();
}

// User is authenticated
class Authenticated extends AuthState {
  final UserModel user;

  const Authenticated(this.user);

  @override
  List<Object?> get props => [user];
}

// User is not authenticated
class Unauthenticated extends AuthState {
  const Unauthenticated();
}

// Authentication error
class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}
