// login_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'theme/app_theme.dart';
import 'theme/app_colors.dart';
import 'theme/app_widgets.dart';
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
    await AppModalBottomSheet.show(
      context: context,
      isDismissible: false,
      title: 'Aviso Importante',
      child: const TradingDisclaimerContent(),
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
        return AppDialog(
          title: 'Selecione sua conta',
          icon: Icons.account_balance_wallet_rounded,
          iconColor: AppColors.primary,
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: accounts.length,
              itemBuilder: (context, index) {
                final account = accounts[index];
                return StaggeredListItem(
                  index: index,
                  delay: const Duration(milliseconds: 50),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: AnimatedCard(
                      onTap: () {
                        AppHaptics.selection();
                        Navigator.of(context).pop(account);
                      },
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
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TertiaryButton(
              text: 'Cancelar',
              onPressed: () {
                AppHaptics.light();
                Navigator.of(context).pop(null);
              },
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
        backgroundColor: context.surface,
        body: LoadingOverlay(
          isLoading: true,
          message: 'Verificando sessão...',
          child: const SizedBox(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: context.surface,
      body: LoadingOverlay(
        isLoading: _isLoading,
        message: 'Conectando...',
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: AppSpacing.massive),

                // Logo
                FadeInWidget(
                  child: Center(
                    child: Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: context.colors.primaryContainer,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                        boxShadow: [
                          BoxShadow(
                            color: context.colors.primary.withOpacity(0.3),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                        child: Image.asset(
                          'assets/icon/icon.png',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.trending_up_rounded,
                              color: context.colors.primary,
                              size: 48,
                            );
                          },
                        ),
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
                      fontWeight: FontWeight.w900,
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
                  child: PrimaryButton(
                    text: 'Login com Email/Senha Deriv',
                    icon: Icons.login_rounded,
                    onPressed: _isLoading ? null : _loginWithDeriv,
                    expanded: true,
                  ),
                ),

                const SizedBox(height: AppSpacing.xl),

                // Divider
                FadeInWidget(
                  delay: const Duration(milliseconds: 400),
                  child: const LabeledDivider(label: 'ou'),
                ),

                const SizedBox(height: AppSpacing.xl),

                // Campo de Token
                FadeInWidget(
                  delay: const Duration(milliseconds: 500),
                  child: AppTextField(
                    controller: _tokenController,
                    label: 'Token de API',
                    hint: 'Cole seu token aqui',
                    prefix: const Icon(Icons.vpn_key_rounded),
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
                  child: SecondaryButton(
                    text: 'Conectar com Token',
                    icon: Icons.link_rounded,
                    onPressed: _isLoading ? null : _login,
                    expanded: true,
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Botão Criar Conta
                FadeInWidget(
                  delay: const Duration(milliseconds: 700),
                  child: TertiaryButton(
                    text: 'Criar Conta Deriv',
                    icon: Icons.person_add_rounded,
                    onPressed: _openRegister,
                    expanded: true,
                  ),
                ),

                const SizedBox(height: AppSpacing.massive),

                // Suporte
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
                      // WhatsApp
                      IconButtonWithBackground(
                        icon: Icons.chat_rounded,
                        onPressed: _openWhatsApp,
                        backgroundColor: const Color(0xFF25D366).withOpacity(0.15),
                        iconColor: const Color(0xFF25D366),
                        size: 48,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      // Email
                      IconButtonWithBackground(
                        icon: Icons.email_rounded,
                        onPressed: _openEmail,
                        backgroundColor: context.colors.primary.withOpacity(0.15),
                        iconColor: context.colors.primary,
                        size: 48,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TradingDisclaimerContent extends StatelessWidget {
  const TradingDisclaimerContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FadeInWidget(
          child: _buildDisclaimerItem(
            context,
            Icons.warning_rounded,
            'Risco Elevado',
            'Trading envolve risco significativo de perda. Apenas negocie com dinheiro que você pode perder.',
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        FadeInWidget(
          delay: const Duration(milliseconds: 100),
          child: _buildDisclaimerItem(
            context,
            Icons.trending_down_rounded,
            'Volatilidade',
            'Os mercados podem ser extremamente voláteis. Os preços podem mudar rapidamente.',
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        FadeInWidget(
          delay: const Duration(milliseconds: 200),
          child: _buildDisclaimerItem(
            context,
            Icons.school_rounded,
            'Educação',
            'Certifique-se de entender completamente os produtos antes de negociar.',
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        FadeInWidget(
          delay: const Duration(milliseconds: 300),
          child: _buildDisclaimerItem(
            context,
            Icons.verified_user_rounded,
            'Responsabilidade',
            'Você é totalmente responsável por suas decisões de trading.',
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        FadeInWidget(
          delay: const Duration(milliseconds: 400),
          child: PrimaryButton(
            text: 'Continuar',
            icon: Icons.check_rounded,
            onPressed: () {
              AppHaptics.medium();
              Navigator.pop(context);
            },
            expanded: true,
          ),
        ),
      ],
    );
  }

  static Widget _buildDisclaimerItem(
    BuildContext context,
    IconData icon,
    String title,
    String description,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.warning.withOpacity(0.15),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Icon(
            icon,
            color: AppColors.warning,
            size: 24,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: context.textStyles.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                description,
                style: context.textStyles.bodyMedium?.copyWith(
                  color: context.colors.onSurfaceVariant,
                  height: 1.5,
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
      ..setBackgroundColor(context.surface)
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
      backgroundColor: context.surface,
      appBar: SecondaryAppBar(
        title: 'Login Deriv',
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