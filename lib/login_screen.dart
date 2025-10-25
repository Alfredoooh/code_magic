// login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
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
  bool _isCheckingSession = true;
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
    _checkExistingSession();
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkExistingSession() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString('deriv_token');
    final hasSeenDisclaimer = prefs.getBool('has_seen_disclaimer') ?? false;

    if (savedToken != null && savedToken.isNotEmpty) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => HomeScreen(token: savedToken),
        ),
      );
    } else {
      setState(() => _isCheckingSession = false);
      _animationController.forward();
      
      // Mostra disclaimer se ainda não viu
      if (!hasSeenDisclaimer) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _showTradingDisclaimer();
          }
        });
      }
    }
  }

  Future<void> _showTradingDisclaimer() async {
    await showModalBottomSheet(
      context: context,
      isScrollable: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (context) => const TradingDisclaimerSheet(),
    );
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_disclaimer', true);
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('deriv_token', token);
  }

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

        if (accounts.length > 1) {
          final selectedAccount = await _showAccountSelectionDialog(accounts);
          if (selectedAccount == null) {
            setState(() => _isLoading = false);
            return;
          }

          await _saveToken(selectedAccount['token']!);

          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => HomeScreen(token: selectedAccount['token']!),
            ),
          );
        } else {
          final firstAccount = accounts.first;
          await _saveToken(firstAccount['token']!);

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
                    title: Text(
                      account['account'] ?? '',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      account['currency'] ?? 'USD',
                      style: const TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white54, size: 16),
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

    await _saveToken(token);

    if (!mounted) return;
    setState(() => _isLoading = false);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => HomeScreen(token: token)),
    );
  }

  Future<void> _openWhatsApp() async {
    final uri = Uri.parse('https://wa.me/258840000000');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openEmail() async {
    final uri = Uri.parse('mailto:suporte@zoomtrade.com');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openRegister() async {
    final uri = Uri.parse('https://deriv.com/signup/');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingSession) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF0066FF)),
        ),
      );
    }

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
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      'assets/icon/icon.png',
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0066FF),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        );
                      },
                    ),
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
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _loginWithDeriv,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0066FF),
                      disabledBackgroundColor: const Color(0xFF0066FF).withOpacity(0.5),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Login com Email/Senha Deriv',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
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
                    prefixIcon: Icon(Icons.vpn_key_rounded, color: Colors.white54),
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
                const SizedBox(height: 16),
                SizedBox(
                  height: 52,
                  child: OutlinedButton(
                    onPressed: _openRegister,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF2A2A2A)),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Criar Conta Deriv', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
                  ),
                ),
                const Spacer(flex: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Precisa de ajuda?',
                      style: TextStyle(color: Colors.white54, fontSize: 15),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      onPressed: _openWhatsApp,
                      icon: const Icon(Icons.chat_rounded, color: Color(0xFF25D366)),
                    ),
                    IconButton(
                      onPressed: _openEmail,
                      icon: const Icon(Icons.email_rounded, color: Color(0xFF0066FF)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Trading Disclaimer Sheet
class TradingDisclaimerSheet extends StatelessWidget {
  const TradingDisclaimerSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Aviso Importante',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              _buildDisclaimerItem(
                Icons.warning_rounded,
                'Risco Elevado',
                'Trading envolve risco significativo de perda. Apenas negocie com dinheiro que você pode perder.',
              ),
              const SizedBox(height: 16),
              _buildDisclaimerItem(
                Icons.trending_down_rounded,
                'Volatilidade',
                'Os mercados podem ser extremamente voláteis. Os preços podem mudar rapidamente.',
              ),
              const SizedBox(height: 16),
              _buildDisclaimerItem(
                Icons.school_rounded,
                'Educação',
                'Certifique-se de entender completamente os produtos antes de negociar.',
              ),
              const SizedBox(height: 16),
              _buildDisclaimerItem(
                Icons.verified_user_rounded,
                'Responsabilidade',
                'Você é totalmente responsável por suas decisões de trading.',
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0066FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Continuar',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDisclaimerItem(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFFFF9500), size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
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

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final uri = Uri.parse(request.url);

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
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}