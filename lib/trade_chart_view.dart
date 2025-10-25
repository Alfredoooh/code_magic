// trade_chart_view.dart - VERSÃO PROFISSIONAL
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
  bool _chartReady = false;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  @override
  void didUpdateWidget(TradeChartView oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Atualizar marcadores quando entryPrice ou entryDirection mudar
    if (_chartReady && widget.controller.entryPrice != null && 
        (oldWidget.controller.entryPrice != widget.controller.entryPrice ||
         oldWidget.controller.entryDirection != widget.controller.entryDirection)) {
      _updateEntryMarker();
    }
    
    // Remover marcadores quando posição for fechada
    if (_chartReady && widget.controller.entryPrice == null && 
        oldWidget.controller.entryPrice != null) {
      _clearMarkers();
    }
  }

  void _initWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..addJavaScriptChannel(
        'FlutterChannel',
        onMessageReceived: (JavaScriptMessage message) {
          try {
            final data = json.decode(message.message);
            if (data['type'] == 'price') {
              widget.controller.updatePrice(
                (data['price'] as num).toDouble(),
                (data['change'] ?? 0.0) is num ? (data['change'] as num).toDouble() : 0.0,
              );
            } else if (data['type'] == 'chart_ready') {
              setState(() => _chartReady = true);
              if (widget.controller.entryPrice != null) {
                _updateEntryMarker();
              }
            }
          } catch (e) {
            debugPrint('Error parsing chart message: $e');
          }
        },
      )
      ..loadHtmlString(_getChartHTML());
  }

  void _updateEntryMarker() {
    if (!_chartReady || widget.controller.entryPrice == null) return;
    
    final entry = widget.controller.entryPrice!;
    final direction = widget.controller.entryDirection ?? 'buy';
    final current = widget.controller.currentPrice;
    
    _webViewController.runJavaScript('''
      updateTradeMarkers(
        $entry, 
        "$direction", 
        $current,
        ${widget.controller.multiplierStopLossPercent},
        ${widget.controller.multiplierTakeProfitPercent}
      );
    ''');
  }

  void _clearMarkers() {
    if (!_chartReady) return;
    _webViewController.runJavaScript('clearTradeMarkers();');
  }

  String _getChartHTML() {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <script src="https://cdnjs.cloudflare.com/ajax/libs/lightweight-charts/4.1.1/lightweight-charts.standalone.production.js"></script>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { 
      margin: 0; 
      padding: 0; 
      background: #000; 
      overflow: hidden;
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
    }
    #chart { width: 100vw; height: 100vh; position: relative; }
    
    .price-label {
      position: absolute;
      right: 8px;
      padding: 6px 12px;
      border-radius: 4px;
      font-size: 12px;
      font-weight: bold;
      z-index: 100;
      pointer-events: none;
      box-shadow: 0 2px 8px rgba(0,0,0,0.3);
    }
    
    .current-price {
      background: #0066FF;
      color: white;
    }
    
    .entry-price {
      background: rgba(255, 255, 255, 0.1);
      color: white;
      border: 2px dashed;
    }
    
    .entry-price.buy { border-color: #00C896; }
    .entry-price.sell { border-color: #FF4444; }
    
    .pl-label {
      position: absolute;
      top: 50%;
      left: 50%;
      transform: translate(-50%, -50%);
      padding: 12px 24px;
      border-radius: 8px;
      font-size: 16px;
      font-weight: 900;
      z-index: 101;
      pointer-events: none;
      backdrop-filter: blur(10px);
    }
    
    .pl-label.profit {
      background: rgba(0, 200, 150, 0.2);
      color: #00C896;
      border: 2px solid #00C896;
    }
    
    .pl-label.loss {
      background: rgba(255, 68, 68, 0.2);
      color: #FF4444;
      border: 2px solid #FF4444;
    }
  </style>
</head>
<body>
  <div id="chart"></div>
  
  <script>
    // Configuração do chart profissional
    const chart = LightweightCharts.createChart(document.getElementById('chart'), {
      layout: { 
        background: { color: '#000000' }, 
        textColor: '#FFFFFF' 
      },
      grid: { 
        vertLines: { color: 'rgba(42, 42, 42, 0.5)' }, 
        horzLines: { color: 'rgba(42, 42, 42, 0.5)' } 
      },
      crosshair: { 
        mode: LightweightCharts.CrosshairMode.Normal,
        vertLine: {
          width: 1,
          color: 'rgba(255, 255, 255, 0.3)',
          style: LightweightCharts.LineStyle.Dashed,
        },
        horzLine: {
          width: 1,
          color: 'rgba(255, 255, 255, 0.3)',
          style: LightweightCharts.LineStyle.Dashed,
        },
      },
      timeScale: { 
        borderColor: '#2A2A2A',
        timeVisible: true,
        secondsVisible: true,
        rightOffset: 12,
        barSpacing: 12,
        minBarSpacing: 8,
      },
      rightPriceScale: { 
        borderColor: '#2A2A2A',
        scaleMargins: {
          top: 0.1,
          bottom: 0.1,
        },
      },
      handleScroll: {
        vertTouchDrag: true,
        horzTouchDrag: true,
      },
      handleScale: {
        axisPressedMouseMove: true,
        mouseWheel: true,
        pinch: true,
      },
    });
    
    // Series principal
    const candleSeries = chart.addCandlestickSeries({
      upColor: '#00C896',
      downColor: '#FF4444',
      borderVisible: false,
      wickUpColor: '#00C896',
      wickDownColor: '#FF4444',
      priceFormat: {
        type: 'price',
        precision: 2,
        minMove: 0.01,
      },
    });
    
    // Volume series
    const volumeSeries = chart.addHistogramSeries({
      color: '#26a69a',
      priceFormat: {
        type: 'volume',
      },
      priceScaleId: '',
      scaleMargins: {
        top: 0.8,
        bottom: 0,
      },
    });
    
    // Linha de entrada (será adicionada quando trade for aberto)
    let entryLine = null;
    let stopLossLine = null;
    let takeProfitLine = null;
    let currentPriceLine = null;
    
    // Dados do chart
    const data = [];
    const volumeData = [];
    let time = Math.floor(Date.now() / 1000) - 300;
    let basePrice = 1000 + Math.random() * 100;
    
    // Gerar dados históricos realistas
    for (let i = 0; i < 100; i++) {
      const open = basePrice;
      const volatility = 5 + Math.random() * 5;
      const change = (Math.random() - 0.5) * volatility;
      const close = basePrice + change;
      const high = Math.max(open, close) + Math.random() * volatility * 0.5;
      const low = Math.min(open, close) - Math.random() * volatility * 0.5;
      const volume = 1000 + Math.random() * 5000;
      
      data.push({ 
        time: time + i * 3, 
        open: parseFloat(open.toFixed(2)), 
        high: parseFloat(high.toFixed(2)), 
        low: parseFloat(low.toFixed(2)), 
        close: parseFloat(close.toFixed(2)) 
      });
      
      volumeData.push({
        time: time + i * 3,
        value: volume,
        color: close >= open ? 'rgba(0, 200, 150, 0.5)' : 'rgba(255, 68, 68, 0.5)'
      });
      
      basePrice = close + (Math.random() - 0.5) * 2;
    }
    
    candleSeries.setData(data);
    volumeSeries.setData(volumeData);
    
    // Linha de preço atual
    currentPriceLine = candleSeries.createPriceLine({
      price: data[data.length - 1].close,
      color: '#0066FF',
      lineWidth: 2,
      lineStyle: LightweightCharts.LineStyle.Solid,
      axisLabelVisible: true,
      title: '',
    });
    
    chart.timeScale().fitContent();
    
    // Notificar Flutter que chart está pronto
    setTimeout(() => {
      FlutterChannel.postMessage(JSON.stringify({ type: 'chart_ready' }));
    }, 500);
    
    // Atualização em tempo real com movimento realista
    let lastPrice = data[data.length - 1].close;
    let trend = 0;
    
    setInterval(() => {
      const lastBar = data[data.length - 1];
      const newTime = lastBar.time + 3;
      
      // Movimento mais realista com tendência
      trend += (Math.random() - 0.5) * 0.5;
      trend = Math.max(-5, Math.min(5, trend));
      
      const volatility = 3 + Math.random() * 4;
      const change = (Math.random() - 0.5) * volatility + trend * 0.3;
      const close = lastPrice + change;
      const high = Math.max(lastPrice, close) + Math.random() * volatility * 0.3;
      const low = Math.min(lastPrice, close) - Math.random() * volatility * 0.3;
      const volume = 1000 + Math.random() * 5000;
      
      const newBar = {
        time: newTime,
        open: parseFloat(lastPrice.toFixed(2)),
        high: parseFloat(high.toFixed(2)),
        low: parseFloat(low.toFixed(2)),
        close: parseFloat(close.toFixed(2))
      };
      
      const newVolume = {
        time: newTime,
        value: volume,
        color: close >= lastPrice ? 'rgba(0, 200, 150, 0.5)' : 'rgba(255, 68, 68, 0.5)'
      };
      
      data.push(newBar);
      volumeData.push(newVolume);
      
      if (data.length > 100) {
        data.shift();
        volumeData.shift();
      }
      
      candleSeries.update(newBar);
      volumeSeries.update(newVolume);
      
      // Atualizar linha de preço atual
      if (currentPriceLine) {
        currentPriceLine.applyOptions({ price: close });
      }
      
      lastPrice = close;
      
      // Enviar preço para Flutter
      FlutterChannel.postMessage(JSON.stringify({
        type: 'price',
        price: close,
        change: ((close - lastBar.close) / lastBar.close) * 100
      }));
      
    }, 1000);
    
    // Função para atualizar marcadores de trade
    function updateTradeMarkers(entryPrice, direction, currentPrice, stopLossPercent, takeProfitPercent) {
      // Limpar marcadores anteriores
      clearTradeMarkers();
      
      const isBuy = direction === 'buy';
      const entryColor = isBuy ? '#00C896' : '#FF4444';
      
      // Linha de entrada
      entryLine = candleSeries.createPriceLine({
        price: entryPrice,
        color: entryColor,
        lineWidth: 2,
        lineStyle: LightweightCharts.LineStyle.Dashed,
        axisLabelVisible: true,
        title: 'Entry: ' + entryPrice.toFixed(2),
      });
      
      // Stop Loss (se configurado)
      if (stopLossPercent > 0) {
        const slPrice = isBuy 
          ? entryPrice * (1 - stopLossPercent / 100)
          : entryPrice * (1 + stopLossPercent / 100);
          
        stopLossLine = candleSeries.createPriceLine({
          price: slPrice,
          color: '#FF4444',
          lineWidth: 1,
          lineStyle: LightweightCharts.LineStyle.Dotted,
          axisLabelVisible: true,
          title: 'SL: ' + slPrice.toFixed(2),
        });
      }
      
      // Take Profit (se configurado)
      if (takeProfitPercent > 0) {
        const tpPrice = isBuy
          ? entryPrice * (1 + takeProfitPercent / 100)
          : entryPrice * (1 - takeProfitPercent / 100);
          
        takeProfitLine = candleSeries.createPriceLine({
          price: tpPrice,
          color: '#00C896',
          lineWidth: 1,
          lineStyle: LightweightCharts.LineStyle.Dotted,
          axisLabelVisible: true,
          title: 'TP: ' + tpPrice.toFixed(2),
        });
      }
      
      // Marcador visual no ponto de entrada
      const markers = candleSeries.markers() || [];
      markers.push({
        time: data[data.length - 1].time,
        position: isBuy ? 'belowBar' : 'aboveBar',
        color: entryColor,
        shape: isBuy ? 'arrowUp' : 'arrowDown',
        text: (isBuy ? 'BUY' : 'SELL') + ' @ ' + entryPrice.toFixed(2),
        size: 2,
      });
      candleSeries.setMarkers(markers);
    }
    
    function clearTradeMarkers() {
      if (entryLine) {
        candleSeries.removePriceLine(entryLine);
        entryLine = null;
      }
      if (stopLossLine) {
        candleSeries.removePriceLine(stopLossLine);
        stopLossLine = null;
      }
      if (takeProfitLine) {
        candleSeries.removePriceLine(takeProfitLine);
        takeProfitLine = null;
      }
      candleSeries.setMarkers([]);
    }
    
    function changeChartType(type) {
      // Implementar mudança de tipo de chart se necessário
      console.log('Chart type changed to:', type);
    }
    
    // Auto-resize
    window.addEventListener('resize', () => {
      chart.applyOptions({
        width: window.innerWidth,
        height: window.innerHeight
      });
    });
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
        if (widget.isExpanded && widget.controller.entryPrice != null) 
          _buildProfitLossOverlay(),
        if (widget.isExpanded) _buildTechnicalAnalysis(),
        _buildChartControls(),
        if (widget.controller.activePositions.isNotEmpty) _buildPositionsOverlay(),
      ],
    );
  }

  Widget _buildProfitLossOverlay() {
    if (widget.controller.entryPrice == null) return const SizedBox.shrink();
    
    final entry = widget.controller.entryPrice!;
    final current = widget.controller.currentPrice;
    final isBuy = widget.controller.entryDirection == 'buy';
    
    final pips = (current - entry) * (isBuy ? 1 : -1);
    final plPercent = (pips / entry) * 100;
    final isProfit = pips > 0;
    
    return Positioned(
      top: 60,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: (isProfit ? const Color(0xFF00C896) : const Color(0xFFFF4444))
                .withOpacity(0.15),
            border: Border.all(
              color: isProfit ? const Color(0xFF00C896) : const Color(0xFFFF4444),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(16),
            backdropFilter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${isProfit ? '+' : ''}${pips.toStringAsFixed(2)} pips',
                style: TextStyle(
                  color: isProfit ? const Color(0xFF00C896) : const Color(0xFFFF4444),
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
              Text(
                '${isProfit ? '+' : ''}${plPercent.toStringAsFixed(2)}%',
                style: TextStyle(
                  color: (isProfit ? const Color(0xFF00C896) : const Color(0xFFFF4444))
                      .withOpacity(0.8),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
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
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.controller.entryPrice != null) ...[
              _buildAnalysisItem('Entry', widget.controller.entryPrice!, 
                  color: widget.controller.entryDirection == 'buy' 
                      ? const Color(0xFF00C896) 
                      : const Color(0xFFFF4444)),
              const SizedBox(height: 4),
            ],
            _buildAnalysisItem('Current', widget.controller.currentPrice, 
                color: const Color(0xFF0066FF)),
            if (widget.controller.entryPrice != null) ...[
              const SizedBox(height: 4),
              _buildAnalysisItem(
                'P/L',
                (widget.controller.currentPrice - widget.controller.entryPrice!) *
                    (widget.controller.entryDirection == 'buy' ? 1 : -1),
                isPL: true,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisItem(String label, double value, 
      {bool isPL = false, Color? color}) {
    Color valueColor = color ?? Colors.white;
    String prefix = '';
    
    if (isPL) {
      valueColor = value >= 0 ? const Color(0xFF00C896) : const Color(0xFFFF4444);
      prefix = value >= 0 ? '+' : '';
    }

    return Row(
      children: [
        Text(
          '$label: ',
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        Text(
          '$prefix${value.toStringAsFixed(2)}',
          style: TextStyle(
            color: valueColor,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildChartControls() {
    return Positioned(
      top: 12,
      right: 12,
      child: Column(
        children: [
          _buildControlButton(
            icon: widget.isExpanded 
                ? CupertinoIcons.fullscreen_exit 
                : CupertinoIcons.fullscreen,
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
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
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
          border: Border.all(color: Colors.white.withOpacity(0.15)),
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
                  const Text(
                    'Position',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
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