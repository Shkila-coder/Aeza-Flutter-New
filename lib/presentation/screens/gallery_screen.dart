import 'dart:ui';
import 'dart:typed_data';
import 'package:aeza_flutter_new/presentation/screens/editor_screen.dart';
import 'package:aeza_flutter_new/presentation/theme/app_colors.dart';
import 'package:aeza_flutter_new/presentation/theme/app_styles.dart';
import 'package:aeza_flutter_new/presentation/widgets/app_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:convert';
import '../../data.repositories/firestore_repository.dart';
import '../../data/models/drawing_model.dart';
import '../../domain.blocs.auth_bloc/auth_bloc.dart';
import '../../domain.blocs.auth_bloc/auth_event.dart';

// Экран галереи, отображающий все рисунки пользователя.
class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  // Переменная для хранения "будущего" списка картинок, которые придут из Firestore.
  late Future<List<Drawing>> _imagesFuture;

  @override
  void initState() {
    super.initState();
    // При инициализации экрана сразу запускаем загрузку изображений.
    _loadImages();
  }

  // Метод для получения списка рисунков из репозитория.
  void _loadImages() {
    setState(() {
      // FutureBuilder будет следить за этой переменной.
      _imagesFuture = context.read<FirestoreRepository>().getUserDrawings();
    });
  }

  // Метод для навигации на экран редактора и обновления галереи после возвращения.
  void _navigateToEditorAndRefresh([Drawing? drawingToEdit]) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => EditorScreen(
          // Передаем весь объект Drawing в редактор
          initialDrawing: drawingToEdit,
        ),
      ),
    );

    if (result == true) {
      _loadImages();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const AppBackground(),
          // FutureBuilder асинхронно строит UI на основе _imagesFuture.
          FutureBuilder<List<Drawing>>(
            future: _imagesFuture,
            builder: (context, snapshot) {
              // Пока данные загружаются, показываем индикатор.
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              // Если произошла ошибка.
              if (snapshot.hasError) {
                return Center(child: Text('Ошибка загрузки: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
              }
              // Если данных нет, показываем сообщение.
              final drawings = snapshot.data ?? [];
              if (drawings.isEmpty) {
                return const Center(
                  child: Text('Ваша галерея пуста', style: TextStyle(color: Colors.grey, fontSize: 18)),
                );
              }

              // Если все успешно, строим и ВОЗВРАЩАЕМ сетку с изображениями.
              return GridView.builder( // <-- ДОБАВЛЕНО СЛОВО RETURN
                padding: const EdgeInsets.only(top: 120, left: 16, right: 16, bottom: 100),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: drawings.length,
                itemBuilder: (context, index) {
                  final drawing = drawings[index];
                  final Uint8List imageBytes = base64Decode(drawing.base64Image);

                  return GestureDetector(
                    onTap: () {
                      _navigateToEditorAndRefresh(drawing);
                    },
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(imageBytes, fit: BoxFit.cover),
                    ),
                  );
                },
              );
            },
          ),
          _buildGlassAppBar(context),
          _buildCreateButton(context),
        ],
      ),
    );
  }

  // Виджет для AppBar'а с эффектом размытия.
  Widget _buildGlassAppBar(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            color: AppColors.appBarColor,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 14.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () {
                        // Кнопка выхода из аккаунта.
                        context.read<AuthBloc>().add(LogOutRequested());
                      },
                      icon: Image.asset('assets/icons/logout_icon.png'),
                    ),
                    const Text('Галерея', style: AppStyles.galleryTitleStyle),
                    const SizedBox(width: 48.0),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Виджет для кнопки "Создать новый рисунок".
  Widget _buildCreateButton(BuildContext context) {
    return Positioned(
      bottom: 40,
      left: 20,
      right: 20,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primaryGradientStart, AppColors.primaryGradientEnd],
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _navigateToEditorAndRefresh, // Вызываем навигацию без картинки.
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: Center(
                  child: Text('Создать', style: TextStyle(color: AppColors.text, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}