import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

// Начальное состояние, пока статус пользователя не определен.
class AuthInitial extends AuthState {}

// Состояние, когда пользователь успешно аутентифицирован.
// Хранит в себе объект User из Firebase.
class Authenticated extends AuthState {
  final User user;
  const Authenticated(this.user);
  @override
  List<Object?> get props => [user];
}

// Состояние, когда пользователь не вошел в систему.
class Unauthenticated extends AuthState {}

// Состояние, когда идет процесс аутентификации (например, при нажатии на кнопку "Войти").
// UI может показать индикатор загрузки в этом состоянии.
class AuthLoading extends AuthState {}

// Состояние, когда в процессе аутентификации произошла ошибка.
// Хранит в себе сообщение об ошибке для показа пользователю.
class AuthFailure extends AuthState {
  final String message;
  const AuthFailure(this.message);
  @override
  List<Object?> get props => [message];
}