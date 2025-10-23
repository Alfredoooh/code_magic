// markets_screen.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'trade_screen.dart';

class MarketsScreen extends StatefulWidget {
  final String token;

  const MarketsScreen({Key? key, required this.token}) : super(key: key);

  @override
  State<MarketsScreen> createState() => _MarketsScreenState();
}

class _MarketsScreenState extends State<MarketsScreen> with AutomaticKeepAliveClientMixin {
  WebSocketChannel? _channel;
  final Map<String, MarketData> _marketData = {};
  bool _isConnected = false;

  final Map<String, MarketInfo> _allMarkets = {
    // Volatility Indices
    'R_10': MarketInfo('Volatility 10 Index', 'https://alfredoooh.github.io/database/gallery/icons/v10.png'),
    'R_25': MarketInfo('Volatility 25 Index', 'https://alfredoooh.github.io/database/gallery/icons/v25.png'),
    'R_50': MarketInfo('Volatility 50 Index', 'https://alfredoooh.github.io/database/gallery/icons/v50.png'),
    'R_75': MarketInfo('Volatility 75 Index', 'https://alfredoooh.github.io/database/gallery/icons/v75.png'),
    'R_100': MarketInfo('Volatility 100 Index', 'https://alfredoooh.github.io/database/gallery/icons/v100.png'),
    '1HZ10V': MarketInfo('Volatility 10 (1s) Index', 'https://alfredoooh.github.io/database/gallery/icons/v10-1s.png'),
    '1HZ25V': MarketInfo('Volatility 25 (1s) Index', 'https://alfredoooh.github.io/database/gallery/icons/v25-1s.png'),
    '1HZ50V': MarketInfo('Volatility 50 (1s) Index', 'https://alfredoooh.github.io/database/gallery/icons/v50-1s.png'),
    '1HZ75V': MarketInfo('Volatility 75 (1s) Index', 'https://alfredoooh.github.io/database/gallery/icons/v75-1s.png'),
    '1HZ100V': MarketInfo('Volatility 100 (1s) Index', 'https://alfredoooh.github.io/database/gallery/icons/v100-1s.png'),
    
    // Crash/Boom Indices
    'BOOM300N': MarketInfo('Boom 300 Index', 'https://alfredoooh.github.io/database/gallery/icons/boom300.png'),
    'BOOM500': MarketInfo('Boom 500 Index', 'https://alfredoooh.github.io/database/gallery/icons/boom500.png'),
    'BOOM600N': MarketInfo('Boom 600 Index', 'https://alfredoooh.github.io/database/gallery/icons/boom600.png'),
    'BOOM900': MarketInfo('Boom 900 Index', 'https://alfredoooh.github.io/database/gallery/icons/boom900.png'),
    'BOOM1000': MarketInfo('Boom 1000 Index', 'https://alfredoooh.github.io/database/gallery/icons/boom1000.png'),
    'CRASH300N': MarketInfo('Crash 300 Index', 'https://alfredoooh.github.io/database/gallery/icons/crash300.png'),
    'CRASH500': MarketInfo('Crash 500 Index', 'https://alfredoooh.github.io/database/gallery/icons/crash500.png'),
    'CRASH600N': MarketInfo('Crash 600 Index', 'https://alfredoooh.github.io/database/gallery/icons/crash600.png'),
    'CRASH900': MarketInfo('Crash 900 Index', 'https://alfredoooh.github.io/database/gallery/icons/crash900.png'),
    'CRASH1000': MarketInfo('Crash 1000 Index', 'https://alfredoooh.github.io/database/gallery/icons/crash1000.png'),
    
    // Step Indices
    'STPRNG': MarketInfo('Step Index', 'https://alfredoooh.github.io/database/gallery/icons/step.png'),
    
    // Jump Indices
    'JD10': MarketInfo('Jump 10 Index', 'https://alfredoooh.github.io/database/gallery/icons/jump10.png'),
    'JD25': MarketInfo('Jump 25 Index', 'https://alfredoooh.github.io/database/gallery/icons/jump25.png'),
    'JD50': MarketInfo('Jump 50 Index', 'https://alfredoooh.github.io/database/gallery/icons/jump50.png'),
    'JD75': MarketInfo('Jump 75 Index', 'https://alfredoooh.github.io/database/gallery/icons/jump75.png'),
    'JD100': MarketInfo('Jump 100 Index', 'https://alfredoooh.github.io/database/gallery/icons/jump100.png'),
    'JD150': MarketInfo('Jump 150 Index', 'https://alfredoooh.github.io/database/gallery/icons/jump150.png'),
    'JD200': MarketInfo('Jump 200 Index', 'https://alfredoooh.github.io/database/gallery/icons/jump200.png'),
  };

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
  }

  @override
  void dispose() {
    _channel?.sink.close();
    super.dispose();
  }

  void _connectWebSocket() {
    try {
      _channel = WebSocketChannel.connect(
        Uri.parse('wss://ws.derivws.com/websockets/v3?app_id=71954'),
      );

      setState(() => _isConnected = true);

      _channel!.stream.listen(
        (message) {
          final data = json.decode(message);
          
          if (data['msg_type'] == 'tick') {
            final tick = data['tick'];
            final symbol = tick['symbol'];
            final quote = double.parse(tick['quote'].toString());
            
            setState(() {
              if (_marketData.containsKey(symbol)) {
                final oldPrice = _marketData[symbol]!.price;
                _marketData[symbol] = MarketData(
                  price: quote,
                  change: ((quote - oldPrice) / oldPrice) * 100,
                  timestamp: DateTime.now(),
                );
              } else {
                _marketData[symbol] = MarketData(
                  price: quote,
                  change: 0.0,
                  timestamp: DateTime.now(),
                );
              }
            });
          }
        },
        onError: (error) => setState(() => _isConnected = false),
        onDone: () {
          setState(() => _isConnected = false);
          Future.delayed(const Duration(seconds: 3), _connectWebSocket);
        },
      );

      // Subscribe to all markets
      for (var symbol in _allMarkets.keys) {
        _channel!.sink.add(json.encode({
          'ticks': symbol,
          'subscribe': 1,
        }));
      }
    } catch (e) {
      setState(() => _isConnected = false);
    }
  }

  void _openMarket(String symbol) {
    Navigator.of(context).push(
      IOSSlideUpRoute(
        builder: (context) => TradeScreen(
          token: widget.token,
          initialMarket: symbol,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isConnected
          ? RefreshIndicator(
              onRefresh: () async {
                _channel?.sink.close();
                await Future.delayed(const Duration(milliseconds: 500));
                _connectWebSocket();
              },
              color: const Color(0xFF0066FF),
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _allMarkets.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final entry = _allMarkets.entries.elementAt(index);
                  final symbol = entry.key;
                  final info = entry.value;
                  final data = _marketData[symbol];

                  return _buildMarketCard(symbol, info, data);
                },
              ),
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CupertinoActivityIndicator(
                    color: Color(0xFF0066FF),
                    radius: 16,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Conectando aos mercados...',
                    style: TextStyle(color: Colors.white54),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildMarketCard(String symbol, MarketInfo info, MarketData? data) {
    final isPositive = (data?.change ?? 0) >= 0;
    final color = isPositive ? const Color(0xFF00C896) : const Color(0xFFFF4444);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openMarket(symbol),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Ícone circular com imagem PNG
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFF0066FF).withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF0066FF).withOpacity(0.2),
                    width: 2,
                  ),
                ),
                padding: const EdgeInsets.all(8),
                child: ClipOval(
                  child: Image.network(
                    info.iconUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.show_chart,
                        color: const Color(0xFF0066FF),
                        size: 28,
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CupertinoActivityIndicator(
                          radius: 10,
                          color: const Color(0xFF0066FF),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      symbol,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    data != null ? data.price.toStringAsFixed(2) : '--',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: color.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                          color: color,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          data != null
                              ? '${data.change.abs().toStringAsFixed(2)}%'
                              : '0.00%',
                          style: TextStyle(
                            color: color,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MarketInfo {
  final String name;
  final String iconUrl;

  MarketInfo(this.name, this.iconUrl);
}

class MarketData {
  final double price;
  final double change;
  final DateTime timestamp;

  MarketData({
    required this.price,
    required this.change,
    required this.timestamp,
  });
}

// Animação iOS Slide Up - Deslizar de baixo para cima
class IOSSlideUpRoute extends PageRouteBuilder {
  final WidgetBuilder builder;

  IOSSlideUpRoute({required this.builder})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => builder(context),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Curva de animação nativa do iOS
            const curve = Curves.easeOutCubic;
            var curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: curve,
            );

            // Animação de deslizar de baixo para cima
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 1.0), // Começa embaixo
                end: Offset.zero, // Termina na posição normal
              ).animate(curvedAnimation),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 350),
          reverseTransitionDuration: const Duration(milliseconds: 300),
        );
}