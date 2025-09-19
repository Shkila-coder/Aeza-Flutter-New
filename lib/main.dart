import 'package:aeza_flutter_new/data.repositories/auth_repository.dart';
import 'package:aeza_flutter_new/domain.blocs.auth_bloc/auth_bloc.dart';
import 'package:aeza_flutter_new/domain.blocs.auth_bloc/auth_event.dart';
import 'package:aeza_flutter_new/domain.blocs.auth_bloc/auth_state.dart';
import 'package:aeza_flutter_new/presentation/screens/login_screen.dart';
import 'package:aeza_flutter_new/presentation/screens/gallery_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'data.repositories/firestore_repository.dart';
import 'firebase_options.dart';

// Точка входа в приложение.
void main() async {
  // Убеждаемся, что все биндинги Flutter инициализированы до запуска приложения.
  WidgetsFlutterBinding.ensureInitialized();
  // Инициализируем Firebase для связи с бэкендом.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Запускаем главный виджет приложения.
  runApp(const MyApp());
}

// Главный виджет приложения.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // MultiRepositoryProvider предоставляет экземпляры репозиториев всему дереву виджетов.
    return MultiRepositoryProvider(
      providers: [
        // Репозиторий для работы с аутентификацией Firebase.
        RepositoryProvider(create: (context) => AuthRepository()),
        // Репозиторий для работы с базой данных Firestore.
        RepositoryProvider(create: (context) => FirestoreRepository()),
      ],
      // BlocProvider создает и предоставляет AuthBloc.
      child: BlocProvider(
        create: (context) => AuthBloc(
          authRepository: RepositoryProvider.of<AuthRepository>(context),
        )..add(AppStarted()), // Сразу после создания BLoC'а отправляем событие AppStarted.
        child: MaterialApp(
          title: 'Artify',
          debugShowCheckedModeBanner: false,
          // BlocBuilder следит за состоянием аутентификации и решает, какой экран показать.
          home: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              // Если пользователь аутентифицирован, показываем галерею.
              if (state is Authenticated) {
                return const GalleryScreen();
              }
              // Если пользователь не аутентифицирован или произошла ошибка, показываем экран входа.
              if (state is Unauthenticated || state is AuthFailure) {
                return const LoginScreen();
              }
              // Во время проверки состояния показываем индикатор загрузки.
              return const Scaffold(
                backgroundColor: Colors.black,
                body: Center(child: CircularProgressIndicator()),
              );
            },
          ),
        ),
      ),
    );
  }
}