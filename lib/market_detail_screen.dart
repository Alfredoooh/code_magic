// market_detail_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'markets_screen.dart';
import 'trade_screen.dart';

class MarketDetailScreen extends StatefulWidget {
  final String symbol;
  final MarketInfo marketInfo;
  final MarketData? marketData;
  final String token;
  final WebSocketChannel? channel;

  const MarketDetailScreen({
    Key? key,
    required this.symbol,
    required this.marketInfo,
    this.marketData,
    required this.token,
    this.channel,
  }) : super(key: key);

  @override
  State<MarketDetailScreen> createState() => _MarketDetailScreenState();
}

class _MarketDetailScreenState extends State<MarketDetailScreen> {
  MarketData? _currentData;
  final List<double> _priceHistory = [];

  @override
  void initState() {
    super.initState();
    _currentData = widget.marketData;
    _subscribeToMarket();
  }

  void _subscribeToMarket() {
    if (widget.channel != null) {
      widget.channel!.sink.add(json.encode({
        'ticks': widget.symbol,
        'subscribe': 1,
      }));

      widget.channel!.stream.listen((message) {
        final data = json.decode(message);
        if (data['msg_type'] == 'tick' && data['tick']['symbol'] == widget.symbol) {
          final tick = data['tick'];
          final quote = double.parse(tick['quote'].toString());

          setState(() {
            if (_currentData != null) {
              final oldPrice = _currentData!.price;
              _currentData = MarketData(
                price: quote,
                change: ((quote - oldPrice) / oldPrice) * 100,
                timestamp: DateTime.now(),
              );
            } else {
              _currentData = MarketData(
                price: quote,
                change: 0.0,
                timestamp: DateTime.now(),
              );
            }

            _priceHistory.add(quote);
            if (_priceHistory.length > 50) {
              _priceHistory.removeAt(0);
            }
          });
        }
      });
    }
  }

  void _openTrade() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => TradeScreen(
          token: widget.token,
          initialMarket: widget.symbol,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 1.0),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPositive = (_currentData?.change ?? 0) >= 0;
    final changeColor = isPositive ? const Color(0xFF34C759) : const Color(0xFFFF3B30);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1C1E),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.marketInfo.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.4,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Price Header
                  Container(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            widget.marketInfo.iconUrl,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _currentData != null 
                              ? _currentData!.price.toStringAsFixed(2)
                              : '...',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_currentData != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: changeColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${isPositive ? '+' : ''}${_currentData!.change.toStringAsFixed(2)}%',
                              style: TextStyle(
                                color: changeColor,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Chart Placeholder
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    height: 200,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C1E),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: _priceHistory.length > 2
                        ? CustomPaint(
                            painter: SimpleChartPainter(_priceHistory, changeColor),
                          )
                        : Center(
                            child: Text(
                              'Carregando gráfico...',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 14,
                              ),
                            ),
                          ),
                  ),

                  const SizedBox(height: 24),

                  // Info Cards
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        _buildInfoCard('Símbolo', widget.symbol),
                        const SizedBox(height: 12),
                        _buildInfoCard('Categoria', widget.marketInfo.category),
                        const SizedBox(height: 12),
                        _buildInfoCard('Nome', widget.marketInfo.name),
                        const SizedBox(height: 12),
                        _buildInfoCard(
                          'Última Atualização',
                          _currentData != null
                              ? _formatTime(_currentData!.timestamp)
                              : 'N/A',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Trade Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _openTrade,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0066FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Negociar',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 15,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inSeconds < 60) return '${diff.inSeconds}s atrás';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m atrás';
    if (diff.inHours < 24) return '${diff.inHours}h atrás';
    return '${diff.inDays}d atrás';
  }
}

class SimpleChartPainter extends CustomPainter {
  final List<double> prices;
  final Color color;

  SimpleChartPainter(this.prices, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (prices.length < 2) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final minPrice = prices.reduce((a, b) => a < b ? a : b);
    final maxPrice = prices.reduce((a, b) => a > b ? a : b);
    final priceRange = maxPrice - minPrice;

    if (priceRange == 0) return;

    final path = Path();
    final spacing = size.width / (prices.length - 1);

    for (var i = 0; i < prices.length; i++) {
      final x = i * spacing;
      final y = size.height - ((prices[i] - minPrice) / priceRange * size.height * 0.8) - size.height * 0.1;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    // Fill area
    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withOpacity(0.3),
          color.withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}