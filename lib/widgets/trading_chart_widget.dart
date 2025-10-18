// lib/widgets/trading_chart_widget.dart
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class TradingChartWidget extends StatefulWidget {
  final String symbol;
  final List<Map<String, dynamic>> tradeHistory;

  const TradingChartWidget({
    Key? key,
    required this.symbol,
    required this.tradeHistory,
  }) : super(key: key);

  @override
  _TradingChartWidgetState createState() => _TradingChartWidgetState();
}

class _TradingChartWidgetState extends State<TradingChartWidget> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            setState(() => _isLoading = false);
            _addTradeMarkers();
          },
        ),
      )
      ..loadRequest(Uri.parse(_getTradingViewUrl()));
  }

  String _getTradingViewUrl() {
    final symbol = _convertSymbolToTradingView(widget.symbol);
    return 'https://www.tradingview.com/chart/?symbol=$symbol&theme=dark&interval=1';
  }

  String _convertSymbolToTradingView(String derivSymbol) {
    final symbolMap = {
      'frxEURUSD': 'FX:EURUSD',
      'frxGBPUSD': 'FX:GBPUSD',
      'frxUSDJPY': 'FX:USDJPY',
      'frxAUDUSD': 'FX:AUDUSD',
      'frxUSDCAD': 'FX:USDCAD',
      'cryBTCUSD': 'BINANCE:BTCUSD',
      'cryETHUSD': 'BINANCE:ETHUSD',
      'R_10': 'FX:EURUSD', // Fallback para synthetic
      'R_25': 'FX:EURUSD',
      'R_50': 'FX:EURUSD',
      'R_75': 'FX:EURUSD',
      'R_100': 'FX:EURUSD',
    };

    return symbolMap[derivSymbol] ?? 'FX:EURUSD';
  }

  void _addTradeMarkers() {
    if (widget.tradeHistory.isEmpty) return;

    // Aqui você pode adicionar lógica para desenhar marcadores no gráfico
    // usando JavaScript injection no WebView
    final lastTrade = widget.tradeHistory.last;
    final isWin = lastTrade['status'] == 'won';
    final color = isWin ? 'green' : 'red';
    final arrow = isWin ? '▲' : '▼';

    _controller.runJavaScript('''
      // Código JavaScript para adicionar marcadores
      console.log('Trade marker: $arrow at ${lastTrade['timestamp']}');
    ''');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Color(0xFF2C2C2E) : Color(0xFFE5E5EA),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            WebViewWidget(controller: _controller),
            if (_isLoading)
              Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF444F)),
                ),
              ),
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Color(0xFFFF444F).withOpacity(0.9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.symbol,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            if (widget.tradeHistory.isNotEmpty)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.show_chart,
                        color: Colors.white,
                        size: 16,
                      ),
                      SizedBox(width: 6),
                      Text(
                        '${widget.tradeHistory.length} trades',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}