import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import '../../services/theme_service.dart';

class ConverterTab extends StatefulWidget {
  @override
  State<ConverterTab> createState() => _ConverterTabState();
}

class _ConverterTabState extends State<ConverterTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThemeService.backgroundColor,
      appBar: AppBar(
        backgroundColor: ThemeService.backgroundColor,
        elevation: 0,
        title: Text(
          'Conversor',
          style: TextStyle(
            color: ThemeService.textColor,
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _tabController.animateTo(0),
                    child: AnimatedBuilder(
                      animation: _tabController,
                      builder: (context, child) {
                        final isSelected = _tabController.index == 0;
                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF1877F2)
                                : ThemeService.isDarkMode
                                    ? const Color(0xFF2C2C2E)
                                    : const Color(0xFFE5E5EA),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Center(
                            child: Text(
                              'Crypto',
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : ThemeService.textColor,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _tabController.animateTo(1),
                    child: AnimatedBuilder(
                      animation: _tabController,
                      builder: (context, child) {
                        final isSelected = _tabController.index == 1;
                        return Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF1877F2)
                                : ThemeService.isDarkMode
                                    ? const Color(0xFF2C2C2E)
                                    : const Color(0xFFE5E5EA),
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Center(
                            child: Text(
                              'Moedas',
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : ThemeService.textColor,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                CryptoConverter(),
                FiatConverter(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CryptoConverter extends StatefulWidget {
  @override
  State<CryptoConverter> createState() => _CryptoConverterState();
}

class _CryptoConverterState extends State<CryptoConverter> {
  final _amountController = TextEditingController(text: '1');
  String _fromCrypto = 'bitcoin';
  String _toCurrency = 'eur';
  double _result = 0;
  bool _isLoading = false;
  List<FlSpot> _chartData = [];
  Map<String, dynamic>? _cryptoInfo;

  final Map<String, String> _cryptos = {
    'bitcoin': 'BTC',
    'ethereum': 'ETH',
    'tether': 'USDT',
    'binancecoin': 'BNB',
    'cardano': 'ADA',
  };

  final Map<String, String> _currencies = {
    'eur': 'EUR',
    'usd': 'USD',
    'gbp': 'GBP',
    'aoa': 'AOA',
  };

  @override
  void initState() {
    super.initState();
    _convert();
  }

  Future<void> _convert() async {
    final amount = double.tryParse(_amountController.text) ?? 1;
    if (amount <= 0) return;

    setState(() => _isLoading = true);

    try {
      final priceResponse = await http.get(
        Uri.parse('https://api.coingecko.com/api/v3/simple/price?ids=$_fromCrypto&vs_currencies=$_toCurrency&include_24hr_change=true&include_market_cap=true'),
      );

      final chartResponse = await http.get(
        Uri.parse('https://api.coingecko.com/api/v3/coins/$_fromCrypto/market_chart?vs_currency=$_toCurrency&days=7'),
      );

      if (priceResponse.statusCode == 200 && chartResponse.statusCode == 200) {
        final priceData = json.decode(priceResponse.body);
        final chartData = json.decode(chartResponse.body);
        
        final price = priceData[_fromCrypto][_toCurrency];
        final change24h = priceData[_fromCrypto]['${_toCurrency}_24h_change'];
        final marketCap = priceData[_fromCrypto]['${_toCurrency}_market_cap'];

        final prices = chartData['prices'] as List;
        final spots = <FlSpot>[];
        for (int i = 0; i < prices.length; i += prices.length ~/ 20) {
          spots.add(FlSpot(i.toDouble(), prices[i][1].toDouble()));
        }

        if (mounted) {
          setState(() {
            _result = price * amount;
            _chartData = spots;
            _cryptoInfo = {
              'price': price,
              'change': change24h,
              'marketCap': marketCap,
            };
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Erro: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildConverterCard(),
          const SizedBox(height: 20),
          if (_cryptoInfo != null) _buildInfoCard(),
          const SizedBox(height: 20),
          if (_chartData.isNotEmpty) _buildChartCard(),
        ],
      ),
    );
  }

  Widget _buildConverterCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ThemeService.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: ThemeService.isDarkMode
              ? Colors.white.withOpacity(0.1)
              : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'De',
            style: TextStyle(
              color: ThemeService.textColor.withOpacity(0.6),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: ThemeService.isDarkMode
                        ? Colors.white.withOpacity(0.05)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(
                      color: ThemeService.textColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    onChanged: (_) => _convert(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1877F2).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButton<String>(
                    value: _fromCrypto,
                    isExpanded: true,
                    underline: Container(),
                    dropdownColor: ThemeService.cardColor,
                    icon: const Icon(CupertinoIcons.chevron_down, size: 16),
                    style: const TextStyle(
                      color: Color(0xFF1877F2),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    items: _cryptos.entries.map((entry) {
                      return DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _fromCrypto = value);
                        _convert();
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1877F2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                CupertinoIcons.arrow_down,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Para',
            style: TextStyle(
              color: ThemeService.textColor.withOpacity(0.6),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1877F2).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          child: Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : Text(
                          _result.toStringAsFixed(2),
                          style: const TextStyle(
                            color: Color(0xFF1877F2),
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: ThemeService.isDarkMode
                        ? Colors.white.withOpacity(0.05)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: DropdownButton<String>(
                    value: _toCurrency,
                    isExpanded: true,
                    underline: Container(),
                    dropdownColor: ThemeService.cardColor,
                    icon: const Icon(CupertinoIcons.chevron_down, size: 16),
                    style: TextStyle(
                      color: ThemeService.textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    items: _currencies.entries.map((entry) {
                      return DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _toCurrency = value);
                        _convert();
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    final price = _cryptoInfo!['price'];
    final change = _cryptoInfo!['change'];
    final marketCap = _cryptoInfo!['marketCap'];
    final isPositive = change >= 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ThemeService.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: ThemeService.isDarkMode
              ? Colors.white.withOpacity(0.1)
              : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informações de Mercado',
            style: TextStyle(
              color: ThemeService.textColor,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInfoItem(
                  'Preço Atual',
                  '${_currencies[_toCurrency]} ${price.toStringAsFixed(2)}',
                  CupertinoIcons.money_dollar_circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoItem(
                  'Variação 24h',
                  '${isPositive ? '+' : ''}${change.toStringAsFixed(2)}%',
                  isPositive ? CupertinoIcons.arrow_up : CupertinoIcons.arrow_down,
                  color: isPositive ? Colors.green : Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoItem(
            'Market Cap',
            '${_currencies[_toCurrency]} ${(marketCap / 1000000000).toStringAsFixed(2)}B',
            CupertinoIcons.chart_bar_circle,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon, {Color? color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (color ?? const Color(0xFF1877F2)).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color: color ?? const Color(0xFF1877F2),
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: ThemeService.textColor.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color ?? ThemeService.textColor,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ThemeService.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: ThemeService.isDarkMode
              ? Colors.white.withOpacity(0.1)
              : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gráfico (7 dias)',
            style: TextStyle(
              color: ThemeService.textColor,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: _chartData,
                    isCurved: true,
                    color: const Color(0xFF1877F2),
                    barWidth: 3,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF1877F2).withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
}

class FiatConverter extends StatefulWidget {
  @override
  State<FiatConverter> createState() => _FiatConverterState();
}

class _FiatConverterState extends State<FiatConverter> {
  final _amountController = TextEditingController(text: '100');
  String _fromCurrency = 'EUR';
  String _toCurrency = 'USD';
  double _result = 0;
  double _rate = 0;
  bool _isLoading = false;

  final List<String> _currencies = ['EUR', 'USD', 'GBP', 'AOA', 'BRL', 'JPY'];

  @override
  void initState() {
    super.initState();
    _convert();
  }

  Future<void> _convert() async {
    final amount = double.tryParse(_amountController.text) ?? 100;
    if (amount <= 0) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.get(
        Uri.parse('https://api.exchangerate-api.com/v4/latest/$_fromCurrency'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rates = data['rates'];
        final rate = rates[_toCurrency];

        if (mounted) {
          setState(() {
            _rate = rate;
            _result = amount * rate;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Erro: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: ThemeService.cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: ThemeService.isDarkMode
                    ? Colors.white.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'De',
                  style: TextStyle(
                    color: ThemeService.textColor.withOpacity(0.6),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: ThemeService.isDarkMode
                              ? Colors.white.withOpacity(0.05)
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: TextStyle(
                            color: ThemeService.textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          onChanged: (_) => _convert(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1877F2).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButton<String>(
                          value: _fromCurrency,
                          isExpanded: true,
                          underline: Container(),
                          dropdownColor: ThemeService.cardColor,
                          icon: const Icon(CupertinoIcons.chevron_down, size: 16),
                          style: const TextStyle(
                            color: Color(0xFF1877F2),
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          items: _currencies.map((currency) {
                            return DropdownMenuItem(
                              value: currency,
                              child: Text(currency),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null && value != _toCurrency) {
                              setState(() => _fromCurrency = value);
                              _convert();
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Center(
                  child: IconButton(
                    onPressed: () {
                      setState(() {
                        final temp = _fromCurrency;
                        _fromCurrency = _toCurrency;
                        _toCurrency = temp;
                      });
                      _convert();
                    },
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1877F2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        CupertinoIcons.arrow_up_arrow_down,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Para',
                  style: TextStyle(
                    color: ThemeService.textColor.withOpacity(0.6),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1877F2).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                child: Center(
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              )
                            : Text(
                                _result.toStringAsFixed(2),
                                style: const TextStyle(
                                  color: Color(0xFF1877F2),
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        decoration: BoxDecoration(
                          color: ThemeService.isDarkMode
                              ? Colors.white.withOpacity(0.05)
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButton<String>(
                          value: _toCurrency,
                          isExpanded: true,
                          underline: Container(),
                          dropdownColor: ThemeService.cardColor,
                          icon: const Icon(CupertinoIcons.chevron_down, size: 16),
                          style: TextStyle(
                            color: ThemeService.textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          items: _currencies.map((currency) {
                            return DropdownMenuItem(
                              value: currency,
                              child: Text(currency),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null && value != _fromCurrency) {
                              setState(() => _toCurrency = value);
                              _convert();
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_rate > 0) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: ThemeService.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: ThemeService.isDarkMode
                      ? Colors.white.withOpacity(0.1)
                      : Colors.grey.withOpacity(0.2),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '1 $_fromCurrency = ',
                    style: TextStyle(
                      color: ThemeService.textColor.withOpacity(0.6),
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '${_rate.toStringAsFixed(4)} $_toCurrency',
                    style: TextStyle(
                      color: ThemeService.textColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
}
