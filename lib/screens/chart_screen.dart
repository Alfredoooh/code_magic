import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import '../services/market_service.dart';
import '../widgets/design_system.dart';
import '../localization/app_localizations.dart';

class ChartScreen extends StatefulWidget {
  @override
  _ChartScreenState createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  final MarketService _marketService = MarketService();
  String _selectedTimeframe = '1d';
  List<charts.Series<OHLCData, DateTime>> _seriesList = [];
  List<String> _indicators = [];

  @override
  void initState() {
    super.initState();
    _fetchChartData('IBM'); // Placeholder asset
  }

  Future<void> _fetchChartData(String symbol) async {
    // Use Alpha Vantage for OHLC
    final response = await _marketService.getStockQuote(symbol);
    // Parse response to OHLCData class (define below)
    // _seriesList = createSeries(from response);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.translate('chart')!),
        actions: [
          DropdownButton<String>(
            value: _selectedTimeframe,
            items: ['1m', '5m', '15m', '1h', '1d', '1w', '1m'].map((tf) => DropdownMenuItem(value: tf, child: Text(tf))).toList(),
            onChanged: (value) {
              setState(() {
                _selectedTimeframe = value!;
                // Refetch data
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.add_chart_rounded),
            onPressed: () {
              // Open indicator selector
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(AppLocalizations.of(context)!.translate('add_indicator')!),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(title: Text('SMA'), onTap: () => _addIndicator('SMA')),
                      ListTile(title: Text('RSI'), onTap: () => _addIndicator('RSI')),
                      // More indicators
                    ],
                  ),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.draw_rounded),
            onPressed: () {
              // Enable drawing mode (placeholder)
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: charts.TimeSeriesChart(
              _seriesList,
              animate: true,
              behaviors: [
                charts.PanAndZoomBehavior(),
                charts.LinePointHighlighter(),
              ],
              dateTimeFactory: const charts.LocalDateTimeFactory(),
            ),
          ),
          // Order ticket panel
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(child: TextField(decoration: InputDecoration(labelText: AppLocalizations.of(context)!.translate('quantity')!))),
                  const SizedBox(width: 8),
                  CustomButton(text: AppLocalizations.of(context)!.translate('buy')!, color: success, onPressed: () {}),
                  const SizedBox(width: 8),
                  CustomButton(text: AppLocalizations.of(context)!.translate('sell')!, color: danger, onPressed: () {}),
                ],
              ),
            ),
          ),
          // Book of offers and time & sales
          ExpansionTile(
            title: Text(AppLocalizations.of(context)!.translate('order_book')!),
            children: [
              // List for bids and asks
              ListView.builder(
                shrinkWrap: true,
                itemCount: 10,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text('Price: $index.00'),
                    trailing: Text('Volume: 100'),
                  );
                },
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
      // Update series with new overlay
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
