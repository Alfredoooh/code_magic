// trade_chart_view.dart - VERSÃO PROFISSIONAL COM INDICADORES E FERRAMENTAS
import 'dart:ui';
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
  final List<String> _activeIndicators = [];
  String? _activeDrawingTool;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  @override
  void didUpdateWidget(TradeChartView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_chartReady && widget.controller.entryPrice != null && 
        (oldWidget.controller.entryPrice != widget.controller.entryPrice ||
         oldWidget.controller.entryDirection != widget.controller.entryDirection)) {
      _updateEntryMarker();
    }

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

  void _toggleIndicator(String indicator) {
    if (_chartReady) {
      final isActive = _activeIndicators.contains(indicator);
      if (isActive) {
        _activeIndicators.remove(indicator);
        _webViewController.runJavaScript('removeIndicator("$indicator");');
      } else {
        _activeIndicators.add(indicator);
        _webViewController.runJavaScript('addIndicator("$indicator");');
      }
      setState(() {});
    }
  }

  void _activateDrawingTool(String tool) {
    if (_chartReady) {
      setState(() => _activeDrawingTool = tool);
      _webViewController.runJavaScript('activateDrawingTool("$tool");');
    }
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
    
    .drawing-layer {
      position: absolute;
      top: 0;
      left: 0;
      width: 100%;
      height: 100%;
      pointer-events: none;
      z-index: 50;
    }
  </style>
</head>
<body>
  <div id="chart"></div>
  <canvas id="drawingCanvas" class="drawing-layer"></canvas>
  
  <script>
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
    
    // Indicadores técnicos
    const indicators = {
      mma20: null,
      mma50: null,
      mma200: null,
      ema12: null,
      ema26: null,
      bb: null,
      rsi: null,
      macd: null
    };
    
    let entryLine = null;
    let stopLossLine = null;
    let takeProfitLine = null;
    let currentPriceLine = null;
    
    const data = [];
    const volumeData = [];
    let time = Math.floor(Date.now() / 1000) - 300;
    let basePrice = 1000 + Math.random() * 100;
    
    for (let i = 0; i < 100; i++) {
      const open = basePrice;
      const volatility = 5 + Math.random() * 5;
      const change = (Math.random() - 0.5) * volatility;
      const close = basePrice + change;
      const high = Math.max(open, close) + Math.random() * volatility * 0.5;
      const low = Math.min(open, close) - Math.random() * volatility * 0.3;
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
    
    currentPriceLine = candleSeries.createPriceLine({
      price: data[data.length - 1].close,
      color: '#0066FF',
      lineWidth: 2,
      lineStyle: LightweightCharts.LineStyle.Solid,
      axisLabelVisible: true,
      title: '',
    });
    
    chart.timeScale().fitContent();
    
    // Funções de cálculo de indicadores
    function calculateSMA(data, period) {
      const result = [];
      for (let i = period - 1; i < data.length; i++) {
        let sum = 0;
        for (let j = 0; j < period; j++) {
          sum += data[i - j].close;
        }
        result.push({
          time: data[i].time,
          value: sum / period
        });
      }
      return result;
    }
    
    function calculateEMA(data, period) {
      const result = [];
      const k = 2 / (period + 1);
      let ema = data[0].close;
      
      for (let i = 0; i < data.length; i++) {
        ema = data[i].close * k + ema * (1 - k);
        result.push({
          time: data[i].time,
          value: ema
        });
      }
      return result;
    }
    
    function calculateBollingerBands(data, period, stdDev) {
      const sma = calculateSMA(data, period);
      const upper = [];
      const lower = [];
      
      for (let i = 0; i < sma.length; i++) {
        const idx = i + period - 1;
        let sum = 0;
        for (let j = 0; j < period; j++) {
          sum += Math.pow(data[idx - j].close - sma[i].value, 2);
        }
        const std = Math.sqrt(sum / period);
        
        upper.push({
          time: sma[i].time,
          value: sma[i].value + stdDev * std
        });
        lower.push({
          time: sma[i].time,
          value: sma[i].value - stdDev * std
        });
      }
      return { upper, middle: sma, lower };
    }
    
    function calculateRSI(data, period) {
      const result = [];
      let gains = 0;
      let losses = 0;
      
      for (let i = 1; i < period; i++) {
        const change = data[i].close - data[i - 1].close;
        if (change > 0) gains += change;
        else losses -= change;
      }
      
      for (let i = period; i < data.length; i++) {
        const change = data[i].close - data[i - 1].close;
        if (change > 0) {
          gains = (gains * (period - 1) + change) / period;
          losses = (losses * (period - 1)) / period;
        } else {
          gains = (gains * (period - 1)) / period;
          losses = (losses * (period - 1) - change) / period;
        }
        
        const rs = gains / losses;
        const rsi = 100 - (100 / (1 + rs));
        
        result.push({
          time: data[i].time,
          value: rsi
        });
      }
      return result;
    }
    
    function calculateMACD(data) {
      const ema12 = calculateEMA(data, 12);
      const ema26 = calculateEMA(data, 26);
      const macdLine = [];
      
      for (let i = 0; i < Math.min(ema12.length, ema26.length); i++) {
        macdLine.push({
          time: ema12[i].time,
          value: ema12[i].value - ema26[i].value
        });
      }
      
      const signal = calculateEMA(macdLine.map((m, i) => ({
        time: m.time,
        close: m.value
      })), 9);
      
      const histogram = [];
      for (let i = 0; i < Math.min(macdLine.length, signal.length); i++) {
        histogram.push({
          time: macdLine[i].time,
          value: macdLine[i].value - signal[i].value,
          color: macdLine[i].value > signal[i].value ? 'rgba(0, 200, 150, 0.5)' : 'rgba(255, 68, 68, 0.5)'
        });
      }
      
      return { macdLine, signal, histogram };
    }
    
    // Adicionar indicadores
    function addIndicator(type) {
      switch(type) {
        case 'mma20':
          if (!indicators.mma20) {
            indicators.mma20 = chart.addLineSeries({
              color: '#2196F3',
              lineWidth: 2,
              title: 'MMA 20'
            });
            indicators.mma20.setData(calculateSMA(data, 20));
          }
          break;
        case 'mma50':
          if (!indicators.mma50) {
            indicators.mma50 = chart.addLineSeries({
              color: '#FF9800',
              lineWidth: 2,
              title: 'MMA 50'
            });
            indicators.mma50.setData(calculateSMA(data, 50));
          }
          break;
        case 'mma200':
          if (!indicators.mma200) {
            indicators.mma200 = chart.addLineSeries({
              color: '#9C27B0',
              lineWidth: 2,
              title: 'MMA 200'
            });
            indicators.mma200.setData(calculateSMA(data, 200));
          }
          break;
        case 'ema12':
          if (!indicators.ema12) {
            indicators.ema12 = chart.addLineSeries({
              color: '#00BCD4',
              lineWidth: 2,
              title: 'EMA 12'
            });
            indicators.ema12.setData(calculateEMA(data, 12));
          }
          break;
        case 'ema26':
          if (!indicators.ema26) {
            indicators.ema26 = chart.addLineSeries({
              color: '#FFEB3B',
              lineWidth: 2,
              title: 'EMA 26'
            });
            indicators.ema26.setData(calculateEMA(data, 26));
          }
          break;
        case 'bollinger':
          if (!indicators.bb) {
            const bb = calculateBollingerBands(data, 20, 2);
            indicators.bb = {
              upper: chart.addLineSeries({
                color: 'rgba(33, 150, 243, 0.5)',
                lineWidth: 1,
                title: 'BB Upper'
              }),
              middle: chart.addLineSeries({
                color: 'rgba(33, 150, 243, 0.8)',
                lineWidth: 2,
                title: 'BB Middle'
              }),
              lower: chart.addLineSeries({
                color: 'rgba(33, 150, 243, 0.5)',
                lineWidth: 1,
                title: 'BB Lower'
              })
            };
            indicators.bb.upper.setData(bb.upper);
            indicators.bb.middle.setData(bb.middle);
            indicators.bb.lower.setData(bb.lower);
          }
          break;
        case 'rsi':
          if (!indicators.rsi) {
            indicators.rsi = chart.addLineSeries({
              color: '#9C27B0',
              lineWidth: 2,
              priceScaleId: 'rsi',
              title: 'RSI'
            });
            chart.priceScale('rsi').applyOptions({
              scaleMargins: { top: 0.8, bottom: 0 }
            });
            indicators.rsi.setData(calculateRSI(data, 14));
          }
          break;
        case 'macd':
          if (!indicators.macd) {
            const macd = calculateMACD(data);
            indicators.macd = {
              macdLine: chart.addLineSeries({
                color: '#2196F3',
                lineWidth: 2,
                priceScaleId: 'macd',
                title: 'MACD'
              }),
              signal: chart.addLineSeries({
                color: '#FF9800',
                lineWidth: 2,
                priceScaleId: 'macd',
                title: 'Signal'
              }),
              histogram: chart.addHistogramSeries({
                priceScaleId: 'macd',
                title: 'Histogram'
              })
            };
            chart.priceScale('macd').applyOptions({
              scaleMargins: { top: 0.85, bottom: 0 }
            });
            indicators.macd.macdLine.setData(macd.macdLine);
            indicators.macd.signal.setData(macd.signal);
            indicators.macd.histogram.setData(macd.histogram);
          }
          break;
      }
    }
    
    function removeIndicator(type) {
      if (indicators[type]) {
        if (type === 'bb' || type === 'macd') {
          Object.values(indicators[type]).forEach(series => {
            chart.removeSeries(series);
          });
        } else {
          chart.removeSeries(indicators[type]);
        }
        indicators[type] = null;
      }
    }
    
    // Canvas de desenho para ferramentas
    const canvas = document.getElementById('drawingCanvas');
    const ctx = canvas.getContext('2d');
    canvas.width = window.innerWidth;
    canvas.height = window.innerHeight;
    
    let drawingTool = null;
    let drawings = [];
    let currentDrawing = null;
    
    function activateDrawingTool(tool) {
      drawingTool = tool;
      canvas.style.pointerEvents = tool ? 'auto' : 'none';
    }
    
    canvas.addEventListener('mousedown', (e) => {
      if (!drawingTool) return;
      currentDrawing = {
        type: drawingTool,
        startX: e.clientX,
        startY: e.clientY,
        endX: e.clientX,
        endY: e.clientY
      };
    });
    
    canvas.addEventListener('mousemove', (e) => {
      if (!currentDrawing) return;
      currentDrawing.endX = e.clientX;
      currentDrawing.endY = e.clientY;
      redrawCanvas();
    });
    
    canvas.addEventListener('mouseup', (e) => {
      if (!currentDrawing) return;
      currentDrawing.endX = e.clientX;
      currentDrawing.endY = e.clientY;
      drawings.push({...currentDrawing});
      currentDrawing = null;
      drawingTool = null;
      canvas.style.pointerEvents = 'none';
      redrawCanvas();
    });
    
    function redrawCanvas() {
      ctx.clearRect(0, 0, canvas.width, canvas.height);
      
      [...drawings, currentDrawing].filter(d => d).forEach(drawing => {
        ctx.strokeStyle = '#0066FF';
        ctx.lineWidth = 2;
        ctx.setLineDash([]);
        
        switch(drawing.type) {
          case 'line':
            ctx.beginPath();
            ctx.moveTo(drawing.startX, drawing.startY);
            ctx.lineTo(drawing.endX, drawing.endY);
            ctx.stroke();
            break;
          case 'horizontal':
            ctx.beginPath();
            ctx.moveTo(0, drawing.startY);
            ctx.lineTo(canvas.width, drawing.startY);
            ctx.stroke();
            break;
          case 'fibonacci':
            const height = drawing.endY - drawing.startY;
            const levels = [0, 0.236, 0.382, 0.5, 0.618, 0.786, 1];
            ctx.setLineDash([5, 5]);
            levels.forEach(level => {
              const y = drawing.startY + height * level;
              ctx.beginPath();
              ctx.moveTo(drawing.startX, y);
              ctx.lineTo(drawing.endX, y);
              ctx.stroke();
              ctx.fillStyle = '#0066FF';
              ctx.fillText((level * 100).toFixed(1) + '%', drawing.endX + 5, y);
            });
            break;
          case 'rectangle':
            ctx.strokeRect(
              drawing.startX,
              drawing.startY,
              drawing.endX - drawing.startX,
              drawing.endY - drawing.startY
            );
            break;
          case 'triangle':
            const midX = (drawing.startX + drawing.endX) / 2;
            ctx.beginPath();
            ctx.moveTo(midX, drawing.startY);
            ctx.lineTo(drawing.startX, drawing.endY);
            ctx.lineTo(drawing.endX, drawing.endY);
            ctx.closePath();
            ctx.stroke();
            break;
        }
      });
    }
    
    setTimeout(() => {
      FlutterChannel.postMessage(JSON.stringify({ type: 'chart_ready' }));
    }, 500);
    
    let lastPrice = data[data.length - 1].close;
    let trend = 0;
    
    setInterval(() => {
      const lastBar = data[data.length - 1];
      const newTime = lastBar.time + 3;
      
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
      
      if (currentPriceLine) {
        currentPriceLine.applyOptions({ price: close });
      }
      
      // Atualizar indicadores ativos
      Object.keys(indicators).forEach(key => {
        if (indicators[key]) {
          switch(key) {
            case 'mma20':
              indicators[key].update(calculateSMA(data.slice(-20), 20).pop());
              break;
            case 'mma50':
              if (data.length >= 50) {
                indicators[key].update(calculateSMA(data.slice(-50), 50).pop());
              }
              break;
            case 'mma200':
              if (data.length >= 200) {
                indicators[key].update(calculateSMA(data.slice(-200), 200).pop());
              }
              break;
          }
        }
      });
      
      lastPrice = close;
      
      FlutterChannel.postMessage(JSON.stringify({
        type: 'price',
        price: close,
        change: ((close - lastBar.close) / lastBar.close) * 100
      }));
      
    }, 1000);
    
    function updateTradeMarkers(entryPrice, direction, currentPrice, stopLossPercent, takeProfitPercent) {
      clearTradeMarkers();
      
      const isBuy = direction === 'buy';
      const entryColor = isBuy ? '#00C896' : '#FF4444';
      
      entryLine = candleSeries.createPriceLine({
        price: entryPrice,
        color: entryColor,
        lineWidth: 2,
        lineStyle: LightweightCharts.LineStyle.Dashed,
        axisLabelVisible: true,
        title: 'Entry: ' + entryPrice.toFixed(2),
      });
      
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
    
    window.addEventListener('resize', () => {
      chart.applyOptions({
        width: window.innerWidth,
        height: window.innerHeight
      });
      canvas.width = window.innerWidth;
      canvas.height = window.innerHeight;
      redrawCanvas();
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
            onPressed: _showIndicatorsMenu,
          ),
          const SizedBox(height: 8),
          _buildControlButton(
            icon: CupertinoIcons.pencil,
            onPressed: _showDrawingToolsMenu,
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

  void _showIndicatorsMenu() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Indicadores Técnicos'),
        message: const Text('Selecione os indicadores para exibir no gráfico'),
        actions: [
          _buildIndicatorAction('MMA 20', 'mma20'),
          _buildIndicatorAction('MMA 50', 'mma50'),
          _buildIndicatorAction('MMA 200', 'mma200'),
          _buildIndicatorAction('EMA 12', 'ema12'),
          _buildIndicatorAction('EMA 26', 'ema26'),
          _buildIndicatorAction('Bollinger Bands', 'bollinger'),
          _buildIndicatorAction('RSI', 'rsi'),
          _buildIndicatorAction('MACD', 'macd'),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          child: const Text('Fechar'),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  Widget _buildIndicatorAction(String label, String indicator) {
    final isActive = _activeIndicators.contains(indicator);
    return CupertinoActionSheetAction(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          if (isActive)
            const Icon(CupertinoIcons.check_mark, color: Color(0xFF00C896)),
        ],
      ),
      onPressed: () {
        _toggleIndicator(indicator);
        Navigator.pop(context);
      },
    );
  }

  void _showDrawingToolsMenu() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Ferramentas de Desenho'),
        message: const Text('Selecione uma ferramenta para desenhar no gráfico'),
        actions: [
          _buildDrawingToolAction('Linha de Tendência', 'line', CupertinoIcons.minus),
          _buildDrawingToolAction('Linha Horizontal', 'horizontal', CupertinoIcons.arrow_right_arrow_left),
          _buildDrawingToolAction('Fibonacci', 'fibonacci', CupertinoIcons.number),
          _buildDrawingToolAction('Retângulo', 'rectangle', CupertinoIcons.square),
          _buildDrawingToolAction('Triângulo', 'triangle', CupertinoIcons.triangle),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          child: const Text('Cancelar'),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  Widget _buildDrawingToolAction(String label, String tool, IconData icon) {
    return CupertinoActionSheetAction(
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Text(label),
        ],
      ),
      onPressed: () {
        _activateDrawingTool(tool);
        Navigator.pop(context);
      },
    );
  }
}