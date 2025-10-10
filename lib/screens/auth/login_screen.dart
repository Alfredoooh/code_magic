import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'signup_screen.dart';
import '../../services/auth_service.dart';
import '../../widgets/design_system.dart';
import '../../localization/app_localizations.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    // Remove o foco do teclado
    FocusScope.of(context).unfocus();

    setState(() => _isLoading = true);

    try {
      await AuthService().login(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        context: context,
      );

      // Login bem-sucedido - não precisa navegar manualmente
      // O StreamBuilder no main.dart já vai redirecionar automaticamente
      
    } on FirebaseAuthException catch (e) {
      // Tratamento específico de erros do Firebase
      String errorMessage;
      
      switch (e.code) {
        case 'user-not-found':
          errorMessage = AppLocalizations.of(context)!.translate('user_not_found') ?? 
                        'Usuário não encontrado';
          break;
        case 'wrong-password':
          errorMessage = AppLocalizations.of(context)!.translate('wrong_password') ?? 
                        'Senha incorreta';
          break;
        case 'invalid-email':
          errorMessage = AppLocalizations.of(context)!.translate('invalid_email') ?? 
                        'Email inválido';
          break;
        case 'user-disabled':
          errorMessage = AppLocalizations.of(context)!.translate('user_disabled') ?? 
                        'Usuário desabilitado';
          break;
        case 'too-many-requests':
          errorMessage = AppLocalizations.of(context)!.translate('too_many_requests') ?? 
                        'Muitas tentativas. Aguarde um momento';
          break;
        case 'network-request-failed':
          errorMessage = AppLocalizations.of(context)!.translate('network_error') ?? 
                        'Erro de conexão. Verifique sua internet';
          break;
        default:
          errorMessage = AppLocalizations.of(context)!.translate('auth_error') ?? 
                        'Erro de autenticação: ${e.message}';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: danger,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      // Captura outros erros (API externa, verificação de sessão, etc)
      if (mounted) {
        String errorMessage = e.toString();
        
        // Remove o "Exception: " do início da mensagem se existir
        if (errorMessage.startsWith('Exception: ')) {
          errorMessage = errorMessage.substring(11);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: danger,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: accentGradient),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock_outline_rounded, size: 80, color: accentPrimary),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context)!.translate('login')!,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 24),
                      CustomTextField(
                        controller: _emailController,
                        label: AppLocalizations.of(context)!.translate('email')!,
                        icon: Icons.email_rounded,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        enabled: !_isLoading,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return AppLocalizations.of(context)!.translate('enter_email')!;
                          }
                          if (!value.contains('@')) {
                            return AppLocalizations.of(context)!.translate('invalid_email')!;
                          }
                          // Validação adicional de email
                          final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                          if (!emailRegex.hasMatch(value.trim())) {
                            return AppLocalizations.of(context)!.translate('invalid_email')!;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _passwordController,
                        label: AppLocalizations.of(context)!.translate('password')!,
                        icon: Icons.lock_rounded,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        enabled: !_isLoading,
                        onFieldSubmitted: (_) => _login(),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return AppLocalizations.of(context)!.translate('enter_password')!;
                          }
                          if (value.length < 6) {
                            return AppLocalizations.of(context)!.translate('password_too_short')!;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      CustomButton(
                        text: _isLoading ? '' : AppLocalizations.of(context)!.translate('login')!,
                        isLoading: _isLoading,
                        onPressed: _isLoading ? null : _login,
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: _isLoading ? null : () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => SignupScreen()),
                          );
                        },
                        child: Text(
                          AppLocalizations.of(context)!.translate('create_account')!,
                          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            color: _isLoading ? Colors.grey : accentPrimary,
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
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}