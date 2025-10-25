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

class _DerivLoginScreenState extends State<DerivLoginScreen> {
  final _tokenController = TextEditingController();
  bool _isLoading = false;
  bool _isCheckingSession = true;

  static const String DERIV_APP_ID = '71954';

  @override
  void initState() {
    super.initState();
    _checkExistingSession();
  }

  @override
  void dispose() {
    _tokenController.dispose();
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

      if (!hasSeenDisclaimer) {
        Future.delayed(AppMotion.short, () {
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
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
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
    AppHaptics.medium();

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
          AppHaptics.success();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => HomeScreen(token: selectedAccount['token']!),
            ),
          );
        } else {
          final firstAccount = accounts.first;
          await _saveToken(firstAccount['token']!);

          if (!mounted) return;
          AppHaptics.success();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => HomeScreen(token: firstAccount['token']!),
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      AppHaptics.error();
      AppSnackbar.error(context, 'Erro ao conectar com Deriv');
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
          backgroundColor: context.colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          ),
          title: Text(
            'Selecione sua conta',
            style: context.textStyles.titleLarge,
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: accounts.length,
              itemBuilder: (context, index) {
                final account = accounts[index];
                return FadeInWidget(
                  delay: Duration(milliseconds: 100 * index),
                  child: Card(
                    margin: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: ListTile(
                      title: Text(
                        account['account'] ?? '',
                        style: context.textStyles.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        account['currency'] ?? 'USD',
                        style: context.textStyles.bodyMedium?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                      trailing: Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: context.colors.onSurfaceVariant,
                        size: 16,
                      ),
                      onTap: () {
                        AppHaptics.selection();
                        Navigator.of(context).pop(account);
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                AppHaptics.light();
                Navigator.of(context).pop(null);
              },
              child: Text(
                'Cancelar',
                style: TextStyle(color: context.colors.error),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _login() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      AppHaptics.error();
      AppSnackbar.error(context, 'Por favor, insira seu token');
      return;
    }

    setState(() => _isLoading = true);
    AppHaptics.medium();
    await Future.delayed(AppMotion.medium);

    await _saveToken(token);

    if (!mounted) return;
    setState(() => _isLoading = false);
    AppHaptics.success();

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => HomeScreen(token: token)),
    );
  }

  Future<void> _openWhatsApp() async {
    AppHaptics.light();
    final uri = Uri.parse('https://wa.me/258840000000');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openEmail() async {
    AppHaptics.light();
    final uri = Uri.parse('mailto:suporte@zoomtrade.com');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openRegister() async {
    AppHaptics.light();
    final uri = Uri.parse('https://deriv.com/signup/');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingSession) {
      return Scaffold(
        backgroundColor: context.colors.surface,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: context.colors.surface,
      body: LoadingOverlay(
        isLoading: _isLoading,
        message: 'Conectando...',
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                
                // Logo
                FadeInWidget(
                  child: Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
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
                              color: context.colors.primary,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                            ),
                            child: Icon(
                              Icons.trending_up_rounded,
                              color: context.colors.onPrimary,
                              size: 40,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: AppSpacing.xxl),
                
                // Título
                FadeInWidget(
                  delay: const Duration(milliseconds: 100),
                  child: Text(
                    'ZoomTrade',
                    style: context.textStyles.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: -1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                const SizedBox(height: AppSpacing.xs),
                
                FadeInWidget(
                  delay: const Duration(milliseconds: 200),
                  child: Text(
                    'Faça login com sua conta Deriv',
                    style: context.textStyles.bodyLarge?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                const SizedBox(height: AppSpacing.massive),
                
                // Botão Login com Email/Senha
                FadeInWidget(
                  delay: const Duration(milliseconds: 300),
                  child: SizedBox(
                    height: 52,
                    child: AnimatedPrimaryButton(
                      text: 'Login com Email/Senha Deriv',
                      icon: Icons.login_rounded,
                      isLoading: _isLoading,
                      onPressed: _loginWithDeriv,
                    ),
                  ),
                ),
                
                const SizedBox(height: AppSpacing.xl),
                
                // Divider
                FadeInWidget(
                  delay: const Duration(milliseconds: 400),
                  child: Row(
                    children: [
                      Expanded(
                        child: Divider(color: context.colors.outlineVariant),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                        child: Text(
                          'ou',
                          style: context.textStyles.bodyMedium?.copyWith(
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(color: context.colors.outlineVariant),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: AppSpacing.xl),
                
                // Campo de Token
                FadeInWidget(
                  delay: const Duration(milliseconds: 500),
                  child: TextField(
                    controller: _tokenController,
                    decoration: const InputDecoration(
                      labelText: 'Token de API',
                      hintText: 'Cole seu token aqui',
                      prefixIcon: Icon(Icons.vpn_key_rounded),
                    ),
                    enabled: !_isLoading,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_\-]')),
                    ],
                  ),
                ),
                
                const SizedBox(height: AppSpacing.lg),
                
                // Botão Conectar com Token
                FadeInWidget(
                  delay: const Duration(milliseconds: 600),
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _login,
                      icon: const Icon(Icons.link_rounded),
                      label: const Text(
                        'Conectar com Token',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: AppSpacing.lg),
                
                // Botão Criar Conta
                FadeInWidget(
                  delay: const Duration(milliseconds: 700),
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: _openRegister,
                      child: const Text(
                        'Criar Conta Deriv',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                
                const Spacer(flex: 2),
                
                // Suporte com ícones oficiais
                FadeInWidget(
                  delay: const Duration(milliseconds: 800),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Precisa de ajuda?',
                        style: context.textStyles.bodyMedium?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      // WhatsApp oficial
                      InkWell(
                        onTap: _openWhatsApp,
                        borderRadius: BorderRadius.circular(50),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: Image.asset(
                            'assets/icons/whatsapp.png',
                            width: 32,
                            height: 32,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.chat_rounded,
                                color: Color(0xFF25D366),
                                size: 32,
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      // Gmail oficial
                      InkWell(
                        onTap: _openEmail,
                        borderRadius: BorderRadius.circular(50),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          child: Image.asset(
                            'assets/icons/gmail.png',
                            width: 32,
                            height: 32,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.email_rounded,
                                color: context.colors.primary,
                                size: 32,
                              );
                            },
                          ),
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

class TradingDisclaimerSheet extends StatelessWidget {
  const TradingDisclaimerSheet({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FadeInWidget(
                  child: Text(
                    'Aviso Importante',
                    style: context.textStyles.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                FadeInWidget(
                  delay: const Duration(milliseconds: 100),
                  child: _buildDisclaimerItem(
                    context,
                    Icons.warning_rounded,
                    'Risco Elevado',
                    'Trading envolve risco significativo de perda. Apenas negocie com dinheiro que você pode perder.',
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                FadeInWidget(
                  delay: const Duration(milliseconds: 200),
                  child: _buildDisclaimerItem(
                    context,
                    Icons.trending_down_rounded,
                    'Volatilidade',
                    'Os mercados podem ser extremamente voláteis. Os preços podem mudar rapidamente.',
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                FadeInWidget(
                  delay: const Duration(milliseconds: 300),
                  child: _buildDisclaimerItem(
                    context,
                    Icons.school_rounded,
                    'Educação',
                    'Certifique-se de entender completamente os produtos antes de negociar.',
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                FadeInWidget(
                  delay: const Duration(milliseconds: 400),
                  child: _buildDisclaimerItem(
                    context,
                    Icons.verified_user_rounded,
                    'Responsabilidade',
                    'Você é totalmente responsável por suas decisões de trading.',
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                FadeInWidget(
                  delay: const Duration(milliseconds: 500),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: AnimatedPrimaryButton(
                      text: 'Continuar',
                      icon: Icons.check_rounded,
                      onPressed: () {
                        AppHaptics.medium();
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDisclaimerItem(
    BuildContext context,
    IconData icon,
    String title,
    String description,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: AppColors.warning,
          size: 24,
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: context.textStyles.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                description,
                style: context.textStyles.bodyMedium?.copyWith(
                  color: context.colors.onSurfaceVariant,
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
      ..setBackgroundColor(context.colors.surface)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final uri = Uri.parse(request.url);

            if (uri.queryParameters.containsKey('acct1') && 
                uri.queryParameters.containsKey('token1')) {

              final accounts = _extractAccounts(uri);
              AppHaptics.success();
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
      backgroundColor: context.colors.surface,
      appBar: AppBar(
        title: const Text('Login Deriv'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () {
            AppHaptics.light();
            Navigator.pop(context);
          },
        ),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}