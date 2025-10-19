// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import '../widgets/app_ui_components.dart';
import '../services/deriv_service.dart';
import '../widgets/app_colors.dart';

class LoginScreen extends StatefulWidget {
  final DerivService derivService;

  const LoginScreen({Key? key, required this.derivService}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _tokenController = TextEditingController();

  bool _isLoading = false;
  bool _rememberMe = false;
  String _selectedMethod = 'oauth'; // 'oauth', 'credentials', 'token'

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedData() async {
    final savedEmail = await _storage.read(key: 'deriv_email');
    final savedToken = await _storage.read(key: 'deriv_api_token');
    final savedRemember = await _storage.read(key: 'deriv_remember');

    if (savedEmail != null && savedRemember == 'true') {
      setState(() {
        _emailController.text = savedEmail;
        _rememberMe = true;
      });
    }

    if (savedToken != null) {
      // NÃO sobrescrever o token real com uma versão truncada.
      // Mantenha o token real para que o botão "Conectar com Token" funcione corretamente.
      setState(() {
        _tokenController.text = savedToken;
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
        'scope': 'trade read payments admin',
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
            'Login OAuth realizado com sucesso',
            onClose: () => Navigator.pop(context),
          );
        }
      } else {
        throw Exception('Token não recebido');
      }
    } catch (e) {
      if (mounted) {
        AppDialogs.showError(context, 'Erro OAuth', e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// LOGIN COM TOKEN DIRETO
  Future<void> _loginWithToken() async {
    final token = _tokenController.text.trim();

    if (token.isEmpty) {
      AppDialogs.showError(context, 'Erro', 'Digite o token');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _storage.write(key: 'deriv_api_token', value: token);
      await widget.derivService.connectWithToken(token);

      if (mounted) {
        AppDialogs.showSuccess(
          context,
          'Conectado!',
          'Login com token realizado',
          onClose: () => Navigator.pop(context),
        );
      }
    } catch (e) {
      if (mounted) {
        AppDialogs.showError(context, 'Erro', 'Token inválido: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// LOGIN COM EMAIL/PASSWORD
  Future<void> _loginWithCredentials() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      AppDialogs.showError(context, 'Erro', 'Preencha email e senha');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Primeiro tente obter token via websocket-based helper
      final token = await widget.derivService.getApiTokenFromCredentials(email, password);

      if (token != null && token.isNotEmpty) {
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
        // Fallback: usar método de login direto do serviço que tentará novamente
        final result = await widget.derivService.loginWithCredentials(email, password);
        debugPrint('loginWithCredentials result: $result');

        if (result['success'] == true) {
          if (result['token'] != null) {
            await _storage.write(key: 'deriv_api_token', value: result['token']);
            await widget.derivService.connectWithToken(result['token']);
          }

          if (_rememberMe) {
            await _storage.write(key: 'deriv_email', value: email);
            await _storage.write(key: 'deriv_remember', value: 'true');
          }

          if (mounted) {
            AppDialogs.showSuccess(
              context,
              'Conectado!',
              'Login realizado',
              onClose: () => Navigator.pop(context),
            );
          }
        } else {
          final serverMsg = result['error'] ?? 'Credenciais inválidas';
          throw Exception(serverMsg);
        }
      }
    } catch (e, st) {
      debugPrint('Erro login credentials: $e\n$st');
      if (mounted) {
        AppDialogs.showError(context, 'Erro', e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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

              AppIconCircle(
                icon: Icons.account_balance_wallet_outlined,
                size: 60,
                iconColor: AppColors.primary,
              ),

              SizedBox(height: 24),

              Text(
                'Conecte sua conta',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),

              SizedBox(height: 8),

              Text(
                'Escolha o método de login',
                style: TextStyle(fontSize: 15, color: Colors.grey),
              ),

              SizedBox(height: 32),

              // Selector de método
              _buildMethodSelector(isDark),

              SizedBox(height: 32),

              // Conteúdo baseado no método selecionado
              if (_selectedMethod == 'oauth') _buildOAuthContent(isDark),
              if (_selectedMethod == 'token') _buildTokenContent(isDark),
              if (_selectedMethod == 'credentials') _buildCredentialsContent(isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMethodSelector(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        children: [
          _buildMethodOption(isDark, 'oauth', 'OAuth Deriv', Icons.security, 'Seguro e recomendado'),
          Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          _buildMethodOption(isDark, 'token', 'API Token', Icons.vpn_key, 'Cole seu token'),
          Divider(height: 1, color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          _buildMethodOption(isDark, 'credentials', 'Email/Senha', Icons.email, 'Login direto'),
        ],
      ),
    );
  }

  Widget _buildMethodOption(bool isDark, String method, String title, IconData icon, String subtitle) {
    final isSelected = _selectedMethod == method;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selectedMethod = method),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary.withOpacity(0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? AppColors.primary : Colors.grey,
                  size: 24,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle, color: AppColors.primary, size: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOAuthContent(bool isDark) {
    return Column(
      children: [
        AppInfoCard(
          icon: Icons.info_outline,
          text: 'Você será redirecionado para Deriv.com para fazer login de forma segura. Método recomendado.',
        ),
        SizedBox(height: 24),
        AppPrimaryButton(
          text: 'Conectar com OAuth',
          onPressed: _isLoading ? null : _loginWithOAuth,
          isLoading: _isLoading,
        ),
      ],
    );
  }

  Widget _buildTokenContent(bool isDark) {
    return Column(
      children: [
        AppFieldLabel(text: 'API Token'),
        SizedBox(height: 8),
        AppTextField(
          controller: _tokenController,
          hintText: 'Cole seu API token aqui',
          maxLines: 3,
          prefixIcon: Icon(Icons.vpn_key, color: Colors.grey),
        ),
        SizedBox(height: 16),
        AppInfoCard(
          icon: Icons.info_outline,
          text: 'Obtenha seu token em: Deriv > Configurações > Segurança > API Token',
        ),
        SizedBox(height: 24),
        AppPrimaryButton(
          text: 'Conectar com Token',
          onPressed: _isLoading ? null : _loginWithToken,
          isLoading: _isLoading,
        ),
      ],
    );
  }

  Widget _buildCredentialsContent(bool isDark) {
    return Column(
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
        Row(
          children: [
            CupertinoSwitch(
              value: _rememberMe,
              activeColor: AppColors.primary,
              onChanged: (value) => setState(() => _rememberMe = value),
            ),
            SizedBox(width: 12),
            Text('Lembrar email', style: TextStyle(fontSize: 14)),
          ],
        ),
        SizedBox(height: 16),
        AppInfoCard(
          icon: Icons.warning_amber_outlined,
          text: 'Use apenas em dispositivos confiáveis. OAuth é mais seguro.',
        ),
        SizedBox(height: 24),
        AppPrimaryButton(
          text: 'Entrar',
          onPressed: _isLoading ? null : _loginWithCredentials,
          isLoading: _isLoading,
        ),
      ],
    );
  }
}