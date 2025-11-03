import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'dart:async';
import '../widgets/loading_screen.dart';
import '../widgets/error_screen.dart';

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({Key? key}) : super(key: key);

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;
  bool _hasConnection = true;
  String _errorMessage = '';
  bool _isInitialLoad = true;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _initWebView();
    _listenToConnectivity();
  }

  void _listenToConnectivity() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      final hasConnection = !results.contains(ConnectivityResult.none);
      setState(() {
        _hasConnection = hasConnection;
      });
    });
  }

  Future<void> _checkConnectivity() async {
    final connectivityResults = await Connectivity().checkConnectivity();
    final hasConnection = !connectivityResults.contains(ConnectivityResult.none);
    setState(() {
      _hasConnection = hasConnection;
      if (!hasConnection && _isInitialLoad) {
        _hasError = true;
        _errorMessage = 'Sem conexão com a internet';
      }
    });
  }

  void _initWebView() {
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final WebViewController controller =
        WebViewController.fromPlatformCreationParams(params);

    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..enableZoom(false)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (_isInitialLoad && progress == 100) {
              Future.delayed(const Duration(milliseconds: 300), () {
                if (mounted) {
                  setState(() {
                    _isLoading = false;
                    _isInitialLoad = false;
                  });
                }
              });
            }
          },
          onPageStarted: (String url) {
            if (!_isInitialLoad) {
              setState(() {
                _hasError = false;
              });
            }
          },
          onPageFinished: (String url) {
            _injectCSS();
          },
          onWebResourceError: (WebResourceError error) {
            if (error.errorType == WebResourceErrorType.hostLookup ||
                error.errorType == WebResourceErrorType.connect ||
                error.errorType == WebResourceErrorType.timeout) {
              setState(() {
                _hasError = true;
                _errorMessage = 'Falha ao carregar a página';
                if (_isInitialLoad) {
                  _isLoading = false;
                }
              });
            }
          },
        ),
      );

    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(false);
      (controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }

    _controller = controller;

    if (_hasConnection) {
      _controller.loadRequest(Uri.parse('https://webtest-oesm.onrender.com'));
    } else {
      setState(() {
        _hasError = true;
        _isLoading = false;
        _errorMessage = 'Sem conexão com a internet';
      });
    }
  }

  void _injectCSS() {
    _controller.runJavaScript('''
      (function() {
        var style = document.createElement('style');
        style.innerHTML = `
          * {
            -webkit-user-select: none !important;
            -moz-user-select: none !important;
            -ms-user-select: none !important;
            user-select: none !important;
            -webkit-touch-callout: none !important;
          }
          body {
            overflow-x: hidden !important;
          }
          ::-webkit-scrollbar {
            width: 0px !important;
            height: 0px !important;
          }
        `;
        document.head.appendChild(style);
      })();
    ''');
  }

  void _retry() {
    setState(() {
      _hasError = false;
      _isLoading = true;
      _isInitialLoad = true;
    });
    _checkConnectivity().then((_) {
      if (_hasConnection) {
        _controller.loadRequest(Uri.parse('https://webtest-oesm.onrender.com'));
      }
    });
  }

  Future<bool> _onWillPop() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
      return false;
    }
    return true;
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: WillPopScope(
        onWillPop: _onWillPop,
        child: Scaffold(
          body: SafeArea(
            top: true,
            bottom: false,
            left: false,
            right: false,
            child: Stack(
              children: [
                if (!_hasError)
                  WebViewWidget(controller: _controller),
                if (_isLoading && !_hasError)
                  const LoadingScreen(),
                if (_hasError)
                  ErrorScreen(
                    message: _errorMessage,
                    onRetry: _retry,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}