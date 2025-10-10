import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../services/market_service.dart';
import '../../widgets/design_system.dart';
import '../../localization/app_localizations.dart';

class ChartScreen extends StatefulWidget {
  @override
  _ChartScreenState createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  final MarketService _marketService = MarketService();
  String _selectedTimeframe = '1d';
  List<String> _indicators = [];
  List<OHLCData> _ohlcData = [];

  @override
  void initState() {
    super.initState();
    _fetchChartData('IBM');
  }

  Future<void> _fetchChartData(String symbol) async {
    // Use Alpha Vantage for OHLC
    final response = await _marketService.getStockQuote(symbol);
    // Parse response to OHLCData
    // _ohlcData = parseResponse(response);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.translate('charts')!),
        actions: [
          DropdownButton<String>(
            value: _selectedTimeframe,
            items: ['1m', '5m', '15m', '1h', '1d', '1w', '1M']
                .map((tf) => DropdownMenuItem(value: tf, child: Text(tf)))
                .toList(),
            onChanged: (value) {
              setState(() {
                _selectedTimeframe = value!;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_chart_rounded),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(AppLocalizations.of(context)!.translate('add_indicator')!),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(title: Text('SMA'), onTap: () => _addIndicator('SMA')),
                      ListTile(title: Text('RSI'), onTap: () => _addIndicator('RSI')),
                      ListTile(title: Text('MACD'), onTap: () => _addIndicator('MACD')),
                      ListTile(title: Text('Bollinger Bands'), onTap: () => _addIndicator('BB')),
                    ],
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.draw_rounded),
            onPressed: () {
              // Enable drawing mode
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: CandlestickChart(data: _ohlcData),
            ),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.translate('quantity')!,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CustomButton(
                    text: AppLocalizations.of(context)!.translate('buy')!,
                    color: success,
                    onPressed: () {},
                  ),
                  const SizedBox(width: 8),
                  CustomButton(
                    text: AppLocalizations.of(context)!.translate('sell')!,
                    color: danger,
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
          ExpansionTile(
            title: Text(AppLocalizations.of(context)!.translate('orders')!),
            children: [
              SizedBox(
                height: 200,
                child: ListView.builder(
                  itemCount: 10,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text('Price: ${100 + index}.00'),
                      trailing: Text('Volume: ${100 * (index + 1)}'),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _addIndicator(String indicator) {
    setState(() {
      _indicators.add(indicator);
    });
    Navigator.pop(context);
  }
}

class OHLCData {
  final DateTime time;
  final double open;
  final double high;
  final double low;
  final double close;

  OHLCData(this.time, this.open, this.high, this.low, this.close);
}

class CandlestickChart extends StatelessWidget {
  final List<OHLCData> data;

  const CandlestickChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Center(child: Text('No data available'));
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(show: true),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true),
          ),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: data.asMap().entries.map((e) {
              return FlSpot(e.key.toDouble(), e.value.close);
            }).toList(),
            isCurved: false,
            color: success,
            barWidth: 2,
            dotData: FlDotData(show: false),
          ),
        ],
      ),
    );
  }
}