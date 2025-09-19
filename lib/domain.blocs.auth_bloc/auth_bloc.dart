import 'package:aeza_flutter_new/data.repositories/auth_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  // BLoC зависит от AuthRepository, чтобы иметь доступ к методам Firebase.
  AuthBloc({required this.authRepository}) : super(AuthInitial()) {

    // Обработчик события AppStarted: проверка текущего статуса пользователя при запуске.
    on<AppStarted>((event, emit) {
      final user = authRepository.getCurrentUser();
      if (user != null) {
        emit(Authenticated(user)); // Если пользователь уже вошел, меняем состояние на Authenticated.
      } else {
        emit(Unauthenticated()); // Иначе — на Unauthenticated.
      }
    });

    // Обработчик события LogInRequested: попытка входа.
    on<LogInRequested>((event, emit) async {
      emit(AuthLoading()); // Сначала показываем состояние загрузки.
      try {
        final user = await authRepository.signIn(
            email: event.email, password: event.password);
        if (user != null) {
          emit(Authenticated(user)); // В случае успеха — Authenticated.
        }
      } on FirebaseAuthException catch (e) {
        // В случае ошибки Firebase — AuthFailure с сообщением об ошибке.
        emit(AuthFailure(e.message ?? "Произошла ошибка аутентификации"));
      }
    });

    // Обработчик события SignUpRequested: попытка регистрации.
    on<SignUpRequested>((event, emit) async {
      emit(AuthLoading());
      try {
        final user = await authRepository.signUp(email: event.email, password: event.password);
        if (user != null) {
          // После успешной регистрации сразу считаем пользователя вошедшим.
          emit(Authenticated(user));
        }
      } on FirebaseAuthException catch (e) {
        // Обрабатываем специфичные ошибки, например, "email-already-in-use".
        emit(AuthFailure(e.message ?? "Произошла ошибка регистрации"));
      }
    });

    // Обработчик события LogOutRequested: выход из системы.
    on<LogOutRequested>((event, emit) async {
      emit(AuthLoading());
      await authRepository.signOut();
      emit(Unauthenticated()); // Меняем состояние на Unauthenticated.
    });
  }
}