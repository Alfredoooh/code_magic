// login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';
import 'styles.dart';
import 'home_screen.dart';

class DerivLoginScreen extends StatefulWidget {
  const DerivLoginScreen({Key? key}) : super(key: key);

  @override
  State<DerivLoginScreen> createState() => _DerivLoginScreenState();
}

class _DerivLoginScreenState extends State<DerivLoginScreen> with SingleTickerProviderStateMixin {
  final _tokenController = TextEditingController();
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  static const String DERIV_APP_ID = '71954';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  /// Login via OAuth2 com conta Deriv - DENTRO DO APP
  Future<void> _loginWithDeriv() async {
    setState(() => _isLoading = true);

    try {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const DerivWebViewLogin(),
          fullscreenDialog: true,
        ),
      );

      if (result != null && result is Map<String, dynamic>) {
        final accounts = result['accounts'] as List<Map<String, String>>;
        
        if (accounts.isEmpty) {
          throw Exception('Nenhuma conta encontrada');
        }

        // Se houver múltiplas contas, mostra seleção
        if (accounts.length > 1) {
          final selectedAccount = await _showAccountSelectionDialog(accounts);
          if (selectedAccount == null) {
            setState(() => _isLoading = false);
            return;
          }

          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => HomeScreen(token: selectedAccount['token']!),
            ),
          );
        } else {
          final firstAccount = accounts.first;
          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => HomeScreen(token: firstAccount['token']!),
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      AppStyles.showSnackBar(
        context,
        'Erro ao conectar com Deriv',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<Map<String, String>?> _showAccountSelectionDialog(List<Map<String, String>> accounts) async {
    return showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(
            'Selecione sua conta',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: accounts.length,
              itemBuilder: (context, index) {
                final account = accounts[index];
                return Card(
                  color: const Color(0xFF000000),
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Color(0xFF2A2A2A), width: 0.5),
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0066FF).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.account_circle, color: Color(0xFF0066FF)),
                    ),
                    title: Text(
                      account['account'] ?? '',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      account['currency'] ?? 'USD',
                      style: const TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
                    onTap: () => Navigator.of(context).pop(account),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Cancelar', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _login() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      AppStyles.showSnackBar(context, 'Por favor, insira seu token', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;
    setState(() => _isLoading = false);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => HomeScreen(token: token)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0066FF),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0066FF).withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.trending_up, size: 40, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'ZoomTrade',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Faça login com sua conta Deriv',
                  style: TextStyle(color: Colors.white54, fontSize: 17),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _loginWithDeriv,
                    icon: _isLoading ? const SizedBox.shrink() : const Icon(Icons.account_circle, size: 20),
                    label: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Login com Email/Senha Deriv', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0066FF),
                      disabledBackgroundColor: const Color(0xFF0066FF).withOpacity(0.5),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: Container(height: 0.5, color: const Color(0xFF2A2A2A))),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('ou', style: TextStyle(color: Colors.white54, fontSize: 15)),
                    ),
                    Expanded(child: Container(height: 0.5, color: const Color(0xFF2A2A2A))),
                  ],
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _tokenController,
                  decoration: const InputDecoration(
                    labelText: 'Token de API',
                    hintText: 'Cole seu token aqui',
                    prefixIcon: Icon(Icons.vpn_key, color: Colors.white54),
                    labelStyle: TextStyle(color: Colors.white70),
                    hintStyle: TextStyle(color: Colors.white30),
                  ),
                  style: const TextStyle(color: Colors.white),
                  enabled: !_isLoading,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_\-]')),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A1A1A),
                      foregroundColor: const Color(0xFF0066FF),
                    ),
                    child: const Text('Conectar com Token', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                  ),
                ),
                const Spacer(flex: 2),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF2A2A2A), width: 0.5),
                  ),
                  child: const Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.security_rounded, color: Color(0xFF00C896), size: 20),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Conexão Segura', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                                SizedBox(height: 2),
                                Text('Seus dados são protegidos pela Deriv', style: TextStyle(color: Colors.white54, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text('Não tem conta? Crie uma em deriv.com', style: TextStyle(color: Colors.white54, fontSize: 11), textAlign: TextAlign.center),
                    ],
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

// WebView para login dentro do app
class DerivWebViewLogin extends StatefulWidget {
  const DerivWebViewLogin({Key? key}) : super(key: key);

  @override
  State<DerivWebViewLogin> createState() => _DerivWebViewLoginState();
}

class _DerivWebViewLoginState extends State<DerivWebViewLogin> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) => setState(() => _isLoading = true),
          onPageFinished: (url) => setState(() => _isLoading = false),
          onNavigationRequest: (request) {
            final uri = Uri.parse(request.url);
            
            // Detecta o redirect com os tokens
            if (uri.queryParameters.containsKey('acct1') && 
                uri.queryParameters.containsKey('token1')) {
              
              final accounts = _extractAccounts(uri);
              Navigator.pop(context, {'accounts': accounts});
              return NavigationDecision.prevent;
            }
            
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(
        Uri.parse(
          'https://oauth.deriv.com/oauth2/authorize?app_id=71954&l=PT'
        ),
      );
  }

  List<Map<String, String>> _extractAccounts(Uri uri) {
    final accounts = <Map<String, String>>[];
    int index = 1;
    
    while (uri.queryParameters.containsKey('acct$index')) {
      final account = uri.queryParameters['acct$index'];
      final token = uri.queryParameters['token$index'];
      final currency = uri.queryParameters['cur$index'];

      if (account != null && token != null) {
        accounts.add({
          'account': account,
          'token': token,
          'currency': currency ?? 'USD',
        });
      }
      index++;
    }
    
    return accounts;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Login Deriv'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFF0066FF)),
            ),
        ],
      ),
    );
  }
}