import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:webview_flutter/webview_flutter.dart';

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

  @override
  void initState() {
    super.initState();
    _loadAllCryptos();
    _updateTimer = Timer.periodic(Duration(seconds: 10), (_) => _loadAllCryptos());
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
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _showMarketMenu(BuildContext context, bool isDark) {
    showCupertinoModalPopup(
      context: context,
      builder: (BuildContext context) => CupertinoActionSheet(
        title: Text(
          'Selecionar Mercado',
          style: TextStyle(
            fontSize: 13,
            color: CupertinoColors.systemGrey,
          ),
        ),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _selectedMarket = 'Criptomoedas');
              Navigator.pop(context);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.                Icon(CupertinoIcons.bitcoin_circle_fill, size: 22),, size: 22),
                SizedBox(width: 8),
                Text('Criptomoedas'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _selectedMarket = 'Forex');
              Navigator.pop(context);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.money_dollar_circle, size: 22),
                SizedBox(width: 8),
                Text('Forex'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _selectedMarket = 'Ações');
              Navigator.pop(context);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.chart_bar_square, size: 22),
                SizedBox(width: 8),
                Text('Ações'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _selectedMarket = 'Commodities');
              Navigator.pop(context);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.cube_box, size: 22),
                SizedBox(width: 8),
                Text('Commodities'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              setState(() => _selectedMarket = 'Índices');
              Navigator.pop(context);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.graph_circle, size: 22),
                SizedBox(width: 8),
                Text('Índices'),
              ],
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDestructiveAction: true,
          onPressed: () => Navigator.pop(context),
          child: Text('Cancelar'),
        ),
      ),
    );
  }

  void _openSearchScreen() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            SearchScreen(cryptos: _allCryptos),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop();
        return false;
      },
      child: CupertinoPageScaffold(
        backgroundColor: isDark ? Color(0xFF0E0E0E) : Color(0xFFF5F5F5),
        navigationBar: CupertinoNavigationBar(
          backgroundColor: isDark ? Color(0xFF1A1A1A) : CupertinoColors.white,
          leading: CupertinoButton(
            padding: EdgeInsets.zero,
            child: Icon(
              CupertinoIcons.back,
              color: isDark ? CupertinoColors.white : CupertinoColors.black,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          middle: Text(
            _selectedMarket,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? CupertinoColors.white : CupertinoColors.black,
            ),
          ),
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            child: Icon(
              CupertinoIcons.ellipsis_circle,
              color: isDark ? CupertinoColors.white : CupertinoColors.black,
              size: 28,
            ),
            onPressed: () => _showMarketMenu(context, isDark),
          ),
          border: null,
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: GestureDetector(
                  onTap: _openSearchScreen,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? Color(0xFF1A1A1A) : CupertinoColors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          CupertinoIcons.search,
                          color: CupertinoColors.systemGrey,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Pesquisar...',
                          style: TextStyle(
                            color: CupertinoColors.systemGrey,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _loading
                    ? Center(child: CupertinoActivityIndicator(radius: 20))
                    : _filteredCryptos.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  CupertinoIcons.search,
                                  size: 60,
                                  color: CupertinoColors.systemGrey,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  'Nenhum item encontrado',
                                  style: TextStyle(
                                    color: CupertinoColors.systemGrey,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : CustomScrollView(
                            physics: BouncingScrollPhysics(),
                            slivers: [
                              CupertinoSliverRefreshControl(
                                onRefresh: _loadAllCryptos,
                              ),
                              SliverPadding(
                                padding: EdgeInsets.symmetric(horizontal: 16),
                                sliver: SliverList(
                                  delegate: SliverChildBuilderDelegate(
                                    (context, index) {
                                      final crypto = _filteredCryptos[index];
                                      return Padding(
                                        padding: EdgeInsets.only(bottom: 12),
                                        child: _buildCryptoCard(crypto, isDark, index + 1),
                                      );
                                    },
                                    childCount: _filteredCryptos.length,
                                  ),
                                ),
                              ),
                              SliverPadding(padding: EdgeInsets.only(bottom: 20)),
                            ],
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCryptoCard(CryptoData crypto, bool isDark, int rank) {
    final isPositive = crypto.priceChange >= 0;

    return GestureDetector(
      onTap: () => _showCryptoDetail(crypto, isDark),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Color(0xFF1A1A1A) : CupertinoColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              alignment: Alignment.center,
              child: Text(
                '$rank',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: CupertinoColors.systemGrey,
                ),
              ),
            ),
            SizedBox(width: 12),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Color(0xFFFF444F).withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.network(
                  'https://cryptologos.cc/logos/${crypto.symbol.toLowerCase()}-${crypto.symbol.toLowerCase()}-logo.png',
                  width: 32,
                  height: 32,
                  errorBuilder: (context, error, stack) => Image.network(
                    'https://s2.coinmarketcap.com/static/img/coins/64x64/${_getCoinMarketCapId(crypto.symbol)}.png',
                    width: 32,
                    height: 32,
                    errorBuilder: (context, error, stack) => Icon(
                      CupertinoIcons.bitcoin_circle_fill,
                      color: Color(0xFFFF444F),
                      size: 32,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    crypto.symbol,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? CupertinoColors.white : CupertinoColors.black,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '\$${crypto.price < 1 ? crypto.price.toStringAsFixed(6) : crypto.price.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isPositive
                        ? CupertinoColors.systemGreen.withOpacity(0.1)
                        : CupertinoColors.systemRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${isPositive ? '+' : ''}${crypto.priceChange.toStringAsFixed(2)}%',
                    style: TextStyle(
                      color: isPositive
                          ? CupertinoColors.systemGreen
                          : CupertinoColors.systemRed,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '24h',
                  style: TextStyle(
                    fontSize: 11,
                    color: CupertinoColors.systemGrey,
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

  void _showCryptoDetail(CryptoData crypto, bool isDark) {
    Navigator.of(context).push(
      CupertinoPageRoute(
        builder: (context) => CryptoDetailScreen(crypto: crypto),
        fullscreenDialog: true,
      ),
    );
  }
}

// Search Screen
class SearchScreen extends StatefulWidget {
  final List<CryptoData> cryptos;

  const SearchScreen({Key? key, required this.cryptos}) : super(key: key);

  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
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
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CupertinoPageScaffold(
      backgroundColor: isDark ? Color(0xFF0E0E0E) : Color(0xFFF5F5F5),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: isDark ? Color(0xFF1A1A1A) : CupertinoColors.white,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Text('Cancelar'),
          onPressed: () => Navigator.pop(context),
        ),
        middle: CupertinoSearchTextField(
          controller: _searchController,
          placeholder: 'Pesquisar...',
          autofocus: true,
          style: TextStyle(
            color: isDark ? CupertinoColors.white : CupertinoColors.black,
          ),
          backgroundColor: isDark ? Color(0xFF2A2A2A) : CupertinoColors.systemGrey6,
        ),
        border: null,
      ),
      child: SafeArea(
        child: ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: _filteredCryptos.length,
          itemBuilder: (context, index) {
            final crypto = _filteredCryptos[index];
            return _buildSearchResult(crypto, isDark);
          },
        ),
      ),
    );
  }

  Widget _buildSearchResult(CryptoData crypto, bool isDark) {
    final isPositive = crypto.priceChange >= 0;

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1A1A1A) : CupertinoColors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                'https://cryptologos.cc/logos/${crypto.symbol.toLowerCase()}-${crypto.symbol.toLowerCase()}-logo.png',
                errorBuilder: (context, error, stack) => Icon(
                  CupertinoIcons.bitcoin_circle_fill,
                  color: Color(0xFFFF444F),
                  size: 28,
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  crypto.symbol,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? CupertinoColors.white : CupertinoColors.black,
                  ),
                ),
                Text(
                  '\$${crypto.price.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isPositive ? '+' : ''}${crypto.priceChange.toStringAsFixed(2)}%',
            style: TextStyle(
              color: isPositive ? CupertinoColors.systemGreen : CupertinoColors.systemRed,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
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
  Color _signalColor = CupertinoColors.systemGrey;

  @override
  void initState() {
    super.initState();
    _initWebViews();
    _calculateSignal();
  }

  void _calculateSignal() {
    if (widget.crypto.priceChange > 5) {
      _signal = 'COMPRAR';
      _signalColor = CupertinoColors.systemGreen;
    } else if (widget.crypto.priceChange < -5) {
      _signal = 'VENDER';
      _signalColor = CupertinoColors.systemRed;
    } else {
      _signal = 'NEUTRO';
      _signalColor = CupertinoColors.systemGrey;
    }
  }

  void _initWebViews() {
    final symbol = 'BINANCE:${widget.crypto.symbol}USDT';

    // Chart Widget
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

    // News Widget
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

    // Technical Analysis Widget
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

    return CupertinoPageScaffold(
      backgroundColor: isDark ? Color(0xFF0E0E0E) : Color(0xFFF5F5F5),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: isDark ? Color(0xFF1A1A1A) : CupertinoColors.white,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(CupertinoIcons.back, color: isDark ? CupertinoColors.white : CupertinoColors.black),
          onPressed: () => Navigator.pop(context),
        ),
        middle: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  'https://cryptologos.cc/logos/${widget.crypto.symbol.toLowerCase()}-${widget.crypto.symbol.toLowerCase()}-logo.png',
                  errorBuilder: (context, error, stack) => Icon(
                    CupertinoIcons.bitcoin_circle_fill,
                    color: Color(0xFFFF444F),
                    size: 24,
                  ),
                ),
              ),
            ),
            SizedBox(width: 8),
            Text(
              widget.crypto.symbol,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? CupertinoColors.white : CupertinoColors.black,
              ),
            ),
          ],
        ),
        border: null,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Price Header
              Container(
                padding: EdgeInsets.all(20),
                color: isDark ? Color(0xFF1A1A1A) : CupertinoColors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Preço Atual',
                      style: TextStyle(
                        fontSize: 14,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '\$${widget.crypto.price < 1 ? widget.crypto.price.toStringAsFixed(6) : widget.crypto.price.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: isDark ? CupertinoColors.white : CupertinoColors.black,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: _signalColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _signalColor, width: 2),
                          ),
                          child: Column(
                            children: [
                              Icon(_signal == 'COMPRAR' ? CupertinoIcons.arrow_up : _signal == 'VENDER' ? CupertinoIcons.arrow_down : CupertinoIcons.minus, color: _signalColor, size: 20),
                              SizedBox(height: 4),
                              Text(
                                _signal,
                                style: TextStyle(
                                  color: _signalColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: widget.crypto.priceChange >= 0
                            ? CupertinoColors.systemGreen.withOpacity(0.1)
                            : CupertinoColors.systemRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${widget.crypto.priceChange >= 0 ? '+' : ''}${widget.crypto.priceChange.toStringAsFixed(2)}% (24h)',
                        style: TextStyle(
                          color: widget.crypto.priceChange >= 0
                              ? CupertinoColors.systemGreen
                              : CupertinoColors.systemRed,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 16),

              // Chart Section
              _buildSection('Gráfico de Preço', isDark, 
                Container(
                  height: 400,
                  child: WebViewWidget(controller: _chartController),
                ),
              ),

              SizedBox(height: 16),

              // Technical Analysis Section
              _buildSection('Análise Técnica', isDark,
                Container(
                  height: 400,
                  child: WebViewWidget(controller: _technicalController),
                ),
              ),

              SizedBox(height: 16),

              // News Section
              _buildSection('Notícias e Timeline', isDark,
                Container(
                  height: 400,
                  child: WebViewWidget(controller: _newsController),
                ),
              ),

              SizedBox(height: 16),

              // Market Stats
              _buildSection('Estatísticas de Mercado', isDark,
                Container(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildStatRow('Volume 24h', '\$${_formatNumber(widget.crypto.volume)}', isDark),
                      Divider(height: 24),
                      _buildStatRow('Máxima 24h', '\$${widget.crypto.high24h.toStringAsFixed(2)}', isDark),
                      Divider(height: 24),
                      _buildStatRow('Mínima 24h', '\$${widget.crypto.low24h.toStringAsFixed(2)}', isDark),
                      Divider(height: 24),
                      _buildStatRow('Variação 24h', '${widget.crypto.priceChange >= 0 ? '+' : ''}${widget.crypto.priceChange.toStringAsFixed(2)}%', isDark,
                        valueColor: widget.crypto.priceChange >= 0 ? CupertinoColors.systemGreen : CupertinoColors.systemRed),
                    ],
                  ),
                ),
              ),

              SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, bool isDark, Widget child) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1A1A1A) : CupertinoColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? CupertinoColors.white : CupertinoColors.black,
              ),
            ),
          ),
          child,
        ],
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
            fontSize: 16,
            color: CupertinoColors.systemGrey,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: valueColor ?? (isDark ? CupertinoColors.white : CupertinoColors.black),
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