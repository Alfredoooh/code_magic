// lib/screens/marketplace_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
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
      _showError('Preencha email e senha');
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
      _showSuccess('Login realizado com sucesso!');
    } catch (e) {
      _showError('Erro ao fazer login: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _connectWithToken() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      _showError('Insira um token válido');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _derivService.connectWithToken(token);
      await _storage.write(key: 'deriv_api_token', value: token);
      Navigator.pop(context);
      _showSuccess('Conectado com sucesso!');
    } catch (e) {
      _showError('Erro ao conectar: $e');
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
      _showError('OAuth cancelado: $e');
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

  void _showError(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Erro'),
        content: Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text(message),
        ),
        actions: [
          CupertinoDialogAction(
            child: Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showSuccess(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Sucesso'),
        content: Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text(message),
        ),
        actions: [
          CupertinoDialogAction(
            child: Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showLoginSheet(BuildContext context) {
    final brightness = MediaQuery.of(context).platformBrightness;
    final isDark = brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: (isDark ? Color(0xFF1C1C1E) : CupertinoColors.white).withOpacity(0.95),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemGrey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Conectar à Deriv',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: isDark ? CupertinoColors.white : CupertinoColors.black,
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Login com Email e Senha',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: isDark ? CupertinoColors.white : CupertinoColors.black,
                    ),
                  ),
                  SizedBox(height: 16),
                  CupertinoTextField(
                    controller: _emailController,
                    placeholder: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? Color(0xFF2C2C2E) : Color(0xFFF2F2F7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  SizedBox(height: 12),
                  CupertinoTextField(
                    controller: _passwordController,
                    placeholder: 'Senha',
                    obscureText: true,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? Color(0xFF2C2C2E) : Color(0xFFF2F2F7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton(
                      color: Color(0xFFFF444F),
                      borderRadius: BorderRadius.circular(12),
                      onPressed: _isLoading ? null : _loginWithEmailPassword,
                      child: _isLoading
                          ? CupertinoActivityIndicator(color: CupertinoColors.white)
                          : Text('Entrar', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                  SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(child: Divider()),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('OU', style: TextStyle(color: CupertinoColors.systemGrey)),
                      ),
                      Expanded(child: Divider()),
                    ],
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Token API',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: isDark ? CupertinoColors.white : CupertinoColors.black,
                    ),
                  ),
                  SizedBox(height: 16),
                  CupertinoTextField(
                    controller: _tokenController,
                    placeholder: 'Cole seu token aqui',
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? Color(0xFF2C2C2E) : Color(0xFFF2F2F7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton(
                      color: Color(0xFFFF444F),
                      borderRadius: BorderRadius.circular(12),
                      onPressed: _isLoading ? null : _connectWithToken,
                      child: Text('Conectar', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                  SizedBox(height: 12),
                  Center(
                    child: CupertinoButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _startOAuthFlow();
                      },
                      child: Text(
                        'OAuth via Navegador',
                        style: TextStyle(color: Color(0xFFFF444F), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.of(context).platformBrightness;
    final isDark = brightness == Brightness.dark;
    final isConnected = _derivService.isConnected;
    final balance = _derivService.balance;

    return CupertinoPageScaffold(
      backgroundColor: isDark ? Color(0xFF000000) : Color(0xFFF2F2F7),
      child: CustomScrollView(
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
                    color: (isDark ? Color(0xFF1C1C1E) : CupertinoColors.white).withOpacity(0.8),
                    border: Border(
                      bottom: BorderSide(
                        color: (isDark ? CupertinoColors.systemGrey : CupertinoColors.systemGrey4).withOpacity(0.2),
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: FlexibleSpaceBar(
                    titlePadding: EdgeInsets.only(left: 20, bottom: 16),
                    title: Text(
                      'Trading',
                      style: TextStyle(
                        color: isDark ? CupertinoColors.white : CupertinoColors.black,
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
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: _disconnect,
                    child: Icon(
                      CupertinoIcons.power,
                      color: Color(0xFFFF444F),
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
          colors: [Color(0xFFFF444F), Color(0xFFFF6B6B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFFF444F).withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(CupertinoIcons.chart_bar_alt_fill, size: 64, color: CupertinoColors.white),
          SizedBox(height: 20),
          Text(
            'Bem-vindo ao Trading',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: CupertinoColors.white,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12),
          Text(
            'Negocie nos mercados financeiros com a Deriv',
            style: TextStyle(
              fontSize: 16,
              color: CupertinoColors.white.withOpacity(0.9),
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
        _buildFeatureItem(isDark, CupertinoIcons.speedometer, 'Trading em Tempo Real', 'Execute ordens instantaneamente'),
        SizedBox(height: 16),
        _buildFeatureItem(isDark, CupertinoIcons.chart_bar_square_fill, 'Múltiplos Mercados', 'Forex, Synthetics, Stocks e mais'),
        SizedBox(height: 16),
        _buildFeatureItem(isDark, CupertinoIcons.lock_shield_fill, 'Seguro', 'Powered by Deriv API'),
      ],
    );
  }

  Widget _buildFeatureItem(bool isDark, IconData icon, String title, String subtitle) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1C1C1E) : CupertinoColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Color(0xFF2C2C2E) : CupertinoColors.systemGrey6,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Color(0xFFFF444F).withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Color(0xFFFF444F), size: 28),
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
                    color: isDark ? CupertinoColors.white : CupertinoColors.black,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: CupertinoColors.systemGrey,
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
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => _showLoginSheet(context),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Color(0xFFFF444F),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Color(0xFFFF444F).withOpacity(0.3),
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.link, color: CupertinoColors.white, size: 22),
            SizedBox(width: 12),
            Text(
              'Conectar Conta Deriv',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: CupertinoColors.white,
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
          colors: [Color(0xFFFF444F), Color(0xFFFF6B6B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFFF444F).withOpacity(0.3),
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
                  color: CupertinoColors.white.withOpacity(0.9),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: CupertinoColors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  accountType?.toUpperCase() ?? 'DEMO',
                  style: TextStyle(
                    color: CupertinoColors.white,
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
              color: CupertinoColors.white,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Icon(CupertinoIcons.checkmark_seal_fill, color: CupertinoColors.white, size: 16),
              SizedBox(width: 8),
              Text(
                loginId ?? 'Conta conectada',
                style: TextStyle(
                  color: CupertinoColors.white.withOpacity(0.9),
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