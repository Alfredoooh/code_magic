// lib/screens/marketplace_screen.dart
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_web_auth/flutter_web_auth.dart';

/// MarketplaceScreen com OAuth (serverless) + WebSocket Deriv (app_id = 71954)
/// Mantive TODO o design original, acrescentei apenas a lógica necessária.
/// Redirect HTTPS configurado para: https://alfredoooh.github.io/database/oauth-redirect/
/// Deep link custom scheme: com.nexa.madeeasy://oauth
class MarketplaceScreen extends StatefulWidget {
  @override
  _MarketplaceScreenState createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  bool _isConnected = false;
  bool _isLoading = false;
  String? _accountInfo;
  double? _balance;
  final _apiTokenController = TextEditingController();

  // Secure storage (token)
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  // WebSocket client
  DerivWSClient? _wsClient;
  StreamSubscription<String?>? _wsSubscription;

  // App ID
  static const int _derivAppId = 71954;

  // OAuth redirect HTTPS (tua página no GitHub Pages)
  static const String _redirectHttps = 'https://alfredoooh.github.io/database/oauth-redirect/';

  // custom scheme that está registado no AndroidManifest/Info.plist
  static const String _customScheme = 'com.nexa.madeeasy';
  static const String _customHost = 'oauth';

  @override
  void initState() {
    super.initState();
    // NOTA: não usamos uni_links (causava erro de build). Usamos flutter_web_auth quando necessário.
    _loadSavedToken();
  }

  @override
  void dispose() {
    _apiTokenController.dispose();
    _wsSubscription?.cancel();
    _wsClient?.disconnect();
    super.dispose();
  }

  // ----------------------------
  // Handle received token / code from callback Uri
  // ----------------------------
  void _handleIncomingUri(Uri uri) {
    // Exemplo: com.nexa.madeeasy://oauth?token=XXX&state=...
    if (uri.scheme == _customScheme && uri.host == _customHost) {
      final params = uri.queryParameters;
      final token = params['token'] ?? params['access_token'];
      final code = params['code'];
      if (token != null && token.isNotEmpty) {
        _onReceivedToken(token);
      } else if (code != null && code.isNotEmpty) {
        _showCodeReceivedDialog(code);
      } else {
        _showErrorDialog('Callback recebido sem token (params: ${params.keys.join(',')})');
      }
    } else {
      // caso o callback venha com query no esquema https (flutter_web_auth devolve a URI completa)
      final params = uri.queryParameters;
      final token = params['token'] ?? params['access_token'];
      final code = params['code'];
      if (token != null && token.isNotEmpty) {
        _onReceivedToken(token);
      } else if (code != null && code.isNotEmpty) {
        _showCodeReceivedDialog(code);
      } else {
        _showErrorDialog('Callback recebido com esquema inesperado: ${uri.toString()}');
      }
    }
  }

  Future<void> _onReceivedToken(String token) async {
    await _secureStorage.write(key: 'deriv_api_token', value: token);
    _apiTokenController.text = token;
    await _connectToDerivAPI(token);
  }

  void _showCodeReceivedDialog(String code) {
    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Código recebido'),
        content: Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text(
            'Recebemos um authorization code. Para trocar este code por um token de acesso é necessário um backend (por segurança). Código:\n\n$code',
            style: TextStyle(fontSize: 13),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: Text('Entendi'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  // ----------------------------
  // Token persistente: load / connect
  // ----------------------------
  Future<void> _loadSavedToken() async {
    try {
      final token = await _secureStorage.read(key: 'deriv_api_token');
      if (token != null && token.isNotEmpty) {
        _apiTokenController.text = token;
        await _tryInitializeAndConnect(token);
      }
    } catch (e) {
      // ignore
    }
  }

  Future<void> _tryInitializeAndConnect(String token) async {
    setState(() => _isLoading = true);
    try {
      _wsClient?.disconnect();
      _wsClient = DerivWSClient(appId: _derivAppId);
      _wsClient!.connect();

      _wsSubscription?.cancel();
      _wsSubscription = _wsClient!.messages.listen((msg) {
        _handleWsMessage(msg);
      }, onError: (_) {}, onDone: () {
        if (mounted) setState(() => _isConnected = false);
      });

      _wsClient!.authorizeWithToken(token);

      await _secureStorage.write(key: 'deriv_api_token', value: token);

      setState(() {
        _isConnected = true;
        _isLoading = false;
      });
      _showSuccessDialog();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isConnected = false;
      });
      _showErrorDialog(e.toString());
    }
  }

  Future<void> _connectToDerivAPI(String token) async {
    setState(() => _isLoading = true);

    try {
      _wsClient?.disconnect();
      _wsClient = DerivWSClient(appId: _derivAppId);
      _wsClient!.connect();

      _wsSubscription?.cancel();
      _wsSubscription = _wsClient!.messages.listen((msg) {
        _handleWsMessage(msg);
      }, onError: (_) {}, onDone: () {
        if (mounted) setState(() => _isConnected = false);
      });

      _wsClient!.authorizeWithToken(token);

      await _secureStorage.write(key: 'deriv_api_token', value: token);

      setState(() {
        _isConnected = true;
        _isLoading = false;
      });

      _showSuccessDialog();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isConnected = false;
      });
      _showErrorDialog(e.toString());
    }
  }

  // ----------------------------
  // WS message handling
  // ----------------------------
  void _handleWsMessage(String? message) {
    if (message == null) return;

    dynamic data;
    try {
      data = jsonDecode(message);
    } catch (e) {
      data = null;
    }

    if (data is Map<String, dynamic>) {
      if (data.containsKey('authorize')) {
        final auth = data['authorize'];
        String accountText = 'Conta conectada';
        if (auth is Map<String, dynamic>) {
          if (auth.containsKey('loginid')) {
            accountText = auth['loginid'].toString();
          } else if (auth.containsKey('client_id')) {
            accountText = auth['client_id'].toString();
          } else if (auth.containsKey('account_email')) {
            accountText = auth['account_email'].toString();
          }
        } else if (auth is String) {
          accountText = auth;
        }

        if (mounted) {
          setState(() {
            _accountInfo = accountText;
            _isConnected = true;
          });
        }
      }

      if (data.containsKey('balance')) {
        final b = data['balance'];
        double? parsed;
        if (b is String) parsed = double.tryParse(b);
        else if (b is num) parsed = b.toDouble();
        else if (b is Map) {
          final inner = b['balance'] ?? b['amount'];
          if (inner is String) parsed = double.tryParse(inner);
          if (inner is num) parsed = inner.toDouble();
        }

        if (parsed != null && mounted) {
          setState(() {
            _balance = parsed;
          });
        }
      }
    }
  }

  // ----------------------------
  // OAuth: abrir URL de autorização e esperar callback com flutter_web_auth
  // ----------------------------
  String _generateRandomState([int length = 24]) {
    final rand = Random.secure();
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(length, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  Future<void> _startOAuthFlow() async {
    final state = _generateRandomState();
    final authUri = Uri.parse('https://oauth.deriv.com/oauth2/authorize').replace(queryParameters: {
      'app_id': _derivAppId.toString(),
      'redirect_uri': _redirectHttps,
      'state': state,
      'response_type': 'token', // pedir implicit token (se suportado)
      'scope': 'trade read',
    });

    final url = authUri.toString();

    try {
      // flutter_web_auth abre o browser e espera o callback de volta ao app scheme
      final result = await FlutterWebAuth.authenticate(
        url: url,
        callbackUrlScheme: _customScheme, // com.nexa.madeeasy
      );

      // result é a URI completa da callback (p.ex.: com.nexa.madeeasy://oauth?access_token=...)
      final callbackUri = Uri.parse(result);
      _handleIncomingUri(callbackUri);
    } catch (e) {
      // Se o user cancelar ou houver erro
      _showErrorDialog('Autenticação interrompida: $e');
    }
  }

  // ----------------------------
  // UI dialogs
  // ----------------------------
  void _showSuccessDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('✅ Conectado'),
        content: Text('Conta Deriv conectada com sucesso!'),
        actions: [
          CupertinoDialogAction(
            child: Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String error) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('❌ Erro'),
        content: Text('Falha: $error'),
        actions: [
          CupertinoDialogAction(
            child: Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  // ----------------------------
  // UI: mantive o design original
  // ----------------------------
  void _showLoginSheet() {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

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
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
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
                    'Conectar Deriv',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: isDark ? CupertinoColors.white : CupertinoColors.black,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Insira seu token API da Deriv para começar',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                  SizedBox(height: 24),
                  CupertinoTextField(
                    controller: _apiTokenController,
                    placeholder: 'Token API',
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? Color(0xFF2C2C2E) : Color(0xFFF2F2F7),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? Color(0xFF3A3A3C) : CupertinoColors.systemGrey5,
                        width: 1,
                      ),
                    ),
                    style: TextStyle(
                      color: isDark ? CupertinoColors.white : CupertinoColors.black,
                      fontSize: 16,
                    ),
                    placeholderStyle: TextStyle(
                      color: CupertinoColors.systemGrey,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton(
                      color: Color(0xFFFF444F),
                      borderRadius: BorderRadius.circular(16),
                      padding: EdgeInsets.symmetric(vertical: 16),
                      onPressed: () {
                        Navigator.pop(context);
                        final token = _apiTokenController.text.trim();
                        if (token.isNotEmpty) {
                          _connectToDerivAPI(token);
                        } else {
                          _showErrorDialog('Token vazio');
                        }
                      },
                      child: _isLoading
                          ? CupertinoActivityIndicator(color: CupertinoColors.white)
                          : Text(
                              'Conectar',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 17,
                                letterSpacing: 0.3,
                              ),
                            ),
                    ),
                  ),
                  SizedBox(height: 8),

                  // === ADICIONADO: botão claro para iniciar OAuth via browser (serverless) ===
                  Center(
                    child: CupertinoButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _startOAuthFlow();
                      },
                      child: Text(
                        'Autorizar via navegador (OAuth)',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFFF444F),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 4),

                  Center(
                    child: CupertinoButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showApiGuide();
                      },
                      child: Text(
                        'Como obter meu token API?',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFFF444F),
                        ),
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

  void _showApiGuide() {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        child: ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: (isDark ? Color(0xFF1C1C1E) : CupertinoColors.white).withOpacity(0.95),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: CupertinoColors.systemGrey.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Guia de Configuração API',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: isDark ? CupertinoColors.white : CupertinoColors.black,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      physics: BouncingScrollPhysics(),
                      children: [
                        _buildGuideStep(
                          isDark,
                          '1',
                          'Acesse sua conta Deriv',
                          'Faça login em app.deriv.com',
                          CupertinoIcons.arrow_right_circle_fill,
                        ),
                        _buildGuideStep(
                          isDark,
                          '2',
                          'Vá para API Token',
                          'Clique no menu → Settings → API Token',
                          CupertinoIcons.settings_solid,
                        ),
                        _buildGuideStep(
                          isDark,
                          '3',
                          'Crie um novo token',
                          'Clique em "Create" e selecione as permissões:\n• Read\n• Trade\n• Trading Information',
                          CupertinoIcons.add_circled_solid,
                        ),
                        _buildGuideStep(
                          isDark,
                          '4',
                          'Copie o token',
                          'Copie o token gerado e cole no app',
                          CupertinoIcons.doc_on_clipboard_fill,
                        ),
                        SizedBox(height: 24),
                        Container(
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Color(0xFFFF444F).withOpacity(0.12),
                                Color(0xFFFF444F).withOpacity(0.06),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Color(0xFFFF444F).withOpacity(0.25),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Color(0xFFFF444F).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  CupertinoIcons.exclamationmark_shield_fill,
                                  color: Color(0xFFFF444F),
                                  size: 24,
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  'Mantenha seu token seguro e nunca o compartilhe',
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: isDark ? CupertinoColors.white : CupertinoColors.black,
                                    fontWeight: FontWeight.w600,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 40),
                      ],
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

  Widget _buildGuideStep(bool isDark, String number, String title, String description, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Color(0xFFFF444F),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0xFFFF444F).withOpacity(0.3),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: CupertinoColors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 20, color: Color(0xFFFF444F)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: isDark ? CupertinoColors.white : CupertinoColors.black,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark
                        ? CupertinoColors.white.withOpacity(0.7)
                        : CupertinoColors.black.withOpacity(0.6),
                    height: 1.5,
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

  void _disconnect() async {
    await _secureStorage.delete(key: 'deriv_api_token');
    _wsSubscription?.cancel();
    _wsClient?.disconnect();
    setState(() {
      _isConnected = false;
      _accountInfo = null;
      _balance = null;
      _apiTokenController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return CupertinoPageScaffold(
      backgroundColor: isDark ? Color(0xFF000000) : Color(0xFFF2F2F7),
      child: CustomScrollView(
        physics: BouncingScrollPhysics(),
        slivers: [
          CupertinoSliverNavigationBar(
            backgroundColor: (isDark ? Color(0xFF1C1C1E) : CupertinoColors.white).withOpacity(0.95),
            border: null,
            largeTitle: Text(
              'Trading',
              style: TextStyle(
                color: isDark ? CupertinoColors.white : CupertinoColors.black,
                fontWeight: FontWeight.w800,
              ),
            ),
            trailing: _isConnected
                ? CupertinoButton(
                    padding: EdgeInsets.zero,
                    minSize: 0,
                    onPressed: _disconnect,
                    child: Icon(
                      CupertinoIcons.power,
                      color: Color(0xFFFF444F),
                      size: 24,
                    ),
                  )
                : null,
          ),
          SliverToBoxAdapter(
            child: _isConnected ? _buildConnectedView(isDark) : _buildDisconnectedView(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildDisconnectedView(bool isDark) {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          SizedBox(height: 40),
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFFF444F),
                  Color(0xFFFF6B6B),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0xFFFF444F).withOpacity(0.4),
                  blurRadius: 30,
                  offset: Offset(0, 15),
                ),
              ],
            ),
            child: Icon(
              CupertinoIcons.chart_bar_alt_fill,
              size: 60,
              color: CupertinoColors.white,
            ),
          ),
          SizedBox(height: 32),
          Text(
            'Bem-vindo ao Trading',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: isDark ? CupertinoColors.white : CupertinoColors.black,
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: 12),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Conecte sua conta Deriv para começar a negociar nos mercados financeiros',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: CupertinoColors.systemGrey,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(height: 48),
          _buildFeatureCard(
            isDark,
            CupertinoIcons.speedometer,
            'Trading Rápido',
            'Execute trades em segundos',
          ),
          SizedBox(height: 16),
          _buildFeatureCard(
            isDark,
            CupertinoIcons.chart_bar_square_fill,
            'Análise em Tempo Real',
            'Gráficos e indicadores avançados',
          ),
          SizedBox(height: 16),
          _buildFeatureCard(
            isDark,
            CupertinoIcons.lock_shield_fill,
            'Seguro e Confiável',
            'Powered by Deriv API',
          ),
          SizedBox(height: 48),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _showLoginSheet,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: Color(0xFFFF444F),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFFFF444F).withOpacity(0.4),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.link, size: 22, color: CupertinoColors.white),
                  SizedBox(width: 10),
                  Text(
                    'Conectar Conta Deriv',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: CupertinoColors.white,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(bool isDark, IconData icon, String title, String subtitle) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1C1C1E) : CupertinoColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Color(0xFF2C2C2E) : CupertinoColors.systemGrey6,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Color(0xFFFF444F).withOpacity(0.12),
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
                    fontWeight: FontWeight.w500,
                    color: CupertinoColors.systemGrey,
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
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFFF444F),
                  Color(0xFFFF6B6B),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Color(0xFFFF444F).withOpacity(0.4),
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Saldo Disponível',
                          style: TextStyle(
                            color: CupertinoColors.white.withOpacity(0.85),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '\$${_balance?.toStringAsFixed(2) ?? '0.00'}',
                          style: TextStyle(
                            color: CupertinoColors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: CupertinoColors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        CupertinoIcons.money_dollar_circle_fill,
                        color: CupertinoColors.white,
                        size: 32,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Icon(
                      CupertinoIcons.checkmark_seal_fill,
                      size: 16,
                      color: CupertinoColors.white.withOpacity(0.9),
                    ),
                    SizedBox(width: 6),
                    Text(
                      _accountInfo ?? 'Conta Deriv',
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
          ),
          SizedBox(height: 32),
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: Color(0xFFFF444F),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Ações Rápidas',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: isDark ? CupertinoColors.white : CupertinoColors.black,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  isDark,
                  CupertinoIcons.arrow_up_circle_fill,
                  'Comprar',
                  CupertinoColors.systemGreen,
                  () {
                    // exemplo: implementar fluxo de proposta->buy aqui
                  },
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  isDark,
                  CupertinoIcons.arrow_down_circle_fill,
                  'Vender',
                  Color(0xFFFF444F),
                  () {
                    // exemplo: implementar fluxo de proposta->buy aqui
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 32),
          Row(
            children: [
              Container(
                width: 4,
                height: 24,
                decoration: BoxDecoration(
                  color: Color(0xFFFF444F),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              SizedBox(width: 12),
              Text(
                'Em Desenvolvimento',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: isDark ? CupertinoColors.white : CupertinoColors.black,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFFF444F).withOpacity(0.12),
                  Color(0xFFFF444F).withOpacity(0.06),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Color(0xFFFF444F).withOpacity(0.25),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Color(0xFFFF444F).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    CupertinoIcons.hammer_fill,
                    color: Color(0xFFFF444F),
                    size: 24,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Funcionalidades de trading completas em breve',
                    style: TextStyle(
                      color: isDark ? CupertinoColors.white : CupertinoColors.black,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildActionButton(bool isDark, IconData icon, String label, Color color, VoidCallback onTap) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 36),
            SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 16,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cliente WebSocket mínimo para Deriv
class DerivWSClient {
  final int appId;
  final String endpoint;
  WebSocketChannel? _channel;
  final StreamController<String?> _messagesController = StreamController.broadcast();

  Stream<String?> get messages => _messagesController.stream;

  DerivWSClient({required this.appId})
      : endpoint = 'wss://ws.derivws.com/websockets/v3?app_id=$appId';

  void connect() {
    disconnect();
    try {
      _channel = WebSocketChannel.connect(Uri.parse(endpoint));
      _channel!.stream.listen((dynamic msg) {
        _messagesController.add(msg?.toString());
      }, onError: (err) {
        _messagesController.addError(err);
      }, onDone: () {
        try {
          _messagesController.close();
        } catch (_) {}
      });
    } catch (e) {
      _messagesController.addError(e);
    }
  }

  void authorizeWithToken(String token) {
    if (_channel == null) return;
    final payload = jsonEncode({'authorize': token});
    _channel!.sink.add(payload);
  }

  void getBalance(String currency) {
    if (_channel == null) return;
    final payload = jsonEncode({'balance': 1, 'currency': currency});
    _channel!.sink.add(payload);
  }

  void sendRaw(Map<String, dynamic> payload) {
    if (_channel == null) return;
    _channel!.sink.add(jsonEncode(payload));
  }

  void disconnect() {
    try {
      _channel?.sink.close();
    } catch (_) {}
    _channel = null;
  }
}