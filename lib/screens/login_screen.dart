// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _showPassword = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      await authProvider.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao fazer login: ${e.toString()}'),
            backgroundColor: const Color(0xFFFA383E),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final bgColor = isDark ? const Color(0xFF18191A) : const Color(0xFFF0F2F5);
    final cardColor = isDark ? const Color(0xFF242526) : Colors.white;
    final textColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo
                  const Text(
                    'facebook',
                    style: TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1877F2),
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Conecte-se com amigos e o mundo ao seu redor',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Login Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        // Email Field
                        CustomTextField(
                          controller: _emailController,
                          label: 'Email',
                          hintText: 'Email ou telefone',
                          keyboardType: TextInputType.emailAddress,
                          isDark: isDark,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Digite seu email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Password Field
                        CustomTextField(
                          controller: _passwordController,
                          label: 'Senha',
                          hintText: 'Senha',
                          obscureText: !_showPassword,
                          isDark: isDark,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _showPassword ? Icons.visibility_off : Icons.visibility,
                              color: isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B),
                            ),
                            onPressed: () {
                              setState(() => _showPassword = !_showPassword);
                            },
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Digite sua senha';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Login Button
                        CustomButton(
                          text: 'Entrar',
                          onPressed: _handleLogin,
                          isLoading: _isLoading,
                        ),
                        const SizedBox(height: 12),

                        // Forgot Password
                        TextButton(
                          onPressed: () {
                            // TODO: Implementar forgot password
                          },
                          child: const Text(
                            'Esqueceu a senha?',
                            style: TextStyle(
                              color: Color(0xFF1877F2),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Create Account Button
                  CustomButton(
                    text: 'Criar nova conta',
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/signup');
                    },
                    backgroundColor: const Color(0xFF42B72A),
                    height: 44,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}