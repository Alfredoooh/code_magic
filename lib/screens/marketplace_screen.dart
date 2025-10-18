// lib/screens/marketplace_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import '../widgets/app_ui_components.dart';
import '../services/deriv_service.dart';
import '../widgets/trading_panel.dart';

class MarketplaceScreen extends StatefulWidget {
  @override
  _MarketplaceScreenState createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final DerivService _derivService = DerivService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _tokenController = TextEditingController();

  bool _isLoading = false;
  String? _accountType;
  String? _currency;
  String? _loginId;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
    _derivService.connectionState.listen((state) {
      if (mounted) setState(() {});
    });
    _derivService.accountInfo.listen((info) {
      if (mounted && info != null) {
        setState(() {
          _accountType = info['account_type'];
          _currency = info['currency'];
          _loginId = info['loginid'];
        });
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _tokenController.dispose();
    _derivService.dispose();
    super.dispose();
  }

  Future<void> _loadSavedCredentials() async {
    try {
      final token = await _storage.read(key: 'deriv_api_token');
      if (token != null && token.isNotEmpty) {
        _tokenController.text = token;
        await _derivService.connectWithToken(token);
      }
    } catch (e) {
      debugPrint('Error loading credentials: $e');
    }
  }

  Future<void> _loginWithEmailPassword() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      AppDialogs.showError(context, 'Erro', 'Preencha email e senha');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _derivService.loginWithCredentials(email, password);
      final token = _derivService.currentToken;
      if (token != null) {
        await _storage.write(key: 'deriv_api_token', value: token);
        _tokenController.text = token;
      }
      Navigator.pop(context);
      AppDialogs.showSuccess(context, 'Sucesso', 'Login realizado com sucesso!');
    } catch (e) {
      AppDialogs.showError(context, 'Erro', 'Erro ao fazer login: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _connectWithToken() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      AppDialogs.showError(context, 'Erro', 'Insira um token válido');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _derivService.connectWithToken(token);
      await _storage.write(key: 'deriv_api_token', value: token);
      Navigator.pop(context);
      AppDialogs.showSuccess(context, 'Sucesso', 'Conectado com sucesso!');
    } catch (e) {
      AppDialogs.showError(context, 'Erro', 'Erro ao conectar: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _startOAuthFlow() async {
    try {
      final result = await FlutterWebAuth2.authenticate(
        url: 'https://oauth.deriv.com/oauth2/authorize?app_id=71954&redirect_uri=https://alfredoooh.github.io/database/oauth-redirect/&response_type=token&scope=trade read',
        callbackUrlScheme: 'com.nexa.madeeasy',
      );
      final uri = Uri.parse(result);
      final token = uri.queryParameters['access_token'] ?? uri.queryParameters['token'];
      if (token != null) {
        _tokenController.text = token;
        await _connectWithToken();
      }
    } catch (e) {
      AppDialogs.showError(context, 'Erro', 'OAuth cancelado: $e');
    }
  }

  Future<void> _disconnect() async {
    await _storage.delete(key: 'deriv_api_token');
    _derivService.disconnect();
    setState(() {
      _accountType = null;
      _currency = null;
      _loginId = null;
      _emailController.clear();
      _passwordController.clear();
      _tokenController.clear();
    });
  }

  void _showLoginSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    AppBottomSheet.show(
      context,
      height: MediaQuery.of(context).size.height * 0.85,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 12),
            AppSectionTitle(
              text: 'Conectar à Deriv',
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
            SizedBox(height: 24),
            AppSectionTitle(text: 'Login com Email e Senha', fontSize: 17),
            SizedBox(height: 16),
            AppTextField(
              controller: _emailController,
              hintText: 'Email',
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 12),
            AppPasswordField(
              controller: _passwordController,
              hintText: 'Senha',
            ),
            SizedBox(height: 16),
            AppPrimaryButton(
              text: 'Entrar',
              onPressed: _loginWithEmailPassword,
              isLoading: _isLoading,
            ),
            SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'OU',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                Expanded(child: Divider()),
              ],
            ),
            SizedBox(height: 24),
            AppSectionTitle(text: 'Token API', fontSize: 17),
            SizedBox(height: 16),
            AppTextField(
              controller: _tokenController,
              hintText: 'Cole seu token aqui',
            ),
            SizedBox(height: 16),
            AppPrimaryButton(
              text: 'Conectar',
              onPressed: _connectWithToken,
              isLoading: _isLoading,
            ),
            SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _startOAuthFlow();
                },
                child: Text(
                  'OAuth via Navegador',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isConnected = _derivService.isConnected;
    final balance = _derivService.balance;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: CustomScrollView(
        physics: BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            stretch: true,
            backgroundColor: Colors.transparent,
            flexibleSpace: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: (isDark ? AppColors.darkCard : AppColors.lightCard).withOpacity(0.8),
                    border: Border(
                      bottom: BorderSide(
                        color: (isDark ? AppColors.darkBorder : AppColors.lightBorder).withOpacity(0.2),
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: FlexibleSpaceBar(
                    titlePadding: EdgeInsets.only(left: 20, bottom: 16),
                    title: Text(
                      'Trading',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              if (isConnected)
                Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: IconButton(
                    onPressed: _disconnect,
                    icon: Icon(
                      Icons.power_settings_new,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                ),
            ],
          ),
          SliverPadding(
            padding: EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (!isConnected) ...[
                  SizedBox(height: 40),
                  _buildWelcomeCard(isDark),
                  SizedBox(height: 32),
                  _buildFeaturesList(isDark),
                  SizedBox(height: 32),
                  _buildConnectButton(isDark),
                ] else ...[
                  _buildBalanceCard(isDark, balance, _currency, _loginId, _accountType),
                  SizedBox(height: 24),
                  TradingPanel(derivService: _derivService),
                ],
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard(bool isDark) {
    return Container(
      padding: EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, Color(0xFFFF6B6B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.bar_chart, size: 64, color: Colors.white),
          SizedBox(height: 20),
          Text(
            'Bem-vindo ao Trading',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12),
          Text(
            'Negocie nos mercados financeiros com a Deriv',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesList(bool isDark) {
    return Column(
      children: [
        _buildFeatureItem(isDark, Icons.speed, 'Trading em Tempo Real', 'Execute ordens instantaneamente'),
        SizedBox(height: 16),
        _buildFeatureItem(isDark, Icons.bar_chart, 'Múltiplos Mercados', 'Forex, Synthetics, Stocks e mais'),
        SizedBox(height: 16),
        _buildFeatureItem(isDark, Icons.security, 'Seguro', 'Powered by Deriv API'),
      ],
    );
  }

  Widget _buildFeatureItem(bool isDark, IconData icon, String title, String subtitle) {
    return AppCard(
      padding: EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primary, size: 28),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _showLoginSheet(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 18),
          elevation: 8,
          shadowColor: AppColors.primary.withOpacity(0.3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.link, size: 22),
            SizedBox(width: 12),
            Text(
              'Conectar Conta Deriv',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(bool isDark, double? balance, String? currency, String? loginId, String? accountType) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, Color(0xFFFF6B6B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Saldo Disponível',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  accountType?.toUpperCase() ?? 'DEMO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            '${currency ?? 'USD'} ${balance?.toStringAsFixed(2) ?? '0.00'}',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Text(
                loginId ?? 'Conta conectada',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}