import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'web_tab.dart';
import 'tabs_overview_screen.dart';
import 'pattern_analysis_screen.dart';
import 'features_bottom_sheet.dart';

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
  bool _adaptColors = false;
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
                tab.url = url;
              });
            }
          },
          onPageFinished: (String url) async {
            if (_tabs[_currentTabIndex].id == tab.id) {
              setState(() {
                _isLoading = false;
              });
            }
            
            final title = await tab.controller?.getTitle();
            if (title != null) {
              setState(() {
                tab.title = title;
              });
            }
            
            // Captura screenshot do tab
            await _captureTabScreenshot(tab);
            
            if (_isDarkMode) {
              _applyDarkMode(tab.controller!);
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(tab.url));
  }

  Future<void> _captureTabScreenshot(WebTab tab) async {
    try {
      await Future.delayed(Duration(milliseconds: 500));
      if (_webViewKey.currentContext != null) {
        RenderRepaintBoundary boundary = _webViewKey.currentContext!
            .findRenderObject() as RenderRepaintBoundary;
        ui.Image image = await boundary.toImage(pixelRatio: 0.5);
        ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          setState(() {
            tab.screenshot = byteData.buffer.asUint8List();
          });
        }
      }
    } catch (e) {
      print('Erro ao capturar screenshot: $e');
    }
  }

  void _applyDarkMode(WebViewController controller) {
    if (_adaptColors) {
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
    } else {
      controller.runJavaScript('''
        (function() {
          var style = document.createElement('style');
          style.id = 'dark-mode-style';
          style.innerHTML = `
            html {
              filter: invert(0.9) !important;
              background-color: #000 !important;
            }
            img, video, iframe, [style*="background-image"] {
              filter: invert(1) !important;
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

  Future<void> _shareScreenshot() async {
    try {
      RenderRepaintBoundary boundary = _webViewKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final watermarkedImage = await _addWatermark(pngBytes);

      final directory = await getTemporaryDirectory();
      final imagePath = '${directory.path}/screenshot_${DateTime.now().millisecondsSinceEpoch}.png';
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(watermarkedImage);

      await Share.shareXFiles([XFile(imagePath)], text: 'Screenshot from LevelUp');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Screenshot compartilhado com sucesso!'),
            backgroundColor: CupertinoColors.systemGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao compartilhar screenshot'),
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

    canvas.drawImage(image, Offset.zero, Paint());

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
    
    final xPosition = image.width - textPainter.width - 20;
    final yPosition = image.height - textPainter.height - 20;

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

  void _showTabsOverview() async {
    final result = await Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => TabsOverviewScreen(
          tabs: _tabs,
          currentIndex: _currentTabIndex,
          onTabSelected: (index) {
            setState(() {
              _currentTabIndex = index;
            });
          },
          onTabClosed: (index) {
            setState(() {
              _tabs.removeAt(index);
              if (_currentTabIndex >= _tabs.length) {
                _currentTabIndex = _tabs.length - 1;
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
          },
        ),
      ),
    );

    if (_tabs.isEmpty) {
      Navigator.of(context).pop();
    }
  }

  void _showOptions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    
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
                Icon(CupertinoIcons.refresh, size: 20, color: primaryColor),
                SizedBox(width: 8),
                Text('Recarregar', style: TextStyle(color: primaryColor)),
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
                Icon(_isDarkMode ? CupertinoIcons.sun_max : CupertinoIcons.moon, 
                     size: 20, color: primaryColor),
                SizedBox(width: 8),
                Text(_isDarkMode ? 'Modo Claro' : 'Modo Escuro',
                     style: TextStyle(color: primaryColor)),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              showCupertinoDialog(
                context: context,
                builder: (context) => CupertinoAlertDialog(
                  title: Text('Adaptação de Cor'),
                  content: Column(
                    children: [
                      SizedBox(height: 16),
                      Text('Adaptar cores do site ao modo escuro'),
                      SizedBox(height: 16),
                      CupertinoSwitch(
                        value: _adaptColors,
                        activeColor: primaryColor,
                        onChanged: (value) {
                          setState(() {
                            _adaptColors = value;
                          });
                          if (_isDarkMode) {
                            _applyDarkMode(_tabs[_currentTabIndex].controller!);
                          }
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.color_filter, size: 20, color: primaryColor),
                SizedBox(width: 8),
                Text('Adaptação de Cor', style: TextStyle(color: primaryColor)),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _shareScreenshot();
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.photo, size: 20, color: primaryColor),
                SizedBox(width: 8),
                Text('Partilhar Conteúdo', style: TextStyle(color: primaryColor)),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.xmark_circle, size: 20, color: CupertinoColors.systemRed),
                SizedBox(width: 8),
                Text('Fechar Atividade', style: TextStyle(color: CupertinoColors.systemRed)),
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

  void _showFeatures() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => FeaturesBottomSheet(
        onPatternAnalysis: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) => 
                PatternAnalysisScreen(webViewKey: _webViewKey),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                const begin = Offset(0.0, 1.0);
                const end = Offset.zero;
                const curve = Curves.easeInOut;
                var tween = Tween(begin: begin, end: end).chain(
                  CurveTween(curve: curve),
                );
                return SlideTransition(
                  position: animation.drive(tween),
                  child: child,
                );
              },
            ),
          );
        },
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
              Expanded(
                child: RepaintBoundary(
                  key: _webViewKey,
                  child: currentTab.controller != null
                      ? WebViewWidget(controller: currentTab.controller!)
                      : Center(child: CupertinoActivityIndicator()),
                ),
              ),
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
                      CupertinoButton(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        minSize: 0,
                        onPressed: _showTabsOverview,
                        child: Container(
                          width: 32,
                          height: 32,
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
                                  bottom: 2,
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.white : Colors.black87,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: Text(
                                      '${_tabs.length}',
                                      style: TextStyle(
                                        color: isDark ? Colors.black : Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 4),
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
                                      Theme.of(context).primaryColor,
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
                      CupertinoButton(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        minSize: 0,
                        onPressed: _showFeatures,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Funcionalidades',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
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