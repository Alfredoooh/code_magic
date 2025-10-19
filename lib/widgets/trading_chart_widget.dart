// lib/widgets/trading_chart_widget.dart
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// TradingChartWidget
/// - symbol: símbolo exibido
/// - tradeHistory: lista de trades (cada trade deve ter: 'entryTick' (price), 'exitTick' (price), 'status', 'timestamp')
/// - tickStream: opcional Stream de ticks (num ou Map com ['quote'])
/// - margins: opcional lista de níveis de preço para desenhar como margens/horizontal lines
/// - candleTicks: número de ticks para agregar 1 candle (default 5)
/// - enablePatterns: se true, detecta padrões simples
class TradingChartWidget extends StatefulWidget {
  final String symbol;
  final List<Map<String, dynamic>> tradeHistory;
  final Stream<dynamic>? tickStream;
  final List<double>? margins;
  final int candleTicks;
  final bool enablePatterns;
  final double height;

  const TradingChartWidget({
    Key? key,
    required this.symbol,
    required this.tradeHistory,
    this.tickStream,
    this.margins,
    this.candleTicks = 5,
    this.enablePatterns = true,
    this.height = 320,
  }) : super(key: key);

  @override
  _TradingChartWidgetState createState() => _TradingChartWidgetState();
}

class Candle {
  final DateTime ts;
  double open;
  double high;
  double low;
  double close;

  Candle({
    required this.ts,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
  });
}

class _TradingChartWidgetState extends State<TradingChartWidget>
    with SingleTickerProviderStateMixin {
  // live price list used for line chart
  final List<double> _priceData = [];

  // candle aggregation
  final List<Candle> _candles = [];
  int _ticksForCurrentCandle = 0;

  // animation/pulse
  late AnimationController _animationController;
  Timer? _simTimer;
  StreamSubscription? _tickSub;

  // last price
  double _currentPrice = 0.0;
  double _priceChange = 0.0;
  bool _isRising = true;

  // UI state
  bool _showCandles = false;
  bool _showMargins = true;

  // pattern detection results: map candle index -> pattern name
  final Map<int, String> _patterns = {};

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 900),
    )..repeat();

    // iniciar com dados simulados
    _initSimulatedData();

    // conectar stream se fornecido
    if (widget.tickStream != null) {
      _tickSub = widget.tickStream!.listen(_handleTickFromStream, onError: (_) {});
    } else {
      // fallback: simula ticks a cada 500ms
      _simTimer = Timer.periodic(Duration(milliseconds: 500), (_) => _generateSimulatedTick());
    }
  }

  @override
  void didUpdateWidget(covariant TradingChartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // se trocar de stream, remapear subscrição
    if (oldWidget.tickStream != widget.tickStream) {
      _tickSub?.cancel();
      _simTimer?.cancel();
      if (widget.tickStream != null) {
        _tickSub = widget.tickStream!.listen(_handleTickFromStream, onError: (_) {});
      } else {
        _simTimer = Timer.periodic(Duration(milliseconds: 500), (_) => _generateSimulatedTick());
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _tickSub?.cancel();
    _simTimer?.cancel();
    super.dispose();
  }

  void _initSimulatedData() {
    final rnd = math.Random();
    double base = 100.0 + rnd.nextDouble() * 100;
    _priceData.clear();
    for (int i = 0; i < 60; i++) {
      final v = base + (rnd.nextDouble() - 0.5) * 6;
      _priceData.add(v);
    }
    _currentPrice = _priceData.last;
    // criar 12 candles de exemplo
    _candles.clear();
    for (int i = 0; i < 12; i++) {
      final open = base + (rnd.nextDouble() - 0.5) * 8;
      final close = open + (rnd.nextDouble() - 0.5) * 6;
      final high = math.max(open, close) + rnd.nextDouble() * 3;
      final low = math.min(open, close) - rnd.nextDouble() * 3;
      _candles.add(Candle(ts: DateTime.now().subtract(Duration(minutes: 12 - i)), open: open, high: high, low: low, close: close));
    }
  }

  void _handleTickFromStream(dynamic tick) {
    // tick could be num or Map with 'quote'
    double? price;
    if (tick == null) return;
    if (tick is num) {
      price = tick.toDouble();
    } else if (tick is Map) {
      // common Deriv tick map could be {'quote': 123.45, 'epoch':...}
      final q = tick['quote'] ?? tick['price'] ?? tick['p'];
      if (q is num) price = q.toDouble();
    }
    if (price == null) return;
    _processNewPrice(price);
  }

  void _generateSimulatedTick() {
    final rnd = math.Random();
    final change = (rnd.nextDouble() - 0.48) * 1.2; // small drift
    final newPrice = (_currentPrice == 0.0 ? (_priceData.isNotEmpty ? _priceData.last : 100.0) : _currentPrice) + change;
    _processNewPrice(newPrice);
  }

  void _processNewPrice(double price) {
    if (!mounted) return;
    setState(() {
      final old = _currentPrice;
      if (old == 0.0) _currentPrice = price;
      _priceChange = price - _currentPrice;
      _isRising = _priceChange >= 0;
      _currentPrice = price;

      // update price series
      _priceData.add(price);
      if (_priceData.length > 240) _priceData.removeAt(0); // keep window

      // aggregate candles by number of ticks
      _ticksForCurrentCandle++;
      if (_candles.isEmpty) {
        // create initial candle
        _candles.add(Candle(ts: DateTime.now(), open: price, high: price, low: price, close: price));
      } else {
        Candle current = _candles.last;
        current.high = math.max(current.high, price);
        current.low = math.min(current.low, price);
        current.close = price;
        // every widget.candleTicks ticks, finalize and start new candle
      }
      if (_ticksForCurrentCandle >= widget.candleTicks) {
        _ticksForCurrentCandle = 0;
        // finalize current candle timestamp to now
        final last = _candles.isNotEmpty ? _candles.last : Candle(ts: DateTime.now(), open: price, high: price, low: price, close: price);
        // push a new empty candle (open = close of last)
        final newCandle = Candle(ts: DateTime.now(), open: last.close, high: last.close, low: last.close, close: last.close);
        _candles.add(newCandle);
        if (_candles.length > 200) _candles.removeAt(0);
        // detect patterns on the rolling set
        if (widget.enablePatterns) _detectPatterns();
      }
    });
  }

  void _detectPatterns() {
    // detect simple patterns on the last candles and store in _patterns map
    // we'll check last 3 candles for Bullish Engulfing and Hammer on last candle
    _patterns.clear();
    final n = _candles.length;
    if (n < 2) return;

    // Bullish Engulfing: previous candle is bearish and last candle bullish and engulfs previous body
    final prev = _candles[n - 2];
    final last = _candles[n - 1];

    bool prevBear = prev.close < prev.open;
    bool lastBull = last.close > last.open;
    final prevBodyLow = math.min(prev.open, prev.close);
    final prevBodyHigh = math.max(prev.open, prev.close);
    final lastBodyLow = math.min(last.open, last.close);
    final lastBodyHigh = math.max(last.open, last.close);

    if (prevBear && lastBull && lastBodyLow <= prevBodyLow && lastBodyHigh >= prevBodyHigh) {
      _patterns[n - 1] = 'Bullish Engulfing';
    }

    // Hammer: small body near top, long lower wick
    final body = (last.close - last.open).abs();
    final lowerWick = math.min(last.open, last.close) - last.low;
    final upperWick = last.high - math.max(last.open, last.close);
    if (body <= (last.high - last.low) * 0.35 && lowerWick > body * 2 && upperWick < body * 0.5) {
      _patterns[n - 1] = (_patterns[n - 1] != null) ? '${_patterns[n - 1]} / Hammer' : 'Hammer';
    }

    // You can add more patterns...
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Color(0xFF2C2C2E) : Color(0xFFE5E5EA),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // background grid
            CustomPaint(
              size: Size.infinite,
              painter: _GridPainter(isDark: isDark),
            ),

            // chart (line or candles)
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return CustomPaint(
                  size: Size.infinite,
                  painter: _ChartPainter(
                    data: List.of(_priceData),
                    candles: List.of(_candles),
                    showCandles: _showCandles,
                    isRising: _isRising,
                    animation: _animationController.value,
                    tradeHistory: widget.tradeHistory,
                    margins: widget.margins,
                    showMargins: _showMargins,
                    patterns: Map.of(_patterns),
                  ),
                );
              },
            ),

            // header controls (symbol, price, toggles)
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Row(
                children: [
                  // symbol badge
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Color(0xFFFF444F).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFFFF444F).withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      widget.symbol,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  // price tag
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: (_isRising ? Colors.green : Colors.red).withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: (_isRising ? Colors.green : Colors.red).withOpacity(0.3),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isRising ? Icons.arrow_upward : Icons.arrow_downward,
                              color: Colors.white,
                              size: 14,
                            ),
                            SizedBox(width: 6),
                            Text(
                              _currentPrice.toStringAsFixed(5),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // toggles
                  SizedBox(width: 8),
                  // candle toggle
                  GestureDetector(
                    onTap: () => setState(() => _showCandles = !_showCandles),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _showCandles ? AppColors.primary.withOpacity(0.12) : Colors.grey.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.candlestick_chart, size: 16, color: _showCandles ? AppColors.primary : Colors.grey),
                          SizedBox(width: 6),
                          Text('Candles', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  // margins toggle
                  GestureDetector(
                    onTap: () => setState(() => _showMargins = !_showMargins),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _showMargins ? AppColors.primary.withOpacity(0.12) : Colors.grey.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.horizontal_rule, size: 16, color: _showMargins ? AppColors.primary : Colors.grey),
                          SizedBox(width: 6),
                          Text('Margens', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // trade counter bottom-right
            if (widget.tradeHistory.isNotEmpty)
              Positioned(
                bottom: 12,
                right: 12,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.show_chart, color: Colors.white, size: 14),
                      SizedBox(width: 6),
                      Text(
                        '${widget.tradeHistory.length}',
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

/// Simple app colors shim (so this file is self-contained).
/// If you have your own AppColors, remove this and import that instead.
class AppColors {
  static Color primary = const Color(0xFF2F80ED);
  static Color success = const Color(0xFF16A34A);
  static Color error = const Color(0xFFEF4444);
  static Color warning = const Color(0xFFF59E0B);
}

/// GRID painter (background)
class _GridPainter extends CustomPainter {
  final bool isDark;
  _GridPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withOpacity(0.05)
      ..strokeWidth = 0.5;

    // horizontals
    for (int i = 0; i < 5; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // verticals
    for (int i = 0; i < 6; i++) {
      final x = size.width * (i / 5);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Main chart painter (handles both line and candles, markers, margins, patterns)
class _ChartPainter extends CustomPainter {
  final List<double> data;
  final List<Candle> candles;
  final bool showCandles;
  final bool isRising;
  final double animation;
  final List<Map<String, dynamic>> tradeHistory;
  final List<double>? margins;
  final bool showMargins;
  final Map<int, String> patterns;

  _ChartPainter({
    required this.data,
    required this.candles,
    required this.showCandles,
    required this.isRising,
    required this.animation,
    required this.tradeHistory,
    required this.margins,
    required this.showMargins,
    required this.patterns,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (showCandles) {
      _paintCandles(canvas, size);
    } else {
      _paintLine(canvas, size);
    }

    if (showMargins) {
      _paintMargins(canvas, size);
    }

    // draw trade markers (entry/exit)
    _paintTradeMarkers(canvas, size);
    // draw pattern labels
    _paintPatterns(canvas, size);
  }

  void _paintMargins(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.orange.withOpacity(0.6);

    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final visibleRange = _getVisiblePriceRange();

    final levels = margins ?? [visibleRange['min']!, visibleRange['max']!];

    for (final lvl in levels) {
      final y = _priceToY(lvl, size);
      // dashed line
      _drawDashedLine(canvas, Offset(0, y), Offset(size.width, y), paint, dash: 6, gap: 4);

      // label
      textPainter.text = TextSpan(
        text: lvl.toStringAsFixed(5),
        style: TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.bold),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(6, y - textPainter.height - 4));
    }
  }

  void _paintLine(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final minPrice = data.reduce(math.min);
    final maxPrice = data.reduce(math.max);
    var range = maxPrice - minPrice;
    if (range == 0) range = minPrice * 0.01 + 1;

    final padding = 36.0;
    final chartW = size.width - padding * 2;
    final chartH = size.height - padding * 2;
    final stepX = chartW / (data.length - 1);

    final points = <Offset>[];
    for (int i = 0; i < data.length; i++) {
      final x = padding + i * stepX;
      final norm = (data[i] - minPrice) / range;
      final y = padding + chartH - (norm * chartH);
      points.add(Offset(x, y));
    }

    // gradient fill
    final fillPath = Path();
    fillPath.moveTo(points.first.dx, size.height);
    for (final p in points) fillPath.lineTo(p.dx, p.dy);
    fillPath.lineTo(points.last.dx, size.height);
    fillPath.close();

    final grad = LinearGradient(
      colors: [(isRising ? AppColors.success : AppColors.error).withOpacity(0.25), Colors.transparent],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );

    final shaderRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paintFill = Paint()..shader = grad.createShader(shaderRect);
    canvas.drawPath(fillPath, paintFill);

    // smooth path
    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      final p0 = points[i - 1];
      final p1 = points[i];
      final cp1x = p0.dx + (p1.dx - p0.dx) / 2;
      final cp1y = p0.dy;
      final cp2x = p0.dx + (p1.dx - p0.dx) / 2;
      final cp2y = p1.dy;
      path.cubicTo(cp1x, cp1y, cp2x, cp2y, p1.dx, p1.dy);
    }

    // shadow stroke
    final shadowPaint = Paint()
      ..color = (isRising ? AppColors.success : AppColors.error).withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6);

    canvas.drawPath(path, shadowPaint);

    // main stroke
    final mainPaint = Paint()
      ..color = isRising ? AppColors.success : AppColors.error
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, mainPaint);

    // last point pulse
    final last = points.last;
    final pulse = 6.0 + math.sin(animation * math.pi * 2) * 2;
    final pulsePaint = Paint()..color = (isRising ? AppColors.success : AppColors.error).withOpacity(0.25);
    canvas.drawCircle(last, pulse, pulsePaint);

    final dotPaint = Paint()..color = (isRising ? AppColors.success : AppColors.error);
    canvas.drawCircle(last, 4, dotPaint);
    canvas.drawCircle(last, 2, Paint()..color = Colors.white);
  }

  void _paintCandles(Canvas canvas, Size size) {
    if (candles.isEmpty) return;

    // compute visible range (min/max among candles in view)
    final visibleCandles = candles;
    double minPrice = visibleCandles.map((c) => c.low).reduce(math.min);
    double maxPrice = visibleCandles.map((c) => c.high).reduce(math.max);
    double range = maxPrice - minPrice;
    if (range == 0) range = maxPrice * 0.01 + 1;

    final padding = 36.0;
    final chartW = size.width - padding * 2;
    final chartH = size.height - padding * 2;
    final stepX = chartW / visibleCandles.length;

    final candleWidth = math.max(4.0, stepX * 0.6);

    for (int i = 0; i < visibleCandles.length; i++) {
      final c = visibleCandles[i];
      final cx = padding + i * stepX + stepX / 2;
      final openY = padding + chartH - ((c.open - minPrice) / range) * chartH;
      final closeY = padding + chartH - ((c.close - minPrice) / range) * chartH;
      final highY = padding + chartH - ((c.high - minPrice) / range) * chartH;
      final lowY = padding + chartH - ((c.low - minPrice) / range) * chartH;

      final isBull = c.close >= c.open;
      final bodyTop = math.min(openY, closeY);
      final bodyBottom = math.max(openY, closeY);

      // wick
      final wickPaint = Paint()
        ..color = isBull ? AppColors.success.withOpacity(0.9) : AppColors.error.withOpacity(0.9)
        ..strokeWidth = 1.2;
      canvas.drawLine(Offset(cx, highY), Offset(cx, lowY), wickPaint);

      // body
      final bodyRect = Rect.fromLTRB(cx - candleWidth / 2, bodyTop, cx + candleWidth / 2, bodyBottom);
      final bodyPaint = Paint()
        ..color = isBull ? AppColors.success : AppColors.error
        ..style = PaintingStyle.fill;
      canvas.drawRect(bodyRect, bodyPaint);

      // border for body
      canvas.drawRect(bodyRect, Paint()..style = PaintingStyle.stroke..color = Colors.white.withOpacity(0.06)..strokeWidth = 0.6);
    }
  }

  void _paintTradeMarkers(Canvas canvas, Size size) {
    if (tradeHistory.isEmpty) return;

    // Use the line mapping when possible; if candles shown, map price to Y similarly
    final visibleRange = _getVisiblePriceRange();
    final minPrice = visibleRange['min']!;
    final maxPrice = visibleRange['max']!;
    double range = maxPrice - minPrice;
    if (range == 0) range = minPrice * 0.01 + 1;

    final padding = 36.0;
    final chartW = size.width - padding * 2;
    final chartH = size.height - padding * 2;

    // We'll map entry price position to X by finding nearest index in data if available,
    // else just draw a small horizontal marker at the price level.
    for (final trade in tradeHistory.take(50)) {
      final entry = (trade['entryTick'] is num) ? (trade['entryTick'] as num).toDouble() : null;
      final exit = (trade['exitTick'] is num) ? (trade['exitTick'] as num).toDouble() : null;
      final status = trade['status']?.toString() ?? '';
      final isWin = status == 'won';

      if (entry != null) {
        final y = padding + chartH - ((entry - minPrice) / range) * chartH;
        // find closest x index in data by price difference
        int idx = _findClosestIndexForPrice(entry, data);
        double x;
        if (idx >= 0 && data.isNotEmpty) {
          final stepX = chartW / (data.length - 1);
          x = padding + idx * stepX;
        } else {
          x = padding + chartW * 0.1; // fallback
        }

        // draw entry marker (triangle pointing up)
        final path = Path();
        path.moveTo(x, y - 8);
        path.lineTo(x - 6, y + 6);
        path.lineTo(x + 6, y + 6);
        path.close();
        canvas.drawPath(path, Paint()..color = Colors.blueAccent.withOpacity(0.95));
        canvas.drawPath(path, Paint()..style = PaintingStyle.stroke..color = Colors.white..strokeWidth = 1);

        // small label
        final tp = TextPainter(textDirection: TextDirection.ltr);
        tp.text = TextSpan(
            text: 'E',
            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold));
        tp.layout();
        tp.paint(canvas, Offset(x - tp.width / 2, y - 22));
      }

      if (exit != null) {
        final y2 = padding + chartH - ((exit - minPrice) / range) * chartH;
        int idx2 = _findClosestIndexForPrice(exit, data);
        double x2;
        if (idx2 >= 0 && data.isNotEmpty) {
          final stepX = chartW / (data.length - 1);
          x2 = padding + idx2 * stepX;
        } else {
          x2 = padding + chartW * 0.9; // fallback
        }

        // draw exit marker (triangle pointing down)
        final path2 = Path();
        path2.moveTo(x2, y2 + 8);
        path2.lineTo(x2 - 6, y2 - 6);
        path2.lineTo(x2 + 6, y2 - 6);
        path2.close();
        canvas.drawPath(path2, Paint()..color = isWin ? AppColors.success : AppColors.error);
        canvas.drawPath(path2, Paint()..style = PaintingStyle.stroke..color = Colors.white..strokeWidth = 1);

        final tp2 = TextPainter(textDirection: TextDirection.ltr);
        tp2.text = TextSpan(
            text: isWin ? '+' : '-',
            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold));
        tp2.layout();
        tp2.paint(canvas, Offset(x2 - tp2.width / 2, y2 + 8));
      }

      // also draw a tiny horizontal line at entry price across chart for context
      if (entry != null) {
        final py = padding + chartH - ((entry - minPrice) / range) * chartH;
        final pPaint = Paint()..color = Colors.blueAccent.withOpacity(0.24)..strokeWidth = 1.0;
        _drawDashedLine(canvas, Offset(padding, py), Offset(size.width - padding, py), pPaint, dash: 4, gap: 4);
      }
    }
  }

  void _paintPatterns(Canvas canvas, Size size) {
    if (patterns.isEmpty) return;
    // paint markers above candles where patterns detected
    if (candles.isEmpty) return;
    final padding = 36.0;
    final chartW = size.width - padding * 2;
    final chartH = size.height - padding * 2;

    double minPrice = candles.map((c) => c.low).reduce(math.min);
    double maxPrice = candles.map((c) => c.high).reduce(math.max);
    double range = maxPrice - minPrice;
    if (range == 0) range = maxPrice * 0.01 + 1;

    final stepX = chartW / candles.length;
    final tp = TextPainter(textDirection: TextDirection.ltr);
    patterns.forEach((idx, name) {
      if (idx < 0 || idx >= candles.length) return;
      final c = candles[idx];
      final cx = padding + idx * stepX + stepX / 2;
      final top = padding + chartH - ((c.high - minPrice) / range) * chartH;
      tp.text = TextSpan(text: name, style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold));
      tp.layout();
      final rect = Rect.fromLTWH(cx - tp.width / 2 - 6, top - tp.height - 12, tp.width + 12, tp.height + 8);
      final rPaint = Paint()..color = Colors.purple.withOpacity(0.9);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(6)), rPaint);
      tp.paint(canvas, Offset(rect.left + 6, rect.top + 4));
    });
  }

  /// helper: get visible price range (from data or candles)
  Map<String, double> _getVisiblePriceRange() {
    if (showCandles && candles.isNotEmpty) {
      final minP = candles.map((c) => c.low).reduce(math.min);
      final maxP = candles.map((c) => c.high).reduce(math.max);
      return {'min': minP, 'max': maxP};
    }
    if (data.isNotEmpty) {
      final minP = data.reduce(math.min);
      final maxP = data.reduce(math.max);
      return {'min': minP, 'max': maxP};
    }
    return {'min': 0.0, 'max': 1.0};
  }

  double _priceToY(double price, Size size) {
    final rng = _getVisiblePriceRange();
    final minP = rng['min']!;
    final maxP = rng['max']!;
    double range = maxP - minP;
    if (range == 0) range = 1;
    final padding = 36.0;
    final chartH = size.height - padding * 2;
    final y = padding + chartH - ((price - minP) / range) * chartH;
    return y;
  }

  int _findClosestIndexForPrice(double price, List<double> arr) {
    if (arr.isEmpty) return -1;
    double bestDiff = double.infinity;
    int bestIdx = -1;
    for (int i = 0; i < arr.length; i++) {
      final d = (arr[i] - price).abs();
      if (d < bestDiff) {
        bestDiff = d;
        bestIdx = i;
      }
    }
    return bestIdx;
  }

  void _drawDashedLine(Canvas canvas, Offset a, Offset b, Paint paint, {double dash = 5, double gap = 3}) {
    final dx = b.dx - a.dx;
    final dy = b.dy - a.dy;
    final dist = math.sqrt(dx * dx + dy * dy);
    final dashCount = (dist / (dash + gap)).floor();
    final vx = dx / dist;
    final vy = dy / dist;
    var start = 0.0;
    for (int i = 0; i < dashCount; i++) {
      final sx = a.dx + vx * start;
      final sy = a.dy + vy * start;
      final ex = a.dx + vx * (start + dash);
      final ey = a.dy + vy * (start + dash);
      canvas.drawLine(Offset(sx, sy), Offset(ex, ey), paint);
      start += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.candles != candles ||
        oldDelegate.showCandles != showCandles ||
        oldDelegate.animation != animation ||
        oldDelegate.tradeHistory.length != tradeHistory.length ||
        oldDelegate.margins != margins ||
        oldDelegate.showMargins != showMargins ||
        oldDelegate.patterns.length != patterns.length;
  }
}