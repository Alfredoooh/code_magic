import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _nicknameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('As senhas não coincidem')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      await authProvider.signUpWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
        _nameController.text.trim(),
        _nicknameController.text.trim(),
      );

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao criar conta: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5),
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
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFDB52A), Color(0xFFFFD700)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFDB52A).withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'C',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Title
                  Text(
                    'Vamos começar',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Crie sua conta gratuitamente',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Name Field
                  CustomTextField(
                    controller: _nameController,
                    label: 'Nome',
                    hintText: 'Seu nome completo',
                    prefixIcon: Icons.person_outline,
                    isDark: isDark,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Digite seu nome';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Nickname Field
                  CustomTextField(
                    controller: _nicknameController,
                    label: 'Nome de usuário',
                    hintText: '@username',
                    prefixIcon: Icons.alternate_email,
                    isDark: isDark,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Digite seu nome de usuário';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Email Field
                  CustomTextField(
                    controller: _emailController,
                    label: 'Email',
                    hintText: 'seu@email.com',
                    prefixIcon: Icons.mail_outline,
                    keyboardType: TextInputType.emailAddress,
                    isDark: isDark,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Digite seu email';
                      }
                      if (!value.contains('@')) {
                        return 'Email inválido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password Field
                  CustomTextField(
                    controller: _passwordController,
                    label: 'Senha',
                    hintText: '••••••••',
                    prefixIcon: Icons.lock_outline,
                    obscureText: !_showPassword,
                    isDark: isDark,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showPassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() => _showPassword = !_showPassword);
                      },
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Digite sua senha';
                      }
                      if (value.length < 6) {
                        return 'Senha deve ter no mínimo 6 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Confirm Password Field
                  CustomTextField(
                    controller: _confirmPasswordController,
                    label: 'Confirmar senha',
                    hintText: '••••••••',
                    prefixIcon: Icons.lock_outline,
                    obscureText: !_showConfirmPassword,
                    isDark: isDark,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showConfirmPassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() => _showConfirmPassword = !_showConfirmPassword);
                      },
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Confirme sua senha';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),

                  // Sign Up Button
                  CustomButton(
                    text: 'Criar conta',
                    onPressed: _handleSignUp,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: 24),

                  // Login Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Já tem uma conta? ',
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                        child: const Text(
                          'Entrar',
                          style: TextStyle(
                            color: Color(0xFFFDB52A),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Phone Auth Link
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/phone-auth');
                    },
                    child: Text(
                      'Cadastrar com número de telefone',
                      style: TextStyle(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
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