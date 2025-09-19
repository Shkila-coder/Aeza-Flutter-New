import 'dart:ui';
import 'package:aeza_flutter_new/presentation/screens/register_screen.dart';
import 'package:aeza_flutter_new/presentation/theme/app_colors.dart';
import 'package:aeza_flutter_new/presentation/theme/app_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain.blocs.auth_bloc/auth_bloc.dart';
import '../../domain.blocs.auth_bloc/auth_event.dart';
import '../../domain.blocs.auth_bloc/auth_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Добавляем контроллеры для считывания текста и ключ для валидации формы
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocListener<AuthBloc, AuthState>(
        // BlocListener для показа ошибок
        listener: (context, state) {
          if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        child: Stack(
          children: [
            Positioned.fill(
              child: Opacity(
                opacity: 0.25,
                child: Image.asset('assets/images/background_glow.png',
                fit: BoxFit.cover),
              ),
            ),
            Positioned.fill(
              child: Image.asset(
                'assets/images/pattern.png',
                fit: BoxFit.cover,
                color: Colors.white.withOpacity(0.15),
                colorBlendMode: BlendMode.modulate,
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                // 3. Оборачиваем Column в Form
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Spacer(flex: 2),
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          ImageFiltered(
                            imageFilter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                            child: ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [AppColors.primaryGradientStart, AppColors.primaryGradientEnd],
                              ).createShader(bounds),
                              child: const Text('Вход', style: AppStyles.titleStyle),
                            ),
                          ),
                          const Text('Вход', style: AppStyles.titleStyle),
                        ],
                      ),
                      const Spacer(flex: 1),
                      // Поле для Email с контроллером и валидацией
                      _buildBlurredTextField(
                        controller: _emailController,
                        label: 'e-mail',
                        hint: 'Введите электронную почту',
                        validator: (value) {
                          if (value == null || !value.contains('@')) {
                            return 'Введите корректный email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Поле для Пароля (исправлен label)
                      _buildBlurredTextField(
                        controller: _passwordController,
                        label: 'Пароль',
                        hint: 'Введите пароль',
                        isObscure: true,
                        validator: (value) {
                          if (value == null || value.length < 6) {
                            return 'Пароль должен быть не менее 6 символов';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 40),
                      // 4. Кнопки с логикой
                      BlocBuilder<AuthBloc, AuthState>(
                        // BlocBuilder для показа индикатора загрузки
                        builder: (context, state) {
                          if (state is AuthLoading) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          return _buildGradientButton('Войти', () {
                            // При нажатии проверяем форму и отправляем событие в BLoC
                            if (_formKey.currentState!.validate()) {
                              context.read<AuthBloc>().add(LogInRequested(
                                email: _emailController.text.trim(),
                                password: _passwordController.text.trim(),
                              ));
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      // Кнопка "Регистрация" с переходом на новый экран
                      _buildRegistrationButton('Регистрация', () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const RegisterScreen()),
                        );
                      }),
                      const Spacer(flex: 2),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  // Виджет для кнопки "Войти"
  Widget _buildGradientButton(String text, VoidCallback onPressed) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8.0),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primaryGradientStart,
              AppColors.primaryGradientEnd,
            ],
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onPressed,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
              child: Center(
                child: Text(text, style: const TextStyle(color: AppColors.text, fontSize: 16)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Виджет для кнопки "Регистрация"
  Widget _buildRegistrationButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.registrationButton,
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      ),
      child: Text(
        text,
        style: const TextStyle(color: AppColors.registrationButtonText, fontSize: 16),
      ),
    );
  }

 Widget _buildBlurredTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required String? Function(String?) validator,
    bool isObscure = false,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: AppColors.background.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: AppColors.textFieldBorder, width: 0.5),
          ),
          child: TextFormField(
            controller: controller,
            validator: validator,
            obscureText: isObscure,
            style: const TextStyle(color: AppColors.text, fontSize: 16),
            decoration: AppStyles.textFieldDecoration(label: label, hint: hint),
          ),
        ),
      ),
    );
  }
}
