import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:email_validator/email_validator.dart';
import '../services/auth_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> with TickerProviderStateMixin {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  bool _isLoading = false;
  bool _showPassword = false;
  String _errorMessage = '';
  String _successMessage = '';

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(duration: const Duration(milliseconds: 900), vsync: this);
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _animController, curve: Curves.easeIn));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
      _successMessage = '';
    });
    HapticFeedback.lightImpact();
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) setState(() => _errorMessage = '');
    });
  }

  void _showSuccess(String message) {
    setState(() {
      _successMessage = message;
      _errorMessage = '';
    });
    HapticFeedback.lightImpact();
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() => _isLoading = true);

    try {
      // Ajusta conforme tua AuthService.register/ createUser
      final result = await AuthService.register(name: name, email: email, password: password);

      if (result.success) {
        _showSuccess(result.message);
        await Future.delayed(const Duration(milliseconds: 1000));
        if (mounted) Navigator.pushReplacementNamed(context, '/main');
      } else {
        _showError(result.message);
      }
    } catch (e) {
      _showError('Erro ao cadastrar. Tente novamente.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openSignIn() {
    Navigator.pushReplacementNamed(context, '/sign_in');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [
            Color(0xFF1A1A1A),
            Color(0xFF2D2D2D),
          ]),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 36),
                  _buildLogo(),
                  const SizedBox(height: 18),
                  _buildForm(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        SizedBox(
          width: 110,
          height: 110,
          child: Image.asset(
            'mipmap/ic_launcher.png',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(CupertinoIcons.person_crop_circle, size: 48, color: Color(0xFF007AFF));
            },
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Cadastro',
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 8),
        Text('Crie sua conta', style: TextStyle(color: Colors.white.withOpacity(0.75))),
      ],
    );
  }

  // Sem container decorado — apenas Form
  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          if (_errorMessage.isNotEmpty) _messageBox(_errorMessage, isError: true),
          if (_successMessage.isNotEmpty) _messageBox(_successMessage, isError: false),
          const SizedBox(height: 8),
          CustomTextField(
            controller: _nameController,
            label: 'Nome',
            hint: 'Seu nome completo',
            prefixIcon: CupertinoIcons.person,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Nome é obrigatório';
              return null;
            },
          ),
          const SizedBox(height: 12),
          CustomTextField(
            controller: _emailController,
            label: 'Email',
            hint: 'Digite seu email',
            prefixIcon: CupertinoIcons.mail,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Email é obrigatório';
              if (!EmailValidator.validate(value)) return 'Email inválido';
              return null;
            },
          ),
          const SizedBox(height: 12),
          CustomTextField(
            controller: _passwordController,
            label: 'Palavra-passe',
            hint: 'Crie uma palavra-passe',
            prefixIcon: CupertinoIcons.lock,
            obscureText: !_showPassword,
            suffixIcon: CupertinoIcons.eye,
            onSuffixTap: () => setState(() => _showPassword = !_showPassword),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Palavra-passe é obrigatória';
              if (value.length < 6) return 'Palavra-passe deve ter ao menos 6 caracteres';
              return null;
            },
          ),
          const SizedBox(height: 12),
          CustomTextField(
            controller: _passwordConfirmController,
            label: 'Confirmar Palavra-passe',
            hint: 'Repita a palavra-passe',
            prefixIcon: CupertinoIcons.lock,
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Confirmação é obrigatória';
              if (value != _passwordController.text) return 'As senhas não coincidem';
              return null;
            },
          ),
          const SizedBox(height: 18),
          CustomButton(text: 'Cadastro', onPressed: _isLoading ? null : _handleSignUp, isLoading: _isLoading),
          const SizedBox(height: 10),
          TextButton(onPressed: _openSignIn, child: const Text('Entrar', style: TextStyle(fontSize: 16))),
        ],
      ),
    );
  }

  Widget _messageBox(String text, {required bool isError}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: (isError ? const Color(0xFFFF3B30) : const Color(0xFF34C759)).withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: (isError ? const Color(0xFFFF3B30) : const Color(0xFF34C759)).withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(isError ? CupertinoIcons.exclamationmark_triangle_fill : CupertinoIcons.checkmark_circle_fill,
              color: isError ? const Color(0xFFFF3B30) : const Color(0xFF34C759), size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(color: (isError ? const Color(0xFFFF3B30) : const Color(0xFF34C759))))),
        ],
      ),
    );
  }
}