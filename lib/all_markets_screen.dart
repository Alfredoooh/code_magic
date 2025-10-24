// all_markets_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'markets_screen.dart';
import 'market_detail_screen.dart';

class AllMarketsScreen extends StatefulWidget {
  final String token;
  final Map<String, MarketInfo> allMarkets;
  final Map<String, MarketData> marketData;
  final WebSocketChannel? channel;

  const AllMarketsScreen({
    Key? key,
    required this.token,
    required this.allMarkets,
    required this.marketData,
    this.channel,
  }) : super(key: key);

  @override
  State<AllMarketsScreen> createState() => _AllMarketsScreenState();
}

class _AllMarketsScreenState extends State<AllMarketsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'Boom/Crash';

  final List<String> _categories = [
    'Boom/Crash',
    'Volatility',
    'Jump',
    'Step',
    'Crypto',
  ];

  final Map<String, MarketInfo> _cryptoMarkets = {
    'cryBTCUSD': MarketInfo('Bitcoin', 'https://cryptologos.cc/logos/bitcoin-btc-logo.png', 'Crypto'),
    'cryETHUSD': MarketInfo('Ethereum', 'https://cryptologos.cc/logos/ethereum-eth-logo.png', 'Crypto'),
  };

  @override
  void initState() {
    super.initState();
    _subscribeToAllMarkets();
  }

  void _subscribeToAllMarkets() {
    if (widget.channel != null) {
      for (var symbol in [...widget.allMarkets.keys, ..._cryptoMarkets.keys]) {
        widget.channel!.sink.add(json.encode({'ticks': symbol, 'subscribe': 1}));
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MapEntry<String, MarketInfo>> _getFilteredMarkets(String category) {
    Map<String, MarketInfo> allMarketsMap = {
      ...widget.allMarkets,
      ..._cryptoMarkets,
    };

    var markets = allMarketsMap.entries.where((entry) {
      final matchesCategory = entry.value.category == category;
      final matchesSearch = _searchQuery.isEmpty ||
          entry.value.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          entry.key.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    markets.sort((a, b) => a.value.name.compareTo(b.value.name));
    return markets;
  }

  void _openMarketDetail(String symbol) {
    final info = widget.allMarkets[symbol] ?? _cryptoMarkets[symbol];
    if (info != null) {
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => MarketDetailScreen(
            symbol: symbol,
            marketInfo: info,
            marketData: widget.marketData[symbol],
            token: widget.token,
            channel: widget.channel,
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
  }

  @override
  Widget build(BuildContext context) {
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
        title: const Text(
          'Todos os Mercados',
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.4,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                  width: 0.5,
                ),
              ),
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Buscar mercados...',
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 15,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: Colors.white.withOpacity(0.4),
                  size: 20,
                ),
                filled: true,
                fillColor: const Color(0xFF1C1C1E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),

          // Category Filter
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                  width: 0.5,
                ),
              ),
            ),
            child: CupertinoSlidingSegmentedControl<String>(
              backgroundColor: const Color(0xFF1C1C1E),
              thumbColor: const Color(0xFF0066FF),
              groupValue: _selectedCategory,
              onValueChanged: (value) {
                if (value != null) {
                  setState(() => _selectedCategory = value);
                }
              },
              children: {
                for (var category in _categories)
                  category: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: Text(
                      category,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
              },
            ),
          ),

          // Markets List
          Expanded(
            child: Builder(
              builder: (context) {
                final markets = _getFilteredMarkets(_selectedCategory);

                if (markets.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          color: Colors.white.withOpacity(0.3),
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhum mercado encontrado',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: markets.length,
                  itemBuilder: (context, index) {
                    final entry = markets[index];
                    final symbol = entry.key;
                    final info = entry.value;
                    final data = widget.marketData[symbol];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _buildMarketCard(symbol, info, data),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketCard(String symbol, MarketInfo info, MarketData? data) {
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
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withOpacity(0.3),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}