// lib/widgets/trading_chart_widget.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../services/deriv_service.dart';

class TradingChartWidget extends StatefulWidget {
  final String symbol;
  final List<Map<String, dynamic>> tradeHistory;
  final DerivService derivService;

  const TradingChartWidget({
    Key? key,
    required this.symbol,
    required this.tradeHistory,
    required this.derivService,
  }) : super(key: key);

  @override
  _TradingChartWidgetState createState() => _TradingChartWidgetState();
}

class _TradingChartWidgetState extends State<TradingChartWidget> with SingleTickerProviderStateMixin {
  List<TickData> _tickData = [];
  List<TradeMarker> _tradeMarkers = [];
  Timer? _updateTimer;
  late AnimationController _animationController;
  double _currentPrice = 0.0;
  double _priceChange = 0.0;
  bool _isRising = true;
  StreamSubscription? _tickSubscription;
  int _displayedTradeCount = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    )..repeat();

    _initializeData();
    _subscribeToTicks();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _animationController.dispose();
    _tickSubscription?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(TradingChartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (oldWidget.symbol != widget.symbol) {
      _tickData.clear();
      _initializeData();
      _subscribeToTicks();
    }

    // Atualizar marcadores de trade em tempo real
    if (oldWidget.tradeHistory.length != widget.tradeHistory.length) {
      _updateTradeMarkers();
    }
  }

  void _initializeData() {
    final random = math.Random();
    double basePrice = 100.0 + random.nextDouble() * 50;

    _tickData.clear();
    for (int i = 0; i < 100; i++) {
      final price = basePrice + (random.nextDouble() - 0.5) * 5;
      _tickData.add(TickData(
        timestamp: DateTime.now().subtract(Duration(seconds: 100 - i)),
        price: price,
      ));
    }

    _currentPrice = _tickData.last.price;
  }

  void _subscribeToTicks() {
    _tickSubscription?.cancel();
    
    _tickSubscription = widget.derivService.tickStream.listen((tick) {
      if (mounted) {
        final newPrice = (tick['quote'] ?? _currentPrice).toDouble();
        
        setState(() {
          final oldPrice = _currentPrice;
          _currentPrice = newPrice;
          _priceChange = _currentPrice - oldPrice;
          _isRising = _priceChange >= 0;

          _tickData.add(TickData(
            timestamp: DateTime.now(),
            price: _currentPrice,
          ));

          // Manter apenas últimos 100 ticks para performance
          if (_tickData.length > 100) {
            _tickData.removeAt(0);
          }
        });
      }
    });
  }

  void _updateTradeMarkers() {
    if (widget.tradeHistory.length > _displayedTradeCount) {
      final newTrades = widget.tradeHistory.sublist(0, widget.tradeHistory.length - _displayedTradeCount);
      
      setState(() {
        for (final trade in newTrades) {
          final entryPrice = trade['entryTick'] as double;
          final exitPrice = trade['exitTick'] as double;
          final isWin = trade['status'] == 'won';
          final timestamp = trade['timestamp'] as DateTime;

          _tradeMarkers.add(TradeMarker(
            entryPrice: entryPrice,
            exitPrice: exitPrice,
            timestamp: timestamp,
            isWin: isWin,
            type: trade['type'],
          ));
        }

        // Manter apenas últimos 50 marcadores
        if (_tradeMarkers.length > 50) {
          _tradeMarkers = _tradeMarkers.sublist(_tradeMarkers.length - 50);
        }

        _displayedTradeCount = widget.tradeHistory.length;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 380,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [Color(0xFF1C1C1E), Color(0xFF2C2C2E)]
              : [Colors.white, Colors.grey[50]!],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Color(0xFF3C3C3E) : Color(0xFFE5E5EA),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Background grid animado
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return CustomPaint(
                  size: Size.infinite,
                  painter: GridPainter(
                    isDark: isDark,
                    animation: _animationController.value,
                  ),
                );
              },
            ),

            // Gráfico de linha principal
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return CustomPaint(
                  size: Size.infinite,
                  painter: ChartPainter(
                    tickData: _tickData,
                    tradeMarkers: _tradeMarkers,
                    isRising: _isRising,
                    animation: _animationController.value,
                    isDark: isDark,
                  ),
                );
              },
            ),

            // Header com informações
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSymbolBadge(),
                  _buildPriceBadge(),
                ],
              ),
            ),

            // Indicador de volume de trades
            Positioned(
              bottom: 16,
              left: 16,
              child: _buildTradeCounter(isDark),
            ),

            // Indicador de tendência
            Positioned(
              bottom: 16,
              right: 16,
              child: _buildTrendIndicator(isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSymbolBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFF6B6B), Color(0xFFFF4757)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Color(0xFFFF4757).withOpacity(0.4),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 8),
          Text(
            widget.symbol,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceBadge() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isRising
              ? [Color(0xFF00D084), Color(0xFF00B972)]
              : [Color(0xFFFF4757), Color(0xFFFF3838)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: (_isRising ? Color(0xFF00D084) : Color(0xFFFF4757)).withOpacity(0.4),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isRising ? Icons.arrow_upward : Icons.arrow_downward,
            color: Colors.white,
            size: 16,
          ),
          SizedBox(width: 6),
          Text(
            _currentPrice.toStringAsFixed(5),
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTradeCounter(bool isDark) {
    if (_tradeMarkers.isEmpty) return SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timeline, color: Colors.white, size: 16),
          SizedBox(width: 6),
          Text(
            '${_tradeMarkers.length}',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendIndicator(bool isDark) {
    final recentTicks = _tickData.length > 20 ? _tickData.sublist(_tickData.length - 20) : _tickData;
    final avgChange = recentTicks.isEmpty ? 0.0 : recentTicks.map((t) => t.price).reduce((a, b) => a + b) / recentTicks.length;
    final trend = _currentPrice > avgChange;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: trend
              ? [Color(0xFF00D084).withOpacity(0.9), Color(0xFF00B972).withOpacity(0.9)]
              : [Color(0xFFFF4757).withOpacity(0.9), Color(0xFFFF3838).withOpacity(0.9)],
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: (trend ? Color(0xFF00D084) : Color(0xFFFF4757)).withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            trend ? Icons.trending_up : Icons.trending_down,
            color: Colors.white,
            size: 16,
          ),
          SizedBox(width: 4),
          Text(
            trend ? 'BULL' : 'BEAR',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// Modelo de dados para tick
class TickData {
  final DateTime timestamp;
  final double price;

  TickData({required this.timestamp, required this.price});
}

// Modelo de marcador de trade
class TradeMarker {
  final double entryPrice;
  final double exitPrice;
  final DateTime timestamp;
  final bool isWin;
  final String type;

  TradeMarker({
    required this.entryPrice,
    required this.exitPrice,
    required this.timestamp,
    required this.isWin,
    required this.type,
  });
}

// Painter para grid animado
class GridPainter extends CustomPainter {
  final bool isDark;
  final double animation;

  GridPainter({required this.isDark, required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withOpacity(0.06)
      ..strokeWidth = 0.5;

    final dashPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withOpacity(0.1)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Linhas horizontais
    for (int i = 0; i <= 6; i++) {
      final y = size.height * (i / 6);
      _drawDashedLine(canvas, Offset(0, y), Offset(size.width, y), dashPaint);
    }

    // Linhas verticais
    for (int i = 0; i <= 8; i++) {
      final x = size.width * (i / 8);
      _drawDashedLine(canvas, Offset(x, 0), Offset(x, size.height), dashPaint);
    }
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashWidth = 5;
    const dashSpace = 3;
    double distance = (end - start).distance;
    double dashCount = (distance / (dashWidth + dashSpace)).floorToDouble();

    for (int i = 0; i < dashCount; i++) {
      double startX = start.dx + (end.dx - start.dx) * (i * (dashWidth + dashSpace)) / distance;
      double startY = start.dy + (end.dy - start.dy) * (i * (dashWidth + dashSpace)) / distance;
      double endX = start.dx + (end.dx - start.dx) * (i * (dashWidth + dashSpace) + dashWidth) / distance;
      double endY = start.dy + (end.dy - start.dy) * (i * (dashWidth + dashSpace) + dashWidth) / distance;

      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Painter principal do gráfico
class ChartPainter extends CustomPainter {
  final List<TickData> tickData;
  final List<TradeMarker> tradeMarkers;
  final bool isRising;
  final double animation;
  final bool isDark;

  ChartPainter({
    required this.tickData,
    required this.tradeMarkers,
    required this.isRising,
    required this.animation,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (tickData.isEmpty) return;

    final prices = tickData.map((t) => t.price).toList();
    final minPrice = prices.reduce(math.min);
    final maxPrice = prices.reduce(math.max);
    final priceRange = maxPrice - minPrice;

    if (priceRange == 0) return;

    final padding = 50.0;
    final chartWidth = size.width - padding * 2;
    final chartHeight = size.height - padding * 2;
    final stepX = chartWidth / (tickData.length - 1);

    // Calcular pontos
    final points = <Offset>[];
    for (int i = 0; i < tickData.length; i++) {
      final x = padding + i * stepX;
      final normalizedValue = (tickData[i].price - minPrice) / priceRange;
      final y = padding + chartHeight - (normalizedValue * chartHeight);
      points.add(Offset(x, y));
    }

    // Desenhar área preenchida com gradiente
    _drawFilledArea(canvas, points, size);

    // Desenhar linha principal
    _drawMainLine(canvas, points);

    // Desenhar marcadores de trades
    _drawTradeMarkers(canvas, points, tickData, minPrice, maxPrice, priceRange, padding, chartHeight);

    // Desenhar ponto atual pulsante
    _drawCurrentPoint(canvas, points.last);
  }

  void _drawFilledArea(Canvas canvas, List<Offset> points, Size size) {
    final gradientPath = Path();
    gradientPath.moveTo(points.first.dx, size.height);

    for (final point in points) {
      gradientPath.lineTo(point.dx, point.dy);
    }

    gradientPath.lineTo(points.last.dx, size.height);
    gradientPath.close();

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        (isRising ? Color(0xFF00D084) : Color(0xFFFF4757)).withOpacity(0.25),
        (isRising ? Color(0xFF00D084) : Color(0xFFFF4757)).withOpacity(0.0),
      ],
    );

    canvas.drawPath(
      gradientPath,
      Paint()..shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );
  }

  void _drawMainLine(Canvas canvas, List<Offset> points) {
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

    // Sombra externa
    canvas.drawPath(
      path,
      Paint()
        ..color = (isRising ? Color(0xFF00D084) : Color(0xFFFF4757)).withOpacity(0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Linha principal
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          colors: isRising
              ? [Color(0xFF00D084), Color(0xFF00B972)]
              : [Color(0xFFFF4757), Color(0xFFFF3838)],
        ).createShader(Rect.fromLTRB(0, 0, points.last.dx, 0))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawTradeMarkers(Canvas canvas, List<Offset> points, List<TickData> tickData,
      double minPrice, double maxPrice, double priceRange, double padding, double chartHeight) {
    for (final marker in tradeMarkers) {
      // Encontrar posição no gráfico baseado no timestamp
      final markerIndex = tickData.indexWhere((t) => 
        t.timestamp.isAfter(marker.timestamp.subtract(Duration(seconds: 5))) &&
        t.timestamp.isBefore(marker.timestamp.add(Duration(seconds: 5)))
      );

      if (markerIndex == -1 || markerIndex >= points.length) continue;

      final markerPoint = points[markerIndex];

      // Desenhar ponto de entrada
      canvas.drawCircle(
        markerPoint,
        8,
        Paint()
          ..color = marker.isWin ? Color(0xFF00D084) : Color(0xFFFF4757)
          ..style = PaintingStyle.fill,
      );

      canvas.drawCircle(
        markerPoint,
        6,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill,
      );

      // Desenhar seta indicadora
      final arrowPath = Path();
      if (marker.type == 'CALL') {
        // Seta para cima
        arrowPath.moveTo(markerPoint.dx, markerPoint.dy - 20);
        arrowPath.lineTo(markerPoint.dx - 7, markerPoint.dy - 10);
        arrowPath.lineTo(markerPoint.dx + 7, markerPoint.dy - 10);
      } else {
        // Seta para baixo
        arrowPath.moveTo(markerPoint.dx, markerPoint.dy + 20);
        arrowPath.lineTo(markerPoint.dx - 7, markerPoint.dy + 10);
        arrowPath.lineTo(markerPoint.dx + 7, markerPoint.dy + 10);
      }
      arrowPath.close();

      // Sombra da seta
      canvas.drawPath(
        arrowPath,
        Paint()
          ..color = Colors.black.withOpacity(0.3)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4),
      );

      // Seta principal
      canvas.drawPath(
        arrowPath,
        Paint()
          ..shader = LinearGradient(
            colors: marker.isWin
                ? [Color(0xFF00D084), Color(0xFF00B972)]
                : [Color(0xFFFF4757), Color(0xFFFF3838)],
          ).createShader(Rect.fromCircle(center: markerPoint, radius: 20))
          ..style = PaintingStyle.fill,
      );

      // Borda da seta
      canvas.drawPath(
        arrowPath,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );

      // Desenhar linha de conexão entre entrada e saída
      if (marker.exitPrice != marker.entryPrice) {
        final exitY = padding + chartHeight - ((marker.exitPrice - minPrice) / priceRange * chartHeight);
        final exitPoint = Offset(markerPoint.dx, exitY);

        final connectionPath = Path();
        connectionPath.moveTo(markerPoint.dx, markerPoint.dy);
        connectionPath.lineTo(exitPoint.dx, exitPoint.dy);

        // Linha pontilhada
        _drawDashedPath(canvas, connectionPath, 
          marker.isWin ? Color(0xFF00D084) : Color(0xFFFF4757));

        // Ponto de saída
        canvas.drawCircle(
          exitPoint,
          5,
          Paint()
            ..color = marker.isWin ? Color(0xFF00D084) : Color(0xFFFF4757)
            ..style = PaintingStyle.fill,
        );

        canvas.drawCircle(
          exitPoint,
          3,
          Paint()
            ..color = Colors.white
            ..style = PaintingStyle.fill,
        );
      }
    }
  }

  void _drawDashedPath(Canvas canvas, Path path, Color color) {
    final dashedPaint = Paint()
      ..color = color.withOpacity(0.6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    const dashWidth = 5.0;
    const dashSpace = 3.0;

    final metrics = path.computeMetrics().toList();
    for (final metric in metrics) {
      double distance = 0.0;
      while (distance < metric.length) {
        final start = metric.getTangentForOffset(distance)!.position;
        distance += dashWidth;
        final end = metric.getTangentForOffset(distance)!.position;
        canvas.drawLine(start, end, dashedPaint);
        distance += dashSpace;
      }
    }
  }

  void _drawCurrentPoint(Canvas canvas, Offset point) {
    // Círculo pulsante externo
    final pulseRadius = 10 + (math.sin(animation * math.pi * 2) * 3);
    canvas.drawCircle(
      point,
      pulseRadius,
      Paint()
        ..color = (isRising ? Color(0xFF00D084) : Color(0xFFFF4757)).withOpacity(0.3),
    );

    // Círculo médio
    canvas.drawCircle(
      point,
      8,
      Paint()
        ..shader = LinearGradient(
          colors: isRising
              ? [Color(0xFF00D084), Color(0xFF00B972)]
              : [Color(0xFFFF4757), Color(0xFFFF3838)],
        ).createShader(Rect.fromCircle(center: point, radius: 8))
        ..style = PaintingStyle.fill,
    );

    // Círculo interno branco
    canvas.drawCircle(
      point,
      5,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );

    // Borda do círculo
    canvas.drawCircle(
      point,
      8,
      Paint()
        ..color = Colors.white.withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant ChartPainter oldDelegate) {
    return oldDelegate.tickData.length != tickData.length ||
        oldDelegate.tradeMarkers.length != tradeMarkers.length ||
        oldDelegate.isRising != isRising ||
        oldDelegate.animation != animation;
  }
}