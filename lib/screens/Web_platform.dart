import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebPlatformScreen extends StatefulWidget {
  final String url;

  const WebPlatformScreen({
    Key? key,
    required this.url,
  }) : super(key: key);

  @override
  _WebPlatformScreenState createState() => _WebPlatformScreenState();
}

class _WebPlatformScreenState extends State<WebPlatformScreen> {
  late WebViewController _controller;
  bool _isLoading = true;
  double _progress = 0.0;
  String _currentTitle = 'Carregando...';

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
          onProgress: (int progress) {
            setState(() {
              _progress = progress / 100;
              _isLoading = progress < 100;
            });
          },
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
            _controller.getTitle().then((title) {
              if (title != null) {
                setState(() {
                  _currentTitle = title;
                });
              }
            });
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _isLoading = false;
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  Future<void> _refresh() async {
    await _controller.reload();
  }

  void _goBack() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
    } else {
      Navigator.of(context).pop();
    }
  }

  void _goForward() async {
    if (await _controller.canGoForward()) {
      await _controller.goForward();
    }
  }

  void _showOptions(BuildContext context, bool isDark) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Text(
          'Opções do Navegador',
          style: TextStyle(
            fontSize: 13,
            color: CupertinoColors.systemGrey,
          ),
        ),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _refresh();
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.refresh, size: 20),
                SizedBox(width: 8),
                Text('Recarregar'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              // Implementar compartilhar URL
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.share, size: 20),
                SizedBox(width: 8),
                Text('Compartilhar'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              // Implementar abrir no navegador externo
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.compass, size: 20),
                SizedBox(width: 8),
                Text('Abrir no Navegador'),
              ],
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text('Cancelar'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return WillPopScope(
      onWillPop: () async {
        if (await _controller.canGoBack()) {
          await _controller.goBack();
          return false;
        }
        return true;
      },
      child: CupertinoPageScaffold(
        backgroundColor: isDark ? Color(0xFF0E0E0E) : Color(0xFFF5F5F5),
        navigationBar: CupertinoNavigationBar(
          backgroundColor: isDark ? Color(0xFF1A1A1A) : CupertinoColors.white,
          leading: CupertinoButton(
            padding: EdgeInsets.zero,
            child: Icon(
              CupertinoIcons.back,
              color: isDark ? CupertinoColors.white : CupertinoColors.black,
            ),
            onPressed: _goBack,
          ),
          middle: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _currentTitle,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: isDark ? CupertinoColors.white : CupertinoColors.black,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (_isLoading)
                Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: SizedBox(
                    width: 120,
                    height: 2,
                    child: LinearProgressIndicator(
                      value: _progress,
                      backgroundColor: CupertinoColors.systemGrey.withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF444F)),
                    ),
                  ),
                ),
            ],
          ),
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            child: Icon(
              CupertinoIcons.ellipsis_circle,
              color: isDark ? CupertinoColors.white : CupertinoColors.black,
              size: 28,
            ),
            onPressed: () => _showOptions(context, isDark),
          ),
          border: null,
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: WebViewWidget(
                  controller: _controller,
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? Color(0xFF1A1A1A) : CupertinoColors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: _goBack,
                          child: Icon(
                            CupertinoIcons.chevron_back,
                            color: isDark ? CupertinoColors.white : CupertinoColors.black,
                            size: 28,
                          ),
                        ),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: _goForward,
                          child: Icon(
                            CupertinoIcons.chevron_forward,
                            color: isDark ? CupertinoColors.white : CupertinoColors.black,
                            size: 28,
                          ),
                        ),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: _refresh,
                          child: Icon(
                            CupertinoIcons.refresh,
                            color: isDark ? CupertinoColors.white : CupertinoColors.black,
                            size: 28,
                          ),
                        ),
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => _showOptions(context, isDark),
                          child: Icon(
                            CupertinoIcons.ellipsis,
                            color: isDark ? CupertinoColors.white : CupertinoColors.black,
                            size: 28,
                          ),
                        ),
                      ],
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
}