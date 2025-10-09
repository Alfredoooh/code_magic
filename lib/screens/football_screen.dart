import 'package:flutter/material.dart';
import '../services/market_service.dart';
import '../widgets/design_system.dart';
import '../localization/app_localizations.dart';

class FootballScreen extends StatefulWidget {
  @override
  _FootballScreenState createState() => _FootballScreenState();
}

class _FootballScreenState extends State<FootballScreen> {
  final MarketService _marketService = MarketService();
  List<dynamic> _fixtures = [];

  @override
  void initState() {
    super.initState();
    _loadFixtures();
  }

  Future<void> _loadFixtures() async {
    _fixtures = await _marketService.getFootballFixtures();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.translate('football')!)),
      body: RefreshIndicator(
        onRefresh: _loadFixtures,
        child: ListView.builder(
          itemCount: _fixtures.length,
          itemBuilder: (context, index) {
            final fixture = _fixtures[index];
            return Card(
              child: ListTile(
                title: Text('${fixture['team1']} vs ${fixture['team2']}'),
                subtitle: Text(fixture['date']),
                trailing: Text(fixture['league']),
                onTap: () {
                  // Open live stats or stream placeholder
                },
              ),
            );
          },
        ),
      ),
    );
  }
}