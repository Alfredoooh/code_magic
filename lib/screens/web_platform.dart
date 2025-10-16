import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';

class WebTab {
  final String id;
  String url;
  String title;
  WebViewController? controller;

  WebTab({
    required this.id,
    required this.url,
    this.title = 'Nova Aba',
    this.controller,
  });
}

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
  late List<WebTab> _tabs;
  int _currentTabIndex = 0;
  bool _isLoading = true;
  double _progress = 0.0;
  bool _isDarkMode = false;
  final GlobalKey _webViewKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tabs = [
      WebTab(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        url: widget.url,
        title: 'Carregando...',
      ),
    ];
    _initWebView(_tabs[0]);
  }

  void _initWebView(WebTab tab) {
    tab.controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (_tabs[_currentTabIndex].id == tab.id) {
              setState(() {
                _progress = progress / 100;
                _isLoading = progress < 100;
              });
            }
          },
          onPageStarted: (String url) {
            if (_tabs[_currentTabIndex].id == tab.id) {
              setState(() {
                _isLoading = true;
              });
            }
          },
          onPageFinished: (String url) {
            if (_tabs[_currentTabIndex].id == tab.id) {
              setState(() {
                _isLoading = false;
              });
            }
            tab.controller?.getTitle().then((title) {
              if (title != null) {
                setState(() {
                  tab.title = title;
                });
              }
            });
            
            // Apply dark mode if enabled
            if (_isDarkMode) {
              _applyDarkMode(tab.controller!);
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(tab.url));
  }

  void _applyDarkMode(WebViewController controller) {
    controller.runJavaScript('''
      (function() {
        var style = document.createElement('style');
        style.id = 'dark-mode-style';
        style.innerHTML = `
          html {
            filter: invert(1) hue-rotate(180deg) !important;
            background-color: #000 !important;
          }
          img, video, iframe, [style*="background-image"] {
            filter: invert(1) hue-rotate(180deg) !important;
          }
        `;
        var existing = document.getElementById('dark-mode-style');
        if (existing) {
          existing.remove();
        }
        document.head.appendChild(style);
      })();
    ''');
  }

  void _removeDarkMode(WebViewController controller) {
    controller.runJavaScript('''
      (function() {
        var existing = document.getElementById('dark-mode-style');
        if (existing) {
          existing.remove();
        }
      })();
    ''');
  }

  void _toggleDarkMode() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });

    final currentTab = _tabs[_currentTabIndex];
    if (currentTab.controller != null) {
      if (_isDarkMode) {
        _applyDarkMode(currentTab.controller!);
      } else {
        _removeDarkMode(currentTab.controller!);
      }
    }
  }

  Future<void> _takeScreenshot() async {
    try {
      // Captura o screenshot
      RenderRepaintBoundary boundary = _webViewKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      // Adiciona marca d'água
      final watermarkedImage = await _addWatermark(pngBytes);

      // Salva o arquivo
      final directory = await getTemporaryDirectory();
      final imagePath = '${directory.path}/screenshot_${DateTime.now().millisecondsSinceEpoch}.png';
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(watermarkedImage);

      // Compartilha
      await Share.shareXFiles([XFile(imagePath)], text: 'Screenshot from LevelUp');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Screenshot capturado com sucesso!'),
            backgroundColor: CupertinoColors.systemGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao capturar screenshot'),
            backgroundColor: CupertinoColors.systemRed,
          ),
        );
      }
    }
  }

  Future<Uint8List> _addWatermark(Uint8List imageBytes) async {
    final codec = await ui.instantiateImageCodec(imageBytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Desenha a imagem original
    canvas.drawImage(image, Offset.zero, Paint());

    // Adiciona marca d'água
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'from LevelUp',
        style: TextStyle(
          color: Colors.white.withOpacity(0.3),
          fontSize: 40,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    
    // Posiciona no canto inferior direito
    final xPosition = image.width - textPainter.width - 20;
    final yPosition = image.height - textPainter.height - 20;

    // Desenha fundo semi-transparente
    canvas.drawRect(
      Rect.fromLTWH(
        xPosition - 10,
        yPosition - 5,
        textPainter.width + 20,
        textPainter.height + 10,
      ),
      Paint()..color = Colors.black.withOpacity(0.5),
    );

    textPainter.paint(canvas, Offset(xPosition, yPosition));

    final picture = recorder.endRecording();
    final finalImage = await picture.toImage(image.width, image.height);
    final byteData = await finalImage.toByteData(format: ui.ImageByteFormat.png);

    return byteData!.buffer.asUint8List();
  }

  void _showTabsOverview() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _TabsOverviewSheet(
        tabs: _tabs,
        currentIndex: _currentTabIndex,
        onTabSelected: (index) {
          setState(() {
            _currentTabIndex = index;
          });
          Navigator.pop(context);
        },
        onTabClosed: (index) {
          setState(() {
            _tabs.removeAt(index);
            if (_currentTabIndex >= _tabs.length) {
              _currentTabIndex = _tabs.length - 1;
            }
            if (_tabs.isEmpty) {
              Navigator.of(context).pop();
            }
          });
        },
        onNewTab: () {
          setState(() {
            final newTab = WebTab(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              url: 'https://www.google.com',
              title: 'Nova Aba',
            );
            _tabs.add(newTab);
            _currentTabIndex = _tabs.length - 1;
            _initWebView(newTab);
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showOptions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _tabs[_currentTabIndex].controller?.reload();
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
              _toggleDarkMode();
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_isDarkMode ? CupertinoIcons.sun_max : CupertinoIcons.moon, size: 20),
                SizedBox(width: 8),
                Text(_isDarkMode ? 'Modo Claro' : 'Modo Escuro'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _takeScreenshot();
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.camera, size: 20),
                SizedBox(width: 8),
                Text('Capturar Tela'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.pop(context);
              final url = _tabs[_currentTabIndex].url;
              await Share.share(url, subject: _tabs[_currentTabIndex].title);
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
            onPressed: () async {
              Navigator.pop(context);
              final url = _tabs[_currentTabIndex].url;
              if (await canLaunchUrl(Uri.parse(url))) {
                await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
              }
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
          onPressed: () => Navigator.pop(context),
          child: Text('Cancelar'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentTab = _tabs[_currentTabIndex];

    return WillPopScope(
      onWillPop: () async {
        if (currentTab.controller != null && await currentTab.controller!.canGoBack()) {
          await currentTab.controller!.goBack();
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: isDark ? Color(0xFF000000) : Colors.white,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // WebView
              Expanded(
                child: RepaintBoundary(
                  key: _webViewKey,
                  child: currentTab.controller != null
                      ? WebViewWidget(controller: currentTab.controller!)
                      : Center(child: CupertinoActivityIndicator()),
                ),
              ),
              // Bottom Bar
              Container(
                height: 52,
                decoration: BoxDecoration(
                  color: isDark ? Color(0xFF1C1C1E) : Color(0xFFF9F9F9),
                  border: Border(
                    top: BorderSide(
                      color: isDark ? Color(0xFF38383A) : Color(0xFFE5E5EA),
                      width: 0.5,
                    ),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Row(
                    children: [
                      // Tabs Button
                      CupertinoButton(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        minSize: 0,
                        onPressed: _showTabsOverview,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(
                              CupertinoIcons.square_on_square,
                              color: isDark ? Colors.white : Colors.black87,
                              size: 24,
                            ),
                            if (_tabs.length > 1)
                              Positioned(
                                top: -2,
                                right: -6,
                                child: Container(
                                  padding: EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Color(0xFFFF444F),
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  child: Text(
                                    '${_tabs.length}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      SizedBox(width: 4),
                      // Title Container
                      Expanded(
                        child: Container(
                          height: 36,
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: isDark ? Color(0xFF2C2C2E) : Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isDark ? Color(0xFF38383A) : Color(0xFFE5E5EA),
                              width: 0.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              if (_isLoading)
                                SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Color(0xFFFF444F),
                                    ),
                                  ),
                                )
                              else
                                Icon(
                                  CupertinoIcons.lock_fill,
                                  size: 14,
                                  color: Colors.grey,
                                ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  currentTab.title,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 4),
                      // Options Button
                      CupertinoButton(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        minSize: 0,
                        onPressed: _showOptions,
                        child: Icon(
                          CupertinoIcons.ellipsis_circle,
                          color: isDark ? Colors.white : Colors.black87,
                          size: 24,
                        ),
                      ),
                    ],
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

// Tabs Overview Sheet
class _TabsOverviewSheet extends StatelessWidget {
  final List<WebTab> tabs;
  final int currentIndex;
  final Function(int) onTabSelected;
  final Function(int) onTabClosed;
  final VoidCallback onNewTab;

  const _TabsOverviewSheet({
    required this.tabs,
    required this.currentIndex,
    required this.onTabSelected,
    required this.onTabClosed,
    required this.onNewTab,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1C1C1E) : Color(0xFFF2F2F7),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.only(top: 8),
            width: 36,
            height: 5,
            decoration: BoxDecoration(
              color: isDark ? Color(0xFF48484A) : Color(0xFFD1D1D6),
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
          SizedBox(height: 20),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${tabs.length} ${tabs.length == 1 ? "Aba" : "Abas"}',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: onNewTab,
                  child: Icon(
                    CupertinoIcons.plus_circle_fill,
                    color: CupertinoColors.systemBlue,
                    size: 32,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.75,
              ),
              itemCount: tabs.length,
              itemBuilder: (context, index) {
                final tab = tabs[index];
                final isActive = index == currentIndex;

                return GestureDetector(
                  onTap: () => onTabSelected(index),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? Color(0xFF2C2C2E) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: isActive
                          ? Border.all(color: CupertinoColors.systemBlue, width: 2)
                          : null,
                    ),
                    child: Stack(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: Container(
                                margin: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isDark ? Color(0xFF1C1C1E) : Color(0xFFF2F2F7),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Icon(
                                    CupertinoIcons.doc_text,
                                    size: 48,
                                    color: Colors.grey,
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.all(12),
                              child: Text(
                                tab.title,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: CupertinoButton(
                            padding: EdgeInsets.all(4),
                            minSize: 0,
                            onPressed: () => onTabClosed(index),
                            child: Container(
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                CupertinoIcons.xmark,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}