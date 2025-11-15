// lib/screens/terms_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/custom_icons.dart';
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
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() => _isLoading = true);
          },
          onPageFinished: (String url) {
            // Remove scrollbar com JavaScript
            _controller.runJavaScript('''
              var style = document.createElement('style');
              style.innerHTML = `
                ::-webkit-scrollbar { display: none !important; }
                body { -ms-overflow-style: none !important; scrollbar-width: none !important; }
                * { -webkit-overflow-scrolling: touch !important; }
              `;
              document.head.appendChild(style);
            ''');
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
    final bgColor = isDark ? const Color(0xFF18191A) : const Color(0xFFF0F2F5);
    final cardColor = isDark ? const Color(0xFF242526) : Colors.white;
    final textColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: SvgPicture.string(
            CustomIcons.arrowLeft,
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(textColor, BlendMode.srcIn),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _getTitle(),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(
            color: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFE4E6EB),
            height: 0.5,
          ),
        ),
      ),
      body: Stack(
        children: [
          // WebView sem padding para ocupar toda a tela
          Positioned.fill(
            child: WebViewWidget(controller: _controller),
          ),
          if (_isLoading)
            Container(
              color: bgColor,
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1877F2)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}