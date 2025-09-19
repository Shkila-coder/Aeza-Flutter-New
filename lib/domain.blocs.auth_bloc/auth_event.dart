import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object> get props => [];
}

// Событие, которое отправляется при запуске приложения для проверки статуса пользователя.
class AppStarted extends AuthEvent {}

// Событие для запроса входа в систему. Содержит email и пароль.
class LogInRequested extends AuthEvent {
  final String email;
  final String password;
  const LogInRequested({required this.email, required this.password});
  @override
  List<Object> get props => [email, password];
}

// Событие для запроса регистрации. Содержит email и пароль.
class SignUpRequested extends AuthEvent {
  final String email;
  final String password;
  const SignUpRequested({required this.email, required this.password});
  @override
  List<Object> get props => [email, password];
}

// Событие для запроса выхода из системы.
class LogOutRequested extends AuthEvent {}