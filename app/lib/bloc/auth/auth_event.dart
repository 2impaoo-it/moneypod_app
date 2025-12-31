import 'package:equatable/equatable.dart';

// Auth Events
abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthLoginRequested extends AuthEvent {
  final String email;
  final String password;
  final String? fcmToken;

  const AuthLoginRequested({
    required this.email,
    required this.password,
    this.fcmToken,
  });

  @override
  List<Object?> get props => [email, password, fcmToken];
}

class AuthRegisterRequested extends AuthEvent {
  final String email;
  final String password;
  final String fullName;

  const AuthRegisterRequested({
    required this.email,
    required this.password,
    required this.fullName,
  });

  @override
  List<Object?> get props => [email, password, fullName];
}

class AuthLogoutRequested extends AuthEvent {}

class AuthCheckRequested extends AuthEvent {}

class AuthTokenLoaded extends AuthEvent {
  final String token;

  const AuthTokenLoaded(this.token);

  @override
  List<Object?> get props => [token];
}
