// lib/screens/change_password_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/app_ui_components.dart';
import '../widgets/app_colors.dart';
import 'forgot_password_screen.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({Key? key}) : super(key: key);

  @override
  _ChangePasswordScreenState createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (_currentPasswordController.text.isEmpty ||
        _newPasswordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      AppDialogs.showError(context, 'Erro', 'Preencha todos os campos');
      return;
    }

    if (_newPasswordController.text.length < 6) {
      AppDialogs.showError(context, 'Erro', 'A nova senha deve ter pelo menos 6 caracteres');
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      AppDialogs.showError(context, 'Erro', 'As senhas não coincidem');
      return;
    }

    if (_currentPasswordController.text == _newPasswordController.text) {
      AppDialogs.showError(context, 'Erro', 'A nova senha deve ser diferente da atual');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        throw Exception('Usuário não autenticado');
      }

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _currentPasswordController.text,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(_newPasswordController.text);

      setState(() => _isLoading = false);

      AppDialogs.showSuccess(
        context,
        'Sucesso!',
        'Sua senha foi alterada com sucesso!',
        onClose: () => Navigator.pop(context),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);

      String errorMessage = 'Erro ao alterar senha';

      switch (e.code) {
        case 'wrong-password':
          errorMessage = 'Senha atual incorreta';
          break;
        case 'weak-password':
          errorMessage = 'A nova senha é muito fraca';
          break;
        case 'requires-recent-login':
          errorMessage = 'Por segurança, faça login novamente e tente outra vez';
          break;
        case 'user-mismatch':
          errorMessage = 'Credenciais inválidas';
          break;
        case 'user-not-found':
          errorMessage = 'Usuário não encontrado';
          break;
        case 'invalid-credential':
          errorMessage = 'Senha atual incorreta';
          break;
        case 'too-many-requests':
          errorMessage = 'Muitas tentativas. Tente novamente mais tarde';
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppSecondaryAppBar(title: 'Alterar Senha'),
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20),

                // Ícone central
                Center(
                  child: AppIconCircle(
                    icon: Icons.lock_outline,
                    size: 60,
                  ),
                ),

                SizedBox(height: 32),

                // Card de informação
                AppInfoCard(
                  icon: Icons.info_outline,
                  text: 'Por segurança, você precisa informar sua senha atual',
                ),

                SizedBox(height: 32),

                // Senha Atual
                AppFieldLabel(text: 'Senha Atual'),
                AppPasswordField(
                  controller: _currentPasswordController,
                  hintText: 'Digite sua senha atual',
                ),

                SizedBox(height: 24),

                // Nova Senha
                AppFieldLabel(text: 'Nova Senha'),
                AppPasswordField(
                  controller: _newPasswordController,
                  hintText: 'Mínimo 6 caracteres',
                ),

                SizedBox(height: 24),

                // Confirmar Nova Senha
                AppFieldLabel(text: 'Confirmar Nova Senha'),
                AppPasswordField(
                  controller: _confirmPasswordController,
                  hintText: 'Confirme a nova senha',
                ),

                SizedBox(height: 40),

                // Botão de alterar senha
                AppPrimaryButton(
                  text: 'Alterar Senha',
                  onPressed: _changePassword,
                  isLoading: _isLoading,
                ),

                SizedBox(height: 24),

                // Link para recuperar senha
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ForgotPasswordScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'Esqueceu sua senha?',
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