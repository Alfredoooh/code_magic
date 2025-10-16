// lib/screens/change_password_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    // Validações
    if (_currentPasswordController.text.isEmpty ||
        _newPasswordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      _showErrorDialog('Erro', 'Preencha todos os campos');
      return;
    }

    if (_newPasswordController.text.length < 6) {
      _showErrorDialog('Erro', 'A nova senha deve ter pelo menos 6 caracteres');
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showErrorDialog('Erro', 'As senhas não coincidem');
      return;
    }

    if (_currentPasswordController.text == _newPasswordController.text) {
      _showErrorDialog('Erro', 'A nova senha deve ser diferente da atual');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) {
        throw Exception('Usuário não autenticado');
      }

      // Reautenticar usuário com senha atual
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _currentPasswordController.text,
      );

      await user.reauthenticateWithCredential(credential);

      // Atualizar para nova senha
      await user.updatePassword(_newPasswordController.text);

      setState(() => _isLoading = false);

      // Mostrar sucesso
      _showSuccessDialog();
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
      
      _showErrorDialog('Erro', errorMessage);
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog('Erro', 'Erro inesperado: $e');
    }
  }

  void _showErrorDialog(String title, String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text(message),
        ),
        actions: [
          CupertinoDialogAction(
            child: Text('OK', style: TextStyle(color: Color(0xFF0095F6))),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CupertinoAlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.check_mark_circled_solid,
                color: CupertinoColors.systemGreen, size: 28),
            SizedBox(width: 8),
            Text('Sucesso!'),
          ],
        ),
        content: Padding(
          padding: EdgeInsets.only(top: 12),
          child: Text(
            'Sua senha foi alterada com sucesso!',
            style: TextStyle(fontSize: 15),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: Text('OK'),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CupertinoPageScaffold(
      backgroundColor: isDark ? Color(0xFF000000) : Color(0xFFFAFAFA),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: isDark ? Color(0xFF000000) : CupertinoColors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Color(0xFF1C1C1E) : Color(0xFFDBDBDB),
            width: 0.5,
          ),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(
            CupertinoIcons.back,
            color: isDark ? CupertinoColors.white : CupertinoColors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        middle: Text(
          'Alterar Senha',
          style: TextStyle(
            color: isDark ? CupertinoColors.white : CupertinoColors.black,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      child: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            physics: BouncingScrollPhysics(),
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20),
                
                Center(
                  child: Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark 
                        ? Color(0xFF1C1C1E) 
                        : Color(0xFFF2F2F7),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      CupertinoIcons.lock_shield,
                      size: 60,
                      color: isDark ? CupertinoColors.white : CupertinoColors.black,
                    ),
                  ),
                ),
                
                SizedBox(height: 32),
                
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? Color(0xFF1C1C1E) : CupertinoColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Color(0xFF2C2C2E) : Color(0xFFDBDBDB),
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.info_circle,
                        color: Color(0xFF0095F6),
                        size: 24,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Por segurança, você precisa informar sua senha atual',
                          style: TextStyle(
                            color: isDark 
                              ? CupertinoColors.white 
                              : CupertinoColors.black,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 32),
                
                Text(
                  'Senha Atual',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? CupertinoColors.white : CupertinoColors.black,
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? Color(0xFF1C1C1E) : CupertinoColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Color(0xFF2C2C2E) : Color(0xFFDBDBDB),
                      width: 0.5,
                    ),
                  ),
                  child: CupertinoTextField(
                    controller: _currentPasswordController,
                    placeholder: 'Digite sua senha atual',
                    obscureText: _obscureCurrentPassword,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.transparent),
                    ),
                    style: TextStyle(
                      color: isDark ? CupertinoColors.white : CupertinoColors.black,
                    ),
                    placeholderStyle: TextStyle(
                      color: CupertinoColors.systemGrey,
                    ),
                    suffix: CupertinoButton(
                      padding: EdgeInsets.only(right: 12),
                      minSize: 0,
                      child: Icon(
                        _obscureCurrentPassword
                            ? CupertinoIcons.eye_slash
                            : CupertinoIcons.eye,
                        color: CupertinoColors.systemGrey,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() => _obscureCurrentPassword = !_obscureCurrentPassword);
                      },
                    ),
                  ),
                ),
                
                SizedBox(height: 24),
                
                Text(
                  'Nova Senha',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? CupertinoColors.white : CupertinoColors.black,
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? Color(0xFF1C1C1E) : CupertinoColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Color(0xFF2C2C2E) : Color(0xFFDBDBDB),
                      width: 0.5,
                    ),
                  ),
                  child: CupertinoTextField(
                    controller: _newPasswordController,
                    placeholder: 'Mínimo 6 caracteres',
                    obscureText: _obscureNewPassword,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.transparent),
                    ),
                    style: TextStyle(
                      color: isDark ? CupertinoColors.white : CupertinoColors.black,
                    ),
                    placeholderStyle: TextStyle(
                      color: CupertinoColors.systemGrey,
                    ),
                    suffix: CupertinoButton(
                      padding: EdgeInsets.only(right: 12),
                      minSize: 0,
                      child: Icon(
                        _obscureNewPassword
                            ? CupertinoIcons.eye_slash
                            : CupertinoIcons.eye,
                        color: CupertinoColors.systemGrey,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() => _obscureNewPassword = !_obscureNewPassword);
                      },
                    ),
                  ),
                ),
                
                SizedBox(height: 24),
                
                Text(
                  'Confirmar Nova Senha',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? CupertinoColors.white : CupertinoColors.black,
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? Color(0xFF1C1C1E) : CupertinoColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Color(0xFF2C2C2E) : Color(0xFFDBDBDB),
                      width: 0.5,
                    ),
                  ),
                  child: CupertinoTextField(
                    controller: _confirmPasswordController,
                    placeholder: 'Confirme a nova senha',
                    obscureText: _obscureConfirmPassword,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.transparent),
                    ),
                    style: TextStyle(
                      color: isDark ? CupertinoColors.white : CupertinoColors.black,
                    ),
                    placeholderStyle: TextStyle(
                      color: CupertinoColors.systemGrey,
                    ),
                    suffix: CupertinoButton(
                      padding: EdgeInsets.only(right: 12),
                      minSize: 0,
                      child: Icon(
                        _obscureConfirmPassword
                            ? CupertinoIcons.eye_slash
                            : CupertinoIcons.eye,
                        color: CupertinoColors.systemGrey,
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                      },
                    ),
                  ),
                ),
                
                SizedBox(height: 40),
                
                Container(
                  width: double.infinity,
                  height: 50,
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _isLoading ? null : _changePassword,
                    child: Container(
                      decoration: BoxDecoration(
                        color: _isLoading 
                          ? CupertinoColors.systemGrey 
                          : Color(0xFF0095F6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignment: Alignment.center,
                      child: _isLoading
                          ? CupertinoActivityIndicator(color: CupertinoColors.white)
                          : Text(
                              'Alterar Senha',
                              style: TextStyle(
                                color: CupertinoColors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ),
                
                SizedBox(height: 24),
                
                Center(
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (context) => ForgotPasswordScreen(),
                        ),
                      );
                    },
                    child: Text(
                      'Esqueceu sua senha?',
                      style: TextStyle(
                        color: Color(0xFF0095F6),
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