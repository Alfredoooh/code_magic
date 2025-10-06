// lib/screens/tabs/home_tab.dart
// Versão atualizada — colar por cima do ficheiro existente.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/user_model.dart';
import '../../models/app_model.dart';
import '../../services/app_service.dart';
import '../../services/auth_service.dart';
import '../notifications_screen.dart';
import '../user_info_screen.dart';
import 'home_widgets/market_screen.dart';
import 'home_widgets/item_detail.dart';

class HomeTab extends StatefulWidget {
  final User user;

  const HomeTab({
    Key? key,
    required this.user,
  }) : super(key: key);

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> with SingleTickerProviderStateMixin {
  // animations
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // countdown
  late Timer _countdownTimer;
  String _timeRemaining = '';
  bool _hasShownOneDayWarning = false;

  // services
  final AppService _appService = AppService();

  // weekly usage
  List<int> _weeklyUsage = List.filled(7, 0);
  List<DateTime> _last7Days = [];

  // polling timers
  Timer? _statsPollTimer;
  Timer? _cryptoPollTimer;

  // cryptos
  late PageController _pageController;
  int _currentCryptoPage = 0;

  // crypto state: map symbol -> data
  final Map<String, CryptoData> _cryptoData = {
    'BTCUSDT': CryptoData(symbol: 'BTCUSDT', display: 'BTC', name: 'Bitcoin', iconUrl: 'https://raw.githubusercontent.com/spothq/cryptocurrency-icons/master/128/color/btc.png'),
    'ETHUSDT': CryptoData(symbol: 'ETHUSDT', display: 'ETH', name: 'Ethereum', iconUrl: 'https://raw.githubusercontent.com/spothq/cryptocurrency-icons/master/128/color/eth.png'),
    'SOLUSDT': CryptoData(symbol: 'SOLUSDT', display: 'SOL', name: 'Solana', iconUrl: 'https://raw.githubusercontent.com/spothq/cryptocurrency-icons/master/128/color/sol.png'),
  };

  // greeting flag
  bool _showGreetingBanner = false;

  // Ads
  final String _adsJsonUrl = 'https://alfredoooh.github.io/database/assets/ads/ads_content.json';
  List<AdItem> _ads = [];
  bool _adsLoading = true;
  String _adsError = '';

  @override
  void initState() {
    super.initState();

    // Nota: NÃO atribuí WebView.platform explicitamente para evitar problemas de compatibilidade.
    // Se quiseres forçar Android composition, adicionamos com package webview_flutter_android
    // e um guard condicional — mas isso pode quebrar builds se o pacote não estiver configurado.

    _pageController = PageController(viewportFraction: 1.0);
    _setupAnimations();
    _startCountdownTimer();
    _initLast7Days();
    _loadWeeklyUsage(); // initial load
    _statsPollTimer = Timer.periodic(const Duration(seconds: 8), (_) => _loadWeeklyUsage());
    _fetchAllCryptos(); // initial fetch
    _cryptoPollTimer = Timer.periodic(const Duration(seconds: 10), (_) => _fetchAllCryptos());
    _pageController.addListener(_onPageChanged);
    _maybeShowGreetingOnce();

    // fetch ads JSON
    _fetchAdsJson();
  }

  void _onPageChanged() {
    final page = _pageController.page;
    if (page != null) {
      final rounded = page.round();
      if (rounded != _currentCryptoPage) {
        setState(() => _currentCryptoPage = rounded);
      }
    }
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  void _startCountdownTimer() {
    _updateCountdown();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateCountdown();
    });
  }

  void _updateCountdown() {
    if (!mounted) return;
    setState(() {
      _timeRemaining = widget.user.timeUntilExpiry;
      if (widget.user.daysUntilExpiry <= 1 && !_hasShownOneDayWarning) {
        _hasShownOneDayWarning = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showExpiryWarningDialog();
        });
      }
    });
  }

  void _initLast7Days() {
    final now = DateTime.now();
    _last7Days = List.generate(7, (i) {
      final day = now.subtract(Duration(days: 6 - i));
      return DateTime(day.year, day.month, day.day);
    });
  }

  Future<void> _loadWeeklyUsage() async {
    try {
      final stats = await _appService.getUsageStats(); // assume Map<String, AppUsageStats>
      // Reset counts
      final counts = List<int>.filled(7, 0);
      for (final stat in stats.values) {
        for (int i = 0; i < _last7Days.length; i++) {
          final d = _last7Days[i];
          if (stat.lastUsed.year == d.year && stat.lastUsed.month == d.month && stat.lastUsed.day == d.day) {
            counts[i] += stat.openCount;
          }
        }
      }
      if (mounted) {
        setState(() {
          _weeklyUsage = counts;
        });
      }
    } catch (e) {
      // ignore silently (keeps previous data)
    }
  }

  // --- Crypto fetching (Binance) ---
  Future<void> _fetchAllCryptos() async {
    for (final symbol in _cryptoData.keys) {
      _fetchCrypto(symbol);
    }
  }

  Future<void> _fetchCrypto(String symbol) async {
    try {
      // price endpoint
      final priceResp = await http.get(Uri.parse('https://api.binance.com/api/v3/ticker/price?symbol=$symbol'));
      if (priceResp.statusCode != 200) return;
      final priceJson = jsonDecode(priceResp.body);
      final price = double.tryParse(priceJson['price']?.toString() ?? '') ?? 0.0;

      // klines for small sparkline (1m interval, 30 points)
      final kResp = await http.get(Uri.parse('https://api.binance.com/api/v3/klines?symbol=$symbol&interval=1m&limit=30'));
      if (kResp.statusCode != 200) {
        // update price only
        _updateCryptoData(symbol, price: price, points: null);
        return;
      }
      final List<dynamic> klines = jsonDecode(kResp.body);
      // parse close prices
      final List<double> closes = klines.map<double>((k) {
        final closeStr = k[4]?.toString() ?? '0';
        return double.tryParse(closeStr) ?? 0.0;
      }).toList();

      _updateCryptoData(symbol, price: price, points: closes);
    } catch (e) {
      // fail quietly
    }
  }

  void _updateCryptoData(String symbol, {required double price, List<double>? points}) {
    if (!mounted) return;
    final current = _cryptoData[symbol];
    if (current == null) return;
    // compute direction (compare last vs first)
    final direction = (points != null && points.length >= 2) ? (points.last - points.first) : 0.0;
    setState(() {
      _cryptoData[symbol] = current.copyWith(price: price, sparkline: points, direction: direction);
    });
  }

  // greeting: show once per user (SharedPreferences)
  Future<void> _maybeShowGreetingOnce() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'greet_shown_${widget.user.id}';
      final shown = prefs.getBool(key) ?? false;
      if (!shown) {
        // mark shown immediately so app doesn't show again
        await prefs.setBool(key, true);
        if (mounted) {
          setState(() {
            _showGreetingBanner = true;
          });
          // hide banner after 4 seconds
          Timer(const Duration(seconds: 4), () {
            if (mounted) setState(() => _showGreetingBanner = false);
          });
        }
      }
    } catch (e) {
      // ignore errors silently
    }
  }

  // -------------------------
  // Ads JSON fetch (com debug e mensagem de erro clara)
  // -------------------------
  Future<void> _fetchAdsJson() async {
    setState(() {
      _adsLoading = true;
      _adsError = '';
    });

    try {
      final resp = await http.get(Uri.parse(_adsJsonUrl)).timeout(const Duration(seconds: 8));
      if (resp.statusCode == 200) {
        final parsed = jsonDecode(resp.body);
        if (parsed is List) {
          final list = parsed.map<AdItem?>((e) {
            try {
              final image = e['image']?.toString() ?? '';
              final url = e['url']?.toString() ?? '';
              if (image.isEmpty && url.isEmpty) return null;
              return AdItem(image: image, url: url);
            } catch (_) {
              return null;
            }
          }).whereType<AdItem>().toList();
          setState(() {
            _ads = list;
            _adsLoading = false;
          });
        } else {
          setState(() {
            _ads = [];
            _adsLoading = false;
            _adsError = 'Formato JSON inesperado';
          });
        }
      } else {
        setState(() {
          _ads = [];
          _adsLoading = false;
          _adsError = 'HTTP ${resp.statusCode} ao carregar anúncios';
        });
      }
    } catch (e) {
      setState(() {
        _ads = [];
        _adsLoading = false;
        _adsError = 'Erro ao buscar anúncios: $e';
      });
    }
  }

  // -------------------------
  // Build UI (preservando teu estilo)
  // -------------------------
  @override
  void dispose() {
    _animationController.dispose();
    _countdownTimer.cancel();
    _statsPollTimer?.cancel();
    _cryptoPollTimer?.cancel();
    _pageController.removeListener(_onPageChanged);
    _pageController.dispose();
    super.dispose();
  }

  void _showExpiryWarningDialog() {
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CupertinoAlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              CupertinoIcons.exclamationmark_triangle_fill,
              color: Color(0xFFFF3B30),
              size: 24,
            ),
            SizedBox(width: 8),
            Text('Tempo Esgotando'),
          ],
        ),
        content: const Padding(
          padding: EdgeInsets.only(top: 12),
          child: Text(
            'Sua conta expira em menos de 1 dia!\n\n'
            'Entre em contato com o administrador imediatamente para renovar sua conta e evitar a perda de acesso.',
            style: TextStyle(fontSize: 15),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _openNotifications() {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => const NotificationsScreen(),
      ),
    );
  }

  // Profile menu — adicionei Settings e Alterar Dados (com prompt senha)
  void _showProfileMenu() {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1C1C1E),
                border: Border.all(
                  color: const Color(0xFF007AFF).withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: widget.user.profileImage.isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        widget.user.profileImage,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          CupertinoIcons.person_fill,
                          size: 40,
                          color: Color(0xFF8E8E93),
                        ),
                      ),
                    )
                  : const Icon(
                      CupertinoIcons.person_fill,
                      size: 40,
                      color: Color(0xFF8E8E93),
                    ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.user.fullName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.user.email,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF8E8E93),
              ),
            ),
          ],
        ),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => UserInfoScreen(user: widget.user),
                ),
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(CupertinoIcons.person_circle, color: Color(0xFF007AFF)),
                SizedBox(width: 12),
                Text('Ver Perfil'),
              ],
            ),
          ),

          // Settings (requires password before opening)
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _requirePasswordThenOpen(
                title: 'Settings',
                url: 'https://alfredoooh.github.io/assets/payments/consult_time_points.html',
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(CupertinoIcons.gear, color: Color(0xFF007AFF)),
                SizedBox(width: 12),
                Text('Settings'),
              ],
            ),
          ),

          // Alterar Dados (requires password before opening)
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _requirePasswordThenOpen(
                title: 'Alterar Dados',
                url: 'https://alfredoooh.github.io/assets/payments/consult_time_points.html',
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(CupertinoIcons.pencil, color: Color(0xFFFF9500)),
                SizedBox(width: 12),
                Text('Alterar Dados'),
              ],
            ),
          ),

          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              _confirmLogout();
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(CupertinoIcons.square_arrow_right),
                SizedBox(width: 12),
                Text('Sair'),
              ],
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ),
    );
  }

  // Prompt de senha e depois abre WebView com titulo só o título na barra
  // OBS: não chamo AuthService.verifyPassword diretamente (pode não existir).
  // Implementação atual:
  // 1) tenta buscar password guardada localmente em SharedPreferences key 'user_pwd_{id}' (opcional)
  // 2) se existir compara; se não existir aceita qualquer senha não vazia (fallback)
  // Substitui por verificação server-side se tiveres endpoint.
  Future<void> _requirePasswordThenOpen({required String title, required String url}) async {
    final entered = await showCupertinoDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        String pwd = '';
        String error = '';
        return StatefulBuilder(builder: (context, setState) {
          return CupertinoAlertDialog(
            title: Text('Confirmar Identidade'),
            content: Column(
              children: [
                const SizedBox(height: 8),
                CupertinoTextField(
                  onChanged: (v) => pwd = v,
                  obscureText: true,
                  placeholder: 'Palavra-passe',
                ),
                if (error.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(error, style: const TextStyle(color: Color(0xFFFF3B30))),
                ],
              ],
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('Cancelar'),
                onPressed: () => Navigator.pop(context, null),
              ),
              CupertinoDialogAction(
                child: const Text('Confirmar'),
                onPressed: () async {
                  // tenta validação local
                  try {
                    final prefs = await SharedPreferences.getInstance();
                    final key = 'user_pwd_${widget.user.id}';
                    final local = prefs.getString(key);
                    if (local != null && local.isNotEmpty) {
                      if (local == pwd) {
                        Navigator.pop(context, pwd);
                        return;
                      } else {
                        setState(() => error = 'Palavra-passe inválida');
                        return;
                      }
                    } else {
                      // fallback: aceita qualquer senha não vazia
                      if (pwd.trim().isNotEmpty) {
                        Navigator.pop(context, pwd);
                        return;
                      } else {
                        setState(() => error = 'Introduza a palavra-passe');
                        return;
                      }
                    }
                  } catch (e) {
                    if (pwd.trim().isNotEmpty) {
                      Navigator.pop(context, pwd);
                      return;
                    } else {
                      setState(() => error = 'Introduza a palavra-passe');
                      return;
                    }
                  }
                },
              ),
            ],
          );
        });
      },
    );

    if (entered != null) {
      _openWebView(title: title, url: url);
    }
  }

  // Confirmação de logout/limpeza (mantém fluxo)
  void _confirmLogout() {
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Apagar Dados do App'),
        content: const Padding(
          padding: EdgeInsets.only(top: 12),
          child: Text(
            'Se escolher "Apagar e Desinstalar", o aplicativo irá limpar TODOS os dados locais (preferências, ficheiros, cache e bases de dados) e em seguida abrirá o ecrã para desinstalar a aplicação. '
            '\n\nATENÇÃO: a desinstalação só será feita com a ação do utilizador — a aplicação NÃO pode desinstalar-se sozinha sem interação do utilizador.',
            style: TextStyle(fontSize: 14),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Apagar e Desinstalar'),
            onPressed: () {
              Navigator.pop(context);
              _wipeAppDataAndOfferUninstall();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _wipeAppDataAndOfferUninstall() async {
    if (!mounted) return;
    showCupertinoDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const CupertinoAlertDialog(
        title: Text('Processando'),
        content: Padding(
          padding: EdgeInsets.only(top: 12),
          child: CupertinoActivityIndicator(radius: 15),
        ),
      ),
    );

    try {
      _statsPollTimer?.cancel();
      _cryptoPollTimer?.cancel();
      _countdownTimer.cancel();

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.clear();
      } catch (e) {}

      try {
        final appDocDir = await getApplicationDocumentsDirectory();
        final tempDir = await getTemporaryDirectory();
        await _deleteDirectorySafe(appDocDir);
        await _deleteDirectorySafe(tempDir);
      } catch (e) {}
      await Future.delayed(const Duration(milliseconds: 600));
    } finally {
      if (mounted) Navigator.pop(context);
    }

    // Abrir settings/desinstalar manualmente — não há forma de desinstalar programaticamente sem ação do user.
    try {
      if (Platform.isAndroid) {
        final package = await _getPackageName();
        if (package != null && package.isNotEmpty) {
          final uninstallUrl = 'package:$package';
          if (await canLaunch(uninstallUrl)) {
            await launch(uninstallUrl);
            return;
          }
        }
      } else if (Platform.isIOS) {
        final uri = Uri.parse('App-prefs:root');
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
          return;
        }
      }
    } catch (e) {}

    if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  Future<void> _deleteDirectorySafe(Directory dir) async {
    try {
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (e) {}
  }

  Future<String?> _getPackageName() async {
    try {
      const channel = MethodChannel('app.channel.general');
      final result = await channel.invokeMethod<String>('getPackageName');
      return result;
    } catch (_) {
      return null;
    }
  }

  // Abre um WebView com título simples (apenas o título no AppBar)
  void _openWebView({required String title, required String url}) {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (_) => SimpleWebViewScreen(title: title, url: url),
      ),
    );
  }

  // --- Buttons on Time Card open remote HTML on GitHub Pages ---
  void _onAddTimePressed() {
    final url = 'https://alfredoooh.github.io/assets/payments/add_time.html';
    _openWebView(title: 'Adicionar Tempo', url: url);
  }

  void _onSendTimePressed() {
    final url = 'https://alfredoooh.github.io/assets/payments/send_time.html';
    _openWebView(title: 'Enviar Tempo', url: url);
  }

  void _onConsultTimePressed() {
    final url = 'https://alfredoooh.github.io/assets/payments/consult_time_points.html';
    _openWebView(title: 'Consultar Tempo', url: url);
  }

  // -------------------------
  // Build UI - pinned header + body
  // -------------------------
  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: CupertinoPageScaffold(
        backgroundColor: const Color(0xFF000000),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // pinned app bar
            SliverPersistentHeader(
              pinned: true,
              delegate: _PinnedHeaderDelegate(
                child: _buildPinnedHeader(context),
                minExtent: 92,
                maxExtent: 92,
              ),
            ),

            // optional greeting banner (shows only once per user)
            if (_showGreetingBanner)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C1E),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: const [
                        Icon(CupertinoIcons.hand_raised, color: Color(0xFF007AFF)),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Bem-vindo! Se precisares, verifica as definições de segurança na tua conta.',
                            style: TextStyle(color: Color(0xFFFFFFFF)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // AD card (remote JSON) - colocado acima do \"add\" e do \"tempo restante\"
                    _buildAdCard(),
                    const SizedBox(height: 12),

                    // Add card
                    _buildAddCard(),
                    const SizedBox(height: 12),

                    _buildTimeRemainingCard(),
                    const SizedBox(height: 12),

                    _buildQuickStatsGrid(),
                    const SizedBox(height: 24),
                    // Weekly activity (full width card)
                    _buildWeeklyActivityWidget(),
                    const SizedBox(height: 16),
                    // Crypto pager (each card same size as weekly activity)
                    _buildCryptoPager(),
                    const SizedBox(height: 24),
                    _buildAccountStatusCard(),
                    const SizedBox(height: 24),
                    _buildQuickActionsSection(),
                    const SizedBox(height: 24),
                    _buildActivityCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Pinned header UI (keeps user & notifications fixed)
  Widget _buildPinnedHeader(BuildContext context) {
    return Container(
      color: const Color(0xFF000000),
      padding: const EdgeInsets.fromLTRB(20, 36, 16, 16),
      child: Row(
        children: [
          // Left: Title \"Início\" aligned top-left
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Início',
                  style: TextStyle(
                    fontSize: 18,
                    color: Color(0xFF8E8E93),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 6),
              ],
            ),
          ),

          // Right: notification and profile circular buttons
          Row(
            children: [
              // notification button (circular)
              _buildCircleButton(
                onTap: _openNotifications,
                child: const Icon(
                  CupertinoIcons.bell_fill,
                  color: Color(0xFFFFFFFF),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              // profile button (circular)
              GestureDetector(
                onTap: _showProfileMenu,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF1C1C1E),
                    border: Border.all(
                      color: const Color(0xFF007AFF).withOpacity(0.06),
                      width: 1,
                    ),
                  ),
                  child: widget.user.profileImage.isNotEmpty
                      ? ClipOval(
                          child: Image.network(
                            widget.user.profileImage,
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              CupertinoIcons.person_fill,
                              color: Color(0xFF8E8E93),
                              size: 20,
                            ),
                          ),
                        )
                      : const Center(
                          child: Icon(
                            CupertinoIcons.person_fill,
                            color: Color(0xFF8E8E93),
                            size: 20,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton({required VoidCallback onTap, required Widget child}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF1C1C1E),
          border: Border.all(
            color: Colors.white.withOpacity(0.02),
            width: 1,
          ),
        ),
        child: Center(child: child),
      ),
    );
  }

  // AD card: mostra um PageView horizontal com imagens vindas do JSON remoto
  Widget _buildAdCard() {
    final height = 120.0;
    if (_adsLoading) {
      return Container(
        width: double.infinity,
        height: height,
        padding: const EdgeInsets.all(0),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: CupertinoActivityIndicator(radius: 14)),
      );
    }

    if (_ads.isEmpty) {
      return Container(
        width: double.infinity,
        height: height,
        padding: const EdgeInsets.all(0),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            _adsError.isEmpty ? 'Sem anúncios' : _adsError,
            style: const TextStyle(color: Color(0xFF8E8E93)),
          ),
        ),
      );
    }

    return SizedBox(
      height: height,
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.92),
        itemCount: _ads.length,
        itemBuilder: (context, index) {
          final ad = _ads[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0),
            child: GestureDetector(
              onTap: () {
                _openWebView(title: 'Publicidade', url: ad.url);
              },
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1E),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    ad.image,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFF2C2C2E),
                      child: const Center(
                        child: Icon(CupertinoIcons.photo, color: Color(0xFF8E8E93)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Add card — este card fica entre ads e tempo restante
  Widget _buildAddCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF2C2C2E),
            ),
            child: const Icon(CupertinoIcons.plus_circled, color: Color(0xFF007AFF), size: 34),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'Adicionar Crédito / Serviços',
              style: TextStyle(
                color: Color(0xFFFFFFFF),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            color: const Color(0xFF007AFF),
            borderRadius: BorderRadius.circular(10),
            onPressed: _onAddTimePressed,
            child: const Text('Abrir'),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRemainingCard() {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (widget.user.daysUntilExpiry <= 1) {
      statusColor = const Color(0xFFFF3B30);
      statusIcon = CupertinoIcons.exclamationmark_triangle_fill;
      statusText = 'URGENTE';
    } else if (widget.user.daysUntilExpiry < 7) {
      statusColor = const Color(0xFFFF3B30);
      statusIcon = CupertinoIcons.time;
      statusText = 'CRÍTICO';
    } else if (widget.user.daysUntilExpiry < 30) {
      statusColor = const Color(0xFFFF9500);
      statusIcon = CupertinoIcons.clock;
      statusText = 'ATENÇÃO';
    } else {
      statusColor = const Color(0xFF34C759);
      statusIcon = CupertinoIcons.checkmark_seal_fill;
      statusText = 'ATIVO';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(statusIcon, color: statusColor, size: 14),
                    const SizedBox(width: 5),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Botões circulares: + (add), enviar, consultar
              Row(
                children: [
                  _smallCircleAction(icon: CupertinoIcons.plus, onTap: _onAddTimePressed, tooltip: 'Adicionar'),
                  const SizedBox(width: 8),
                  _smallCircleAction(icon: CupertinoIcons.paperplane, onTap: _onSendTimePressed, tooltip: 'Enviar'),
                  const SizedBox(width: 8),
                  _smallCircleAction(icon: CupertinoIcons.search, onTap: _onConsultTimePressed, tooltip: 'Consultar'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Tempo Restante',
            style: TextStyle(
              color: Color(0xFF8E8E93),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _timeRemaining,
            style: TextStyle(
              color: statusColor,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallCircleAction({required IconData icon, required VoidCallback onTap, String? tooltip}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF2C2C2E),
          border: Border.all(color: Colors.white.withOpacity(0.02)),
        ),
        child: Center(
          child: Icon(icon, size: 18, color: const Color(0xFFFFFFFF)),
        ),
      ),
    );
  }

  Widget _buildQuickStatsGrid() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: CupertinoIcons.calendar,
            value: '${widget.user.daysUntilExpiry}',
            label: 'Dias',
            color: const Color(0xFF007AFF),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: CupertinoIcons.shield_lefthalf_fill,
            value: widget.user.twoFactorAuth ? 'ON' : 'OFF',
            label: '2FA',
            color: widget.user.twoFactorAuth ? const Color(0xFF34C759) : const Color(0xFF8E8E93),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFFFFFF),
              letterSpacing: -0.5,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF8E8E93),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ---------- Weekly Activity widget: uses _weeklyUsage (real-time) ----------
  Widget _buildWeeklyActivityWidget() {
    final maxY = (_weeklyUsage.isEmpty || _weeklyUsage.reduce((a, b) => a > b ? a : b) == 0) ? 10.0 : (_weeklyUsage.reduce((a, b) => a > b ? a : b) + 5).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Atividade Semanal',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFFFFFFFF),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 180,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY,
              barTouchData: BarTouchData(enabled: false),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      const days = ['D', 'S', 'T', 'Q', 'Q', 'S', 'S'];
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          days[value.toInt() % 7],
                          style: const TextStyle(
                            color: Color(0xFF8E8E93),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxY / 4,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: const Color(0xFF2C2C2E),
                    strokeWidth: 1,
                  );
                },
              ),
              borderData: FlBorderData(show: false),
              barGroups: _weeklyUsage.asMap().entries.map((entry) {
                return BarChartGroupData(
                  x: entry.key,
                  barRods: [
                    BarChartRodData(
                      toY: entry.value.toDouble(),
                      color: const Color(0xFF007AFF),
                      width: 16,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  // ---------- Crypto pager (horizontal) ----------
  Widget _buildCryptoPager() {
    final pages = _cryptoData.keys.toList();
    final screenWidth = MediaQuery.of(context).size.width;
    final cardWidth = (screenWidth - 40); // same visual width as main content area (padding 20 each side)

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 180, // same visual height as weekly activity card
          child: PageView.builder(
            controller: _pageController,
            itemCount: pages.length + 1, // +1 for add card
            itemBuilder: (context, index) {
              if (index < pages.length) {
                final symbol = pages[index];
                final data = _cryptoData[symbol]!;
                return Center(
                  child: SizedBox(
                    width: cardWidth,
                    child: _buildCryptoCard(data),
                  ),
                );
              } else {
                // add card
                return Center(
                  child: SizedBox(
                    width: cardWidth,
                    child: GestureDetector(
                      onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (_) => const MarketScreen())),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C1C1E),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF2C2C2E),
                              ),
                              child: const Icon(CupertinoIcons.add_circled, color: Color(0xFF007AFF), size: 34),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Text(
                                'Market',
                                style: TextStyle(
                                  color: Color(0xFFFFFFFF),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Icon(CupertinoIcons.chevron_right, color: const Color(0xFF8E8E93).withOpacity(0.8)),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }
            },
          ),
        ),
        const SizedBox(height: 8),
        // page indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_cryptoData.length + 1, (i) {
            final active = i == _currentCryptoPage;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: active ? 10 : 8,
              height: active ? 10 : 8,
              decoration: BoxDecoration(
                color: active ? const Color(0xFF007AFF) : const Color(0xFF2C2C2E),
                shape: BoxShape.circle,
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildCryptoCard(CryptoData data) {
    final priceText = data.price != null ? data.price!.toStringAsFixed(2) : '--';
    final isUp = (data.direction ?? 0) >= 0;
    final sparkPoints = data.sparkline ?? [];

    return GestureDetector(
      onTap: () {
        // open item_detail with the symbol and data
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (_) => ItemDetailScreen(
              symbol: data.symbol,
              display: data.display,
              name: data.name,
              iconUrl: data.iconUrl,
              latestPrice: data.price ?? 0.0,
              sparkline: sparkPoints,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // icon
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                data.iconUrl,
                width: 56,
                height: 56,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 56,
                  height: 56,
                  color: const Color(0xFF2C2C2E),
                  child: const Icon(CupertinoIcons.question, color: Color(0xFF8E8E93)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // name + price + mini chart
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.name,
                    style: const TextStyle(
                      color: Color(0xFFFFFFFF),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '\$ $priceText',
                    style: const TextStyle(
                      color: Color(0xFF8E8E93),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  // mini sparkline
                  SizedBox(
                    height: 36,
                    child: sparkPoints.isEmpty
                        ? Container()
                        : LineChart(
                            LineChartData(
                              gridData: FlGridData(show: false),
                              titlesData: FlTitlesData(show: false),
                              borderData: FlBorderData(show: false),
                              minX: 0,
                              maxX: (sparkPoints.length - 1).toDouble(),
                              minY: sparkPoints.reduce((a, b) => a < b ? a : b),
                              maxY: sparkPoints.reduce((a, b) => a > b ? a : b),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: sparkPoints.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                                  isCurved: true,
                                  dotData: FlDotData(show: false),
                                  color: isUp ? const Color(0xFF34C759) : const Color(0xFFFF3B30),
                                  barWidth: 2,
                                ),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),
            // arrow (direction)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  data.direction != null ? (data.direction! >= 0 ? '+${data.direction!.toStringAsFixed(2)}' : data.direction!.toStringAsFixed(2)) : '--',
                  style: TextStyle(
                    color: isUp ? const Color(0xFF34C759) : const Color(0xFFFF3B30),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Icon(
                  isUp ? CupertinoIcons.arrow_up : CupertinoIcons.arrow_down,
                  color: isUp ? const Color(0xFF34C759) : const Color(0xFFFF3B30),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountStatusCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detalhes da Conta',
            style: TextStyle(
              color: Color(0xFFFFFFFF),
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(
            'Status',
            widget.user.accountStatus,
            widget.user.statusColor,
            CupertinoIcons.checkmark_circle_fill,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            'Email',
            widget.user.email,
            const Color(0xFFFFFFFF),
            CupertinoIcons.mail_solid,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            'Tipo',
            widget.user.role.toUpperCase(),
            const Color(0xFF007AFF),
            CupertinoIcons.person,
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
            'ID',
            widget.user.id,
            const Color(0xFF8E8E93),
            CupertinoIcons.number,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color valueColor, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: valueColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: valueColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF8E8E93),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: valueColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ações Rápidas',
          style: TextStyle(
            color: Color(0xFFFFFFFF),
            fontSize: 22,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          'Renovar Conta',
          'Solicitar extensão',
          CupertinoIcons.arrow_clockwise_circle_fill,
          const Color(0xFF007AFF),
          () => _showRenewalDialog(),
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          'Segurança',
          'Configurar 2FA',
          CupertinoIcons.lock_shield_fill,
          const Color(0xFF34C759),
          () => _showSecurityDialog(),
        ),
        const SizedBox(height: 12),
        _buildActionButton(
          'Suporte',
          'Contactar admin',
          CupertinoIcons.chat_bubble_2_fill,
          const Color(0xFFFF9500),
          () => _showSupportDialog(),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFFFFFFFF),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF8E8E93),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              color: color.withOpacity(0.6),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Atividade Recente',
            style: TextStyle(
              color: Color(0xFFFFFFFF),
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 16),
          _buildActivityItem(
            'Login realizado',
            widget.user.lastLogin != null
                ? 'Há ${DateTime.now().difference(widget.user.lastLogin!).inMinutes} min'
                : 'Agora',
            CupertinoIcons.checkmark_seal_fill,
            const Color(0xFF34C759),
          ),
          const SizedBox(height: 12),
          _buildActivityItem(
            'Conta criada',
            '${DateTime.now().difference(widget.user.createdAt).inDays} dias atrás',
            CupertinoIcons.person_badge_plus_fill,
            const Color(0xFF007AFF),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String title, String time, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFFFFFFFF),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                time,
                style: const TextStyle(
                  color: Color(0xFF8E8E93),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // dialogs
  void _showRenewalDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Renovar Conta'),
        content: Text(
          'Para renovar sua conta, contacte:\n\n'
          'Email: admin@authsystem.com\n'
          'ID: ${widget.user.id}\n'
          'Expira: ${widget.user.expirationDate.day}/${widget.user.expirationDate.month}/${widget.user.expirationDate.year}',
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showSecurityDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Segurança'),
        content: Text(
          '2FA: ${widget.user.twoFactorAuth ? "Ativo ✓" : "Inativo ✗"}\n'
          'Chave: ${widget.user.userKey}\n\n'
          'Status: ${widget.user.twoFactorAuth ? "Protegida" : "Vulnerável"}',
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _showSupportDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Suporte'),
        content: const Text(
          'Contacte-nos:\n\n'
          'Email: support@authsystem.com\n'
          'Tel: +351 800 123 456\n\n'
          'Disponível 24/7',
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

// --- helper classes ---
class AdItem {
  final String image;
  final String url;
  AdItem({required this.image, required this.url});
}

class CryptoData {
  final String symbol;
  final String display;
  final String name;
  final String iconUrl;
  final double? price;
  final List<double>? sparkline;
  final double? direction;

  CryptoData({
    required this.symbol,
    required this.display,
    required this.name,
    required this.iconUrl,
    this.price,
    this.sparkline,
    this.direction,
  });

  CryptoData copyWith({
    double? price,
    List<double>? sparkline,
    double? direction,
  }) {
    return CryptoData(
      symbol: symbol,
      display: display,
      name: name,
      iconUrl: iconUrl,
      price: price ?? this.price,
      sparkline: sparkline ?? this.sparkline,
      direction: direction ?? this.direction,
    );
  }
}

// Simple WebView screen with only title shown in app bar
class SimpleWebViewScreen extends StatefulWidget {
  final String title;
  final String url;
  const SimpleWebViewScreen({Key? key, required this.title, required this.url}) : super(key: key);

  @override
  State<SimpleWebViewScreen> createState() => _SimpleWebViewScreenState();
}

class _SimpleWebViewScreenState extends State<SimpleWebViewScreen> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) => setState(() => _loading = true),
        onPageFinished: (_) => setState(() => _loading = false),
      ));

    _controller.loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.title),
        previousPageTitle: 'Voltar',
      ),
      child: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading)
            const Center(
              child: CupertinoActivityIndicator(radius: 16),
            ),
        ],
      ),
    );
  }
}

// Pinned header delegate for SliverPersistentHeader
class _PinnedHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double minExtent;
  final double maxExtent;

  _PinnedHeaderDelegate({
    required this.child,
    required this.minExtent,
    required this.maxExtent,
  });

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Material(
      color: const Color(0xFF000000),
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _PinnedHeaderDelegate oldDelegate) {
    return oldDelegate.child != child || oldDelegate.minExtent != minExtent || oldDelegate.maxExtent != maxExtent;
  }
}