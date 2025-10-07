import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/theme_service.dart';
import 'signup_modal.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  bool _isLoading = false;
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showErrorDialog(String title, String message) {
    HapticFeedback.lightImpact();
    final bgColor = ThemeService.currentTheme == AppTheme.deepDark
        ? const Color(0xFF000000)
        : ThemeService.currentTheme == AppTheme.dark
            ? const Color(0xFF1C1C1E)
            : const Color(0xFFFFFFFF);
    final textColor = ThemeService.currentTheme == AppTheme.light
        ? const Color(0xFF000000)
        : const Color(0xFFFFFFFF);

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (context) => Dialog(
        backgroundColor: bgColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
              child: Column(
                children: [
                  const Icon(Icons.close, color: Color(0xFFFF3B30), size: 52),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: TextStyle(
                      color: textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    message,
                    style: TextStyle(
                      color: textColor.withOpacity(0.65),
                      fontSize: 14,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: textColor.withOpacity(0.1),
                    width: 0.5,
                  ),
                ),
              ),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(
                      color: Color(0xFF1877F2),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
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

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() => _isLoading = true);

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Criar documento de usuário se não existir
      final userDoc = FirebaseFirestore.instance.collection('users').doc(credential.user!.uid);
      final docSnapshot = await userDoc.get();

      if (!docSnapshot.exists) {
        await userDoc.set({
          'email': email,
          'displayName': credential.user!.displayName ?? email.split('@')[0],
          'createdAt': FieldValue.serverTimestamp(),
          'theme': 'dark',
          'lastActive': FieldValue.serverTimestamp(),
        });
      } else {
        await userDoc.update({
          'lastActive': FieldValue.serverTimestamp(),
        });
      }

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/main');
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Erro ao autenticar';

      if (e.code == 'user-not-found') {
        message = 'Usuário não encontrado';
      } else if (e.code == 'wrong-password') {
        message = 'Senha incorreta';
      } else if (e.code == 'invalid-email') {
        message = 'Email inválido';
      }

      _showErrorDialog('Login Failed', message);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _openSignUpModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SignUpModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = ThemeService.currentTheme == AppTheme.deepDark
        ? const Color(0xFF000000)
        : ThemeService.currentTheme == AppTheme.dark
            ? const Color(0xFF1C1C1E)
            : const Color(0xFFF2F2F7);
    
    final textColor = ThemeService.currentTheme == AppTheme.light
        ? const Color(0xFF000000)
        : const Color(0xFFFFFFFF);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            child: Container(
              height: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  _buildLogo(textColor),
                  const SizedBox(height: 60),
                  _buildForm(textColor),
                  const SizedBox(height: 24),
                  _buildSignUpButton(),
                  const Spacer(),
                  _buildFooter(textColor),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(Color textColor) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: const Color(0xFF1877F2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Icon(
            Icons.chat_bubble_rounded,
            size: 40,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Easify',
          style: TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.w700,
            color: textColor,
            letterSpacing: -1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildForm(Color textColor) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          _buildTextField(
            controller: _emailController,
            hint: 'Mobile number or email address',
            keyboardType: TextInputType.emailAddress,
            textColor: textColor,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _passwordController,
            hint: 'Password',
            obscureText: !_showPassword,
            textColor: textColor,
            suffixIcon: IconButton(
              icon: Icon(
                _showPassword ? Icons.visibility : Icons.visibility_off,
                color: textColor.withOpacity(0.5),
                size: 22,
              ),
              onPressed: () {
                setState(() => _showPassword = !_showPassword);
              },
            ),
          ),
          const SizedBox(height: 24),
          _buildLoginButton(),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () {},
            child: Text(
              'Forgotten Password?',
              style: TextStyle(
                color: textColor.withOpacity(0.9),
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required Color textColor,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: textColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textColor.withOpacity(0.15)),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: TextStyle(fontSize: 16, color: textColor.withOpacity(0.9)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: textColor.withOpacity(0.4),
            fontSize: 16,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          suffixIcon: suffixIcon,
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1877F2),
          disabledBackgroundColor: const Color(0xFF1877F2).withOpacity(0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Log In',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
      ),
    );
  }

  Widget _buildSignUpButton() {
    return GestureDetector(
      onTap: _openSignUpModal,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF1877F2), width: 1.5),
          borderRadius: BorderRadius.circular(26),
        ),
        child: const Center(
          child: Text(
            'Create new account',
            style: TextStyle(
              color: Color(0xFF1877F2),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(Color textColor) {
    return Text(
      'Easify',
      style: TextStyle(
        color: textColor.withOpacity(0.3),
        fontSize: 13,
      ),
    );
  }
}
