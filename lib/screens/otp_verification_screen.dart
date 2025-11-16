// lib/screens/otp_verification_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/custom_icons.dart';

class OTPVerificationScreen extends StatefulWidget {
  const OTPVerificationScreen({super.key});

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isVerifying = false;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    // Auto-foca no campo ao abrir a tela
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _verifyOTP() async {
    final code = _otpController.text.trim();
    
    if (code.length != 6) {
      _showSnackBar('Digite o código de 6 dígitos', isError: true);
      return;
    }

    // Remove foco do teclado
    _focusNode.unfocus();
    setState(() => _isVerifying = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final success = await authProvider.verifyOTP(code);

      if (mounted) {
        if (success) {
          _showSnackBar('Email verificado com sucesso!', isError: false);
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            Navigator.pushReplacementNamed(context, '/home');
          }
        } else {
          _showSnackBar('Código inválido', isError: true);
          _otpController.clear();
          _focusNode.requestFocus();
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Erro ao verificar código', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<void> _resendOTP() async {
    setState(() => _isResending = true);

    try {
      final authProvider = context.read<AuthProvider>();
      await authProvider.resendOTP();

      if (mounted) {
        _showSnackBar('Novo código enviado!', isError: false);
        _otpController.clear();
        _focusNode.requestFocus();
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Erro ao reenviar código', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  void _showLogoutDialog() {
    final isDark = context.read<ThemeProvider>().isDarkMode;
    final cardColor = isDark ? const Color(0xFF242526) : Colors.white;
    final textColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);
    final secondaryColor = isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Sair sem verificar?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        content: Text(
          'Você precisará verificar seu email novamente no próximo login.',
          style: TextStyle(fontSize: 15, color: secondaryColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancelar',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: secondaryColor,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await context.read<AuthProvider>().signOut();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
            child: const Text(
              'Sair',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFFFA383E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFFA383E) : const Color(0xFF42B72A),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final bgColor = isDark ? const Color(0xFF18191A) : const Color(0xFFF0F2F5);
    final cardColor = isDark ? const Color(0xFF242526) : Colors.white;
    final textColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);
    final secondaryColor = isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B);
    final authProvider = context.watch<AuthProvider>();

    return WillPopScope(
      onWillPop: () async => false,
      child: GestureDetector(
        // Fecha teclado ao tocar fora
        onTap: () {
          _focusNode.unfocus();
        },
        child: Scaffold(
          backgroundColor: bgColor,
          resizeToAvoidBottomInset: true, // Importante para o teclado
          appBar: AppBar(
            backgroundColor: cardColor,
            elevation: 0,
            automaticallyImplyLeading: false,
            title: Text(
              'Verificação',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            actions: [
              IconButton(
                icon: SvgPicture.string(
                  CustomIcons.logout,
                  width: 24,
                  height: 24,
                  colorFilter: const ColorFilter.mode(
                    Color(0xFFFA383E),
                    BlendMode.srcIn,
                  ),
                ),
                onPressed: _showLogoutDialog,
                tooltip: 'Sair',
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                height: 1,
                color: isDark ? const Color(0xFF3E4042) : const Color(0xFFDADADA),
              ),
            ),
          ),
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Ícone
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1877F2).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.mail_outline,
                        size: 40,
                        color: const Color(0xFF1877F2),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Título
                    Text(
                      'Verificação de Email',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Subtítulo
                    Text(
                      'Código enviado para',
                      style: TextStyle(fontSize: 15, color: secondaryColor),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      authProvider.userData?['email'] ?? '',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1877F2),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Campo de entrada único
                    Container(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: TextField(
                        controller: _otpController,
                        focusNode: _focusNode,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 6,
                        enabled: !_isVerifying,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                          letterSpacing: 16,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          counterText: '',
                          hintText: '000000',
                          hintStyle: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: secondaryColor.withOpacity(0.3),
                            letterSpacing: 16,
                          ),
                          filled: true,
                          fillColor: isDark 
                              ? const Color(0xFF3A3B3C) 
                              : const Color(0xFFF0F2F5),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: isDark 
                                  ? const Color(0xFF3E4042) 
                                  : const Color(0xFFDADADA),
                              width: 1,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: Color(0xFF1877F2),
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 20,
                            horizontal: 24,
                          ),
                        ),
                        onChanged: (value) {
                          // Auto-verifica quando completa 6 dígitos
                          if (value.length == 6) {
                            _verifyOTP();
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Info sobre auto-verificação
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1877F2).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 18,
                            color: const Color(0xFF1877F2),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'O código será verificado automaticamente',
                            style: TextStyle(
                              fontSize: 13,
                              color: secondaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Botão de verificar
                    SizedBox(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: ElevatedButton(
                        onPressed: _isVerifying ? null : _verifyOTP,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1877F2),
                          disabledBackgroundColor: isDark 
                              ? const Color(0xFF3A3B3C) 
                              : const Color(0xFFE4E6EB),
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isVerifying
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                'Verificar',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Botão reenviar
                    TextButton(
                      onPressed: _isResending ? null : _resendOTP,
                      child: _isResending
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0xFF1877F2),
                                ),
                              ),
                            )
                          : const Text(
                              'Reenviar código',
                              style: TextStyle(
                                color: Color(0xFF1877F2),
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}