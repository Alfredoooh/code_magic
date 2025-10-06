// webview_screen.dart - VERSÃO ATUALIZADA (sem abertura externa, copia apenas título)
import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:collection/collection.dart';

/// WebTab model otimizado
class WebTab {
  final String id;
  String url;
  String title;
  final WebViewController controller;
  Color? primaryColor;
  Brightness? brightness;
  bool isLoading = true;
  bool hasError = false;
  String? errorMessage;
  String? category;
  String? appName;
  Timer? scrollTimer;

  WebTab({
    required this.id,
    required this.url,
    required this.title,
    required this.controller,
    this.primaryColor,
    this.brightness,
  });
}

class WebViewScreen extends StatefulWidget {
  final String url;
  final String title;

  const WebViewScreen({
    Key? key,
    required this.url,
    required this.title,
  }) : super(key: key);

  @override
  State createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen>
    with SingleTickerProviderStateMixin {
  final List<WebTab> _tabs = [];
  int _currentTabIndex = 0;

  Color _primaryColor = const Color(0xFF007AFF);
  Brightness _brightness = Brightness.dark;
  bool _darkModeEnabled = false; // modo escuro CORRIGIDO
  bool _showErrorBanner = false;
  String? _errorBannerMessage;

  FlutterTts? _flutterTts;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  bool _isLoading = true;
  bool _isBottomBarVisible = true;
  bool _canGoBack = false;
  bool _canGoForward = false;

  List<Map<String, dynamic>> _appsIndex = [];
  bool _isFetchingApps = false;

  // Configurações do navegador
  bool _jsEnabled = true;
  bool _autoHideBar = false; // por defeito não esconde a barra ao rolar
  double _textZoom = 100.0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _scaleAnimation =
        CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic);
    _animController.forward();

    _initTts();
    _monitorConnectivity();
    _createNewTab(widget.url, widget.title);
    _fetchAppsIndex();
  }

  Future<void> _fetchAppsIndex() async {
    if (_isFetchingApps) return;
    _isFetchingApps = true;
    try {
      final res = await http
          .get(Uri.parse(
              'https://alfredoooh.github.io/database/apps/apps.json'))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data is List) {
          _appsIndex = List<Map<String, dynamic>>.from(data);
        }
      }
    } catch (e) {
      debugPrint('Erro ao carregar apps: $e');
    } finally {
      _isFetchingApps = false;
      if (mounted) setState(() {});
    }
  }

  void _initTts() async {
    try {
      _flutterTts = FlutterTts();
      await _flutterTts?.setLanguage("pt-BR");
      await _flutterTts?.setSpeechRate(0.5);
      await _flutterTts?.setVolume(1.0);
    } catch (e) {
      debugPrint('TTS não disponível: $e');
    }
  }

  void _monitorConnectivity() {
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen((result) {
      if (result == ConnectivityResult.none) {
        if (mounted) {
          _showNonBlockingBanner('Sem conexão com a internet');
        }
      } else {
        if (_tabs.isNotEmpty && _tabs[_currentTabIndex].hasError) {
          _retryLoad();
        }
      }
    });
  }

  void _createNewTab(String url, String title) {
    final controller = WebViewController();
    final tab = WebTab(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      url: url,
      title: title,
      controller: controller,
    );

    // Configuração do controller
    controller
      ..setJavaScriptMode(
          _jsEnabled ? JavaScriptMode.unrestricted : JavaScriptMode.disabled)
      ..setBackgroundColor(Colors.transparent)
      ..enableZoom(true);

    final tabId = tab.id;

    controller.setNavigationDelegate(
      NavigationDelegate(
        onPageStarted: (pageUrl) {
          final index = _tabs.indexWhere((t) => t.id == tabId);
          if (index == -1) return;
          if (mounted) {
            setState(() {
              _tabs[index].url = pageUrl;
              _tabs[index].isLoading = true;
              _tabs[index].hasError = false;
              // não mostramos banner de erro de página aqui (conforme solicitado)
            });
          }
          _updateNavigationState(controller, index);
        },
        onPageFinished: (pageUrl) async {
          final index = _tabs.indexWhere((t) => t.id == tabId);
          if (index == -1) return;
          if (mounted) setState(() => _tabs[index].isLoading = false);
          _updateNavigationState(controller, index);

          await _extractThemeColors(controller, index);
          _applyDarkModeFixed(controller, index);
          _applyTextZoom(controller);

          try {
            final pageTitle = await controller.getTitle() ?? title;
            if (!mounted) return;
            setState(() {
              _tabs[index].title = pageTitle;
              _tabs[index].url = pageUrl;
            });
            _tryMapTabToApp(index);
          } catch (e) {
            debugPrint('Erro ao obter título: $e');
          }

          if (_autoHideBar) {
            _startScrollPolling(controller, tabId);
          }
        },
        onWebResourceError: (error) {
          final index = _tabs.indexWhere((t) => t.id == tabId);
          try {
            debugPrint('WebResourceError (silencioso): ${error.toString()}');
          } catch (_) {}
          if (index == -1) return;
          if (mounted) {
            setState(() {
              _tabs[index].hasError = true;
              _tabs[index].isLoading = false;
              _tabs[index].errorMessage = _getErrorMessage(error);
            });
          }
        },
        onHttpError: (error) {
          final index = _tabs.indexWhere((t) => t.id == tabId);
          try {
            debugPrint('HttpError (silencioso): ${error.toString()}');
          } catch (_) {}
          String status = 'Desconhecido';
          try {
            final dyn = error as dynamic;
            final resp = dyn.response ?? dyn;
            final code = resp?.statusCode ?? resp?.status ?? null;
            status = code?.toString() ?? 'Desconhecido';
          } catch (_) {
            status = 'Desconhecido';
          }

          if (index == -1) return;
          if (mounted) {
            setState(() {
              _tabs[index].hasError = true;
              _tabs[index].isLoading = false;
              _tabs[index].errorMessage = 'Erro HTTP: $status';
            });
          }
        },
      ),
    );

    // Injeção de script (scroll tracking)
    controller.runJavaScript('''
      (function() {
        if (window.__flutter_init) return;
        window.__flutter_init = true;
        window.__flutter_scrollY = 0;
        window.addEventListener('scroll', () => {
          window.__flutter_scrollY = window.scrollY || 0;
        }, { passive: true });
      })();
    ''');

    try {
      controller.loadRequest(Uri.parse(url));
    } catch (e) {
      debugPrint('Erro ao carregar: $e');
    }

    if (mounted) {
      setState(() {
        _tabs.add(tab);
        _currentTabIndex = _tabs.length - 1;
        _primaryColor = tab.primaryColor ?? const Color(0xFF007AFF);
        _brightness = tab.brightness ?? Brightness.dark;
        _isLoading = true;
      });
    }
  }

  // MODO ESCURO CORRIGIDO - Não inverte/oculta imagens
  void _applyDarkModeFixed(WebViewController controller, int index) {
    if (!_darkModeEnabled) {
      controller.runJavaScript('''
        (function() {
          var s = document.getElementById('flutter-dark-v3');
          if (s) s.remove();
        })();
      ''');
      return;
    }

    controller.runJavaScript('''
      (function() {
        if (document.getElementById('flutter-dark-v3')) return;
        var style = document.createElement('style');
        style.id = 'flutter-dark-v3';
        style.innerHTML = `
          :root {
            --bg-dark: #0a0a0a;
            --text-light: #e8e8e8;
            --border-dark: rgba(255,255,255,0.08);
          }
          html, body {
            background: var(--bg-dark) !important;
            color-scheme: dark !important;
            color: var(--text-light) !important;
          }
          body, header, main, nav, section, article, footer, p, span, div, ul, li, a, button, input, textarea, select {
            background-color: transparent !important;
            color: var(--text-light) !important;
            border-color: var(--border-dark) !important;
          }
          .content, .article, .post, .page, .container {
            background-color: var(--bg-dark) !important;
            color: var(--text-light) !important;
          }
          img, video, picture, canvas, svg, iframe {
            filter: none !important;
            background-color: transparent !important;
            -webkit-filter: none !important;
          }
          a, a * {
            color: #64b5f6 !important;
          }
          input, textarea, select {
            background-color: #1a1a1a !important;
            color: var(--text-light) !important;
            border-color: var(--border-dark) !important;
          }
        `;
        document.head.appendChild(style);
      })();
    ''');
  }

  void _applyTextZoom(WebViewController controller) {
    final zoom = _textZoom / 100.0;
    controller.runJavaScript('''
      document.body.style.zoom = '$zoom';
    ''');
  }

  void _startScrollPolling(WebViewController controller, String tabId) {
    final tab = _tabs.firstWhereOrNull((t) => t.id == tabId);
    if (tab == null) return;

    tab.scrollTimer?.cancel();

    double lastOffset = 0;

    tab.scrollTimer =
        Timer.periodic(const Duration(milliseconds: 300), (_) async {
      try {
        final raw = await controller
            .runJavaScriptReturningResult('window.__flutter_scrollY || 0');
        if (raw == null) return;
        double offset = (raw is num) ? raw.toDouble() : 0.0;

        final shouldHide = offset > lastOffset && offset > 150;
        lastOffset = offset;

        final isCurrent = _tabs.indexOf(tab) == _currentTabIndex;
        if (isCurrent) {
          if (shouldHide != !_isBottomBarVisible && mounted) {
            setState(() => _isBottomBarVisible = !shouldHide);
          }
        }
      } catch (e) {
        // silencioso
      }
    });
  }

  String _getErrorMessage(WebResourceError error) {
    try {
      switch (error.errorType) {
        case WebResourceErrorType.hostLookup:
          return 'Servidor não encontrado';
        case WebResourceErrorType.timeout:
          return 'Tempo esgotado';
        case WebResourceErrorType.unsupportedScheme:
          return 'Protocolo não suportado';
        case WebResourceErrorType.authentication:
          return 'Erro de autenticação';
        case WebResourceErrorType.fileNotFound:
          return 'Página não encontrada';
        case WebResourceErrorType.connect:
          return 'Falha na conexão';
        default:
          final desc = (error as dynamic).description ?? error.toString();
          return desc.toString();
      }
    } catch (_) {
      return error.toString();
    }
  }

  void _showNonBlockingBanner(String message) {
    if (!mounted) return;
    setState(() {
      _showErrorBanner = true;
      _errorBannerMessage = message;
    });
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) setState(() => _showErrorBanner = false);
    });
  }

  void _retryLoad() {
    if (_tabs.isEmpty) return;
    try {
      final url = _tabs[_currentTabIndex].url;
      _tabs[_currentTabIndex].controller.loadRequest(Uri.parse(url));
      setState(() {
        _tabs[_currentTabIndex].isLoading = true;
        _tabs[_currentTabIndex].hasError = false;
      });
    } catch (e) {
      _showNonBlockingBanner('Erro ao recarregar');
    }
  }

  Future<void> _updateNavigationState(
      WebViewController controller, int index) async {
    try {
      final canGoBack = await controller.canGoBack();
      final canGoForward = await controller.canGoForward();
      if (!mounted) return;
      if (index == _currentTabIndex) {
        setState(() {
          _canGoBack = canGoBack;
          _canGoForward = canGoForward;
        });
      }
    } catch (e) {
      debugPrint('Erro navigation state: $e');
    }
  }

  Future<void> _extractThemeColors(
      WebViewController controller, int index) async {
    try {
      final result = await controller.runJavaScriptReturningResult('''
        (function() {
          var theme = null;
          var m = document.querySelector('meta[name="theme-color"]');
          if (m) theme = m.content;
          var brightness = (window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches) ? 'dark' : 'light';
          return JSON.stringify({ theme: theme, brightness: brightness });
        })();
      ''');

      if (result == null) return;
      final data = jsonDecode(result.toString());
      final Color parsed =
          _parseColor(data['theme']) ?? const Color(0xFF007AFF);
      final brightnessStr = data['brightness'] ?? 'light';

      if (!mounted) return;
      setState(() {
        _tabs[index].primaryColor = parsed;
        _tabs[index].brightness =
            brightnessStr == 'dark' ? Brightness.dark : Brightness.light;
        if (index == _currentTabIndex) {
          _primaryColor = parsed;
          _brightness = _tabs[index].brightness!;
          _updateSystemUI();
        }
      });
    } catch (e) {
      debugPrint('Erro extract colors: $e');
    }
  }

  Color? _parseColor(String? s) {
    if (s == null) return null;
    try {
      final hex = RegExp(r'#([0-9A-Fa-f]{6})').firstMatch(s);
      if (hex != null) {
        return Color(int.parse('FF${hex.group(1)}', radix: 16));
      }
    } catch (_) {}
    return null;
  }

  void _updateSystemUI() {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness:
          _brightness == Brightness.dark ? Brightness.light : Brightness.dark,
    ));
  }

  WebViewController get _currentController =>
      _tabs.isEmpty ? throw StateError('No tabs') : _tabs[_currentTabIndex].controller;

  void _tryMapTabToApp(int index) {
    if (_appsIndex.isEmpty) return;
    final url = _tabs[index].url;
    Uri? u;
    try {
      u = Uri.parse(url);
    } catch (_) {}
    if (u == null) return;
    final host = u.host.replaceFirst(RegExp(r'^www\.'), '');

    final match = _appsIndex.firstWhereOrNull((m) {
      final webview = (m['webviewUrl'] ?? '').toString();
      return webview.contains(host) ||
          (m['id'] ?? '').toString().contains(host);
    });

    if (match != null) {
      setState(() {
        _tabs[index].category = match['category']?.toString();
        _tabs[index].appName = match['name']?.toString();
      });
    }
  }

  String _abbreviateCategory(String? cat) {
    if (cat == null || cat.length <= 12) return cat ?? '';
    final words = cat.split(' ');
    if (words.length == 1) return '${cat.substring(0, 10)}...';
    return words.map((w) => w[0].toUpperCase()).take(3).join('');
  }

  Future<void> _readPage() async {
    if (_flutterTts == null) {
      _showToast('Leitura não disponível');
      return;
    }
    if (_tabs.isEmpty) return;
    try {
      final result = await _currentController.runJavaScriptReturningResult('''
        document.body.innerText || '';
      ''');
      final text = result?.toString() ?? '';
      if (text.isEmpty) {
        _showToast('Sem texto para ler');
        return;
      }
      final limited = text.substring(0, text.length > 1000 ? 1000 : text.length);
      await _flutterTts?.speak(limited);
    } catch (e) {
      _showToast('Erro ao ler');
    }
  }

  void _showToast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Copia apenas o TÍTULO da aba (não expõe nem mostra URLs)
  Future<void> _copyLinkToClipboard() async {
    final title = _tabs.isNotEmpty ? (_tabs[_currentTabIndex].title ?? '') : '';
    if (title.isEmpty) {
      _showToast('Nada para copiar');
      return;
    }
    await Clipboard.setData(ClipboardData(text: title));
    _showToast('Título copiado');
  }

  Future<void> _findInPage() async {
    final TextEditingController t = TextEditingController();
    await showCupertinoModalPopup(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: CupertinoTextField(
            controller: t,
            placeholder: 'Buscar texto na página',
            onSubmitted: (v) async {
              Navigator.pop(ctx);
              if (v.trim().isEmpty) return;
              final js = '''
                (function() {
                  var s = window.find("${v.replaceAll('"', '\\"')}", false, false, true, false, false, false);
                  return s ? "FOUND" : "NOT_FOUND";
                })();
              ''';
              final res = await _currentController.runJavaScriptReturningResult(js);
              _showToast(res?.toString() == '"FOUND"' ? 'Encontrado' : 'Não encontrado');
            },
          ),
        ),
        cancelButton: CupertinoButton(
          child: const Text('Cancelar'),
          onPressed: () => Navigator.pop(ctx),
        ),
      ),
    );
  }

  Future<void> _requestDesktopSite() async {
    try {
      await _currentController.runJavaScript('''
        (function() {
          var m = document.querySelector('meta[name="viewport"]');
          if (m) {
            m.setAttribute('content', 'width=1024, initial-scale=1');
          } else {
            var mm = document.createElement('meta');
            mm.name = 'viewport';
            mm.content = 'width=1024, initial-scale=1';
            document.head.appendChild(mm);
          }
        })();
      ''');
      await Future.delayed(const Duration(milliseconds: 250));
      _currentController.reload();
      _showToast('Solicitado site desktop');
    } catch (e) {
      _showToast('Não foi possível solicitar desktop');
    }
  }

  void _showMenu() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              if (_canGoBack) _currentController.goBack();
            },
            child: const Text('Voltar'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              if (_canGoForward) _currentController.goForward();
            },
            child: const Text('Avançar'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _currentController.reload();
            },
            child: const Text('Recarregar'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _readPage();
            },
            child: const Text('Ouvir Página'),
          ),
          // substituí "Abrir no Navegador" (removido por requisição)
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _copyLinkToClipboard(); // agora copia apenas o título
            },
            child: const Text('Copiar título'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _findInPage();
            },
            child: const Text('Encontrar na Página'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _requestDesktopSite();
            },
            child: const Text('Solicitar Site Desktop'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _darkModeEnabled = !_darkModeEnabled;
                _applyDarkModeFixed(_currentController, _currentTabIndex);
              });
            },
            child: Text(_darkModeEnabled
                ? 'Desativar Modo Escuro'
                : 'Ativar Modo Escuro'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _showSettings();
            },
            child: const Text('Configurações'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ),
    );
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Configurações do Navegador',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              SwitchListTile(
                title: const Text('JavaScript',
                    style: TextStyle(color: Colors.white)),
                subtitle: const Text('Habilitar execução de scripts',
                    style: TextStyle(color: Colors.white70)),
                value: _jsEnabled,
                activeColor: _primaryColor,
                onChanged: (v) {
                  setModalState(() => _jsEnabled = v);
                  setState(() => _jsEnabled = v);
                  _currentController.setJavaScriptMode(
                      v ? JavaScriptMode.unrestricted : JavaScriptMode.disabled);
                },
              ),
              SwitchListTile(
                title: const Text('Ocultar barra automaticamente',
                    style: TextStyle(color: Colors.white)),
                subtitle: const Text('Esconde ao rolar página',
                    style: TextStyle(color: Colors.white70)),
                value: _autoHideBar,
                activeColor: _primaryColor,
                onChanged: (v) {
                  setModalState(() => _autoHideBar = v);
                  setState(() => _autoHideBar = v);
                },
              ),
              const SizedBox(height: 16),
              const Text('Zoom de Texto',
                  style: TextStyle(color: Colors.white, fontSize: 16)),
              Slider(
                value: _textZoom,
                min: 50,
                max: 200,
                divisions: 30,
                label: '${_textZoom.round()}%',
                activeColor: _primaryColor,
                onChanged: (v) {
                  setModalState(() => _textZoom = v);
                  setState(() => _textZoom = v);
                  _applyTextZoom(_currentController);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _showTabsViewFullscreen() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.95,
        child: _TabsViewFullscreen(
          tabs: _tabs,
          currentIndex: _currentTabIndex,
          onTabSelected: (index) {
            setState(() {
              _currentTabIndex = index;
              final t = _tabs[index];
              _primaryColor = t.primaryColor ?? const Color(0xFF007AFF);
              _brightness = t.brightness ?? Brightness.dark;
              _updateSystemUI();
            });
            Navigator.pop(context);
          },
          onTabClosed: (index) {
            if (_tabs.length == 1) {
              Navigator.pop(context);
              Navigator.pop(this.context);
              return;
            }
            _tabs[index].scrollTimer?.cancel();
            setState(() {
              _tabs.removeAt(index);
              if (_currentTabIndex >= _tabs.length) {
                _currentTabIndex = _tabs.length - 1;
              }
            });
          },
          onNewTab: () {
            Navigator.pop(context);
            _createNewTab('https://www.google.com', 'Nova Aba');
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentTab = _tabs.isNotEmpty ? _tabs[_currentTabIndex] : null;
    _isLoading = currentTab?.isLoading ?? false;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            _brightness == Brightness.dark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF000000),
        body: SafeArea(
          top: true,
          bottom: false,
          child: _tabs.isEmpty
              ? const Center(child: CupertinoActivityIndicator())
              : Stack(
                  children: [
                    Positioned.fill(
                        child: WebViewWidget(controller: _currentController)),
                    if (_showErrorBanner && _errorBannerMessage != null)
                      Positioned(
                        left: 16,
                        right: 16,
                        top: 12,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade800,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(CupertinoIcons.exclamationmark_triangle,
                                  color: Colors.white),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(_errorBannerMessage!,
                                    style: const TextStyle(color: Colors.white)),
                              ),
                              GestureDetector(
                                onTap: () =>
                                    setState(() => _showErrorBanner = false),
                                child: const Icon(CupertinoIcons.xmark,
                                    color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    AnimatedPositioned(
                      duration: const Duration(milliseconds: 300),
                      left: 16,
                      right: 16,
                      bottom: _isBottomBarVisible ? 16 : -90,
                      child: _FloatingBottomBar(
                        primaryColor: _primaryColor,
                        onBack: _canGoBack ? () => _currentController.goBack() : null,
                        onForward:
                            _canGoForward ? () => _currentController.goForward() : null,
                        onMenu: _showMenu,
                        onTabs: _showTabsViewFullscreen,
                        tabCount: _tabs.length,
                        isLoading: _isLoading,
                        category: _abbreviateCategory(currentTab?.category),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _flutterTts?.stop();
    _animController.dispose();
    _connectivitySubscription?.cancel();
    for (final t in _tabs) {
      t.scrollTimer?.cancel();
    }
    super.dispose();
  }
}

class _FloatingBottomBar extends StatelessWidget {
  final Color primaryColor;
  final VoidCallback? onBack;
  final VoidCallback? onForward;
  final VoidCallback onMenu;
  final VoidCallback onTabs;
  final int tabCount;
  final bool isLoading;
  final String? category;

  const _FloatingBottomBar({
    required this.primaryColor,
    this.onBack,
    this.onForward,
    required this.onMenu,
    required this.onTabs,
    required this.tabCount,
    this.isLoading = false,
    this.category,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 62,
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C2E).withOpacity(0.95),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
                color: Colors.white.withOpacity(0.08), width: 0.5),
          ),
          child: Row(
            children: [
              const SizedBox(width: 8),
              _BarButton(
                icon: CupertinoIcons.back,
                onTap: onBack,
                color: onBack != null ? Colors.white : Colors.grey,
              ),
              _BarButton(
                icon: CupertinoIcons.forward,
                onTap: onForward,
                color: onForward != null ? Colors.white : Colors.grey,
              ),
              Expanded(
                child: Center(
                  child: isLoading
                      ? CupertinoActivityIndicator(
                          radius: 12, color: primaryColor)
                      : (category != null && category!.isNotEmpty
                          ? Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Text(
                                category!,
                                style: TextStyle(
                                  color: primaryColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                          : const SizedBox.shrink()),
                ),
              ),
              _BarButton(
                icon: CupertinoIcons.ellipsis_circle,
                onTap: onMenu,
                color: Colors.white,
              ),
              const SizedBox(width: 4),
              _TabButton(
                count: tabCount,
                onTap: onTabs,
                color: Colors.white,
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _BarButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final Color color;
  const _BarButton(
      {required this.icon, this.onTap, required this.color});

  @override
  State<_BarButton> createState() => _BarButtonState();
}

class _BarButtonState extends State<_BarButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween(begin: 1.0, end: 0.88)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          child: Icon(widget.icon, color: widget.color, size: 24),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _TabButton extends StatefulWidget {
  final int count;
  final VoidCallback onTap;
  final Color color;
  const _TabButton(
      {required this.count, required this.onTap, required this.color});

  @override
  State<_TabButton> createState() => _TabButtonState();
}

class _TabButtonState extends State<_TabButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween(begin: 1.0, end: 0.88)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            border: Border.all(color: widget.color, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              widget.count > 99 ? '99+' : widget.count.toString(),
              style: TextStyle(
                color: widget.color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

/// Tela de tabs FULLSCREEN estilo iOS
class _TabsViewFullscreen extends StatelessWidget {
  final List<WebTab> tabs;
  final int currentIndex;
  final Function(int) onTabSelected;
  final Function(int) onTabClosed;
  final VoidCallback onNewTab;

  const _TabsViewFullscreen({
    required this.tabs,
    required this.currentIndex,
    required this.onTabSelected,
    required this.onTabClosed,
    required this.onNewTab,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: SafeArea(
        child: Column(
          children: [
            // Header com botão Concluído e Nova Aba
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${tabs.length} ${tabs.length == 1 ? "Aba" : "Abas"}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: onNewTab,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: Color(0xFF007AFF),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            CupertinoIcons.add,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Concluído',
                          style: TextStyle(
                            color: Color(0xFF007AFF),
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Grid de tabs
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                physics: const BouncingScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.7,
                ),
                itemCount: tabs.length,
                itemBuilder: (context, index) => _TabCardFullscreen(
                  tab: tabs[index],
                  isSelected: index == currentIndex,
                  onTap: () => onTabSelected(index),
                  onClose: () => onTabClosed(index),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabCardFullscreen extends StatelessWidget {
  final WebTab tab;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onClose;

  const _TabCardFullscreen({
    required this.tab,
    required this.isSelected,
    required this.onTap,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final color = tab.primaryColor ?? const Color(0xFF007AFF);
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 3,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 16,
                    spreadRadius: 0,
                  )
                ]
              : null,
        ),
        child: Stack(
          children: [
            // Conteúdo da aba
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 48),
                // Área de preview (simulada)
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Icon(
                        CupertinoIcons.globe,
                        size: 64,
                        color: color.withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Título
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    tab.title.isEmpty ? 'Nova Aba' : tab.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // não mostrar URL — mostramos apenas o título (requisito)
                const SizedBox(height: 12),
              ],
            ),
            // Botão fechar
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: onClose,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.xmark,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            // Badge de categoria (se houver)
            if (tab.category != null)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: color.withOpacity(0.4)),
                  ),
                  child: Text(
                    tab.category!.length > 10
                        ? '${tab.category!.substring(0, 8)}...'
                        : tab.category!,
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}