import 'package:equatable/equatable.dart';
import '../../models/user_model.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

// Event to check if user is already logged in (from cache)
class CheckAuthStatus extends AuthEvent {
  const CheckAuthStatus();
}

// Event to login user with email and password
class LoginWithEmail extends AuthEvent {
  final String email;
  final String password;

  const LoginWithEmail({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

// Event to register user with email and password
class RegisterWithEmail extends AuthEvent {
  final String email;
  final String password;
  final String name;

  const RegisterWithEmail({
    required this.email,
    required this.password,
    required this.name,
  });

  @override
  List<Object?> get props => [email, password, name];
}

// Event to login with Google
class LoginWithGoogle extends AuthEvent {
  const LoginWithGoogle();
}

// Event to login user (legacy - for cached user)
class LoginUser extends AuthEvent {
  final UserModel user;

  const LoginUser(this.user);

  @override
  List<Object?> get props => [user];
}

// Event to register user (legacy - for cached user)
class RegisterUser extends AuthEvent {
  final UserModel user;

  const RegisterUser(this.user);

  @override
  List<Object?> get props => [user];
}

// Event to logout user
class LogoutUser extends AuthEvent {
  const LogoutUser();
}

// Event to load user from cache
class LoadUserFromCache extends AuthEvent {
  const LoadUserFromCache();
}

// Event to update user profile
class UpdateUser extends AuthEvent {
  final UserModel user;

  const UpdateUser(this.user);

  @override
  List<Object?> get props => [user];
}

// Event to delete user account
class DeleteUser extends AuthEvent {
  const DeleteUser();
}