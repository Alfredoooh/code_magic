// all_markets_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'markets_screen.dart';
import 'trade_screen.dart';

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

class _AllMarketsScreenState extends State<AllMarketsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final Set<String> _favorites = {};

  final List<MarketCategory> _categories = [
    MarketCategory('Volatility', Icons.show_chart),
    MarketCategory('Boom/Crash', Icons.trending_up),
    MarketCategory('Jump', Icons.double_arrow),
    MarketCategory('Step', Icons.stairs),
    MarketCategory('Forex', Icons.attach_money),
    MarketCategory('Crypto', Icons.currency_bitcoin),
  ];

  final Map<String, MarketInfo> _forexMarkets = {
    'frxEURUSD': MarketInfo('EUR/USD', 'https://raw.githubusercontent.com/lipis/flag-icons/main/flags/4x3/eu.svg', 'Forex'),
    'frxGBPUSD': MarketInfo('GBP/USD', 'https://raw.githubusercontent.com/lipis/flag-icons/main/flags/4x3/gb.svg', 'Forex'),
    'frxUSDJPY': MarketInfo('USD/JPY', 'https://raw.githubusercontent.com/lipis/flag-icons/main/flags/4x3/jp.svg', 'Forex'),
    'frxAUDUSD': MarketInfo('AUD/USD', 'https://raw.githubusercontent.com/lipis/flag-icons/main/flags/4x3/au.svg', 'Forex'),
    'frxUSDCAD': MarketInfo('USD/CAD', 'https://raw.githubusercontent.com/lipis/flag-icons/main/flags/4x3/ca.svg', 'Forex'),
  };

  final Map<String, MarketInfo> _cryptoMarkets = {
    'cryBTCUSD': MarketInfo('Bitcoin', 'https://cryptologos.cc/logos/bitcoin-btc-logo.png', 'Crypto'),
    'cryETHUSD': MarketInfo('Ethereum', 'https://cryptologos.cc/logos/ethereum-eth-logo.png', 'Crypto'),
    'cryLTCUSD': MarketInfo('Litecoin', 'https://cryptologos.cc/logos/litecoin-ltc-logo.png', 'Crypto'),
    'cryXRPUSD': MarketInfo('Ripple', 'https://cryptologos.cc/logos/xrp-xrp-logo.png', 'Crypto'),
    'cryBNBUSD': MarketInfo('Binance Coin', 'https://cryptologos.cc/logos/bnb-bnb-logo.png', 'Crypto'),
    'cryADAUSD': MarketInfo('Cardano', 'https://cryptologos.cc/logos/cardano-ada-logo.png', 'Crypto'),
    'crySOLUSD': MarketInfo('Solana', 'https://cryptologos.cc/logos/solana-sol-logo.png', 'Crypto'),
    'cryDOTUSD': MarketInfo('Polkadot', 'https://cryptologos.cc/logos/polkadot-new-dot-logo.png', 'Crypto'),
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _subscribeToAllMarkets();
  }

  void _subscribeToAllMarkets() {
    if (widget.channel != null) {
      for (var symbol in [...widget.allMarkets.keys, ..._forexMarkets.keys, ..._cryptoMarkets.keys]) {
        widget.channel!.sink.add(json.encode({'ticks': symbol, 'subscribe': 1}));
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<MapEntry<String, MarketInfo>> _getFilteredMarkets(String category) {
    Map<String, MarketInfo> allMarketsMap = {
      ...widget.allMarkets,
      ..._forexMarkets,
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

  void _openMarket(String symbol) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => TradeScreen(
          token: widget.token,
          initialMarket: symbol,
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
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0A0A0A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Todos os Mercados',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _favorites.isEmpty ? Icons.star_border : Icons.star,
              color: _favorites.isEmpty ? Colors.white : Colors.amber,
            ),
            onPressed: () {},
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(110),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Buscar mercados...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                    prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.4)),
                    filled: true,
                    fillColor: const Color(0xFF151515),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),
              TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: const Color(0xFF0066FF),
                indicatorWeight: 3,
                labelColor: const Color(0xFF0066FF),
                unselectedLabelColor: Colors.white.withOpacity(0.5),
                labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                tabs: _categories.map((cat) => Tab(
                  child: Row(
                    children: [
                      Icon(cat.icon, size: 16),
                      const SizedBox(width: 6),
                      Text(cat.name),
                    ],
                  ),
                )).toList(),
              ),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _categories.map((category) {
          final markets = _getFilteredMarkets(category.name);
          
          if (markets.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off,
                    color: Colors.white.withOpacity(0.3),
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhum mercado encontrado',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: markets.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final entry = markets[index];
              final symbol = entry.key;
              final info = entry.value;
              final data = widget.marketData[symbol];
              
              return _buildMarketCard(symbol, info, data);
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMarketCard(String symbol, MarketInfo info, MarketData? data) {
    final isPositive = (data?.change ?? 0) >= 0;
    final color = isPositive ? const Color(0xFF00C896) : const Color(0xFFFF4444);
    final isFavorite = _favorites.contains(symbol);

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
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  isFavorite ? Icons.star : Icons.star_border,
                  color: isFavorite ? Colors.amber : Colors.white.withOpacity(0.3),
                  size: 20,
                ),
                onPressed: () {
                  setState(() {
                    if (isFavorite) {
                      _favorites.remove(symbol);
                    } else {
                      _favorites.add(symbol);
                    }
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MarketCategory {
  final String name;
  final IconData icon;

  MarketCategory(this.name, this.icon);
}