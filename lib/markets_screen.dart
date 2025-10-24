// markets_screen.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http/http.dart' as http;
import 'trade_screen.dart';
import 'all_markets_screen.dart';
import 'news_detail_screen.dart';
import 'market_detail_screen.dart';

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
  List<NewsItem> _newsItems = [];
  bool _isLoadingNews = true;
  String? _newsError;

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

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
    _fetchCryptoNews();
  }

  @override
  void dispose() {
    _channel?.sink.close();
    super.dispose();
  }

  Future<void> _fetchCryptoNews() async {
    setState(() {
      _isLoadingNews = true;
      _newsError = null;
    });

    try {
      // CryptoPanic API - requer token gratuito em https://cryptopanic.com/developers/api/
      final response = await http.get(
        Uri.parse('https://cryptopanic.com/api/v1/posts/?auth_token=YOUR_API_TOKEN&public=true&kind=news'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;

        setState(() {
          _newsItems = results.map((item) {
            return NewsItem(
              title: item['title'],
              summary: item['title'],
              source: item['source']['title'],
              favicon: 'https://www.google.com/s2/favicons?domain=${item['source']['domain']}&sz=128',
              time: _formatTime(item['published_at']),
              url: item['url'],
              category: item['currencies']?.isNotEmpty == true ? item['currencies'][0]['code'] : 'NEWS',
              imageUrl: item['currencies']?.isNotEmpty == true 
                  ? 'https://cryptologos.cc/logos/${item['currencies'][0]['code'].toLowerCase()}-${item['currencies'][0]['slug']}-logo.png'
                  : null,
            );
          }).toList();
          _isLoadingNews = false;
        });
      } else {
        setState(() {
          _newsError = 'Erro ao carregar notícias. Código: ${response.statusCode}';
          _isLoadingNews = false;
        });
      }
    } catch (e) {
      setState(() {
        _newsError = 'Erro de conexão: ${e.toString()}';
        _isLoadingNews = false;
      });
    }
  }

  String _formatTime(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      final diff = DateTime.now().difference(date);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m';
      if (diff.inHours < 24) return '${diff.inHours}h';
      return '${diff.inDays}d';
    } catch (e) {
      return '';
    }
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

  void _openMarketDetail(String symbol) {
    Navigator.of(context).push(
      IOSSlideUpRoute(
        builder: (context) => MarketDetailScreen(
          symbol: symbol,
          marketInfo: _allMarkets[symbol]!,
          marketData: _marketData[symbol],
          token: widget.token,
          channel: _channel,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  const SizedBox(height: 24),
                  _buildTopMarketsSection(),
                  const SizedBox(height: 32),
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
    return const Text(
      'Mercados',
      style: TextStyle(
        color: Colors.white,
        fontSize: 34,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
      ),
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
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            GestureDetector(
              onTap: _openAllMarkets,
              child: const Text(
                'Ver Todos',
                style: TextStyle(
                  color: Color(0xFF007AFF),
                  fontSize: 17,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...(_topMarkets.map((symbol) {
          final info = _allMarkets[symbol]!;
          final data = _marketData[symbol];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildIOSMarketCard(symbol, info, data),
          );
        }).toList()),
      ],
    );
  }

  Widget _buildIOSMarketCard(String symbol, MarketInfo info, MarketData? data) {
    final isPositive = (data?.change ?? 0) >= 0;
    final changeColor = isPositive ? const Color(0xFF34C759) : const Color(0xFFFF3B30);

    return GestureDetector(
      onTap: () => _openMarketDetail(symbol),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                info.iconUrl,
                width: 40,
                height: 40,
                fit: BoxFit.cover,
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
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    symbol,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  data != null ? data.price.toStringAsFixed(2) : '...',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                if (data != null)
                  Text(
                    '${isPositive ? '+' : ''}${data.change.toStringAsFixed(2)}%',
                    style: TextStyle(
                      color: changeColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Notícias',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        if (_isLoadingNews)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(color: Color(0xFF007AFF)),
            ),
          )
        else if (_newsError != null)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  const Icon(Icons.error_outline, color: Color(0xFFFF3B30), size: 48),
                  const SizedBox(height: 16),
                  Text(
                    _newsError!,
                    style: TextStyle(color: Colors.white.withOpacity(0.6)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _fetchCryptoNews,
                    child: const Text('Tentar Novamente'),
                  ),
                ],
              ),
            ),
          )
        else if (_newsItems.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text(
                'Nenhuma notícia disponível',
                style: TextStyle(color: Colors.white.withOpacity(0.6)),
              ),
            ),
          )
        else
          _buildNewsGrid(),
      ],
    );
  }

  Widget _buildNewsGrid() {
    // Layouts variados tipo Google News
    return Column(
      children: [
        // Featured (primeira notícia grande)
        if (_newsItems.isNotEmpty)
          _buildFeaturedNews(_newsItems[0]),
        
        const SizedBox(height: 10),
        
        // Grid 2 colunas
        if (_newsItems.length > 1)
          Row(
            children: [
              if (_newsItems.length > 1)
                Expanded(child: _buildSmallNews(_newsItems[1])),
              if (_newsItems.length > 2)
                const SizedBox(width: 10),
              if (_newsItems.length > 2)
                Expanded(child: _buildSmallNews(_newsItems[2])),
            ],
          ),
        
        const SizedBox(height: 10),
        
        // Lista horizontal
        if (_newsItems.length > 3)
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _newsItems.length - 3,
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.only(right: index < _newsItems.length - 4 ? 10 : 0),
                  child: _buildHorizontalNews(_newsItems[index + 3]),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildFeaturedNews(NewsItem news) {
    return GestureDetector(
      onTap: () => _openNewsDetail(news),
      child: Container(
        height: 280,
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (news.imageUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  news.imageUrl!,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF007AFF).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      news.category,
                      style: const TextStyle(
                        color: Color(0xFF007AFF),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    news.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Image.network(
                        news.favicon,
                        width: 16,
                        height: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        news.source,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        ' • ${news.time}',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallNews(NewsItem news) {
    return GestureDetector(
      onTap: () => _openNewsDetail(news),
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (news.imageUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  news.imageUrl!,
                  height: 100,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  const Spacer(),
                  Row(
                    children: [
                      Image.network(
                        news.favicon,
                        width: 14,
                        height: 14,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          news.source,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalNews(NewsItem news) {
    return GestureDetector(
      onTap: () => _openNewsDetail(news),
      child: Container(
        width: 280,
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (news.imageUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  news.imageUrl!,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Image.network(
                        news.favicon,
                        width: 14,
                        height: 14,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${news.source} • ${news.time}',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
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
  final String? imageUrl;

  NewsItem({
    required this.title,
    required this.summary,
    required this.source,
    required this.favicon,
    required this.time,
    required this.url,
    required this.category,
    this.imageUrl,
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