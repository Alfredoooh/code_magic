// =====================================================================
// lib/deriv_chart_widget.dart
// Widget de gráfico avançado com Chart.js - Tick por tick com área
// =====================================================================

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'styles.dart';

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
      height: widget.height ?? 280,
      decoration: BoxDecoration(
        color: context.colors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: context.colors.outlineVariant,
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: WebViewWidget(controller: _controller),
      ),
    );
  }

  String _buildAdvancedHtml(List<double> points, bool autoScale, bool showGradient) {
    final initialData = points.map((p) => p.toString()).join(',');
    final isDark = true; // Detectar tema se necessário
    
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
      background: ${isDark ? '#1A1A1A' : '#FFFFFF'}; 
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
    #stats {
      position: absolute;
      top: 12px;
      left: 12px;
      background: ${isDark ? 'rgba(0, 0, 0, 0.7)' : 'rgba(255, 255, 255, 0.9)'};
      backdrop-filter: blur(10px);
      padding: 10px 14px;
      border-radius: 10px;
      font-size: 11px;
      color: ${isDark ? '#FFFFFF' : '#000000'};
      font-weight: 600;
      z-index: 10;
      box-shadow: 0 2px 8px rgba(0, 0, 0, 0.2);
      min-width: 140px;
    }
    .stat-row {
      display: flex;
      justify-content: space-between;
      margin-bottom: 4px;
      align-items: center;
    }
    .stat-row:last-child {
      margin-bottom: 0;
    }
    .stat-label {
      color: ${isDark ? 'rgba(255, 255, 255, 0.6)' : 'rgba(0, 0, 0, 0.6)'};
      font-weight: 500;
    }
    .stat-value {
      font-weight: 700;
      margin-left: 12px;
    }
    .stat-value.positive { color: #34C759; }
    .stat-value.negative { color: #FF3B30; }
    #tickInfo {
      position: absolute;
      bottom: 12px;
      right: 12px;
      background: ${isDark ? 'rgba(0, 0, 0, 0.7)' : 'rgba(255, 255, 255, 0.9)'};
      backdrop-filter: blur(10px);
      padding: 8px 12px;
      border-radius: 8px;
      font-size: 10px;
      color: ${isDark ? 'rgba(255, 255, 255, 0.7)' : 'rgba(0, 0, 0, 0.7)'};
      z-index: 10;
      box-shadow: 0 2px 8px rgba(0, 0, 0, 0.2);
    }
    canvas { display: block; }
  </style>
</head>
<body>
  <div id="chartContainer">
    <div id="stats">
      <div class="stat-row">
        <span class="stat-label">Preço:</span>
        <span class="stat-value" id="currentPrice">--</span>
      </div>
      <div class="stat-row">
        <span class="stat-label">Variação:</span>
        <span class="stat-value" id="priceChange">--</span>
      </div>
      <div class="stat-row">
        <span class="stat-label">Ticks:</span>
        <span class="stat-value" id="tickCount">0</span>
      </div>
    </div>
    <canvas id="chart"></canvas>
    <div id="tickInfo">
      <span id="timeInfo">Aguardando dados...</span>
    </div>
  </div>
  
  <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/chartjs-adapter-date-fns@3.0.0/dist/chartjs-adapter-date-fns.bundle.min.js"></script>
  
  <script>
    const ctx = document.getElementById('chart').getContext('2d');
    
    // Configurações de cores
    const colors = {
      background: '${isDark ? '#1A1A1A' : '#FFFFFF'}',
      text: '${isDark ? '#FFFFFF' : '#000000'}',
      grid: '${isDark ? 'rgba(255, 255, 255, 0.08)' : 'rgba(0, 0, 0, 0.08)'}',
      positive: '#34C759',
      negative: '#FF3B30',
      neutral: '${isDark ? 'rgba(255, 255, 255, 0.5)' : 'rgba(0, 0, 0, 0.5)'}',
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
    
    const config = {
      type: 'line',
      data: {
        labels: timestamps,
        datasets: [{
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
              gradient.addColorStop(0, 'rgba(52, 199, 89, 0.3)');
              gradient.addColorStop(0.5, 'rgba(52, 199, 89, 0.15)');
              gradient.addColorStop(1, 'rgba(52, 199, 89, 0.0)');
            } else {
              gradient.addColorStop(0, 'rgba(255, 59, 48, 0.3)');
              gradient.addColorStop(0.5, 'rgba(255, 59, 48, 0.15)');
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
          pointHitRadius: 10,
          pointHoverRadius: 4,
          pointHoverBackgroundColor: '#FFFFFF',
          pointHoverBorderWidth: 2,
          borderWidth: 2.5,
          segment: {
            borderColor: function(ctx) {
              const prev = ctx.p0.parsed.y;
              const curr = ctx.p1.parsed.y;
              return curr >= prev ? colors.positive : colors.negative;
            }
          }
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        animation: {
          duration: 300,
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
                weight: '500'
              },
              maxRotation: 0,
              autoSkipPadding: 20,
              padding: 8
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
                weight: '600'
              },
              padding: 8,
              callback: function(value) {
                return value.toFixed(2);
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
            backgroundColor: '${isDark ? 'rgba(0, 0, 0, 0.9)' : 'rgba(255, 255, 255, 0.95)'}',
            titleColor: colors.text,
            bodyColor: colors.text,
            borderColor: colors.grid,
            borderWidth: 1,
            padding: 12,
            displayColors: false,
            callbacks: {
              title: function(context) {
                const date = new Date(context[0].parsed.x);
                return date.toLocaleTimeString('pt-BR');
              },
              label: function(context) {
                return 'Preço: ' + context.parsed.y.toFixed(4);
              }
            }
          }
        }
      }
    };
    
    const myChart = new Chart(ctx, config);
    
    function updateStats() {
      const currentPrice = dataPoints[dataPoints.length - 1];
      const prevPrice = dataPoints.length > 1 ? dataPoints[dataPoints.length - 2] : currentPrice;
      const change = currentPrice - startPrice;
      const changePercent = startPrice !== 0 ? ((change / startPrice) * 100) : 0;
      
      document.getElementById('currentPrice').textContent = currentPrice.toFixed(4);
      
      const changeEl = document.getElementById('priceChange');
      const changeText = (change >= 0 ? '+' : '') + change.toFixed(4) + 
                        ' (' + (changePercent >= 0 ? '+' : '') + changePercent.toFixed(2) + '%)';
      changeEl.textContent = changeText;
      changeEl.className = 'stat-value ' + (change >= 0 ? 'positive' : 'negative');
      
      document.getElementById('tickCount').textContent = dataPoints.length;
      
      const now = new Date();
      document.getElementById('timeInfo').textContent = 
        'Último tick: ' + now.toLocaleTimeString('pt-BR');
    }
    
    function updateData(newPoints) {
      try {
        if (!Array.isArray(newPoints) || newPoints.length === 0) return;
        
        // Atualizar dados
        dataPoints.length = 0;
        dataPoints.push(...newPoints);
        
        // Atualizar timestamps
        timestamps.length = 0;
        newPoints.forEach((_, i) => {
          const now = new Date();
          now.setSeconds(now.getSeconds() - (newPoints.length - i));
          timestamps.push(now);
        });
        
        // Atualizar preço inicial se necessário
        if (dataPoints.length > 0 && startPrice === 0) {
          startPrice = dataPoints[0];
        }
        
        myChart.data.labels = timestamps;
        myChart.data.datasets[0].data = dataPoints;
        
        // Atualizar cor da linha
        if (dataPoints.length >= 2) {
          const last = dataPoints[dataPoints.length - 1];
          const prev = dataPoints[dataPoints.length - 2];
          myChart.data.datasets[0].borderColor = last >= prev ? colors.positive : colors.negative;
        }
        
        myChart.update('none'); // Update sem animação para melhor performance
        updateStats();
        
      } catch (e) {
        console.error('updateData error:', e);
      }
    }
    
    window.updateData = updateData;
    
    // Inicializar stats
    if (dataPoints.length > 0) {
      updateStats();
    }
  </script>
</body>
</html>
''';
  }
}