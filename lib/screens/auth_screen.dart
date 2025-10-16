import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'forgot_password_screen.dart'; // Import da tela existente

class AuthScreen extends StatefulWidget {
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _submit() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      _showErrorDialog('Erro', 'Por favor, preencha todos os campos');
      return;
    }

    if (!_isLogin && _nameController.text.trim().isEmpty) {
      _showErrorDialog('Erro', 'Por favor, digite seu nome');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(credential.user!.uid)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data()!;
          if (userData['access'] == false) {
            await FirebaseAuth.instance.signOut();
            throw Exception('Acesso negado. Conta desativada.');
          }

          if (userData['expiration_date'] != null) {
            final expDate = DateTime.parse(userData['expiration_date']);
            if (expDate.isBefore(DateTime.now())) {
              await FirebaseAuth.instance.signOut();
              throw Exception('Conta expirada.');
            }
          }
        }
      } else {
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
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Erro ao autenticar';
      if (e.code == 'user-not-found') {
        message = 'Usuário não encontrado';
      } else if (e.code == 'wrong-password') {
        message = 'Senha incorreta';
      } else if (e.code == 'email-already-in-use') {
        message = 'Email já está em uso';
      } else if (e.code == 'weak-password') {
        message = 'Senha muito fraca (mín. 6 caracteres)';
      } else if (e.code == 'invalid-email') {
        message = 'Email inválido';
      }
      _showErrorDialog('Erro', message);
    } catch (e) {
      _showErrorDialog('Erro', e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
            child: Text('OK', style: TextStyle(color: Color(0xFFFF444F))),
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
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return CupertinoPageScaffold(
      backgroundColor: isDark ? Color(0xFF000000) : Color(0xFFF2F2F7),
      child: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Top bar with Learn button
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            ),
            
            // Main content
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Spacer(),
                    
                    // App icon
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Color(0xFFFF444F),
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFFFF444F).withOpacity(0.3),
                            blurRadius: 20,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(
                        CupertinoIcons.chat_bubble_fill,
                        size: 50,
                        color: CupertinoColors.white,
                      ),
                    ),
                    
                    SizedBox(height: 32),
                    
                    // Title
                    Text(
                      _isLogin ? 'Entrar' : 'Criar Conta',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        color: isDark ? CupertinoColors.white : CupertinoColors.black,
                        letterSpacing: -0.5,
                      ),
                    ),
                    
                    SizedBox(height: 8),
                    
                    Text(
                      _isLogin ? 'Bem-vindo de volta!' : 'Crie sua conta para começar',
                      style: TextStyle(
                        fontSize: 17,
                        color: isDark ? CupertinoColors.systemGrey : CupertinoColors.systemGrey,
                      ),
                    ),
                    
                    SizedBox(height: 40),
                    
                    // Form fields
                    if (!_isLogin) ...[
                      _buildInputField(
                        controller: _nameController,
                        placeholder: 'Nome',
                        icon: CupertinoIcons.person_fill,
                        isDark: isDark,
                      ),
                      SizedBox(height: 12),
                    ],
                    
                    _buildInputField(
                      controller: _emailController,
                      placeholder: 'Email',
                      icon: CupertinoIcons.mail_solid,
                      keyboardType: TextInputType.emailAddress,
                      isDark: isDark,
                    ),
                    
                    SizedBox(height: 12),
                    
                    _buildInputField(
                      controller: _passwordController,
                      placeholder: 'Senha',
                      icon: CupertinoIcons.lock_fill,
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
                      SizedBox(height: 8),
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
                    
                    SizedBox(height: 24),
                    
                    // Submit button
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
                    
                    SizedBox(height: 16),
                    
                    // Toggle button
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
                    
                    // Footer
                    Padding(
                      padding: EdgeInsets.only(bottom: 20),
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
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String placeholder,
    required IconData icon,
    required bool isDark,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1C1C1E) : CupertinoColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
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
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        prefix: Padding(
          padding: EdgeInsets.only(left: 12, right: 12),
          child: Icon(
            icon,
            color: Color(0xFFFF444F),
            size: 22,
          ),
        ),
        suffix: suffixIcon != null
            ? Padding(
                padding: EdgeInsets.only(right: 12),
                child: suffixIcon,
              )
            : null,
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}

// Learn Screen
class LearnScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return CupertinoPageScaffold(
      backgroundColor: isDark ? Color(0xFF000000) : Color(0xFFF2F2F7),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: isDark ? Color(0xFF000000) : CupertinoColors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Color(0xFF1C1C1E) : Color(0xFFE5E5EA),
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
            padding: EdgeInsets.all(20),
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
                    color: isDark ? CupertinoColors.systemGrey : CupertinoColors.systemGrey,
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