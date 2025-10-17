import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'forgot_password_screen.dart';

class AuthScreen extends StatefulWidget {
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      _showErrorDialog('Campos Obrigatórios', 'Por favor, preencha o email e a senha para continuar.');
      return;
    }

    if (!_isLogin && _nameController.text.trim().isEmpty) {
      _showErrorDialog('Nome Obrigatório', 'Por favor, digite seu nome completo para criar a conta.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        // Login
        final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // Verifica dados do usuário
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(credential.user!.uid)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data()!;

          if (userData['access'] == false) {
            await FirebaseAuth.instance.signOut();
            _showErrorDialog(
              'Acesso Negado',
              'Sua conta foi desativada. Entre em contato com o suporte para mais informações.'
            );
            setState(() => _isLoading = false);
            return;
          }

          if (userData['expiration_date'] != null) {
            final expDate = DateTime.parse(userData['expiration_date']);
            if (expDate.isBefore(DateTime.now())) {
              await FirebaseAuth.instance.signOut();
              _showErrorDialog(
                'Conta Expirada',
                'Sua assinatura expirou. Renove para continuar usando o serviço.'
              );
              setState(() => _isLoading = false);
              return;
            }
          }
        }

        // Login bem-sucedido - NÃO reseta o estado de loading
        // O StreamBuilder do main.dart vai detectar a mudança e navegar automaticamente
        // Importante: não chamar setState aqui para evitar rebuild que pode causar logout

      } else {
        // Registro
        final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        await userCredential.user?.updateDisplayName(_nameController.text.trim());

        await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
          'id': userCredential.user!.uid,
          'username': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'full_name': _nameController.text.trim(),
          'created_at': DateTime.now().toIso8601String(),
          'profile_image': '',
          'role': 'user',
          'admin': false,
          'access': true,
          'blocked': false,
          'theme': 'dark',
          'language': 'pt',
          'pro': false,
          'tokens': 50,
          'expiration_date': DateTime.now().add(Duration(days: 365)).toIso8601String(),
          'phone': '',
          'birth_date': '',
        });

        // Registro bem-sucedido - mesmo comportamento do login
      }

      // IMPORTANTE: Não fazer setState após login/registro bem-sucedido
      // Deixar o Firebase Auth gerenciar o estado

    } on FirebaseAuthException catch (e) {
      String title = 'Erro de Autenticação';
      String message = '';

      if (e.code == 'user-not-found') {
        title = 'Usuário Não Encontrado';
        message = 'Não encontramos uma conta com este email. Verifique o email digitado ou crie uma nova conta.';
      } else if (e.code == 'wrong-password') {
        title = 'Senha Incorreta';
        message = 'A senha está incorreta. Verifique sua senha ou use a opção "Esqueceu a palavra-passe?" para recuperá-la.';
      } else if (e.code == 'invalid-credential') {
        title = 'Credenciais Inválidas';
        message = 'Email ou senha incorretos. Verifique seus dados e tente novamente.';
      } else if (e.code == 'email-already-in-use') {
        title = 'Email Já Cadastrado';
        message = 'Este email já está sendo usado por outra conta. Tente fazer login ou use outro email.';
      } else if (e.code == 'weak-password') {
        title = 'Senha Fraca';
        message = 'A senha deve ter no mínimo 6 caracteres. Escolha uma senha mais forte com letras e números.';
      } else if (e.code == 'invalid-email') {
        title = 'Email Inválido';
        message = 'O formato do email está incorreto. Verifique e digite um email válido.';
      } else if (e.code == 'network-request-failed') {
        title = 'Erro de Conexão';
        message = 'Não foi possível conectar ao servidor. Verifique sua conexão com a internet e tente novamente.';
      } else if (e.code == 'too-many-requests') {
        title = 'Muitas Tentativas';
        message = 'Muitas tentativas de login. Por segurança, aguarde alguns minutos antes de tentar novamente.';
      } else {
        title = 'Erro Inesperado';
        message = 'Ocorreu um erro ao processar sua solicitação. Tente novamente mais tarde.';
      }

      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorDialog(title, message);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorDialog('Erro', 'Ocorreu um erro inesperado. Por favor, tente novamente.');
      }
    }
  }

  void _showErrorDialog(String title, String message) {
    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => CupertinoAlertDialog(
        title: Text(
          title,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text(
            message,
            style: TextStyle(fontSize: 13),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: Text(
              'Entendi',
              style: TextStyle(
                color: Color(0xFFFF444F),
                fontWeight: FontWeight.w600,
              ),
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _navigateToForgotPassword() {
    Navigator.of(context).push(
      CupertinoPageRoute(builder: (context) => ForgotPasswordScreen()),
    );
  }

  void _navigateToLearn() {
    Navigator.of(context).push(
      CupertinoPageRoute(builder: (context) => LearnScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.of(context).platformBrightness;
    final isDark = brightness == Brightness.dark;

    return CupertinoPageScaffold(
      backgroundColor: isDark ? Color(0xFF000000) : Color(0xFFF2F2F7),
      resizeToAvoidBottomInset: true,
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: CustomScrollView(
            controller: _scrollController,
            physics: BouncingScrollPhysics(),
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            CupertinoButton(
                              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              onPressed: _navigateToLearn,
                              child: Text(
                                'Aprender',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFFF444F),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      Spacer(),

                      // Logo do app
                      Image.asset(
                        'assets/icon/icon.png',
                        width: 100,
                        height: 100,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            CupertinoIcons.app_fill,
                            size: 100,
                            color: Color(0xFFFF444F),
                          );
                        },
                      ),

                      SizedBox(height: 40),

                      Text(
                        _isLogin ? 'Entrar' : 'Criar Conta',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                          color: isDark ? CupertinoColors.white : CupertinoColors.black,
                          letterSpacing: -0.5,
                        ),
                      ),

                      SizedBox(height: 40),

                      if (!_isLogin) ...[
                        _buildInputField(
                          controller: _nameController,
                          placeholder: 'Nome',
                          isDark: isDark,
                        ),
                        SizedBox(height: 16),
                      ],

                      _buildInputField(
                        controller: _emailController,
                        placeholder: 'Email',
                        keyboardType: TextInputType.emailAddress,
                        isDark: isDark,
                      ),

                      SizedBox(height: 16),

                      _buildInputField(
                        controller: _passwordController,
                        placeholder: 'Senha',
                        obscureText: _obscurePassword,
                        isDark: isDark,
                        suffixIcon: CupertinoButton(
                          padding: EdgeInsets.zero,
                          minSize: 0,
                          onPressed: () {
                            setState(() => _obscurePassword = !_obscurePassword);
                          },
                          child: Icon(
                            _obscurePassword
                                ? CupertinoIcons.eye_fill
                                : CupertinoIcons.eye_slash_fill,
                            color: CupertinoColors.systemGrey,
                            size: 22,
                          ),
                        ),
                      ),

                      if (_isLogin) ...[
                        SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: CupertinoButton(
                            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                            onPressed: _navigateToForgotPassword,
                            child: Text(
                              'Esqueceu a palavra-passe?',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFFFF444F),
                              ),
                            ),
                          ),
                        ),
                      ],

                      SizedBox(height: 32),

                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: CupertinoButton(
                          padding: EdgeInsets.zero,
                          color: Color(0xFFFF444F),
                          borderRadius: BorderRadius.circular(14),
                          onPressed: _isLoading ? null : _submit,
                          child: _isLoading
                              ? CupertinoActivityIndicator(color: CupertinoColors.white)
                              : Text(
                                  _isLogin ? 'Entrar' : 'Criar Conta',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    color: CupertinoColors.white,
                                  ),
                                ),
                        ),
                      ),

                      SizedBox(height: 20),

                      CupertinoButton(
                        onPressed: () => setState(() => _isLogin = !_isLogin),
                        child: Text(
                          _isLogin ? 'Não tem conta? Criar uma' : 'Já tem conta? Entrar',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFFF444F),
                          ),
                        ),
                      ),

                      Spacer(),

                      Padding(
                        padding: EdgeInsets.only(bottom: 24, top: 20),
                        child: Text(
                          'from nexa',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: CupertinoColors.systemGrey,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String placeholder,
    required bool isDark,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1C1C1E) : CupertinoColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Color(0xFF2C2C2E) : Color(0xFFE5E5EA),
          width: 1,
        ),
      ),
      child: CupertinoTextField(
        controller: controller,
        placeholder: placeholder,
        keyboardType: keyboardType,
        obscureText: obscureText,
        style: TextStyle(
          fontSize: 17,
          color: isDark ? CupertinoColors.white : CupertinoColors.black,
        ),
        placeholderStyle: TextStyle(
          fontSize: 17,
          color: CupertinoColors.systemGrey,
        ),
        decoration: BoxDecoration(
          color: Colors.transparent,
        ),
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        suffix: suffixIcon != null
            ? Padding(
                padding: EdgeInsets.only(right: 12),
                child: suffixIcon,
              )
            : null,
      ),
    );
  }
}

class LearnScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.of(context).platformBrightness;
    final isDark = brightness == Brightness.dark;

    return CupertinoPageScaffold(
      backgroundColor: isDark ? Color(0xFF000000) : Color(0xFFF2F2F7),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: (isDark ? Color(0xFF1C1C1E) : CupertinoColors.white).withOpacity(0.95),
        border: Border(
          bottom: BorderSide(
            color: (isDark ? Color(0xFF2C2C2E) : Color(0xFFE5E5EA)).withOpacity(0.5),
            width: 0.5,
          ),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CupertinoIcons.back,
                color: Color(0xFFFF444F),
                size: 28,
              ),
              SizedBox(width: 4),
              Text(
                'Voltar',
                style: TextStyle(
                  color: Color(0xFFFF444F),
                  fontSize: 17,
                ),
              ),
            ],
          ),
          onPressed: () => Navigator.pop(context),
        ),
        middle: Text(
          'Aprender',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: isDark ? CupertinoColors.white : CupertinoColors.black,
          ),
        ),
      ),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.book_fill,
                  size: 80,
                  color: Color(0xFFFF444F).withOpacity(0.5),
                ),
                SizedBox(height: 24),
                Text(
                  'Conteúdo Educacional',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: isDark ? CupertinoColors.white : CupertinoColors.black,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Em breve você terá acesso a conteúdos educacionais exclusivos.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    color: CupertinoColors.systemGrey,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}