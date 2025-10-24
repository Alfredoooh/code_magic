// =====================================================================
// lib/deriv_chart_widget.dart
// Widget de gráfico com Chart.js embebido em WebView
// =====================================================================

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
    this.showGradient = false,
    this.height,
    this.market,
    this.onControllerCreated,
  }) : super(key: key);

  @override
  State<DerivAreaChart> createState() => _DerivAreaChartState();
}

class _DerivAreaChartState extends State<DerivAreaChart> {
  late final WebViewController _controller;
  String get _initialHtml => _buildHtml(widget.points, widget.autoScale, widget.showGradient);

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF1A1A1A))
      ..addJavaScriptChannel('FlutterChannel', onMessageReceived: (message) {})
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
    final jsArray = widget.points.map((p) => p.toString()).join(',');
    final script = "try{ updateData([${jsArray}]); }catch(e){};";
    _controller.runJavaScript(script);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height ?? 180,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: WebViewWidget(controller: _controller),
      ),
    );
  }

  String _buildHtml(List<double> points, bool autoScale, bool showGradient) {
    final initialData = points.map((p) => p.toString()).join(',');
    return '''
<!doctype html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <style>
    html, body { margin:0; padding:0; background:#0F0F0F; }
    #chart { width:100%; height:100%; }
    canvas { display:block; }
  </style>
</head>
<body>
  <canvas id="chart"></canvas>
  <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
  <script>
    const ctx = document.getElementById('chart').getContext('2d');
    Chart.defaults.font.family = 'Arial';
    Chart.defaults.color = '#FFFFFF';
    const dataPoints = [${initialData}];
    const labels = dataPoints.map((_, i) => i.toString());

    const config = {
      type: 'line',
      data: {
        labels: labels,
        datasets: [{
          label: '',
          data: dataPoints,
          fill: ${showGradient ? 'true' : 'false'},
          backgroundColor: '${showGradient ? 'rgba(0,200,150,0.12)' : 'rgba(0,0,0,0)'}',
          borderColor: dataPoints.length>1 && dataPoints[dataPoints.length-1] >= dataPoints[dataPoints.length-2] ? '#00C896' : '#FF4444',
          tension: 0.25,
          pointRadius: 0,
          borderWidth: 2,
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        animation: false,
        scales: {
          x: { display: false },
          y: {
            display: false,
            beginAtZero: ${autoScale ? 'false' : 'true'}
          }
        },
        plugins: {
          legend: { display: false },
          tooltip: { enabled: false }
        }
      }
    };

    const myChart = new Chart(ctx, config);

    function updateData(newPoints) {
      try {
        const labels = newPoints.map((_, i) => i.toString());
        myChart.data.labels = labels;
        myChart.data.datasets[0].data = newPoints;
        if (newPoints.length >= 2) {
          const last = newPoints[newPoints.length - 1];
          const prev = newPoints[newPoints.length - 2];
          myChart.data.datasets[0].borderColor = last >= prev ? '#00C896' : '#FF4444';
        }
        myChart.update();
      } catch (e) {
        console.log('updateData error', e);
      }
    }

    window.updateData = updateData;
  </script>
</body>
</html>
''';
  }
}