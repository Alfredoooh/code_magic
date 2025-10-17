import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import 'package:flutter_deriv_api/api/api_initializer.dart';
import 'package:flutter_deriv_api/basic_api/generated/api.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  @override
  void initState() {
    super.initState();
    _loadSavedToken();
  }

  @override
  void dispose() {
    _apiTokenController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('deriv_api_token');
    if (token != null) {
      _apiTokenController.text = token;
      _connectToDerivAPI(token);
    }
  }

  Future<void> _connectToDerivAPI(String token) async {
    setState(() => _isLoading = true);

    try {
      // Inicializar a API da Deriv
      await APIInitializer().initialize(
        apiToken: token,
        isMock: false, // Mude para true para usar API de teste
      );

      // Obter informações da conta
      final authorize = await AuthorizeRequest(authorize: token).fetchAuthorize();
      
      setState(() {
        _isConnected = true;
        _accountInfo = authorize.authorize?.email ?? 'Conta conectada';
        _balance = authorize.authorize?.balance;
        _isLoading = false;
      });

      // Salvar token
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('deriv_api_token', token);

      _showSuccessDialog();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isConnected = false;
      });
      _showErrorDialog(e.toString());
    }
  }

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
        content: Text('Falha na conexão: $error'),
        actions: [
          CupertinoDialogAction(
            child: Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showLoginSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: (isDark ? Color(0xFF1C1C1E) : Colors.white).withOpacity(0.95),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                        color: Colors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Conectar Deriv',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Insira seu token API da Deriv para começar',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 24),
                  CupertinoTextField(
                    controller: _apiTokenController,
                    placeholder: 'Token API',
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? Color(0xFF2C2C2E) : Color(0xFFF2F2F7),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    placeholderStyle: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton(
                      color: Color(0xFFFF444F),
                      borderRadius: BorderRadius.circular(12),
                      onPressed: () {
                        Navigator.pop(context);
                        if (_apiTokenController.text.isNotEmpty) {
                          _connectToDerivAPI(_apiTokenController.text);
                        }
                      },
                      child: _isLoading
                          ? CupertinoActivityIndicator(color: Colors.white)
                          : Text(
                              'Conectar',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                  SizedBox(height: 12),
                  Center(
                    child: CupertinoButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showApiGuide();
                      },
                      child: Text(
                        'Como obter meu token API?',
                        style: TextStyle(
                          fontSize: 14,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        child: ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: (isDark ? Color(0xFF1C1C1E) : Colors.white).withOpacity(0.95),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Guia de Configuração API',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.all(24),
                      children: [
                        _buildGuideStep(
                          isDark,
                          '1',
                          'Acesse sua conta Deriv',
                          'Faça login em app.deriv.com',
                          Icons.login_rounded,
                        ),
                        _buildGuideStep(
                          isDark,
                          '2',
                          'Vá para API Token',
                          'Clique no menu → Settings → API Token',
                          Icons.settings_rounded,
                        ),
                        _buildGuideStep(
                          isDark,
                          '3',
                          'Crie um novo token',
                          'Clique em "Create" e selecione as permissões:\n• Read\n• Trade\n• Trading Information',
                          Icons.add_circle_rounded,
                        ),
                        _buildGuideStep(
                          isDark,
                          '4',
                          'Copie o token',
                          'Copie o token gerado e cole no app',
                          Icons.copy_rounded,
                        ),
                        SizedBox(height: 24),
                        Container(
                          padding: EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Color(0xFFFF444F).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Color(0xFFFF444F).withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_rounded,
                                color: Color(0xFFFF444F),
                                size: 24,
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Mantenha seu token seguro e nunca o compartilhe',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? Colors.white : Colors.black87,
                                    fontWeight: FontWeight.w500,
                                  ),
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
          ),
        ),
      ),
    );
  }

  Widget _buildGuideStep(bool isDark, String number, String title, String description, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Color(0xFFFF444F),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
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
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    height: 1.5,
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('deriv_api_token');
    setState(() {
      _isConnected = false;
      _accountInfo = null;
      _balance = null;
      _apiTokenController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? Color(0xFF0E0E0E) : Color(0xFFF5F5F5),
      body: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar(
            backgroundColor: (isDark ? Color(0xFF1C1C1E) : Colors.white).withOpacity(0.9),
            border: Border(
              bottom: BorderSide(
                color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
                width: 0.5,
              ),
            ),
            largeTitle: Text(
              'Trading',
              style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
            trailing: _isConnected
                ? CupertinoButton(
                    padding: EdgeInsets.zero,
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
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          SizedBox(height: 60),
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
                  color: Color(0xFFFF444F).withOpacity(0.3),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              Icons.show_chart_rounded,
              size: 60,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 32),
          Text(
            'Bem-vindo ao Trading',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Conecte sua conta Deriv para começar\na negociar nos mercados financeiros',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
              height: 1.5,
            ),
          ),
          SizedBox(height: 48),
          _buildFeatureCard(
            isDark,
            Icons.speed_rounded,
            'Trading Rápido',
            'Execute trades em segundos',
          ),
          SizedBox(height: 16),
          _buildFeatureCard(
            isDark,
            Icons.analytics_rounded,
            'Análise em Tempo Real',
            'Gráficos e indicadores avançados',
          ),
          SizedBox(height: 16),
          _buildFeatureCard(
            isDark,
            Icons.security_rounded,
            'Seguro e Confiável',
            'Powered by Deriv API',
          ),
          SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            child: CupertinoButton(
              color: Color(0xFFFF444F),
              borderRadius: BorderRadius.circular(16),
              padding: EdgeInsets.symmetric(vertical: 16),
              onPressed: _showLoginSheet,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.link_rounded, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Conectar Conta Deriv',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(bool isDark, IconData icon, String title, String subtitle) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Color(0xFFFF444F).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Color(0xFFFF444F), size: 24),
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
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                SizedBox(height: 4),
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
        ],
      ),
    );
  }

  Widget _buildConnectedView(bool isDark) {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFFF444F),
                  Color(0xFFFF6B6B),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Saldo Disponível',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          '\$${_balance?.toStringAsFixed(2) ?? '0.00'}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Text(
                  _accountInfo ?? 'Conta Deriv',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Ações Rápidas',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  isDark,
                  Icons.trending_up_rounded,
                  'Comprar',
                  Color(0xFF4CAF50),
                  () {},
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  isDark,
                  Icons.trending_down_rounded,
                  'Vender',
                  Color(0xFFFF444F),
                  () {},
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          Text(
            'Em Desenvolvimento',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFFFF444F).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Color(0xFFFF444F).withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.info_rounded, color: Color(0xFFFF444F)),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Funcionalidades de trading completas em breve',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(bool isDark, IconData icon, String label, Color color, VoidCallback onTap) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withOpacity(0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}