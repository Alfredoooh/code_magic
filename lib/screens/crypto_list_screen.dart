// lib/screens/crypto_list_screen.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';

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
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadAllCryptos();
    _updateTimer = Timer.periodic(Duration(seconds: 10), (_) => _loadAllCryptos());
    _searchController.addListener(_filterCryptos);
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _filterCryptos() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredCryptos = _allCryptos;
      } else {
        _filteredCryptos = _allCryptos
            .where((crypto) => crypto.symbol.toLowerCase().contains(query))
            .toList();
      }
    });
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
            'Criptomoedas',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? CupertinoColors.white : CupertinoColors.black,
            ),
          ),
          border: null,
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: CupertinoSearchTextField(
                  controller: _searchController,
                  placeholder: 'Pesquisar criptomoeda...',
                  style: TextStyle(
                    color: isDark ? CupertinoColors.white : CupertinoColors.black,
                  ),
                  backgroundColor: isDark ? Color(0xFF1A1A1A) : CupertinoColors.white,
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
                                  'Nenhuma criptomoeda encontrada',
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
              child: Center(
                child: Image.network(
                  'https://cryptoicons.org/api/icon/${crypto.symbol.toLowerCase()}/32',
                  width: 32,
                  height: 32,
                  errorBuilder: (context, error, stack) => Text(
                    crypto.symbol.substring(0, 1),
                    style: TextStyle(
                      color: Color(0xFFFF444F),
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
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
            Container(
              width: 100,
              height: 50,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: crypto.sparkline.asMap().entries.map((e) {
                        return FlSpot(e.key.toDouble(), e.value);
                      }).toList(),
                      isCurved: true,
                      colors: [
                        isPositive ? CupertinoColors.systemGreen : CupertinoColors.systemRed
                      ],
                      barWidth: 2,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 12),
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

  void _showCryptoDetail(CryptoData crypto, bool isDark) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: isDark ? Color(0xFF1A1A1A) : CupertinoColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Color(0xFFFF444F).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Center(
                            child: Image.network(
                              'https://cryptoicons.org/api/icon/${crypto.symbol.toLowerCase()}/32',
                              width: 32,
                              height: 32,
                              errorBuilder: (context, error, stack) => Text(
                                crypto.symbol.substring(0, 1),
                                style: TextStyle(
                                  color: Color(0xFFFF444F),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          crypto.symbol,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isDark ? CupertinoColors.white : CupertinoColors.black,
                          ),
                        ),
                      ],
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: Icon(CupertinoIcons.xmark_circle_fill,
                          color: CupertinoColors.systemGrey),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(20),
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
                      Text(
                        '\$${crypto.price < 1 ? crypto.price.toStringAsFixed(6) : crypto.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: isDark ? CupertinoColors.white : CupertinoColors.black,
                        ),
                      ),
                      SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: crypto.priceChange >= 0
                              ? CupertinoColors.systemGreen.withOpacity(0.1)
                              : CupertinoColors.systemRed.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${crypto.priceChange >= 0 ? '+' : ''}${crypto.priceChange.toStringAsFixed(2)}% (24h)',
                          style: TextStyle(
                            color: crypto.priceChange >= 0
                                ? CupertinoColors.systemGreen
                                : CupertinoColors.systemRed,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(height: 32),
                      Text(
                        'Gráfico de Preço',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? CupertinoColors.white : CupertinoColors.black,
                        ),
                      ),
                      SizedBox(height: 16),
                      Container(
                        height: 200,
                        child: LineChart(
                          LineChartData(
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval: 1,
                              getDrawingHorizontalLine: (value) {
                                return FlLine(
                                  color: CupertinoColors.systemGrey.withOpacity(0.1),
                                  strokeWidth: 1,
                                );
                              },
                            ),
                            titlesData: FlTitlesData(show: false),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                spots: crypto.sparkline.asMap().entries.map((e) {
                                  return FlSpot(e.key.toDouble(), e.value);
                                }).toList(),
                                isCurved: true,
                                colors: [
                                  crypto.priceChange >= 0 ? CupertinoColors.systemGreen : CupertinoColors.systemRed
                                ],
                                barWidth: 3,
                                dotData: FlDotData(show: false),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: (crypto.priceChange >= 0
                                          ? CupertinoColors.systemGreen
                                          : CupertinoColors.systemRed)
                                      .withOpacity(0.1),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 32),
                      _buildInfoRow('Volume 24h', '\$${crypto.volume.toStringAsFixed(0)}', isDark),
                      SizedBox(height: 16),
                      _buildInfoRow('Máxima 24h', '\$${crypto.high24h.toStringAsFixed(2)}', isDark),
                      SizedBox(height: 16),
                      _buildInfoRow('Mínima 24h', '\$${crypto.low24h.toStringAsFixed(2)}', isDark),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isDark) {
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
            color: isDark ? CupertinoColors.white : CupertinoColors.black,
          ),
        ),
      ],
    );
  }
}

class CryptoData {
  final String symbol;
  final double price;
  final double priceChange;
  final List<double> sparkline;
  final double volume;
  final double high24h;
  final double low24h;

  CryptoData({
    required this.symbol,
    required this.price,
    required this.priceChange,
    required this.sparkline,
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

    List<double> sparkline = [];
    for (int i = 0; i < 20; i++) {
      sparkline.add(price * (1 + (priceChange / 100) * (i / 20)));
    }

    return CryptoData(
      symbol: symbol,
      price: price,
      priceChange: priceChange,
      sparkline: sparkline,
      volume: volume,
      high24h: high24h,
      low24h: low24h,
    );
  }
}