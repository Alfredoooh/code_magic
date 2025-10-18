// lib/widgets/trading_chart_widget.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:math' as math;

class TradingChartWidget extends StatefulWidget {
  final String symbol;
  final List<Map<String, dynamic>> tradeHistory;

  const TradingChartWidget({
    Key? key,
    required this.symbol,
    required this.tradeHistory,
  }) : super(key: key);

  @override
  _TradingChartWidgetState createState() => _TradingChartWidgetState();
}

class _TradingChartWidgetState extends State<TradingChartWidget> with SingleTickerProviderStateMixin {
  List<double> _priceData = [];
  Timer? _updateTimer;
  late AnimationController _animationController;
  double _currentPrice = 0.0;
  double _priceChange = 0.0;
  bool _isRising = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    )..repeat();
    
    _initializeData();
    _startUpdating();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  void _initializeData() {
    // Inicializar com 50 pontos de dados
    final random = math.Random();
    double basePrice = 100.0 + random.nextDouble() * 50;
    
    for (int i = 0; i < 50; i++) {
      _priceData.add(basePrice + (random.nextDouble() - 0.5) * 10);
    }
    
    _currentPrice = _priceData.last;
  }

  void _startUpdating() {
    // Atualizar a cada 500ms para simular dados em tempo real
    _updateTimer = Timer.periodic(Duration(milliseconds: 500), (timer) {
      if (mounted) {
        setState(() {
          final random = math.Random();
          final oldPrice = _currentPrice;
          
          // Movimento mais realista do preço
          final change = (random.nextDouble() - 0.5) * 2;
          _currentPrice += change;
          
          _priceChange = _currentPrice - oldPrice;
          _isRising = _priceChange >= 0;
          
          // Adicionar novo ponto e remover o mais antigo
          _priceData.add(_currentPrice);
          if (_priceData.length > 50) {
            _priceData.removeAt(0);
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 320,
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
            // Background grid
            CustomPaint(
              size: Size.infinite,
              painter: GridPainter(isDark: isDark),
            ),
            
            // Price line chart
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return CustomPaint(
                  size: Size.infinite,
                  painter: ChartPainter(
                    data: _priceData,
                    isRising: _isRising,
                    animation: _animationController.value,
                    tradeHistory: widget.tradeHistory,
                  ),
                );
              },
            ),
            
            // Header with symbol and price
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Symbol badge
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
                  
                  // Current price
                  Container(
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
                        SizedBox(width: 4),
                        Text(
                          _currentPrice.toStringAsFixed(3),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Trade counter
            if (widget.tradeHistory.isNotEmpty)
              Positioned(
                bottom: 16,
                right: 16,
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

// Painter para o grid de fundo
class GridPainter extends CustomPainter {
  final bool isDark;

  GridPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withOpacity(0.05)
      ..strokeWidth = 0.5;

    // Linhas horizontais
    for (int i = 0; i < 5; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }

    // Linhas verticais
    for (int i = 0; i < 6; i++) {
      final x = size.width * (i / 5);
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Painter para o gráfico de linha
class ChartPainter extends CustomPainter {
  final List<double> data;
  final bool isRising;
  final double animation;
  final List<Map<String, dynamic>> tradeHistory;

  ChartPainter({
    required this.data,
    required this.isRising,
    required this.animation,
    required this.tradeHistory,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final minPrice = data.reduce(math.min);
    final maxPrice = data.reduce(math.max);
    final priceRange = maxPrice - minPrice;

    if (priceRange == 0) return;

    // Calcular pontos do gráfico
    final points = <Offset>[];
    final padding = 40.0;
    final chartWidth = size.width - padding * 2;
    final chartHeight = size.height - padding * 2;
    final stepX = chartWidth / (data.length - 1);

    for (int i = 0; i < data.length; i++) {
      final x = padding + i * stepX;
      final normalizedValue = (data[i] - minPrice) / priceRange;
      final y = padding + chartHeight - (normalizedValue * chartHeight);
      points.add(Offset(x, y));
    }

    // Desenhar gradiente de preenchimento
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
        (isRising ? Colors.green : Colors.red).withOpacity(0.3),
        (isRising ? Colors.green : Colors.red).withOpacity(0.0),
      ],
    );

    canvas.drawPath(
      gradientPath,
      Paint()..shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // Desenhar linha principal
    final path = Path();
    path.moveTo(points.first.dx, points.first.dy);
    
    for (int i = 1; i < points.length; i++) {
      final p0 = points[i - 1];
      final p1 = points[i];
      
      // Curva suave entre pontos
      final cp1x = p0.dx + (p1.dx - p0.dx) / 2;
      final cp1y = p0.dy;
      final cp2x = p0.dx + (p1.dx - p0.dx) / 2;
      final cp2y = p1.dy;
      
      path.cubicTo(cp1x, cp1y, cp2x, cp2y, p1.dx, p1.dy);
    }

    // Sombra da linha
    canvas.drawPath(
      path,
      Paint()
        ..color = (isRising ? Colors.green : Colors.red).withOpacity(0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Linha principal
    canvas.drawPath(
      path,
      Paint()
        ..color = isRising ? Colors.green : Colors.red
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    );

    // Ponto atual (último ponto)
    final lastPoint = points.last;
    
    // Círculo externo pulsante
    final pulseRadius = 8 + (math.sin(animation * math.pi * 2) * 2);
    canvas.drawCircle(
      lastPoint,
      pulseRadius,
      Paint()
        ..color = (isRising ? Colors.green : Colors.red).withOpacity(0.3),
    );

    // Círculo do ponto
    canvas.drawCircle(
      lastPoint,
      6,
      Paint()
        ..color = isRising ? Colors.green : Colors.red
        ..style = PaintingStyle.fill,
    );

    canvas.drawCircle(
      lastPoint,
      4,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );

    // Desenhar marcadores de trades
    _drawTradeMarkers(canvas, size, points, minPrice, maxPrice, priceRange, padding, chartHeight);
  }

  void _drawTradeMarkers(
    Canvas canvas,
    Size size,
    List<Offset> points,
    double minPrice,
    double maxPrice,
    double priceRange,
    double padding,
    double chartHeight,
  ) {
    for (final trade in tradeHistory.take(10)) {
      final isWin = trade['status'] == 'won';
      
      // Colocar marcador no último ponto do gráfico
      final markerPoint = points.last;
      
      // Desenhar triângulo (seta)
      final path = Path();
      if (isWin) {
        // Seta para cima
        path.moveTo(markerPoint.dx, markerPoint.dy - 15);
        path.lineTo(markerPoint.dx - 6, markerPoint.dy - 5);
        path.lineTo(markerPoint.dx + 6, markerPoint.dy - 5);
      } else {
        // Seta para baixo
        path.moveTo(markerPoint.dx, markerPoint.dy + 15);
        path.lineTo(markerPoint.dx - 6, markerPoint.dy + 5);
        path.lineTo(markerPoint.dx + 6, markerPoint.dy + 5);
      }
      path.close();

      canvas.drawPath(
        path,
        Paint()
          ..color = isWin ? Colors.green : Colors.red
          ..style = PaintingStyle.fill,
      );

      canvas.drawPath(
        path,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(covariant ChartPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.isRising != isRising ||
        oldDelegate.animation != animation ||
        oldDelegate.tradeHistory.length != tradeHistory.length;
  }
}