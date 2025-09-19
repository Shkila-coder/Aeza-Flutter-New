// lib/presentation/theme/app_styles.dart
import 'package:aeza_flutter_new/presentation/theme/app_colors.dart';
import 'package:flutter/material.dart';

class AppStyles {
  // Стиль для заголовка "Вход"
  static const TextStyle titleStyle = TextStyle(
    fontFamily: 'Press Start 2P',
    fontSize: 20,
    color: AppColors.text,
    fontWeight: FontWeight.w400,
  );

  // Обновлённый стиль для полей ввода
  static InputDecoration textFieldDecoration({required String label, required String hint}) {
    return InputDecoration(
      floatingLabelBehavior: FloatingLabelBehavior.always, // Чтобы label всегда был вверху
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(
        fontFamily: 'Roboto',
        color: AppColors.textFieldBorder,
        fontSize: 12, // Размер из Figma
        fontWeight: FontWeight.w400,
      ),
      hintStyle: const TextStyle(
        fontFamily: 'Roboto', // Шрифт можно указать и для hint
        color: AppColors.textFieldBorder,
      ),
      // Убираем стандартные рамки, так как мы их рисуем на контейнере
      border: InputBorder.none,
      contentPadding: EdgeInsets.zero, // Убираем внутренние отступы поля
    );
  }

  static const TextStyle galleryTitleStyle = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 22,
    color: AppColors.appBarTitle,
    fontWeight: FontWeight.w500, // Medium
  );
}