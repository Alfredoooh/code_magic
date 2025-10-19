import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/app_ui_components.dart';
import '../widgets/app_colors.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendPasswordResetEmail() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      AppDialogs.showError(context, 'Erro', 'Por favor, digite seu email');
      return;
    }

    if (!_isValidEmail(email)) {
      AppDialogs.showError(context, 'Erro', 'Por favor, digite um email válido');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      setState(() {
        _isLoading = false;
        _emailSent = true;
      });

      _showSuccessDialog();
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);

      String errorMessage = 'Erro ao enviar email';

      switch (e.code) {
        case 'user-not-found':
          errorMessage = 'Não existe conta cadastrada com este email';
          break;
        case 'invalid-email':
          errorMessage = 'Email inválido';
          break;
        case 'too-many-requests':
          errorMessage = 'Muitas tentativas. Aguarde alguns minutos e tente novamente';
          break;
        case 'network-request-failed':
          errorMessage = 'Erro de conexão. Verifique sua internet';
          break;
        default:
          errorMessage = 'Erro: ${e.message}';
      }

      AppDialogs.showError(context, 'Erro', errorMessage);
    } catch (e) {
      setState(() => _isLoading = false);
      AppDialogs.showError(context, 'Erro', 'Erro inesperado. Tente novamente.');
    }
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  void _showSuccessDialog() {
    AppDialogs.showSuccess(
      context,
      'Email Enviado!',
      'Enviamos um link de recuperação para:\n\n${_emailController.text}\n\n'
      'Verifique sua caixa de entrada e spam.\n\n'
      'O link expira em 1 hora.',
    );
  }

  Future<void> _resendEmail() async {
    if (_emailController.text.trim().isEmpty) return;

    setState(() {
      _emailSent = false;
      _isLoading = true;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );

      setState(() {
        _isLoading = false;
        _emailSent = true;
      });

      AppDialogs.showSuccess(
        context,
        'Email Reenviado',
        'Um novo email foi enviado com sucesso!',
      );
    } catch (e) {
      setState(() => _isLoading = false);
      AppDialogs.showError(context, 'Erro', 'Não foi possível reenviar o email');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppSecondaryAppBar(
        title: 'Recuperar Senha',
      ),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 40),

                AppIconCircle(
                  icon: Icons.lock_reset,
                  size: 60,
                  iconColor: AppColors.primary,
                ),

                SizedBox(height: 24),

                AppSectionTitle(
                  text: 'Problemas para entrar?',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),

                SizedBox(height: 12),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Insira seu email e enviaremos um link para você voltar a acessar sua conta.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      height: 1.4,
                    ),
                  ),
                ),

                SizedBox(height: 32),

                if (!_emailSent) ...[
                  AppTextField(
                    controller: _emailController,
                    hintText: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icon(
                      Icons.mail_outline,
                      color: Colors.grey,
                    ),
                  ),

                  SizedBox(height: 24),

                  AppPrimaryButton(
                    text: 'Enviar Link de Recuperação',
                    onPressed: _sendPasswordResetEmail,
                    isLoading: _isLoading,
                  ),
                ] else ...[
                  AppCard(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 60,
                          ),
                          SizedBox(height: 16),
                          AppSectionTitle(
                            text: 'Email Enviado!',
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Enviamos um link para:\n${_emailController.text}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                          SizedBox(height: 24),
                          AppPrimaryButton(
                            text: 'Reenviar Email',
                            onPressed: _resendEmail,
                            isLoading: _isLoading,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                SizedBox(height: 32),

                Divider(
                  color: isDark ? AppColors.darkSeparator : AppColors.separator,
                  thickness: 0.5,
                ),

                SizedBox(height: 32),

                AppInfoCard(
                  icon: Icons.info_outline,
                  text: 'Dicas Importantes:\n\n'
                      '• Verifique sua caixa de spam/lixo eletrônico\n'
                      '• O link expira em 1 hora após o envio\n'
                      '• Use o mesmo navegador para abrir o link\n'
                      '• Verifique se digitou o email corretamente\n'
                      '• Aguarde alguns minutos para o email chegar',
                ),

                SizedBox(height: 32),

                Center(
                  child: TextButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.arrow_back,
                      color: AppColors.primary,
                      size: 18,
                    ),
                    label: Text(
                      'Voltar para Login',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}