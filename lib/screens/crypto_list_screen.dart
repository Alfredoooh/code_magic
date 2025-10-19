// lib/screens/crypto_list_screen.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../widgets/app_ui_components.dart';
import '../widgets/app_colors.dart';
import 'crypto_detail_screen.dart';

class CryptoListScreen extends StatefulWidget {
  const CryptoListScreen({Key? key}) : super(key: key);

  @override
  _CryptoListScreenState createState() => _CryptoListScreenState();
}

class _CryptoListScreenState extends State<CryptoListScreen> {
  List<CryptoData> _allCryptos = [];
  List<CryptoData> _filteredCryptos = [];
  bool _loading = true;
  Timer? _updateTimer;
  String _selectedMarket = 'Criptomoedas';

  final Map<String, String> _marketIcons = {
    'Criptomoedas': 'https://cdn-icons-png.flaticon.com/512/6001/6001527.png',
    'Forex': 'https://cdn-icons-png.flaticon.com/512/8968/8968458.png',
    'Ações': 'https://cdn-icons-png.flaticon.com/512/3588/3588592.png',
    'Commodities': 'https://cdn-icons-png.flaticon.com/512/2331/2331966.png',
    'Índices': 'https://cdn-icons-png.flaticon.com/512/9195/9195886.png',
  };

  @override
  void initState() {
    super.initState();
    _loadAllCryptos();
    _updateTimer = Timer.periodic(const Duration(seconds: 10), (_) => _loadAllCryptos());
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadAllCryptos() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.binance.com/api/v3/ticker/24hr'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final usdtPairs = data
            .where((coin) =>
                coin['symbol'].toString().endsWith('USDT') &&
                !coin['symbol'].toString().contains('DOWN') &&
                !coin['symbol'].toString().contains('UP') &&
                !coin['symbol'].toString().contains('BEAR') &&
                !coin['symbol'].toString().contains('BULL'))
            .toList();

        usdtPairs.sort((a, b) => double.parse(b['quoteVolume'].toString())
            .compareTo(double.parse(a['quoteVolume'].toString())));

        if (mounted) {
          setState(() {
            _allCryptos = usdtPairs.take(100).map((coin) => CryptoData.fromBinance(coin)).toList();
            _filteredCryptos = _allCryptos;
            _loading = false;
          });
        }
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _showMarketMenu(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: 480,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 20),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: AppSectionTitle(text: 'Selecionar Mercado', fontSize: 18),
            ),
            SizedBox(height: 16),
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 20),
                children: _marketIcons.entries.map((entry) {
                  return _buildMarketOption(entry.key, entry.value, isDark);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarketOption(String market, String iconUrl, bool isDark) {
    final isSelected = _selectedMarket == market;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() => _selectedMarket = market);
            Navigator.pop(context);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.15),
                        AppColors.primary.withOpacity(0.05),
                      ],
                    )
                  : null,
              color: !isSelected
                  ? (isDark ? AppColors.darkCard : AppColors.lightCard)
                  : null,
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withOpacity(0.15)
                        : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Image.network(
                    iconUrl,
                    width: 24,
                    height: 24,
                    color: isSelected ? AppColors.primary : Colors.grey.shade600,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.category_rounded,
                      color: isSelected ? AppColors.primary : Colors.grey.shade600,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    market,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? AppColors.primary
                          : (isDark ? Colors.white : Colors.black),
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openSearchScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CryptoSearchScreen(cryptos: _allCryptos),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppSecondaryAppBar(
        title: _selectedMarket,
        actions: [
          IconButton(
            icon: Icon(
              Icons.more_vert_rounded,
              color: isDark ? Colors.white : Colors.black,
            ),
            onPressed: () => _showMarketMenu(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: GestureDetector(
                onTap: _openSearchScreen,
                child: AppTextField(
                  hintText: 'Pesquisar...',
                  enabled: false,
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: Colors.grey.shade500,
                    size: 20,
                  ),
                ),
              ),
            ),
            Expanded(
              child: _loading
                  ? Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    )
                  : _filteredCryptos.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.primary.withOpacity(0.15),
                                      AppColors.primary.withOpacity(0.05),
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.search_off_rounded,
                                  size: 60,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Nenhum item encontrado',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          color: AppColors.primary,
                          onRefresh: _loadAllCryptos,
                          child: ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _filteredCryptos.length,
                            itemBuilder: (context, index) {
                              final crypto = _filteredCryptos[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildCryptoCard(crypto, isDark, index + 1),
                              );
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCryptoCard(CryptoData crypto, bool isDark, int rank) {
    final isPositive = crypto.priceChange >= 0;

    return GestureDetector(
      onTap: () => _showCryptoDetail(crypto),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(AppDesignConfig.cardRadius),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              alignment: Alignment.center,
              child: Text(
                '$rank',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade600,
                  letterSpacing: -0.2,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.15),
                    AppColors.primary.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              padding: const EdgeInsets.all(8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Image.network(
                  'https://cryptologos.cc/logos/${crypto.symbol.toLowerCase()}-${crypto.symbol.toLowerCase()}-logo.png',
                  errorBuilder: (context, error, stack) => Image.network(
                    'https://s2.coinmarketcap.com/static/img/coins/64x64/${_getCoinMarketCapId(crypto.symbol)}.png',
                    errorBuilder: (context, error, stack) => Image.network(
                      'https://cdn-icons-png.flaticon.com/512/7385/7385505.png',
                      color: AppColors.primary,
                    ),
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
                    crypto.symbol,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '\$${crypto.price < 1 ? crypto.price.toStringAsFixed(6) : crypto.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isPositive
                        ? AppColors.success.withOpacity(0.15)
                        : AppColors.error.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isPositive
                          ? AppColors.success.withOpacity(0.3)
                          : AppColors.error.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositive ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded,
                        color: isPositive ? AppColors.success : AppColors.error,
                        size: 18,
                      ),
                      Text(
                        '${crypto.priceChange.abs().toStringAsFixed(2)}%',
                        style: TextStyle(
                          color: isPositive ? AppColors.success : AppColors.error,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '24h',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getCoinMarketCapId(String symbol) {
    final Map<String, String> ids = {
      'BTC': '1',
      'ETH': '1027',
      'BNB': '1839',
      'XRP': '52',
      'ADA': '2010',
      'DOGE': '74',
      'SOL': '5426',
      'DOT': '6636',
      'MATIC': '3890',
      'AVAX': '5805',
    };
    return ids[symbol] ?? '1';
  }

  void _showCryptoDetail(CryptoData crypto) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CryptoDetailScreen(crypto: crypto),
        fullscreenDialog: true,
      ),
    );
  }
}

// Search Screen
class CryptoSearchScreen extends StatefulWidget {
  final List<CryptoData> cryptos;

  const CryptoSearchScreen({Key? key, required this.cryptos}) : super(key: key);

  @override
  _CryptoSearchScreenState createState() => _CryptoSearchScreenState();
}

class _CryptoSearchScreenState extends State<CryptoSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<CryptoData> _filteredCryptos = [];

  @override
  void initState() {
    super.initState();
    _filteredCryptos = widget.cryptos;
    _searchController.addListener(_filterCryptos);
  }

  void _filterCryptos() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredCryptos = widget.cryptos;
      } else {
        _filteredCryptos = widget.cryptos
            .where((crypto) => crypto.symbol.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppSecondaryAppBar(
        title: 'Pesquisar',
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: AppTextField(
                controller: _searchController,
                hintText: 'Digite para pesquisar...',
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: Colors.grey.shade500,
                  size: 20,
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear_rounded,
                          color: Colors.grey.shade500,
                          size: 20,
                        ),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                physics: BouncingScrollPhysics(),
                itemCount: _filteredCryptos.length,
                itemBuilder: (context, index) {
                  final crypto = _filteredCryptos[index];
                  return _buildSearchResult(crypto, isDark);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResult(CryptoData crypto, bool isDark) {
    final isPositive = crypto.priceChange >= 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(AppDesignConfig.cardRadius),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.15),
                    AppColors.primary.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.all(8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  'https://cryptologos.cc/logos/${crypto.symbol.toLowerCase()}-${crypto.symbol.toLowerCase()}-logo.png',
                  errorBuilder: (context, error, stack) => Image.network(
                    'https://cdn-icons-png.flaticon.com/512/7385/7385505.png',
                    color: AppColors.primary,
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
                    crypto.symbol,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    '\$${crypto.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${isPositive ? '+' : ''}${crypto.priceChange.toStringAsFixed(2)}%',
              style: TextStyle(
                color: isPositive ? AppColors.success : AppColors.error,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Model
class CryptoData {
  final String symbol;
  final double price;
  final double priceChange;
  final double volume;
  final double high24h;
  final double low24h;

  CryptoData({
    required this.symbol,
    required this.price,
    required this.priceChange,
    required this.volume,
    required this.high24h,
    required this.low24h,
  });

  factory CryptoData.fromBinance(Map<String, dynamic> json) {
    final symbol = json['symbol'].toString().replaceAll('USDT', '');
    final price = double.parse(json['lastPrice'].toString());
    final priceChange = double.parse(json['priceChangePercent'].toString());
    final volume = double.parse(json['quoteVolume'].toString());
    final high24h = double.parse(json['highPrice'].toString());
    final low24h = double.parse(json['lowPrice'].toString());

    return CryptoData(
      symbol: symbol,
      price: price,
      priceChange: priceChange,
      volume: volume,
      high24h: high24h,
      low24h: low24h,
    );
  }
}