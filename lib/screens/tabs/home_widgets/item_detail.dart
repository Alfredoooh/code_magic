// lib/screens/item_detail.dart
import 'dart:convert';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';

class ItemDetailScreen extends StatefulWidget {
  final String symbol;
  final String display;
  final String name;
  final String iconUrl;
  final double latestPrice;
  final List<double>? sparkline;
  final String? externalLink;

  const ItemDetailScreen({
    Key? key,
    required this.symbol,
    required this.display,
    required this.name,
    required this.iconUrl,
    required this.latestPrice,
    this.sparkline,
    this.externalLink,
  }) : super(key: key);

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  List<List<num>> _klines = [];
  bool _loading = true;
  String _error = '';
  double? _smaShort;
  double? _smaLong;
  double? _emaShort;
  double? _emaLong;
  double? _rsi;
  double? _slopeValue;
  String _recommendation = 'Neutro';
  late final WebViewController _webController;
  bool _webReady = false;

  List<SignalItem> _signals = [];
  double _signalsPerDayEstimate = 0.0;

  final int _intervalMinutes = 5;

  @override
  void initState() {
    super.initState();

    _webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) {
            if (mounted) setState(() => _webReady = true);
          },
          onNavigationRequest: (nav) => NavigationDecision.navigate,
          onWebResourceError: (err) {},
        ),
      );

    _loadTradingViewHtml();
    _fetchKlinesAndCompute();
  }

  void _loadTradingViewHtml() {
    final html = _tradingViewHtml(widget.symbol, widget.display, widget.name);
    _webController.loadHtmlString(html);
  }

  Future<void> _fetchKlinesAndCompute() async {
    setState(() {
      _loading = true;
      _error = '';
      _signals = [];
      _signalsPerDayEstimate = 0.0;
    });

    try {
      final symbol = widget.symbol;
      final resp = await http.get(Uri.parse('https://api.binance.com/api/v3/klines?symbol=$symbol&interval=5m&limit=200'));
      if (resp.statusCode != 200) throw Exception('Binance returned ${resp.statusCode}');
      final List<dynamic> raw = jsonDecode(resp.body);
      if (raw.isEmpty) throw Exception('Dados insuficientes');

      _klines = raw.map<List<num>>((k) {
        final ts = k[0];
        final close = double.tryParse(k[4].toString()) ?? 0.0;
        return [ts as num, close as num];
      }).toList();

      final closes = _klines.map<double>((e) => e[1].toDouble()).toList();
      if (closes.length < 6) throw Exception('Pontos insuficientes para análise');

      _smaShort = _sma(closes, 7);
      _smaLong = _sma(closes, 25);
      _emaShort = _ema(closes, 12);
      _emaLong = _ema(closes, 26);
      _rsi = _rsiCalc(closes, 14);
      _slopeValue = _calculateSlope(closes, 12);

      _composeRecommendation();

      _signals = _detectSignals(raw, closes);
      _signalsPerDayEstimate = _estimateSignalsPerDay(_signals.length, closes.length);

      setState(() {
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  double _sma(List<double> p, int n) {
    if (p.isEmpty) return 0.0;
    final len = p.length;
    final start = max(0, len - n);
    final sub = p.sublist(start);
    final sum = sub.fold<double>(0.0, (a, b) => a + b);
    return sum / sub.length;
  }

  double _ema(List<double> p, int n) {
    if (p.isEmpty) return 0.0;
    final k = 2 / (n + 1);
    double ema = p[0];
    for (var i = 1; i < p.length; i++) {
      ema = p[i] * k + ema * (1 - k);
    }
    return ema;
  }

  double _rsiCalc(List<double> prices, int period) {
    if (prices.length <= period) return 50.0;
    double gain = 0, loss = 0;
    for (var i = prices.length - period; i < prices.length; i++) {
      final diff = prices[i] - prices[i - 1];
      if (diff >= 0) gain += diff;
      else loss += -diff;
    }
    final avgGain = gain / period;
    final avgLoss = loss / period;
    if (avgLoss == 0) return 100.0;
    final rs = avgGain / avgLoss;
    final rsi = 100 - (100 / (1 + rs));
    return rsi;
  }

  double _calculateSlope(List<double> p, int window) {
    if (p.length < window + 1) return 0.0;
    final last = p.sublist(p.length - window);
    final first = last.first;
    final lastVal = last.last;
    return (lastVal - first) / window;
  }

  void _composeRecommendation() {
    var score = 0;

    if ((_smaShort ?? 0) > (_smaLong ?? 0)) score += 1;
    else score -= 1;

    if ((_emaShort ?? 0) > (_emaLong ?? 0)) score += 1;
    else score -= 1;

    if ((_slopeValue ?? 0) > 0) score += 1;
    else score -= 1;

    if ((_rsi ?? 50) < 35) score += 1;
    if ((_rsi ?? 50) > 65) score -= 1;

    if (score >= 2) _recommendation = 'Comprar';
    else if (score <= -2) _recommendation = 'Vender';
    else _recommendation = 'Neutro';
  }

  List<SignalItem> _detectSignals(List<dynamic> rawKlines, List<double> closes) {
    final List<SignalItem> signals = [];
    final List<double> smaShortArr = _rollingSMA(closes, 7);
    final List<double> smaLongArr = _rollingSMA(closes, 25);
    final List<double> rsiArr = _rollingRsi(closes, 14);

    final count = closes.length;
    for (int i = 1; i < count; i++) {
      if (i < smaShortArr.length && i < smaLongArr.length) {
        final sPrev = smaShortArr[i - 1];
        final lPrev = smaLongArr[i - 1];
        final sCurr = smaShortArr[i];
        final lCurr = smaLongArr[i];
        if (sPrev <= lPrev && sCurr > lCurr) {
          final ts = rawKlines[i][0] as int;
          signals.add(SignalItem(ts: ts, type: SignalType.buy, reason: 'SMA crossover'));
        } else if (sPrev >= lPrev && sCurr < lCurr) {
          final ts = rawKlines[i][0] as int;
          signals.add(SignalItem(ts: ts, type: SignalType.sell, reason: 'SMA crossover'));
        }
      }

      if (i < rsiArr.length) {
        final r = rsiArr[i];
        final rPrev = rsiArr[i - 1];
        if (rPrev >= 70 && r < 70) {
          final ts = rawKlines[i][0] as int;
          signals.add(SignalItem(ts: ts, type: SignalType.sell, reason: 'RSI crossed below 70'));
        } else if (rPrev <= 30 && r > 30) {
          final ts = rawKlines[i][0] as int;
          signals.add(SignalItem(ts: ts, type: SignalType.buy, reason: 'RSI crossed above 30'));
        }
      }
    }

    signals.sort((a, b) => b.ts.compareTo(a.ts));
    return signals;
  }

  List<double> _rollingSMA(List<double> prices, int window) {
    final List<double> out = [];
    for (int i = 0; i < prices.length; i++) {
      final start = max(0, i - window + 1);
      final slice = prices.sublist(start, i + 1);
      final sum = slice.fold<double>(0.0, (a, b) => a + b);
      out.add(sum / slice.length);
    }
    return out;
  }

  List<double> _rollingRsi(List<double> prices, int period) {
    final List<double> out = [];
    for (int i = 0; i < prices.length; i++) {
      if (i == 0) {
        out.add(50.0);
        continue;
      }
      final start = max(1, i - period + 1);
      double gain = 0, loss = 0;
      for (int j = start; j <= i; j++) {
        final diff = prices[j] - prices[j - 1];
        if (diff >= 0) gain += diff;
        else loss += -diff;
      }
      final denom = (i - start + 1);
      final avgGain = denom > 0 ? gain / denom : 0;
      final avgLoss = denom > 0 ? loss / denom : 0;
      if (avgLoss == 0) out.add(100.0);
      else {
        final rs = avgGain / avgLoss;
        out.add(100 - (100 / (1 + rs)));
      }
    }
    return out;
  }

  double _estimateSignalsPerDay(int countSignals, int pointsCount) {
    if (pointsCount <= 0) return 0.0;
    final minutesCovered = pointsCount * _intervalMinutes;
    final perMinute = countSignals / minutesCovered;
    final perDay = perMinute * 60 * 24;
    return perDay;
  }

  String _tradingViewHtml(String symbol, String display, String name) {
    final tvSymbol = symbol.contains(':') ? symbol : 'BINANCE:$symbol';
    return '''
<!DOCTYPE html>
<html>
  <head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
    <style>
      * { margin: 0; padding: 0; box-sizing: border-box; }
      html, body { 
        width: 100%; 
        height: 100%; 
        background: #000; 
        overflow: hidden;
        -webkit-font-smoothing: antialiased;
        -moz-osx-font-smoothing: grayscale;
      }
      #tradingview_widget { width: 100%; height: 100%; }
    </style>
  </head>
  <body>
    <div id="tradingview_widget"></div>
    <script type="text/javascript" src="https://s3.tradingview.com/tv.js"></script>
    <script type="text/javascript">
      new TradingView.widget({
        "width": "100%",
        "height": "100%",
        "symbol": "${tvSymbol}",
        "interval": "5",
        "timezone": "Etc/UTC",
        "theme": "dark",
        "style": "1",
        "locale": "pt",
        "toolbar_bg": "#000000",
        "enable_publishing": false,
        "hide_top_toolbar": false,
        "hide_legend": false,
        "save_image": false,
        "container_id": "tradingview_widget",
        "backgroundColor": "rgba(0, 0, 0, 1)",
        "gridColor": "rgba(42, 46, 57, 0.06)",
        "hide_side_toolbar": false,
        "allow_symbol_change": false,
        "studies": [
          "MASimple@tv-basicstudies",
          "RSI@tv-basicstudies"
        ],
        "show_popup_button": false,
        "popup_width": "1000",
        "popup_height": "650"
      });
    </script>
  </body>
</html>
''';
  }

  @override
  Widget build(BuildContext context) {
    final points = widget.sparkline ?? (_klines.isNotEmpty ? _klines.map((e) => e[1].toDouble()).toList() : []);
    final analysis = _recommendation;
    final isBuy = analysis == 'Comprar';
    final isSell = analysis == 'Vender';
    final colorAnalysis = isBuy ? const Color(0xFF34C759) : isSell ? const Color(0xFFFF3B30) : const Color(0xFF8E8E93);

    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFF000000),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: const Color(0xFF000000),
        border: null,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.pop(context),
          child: const Icon(
            CupertinoIcons.back,
            color: Color(0xFF007AFF),
            size: 24,
          ),
        ),
        middle: Text(
          widget.name,
          style: const TextStyle(
            color: Color(0xFFFFFFFF),
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            // Header com preço
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    widget.iconUrl,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2C2C2E),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        CupertinoIcons.chart_bar_alt_fill,
                        color: Color(0xFF8E8E93),
                        size: 28,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.name,
                        style: const TextStyle(
                          color: Color(0xFFFFFFFF),
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.display,
                        style: const TextStyle(
                          color: Color(0xFF8E8E93),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${widget.latestPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Color(0xFFFFFFFF),
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.symbol,
                      style: const TextStyle(
                        color: Color(0xFF8E8E93),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ]),
            ),

            const SizedBox(height: 16),

            // TradingView Chart
            Container(
              height: 380,
              decoration: BoxDecoration(
                color: const Color(0xFF000000),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF2C2C2E),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(children: [
                  WebViewWidget(controller: _webController),
                  if (!_webReady)
                    Container(
                      color: const Color(0xFF000000),
                      child: const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CupertinoActivityIndicator(
                              radius: 18,
                              color: Color(0xFF007AFF),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Carregando gráfico...',
                              style: TextStyle(
                                color: Color(0xFF8E8E93),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  Positioned(
                    right: 12,
                    top: 12,
                    child: GestureDetector(
                      onTap: _loadTradingViewHtml,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C1C1E).withOpacity(0.9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFF2C2C2E),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          CupertinoIcons.refresh_thick,
                          color: Color(0xFFFFFFFF),
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ]),
              ),
            ),

            const SizedBox(height: 16),

            // Analysis Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Análise Técnica',
                    style: TextStyle(
                      color: Color(0xFFFFFFFF),
                      fontWeight: FontWeight.w700,
                      fontSize: 20,
                      letterSpacing: -0.6,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (_loading)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CupertinoActivityIndicator(
                          color: Color(0xFF007AFF),
                        ),
                      ),
                    )
                  else if (_error.isNotEmpty)
                    Column(children: [
                      Text(
                        'Erro: $_error',
                        style: const TextStyle(
                          color: Color(0xFFFF3B30),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      CupertinoButton.filled(
                        onPressed: _fetchKlinesAndCompute,
                        child: const Text('Tentar novamente'),
                      ),
                    ])
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: colorAnalysis.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: colorAnalysis.withOpacity(0.3),
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isBuy ? CupertinoIcons.arrow_up_circle_fill : 
                                  isSell ? CupertinoIcons.arrow_down_circle_fill : 
                                  CupertinoIcons.circle_fill,
                                  color: colorAnalysis,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  analysis,
                                  style: TextStyle(
                                    color: colorAnalysis,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'Sinais',
                                style: TextStyle(
                                  color: Color(0xFF8E8E93),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_signals.length}',
                                style: const TextStyle(
                                  color: Color(0xFFFFFFFF),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 22,
                                  letterSpacing: -0.5,
                                  height: 1.1,
                                ),
                              ),
                              Text(
                                '~${_signalsPerDayEstimate.toStringAsFixed(1)}/dia',
                                style: const TextStyle(
                                  color: Color(0xFF8E8E93),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ]),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _infoTile('SMA(7)', _smaShort),
                            _infoTile('SMA(25)', _smaLong),
                            _infoTile('EMA(12)', _emaShort),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _infoTile('EMA(26)', _emaLong),
                            _infoTile('RSI(14)', _rsi),
                            _infoTile('Slope', _slopeValue),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Método:',
                          style: TextStyle(
                            color: Color(0xFFFFFFFF),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '• SMA curto vs longo\n• EMA curto vs longo\n• Slope das últimas velas\n• RSI para sobrecompra/sobrevenda\n• Cruzamentos detectados como sinais',
                          style: TextStyle(
                            color: Color(0xFF8E8E93),
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Sparkline Chart
            if (points.isNotEmpty)
              Container(
                height: 140,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1C1C1E),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      getDrawingHorizontalLine: (_) => FlLine(
                        color: const Color(0xFF2C2C2E),
                        strokeWidth: 1,
                      ),
                    ),
                    titlesData: FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    minX: 0,
                    maxX: (points.length - 1).toDouble(),
                    minY: points.reduce((a, b) => a < b ? a : b),
                    maxY: points.reduce((a, b) => a > b ? a : b),
                    lineBarsData: [
                      LineChartBarData(
                        spots: points.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList(),
                        isCurved: true,
                        curveSmoothness: 0.3,
                        barWidth: 2.5,
                        dotData: FlDotData(show: false),
                        color: (points.last - points.first) >= 0 ? const Color(0xFF34C759) : const Color(0xFFFF3B30),
                        belowBarData: BarAreaData(
                          show: true,
                          color: ((points.last - points.first) >= 0 ? const Color(0xFF34C759) : const Color(0xFFFF3B30)).withOpacity(0.1),
                        ),
                      )
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Signals List
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sinais Recentes',
                    style: TextStyle(
                      color: Color(0xFFFFFFFF),
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_signals.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: Text(
                          'Nenhum sinal detectado',
                          style: TextStyle(
                            color: Color(0xFF8E8E93),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    )
                  else
                    Column(
                      children: _signals.take(8).map((s) {
                        final dt = DateTime.fromMillisecondsSinceEpoch(s.ts);
                        final label = s.type == SignalType.buy ? 'Compra' : 'Venda';
                        final color = s.type == SignalType.buy ? const Color(0xFF34C759) : const Color(0xFFFF3B30);
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2C2C2E),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  s.type == SignalType.buy ? CupertinoIcons.arrow_up : CupertinoIcons.arrow_down,
                                  color: color,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      label,
                                      style: const TextStyle(
                                        color: Color(0xFFFFFFFF),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 15,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${s.reason} • ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')} ${dt.day}/${dt.month}',
                                      style: const TextStyle(
                                        color: Color(0xFF8E8E93),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Action Buttons
            Row(children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _showNotImplemented('Comprar'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF007AFF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        'Comprar',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => _showNotImplemented('Vender'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C1E),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF2C2C2E),
                        width: 1,
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        'Vender',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ]),

            const SizedBox(height: 100),
          ]),
        ),
      ),
    );
  }

  Widget _infoTile(String title, double? value) {
    final text = value == null ? '--' : (title.startsWith('RSI') ? value.toStringAsFixed(1) : value.toStringAsFixed(2));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF8E8E93),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          text,
          style: const TextStyle(
            color: Color(0xFFFFFFFF),
            fontWeight: FontWeight.w700,
            fontSize: 15,
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  void _openExternal(String url) {
    showCupertinoDialog(
      context: context,
      builder: (c) => CupertinoAlertDialog(
        title: const Text('Abrir link externo'),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            url,
            style: const TextStyle(color: Color(0xFF8E8E93)),
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.pop(c),
          ),
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('Abrir'),
            onPressed: () {
              Navigator.pop(c);
              // Adicione url_launcher aqui se necessário
            },
          )
        ],
      ),
    );
  }

  void _showNotImplemented(String action) {
    showCupertinoDialog(
      context: context,
      builder: (c) => CupertinoAlertDialog(
        title: Text(action),
        content: const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text('Funcionalidade não implementada nesta versão.'),
        ),
        actions: [
          CupertinoDialogAction(
            isDefaultAction: true,
            child: const Text('OK'),
            onPressed: () => Navigator.pop(c),
          )
        ],
      ),
    );
  }
}

enum SignalType { buy, sell }

class SignalItem {
  final int ts;
  final SignalType type;
  final String reason;
  SignalItem({required this.ts, required this.type, required this.reason});
}
