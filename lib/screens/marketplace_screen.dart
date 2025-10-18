// lib/screens/marketplace_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';
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

  /// Inicialização - verifica conexão existente
  Future<void> _initializeConnection() async {
    try {
      final token = await _storage.read(key: 'deriv_api_token');
      
      if (token != null && token.isNotEmpty) {
        await _derivService.connectWithToken(token);
        
        _derivService.accountInfo.listen((info) {
          if (mounted && info != null) {
            setState(() {
              _accountType = info['account_type'];
              _currency = info['currency'];
              _loginId = info['loginid'];
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

  /// Abrir tela de login
  void _openLoginScreen() {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => LoginScreen(derivService: _derivService),
      ),
    ).then((_) {
      // Atualizar estado após retornar do login
      if (_derivService.isConnected) {
        setState(() {});
      }
    });
  }

  /// Desconectar e limpar cache
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
      });
    }
  }

  /// Abre página de registro
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
        actions: isConnected ? [
          IconButton(
            icon: Icon(Icons.power_settings_new, color: AppColors.primary),
            onPressed: () {
              AppDialogs.showConfirmation(
                context,
                'Desconectar',
                'Deseja desconectar sua conta Deriv?',
                onConfirm: _disconnect,
                isDestructive: true,
                confirmText: 'Desconectar',
              );
            },
            splashRadius: 24,
          ),
        ] : null,
      ),
      body: isConnected ? _buildConnectedView(isDark) : _buildDisconnectedView(isDark),
    );
  }

  /// Tela quando NÃO está conectado
  Widget _buildDisconnectedView(bool isDark) {
    return SafeArea(
      child: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 40),
            
            // Ícone principal
            AppIconCircle(
              icon: Icons.account_balance_wallet_outlined,
              size: 64,
              iconColor: AppColors.primary,
            ),
            
            SizedBox(height: 32),
            
            // Título
            Text(
              'Conecte-se à sua conta\npara começar a negociar',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: 16),
            
            // Subtítulo
            Text(
              'Acesse sua carteira Deriv e opere\nnos mercados financeiros globais',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: 48),
            
            // Botão de login (abre tela com ambas opções)
            AppPrimaryButton(
              text: 'Fazer Login',
              onPressed: _openLoginScreen,
              height: 56,
            ),
            
            SizedBox(height: 16),
            
            // Texto explicativo
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Escolha entre OAuth ou Email/Senha',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 20),
            
            // Botão registrar
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Não tem uma conta? ',
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
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
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 60),
            
            // Cards de recursos
            _buildFeatureCard(
              isDark,
              Icons.speed_outlined,
              'Trading em Tempo Real',
              'Execute operações instantaneamente com dados ao vivo',
            ),
            
            SizedBox(height: 16),
            
            _buildFeatureCard(
              isDark,
              Icons.bar_chart_rounded,
              'Múltiplos Mercados',
              'Forex, Synthetics, Indices e muito mais',
            ),
            
            SizedBox(height: 16),
            
            _buildFeatureCard(
              isDark,
              Icons.auto_awesome,
              'Trading Automático',
              '6 estratégias de automação incluídas',
            ),
            
            SizedBox(height: 16),
            
            _buildFeatureCard(
              isDark,
              Icons.security_outlined,
              'Seguro e Confiável',
              'Powered by Deriv API - Regulamentado globalmente',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(bool isDark, IconData icon, String title, String subtitle) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
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
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: AppColors.primary,
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
                SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Tela quando ESTÁ conectado
  Widget _buildConnectedView(bool isDark) {
    return SafeArea(
      child: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            // Card de saldo principal
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, Color(0xFFFF6B6B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
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
                          _accountType?.toUpperCase() ?? 'DEMO',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    '${_currency ?? 'USD'} ${_balance?.toStringAsFixed(2) ?? '0.00'}',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white, size: 16),
                      SizedBox(width: 8),
                      Text(
                        _loginId ?? 'Conectado',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 24),
            
            // Cards de ações rápidas
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionCard(
                    isDark,
                    Icons.account_balance_wallet,
                    'Depositar',
                    Colors.green,
                    () => _openDerivSite('cashier/deposit'),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionCard(
                    isDark,
                    Icons.history,
                    'Histórico',
                    Colors.blue,
                    () => _openDerivSite('reports/statement'),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 24),
            
            // Botão principal de trading
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
            
            // Informações da conta
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Informações da Conta',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  _buildInfoRow(isDark, 'Login ID', _loginId ?? '-'),
                  SizedBox(height: 12),
                  _buildInfoRow(isDark, 'Tipo de Conta', _accountType ?? '-'),
                  SizedBox(height: 12),
                  _buildInfoRow(isDark, 'Moeda', _currency ?? '-'),
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
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
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
            color: Colors.grey,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
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