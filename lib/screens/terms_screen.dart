// lib/screens/terms_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

enum TermsType { terms, privacy, about }

class TermsScreen extends StatefulWidget {
  final TermsType type;

  const TermsScreen({super.key, required this.type});

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() => _isLoading = true);
          },
          onPageFinished: (String url) {
            setState(() => _isLoading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(_getUrl()));
  }

  String _getUrl() {
    switch (widget.type) {
      case TermsType.terms:
        return 'https://www.facebook.com/legal/terms';
      case TermsType.privacy:
        return 'https://www.facebook.com/privacy/policy';
      case TermsType.about:
        return 'https://about.meta.com/';
    }
  }

  String _getTitle() {
    switch (widget.type) {
      case TermsType.terms:
        return 'Termos de uso';
      case TermsType.privacy:
        return 'Política de privacidade';
      case TermsType.about:
        return 'Sobre';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final cardColor = isDark ? const Color(0xFF242526) : Colors.white;
    final textColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        title: Text(
          _getTitle(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: isDark ? const Color(0xFF3E4042) : const Color(0xFFDADADA),
            height: 0.5,
          ),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1877F2)),
              ),
            ),
        ],
      ),
    );
  }
}