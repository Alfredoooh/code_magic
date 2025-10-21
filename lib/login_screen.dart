import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'styles.dart';
import 'main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _tokenController = TextEditingController();
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Configuração OAuth
  static const String DERIV_APP_ID = '71954';
  static const String REDIRECT_URL = 'https://alfredoooh.github.io/database/oauth-redirect/';
  static const String APP_SCHEME = 'com.nexa.madeeasy';

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

  /// Login via OAuth2 com conta Deriv
  Future<void> _loginWithDeriv() async {
    setState(() => _isLoading = true);

    try {
      final authUrl = Uri.https('oauth.deriv.com', '/oauth2/authorize', {
        'app_id': DERIV_APP_ID,
        'l': 'PT',
        'redirect_uri': REDIRECT_URL,
        'prompt': 'login', // Força a tela de login
      }).toString();
      
      final result = await FlutterWebAuth2.authenticate(
        url: authUrl,
        callbackUrlScheme: APP_SCHEME,
        options: const FlutterWebAuth2Options(
          preferEphemeral: true, // Modo privado - não usa sessões anteriores
        ),
      );

      final uri = Uri.parse(result);
      final accounts = _extractAccountsFromUrl(uri);

      if (accounts.isEmpty) {
        throw Exception('Nenhuma conta encontrada');
      }

      // Se houver múltiplas contas, mostra dialog para escolher
      if (accounts.length > 1 && mounted) {
        final selectedAccount = await _showAccountSelectionDialog(accounts);
        if (selectedAccount == null) {
          // Usuário cancelou a seleção
          setState(() => _isLoading = false);
          return;
        }
        
        if (!mounted) return;
        
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => MainScreen(
              token: selectedAccount['token']!,
              accountId: selectedAccount['account'],
            ),
          ),
        );
      } else {
        // Apenas uma conta, usa ela diretamente
        final firstAccount = accounts.first;
        
        if (!mounted) return;
        
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => MainScreen(
              token: firstAccount['token']!,
              accountId: firstAccount['account'],
            ),
          ),
        );
      }

    } catch (e) {
      if (!mounted) return;
      
      String errorMessage = 'Erro ao conectar com Deriv';
      if (e.toString().contains('CANCELED')) {
        errorMessage = 'Login cancelado';
      }
      
      AppStyles.showSnackBar(context, errorMessage, isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Mostra dialog para selecionar conta quando há múltiplas
  Future<Map<String, String>?> _showAccountSelectionDialog(List<Map<String, String>> accounts) async {
    return showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppStyles.bgSecondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Selecione sua conta',
            style: TextStyle(
              color: AppStyles.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: accounts.length,
              itemBuilder: (context, index) {
                final account = accounts[index];
                return Card(
                  color: AppStyles.bgPrimary,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: AppStyles.border, width: 0.5),
                  ),
                  child: ListTile(
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppStyles.iosBlue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.account_circle,
                        color: AppStyles.iosBlue,
                      ),
                    ),
                    title: Text(
                      account['account'] ?? '',
                      style: const TextStyle(
                        color: AppStyles.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      account['currency'] ?? 'USD',
                      style: const TextStyle(
                        color: AppStyles.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      color: AppStyles.textSecondary,
                      size: 16,
                    ),
                    onTap: () => Navigator.of(context).pop(account),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text(
                'Cancelar',
                style: TextStyle(color: AppStyles.iosRed),
              ),
            ),
          ],
        );
      },
    );
  }

  List<Map<String, String>> _extractAccountsFromUrl(Uri uri) {
    final accounts = <Map<String, String>>[];
    final params = uri.queryParameters;

    int index = 1;
    while (params.containsKey('acct$index')) {
      final account = params['acct$index'];
      final token = params['token$index'];
      final currency = params['cur$index'];

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

  /// Login via Token de API manual
  Future<void> _login() async {
    final token = _tokenController.text.trim();
    
    if (token.isEmpty) {
      AppStyles.showSnackBar(context, 'Por favor, insira seu token', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    setState(() => _isLoading = false);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => MainScreen(token: token),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.bgPrimary,
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
                
                // Logo com imagem do assets
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      'assets/icon/icon.png',
                      width: 80,
                      height: 80,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppStyles.iosBlue,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: AppStyles.iosBlue.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.trending_up,
                            size: 40,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Título ZoomTrade
                const Text(
                  'ZoomTrade',
                  style: TextStyle(
                    color: AppStyles.textPrimary,
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 8),
                
                const Text(
                  'Conecte-se com sua conta Deriv',
                  style: TextStyle(
                    color: AppStyles.textSecondary,
                    fontSize: 17,
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 48),
                
                // Botão OAuth Deriv
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _loginWithDeriv,
                    icon: _isLoading
                        ? const SizedBox.shrink()
                        : const Icon(Icons.account_circle, size: 20),
                    label: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Entrar com Conta Deriv',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppStyles.iosBlue,
                      disabledBackgroundColor: AppStyles.iosBlue.withOpacity(0.5),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Divisor
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 0.5,
                        color: AppStyles.border,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'ou',
                        style: TextStyle(
                          color: AppStyles.textSecondary,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 0.5,
                        color: AppStyles.border,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Campo de token
                TextField(
                  controller: _tokenController,
                  decoration: const InputDecoration(
                    labelText: 'Token de API',
                    hintText: 'Cole seu token aqui',
                    prefixIcon: Icon(Icons.vpn_key, color: AppStyles.textSecondary),
                  ),
                  style: const TextStyle(color: AppStyles.textPrimary),
                  enabled: !_isLoading,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_\-]')),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Botão de login com token
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppStyles.bgSecondary,
                      foregroundColor: AppStyles.iosBlue,
                      disabledBackgroundColor: AppStyles.bgSecondary.withOpacity(0.5),
                    ),
                    child: const Text(
                      'Conectar com Token',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                
                const Spacer(flex: 2),
                
                // Informação do App ID
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppStyles.bgSecondary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppStyles.border, width: 0.5),
                  ),
                  child: Row(
                    children: const [
                      Icon(
                        Icons.security_rounded,
                        color: AppStyles.iosGreen,
                        size: 20,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'App ID: 71954',
                              style: TextStyle(
                                color: AppStyles.textPrimary,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Conexão segura com Deriv',
                              style: TextStyle(
                                color: AppStyles.textSecondary,
                                fontSize: 12,
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
    );
  }
}
