import 'package:flutter/material.dart';
import '../services/market_service.dart';
import '../widgets/design_system.dart';
import '../localization/app_localizations.dart';
import 'charts/chart_screen.dart';

class ScreenerScreen extends StatefulWidget {
  @override
  _ScreenerScreenState createState() => _ScreenerScreenState();
}

class _ScreenerScreenState extends State<ScreenerScreen> {
  final MarketService _marketService = MarketService();
  List<Map<String, dynamic>> _results = [];
  String _sector = 'All';
  double _minMarketCap = 0.0;
  // More filters

  Future<void> _runScreener() async {
    // Use API to fetch filtered stocks
    // _results = await _marketService.getFilteredStocks(filters);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.translate('screener')!),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(AppLocalizations.of(context)!.translate('filters')!, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: _sector,
              items: ['All', 'Tech', 'Finance', 'Health'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (value) {
                setState(() {
                  _sector = value!;
                });
              },
            ),
            // Add more filter inputs: market cap, P/E, etc.
            const SizedBox(height: 16),
            CustomButton(text: AppLocalizations.of(context)!.translate('run_screener')!, onPressed: _runScreener),
            const SizedBox(height: 24),
            Text(AppLocalizations.of(context)!.translate('results')!, style: Theme.of(context).textTheme.headlineSmall),
            Expanded(
              child: ListView.builder(
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final result = _results[index];
                  return ListTile(
                    title: Text(result['symbol']),
                    subtitle: Text('Market Cap: \$${result['marketCap']}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.add_rounded),
                      onPressed: () {
                        // Add to watchlist
                      },
                    ),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => ChartScreen()));
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}