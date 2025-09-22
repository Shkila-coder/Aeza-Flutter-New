// lib/presentation/widgets/app_background.dart
import 'package:flutter/material.dart';

class AppBackground extends StatelessWidget {
  const AppBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Слой 1: Основной фон-свечение
        Positioned.fill(
          child: Opacity(
            opacity: 0.25,
            child: Image.asset('assets/images/background_glow.png', fit: BoxFit.cover),
          ),
        ),
        // Слой 2: Паттерн с линиями
        Positioned.fill(
          child: Image.asset(
            'assets/images/pattern.png',
            fit: BoxFit.cover,
            color: Colors.white.withAlpha(38),
            colorBlendMode: BlendMode.modulate,
          ),
        ),
      ],
    );
  }
}