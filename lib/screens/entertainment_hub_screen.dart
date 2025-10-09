import 'package:flutter/material.dart';
import '../widgets/design_system.dart';
import '../localization/app_localizations.dart';
import '../screens/trading_simulator_screen.dart';
import '../screens/quiz_screen.dart';
import '../screens/movies_screen.dart';

class EntertainmentHubScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.translate('entertainment')!)),
      body: GridView.count(
        crossAxisCount: 2,
        children: [
          Card(
            child: InkWell(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => TradingSimulatorScreen())),
              child: Center(child: Text(AppLocalizations.of(context)!.translate('trading_simulator')!)),
            ),
          ),
          Card(
            child: InkWell(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => QuizScreen())),
              child: Center(child: Text(AppLocalizations.of(context)!.translate('quiz')!)),
            ),
          ),
          Card(
            child: InkWell(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => MoviesScreen())),
              child: Center(child: Text(AppLocalizations.of(context)!.translate('movies')!)),
            ),
          ),
          // Add paid games, etc.
        ],
      ),
    );
  }
}