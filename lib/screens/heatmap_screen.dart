import 'package:flutter/material.dart';
import '../services/market_service.dart';
import '../widgets/design_system.dart';
import '../localization/app_localizations.dart';
import 'charts/chart_screen.dart';

class HeatmapScreen extends StatefulWidget {
  @override
  _HeatmapScreenState createState() => _HeatmapScreenState();
}

class _HeatmapScreenState extends State<HeatmapScreen> {
  final MarketService _marketService = MarketService();
  List<Map<String, dynamic>> _data = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // Fetch market data for heatmap
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.translate('heatmaps')!)),
      body: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, childAspectRatio: 1.0),
        itemCount: _data.length,
        itemBuilder: (context, index) {
          final item = _data[index];
          final change = item['change'] ?? 0.0;
          final color = change > 0 ? success.withOpacity(0.7) : danger.withOpacity(0.7);
          return GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => ChartScreen()));
            },
            child: Container(
              color: color,
              child: Center(child: Text(item['symbol'] ?? 'Symbol')),
            ),
          );
        },
      ),
    );
  }
}