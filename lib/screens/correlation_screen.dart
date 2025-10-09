import 'package:flutter/material.dart';
import '../widgets/design_system.dart';
import '../localization/app_localizations.dart';

class CorrelationScreen extends StatefulWidget {
  @override
  _CorrelationScreenState createState() => _CorrelationScreenState();
}

class _CorrelationScreenState extends State<CorrelationScreen> {
  List<String> _assets = ['AAPL', 'GOOG'];
  // Matrix data

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.translate('correlation')!)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(AppLocalizations.of(context)!.translate('select_assets')!, style: Theme.of(context).textTheme.headlineSmall),
            // Add asset selector
            const SizedBox(height: 16),
            CustomButton(text: AppLocalizations.of(context)!.translate('calculate_correlation')!, onPressed: () {
              // Compute and show matrix
            }),
            // Show heatmap for correlation matrix
          ],
        ),
      ),
    );
  }
}