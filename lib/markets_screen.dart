// markets_screen.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
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

  final Map<String, String> _allMarkets = {
    // Volatility Indices
    'R_10': 'Volatility 10 Index',
    'R_25': 'Volatility 25 Index',
    'R_50': 'Volatility 50 Index',
    'R_75': 'Volatility 75 Index',
    'R_100': 'Volatility 100 Index',
    '1HZ10V': 'Volatility 10 (1s) Index',
    '1HZ25V': 'Volatility 25 (1s) Index',
    '1HZ50V': 'Volatility 50 (1s) Index',
    '1HZ75V': 'Volatility 75 (1s) Index',
    '1HZ100V': 'Volatility 100 (1s) Index',
    
    // Crash/Boom Indices
    'BOOM300N': 'Boom 300 Index',
    'BOOM500': 'Boom 500 Index',
    'BOOM600N': 'Boom 600 Index',
    'BOOM900': 'Boom 900 Index',
    'BOOM1000': 'Boom 1000 Index',
    'CRASH300N': 'Crash 300 Index',
    'CRASH500': 'Crash 500 Index',
    'CRASH600N': 'Crash 600 Index',
    'CRASH900': 'Crash 900 Index',
    'CRASH1000': 'Crash 1000 Index',
    
    // Step Indices
    'STPRNG': 'Step Index',
    
    // Jump Indices
    'JD10': 'Jump 10 Index',
    'JD25': 'Jump 25 Index',
    'JD50': 'Jump 50 Index',
    'JD75': 'Jump 75 Index',
    'JD100': 'Jump 100 Index',
    'JD150': 'Jump 150 Index',
    'JD200': 'Jump 200 Index',
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
                  final name = entry.value;
                  final data = _marketData[symbol];

                  return _buildMarketCard(symbol, name, data);
                },
              ),
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Color(0xFF0066FF)),
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

  Widget _buildMarketCard(String symbol, String name, MarketData? data) {
    final isPositive = (data?.change ?? 0) >= 0;
    final color = isPositive ? const Color(0xFF00C896) : const Color(0xFFFF4444);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TradeScreen(
              token: widget.token,
              initialMarket: symbol,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isPositive ? Icons.trending_up : Icons.trending_down,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    symbol,
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
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
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    data != null
                        ? '${isPositive ? '+' : ''}${data.change.toStringAsFixed(2)}%'
                        : '0.00%',
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
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