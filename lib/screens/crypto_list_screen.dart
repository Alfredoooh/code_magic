// lib/screens/crypto_list_screen.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';
import '../widgets/app_ui_components.dart';
import '../widgets/app_colors.dart';

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

  // Ícones PNG dos mercados (URLs reais do Flaticon)
  final Map<String, String> _marketIcons = {
    'Criptomoedas': 'https://cdn-icons-png.flaticon.com/512/6001/6001527.png', // Bitcoin icon
    'Forex': 'https://cdn-icons-png.flaticon.com/512/8968/8968458.png', // Currency exchange
    'Ações': 'https://cdn-icons-png.flaticon.com/512/3588/3588592.png', // Stock market
    'Commodities': 'https://cdn-icons-png.flaticon.com/512/2331/2331966.png', // Gold bar
    'Índices': 'https://cdn-icons-png.flaticon.com/512/9195/9195886.png', // Chart graph
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
    AppBottomSheet.show(
      context,
      height: 480,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            const AppSectionTitle(text: 'Selecionar Mercado', fontSize: 18),
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: _marketIcons.entries.map((entry) {
                  return _buildMarketOption(entry.key, entry.value);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarketOption(String market, String iconUrl) {
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
              color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
              border: Border.all(
                color: isSelected ? AppColors.primary : Colors.grey.withOpacity(0.3),
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withOpacity(0.15)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Image.network(
                    iconUrl,
                    width: 24,
                    height: 24,
                    color: isSelected ? AppColors.primary : Colors.grey,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.category_outlined,
                      color: isSelected ? AppColors.primary : Colors.grey,
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
                      fontWeight: FontWeight.w600,
                      color: isSelected ? AppColors.primary : null,
                    ),
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.primary,
                    size: 20,
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
            icon: const Icon(Icons.more_vert),
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
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                ),
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    )
                  : _filteredCryptos.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              AppIconCircle(
                                icon: Icons.search_off,
                                size: 60,
                                iconColor: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Nenhum item encontrado',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 16,
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
      child: AppCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 28,
              alignment: Alignment.center,
              child: Text(
                '$rank',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
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
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '\$${crypto.price < 1 ? crypto.price.toStringAsFixed(6) : crypto.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
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
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositive ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                        color: isPositive ? Colors.green : Colors.red,
                        size: 18,
                      ),
                      Text(
                        '${crypto.priceChange.abs().toStringAsFixed(2)}%',
                        style: TextStyle(
                          color: isPositive ? Colors.green : Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
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
                    color: Colors.grey[600],
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

// Search Screen (renomeada para evitar conflito com widgets/search_screen.dart)
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
      appBar: const AppSecondaryAppBar(
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
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
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
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
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
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  Text(
                    '\$${crypto.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${isPositive ? '+' : ''}${crypto.priceChange.toStringAsFixed(2)}%',
              style: TextStyle(
                color: isPositive ? Colors.green : Colors.red,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Crypto Detail Screen
class CryptoDetailScreen extends StatefulWidget {
  final CryptoData crypto;

  const CryptoDetailScreen({Key? key, required this.crypto}) : super(key: key);

  @override
  _CryptoDetailScreenState createState() => _CryptoDetailScreenState();
}

class _CryptoDetailScreenState extends State<CryptoDetailScreen> {
  late WebViewController _chartController;
  late WebViewController _newsController;
  late WebViewController _technicalController;
  String _signal = 'NEUTRO';
  Color _signalColor = Colors.grey;

  @override
  void initState() {
    super.initState();
    _initWebViews();
    _calculateSignal();
  }

  void _calculateSignal() {
    if (widget.crypto.priceChange > 5) {
      _signal = 'COMPRAR';
      _signalColor = Colors.green;
    } else if (widget.crypto.priceChange < -5) {
      _signal = 'VENDER';
      _signalColor = Colors.red;
    } else {
      _signal = 'NEUTRO';
      _signalColor = Colors.grey;
    }
  }

  void _initWebViews() {
    final symbol = 'BINANCE:${widget.crypto.symbol}USDT';

    _chartController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadHtmlString('''
        <!DOCTYPE html>
        <html>
          <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>body { margin: 0; padding: 0; }</style>
          </head>
          <body>
            <div class="tradingview-widget-container">
              <div id="tradingview_chart"></div>
              <script type="text/javascript" src="https://s3.tradingview.com/tv.js"></script>
              <script type="text/javascript">
                new TradingView.widget({
                  "width": "100%",
                  "height": 400,
                  "symbol": "$symbol",
                  "interval": "D",
                  "timezone": "Etc/UTC",
                  "theme": "dark",
                  "style": "1",
                  "locale": "br",
                  "toolbar_bg": "#f1f3f6",
                  "enable_publishing": false,
                  "hide_side_toolbar": false,
                  "allow_symbol_change": true,
                  "container_id": "tradingview_chart"
                });
              </script>
            </div>
          </body>
        </html>
      ''');

    _newsController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadHtmlString('''
        <!DOCTYPE html>
        <html>
          <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>body { margin: 0; padding: 0; }</style>
          </head>
          <body>
            <div class="tradingview-widget-container">
              <div class="tradingview-widget-container__widget"></div>
              <script type="text/javascript" src="https://s3.tradingview.com/external-embedding/embed-widget-timeline.js" async>
              {
                "feedMode": "symbol",
                "symbol": "$symbol",
                "colorTheme": "dark",
                "isTransparent": false,
                "displayMode": "regular",
                "width": "100%",
                "height": 400,
                "locale": "br"
              }
              </script>
            </div>
          </body>
        </html>
      ''');

    _technicalController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadHtmlString('''
        <!DOCTYPE html>
        <html>
          <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>body { margin: 0; padding: 0; }</style>
          </head>
          <body>
            <div class="tradingview-widget-container">
              <div class="tradingview-widget-container__widget"></div>
              <script type="text/javascript" src="https://s3.tradingview.com/external-embedding/embed-widget-technical-analysis.js" async>
              {
                "interval": "1m",
                "width": "100%",
                "isTransparent": false,
                "height": 400,
                "symbol": "$symbol",
                "showIntervalTabs": true,
                "locale": "br",
                "colorTheme": "dark"
              }
              </script>
            </div>
          </body>
        </html>
      ''');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppSecondaryAppBar(
        title: widget.crypto.symbol,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Price Header
              AppCard(
                padding: const EdgeInsets.all(20),
                borderRadius: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Preço Atual',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '\$${widget.crypto.price < 1 ? widget.crypto.price.toStringAsFixed(6) : widget.crypto.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: _signalColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _signalColor, width: 2),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                _signal == 'COMPRAR'
                                    ? Icons.trending_up
                                    : _signal == 'VENDER'
                                        ? Icons.trending_down
                                        : Icons.remove,
                                color: _signalColor,
                                size: 20,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _signal,
                                style: TextStyle(
                                  color: _signalColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: widget.crypto.priceChange >= 0
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${widget.crypto.priceChange >= 0 ? '+' : ''}${widget.crypto.priceChange.toStringAsFixed(2)}% (24h)',
                        style: TextStyle(
                          color: widget.crypto.priceChange >= 0 ? Colors.green : Colors.red,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Chart Section
              _buildSection('Gráfico de Preço', isDark,
                  SizedBox(
                    height: 400,
                    child: WebViewWidget(controller: _chartController),
                  )),

              const SizedBox(height: 16),

              // Technical Analysis Section
              _buildSection('Análise Técnica', isDark,
                  SizedBox(
                    height: 400,
                    child: WebViewWidget(controller: _technicalController),
                  )),

              const SizedBox(height: 16),

              // News Section
              _buildSection('Notícias e Timeline', isDark,
                  SizedBox(
                    height: 400,
                    child: WebViewWidget(controller: _newsController),
                  )),

              const SizedBox(height: 16),

              // Market Stats
              _buildSection(
                'Estatísticas de Mercado',
                isDark,
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildStatRow('Volume 24h', '\$${_formatNumber(widget.crypto.volume)}', isDark),
                      const Divider(height: 24),
                      _buildStatRow(
                          'Máxima 24h', '\$${widget.crypto.high24h.toStringAsFixed(2)}', isDark),
                      const Divider(height: 24),
                      _buildStatRow(
                          'Mínima 24h', '\$${widget.crypto.low24h.toStringAsFixed(2)}', isDark),
                      const Divider(height: 24),
                      _buildStatRow(
                          'Variação 24h',
                          '${widget.crypto.priceChange >= 0 ? '+' : ''}${widget.crypto.priceChange.toStringAsFixed(2)}%',
                          isDark,
                          valueColor: widget.crypto.priceChange >= 0 ? Colors.green : Colors.red),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, bool isDark, Widget child) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: AppCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: AppSectionTitle(text: title, fontSize: 17),
            ),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, bool isDark, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: valueColor ?? (isDark ? Colors.white : Colors.black),
          ),
        ),
      ],
    );
  }

  String _formatNumber(double number) {
    if (number >= 1000000000) {
      return '${(number / 1000000000).toStringAsFixed(2)}B';
    } else if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(2)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(2)}K';
    }
    return number.toStringAsFixed(2);
  }
}

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