// lib/screens/marketplace_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/app_ui_components.dart';
import '../services/deriv_service.dart';
import 'trading_chart_screen.dart';

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

  /// Inicialização otimizada - verifica conexão existente
  Future<void> _initializeConnection() async {
    try {
      final token = await _storage.read(key: 'deriv_api_token');
      
      if (token != null && token.isNotEmpty) {
        // Conecta silenciosamente em background
        await _derivService.connectWithToken(token);
        
        // Escuta mudanças de estado
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

  /// OAuth Flow otimizado
  Future<void> _startOAuthFlow() async {
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
      String? token = uri.queryParameters['token'] ?? 
                     uri.queryParameters['access_token'];

      if (token == null && uri.fragment.isNotEmpty) {
        final fragmentParams = Uri.splitQueryString(uri.fragment);
        token = fragmentParams['token'] ?? fragmentParams['access_token'];
      }

      if (token != null && token.isNotEmpty) {
        await _storage.write(key: 'deriv_api_token', value: token);
        await _derivService.connectWithToken(token);
        
        if (mounted) {
          AppDialogs.showSuccess(
            context, 
            'Conectado!', 
            'Sua conta foi conectada com sucesso',
          );
        }
      } else {
        throw Exception('Token não recebido');
      }
    } catch (e) {
      if (mounted) {
        AppDialogs.showError(
          context, 
          'Erro', 
          'Falha ao conectar: ${e.toString()}',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Desconectar e limpar cache
  Future<void> _disconnect() async {
    await _storage.delete(key: 'deriv_api_token');
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

    // Loading inicial
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
            icon: Icon(
              Icons.power_settings_new,
              color: AppColors.primary,
            ),
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
              'Conecte-se à sua conta\npara continuar',
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
              'Acesse sua carteira Deriv e comece\na negociar nos mercados financeiros',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            
            SizedBox(height: 48),
            
            // Botão conectar
            AppPrimaryButton(
              text: 'Conectar Conta Deriv',
              onPressed: _isLoading ? null : _startOAuthFlow,
              isLoading: _isLoading,
              height: 56,
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
            
            SizedBox(height: 60),
            
            // Cards de recursos
            _buildFeatureCard(
              isDark,
              Icons.speed_outlined,
              'Trading em Tempo Real',
              'Execute operações instantaneamente',
            ),
            
            SizedBox(height: 16),
            
            _buildFeatureCard(
              isDark,
              Icons.bar_chart_rounded,
              'Múltiplos Mercados',
              'Forex, Synthetics, Stocks e mais',
            ),
            
            SizedBox(height: 16),
            
            _buildFeatureCard(
              isDark,
              Icons.security_outlined,
              'Seguro e Confiável',
              'Powered by Deriv API',
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
            // Card de saldo
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
            
            // Botão de trading
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
          ],
        ),
      ),
    );
  }
}