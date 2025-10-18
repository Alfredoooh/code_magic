import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/app_ui_components.dart';
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
      AppDialogs.showError(context, 'Campos Obrigatórios', 'Por favor, preencha o email e a senha para continuar.');
      return;
    }

    if (!_isLogin && _nameController.text.trim().isEmpty) {
      AppDialogs.showError(context, 'Nome Obrigatório', 'Por favor, digite seu nome completo para criar a conta.');
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
            AppDialogs.showError(
              context,
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
              AppDialogs.showError(
                context,
                'Conta Expirada',
                'Sua assinatura expirou. Renove para continuar usando o serviço.'
              );
              setState(() => _isLoading = false);
              return;
            }
          }
        }

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
      }

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
        AppDialogs.showError(context, title, message);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppDialogs.showError(context, 'Erro', 'Ocorreu um erro inesperado. Por favor, tente novamente.');
      }
    }
  }

  void _navigateToForgotPassword() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => ForgotPasswordScreen()),
    );
  }

  void _navigateToLearn() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => LearnScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      resizeToAvoidBottomInset: true,
      body: GestureDetector(
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
                      SizedBox(height: 40),

                      // Logo do app SEM CONTAINER
                      Image.asset(
                        'assets/icon/icon.png',
                        width: 100,
                        height: 100,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.apps,
                            size: 100,
                            color: AppColors.primary,
                          );
                        },
                      ),

                      SizedBox(height: 40),

                      Text(
                        _isLogin ? 'Entrar' : 'Criar Conta',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black,
                          letterSpacing: -0.5,
                        ),
                      ),

                      SizedBox(height: 40),

                      if (!_isLogin) ...[
                        AppTextField(
                          controller: _nameController,
                          hintText: 'Nome',
                        ),
                        SizedBox(height: 16),
                      ],

                      AppTextField(
                        controller: _emailController,
                        hintText: 'Email',
                        keyboardType: TextInputType.emailAddress,
                      ),

                      SizedBox(height: 16),

                      AppPasswordField(
                        controller: _passwordController,
                        hintText: 'Senha',
                      ),

                      if (_isLogin) ...[
                        SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _navigateToForgotPassword,
                            child: Text(
                              'Esqueceu a palavra-passe?',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ],

                      SizedBox(height: 32),

                      AppPrimaryButton(
                        text: _isLogin ? 'Entrar' : 'Criar Conta',
                        onPressed: _submit,
                        isLoading: _isLoading,
                        height: 56,
                      ),

                      SizedBox(height: 20),

                      TextButton(
                        onPressed: () => setState(() => _isLogin = !_isLogin),
                        child: Text(
                          _isLogin ? 'Não tem conta? Criar uma' : 'Já tem conta? Entrar',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),

                      Spacer(),

                      // BOTÃO "SABER MAIS" NO BOTTOM
                      Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: TextButton(
                          onPressed: _navigateToLearn,
                          child: Text(
                            'Saber mais',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),

                      Padding(
                        padding: EdgeInsets.only(bottom: 24),
                        child: Text(
                          'from nexa',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
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
}

class LearnScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppSecondaryAppBar(
        title: 'Saber mais',
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppIconCircle(
                  icon: Icons.book,
                  size: 80,
                ),
                SizedBox(height: 24),
                Text(
                  'Conteúdo Educacional',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Em breve você terá acesso a conteúdos educacionais exclusivos.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    color: Colors.grey,
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