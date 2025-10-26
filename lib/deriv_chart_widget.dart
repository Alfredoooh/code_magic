// =====================================================================
// lib/deriv_chart_widget.dart
// Widget de gráfico ultra avançado com Chart.js - Análise técnica completa
// =====================================================================

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'styles.dart' hide EdgeInsets;

class DerivAreaChart extends StatefulWidget {
  final List<double> points;
  final bool autoScale;
  final bool showGradient;
  final double? height;
  final String? market;
  final void Function(WebViewController controller, String? market)? onControllerCreated;

  const DerivAreaChart({
    Key? key,
    required this.points,
    this.autoScale = true,
    this.showGradient = true,
    this.height,
    this.market,
    this.onControllerCreated,
  }) : super(key: key);

  @override
  State<DerivAreaChart> createState() => _DerivAreaChartState();
}

class _DerivAreaChartState extends State<DerivAreaChart> {
  late final WebViewController _controller;
  String get _initialHtml => _buildAdvancedHtml(widget.points, widget.autoScale, widget.showGradient);

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..addJavaScriptChannel('FlutterChannel', onMessageReceived: (message) {
        debugPrint('Chart message: ${message.message}');
      })
      ..loadHtmlString(_initialHtml);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.onControllerCreated != null) {
        widget.onControllerCreated!(_controller, widget.market);
      }
    });
  }

  @override
  void didUpdateWidget(covariant DerivAreaChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.points != oldWidget.points) {
      final jsArray = widget.points.map((p) => p.toString()).join(',');
      final script = "try{ updateData([${jsArray}]); }catch(e){ console.log('Update error:', e); };";
      _controller.runJavaScript(script);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height ?? 320,
      decoration: BoxDecoration(
        color: context.colors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppShapes.large),
        border: Border.all(
          color: context.colors.outlineVariant,
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppShapes.large),
        child: WebViewWidget(controller: _controller),
      ),
    );
  }

  String _buildAdvancedHtml(List<double> points, bool autoScale, bool showGradient) {
    final initialData = points.map((p) => p.toString()).join(',');
    final isDark = true;

    return '''
<!doctype html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    html, body { 
      width: 100%; 
      height: 100%; 
      background: ${isDark ? '#0A0A0A' : '#FFFFFF'}; 
      overflow: hidden;
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
    }
    #chartContainer { 
      width: 100%; 
      height: 100%; 
      position: relative;
    }
    #chart { 
      width: 100%; 
      height: 100%; 
    }
    
    /* Stats Panel - Redesenhado */
    #stats {
      position: absolute;
      top: 16px;
      left: 16px;
      background: ${isDark ? 'rgba(10, 10, 10, 0.85)' : 'rgba(255, 255, 255, 0.95)'};
      backdrop-filter: blur(20px) saturate(180%);
      padding: 12px 16px;
      border-radius: 14px;
      font-size: 11px;
      color: ${isDark ? '#FFFFFF' : '#000000'};
      font-weight: 600;
      z-index: 100;
      box-shadow: 0 8px 32px rgba(0, 0, 0, 0.4), 
                  0 2px 8px rgba(0, 0, 0, 0.2),
                  inset 0 1px 0 rgba(255, 255, 255, 0.1);
      border: 1px solid ${isDark ? 'rgba(255, 255, 255, 0.1)' : 'rgba(0, 0, 0, 0.05)'};
      min-width: 180px;
      transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
    }
    #stats:hover {
      transform: scale(1.02);
      box-shadow: 0 12px 48px rgba(0, 0, 0, 0.5);
    }
    .stat-row {
      display: flex;
      justify-content: space-between;
      margin-bottom: 8px;
      align-items: center;
      padding: 4px 0;
    }
    .stat-row:last-child {
      margin-bottom: 0;
    }
    .stat-label {
      color: ${isDark ? 'rgba(255, 255, 255, 0.6)' : 'rgba(0, 0, 0, 0.6)'};
      font-weight: 500;
      font-size: 10px;
      text-transform: uppercase;
      letter-spacing: 0.5px;
    }
    .stat-value {
      font-weight: 700;
      margin-left: 16px;
      font-size: 13px;
      font-variant-numeric: tabular-nums;
    }
    .stat-value.positive { 
      color: #34C759;
      text-shadow: 0 0 8px rgba(52, 199, 89, 0.3);
    }
    .stat-value.negative { 
      color: #FF3B30;
      text-shadow: 0 0 8px rgba(255, 59, 48, 0.3);
    }
    
    /* Indicators Panel */
    #indicators {
      position: absolute;
      top: 16px;
      right: 16px;
      background: ${isDark ? 'rgba(10, 10, 10, 0.85)' : 'rgba(255, 255, 255, 0.95)'};
      backdrop-filter: blur(20px) saturate(180%);
      padding: 12px 16px;
      border-radius: 14px;
      font-size: 10px;
      color: ${isDark ? '#FFFFFF' : '#000000'};
      z-index: 100;
      box-shadow: 0 8px 32px rgba(0, 0, 0, 0.4);
      border: 1px solid ${isDark ? 'rgba(255, 255, 255, 0.1)' : 'rgba(0, 0, 0, 0.05)'};
      min-width: 140px;
    }
    .indicator-row {
      display: flex;
      justify-content: space-between;
      margin-bottom: 6px;
      align-items: center;
    }
    .indicator-row:last-child { margin-bottom: 0; }
    .indicator-label {
      color: ${isDark ? 'rgba(255, 255, 255, 0.5)' : 'rgba(0, 0, 0, 0.5)'};
      font-weight: 500;
      font-size: 9px;
      text-transform: uppercase;
      letter-spacing: 0.5px;
    }
    .indicator-value {
      font-weight: 700;
      font-size: 11px;
      margin-left: 8px;
    }
    
    /* Tick Info */
    #tickInfo {
      position: absolute;
      bottom: 16px;
      right: 16px;
      background: ${isDark ? 'rgba(10, 10, 10, 0.85)' : 'rgba(255, 255, 255, 0.95)'};
      backdrop-filter: blur(20px) saturate(180%);
      padding: 10px 14px;
      border-radius: 10px;
      font-size: 10px;
      color: ${isDark ? 'rgba(255, 255, 255, 0.7)' : 'rgba(0, 0, 0, 0.7)'};
      z-index: 100;
      box-shadow: 0 4px 16px rgba(0, 0, 0, 0.3);
      border: 1px solid ${isDark ? 'rgba(255, 255, 255, 0.08)' : 'rgba(0, 0, 0, 0.05)'};
      font-weight: 600;
    }
    
    /* Signal Badge */
    #signal {
      position: absolute;
      bottom: 16px;
      left: 16px;
      padding: 10px 16px;
      border-radius: 10px;
      font-size: 11px;
      font-weight: 700;
      z-index: 100;
      display: flex;
      align-items: center;
      gap: 8px;
      box-shadow: 0 4px 16px rgba(0, 0, 0, 0.3);
      transition: all 0.3s ease;
    }
    #signal.bullish {
      background: linear-gradient(135deg, rgba(52, 199, 89, 0.2), rgba(52, 199, 89, 0.1));
      color: #34C759;
      border: 1px solid rgba(52, 199, 89, 0.3);
    }
    #signal.bearish {
      background: linear-gradient(135deg, rgba(255, 59, 48, 0.2), rgba(255, 59, 48, 0.1));
      color: #FF3B30;
      border: 1px solid rgba(255, 59, 48, 0.3);
    }
    #signal.neutral {
      background: linear-gradient(135deg, rgba(255, 204, 0, 0.2), rgba(255, 204, 0, 0.1));
      color: #FFCC00;
      border: 1px solid rgba(255, 204, 0, 0.3);
    }
    .signal-icon {
      width: 8px;
      height: 8px;
      border-radius: 50%;
      animation: pulse 2s ease-in-out infinite;
    }
    @keyframes pulse {
      0%, 100% { opacity: 1; transform: scale(1); }
      50% { opacity: 0.5; transform: scale(1.2); }
    }
    
    canvas { display: block; }
  </style>
</head>
<body>
  <div id="chartContainer">
    <!-- Stats Panel -->
    <div id="stats">
      <div class="stat-row">
        <span class="stat-label">Preço</span>
        <span class="stat-value" id="currentPrice">--</span>
      </div>
      <div class="stat-row">
        <span class="stat-label">Variação</span>
        <span class="stat-value" id="priceChange">--</span>
      </div>
      <div class="stat-row">
        <span class="stat-label">Volatilidade</span>
        <span class="stat-value" id="volatility">--</span>
      </div>
      <div class="stat-row">
        <span class="stat-label">Ticks</span>
        <span class="stat-value" id="tickCount">0</span>
      </div>
    </div>
    
    <!-- Technical Indicators -->
    <div id="indicators">
      <div class="indicator-row">
        <span class="indicator-label">RSI</span>
        <span class="indicator-value" id="rsi">--</span>
      </div>
      <div class="indicator-row">
        <span class="indicator-label">MA(20)</span>
        <span class="indicator-value" id="ma20">--</span>
      </div>
      <div class="indicator-row">
        <span class="indicator-label">Bollinger</span>
        <span class="indicator-value" id="bbands">--</span>
      </div>
      <div class="indicator-row">
        <span class="indicator-label">Trend</span>
        <span class="indicator-value" id="trend">--</span>
      </div>
    </div>
    
    <!-- Chart Canvas -->
    <canvas id="chart"></canvas>
    
    <!-- Signal Badge -->
    <div id="signal" class="neutral">
      <span class="signal-icon"></span>
      <span id="signalText">AGUARDANDO</span>
    </div>
    
    <!-- Tick Info -->
    <div id="tickInfo">
      <span id="timeInfo">Aguardando dados...</span>
    </div>
  </div>
  
  <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/chartjs-adapter-date-fns@3.0.0/dist/chartjs-adapter-date-fns.bundle.min.js"></script>
  
  <script>
    const ctx = document.getElementById('chart').getContext('2d');
    
    const colors = {
      background: '${isDark ? '#0A0A0A' : '#FFFFFF'}',
      text: '${isDark ? '#FFFFFF' : '#000000'}',
      grid: '${isDark ? 'rgba(255, 255, 255, 0.05)' : 'rgba(0, 0, 0, 0.05)'}',
      positive: '#34C759',
      negative: '#FF3B30',
      neutral: '${isDark ? 'rgba(255, 255, 255, 0.4)' : 'rgba(0, 0, 0, 0.4)'}',
      ma: '#007AFF',
      bb: '#FF9500',
    };
    
    Chart.defaults.font.family = '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto';
    Chart.defaults.color = colors.text;
    
    const dataPoints = [${initialData}];
    const timestamps = dataPoints.map((_, i) => {
      const now = new Date();
      now.setSeconds(now.getSeconds() - (dataPoints.length - i));
      return now;
    });
    
    let startPrice = dataPoints.length > 0 ? dataPoints[0] : 0;
    let ma20Data = [];
    let upperBand = [];
    let lowerBand = [];
    
    // Calcular Moving Average
    function calculateMA(data, period) {
      const result = [];
      for (let i = 0; i < data.length; i++) {
        if (i < period - 1) {
          result.push(null);
        } else {
          const sum = data.slice(i - period + 1, i + 1).reduce((a, b) => a + b, 0);
          result.push(sum / period);
        }
      }
      return result;
    }
    
    // Calcular Bollinger Bands
    function calculateBollingerBands(data, period = 20, stdDev = 2) {
      const ma = calculateMA(data, period);
      const upper = [];
      const lower = [];
      
      for (let i = 0; i < data.length; i++) {
        if (i < period - 1) {
          upper.push(null);
          lower.push(null);
        } else {
          const slice = data.slice(i - period + 1, i + 1);
          const mean = ma[i];
          const variance = slice.reduce((sum, val) => sum + Math.pow(val - mean, 2), 0) / period;
          const std = Math.sqrt(variance);
          upper.push(mean + (stdDev * std));
          lower.push(mean - (stdDev * std));
        }
      }
      return { upper, lower };
    }
    
    // Calcular RSI
    function calculateRSI(data, period = 14) {
      if (data.length < period + 1) return 50;
      
      let gains = 0;
      let losses = 0;
      
      for (let i = data.length - period; i < data.length; i++) {
        const change = data[i] - data[i - 1];
        if (change > 0) gains += change;
        else losses -= change;
      }
      
      const avgGain = gains / period;
      const avgLoss = losses / period;
      
      if (avgLoss === 0) return 100;
      const rs = avgGain / avgLoss;
      return 100 - (100 / (1 + rs));
    }
    
    // Calcular Volatilidade
    function calculateVolatility(data, period = 10) {
      if (data.length < period) return 0;
      const slice = data.slice(-period);
      const mean = slice.reduce((a, b) => a + b, 0) / period;
      const variance = slice.reduce((sum, val) => sum + Math.pow(val - mean, 2), 0) / period;
      return Math.sqrt(variance);
    }
    
    // Inicializar indicadores
    ma20Data = calculateMA(dataPoints, 20);
    const bands = calculateBollingerBands(dataPoints);
    upperBand = bands.upper;
    lowerBand = bands.lower;
    
    const config = {
      type: 'line',
      data: {
        labels: timestamps,
        datasets: [
          {
            label: 'Preço',
            data: dataPoints,
            fill: true,
            backgroundColor: function(context) {
              const chart = context.chart;
              const {ctx, chartArea} = chart;
              if (!chartArea) return null;
              
              const gradient = ctx.createLinearGradient(0, chartArea.top, 0, chartArea.bottom);
              const isPositive = dataPoints.length > 1 && 
                dataPoints[dataPoints.length - 1] >= dataPoints[dataPoints.length - 2];
              
              if (isPositive) {
                gradient.addColorStop(0, 'rgba(52, 199, 89, 0.4)');
                gradient.addColorStop(0.5, 'rgba(52, 199, 89, 0.2)');
                gradient.addColorStop(1, 'rgba(52, 199, 89, 0.0)');
              } else {
                gradient.addColorStop(0, 'rgba(255, 59, 48, 0.4)');
                gradient.addColorStop(0.5, 'rgba(255, 59, 48, 0.2)');
                gradient.addColorStop(1, 'rgba(255, 59, 48, 0.0)');
              }
              return gradient;
            },
            borderColor: function(context) {
              if (dataPoints.length < 2) return colors.neutral;
              const isPositive = dataPoints[dataPoints.length - 1] >= dataPoints[dataPoints.length - 2];
              return isPositive ? colors.positive : colors.negative;
            },
            tension: 0.4,
            pointRadius: 0,
            pointHitRadius: 12,
            pointHoverRadius: 5,
            pointHoverBackgroundColor: '#FFFFFF',
            pointHoverBorderWidth: 3,
            borderWidth: 3,
            order: 1
          },
          {
            label: 'MA(20)',
            data: ma20Data,
            borderColor: colors.ma,
            borderWidth: 2,
            borderDash: [5, 5],
            fill: false,
            pointRadius: 0,
            tension: 0.4,
            order: 2
          },
          {
            label: 'BB Upper',
            data: upperBand,
            borderColor: colors.bb,
            borderWidth: 1,
            borderDash: [3, 3],
            fill: false,
            pointRadius: 0,
            tension: 0.4,
            order: 3
          },
          {
            label: 'BB Lower',
            data: lowerBand,
            borderColor: colors.bb,
            borderWidth: 1,
            borderDash: [3, 3],
            fill: '-1',
            backgroundColor: 'rgba(255, 149, 0, 0.05)',
            pointRadius: 0,
            tension: 0.4,
            order: 3
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        animation: {
          duration: 250,
          easing: 'easeInOutCubic'
        },
        interaction: {
          intersect: false,
          mode: 'index'
        },
        scales: {
          x: {
            type: 'time',
            time: {
              unit: 'second',
              displayFormats: {
                second: 'HH:mm:ss'
              },
              tooltipFormat: 'HH:mm:ss'
            },
            grid: {
              color: colors.grid,
              drawTicks: false,
            },
            ticks: {
              color: colors.neutral,
              font: {
                size: 10,
                weight: '600'
              },
              maxRotation: 0,
              autoSkipPadding: 20,
              padding: 10
            },
            border: {
              display: false
            }
          },
          y: {
            position: 'right',
            beginAtZero: false,
            grid: {
              color: colors.grid,
              drawTicks: false,
            },
            ticks: {
              color: colors.neutral,
              font: {
                size: 10,
                weight: '700'
              },
              padding: 10,
              callback: function(value) {
                return value.toFixed(3);
              }
            },
            border: {
              display: false
            }
          }
        },
        plugins: {
          legend: { 
            display: false 
          },
          tooltip: {
            enabled: true,
            backgroundColor: '${isDark ? 'rgba(0, 0, 0, 0.95)' : 'rgba(255, 255, 255, 0.98)'}',
            titleColor: colors.text,
            bodyColor: colors.text,
            borderColor: colors.grid,
            borderWidth: 1,
            padding: 14,
            displayColors: true,
            callbacks: {
              title: function(context) {
                const date = new Date(context[0].parsed.x);
                return date.toLocaleTimeString('pt-BR');
              },
              label: function(context) {
                return context.dataset.label + ': ' + context.parsed.y.toFixed(4);
              }
            }
          }
        }
      }
    };
    
    const myChart = new Chart(ctx, config);
    
    function updateStats() {
      const currentPrice = dataPoints[dataPoints.length - 1];
      const change = currentPrice - startPrice;
      const changePercent = startPrice !== 0 ? ((change / startPrice) * 100) : 0;
      const volatility = calculateVolatility(dataPoints);
      const rsi = calculateRSI(dataPoints);
      
      // Update price
      document.getElementById('currentPrice').textContent = currentPrice.toFixed(4);
      
      // Update change
      const changeEl = document.getElementById('priceChange');
      const changeText = (change >= 0 ? '+' : '') + change.toFixed(4) + 
                        ' (' + (changePercent >= 0 ? '+' : '') + changePercent.toFixed(2) + '%)';
      changeEl.textContent = changeText;
      changeEl.className = 'stat-value ' + (change >= 0 ? 'positive' : 'negative');
      
      // Update volatility
      const volEl = document.getElementById('volatility');
      volEl.textContent = (volatility * 100).toFixed(2) + '%';
      volEl.className = 'stat-value ' + (volatility > 0.02 ? 'negative' : 'positive');
      
      // Update tick count
      document.getElementById('tickCount').textContent = dataPoints.length;
      
      // Update RSI
      const rsiEl = document.getElementById('rsi');
      rsiEl.textContent = rsi.toFixed(1);
      rsiEl.style.color = rsi > 70 ? colors.negative : rsi < 30 ? colors.positive : colors.neutral;
      
      // Update MA
      const ma20Val = ma20Data[ma20Data.length - 1];
      if (ma20Val) {
        document.getElementById('ma20').textContent = ma20Val.toFixed(4);
      }
      
      // Update Bollinger
      const upperVal = upperBand[upperBand.length - 1];
      const lowerVal = lowerBand[lowerBand.length - 1];
      if (upperVal && lowerVal) {
        const bbPos = ((currentPrice - lowerVal) / (upperVal - lowerVal) * 100).toFixed(0);
        document.getElementById('bbands').textContent = bbPos + '%';
      }
      
      // Update Trend
      const trendEl = document.getElementById('trend');
      if (dataPoints.length >= 5) {
        const recent = dataPoints.slice(-5);
        const isUptrend = recent[recent.length - 1] > recent[0];
        trendEl.textContent = isUptrend ? '↗ UP' : '↘ DOWN';
        trendEl.style.color = isUptrend ? colors.positive : colors.negative;
      }
      
      // Update Signal
      updateSignal(rsi, currentPrice, ma20Val);
      
      // Update time
      const now = new Date();
      document.getElementById('timeInfo').textContent = 
        'Último tick: ' + now.toLocaleTimeString('pt-BR');
    }
    
    function updateSignal(rsi, price, ma) {
      const signalEl = document.getElementById('signal');
      const signalText = document.getElementById('signalText');
      const signalIcon = signalEl.querySelector('.signal-icon');
      
      let signal = 'neutral';
      let text = 'AGUARDANDO';
      
      if (rsi < 30 && price < ma) {
        signal = 'bullish';
        text = '🚀 COMPRA FORTE';
      } else if (rsi > 70 && price > ma) {
        signal = 'bearish';
        text = '📉 VENDA FORTE';
      } else if (rsi < 40) {
        signal = 'bullish';
        text = '📈 COMPRA';
      } else if (rsi > 60) {
        signal = 'bearish';
        text = '📉 VENDA';
      }
      
      signalEl.className = signal;
      signalText.textContent = text;
      signalIcon.style.backgroundColor = 
        signal === 'bullish' ? colors.positive : 
        signal === 'bearish' ? colors.negative : '#FFCC00';
    }
    
    function updateData(newPoints) {
      try {
        if (!Array.isArray(newPoints) || newPoints.length === 0) return;
        
        dataPoints.length = 0;
        dataPoints.push(...newPoints);
        
        timestamps.length = 0;
        newPoints.forEach((_, i) => {
          const now = new Date();
          now.setSeconds(now.getSeconds() - (newPoints.length - i));
          timestamps.push(now);
        });
        
        if (dataPoints.length > 0 && startPrice === 0) {
          startPrice = dataPoints[0];
        }
        
        // Recalcular indicadores
        ma20Data = calculateMA(dataPoints, 20);
        const bands = calculateBollingerBands(dataPoints);
        upperBand = bands.upper;
        lowerBand = bands.lower;
        
        myChart.data.labels = timestamps;
        myChart.data.datasets[0].data = dataPoints;
        myChart.data.datasets[1].data = ma20Data;
        myChart.data.datasets[2].data = upperBand;
        myChart.data.datasets[3].data = lowerBand;
        
        if (dataPoints.length >= 2) {
          const last = dataPoints[dataPoints.length - 1];
          const prev = dataPoints[dataPoints.length - 2];
          myChart.data.datasets[0].borderColor = last >= prev ? colors.positive : colors.negative;
        }
        
        myChart.update('none');
        updateStats();
        
      } catch (e) {
        console.error('updateData error:', e);
      }
    }
    
    window.updateData = updateData;
    
    if (dataPoints.length > 0) {
      updateStats();
    }
  </script>
</body>
</html>
''';
  }
}