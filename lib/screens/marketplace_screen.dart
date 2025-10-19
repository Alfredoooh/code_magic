// lib/screens/marketplace_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/app_colors.dart';
import '../widgets/app_ui_components.dart';
import '../services/deriv_service.dart';
import 'trading_chart_screen.dart';
import 'login_screen.dart';

class MarketplaceScreen extends StatefulWidget {
  @override
  _MarketplaceScreenState createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final DerivService _derivService = DerivService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool _isLoading = false;
  bool _isChecking = true;
  String? _accountType;
  String? _currency;
  String? _loginId;
  String? _email;
  double? _balance;

  @override
  void initState() {
    super.initState();
    _initializeConnection();
  }

  @override
  void dispose() {
    _derivService.dispose();
    super.dispose();
  }

  Future<void> _initializeConnection() async {
    try {
      final token = await _storage.read(key: 'deriv_api_token');
      final savedEmail = await _storage.read(key: 'deriv_email');

      if (token != null && token.isNotEmpty) {
        await _derivService.connectWithToken(token);

        _derivService.accountInfo.listen((info) {
          if (mounted && info != null) {
            setState(() {
              _accountType = info['account_type'];
              _currency = info['currency'];
              _loginId = info['loginid'];
              _email = info['email'] ?? savedEmail;
            });
          }
        });

        _derivService.balanceStream.listen((balance) {
          if (mounted) {
            setState(() => _balance = balance);
          }
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar credenciais: $e');
    } finally {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  void _openLoginScreen() {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => LoginScreen(derivService: _derivService),
      ),
    ).then((_) {
      if (_derivService.isConnected) {
        setState(() {});
      }
    });
  }

  Future<void> _disconnect() async {
    await _storage.delete(key: 'deriv_api_token');
    await _storage.delete(key: 'deriv_email');
    await _storage.delete(key: 'deriv_remember');
    _derivService.disconnect();

    if (mounted) {
      setState(() {
        _accountType = null;
        _currency = null;
        _loginId = null;
        _balance = null;
        _email = null;
      });
    }
  }

  void _showAccountMenu() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 20),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.2),
                          AppColors.primary.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.account_circle_rounded,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _email ?? _loginId ?? 'Conta Deriv',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : Colors.black,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          _loginId ?? 'Conectado',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            _buildMenuItem(
              icon: Icons.info_outline_rounded,
              label: 'Informações da Conta',
              color: Colors.blue,
              isDark: isDark,
              onTap: () {
                Navigator.pop(context);
                _showAccountInfo();
              },
            ),
            _buildMenuItem(
              icon: Icons.history_rounded,
              label: 'Histórico de Transações',
              color: Colors.purple,
              isDark: isDark,
              onTap: () {
                Navigator.pop(context);
                _openDerivSite('reports/statement');
              },
            ),
            _buildMenuItem(
              icon: Icons.settings_rounded,
              label: 'Configurações',
              color: Colors.orange,
              isDark: isDark,
              onTap: () {
                Navigator.pop(context);
                _openDerivSite('account/personal-details');
              },
            ),
            _buildMenuItem(
              icon: Icons.support_agent_rounded,
              label: 'Suporte',
              color: Colors.green,
              isDark: isDark,
              onTap: () {
                Navigator.pop(context);
                _openDerivSite('help-centre');
              },
            ),
            Divider(
              color: isDark ? AppColors.darkSeparator : AppColors.separator,
              height: 1,
            ),
            _buildMenuItem(
              icon: Icons.logout_rounded,
              label: 'Desconectar',
              color: AppColors.error,
              isDark: isDark,
              onTap: () {
                Navigator.pop(context);
                AppDialogs.showConfirmation(
                  context,
                  'Desconectar',
                  'Tem certeza que deseja desconectar sua conta Deriv?',
                  onConfirm: _disconnect,
                  isDestructive: true,
                  confirmText: 'Desconectar',
                );
              },
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: color.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Colors.grey.shade500,
            ),
          ],
        ),
      ),
    );
  }

  void _showAccountInfo() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.info_outline_rounded, color: AppColors.primary),
            SizedBox(width: 12),
            Text(
              'Informações da Conta',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildInfoRow(isDark, 'Email', _email ?? '-'),
            SizedBox(height: 12),
            _buildInfoRow(isDark, 'Login ID', _loginId ?? '-'),
            SizedBox(height: 12),
            _buildInfoRow(isDark, 'Tipo de Conta', _accountType ?? '-'),
            SizedBox(height: 12),
            _buildInfoRow(isDark, 'Moeda', _currency ?? '-'),
            SizedBox(height: 12),
            _buildInfoRow(
              isDark,
              'Saldo',
              '${_currency ?? 'USD'} ${_balance?.toStringAsFixed(2) ?? '0.00'}',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Fechar',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
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
    final isConnected = _derivService.isConnected;

    if (_isChecking) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
        body: Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
            strokeWidth: 3,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppPrimaryAppBar(
        title: 'Trading',
        actions: isConnected
            ? [
                IconButton(
                  icon: Icon(
                    Icons.more_vert_rounded,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                  onPressed: _showAccountMenu,
                ),
              ]
            : null,
      ),
      body: isConnected ? _buildConnectedView(isDark) : _buildDisconnectedView(isDark),
    );
  }

  Widget _buildDisconnectedView(bool isDark) {
    return SafeArea(
      child: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 40),
            AppIconCircle(
              icon: Icons.account_balance_wallet_outlined,
              size: 64,
              iconColor: AppColors.primary,
            ),
            SizedBox(height: 32),
            Text(
              'Conecte-se à sua conta\npara começar a negociar',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black,
                height: 1.3,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            Text(
              'Acesse sua carteira Deriv e opere\nnos mercados financeiros globais',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey.shade600,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 48),
            AppPrimaryButton(
              text: 'Fazer Login',
              onPressed: _openLoginScreen,
              height: 56,
            ),
            SizedBox(height: 16),
            AppInfoCard(
              icon: Icons.info_outline_rounded,
              text: 'Escolha entre OAuth ou Email/Senha',
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Não tem uma conta? ',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                InkWell(
                  onTap: _openRegisterPage,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Text(
                      'Registrar Grátis',
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 60),
            _buildFeatureCard(
              isDark,
              Icons.speed_outlined,
              'Trading em Tempo Real',
              'Execute operações instantaneamente com dados ao vivo',
              Colors.blue,
            ),
            SizedBox(height: 16),
            _buildFeatureCard(
              isDark,
              Icons.bar_chart_rounded,
              'Múltiplos Mercados',
              'Forex, Synthetics, Indices e muito mais',
              Colors.purple,
            ),
            SizedBox(height: 16),
            _buildFeatureCard(
              isDark,
              Icons.auto_awesome_rounded,
              'Trading Automático',
              '6 estratégias de automação incluídas',
              Colors.orange,
            ),
            SizedBox(height: 16),
            _buildFeatureCard(
              isDark,
              Icons.security_outlined,
              'Seguro e Confiável',
              'Powered by Deriv API - Regulamentado globalmente',
              Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    bool isDark,
    IconData icon,
    String title,
    String subtitle,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppDesignConfig.cardRadius),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: color.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Icon(icon, color: color, size: 24),
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
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black,
                    letterSpacing: -0.3,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    height: 1.3,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectedView(bool isDark) {
    return SafeArea(
      child: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primaryLight,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.4),
                    blurRadius: 24,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Saldo Disponível',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '${_currency ?? 'USD'} ${_balance?.toStringAsFixed(2) ?? '0.00'}',
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -1,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          _accountType?.toUpperCase() ?? 'DEMO',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.verified_user_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _email ?? _loginId ?? 'Conectado',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (_email != null && _loginId != null)
                                Text(
                                  _loginId!,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionCard(
                    isDark,
                    Icons.account_balance_wallet_rounded,
                    'Depositar',
                    AppColors.success,
                    () => _openDerivSite('cashier/deposit'),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionCard(
                    isDark,
                    Icons.history_rounded,
                    'Histórico',
                    Colors.blue,
                    () => _openDerivSite('reports/statement'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            AppPrimaryButton(
              text: 'Iniciar Trading',
              onPressed: () {
                Navigator.push(
                  context,
                  CupertinoPageRoute(
                    builder: (context) => TradingChartScreen(
                      derivService: _derivService,
                    ),
                  ),
                );
              },
              height: 56,
            ),
            SizedBox(height: 24),
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(AppDesignConfig.cardRadius),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppSectionTitle(
                    text: 'Estatísticas Rápidas',
                    fontSize: 18,
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          isDark,
                          Icons.trending_up_rounded,
                          'Lucro Total',
                          'Em breve',
                          AppColors.success,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          isDark,
                          Icons.swap_horiz_rounded,
                          'Trades',
                          'Em breve',
                          Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(
    bool isDark,
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(AppDesignConfig.cardRadius),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: color.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    bool isDark,
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(bool isDark, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
      ],
    );
  }

  Future<void> _openDerivSite(String path) async {
    final url = 'https://app.deriv.com/$path';
    final uri = Uri.parse(url);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}