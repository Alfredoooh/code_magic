// lib/widgets/trading_chart_widget.dart
import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// TradingChartWidget com:
/// - suporte a stream de ticks (tickStream)
/// - candles / line toggle
/// - margens (horizontal lines)
/// - deteção simples de padrões
/// - tooltips interativos (tap)
/// - SMA e EMA desenhadas
class TradingChartWidget extends StatefulWidget {
  final String symbol;
  final List<Map<String, dynamic>> tradeHistory;
  final Stream<dynamic>? tickStream;
  final List<double>? margins;
  final int candleTicks;
  final bool enablePatterns;
  final double height;
  final int smaPeriod; // período SMA
  final int emaPeriod; // período EMA

  const TradingChartWidget({
    Key? key,
    required this.symbol,
    required this.tradeHistory,
    this.tickStream,
    this.margins,
    this.candleTicks = 5,
    this.enablePatterns = true,
    this.height = 320,
    this.smaPeriod = 20,
    this.emaPeriod = 50,
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

/// Minimal AppColors shim if your project already has AppColors remove this block
class AppColors {
  static Color primary = const Color(0xFF2F80ED);
  static Color success = const Color(0xFF16A34A);
  static Color error = const Color(0xFFEF4444);
  static Color warning = const Color(0xFFF59E0B);
}

class _TradingChartWidgetState extends State<TradingChartWidget>
    with SingleTickerProviderStateMixin {
  final List<double> _priceData = [];
  final List<Candle> _candles = [];
  int _ticksForCurrentCandle = 0;

  late AnimationController _animationController;
  Timer? _simTimer;
  StreamSubscription? _tickSub;

  double _currentPrice = 0.0;
  double _priceChange = 0.0;
  bool _isRising = true;

  bool _showCandles = false;
  bool _showMargins = true;

  final Map<int, String> _patterns = {};

  // SMA / EMA precomputadas (alinhadas com data index). Nulls for indices without value.
  List<double?> _sma = [];
  List<double?> _ema = [];

  // Tooltip state
  bool _showTooltip = false;
  Offset _tooltipPos = Offset.zero;
  String _tooltipText = '';
  Timer? _tooltipTimer;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 900),
    )..repeat();

    _initSimulatedData();

    if (widget.tickStream != null) {
      _tickSub = widget.tickStream!.listen(_handleTickFromStream, onError: (_) {});
    } else {
      _simTimer = Timer.periodic(Duration(milliseconds: 500), (_) => _generateSimulatedTick());
    }

    // init indicators
    _recalculateIndicators();
  }

  @override
  void didUpdateWidget(covariant TradingChartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
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
    _tooltipTimer?.cancel();
    super.dispose();
  }

  void _initSimulatedData() {
    final rnd = math.Random();
    double base = 100.0 + rnd.nextDouble() * 100;
    _priceData.clear();
    for (int i = 0; i < 120; i++) {
      final v = base + (rnd.nextDouble() - 0.5) * 6;
      _priceData.add(v);
    }
    _currentPrice = _priceData.last;

    _candles.clear();
    for (int i = 0; i < 40; i++) {
      final open = base + (rnd.nextDouble() - 0.5) * 8;
      final close = open + (rnd.nextDouble() - 0.5) * 6;
      final high = math.max(open, close) + rnd.nextDouble() * 3;
      final low = math.min(open, close) - rnd.nextDouble() * 3;
      _candles.add(Candle(ts: DateTime.now().subtract(Duration(minutes: 40 - i)), open: open, high: high, low: low, close: close));
    }

    _recalculateIndicators();
  }

  void _handleTickFromStream(dynamic tick) {
    double? price;
    if (tick == null) return;
    if (tick is num) {
      price = tick.toDouble();
    } else if (tick is Map) {
      final q = tick['quote'] ?? tick['price'] ?? tick['p'] ?? tick['ask'] ?? tick['bid'];
      if (q is num) price = q.toDouble();
    }
    if (price == null) return;
    _processNewPrice(price);
  }

  void _generateSimulatedTick() {
    final rnd = math.Random();
    final change = (rnd.nextDouble() - 0.48) * 1.2;
    final newPrice = (_currentPrice == 0.0 ? (_priceData.isNotEmpty ? _priceData.last : 100.0) : _currentPrice) + change;
    _processNewPrice(newPrice);
  }

  void _processNewPrice(double price) {
    if (!mounted) return;
    setState(() {
      final old = _currentPrice;
      _priceChange = price - old;
      _isRising = _priceChange >= 0;
      _currentPrice = price;

      _priceData.add(price);
      if (_priceData.length > 720) _priceData.removeAt(0);

      // update candles aggregation
      if (_candles.isEmpty) {
        _candles.add(Candle(ts: DateTime.now(), open: price, high: price, low: price, close: price));
        _ticksForCurrentCandle = 1;
      } else {
        final current = _candles.last;
        current.high = math.max(current.high, price);
        current.low = math.min(current.low, price);
        current.close = price;
        _ticksForCurrentCandle++;
        if (_ticksForCurrentCandle >= math.max(1, widget.candleTicks)) {
          _ticksForCurrentCandle = 0;
          _candles.add(Candle(ts: DateTime.now(), open: price, high: price, low: price, close: price));
          if (_candles.length > 300) _candles.removeAt(0);
        }
      }

      // recalc indicators
      _recalculateIndicators();

      // detect patterns
      if (widget.enablePatterns) _detectPatterns();
    });
  }

  void _recalculateIndicators() {
    // compute SMA and EMA for _priceData (aligned to data indices)
    _sma = List<double?>.filled(_priceData.length, null);
    _ema = List<double?>.filled(_priceData.length, null);

    final p = widget.smaPeriod;
    if (p > 0 && _priceData.length >= p) {
      double sum = 0;
      for (int i = 0; i < _priceData.length; i++) {
        sum += _priceData[i];
        if (i >= p) sum -= _priceData[i - p];
        if (i >= p - 1) {
          _sma[i] = sum / p;
        }
      }
    }

    final ep = widget.emaPeriod;
    if (ep > 0 && _priceData.isNotEmpty) {
      final k = 2 / (ep + 1);
      double? prev;
      for (int i = 0; i < _priceData.length; i++) {
        final price = _priceData[i];
        if (i == 0) {
          prev = price;
          _ema[i] = prev;
        } else {
          prev = (price * k) + (prev! * (1 - k));
          _ema[i] = prev;
        }
      }
    }
  }

  void _detectPatterns() {
    _patterns.clear();
    final n = _candles.length;
    if (n < 2) return;
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

    final body = (last.close - last.open).abs();
    final lowerWick = math.min(last.open, last.close) - last.low;
    final upperWick = last.high - math.max(last.open, last.close);
    if (body <= (last.high - last.low) * 0.35 && lowerWick > body * 2 && upperWick < body * 0.5) {
      _patterns[n - 1] = (_patterns[n - 1] != null) ? '${_patterns[n - 1]} / Hammer' : 'Hammer';
    }
  }

  // Tooltip helpers
  void _showTooltipAt(Offset localPos, Size size) {
    // find nearest data index
    final visible = _priceData;
    if (visible.isEmpty) return;

    final padding = 36.0;
    final chartW = size.width - padding * 2;
    final stepX = chartW / (visible.length - 1);
    final relativeX = (localPos.dx - padding).clamp(0.0, chartW);
    final idx = ((relativeX / stepX).round()).clamp(0, visible.length - 1);

    final price = visible[idx];
    final text = 'Index: $idx\nPrice: ${price.toStringAsFixed(5)}\nSMA: ${_sma[idx]?.toStringAsFixed(5) ?? '-'}\nEMA: ${_ema[idx]?.toStringAsFixed(5) ?? '-'}';
    setState(() {
      _tooltipPos = localPos;
      _tooltipText = text;
      _showTooltip = true;
    });

    _tooltipTimer?.cancel();
    _tooltipTimer = Timer(Duration(seconds: 4), () {
      setState(() => _showTooltip = false);
    });
  }

  void _hideTooltip() {
    _tooltipTimer?.cancel();
    setState(() {
      _showTooltip = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTapDown: (tap) {
        final box = context.findRenderObject() as RenderBox?;
        if (box != null) {
          final local = box.globalToLocal(tap.globalPosition);
          _showTooltipAt(local, box.size);
        }
      },
      onTapUp: (_) => null,
      onTapCancel: _hideTooltip,
      child: Container(
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
              CustomPaint(
                size: Size.infinite,
                painter: _GridPainter(isDark: isDark),
              ),
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
                      sma: List.of(_sma),
                      ema: List.of(_ema),
                    ),
                  );
                },
              ),
              // header and controls (symbol, price, toggles)
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: Row(
                  children: [
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
                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                    SizedBox(width: 10),
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
                              Icon(_isRising ? Icons.arrow_upward : Icons.arrow_downward, color: Colors.white, size: 14),
                              SizedBox(width: 6),
                              Text(_currentPrice.toStringAsFixed(5), style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
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

              // tooltip (positioned)
              if (_showTooltip)
                LayoutBuilder(builder: (context, constraints) {
                  final left = (_tooltipPos.dx + 8).clamp(8.0, constraints.maxWidth - 180.0);
                  final top = (_tooltipPos.dy - 60).clamp(36.0, constraints.maxHeight - 80.0);
                  return Positioned(
                    left: left,
                    top: top,
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        width: 180,
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.75),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(_tooltipText, style: TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                    ),
                  );
                }),

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
                        Text('${widget.tradeHistory.length}', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Grid painter
class _GridPainter extends CustomPainter {
  final bool isDark;
  _GridPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = (isDark ? Colors.white : Colors.black).withOpacity(0.05)..strokeWidth = 0.5;
    for (int i = 0; i < 5; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    for (int i = 0; i < 6; i++) {
      final x = size.width * (i / 5);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Chart painter
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
  final List<double?> sma;
  final List<double?> ema;

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
    required this.sma,
    required this.ema,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (showCandles) {
      _paintCandles(canvas, size);
    } else {
      _paintLine(canvas, size);
    }

    if (showMargins) _paintMargins(canvas, size);
    _paintTradeMarkers(canvas, size);
    _paintPatterns(canvas, size);

    // draw SMA/EMA on top of line (only meaningful in line mode)
    if (!showCandles) _paintSMAEMA(canvas, size);
  }

  void _paintMargins(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = 1.0..color = Colors.orange.withOpacity(0.6);
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final visible = _getVisibleRange();
    final levels = margins ?? [visible['min']!, visible['max']!];
    for (final lvl in levels) {
      final y = _priceToY(lvl, size);
      _drawDashedLine(canvas, Offset(0, y), Offset(size.width, y), paint, dash: 6, gap: 4);
      textPainter.text = TextSpan(text: lvl.toStringAsFixed(5), style: TextStyle(fontSize: 11, color: Colors.orange, fontWeight: FontWeight.bold));
      textPainter.layout();
      textPainter.paint(canvas, Offset(6, y - textPainter.height - 4));
    }
  }

  void _paintLine(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    var minPrice = data.reduce(math.min);
    var maxPrice = data.reduce(math.max);
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
    final fillPath = Path()..moveTo(points.first.dx, size.height);
    for (final p in points) fillPath.lineTo(p.dx, p.dy);
    fillPath.lineTo(points.last.dx, size.height);
    fillPath.close();

    final grad = LinearGradient(colors: [AppColors.primary.withOpacity(0.12), Colors.transparent], begin: Alignment.topCenter, end: Alignment.bottomCenter);
    canvas.drawPath(fillPath, Paint()..shader = grad.createShader(Rect.fromLTWH(0, 0, size.width, size.height)));

    // smooth path
    final path = Path()..moveTo(points.first.dx, points.first.dy);
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
    canvas.drawPath(path, Paint()..color = AppColors.primary.withOpacity(0.12)..style = PaintingStyle.stroke..strokeWidth = 6..maskFilter = MaskFilter.blur(BlurStyle.normal, 6));

    // main stroke
    canvas.drawPath(path, Paint()..color = AppColors.primary..style = PaintingStyle.stroke..strokeWidth = 2.2..strokeCap = StrokeCap.round);

    // last point pulse
    final last = points.last;
    final pulse = 6.0 + math.sin(animation * math.pi * 2) * 2;
    canvas.drawCircle(last, pulse, Paint()..color = AppColors.primary.withOpacity(0.18));
    canvas.drawCircle(last, 4, Paint()..color = AppColors.primary);
    canvas.drawCircle(last, 2, Paint()..color = Colors.white);
  }

  void _paintSMAEMA(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final visible = _getVisibleRange();
    double minPrice = visible['min']!;
    double maxPrice = visible['max']!;
    double range = maxPrice - minPrice;
    if (range == 0) range = minPrice * 0.01 + 1;

    final padding = 36.0;
    final chartW = size.width - padding * 2;
    final chartH = size.height - padding * 2;
    final stepX = chartW / (data.length - 1);

    // draw SMA
    final smaPoints = <Offset>[];
    for (int i = 0; i < sma.length; i++) {
      final v = sma[i];
      if (v == null) {
        smaPoints.add(Offset(padding + i * stepX, padding + chartH)); // placeholder off-chart
      } else {
        final y = padding + chartH - ((v - minPrice) / range) * chartH;
        smaPoints.add(Offset(padding + i * stepX, y));
      }
    }
    // SMA stroke
    final pSMA = Paint()..color = Colors.yellowAccent.withOpacity(0.95)..style = PaintingStyle.stroke..strokeWidth = 1.6;
    final pathSMA = Path();
    bool started = false;
    for (int i = 0; i < smaPoints.length; i++) {
      final pt = smaPoints[i];
      if (sma[i] == null) {
        started = false;
        continue;
      }
      if (!started) {
        pathSMA.moveTo(pt.dx, pt.dy);
        started = true;
      } else {
        pathSMA.lineTo(pt.dx, pt.dy);
      }
    }
    canvas.drawPath(pathSMA, pSMA);

    // draw EMA
    final emaPoints = <Offset>[];
    for (int i = 0; i < ema.length; i++) {
      final v = ema[i];
      if (v == null) {
        emaPoints.add(Offset(padding + i * stepX, padding + chartH));
      } else {
        final y = padding + chartH - ((v - minPrice) / range) * chartH;
        emaPoints.add(Offset(padding + i * stepX, y));
      }
    }
    final pEMA = Paint()..color = Colors.purpleAccent.withOpacity(0.95)..style = PaintingStyle.stroke..strokeWidth = 1.6;
    final pathEMA = Path();
    started = false;
    for (int i = 0; i < emaPoints.length; i++) {
      final pt = emaPoints[i];
      if (ema[i] == null) {
        started = false;
        continue;
      }
      if (!started) {
        pathEMA.moveTo(pt.dx, pt.dy);
        started = true;
      } else {
        pathEMA.lineTo(pt.dx, pt.dy);
      }
    }
    canvas.drawPath(pathEMA, pEMA);
  }

  void _paintCandles(Canvas canvas, Size size) {
    if (candles.isEmpty) return;
    final visible = candles;
    double minPrice = visible.map((c) => c.low).reduce(math.min);
    double maxPrice = visible.map((c) => c.high).reduce(math.max);
    double range = maxPrice - minPrice;
    if (range == 0) range = maxPrice * 0.01 + 1;

    final padding = 36.0;
    final chartW = size.width - padding * 2;
    final chartH = size.height - padding * 2;
    final stepX = chartW / visible.length;
    final candleWidth = math.max(4.0, stepX * 0.6);

    for (int i = 0; i < visible.length; i++) {
      final c = visible[i];
      final cx = padding + i * stepX + stepX / 2;
      final openY = padding + chartH - ((c.open - minPrice) / range) * chartH;
      final closeY = padding + chartH - ((c.close - minPrice) / range) * chartH;
      final highY = padding + chartH - ((c.high - minPrice) / range) * chartH;
      final lowY = padding + chartH - ((c.low - minPrice) / range) * chartH;

      final isBull = c.close >= c.open;
      final bodyTop = math.min(openY, closeY);
      final bodyBottom = math.max(openY, closeY);

      final wickPaint = Paint()..color = isBull ? AppColors.success.withOpacity(0.9) : AppColors.error.withOpacity(0.9)..strokeWidth = 1.2;
      canvas.drawLine(Offset(cx, highY), Offset(cx, lowY), wickPaint);

      final bodyRect = Rect.fromLTRB(cx - candleWidth / 2, bodyTop, cx + candleWidth / 2, bodyBottom);
      final bodyPaint = Paint()..color = isBull ? AppColors.success : AppColors.error..style = PaintingStyle.fill;
      canvas.drawRect(bodyRect, bodyPaint);
      canvas.drawRect(bodyRect, Paint()..style = PaintingStyle.stroke..color = Colors.white.withOpacity(0.06)..strokeWidth = 0.6);
    }
  }

  void _paintTradeMarkers(Canvas canvas, Size size) {
    if (tradeHistory.isEmpty) return;

    final visible = data.isNotEmpty ? data : candles.map((c) => c.close).toList();
    if (visible.isEmpty) return;
    final visRange = _getVisibleRange();
    final minPrice = visRange['min']!;
    final maxPrice = visRange['max']!;
    var range = maxPrice - minPrice;
    if (range == 0) range = minPrice * 0.01 + 1;

    final padding = 36.0;
    final chartW = size.width - padding * 2;
    final chartH = size.height - padding * 2;
    final stepX = chartW / (visible.length - 1);

    for (final trade in tradeHistory.take(60)) {
      final entry = (trade['entryTick'] is num) ? (trade['entryTick'] as num).toDouble() : null;
      final exit = (trade['exitTick'] is num) ? (trade['exitTick'] as num).toDouble() : null;
      final status = trade['status']?.toString() ?? '';
      final isWin = status == 'won';

      if (entry != null) {
        final y = padding + chartH - ((entry - minPrice) / range) * chartH;
        final idx = _findClosestIndexForPrice(entry, visible);
        final x = (idx >= 0) ? (padding + idx * stepX) : (padding + chartW * 0.1);

        final path = Path();
        path.moveTo(x, y - 8);
        path.lineTo(x - 6, y + 6);
        path.lineTo(x + 6, y + 6);
        path.close();
        canvas.drawPath(path, Paint()..color = Colors.blueAccent.withOpacity(0.95));
        canvas.drawPath(path, Paint()..style = PaintingStyle.stroke..color = Colors.white..strokeWidth = 1);

        final tp = TextPainter(textDirection: TextDirection.ltr);
        tp.text = TextSpan(text: 'E', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold));
        tp.layout();
        tp.paint(canvas, Offset(x - tp.width / 2, y - 22));

        // horizontal guide line
        final pPaint = Paint()..color = Colors.blueAccent.withOpacity(0.18)..strokeWidth = 1.0;
        _drawDashedLine(canvas, Offset(padding, y), Offset(size.width - padding, y), pPaint, dash: 4, gap: 4);
      }

      if (exit != null) {
        final y2 = padding + chartH - ((exit - minPrice) / range) * chartH;
        final idx2 = _findClosestIndexForPrice(exit, visible);
        final x2 = (idx2 >= 0) ? (padding + idx2 * stepX) : (padding + chartW * 0.9);

        final path2 = Path();
        path2.moveTo(x2, y2 + 8);
        path2.lineTo(x2 - 6, y2 - 6);
        path2.lineTo(x2 + 6, y2 - 6);
        path2.close();
        canvas.drawPath(path2, Paint()..color = isWin ? AppColors.success : AppColors.error);
        canvas.drawPath(path2, Paint()..style = PaintingStyle.stroke..color = Colors.white..strokeWidth = 1);

        final tp2 = TextPainter(textDirection: TextDirection.ltr);
        tp2.text = TextSpan(text: isWin ? '+' : '-', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold));
        tp2.layout();
        tp2.paint(canvas, Offset(x2 - tp2.width / 2, y2 + 8));
      }
    }
  }

  void _paintPatterns(Canvas canvas, Size size) {
    if (patterns.isEmpty || candles.isEmpty) return;

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

  Map<String, double> _getVisibleRange() {
    if (showCandles && candles.isNotEmpty) {
      return {'min': candles.map((c) => c.low).reduce(math.min), 'max': candles.map((c) => c.high).reduce(math.max)};
    }
    if (data.isNotEmpty) {
      return {'min': data.reduce(math.min), 'max': data.reduce(math.max)};
    }
    return {'min': 0.0, 'max': 1.0};
  }

  double _priceToY(double price, Size size) {
    final rng = _getVisibleRange();
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
    if (dist == 0) return;
    final vx = dx / dist;
    final vy = dy / dist;
    double start = 0.0;
    while (start < dist) {
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
        oldDelegate.patterns.length != patterns.length ||
        oldDelegate.sma != sma ||
        oldDelegate.ema != ema;
  }
}