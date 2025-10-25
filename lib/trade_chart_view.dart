// 4. trade_chart_view.dart
// ========================================
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'trade_logic_controller.dart';

class TradeChartView extends StatefulWidget {
  final TradeLogicController controller;
  final bool isExpanded;
  final VoidCallback onExpandToggle;

  const TradeChartView({
    Key? key,
    required this.controller,
    required this.isExpanded,
    required this.onExpandToggle,
  }) : super(key: key);

  @override
  State<TradeChartView> createState() => _TradeChartViewState();
}

class _TradeChartViewState extends State<TradeChartView> {
  late WebViewController _webViewController;
  String _chartType = 'candlestick';

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..addJavaScriptChannel(
        'FlutterChannel',
        onMessageReceived: (JavaScriptMessage message) {
          final data = json.decode(message.message);
          if (data['type'] == 'price') {
            widget.controller.updatePrice(
              (data['price'] as num).toDouble(),
              (data['change'] ?? 0.0) is num ? (data['change'] as num).toDouble() : 0.0,
            );
          }
        },
      )
      ..loadHtmlString(_getChartHTML());
  }

  String _getChartHTML() {
    return '''
<!doctype html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <script src="https://cdnjs.cloudflare.com/ajax/libs/lightweight-charts/3.8.0/lightweight-charts.standalone.production.js"></script>
  <style>
    body { margin: 0; padding: 0; background: #000; overflow: hidden; }
    #chart { width: 100vw; height: 100vh; }
  </style>
</head>
<body>
  <div id="chart"></div>
  <script>
    const chart = LightweightCharts.createChart(document.getElementById('chart'), {
      layout: { background: { color: '#000' }, textColor: '#fff' },
      grid: { vertLines: { color: '#1a1a1a' }, horzLines: { color: '#1a1a1a' } },
      crosshair: { mode: LightweightCharts.CrosshairMode.Normal },
      timeScale: { borderColor: '#2a2a2a', timeVisible: true, secondsVisible: false },
      rightPriceScale: { borderColor: '#2a2a2a' }
    });
    
    const candleSeries = chart.addCandlestickSeries({
      upColor: '#00C896',
      downColor: '#FF4444',
      borderVisible: false,
      wickUpColor: '#00C896',
      wickDownColor: '#FF4444'
    });

    // Dados simulados
    const data = [];
    let time = Math.floor(Date.now() / 1000) - 300;
    let price = 1000 + Math.random() * 100;
    
    for (let i = 0; i < 100; i++) {
      const open = price;
      const change = (Math.random() - 0.5) * 10;
      const close = price + change;
      const high = Math.max(open, close) + Math.random() * 5;
      const low = Math.min(open, close) - Math.random() * 5;
      
      data.push({ time: time + i * 3, open, high, low, close });
      price = close;
    }
    
    candleSeries.setData(data);
    chart.timeScale().fitContent();

    // Atualização em tempo real
    setInterval(() => {
      const lastBar = data[data.length - 1];
      const newTime = lastBar.time + 3;
      const change = (Math.random() - 0.5) * 10;
      const close = lastBar.close + change;
      
      const newBar = {
        time: newTime,
        open: lastBar.close,
        high: Math.max(lastBar.close, close) + Math.random() * 3,
        low: Math.min(lastBar.close, close) - Math.random() * 3,
        close: close
      };
      
      data.push(newBar);
      if (data.length > 100) data.shift();
      
      candleSeries.update(newBar);
      
      FlutterChannel.postMessage(JSON.stringify({
        type: 'price',
        price: close,
        change: ((close - lastBar.close) / lastBar.close) * 100
      }));
    }, 1000);

    function addEntryMarker(direction, price) {
      const marker = {
        time: data[data.length - 1].time,
        position: direction === 'buy' ? 'belowBar' : 'aboveBar',
        color: direction === 'buy' ? '#00C896' : '#FF4444',
        shape: direction === 'buy' ? 'arrowUp' : 'arrowDown',
        text: direction.toUpperCase()
      };
      candleSeries.setMarkers([marker]);
    }
  </script>
</body>
</html>
''';
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        WebViewWidget(controller: _webViewController),
        if (widget.isExpanded) _buildTechnicalAnalysis(),
        _buildChartControls(),
        if (widget.controller.activePositions.isNotEmpty) _buildPositionsOverlay(),
      ],
    );
  }

  Widget _buildTechnicalAnalysis() {
    return Positioned(
      left: 12,
      top: 12,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAnalysisItem('Entry', widget.controller.entryPrice ?? 0.0),
            _buildAnalysisItem('Current', widget.controller.currentPrice),
            _buildAnalysisItem(
              'P/L',
              widget.controller.entryPrice != null
                  ? (widget.controller.currentPrice - widget.controller.entryPrice!) *
                      (widget.controller.entryDirection == 'buy' ? 1 : -1)
                  : 0.0,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisItem(String label, double value) {
    Color valueColor = Colors.white;
    if (label == 'P/L' && value != 0) {
      valueColor = value >= 0 ? const Color(0xFF00C896) : const Color(0xFFFF4444);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(color: Colors.white70, fontSize: 12)),
          Text(
            value.toStringAsFixed(2),
            style: TextStyle(color: valueColor, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildChartControls() {
    return Positioned(
      top: 12,
      right: 12,
      child: Column(
        children: [
          _buildControlButton(
            icon: widget.isExpanded ? CupertinoIcons.fullscreen_exit : CupertinoIcons.fullscreen,
            onPressed: widget.onExpandToggle,
          ),
          const SizedBox(height: 8),
          _buildControlButton(
            icon: CupertinoIcons.chart_bar,
            onPressed: _showChartTypeSelector,
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({required IconData icon, required VoidCallback onPressed}) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minSize: 0,
      onPressed: onPressed,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildPositionsOverlay() {
    return Positioned(
      bottom: 12,
      left: 12,
      right: 12,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.85),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          children: widget.controller.activePositions.map<Widget>((pos) {
            final profit = (pos['profit'] as num?)?.toDouble() ?? 0.0;
            final isProfit = profit >= 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Position',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  Text(
                    '${isProfit ? '+' : ''}\$${profit.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: isProfit ? const Color(0xFF00C896) : const Color(0xFFFF4444),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showChartTypeSelector() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Tipo de Gráfico'),
        actions: [
          CupertinoActionSheetAction(
            child: const Text('Candlestick'),
            onPressed: () {
              setState(() => _chartType = 'candlestick');
              Navigator.pop(context);
            },
          ),
          CupertinoActionSheetAction(
            child: const Text('Line'),
            onPressed: () {
              setState(() => _chartType = 'line');
              Navigator.pop(context);
            },
          ),
          CupertinoActionSheetAction(
            child: const Text('Area'),
            onPressed: () {
              setState(() => _chartType = 'area');
              Navigator.pop(context);
            },
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          child: const Text('Cancelar'),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }
}
