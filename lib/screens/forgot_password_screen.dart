// lib/screens/forgot_password_screen.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
      _showErrorDialog('Erro', 'Por favor, digite seu email');
      return;
    }

    if (!_isValidEmail(email)) {
      _showErrorDialog('Erro', 'Por favor, digite um email válido');
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
      
      _showErrorDialog('Erro', errorMessage);
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog('Erro', 'Erro inesperado: $e');
    }
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
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
            Icon(CupertinoIcons.mail_solid,
                color: Color(0xFF0095F6), size: 28),
            SizedBox(width: 8),
            Text('Email Enviado!'),
          ],
        ),
        content: Padding(
          padding: EdgeInsets.only(top: 12),
          child: Text(
            'Enviamos um link de recuperação para:\n\n${_emailController.text}\n\n'
            'Verifique sua caixa de entrada e spam.\n\n'
            'O link expira em 1 hora.',
            style: TextStyle(fontSize: 15),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: Text('Entendi'),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
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

      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text('Email Reenviado'),
          content: Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('Um novo email foi enviado com sucesso!'),
          ),
          actions: [
            CupertinoDialogAction(
              child: Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorDialog('Erro', 'Não foi possível reenviar o email');
    }
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
          'Recuperar Senha',
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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 40),
                
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark 
                      ? Color(0xFF1C1C1E) 
                      : Color(0xFFF2F2F7),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    CupertinoIcons.lock_rotation,
                    size: 60,
                    color: isDark ? CupertinoColors.white : CupertinoColors.black,
                  ),
                ),
                
                SizedBox(height: 24),
                
                Text(
                  'Problemas para entrar?',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? CupertinoColors.white : CupertinoColors.black,
                  ),
                ),
                
                SizedBox(height: 12),
                
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Insira seu email e enviaremos um link para você voltar a acessar sua conta.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: CupertinoColors.systemGrey,
                      height: 1.4,
                    ),
                  ),
                ),
                
                SizedBox(height: 32),
                
                if (!_emailSent) ...[
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
                      controller: _emailController,
                      placeholder: 'Email',
                      keyboardType: TextInputType.emailAddress,
                      autocorrect: false,
                      textCapitalization: TextCapitalization.none,
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.transparent),
                      ),
                      style: TextStyle(
                        color: isDark ? CupertinoColors.white : CupertinoColors.black,
                        fontSize: 16,
                      ),
                      placeholderStyle: TextStyle(
                        color: CupertinoColors.systemGrey,
                        fontSize: 16,
                      ),
                      prefix: Padding(
                        padding: EdgeInsets.only(left: 12),
                        child: Icon(
                          CupertinoIcons.mail,
                          color: CupertinoColors.systemGrey,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 24),
                  
                  Container(
                    width: double.infinity,
                    height: 50,
                    child: CupertinoButton(
                      padding: EdgeInsets.zero,
                      onPressed: _isLoading ? null : _sendPasswordResetEmail,
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
                                'Enviar Link de Recuperação',
                                style: TextStyle(
                                  color: CupertinoColors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? Color(0xFF1C1C1E) : CupertinoColors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? Color(0xFF2C2C2E) : Color(0xFFDBDBDB),
                        width: 0.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          CupertinoIcons.check_mark_circled_solid,
                          color: CupertinoColors.systemGreen,
                          size: 60,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Email Enviado!',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark ? CupertinoColors.white : CupertinoColors.black,
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Enviamos um link para:\n${_emailController.text}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: CupertinoColors.systemGrey,
                          ),
                        ),
                        SizedBox(height: 24),
                        Container(
                          width: double.infinity,
                          height: 50,
                          child: CupertinoButton(
                            padding: EdgeInsets.zero,
                            onPressed: _isLoading ? null : _resendEmail,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Color(0xFF0095F6),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              alignment: Alignment.center,
                              child: _isLoading
                                  ? CupertinoActivityIndicator(color: CupertinoColors.white)
                                  : Text(
                                      'Reenviar Email',
                                      style: TextStyle(
                                        color: CupertinoColors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                SizedBox(height: 32),
                
                Container(
                  height: 0.5,
                  color: isDark ? Color(0xFF2C2C2E) : Color(0xFFDBDBDB),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            CupertinoIcons.info_circle,
                            color: Color(0xFF0095F6),
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Dicas',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isDark ? CupertinoColors.white : CupertinoColors.black,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      _buildTipItem(
                        '• Verifique sua caixa de spam',
                        isDark,
                      ),
                      _buildTipItem(
                        '• O link expira em 1 hora',
                        isDark,
                      ),
                      _buildTipItem(
                        '• Use o mesmo dispositivo do email',
                        isDark,
                      ),
                      _buildTipItem(
                        '• Verifique se o email está correto',
                        isDark,
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 32),
                
                Center(
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => Navigator.pop(context),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.arrow_left,
                          color: Color(0xFF0095F6),
                          size: 18,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Voltar para Login',
                          style: TextStyle(
                            color: Color(0xFF0095F6),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
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

  Widget _buildTipItem(String text, bool isDark) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          color: isDark ? CupertinoColors.systemGrey : CupertinoColors.systemGrey,
          height: 1.4,
        ),
      ),
    );
  }
}