// trade_chart_view.dart - VERSÃO COM STYLES
import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'trade_logic_controller.dart';
import 'styles.dart';

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
          debugPrint('📨 Mensagem recebida do chart: ${message.message}');
          try {
            final data = json.decode(message.message);
            if (data['type'] == 'price') {
              widget.controller.updatePrice(
                (data['price'] as num).toDouble(),
                (data['change'] ?? 0.0) is num ? (data['change'] as num).toDouble() : 0.0,
              );
            } else if (data['type'] == 'chart_ready') {
              debugPrint('✅ Gráfico carregado e pronto!');
              setState(() => _chartReady = true);
              if (widget.controller.entryPrice != null) {
                _updateEntryMarker();
              }
            }
          } catch (e) {
            debugPrint('❌ Erro ao processar mensagem do chart: $e');
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            debugPrint('🌐 WebView carregada: $url');
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('❌ Erro no WebView: ${error.description}');
          },
        ),
      )
      ..loadHtmlString(_getChartHTML());
  }

  void _updateEntryMarker() {
    if (!_chartReady || widget.controller.entryPrice == null) return;

    final entry = widget.controller.entryPrice!;
    final direction = widget.controller.entryDirection ?? 'buy';
    final current = widget.controller.currentPrice;

    debugPrint('🎯 Atualizando marcador: entry=$entry, direction=$direction, current=$current');

    _webViewController.runJavaScript('''
      try {
        updateTradeMarkers(
          $entry, 
          "$direction", 
          $current,
          ${widget.controller.multiplierStopLossPercent},
          ${widget.controller.multiplierTakeProfitPercent}
        );
        console.log('✅ Marcadores atualizados com sucesso');
      } catch (error) {
        console.error('❌ Erro ao atualizar marcadores:', error);
      }
    ''');
  }

  void _clearMarkers() {
    if (!_chartReady) return;
    debugPrint('🧹 Limpando marcadores');
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
      AppHaptics.selection();
    }
  }

  void _activateDrawingTool(String tool) {
    if (_chartReady) {
      setState(() => _activeDrawingTool = tool);
      _webViewController.runJavaScript('activateDrawingTool("$tool");');
      AppHaptics.medium();
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
    console.log('🚀 Iniciando gráfico...');
    
    if (typeof FlutterChannel !== 'undefined' && FlutterChannel.postMessage) {
      console.log('✅ FlutterChannel disponível!');
    } else {
      console.warn('⚠️ FlutterChannel NÃO disponível');
    }
    
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
      priceFormat: { type: 'volume' },
      priceScaleId: '',
      scaleMargins: { top: 0.8, bottom: 0 },
    });
    
    const indicators = {
      mma20: null, mma50: null, mma200: null,
      ema12: null, ema26: null, bb: null,
      rsi: null, macd: null
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
    
    function calculateSMA(data, period) {
      const result = [];
      for (let i = period - 1; i < data.length; i++) {
        let sum = 0;
        for (let j = 0; j < period; j++) {
          sum += data[i - j].close;
        }
        result.push({ time: data[i].time, value: sum / period });
      }
      return result;
    }
    
    function calculateEMA(data, period) {
      const result = [];
      const k = 2 / (period + 1);
      let ema = data[0].close;
      
      for (let i = 0; i < data.length; i++) {
        ema = data[i].close * k + ema * (1 - k);
        result.push({ time: data[i].time, value: ema });
      }
      return result;
    }
    
    window.addIndicator = function(type) {
      switch(type) {
        case 'mma20':
          if (!indicators.mma20) {
            indicators.mma20 = chart.addLineSeries({
              color: '#2196F3', lineWidth: 2, title: 'MMA 20'
            });
            indicators.mma20.setData(calculateSMA(data, 20));
          }
          break;
        case 'mma50':
          if (!indicators.mma50) {
            indicators.mma50 = chart.addLineSeries({
              color: '#FF9800', lineWidth: 2, title: 'MMA 50'
            });
            indicators.mma50.setData(calculateSMA(data, 50));
          }
          break;
      }
    };
    
    window.removeIndicator = function(type) {
      if (indicators[type]) {
        chart.removeSeries(indicators[type]);
        indicators[type] = null;
      }
    };
    
    const canvas = document.getElementById('drawingCanvas');
    const ctx = canvas.getContext('2d');
    canvas.width = window.innerWidth;
    canvas.height = window.innerHeight;
    
    let drawingTool = null;
    
    window.activateDrawingTool = function(tool) {
      drawingTool = tool;
      canvas.style.pointerEvents = tool ? 'auto' : 'none';
    };
    
    setTimeout(() => {
      if (typeof FlutterChannel !== 'undefined' && FlutterChannel.postMessage) {
        FlutterChannel.postMessage(JSON.stringify({ type: 'chart_ready' }));
      }
    }, 500);
    
    let lastPrice = data[data.length - 1].close;
    
    setInterval(() => {
      const lastBar = data[data.length - 1];
      const newTime = lastBar.time + 3;
      const change = (Math.random() - 0.5) * 5;
      const close = lastPrice + change;
      
      const newBar = {
        time: newTime,
        open: parseFloat(lastPrice.toFixed(2)),
        high: parseFloat(Math.max(lastPrice, close).toFixed(2)),
        low: parseFloat(Math.min(lastPrice, close).toFixed(2)),
        close: parseFloat(close.toFixed(2))
      };
      
      data.push(newBar);
      if (data.length > 100) data.shift();
      
      candleSeries.update(newBar);
      if (currentPriceLine) currentPriceLine.applyOptions({ price: close });
      
      lastPrice = close;
      
      if (typeof FlutterChannel !== 'undefined' && FlutterChannel.postMessage) {
        FlutterChannel.postMessage(JSON.stringify({
          type: 'price',
          price: close,
          change: ((close - lastBar.close) / lastBar.close) * 100
        }));
      }
    }, 1000);
    
    window.updateTradeMarkers = function(entryPrice, direction, currentPrice, stopLossPercent, takeProfitPercent) {
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
    };
    
    window.clearTradeMarkers = function() {
      if (entryLine) candleSeries.removePriceLine(entryLine);
      if (stopLossLine) candleSeries.removePriceLine(stopLossLine);
      if (takeProfitLine) candleSeries.removePriceLine(takeProfitLine);
      candleSeries.setMarkers([]);
    };
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
          _buildProfitLossOverlay(context),
        if (widget.isExpanded) _buildTechnicalAnalysis(context),
        _buildChartControls(context),
        if (widget.controller.activePositions.isNotEmpty) 
          _buildPositionsOverlay(context),
      ],
    );
  }

  Widget _buildProfitLossOverlay(BuildContext context) {
    if (widget.controller.entryPrice == null) return const SizedBox.shrink();

    final entry = widget.controller.entryPrice!;
    final current = widget.controller.currentPrice;
    final isBuy = widget.controller.entryDirection == 'buy';

    final pips = (current - entry) * (isBuy ? 1 : -1);
    final plPercent = (pips / entry) * 100;
    final isProfit = pips > 0;

    return Positioned(
      top: AppSpacing.xxl * 1.5,
      left: 0,
      right: 0,
      child: Center(
        child: FadeInWidget(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl,
              vertical: AppSpacing.lg,
            ),
            decoration: BoxDecoration(
              color: (isProfit ? AppColors.success : AppColors.error)
                  .withOpacity(0.15),
              border: Border.all(
                color: isProfit ? AppColors.success : AppColors.error,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(AppRadius.xl),
              boxShadow: [AppShadows.medium],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${isProfit ? '+' : ''}${pips.toStringAsFixed(2)} pips',
                  style: context.textStyles.headlineMedium?.copyWith(
                    color: isProfit ? AppColors.success : AppColors.error,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '${isProfit ? '+' : ''}${plPercent.toStringAsFixed(2)}%',
                  style: context.textStyles.bodyLarge?.copyWith(
                    color: (isProfit ? AppColors.success : AppColors.error)
                        .withOpacity(0.8),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTechnicalAnalysis(BuildContext context) {
    return Positioned(
      left: AppSpacing.md,
      top: AppSpacing.md,
      child: FadeInWidget(
        child: GlassContainer(
          blur: 20,
          opacity: 0.7,
          padding: const EdgeInsets.all(AppSpacing.md),
          borderRadius: AppRadius.xl,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.controller.entryPrice != null) ...[
                _buildAnalysisItem(
                  context,
                  'Entry',
                  widget.controller.entryPrice!,
                  color: widget.controller.entryDirection == 'buy'
                      ? AppColors.success
                      : AppColors.error,
                ),
                const SizedBox(height: AppSpacing.xs),
              ],
              _buildAnalysisItem(
                context,
                'Current',
                widget.controller.currentPrice,
                color: AppColors.primary,
              ),
              if (widget.controller.entryPrice != null) ...[
                const SizedBox(height: AppSpacing.xs),
                _buildAnalysisItem(
                  context,
                  'P/L',
                  (widget.controller.currentPrice - widget.controller.entryPrice!) *
                      (widget.controller.entryDirection == 'buy' ? 1 : -1),
                  isPL: true,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalysisItem(
    BuildContext context,
    String label,
    double value, {
    bool isPL = false,
    Color? color,
  }) {
    Color valueColor = color ?? context.colors.onSurface;
    String prefix = '';

    if (isPL) {
      valueColor = value >= 0 ? AppColors.success : AppColors.error;
      prefix = value >= 0 ? '+' : '';
    }

    return Row(
      children: [
        Text(
          '$label: ',
          style: context.textStyles.bodySmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        Text(
          '$prefix${value.toStringAsFixed(2)}',
          style: context.textStyles.bodySmall?.copyWith(
            color: valueColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildChartControls(BuildContext context) {
    return Positioned(
      top: AppSpacing.md,
      right: AppSpacing.md,
      child: FadeInWidget(
        delay: const Duration(milliseconds: 100),
        child: Column(
          children: [
            _buildControlButton(
              context,
              icon: widget.isExpanded
                  ? CupertinoIcons.fullscreen_exit
                  : CupertinoIcons.fullscreen,
              onPressed: () {
                AppHaptics.medium();
                widget.onExpandToggle();
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildControlButton(
              context,
              icon: CupertinoIcons.chart_bar,
              onPressed: () {
                AppHaptics.light();
                _showIndicatorsMenu(context);
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            _buildControlButton(
              context,
              icon: CupertinoIcons.pencil,
              onPressed: () {
                AppHaptics.light();
                _showDrawingToolsMenu(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      minSize: 0,
      onPressed: onPressed,
      child: GlassContainer(
        blur: 20,
        opacity: 0.7,
        width: 44,
        height: 44,
        borderRadius: AppRadius.md,
        child: Icon(
          icon,
          color: context.colors.onSurface,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildPositionsOverlay(BuildContext context) {
    return Positioned(
      bottom: AppSpacing.md,
      left: AppSpacing.md,
      right: AppSpacing.md,
      child: FadeInWidget(
        child: GlassContainer(
          blur: 30,
          opacity: 0.85,
          padding: const EdgeInsets.all(AppSpacing.md),
          borderRadius: AppRadius.xl,
          child: Column(
            children: widget.controller.activePositions.map<Widget>((pos) {
              final profit = (pos['profit'] as num?)?.toDouble() ?? 0.0;
              final isProfit = profit >= 0;
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Position',
                      style: context.textStyles.bodyMedium?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '${isProfit ? '+' : ''}\$${profit.toStringAsFixed(2)}',
                      style: context.textStyles.bodyLarge?.copyWith(
                        color: isProfit ? AppColors.success : AppColors.error,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _showIndicatorsMenu(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(
          'Indicadores Técnicos',
          style: context.textStyles.titleLarge,
        ),
        message: Text(
          'Selecione os indicadores para exibir no gráfico',
          style: context.textStyles.bodyMedium,
        ),
        actions: [
          _buildIndicatorAction(context, 'MMA 20', 'mma20'),
          _buildIndicatorAction(context, 'MMA 50', 'mma50'),
          _buildIndicatorAction(context, 'MMA 200', 'mma200'),
          _buildIndicatorAction(context, 'EMA 12', 'ema12'),
          _buildIndicatorAction(context, 'EMA 26', 'ema26'),
          _buildIndicatorAction(context, 'Bollinger Bands', 'bollinger'),
          _buildIndicatorAction(context, 'RSI', 'rsi'),
          _buildIndicatorAction(context, 'MACD', 'macd'),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          child: const Text('Fechar'),
          onPressed: () {
            AppHaptics.light();
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  Widget _buildIndicatorAction(
    BuildContext context,
    String label,
    String indicator,
  ) {
    final isActive = _activeIndicators.contains(indicator);
    return CupertinoActionSheetAction(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          if (isActive)
            const Icon(
              CupertinoIcons.check_mark,
              color: AppColors.success,
            ),
        ],
      ),
      onPressed: () {
        _toggleIndicator(indicator);
        Navigator.pop(context);
      },
    );
  }

  void _showDrawingToolsMenu(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text(
          'Ferramentas de Desenho',
          style: context.textStyles.titleLarge,
        ),
        message: Text(
          'Selecione uma ferramenta para desenhar no gráfico',
          style: context.textStyles.bodyMedium,
        ),
        actions: [
          _buildDrawingToolAction(
            context,
            'Linha de Tendência',
            'line',
            CupertinoIcons.minus,
          ),
          _buildDrawingToolAction(
            context,
            'Linha Horizontal',
            'horizontal',
            CupertinoIcons.arrow_right_arrow_left,
          ),
          _buildDrawingToolAction(
            context,
            'Fibonacci',
            'fibonacci',
            CupertinoIcons.number,
          ),
          _buildDrawingToolAction(
            context,
            'Retângulo',
            'rectangle',
            CupertinoIcons.square,
          ),
          _buildDrawingToolAction(
            context,
            'Triângulo',
            'triangle',
            CupertinoIcons.triangle,
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          child: const Text('Cancelar'),
          onPressed: () {
            AppHaptics.light();
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  Widget _buildDrawingToolAction(
    BuildContext context,
    String label,
    String tool,
    IconData icon,
  ) {
    return CupertinoActionSheetAction(
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: AppSpacing.md),
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