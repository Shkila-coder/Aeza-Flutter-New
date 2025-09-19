import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain.blocs.auth_bloc/auth_bloc.dart';
import '../../domain.blocs.auth_bloc/auth_event.dart';
import '../../domain.blocs.auth_bloc/auth_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_styles.dart';


class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _signUp() {
    if (_formKey.currentState!.validate()) {
      print('Форма валидна! Отправляем событие SignUpRequested...');
      context.read<AuthBloc>().add(
        SignUpRequested(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        ),
      );
    }else {
      print('Форма НЕ прошла валидацию!');
    }

  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          // Если состояние - ошибка, показываем SnackBar
          if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(state.message), backgroundColor: Colors.red),
            );
          }
          // Если состояние - успех (Authenticated), закрываем экран
          if (state is Authenticated) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        },
    child:  Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Фоновые слои
          Positioned.fill(
            child: Opacity(
              opacity: 0.25,
              child: Image.asset('assets/images/background_glow.png', fit: BoxFit.cover),
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
          // Основной контент
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Form(
                  key: _formKey,
                  child: Column(

                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [

                      // Заголовок "Регистрация"
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Positioned(
                            top: -10,
                            left: 4,
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                          ),

                          ImageFiltered(
                            imageFilter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                            child: ShaderMask(
                              shaderCallback: (bounds) => const LinearGradient(
                                colors: [AppColors.primaryGradientStart, AppColors.primaryGradientEnd],
                              ).createShader(bounds),
                              child: const Text('Регистрация', style: AppStyles.titleStyle),
                            ),
                          ),
                          const Text('Регистрация', style: AppStyles.titleStyle),
                        ],
                      ),
                      const SizedBox(height: 40),

                      // Поле "Имя"
                      _buildBlurredTextField(
                        controller: _nameController,
                        label: 'Имя',
                        hint: 'Введите ваше имя',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Пожалуйста, введите ваше имя';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Поле "Email"
                      _buildBlurredTextField(
                        controller: _emailController,
                        label: 'e-mail',
                        hint: 'Ваша электронная почта',
                        validator: (value) {
                          if (value == null || !value.contains('@')) {
                            return 'Пожалуйста, введите корректный email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Поле "Пароль"
                      _buildBlurredTextField(
                        controller: _passwordController,
                        label: 'Пароль',
                        hint: '8-16 символов',
                        isObscure: true,
                        validator: (value) {
                          if (value == null || value.length < 8) {
                            return 'Пароль должен быть не менее 8 символов';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Поле "Подтверждение пароля"
                      _buildBlurredTextField(
                        controller: _confirmPasswordController,
                        label: 'Подтверждение пароля',
                        hint: '8-16 символов',
                        isObscure: true,
                        validator: (value) {
                          if (value != _passwordController.text) {
                            return 'Пароли не совпадают';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 40),

                      // Кнопка "Зарегистрироваться"
                      BlocBuilder<AuthBloc, AuthState>(
                        builder: (context, state) {
                          if (state is AuthLoading) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          return _buildRegistrationButton('Зарегистрироваться', _signUp);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

        ],
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
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      ),
      child: Text(
        text,
        style: const TextStyle(color: AppColors.registrationButtonText, fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  // Виджет для поля ввода с эффектом размытия
  Widget _buildBlurredTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool isObscure = false,
    String? Function(String?)? validator,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.background.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(color: AppColors.textFieldBorder, width: 0.5),
          ),
          child: TextFormField( // Заменяем TextField на TextFormField для валидации
            controller: controller,
            obscureText: isObscure,
            style: const TextStyle(color: AppColors.text, fontSize: 16),
            decoration: AppStyles.textFieldDecoration(label: label, hint: hint).copyWith(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            validator: validator,
          ),
        ),
      ),
    );
  }
}