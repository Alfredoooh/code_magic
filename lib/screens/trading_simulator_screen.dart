import 'package:flutter/material.dart';
import '../widgets/design_system.dart';
import '../localization/app_localizations.dart';

class TradingSimulatorScreen extends StatefulWidget {
  @override
  _TradingSimulatorScreenState createState() => _TradingSimulatorScreenState();
}

class _TradingSimulatorScreenState extends State<TradingSimulatorScreen> {
  double _score = 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.translate('trading_simulator')!)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(AppLocalizations.of(context)!.translate('score')! + ': $_score'),
            const SizedBox(height: 16),
            CustomButton(text: AppLocalizations.of(context)!.translate('start_game')!, onPressed: () {
              // Start game logic, update score
            }),
          ],
        ),
      ),
    );
  }
}