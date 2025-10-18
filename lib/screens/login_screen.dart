// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/app_ui_components.dart';
import '../services/deriv_service.dart';
import 'trading_chart_screen.dart';

class LoginScreen extends StatefulWidget {
  final DerivService derivService;

  const LoginScreen({Key? key, required this.derivService}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  late TabController _tabController;
  bool _isLoading = false;
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSavedCredentials();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedCredentials() async {
    final savedEmail = await _storage.read(key: 'deriv_email');
    final savedRemember = await _storage.read(key: 'deriv_remember');
    
    if (savedEmail != null && savedRemember == 'true') {
      setState(() {
        _emailController.text = savedEmail;
        _rememberMe = true;
      });
    }
  }

  /// LOGIN COM OAUTH
  Future<void> _loginWithOAuth() async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);

    try {
      final authUrl = Uri.https('oauth.deriv.com', '/oauth2/authorize', {
        'app_id': '71954',
        'redirect_uri': 'https://alfredoooh.github.io/database/oauth-redirect/',
        'response_type': 'token',
        'scope': 'trade read',
      });

      final result = await FlutterWebAuth2.authenticate(
        url: authUrl.toString(),
        callbackUrlScheme: 'com.nexa.madeeasy',
      );

      final uri = Uri.parse(result);
      String? token = uri.queryParameters['token'] ?? uri.queryParameters['access_token'];

      if (token == null && uri.fragment.isNotEmpty) {
        final fragmentParams = Uri.splitQueryString(uri.fragment);
        token = fragmentParams['token'] ?? fragmentParams['access_token'];
      }

      if (token != null && token.isNotEmpty) {
        await _storage.write(key: 'deriv_api_token', value: token);
        await widget.derivService.connectWithToken(token);
        
        if (mounted) {
          AppDialogs.showSuccess(
            context, 
            'Conectado!', 
            'Login realizado com sucesso',
            onClose: () => Navigator.pop(context),
          );
        }
      } else {
        throw Exception('Token não recebido');
      }
    } catch (e) {
      if (mounted) {
        AppDialogs.showError(context, 'Erro', 'Falha ao conectar: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// LOGIN COM EMAIL E PASSWORD
  Future<void> _loginWithCredentials() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      AppDialogs.showError(context, 'Erro', 'Preencha email e senha');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Método 1: Tentar obter token primeiro
      final token = await widget.derivService.getApiTokenFromCredentials(email, password);
      
      if (token != null && token.isNotEmpty) {
        // Sucesso! Salvar token e conectar
        await _storage.write(key: 'deriv_api_token', value: token);
        
        if (_rememberMe) {
          await _storage.write(key: 'deriv_email', value: email);
          await _storage.write(key: 'deriv_remember', value: 'true');
        } else {
          await _storage.delete(key: 'deriv_email');
          await _storage.delete(key: 'deriv_remember');
        }

        await widget.derivService.connectWithToken(token);
        
        if (mounted) {
          AppDialogs.showSuccess(
            context,
            'Conectado!',
            'Login realizado com sucesso',
            onClose: () => Navigator.pop(context),
          );
        }
      } else {
        // Método 2: Tentar login direto
        final result = await widget.derivService.loginWithCredentials(email, password);
        
        if (result['success'] == true) {
          if (result['token'] != null) {
            await _storage.write(key: 'deriv_api_token', value: result['token']);
          }
          
          if (_rememberMe) {
            await _storage.write(key: 'deriv_email', value: email);
            await _storage.write(key: 'deriv_remember', value: 'true');
          }

          if (mounted) {
            AppDialogs.showSuccess(
              context,
              'Conectado!',
              'Login realizado com sucesso',
              onClose: () => Navigator.pop(context),
            );
          }
        } else {
          throw Exception(result['error'] ?? 'Falha na autenticação');
        }
      }
    } catch (e) {
      if (mounted) {
        AppDialogs.showError(
          context,
          'Erro de Login',
          'Verifique suas credenciais: ${e.toString()}',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _openRegisterPage() async {
    const url = 'https://deriv.com/signup/';
    final uri = Uri.parse(url);
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppSecondaryAppBar(title: 'Login'),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          padding: EdgeInsets.all(24),
          child: Column(
            children: [
              SizedBox(height: 20),
              
              // Logo/Icon
              AppIconCircle(
                icon: Icons.account_balance_wallet_outlined,
                size: 60,
                iconColor: AppColors.primary,
              ),
              
              SizedBox(height: 24),
              
              Text(
                'Bem-vindo de volta',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              
              SizedBox(height: 8),
              
              Text(
                'Escolha como deseja entrar',
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey,
                ),
              ),
              
              SizedBox(height: 32),
              
              // Tab Bar
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  ),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey,
                  labelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  tabs: [
                    Tab(text: 'OAuth'),
                    Tab(text: 'Email/Senha'),
                  ],
                ),
              ),
              
              SizedBox(height: 32),
              
              // Tab Views
              SizedBox(
                height: 400,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOAuthTab(isDark),
                    _buildCredentialsTab(isDark),
                  ],
                ),
              ),
              
              SizedBox(height: 24),
              
              // Registrar
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Não tem conta? ',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey,
                    ),
                  ),
                  InkWell(
                    onTap: _openRegisterPage,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Text(
                        'Registrar',
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOAuthTab(bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.security,
          size: 80,
          color: AppColors.primary.withOpacity(0.3),
        ),
        
        SizedBox(height: 24),
        
        Text(
          'Login Seguro',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        SizedBox(height: 12),
        
        Text(
          'Conecte-se usando OAuth da Deriv.\nSeguro, rápido e sem compartilhar senha.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
            height: 1.5,
          ),
        ),
        
        SizedBox(height: 32),
        
        AppPrimaryButton(
          text: 'Conectar com OAuth',
          onPressed: _isLoading ? null : _loginWithOAuth,
          isLoading: _isLoading,
        ),
        
        SizedBox(height: 16),
        
        AppInfoCard(
          icon: Icons.info_outline,
          text: 'Método recomendado pela Deriv. Seus dados ficam sempre seguros.',
        ),
      ],
    );
  }

  Widget _buildCredentialsTab(bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AppFieldLabel(text: 'Email'),
        SizedBox(height: 8),
        AppTextField(
          controller: _emailController,
          hintText: 'seu@email.com',
          keyboardType: TextInputType.emailAddress,
          prefixIcon: Icon(Icons.email_outlined, color: Colors.grey),
        ),
        
        SizedBox(height: 16),
        
        AppFieldLabel(text: 'Senha'),
        SizedBox(height: 8),
        AppPasswordField(
          controller: _passwordController,
          hintText: 'Sua senha',
        ),
        
        SizedBox(height: 16),
        
        // Remember me
        Row(
          children: [
            CupertinoSwitch(
              value: _rememberMe,
              activeColor: AppColors.primary,
              onChanged: (value) {
                setState(() => _rememberMe = value);
              },
            ),
            SizedBox(width: 12),
            Text(
              'Lembrar meu email',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        
        SizedBox(height: 24),
        
        AppPrimaryButton(
          text: 'Entrar com Email',
          onPressed: _isLoading ? null : _loginWithCredentials,
          isLoading: _isLoading,
        ),
        
        SizedBox(height: 16),
        
        AppInfoCard(
          icon: Icons.warning_amber_outlined,
          text: 'Use apenas em dispositivos confiáveis. O OAuth é mais seguro.',
        ),
      ],
    );
  }
}