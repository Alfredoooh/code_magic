// markets_screen.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'trade_screen.dart';
import 'all_markets_screen.dart';
import 'news_detail_screen.dart';

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
  final Set<String> _favorites = {};

  // Top 5 mercados principais
  final List<String> _topMarkets = ['R_100', 'BOOM1000', 'CRASH1000', '1HZ100V', 'STPRNG'];

  final Map<String, MarketInfo> _allMarkets = {
    'R_10': MarketInfo('Volatility 10', 'https://raw.githubusercontent.com/alfredoooh/database/main/gallery/icons/v10.png', 'Volatility'),
    'R_25': MarketInfo('Volatility 25', 'https://raw.githubusercontent.com/alfredoooh/database/main/gallery/icons/v25.png', 'Volatility'),
    'R_50': MarketInfo('Volatility 50', 'https://raw.githubusercontent.com/alfredoooh/database/main/gallery/icons/v50.png', 'Volatility'),
    'R_75': MarketInfo('Volatility 75', 'https://raw.githubusercontent.com/alfredoooh/database/main/gallery/icons/v75.png', 'Volatility'),
    'R_100': MarketInfo('Volatility 100', 'https://raw.githubusercontent.com/alfredoooh/database/main/gallery/icons/v100.png', 'Volatility'),
    '1HZ10V': MarketInfo('Volatility 10 (1s)', 'https://raw.githubusercontent.com/alfredoooh/database/main/gallery/icons/v10-1s.png', 'Volatility'),
    '1HZ25V': MarketInfo('Volatility 25 (1s)', 'https://raw.githubusercontent.com/alfredoooh/database/main/gallery/icons/v25-1s.png', 'Volatility'),
    '1HZ50V': MarketInfo('Volatility 50 (1s)', 'https://raw.githubusercontent.com/alfredoooh/database/main/gallery/icons/v50-1s.png', 'Volatility'),
    '1HZ75V': MarketInfo('Volatility 75 (1s)', 'https://raw.githubusercontent.com/alfredoooh/database/main/gallery/icons/v75-1s.png', 'Volatility'),
    '1HZ100V': MarketInfo('Volatility 100 (1s)', 'https://raw.githubusercontent.com/alfredoooh/database/main/gallery/icons/v100-1s.png', 'Volatility'),
    'BOOM300N': MarketInfo('Boom 300', 'https://raw.githubusercontent.com/alfredoooh/database/main/gallery/icons/boom300.png', 'Boom/Crash'),
    'BOOM500': MarketInfo('Boom 500', 'https://raw.githubusercontent.com/alfredoooh/database/main/gallery/icons/boom500.png', 'Boom/Crash'),
    'BOOM600N': MarketInfo('Boom 600', 'https://raw.githubusercontent.com/alfredoooh/database/main/gallery/icons/boom600.png', 'Boom/Crash'),
    'BOOM900': MarketInfo('Boom 900', 'https://raw.githubusercontent.com/alfredoooh/database/main/gallery/icons/boom900.png', 'Boom/Crash'),
    'BOOM1000': MarketInfo('Boom 1000', 'https://raw.githubusercontent.com/alfredoooh/database/main/gallery/icons/boom1000.png', 'Boom/Crash'),
    'CRASH300N': MarketInfo('Crash 300', 'https://raw.githubusercontent.com/alfredoooh/database/main/gallery/icons/crash300.png', 'Boom/Crash'),
    'CRASH500': MarketInfo('Crash 500', 'https://raw.githubusercontent.com/alfredoooh/database/main/gallery/icons/crash500.png', 'Boom/Crash'),
    'CRASH600N': MarketInfo('Crash 600', 'https://raw.githubusercontent.com/alfredoooh/database/main/gallery/icons/crash600.png', 'Boom/Crash'),
    'CRASH900': MarketInfo('Crash 900', 'https://raw.githubusercontent.com/alfredoooh/database/main/gallery/icons/crash900.png', 'Boom/Crash'),
    'CRASH1000': MarketInfo('Crash 1000', 'https://raw.githubusercontent.com/alfredoooh/database/main/gallery/icons/crash1000.png', 'Boom/Crash'),
    'STPRNG': MarketInfo('Step Index', 'https://raw.githubusercontent.com/alfredoooh/database/main/gallery/icons/step.png', 'Step'),
    'JD10': MarketInfo('Jump 10', 'https://raw.githubusercontent.com/alfredoooh/database/main/gallery/icons/jump10.png', 'Jump'),
    'JD25': MarketInfo('Jump 25', 'https://raw.githubusercontent.com/alfredoooh/database/main/gallery/icons/jump25.png', 'Jump'),
    'JD50': MarketInfo('Jump 50', 'https://raw.githubusercontent.com/alfredoooh/database/main/gallery/icons/jump50.png', 'Jump'),
    'JD75': MarketInfo('Jump 75', 'https://raw.githubusercontent.com/alfredoooh/database/main/gallery/icons/jump75.png', 'Jump'),
    'JD100': MarketInfo('Jump 100', 'https://raw.githubusercontent.com/alfredoooh/database/main/gallery/icons/jump100.png', 'Jump'),
  };

  final List<NewsItem> _newsItems = [
    NewsItem(
      title: 'Bitcoin Atinge Nova Máxima Histórica',
      summary: 'BTC ultrapassa \$95,000 em meio a otimismo institucional',
      source: 'CoinDesk',
      favicon: 'https://www.coindesk.com/favicon.ico',
      time: '2h atrás',
      url: 'https://www.coindesk.com',
      category: 'Cripto',
    ),
    NewsItem(
      title: 'Fed Mantém Taxa de Juros Inalterada',
      summary: 'Decisão influencia mercados globais e volatilidade',
      source: 'Bloomberg',
      favicon: 'https://www.bloomberg.com/favicon.ico',
      time: '4h atrás',
      url: 'https://www.bloomberg.com',
      category: 'Economia',
    ),
    NewsItem(
      title: 'Ethereum 2.0: Próxima Atualização em Breve',
      summary: 'Rede promete maior eficiência e menores taxas de gas',
      source: 'CoinTelegraph',
      favicon: 'https://cointelegraph.com/favicon.ico',
      time: '5h atrás',
      url: 'https://cointelegraph.com',
      category: 'Cripto',
    ),
    NewsItem(
      title: 'Mercados Asiáticos em Alta',
      summary: 'Índices sobem com dados positivos de manufatura',
      source: 'Reuters',
      favicon: 'https://www.reuters.com/favicon.ico',
      time: '6h atrás',
      url: 'https://www.reuters.com',
      category: 'Mercados',
    ),
    NewsItem(
      title: 'Altcoins Ganham Momentum',
      summary: 'SOL, ADA e DOT lideram ganhos semanais',
      source: 'CryptoNews',
      favicon: 'https://cryptonews.com/favicon.ico',
      time: '8h atrás',
      url: 'https://cryptonews.com',
      category: 'Cripto',
    ),
    NewsItem(
      title: 'Volatilidade Aumenta em Índices Sintéticos',
      summary: 'Traders buscam oportunidades em mercados 24/7',
      source: 'Deriv Blog',
      favicon: 'https://deriv.com/favicon.ico',
      time: '10h atrás',
      url: 'https://blog.deriv.com',
      category: 'Trading',
    ),
  ];

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

      for (var symbol in _topMarkets) {
        _channel!.sink.add(json.encode({'ticks': symbol, 'subscribe': 1}));
      }
    } catch (e) {
      setState(() => _isConnected = false);
    }
  }

  void _openAllMarkets() {
    Navigator.of(context).push(
      IOSSlideUpRoute(
        builder: (context) => AllMarketsScreen(
          token: widget.token,
          allMarkets: _allMarkets,
          marketData: _marketData,
          channel: _channel,
        ),
      ),
    );
  }

  void _openNewsDetail(NewsItem news) {
    Navigator.of(context).push(
      IOSSlideUpRoute(
        builder: (context) => NewsDetailScreen(news: news),
      ),
    );
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
      backgroundColor: const Color(0xFF0A0A0A),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 20),
                  _buildTopMarketsSection(),
                  const SizedBox(height: 24),
                  _buildNewsSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mercados',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _isConnected ? const Color(0xFF00C896) : Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _isConnected ? 'Conectado' : 'Desconectado',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0066FF).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.search, color: Color(0xFF0066FF)),
            onPressed: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildTopMarketsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Top Mercados',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: _openAllMarkets,
              child: Row(
                children: [
                  Text(
                    'Ver Todos',
                    style: TextStyle(
                      color: const Color(0xFF0066FF),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Color(0xFF0066FF),
                    size: 14,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...(_topMarkets.map((symbol) {
          final info = _allMarkets[symbol]!;
          final data = _marketData[symbol];
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildCompactMarketCard(symbol, info, data),
          );
        }).toList()),
      ],
    );
  }

  Widget _buildCompactMarketCard(String symbol, MarketInfo info, MarketData? data) {
    final isPositive = (data?.change ?? 0) >= 0;
    final color = isPositive ? const Color(0xFF00C896) : const Color(0xFFFF4444);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openMarket(symbol),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF151515),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF0066FF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    info.iconUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.show_chart,
                      color: Color(0xFF0066FF),
                      size: 20,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      symbol,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
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
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(
                        isPositive ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                        color: color,
                        size: 18,
                      ),
                      Text(
                        data != null ? '${data.change.abs().toStringAsFixed(2)}%' : '0.00%',
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Notícias do Mercado',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ..._newsItems.map((news) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _buildNewsCard(news),
        )).toList(),
      ],
    );
  }

  Widget _buildNewsCard(NewsItem news) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openNewsDetail(news),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF151515),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    news.favicon,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.article,
                      color: Colors.white.withOpacity(0.3),
                      size: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0066FF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        news.category,
                        style: const TextStyle(
                          color: Color(0xFF0066FF),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      news.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      news.summary,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 12,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          news.source,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          ' • ',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          news.time,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.4),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: Colors.white.withOpacity(0.3),
                size: 20,
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
  final String category;

  MarketInfo(this.name, this.iconUrl, this.category);
}

class MarketData {
  final double price;
  final double change;
  final DateTime timestamp;

  MarketData({required this.price, required this.change, required this.timestamp});
}

class NewsItem {
  final String title;
  final String summary;
  final String source;
  final String favicon;
  final String time;
  final String url;
  final String category;

  NewsItem({
    required this.title,
    required this.summary,
    required this.source,
    required this.favicon,
    required this.time,
    required this.url,
    required this.category,
  });
}

class IOSSlideUpRoute extends PageRouteBuilder {
  final WidgetBuilder builder;

  IOSSlideUpRoute({required this.builder})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => builder(context),
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
          reverseTransitionDuration: const Duration(milliseconds: 300),
        );
}