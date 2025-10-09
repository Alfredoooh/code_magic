import 'package:flutter/material.dart';
import '../widgets/design_system.dart';
import '../localization/app_localizations.dart';

class BacktestingScreen extends StatefulWidget {
  @override
  _BacktestingScreenState createState() => _BacktestingScreenState();
}

class _BacktestingScreenState extends State<BacktestingScreen> {
  String _selectedStrategy = '';
  String _asset = '';
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 365));
  DateTime _endDate = DateTime.now();
  bool _isRunning = false;

  Future<void> _runBacktest() async {
    setState(() => _isRunning = true);
    // Call API or local calculation for backtest
    await Future.delayed(const Duration(seconds: 2)); // Placeholder
    setState(() => _isRunning = false);
    // Show results
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.translate('backtest_results')!),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Sharpe Ratio: 1.5'),
            Text('Max Drawdown: 10%'),
            // More metrics
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context)!.translate('close')!)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.translate('backtesting')!)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(AppLocalizations.of(context)!.translate('select_strategy')!, style: Theme.of(context).textTheme.bodyLarge),
            DropdownButton<String>(
              value: _selectedStrategy,
              items: ['Strategy1', 'Strategy2'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedStrategy = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            CustomTextField(label: AppLocalizations.of(context)!.translate('asset')!, icon: Icons.trending_up_rounded, onChanged: (value) => _asset = value),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(AppLocalizations.of(context)!.translate('start_date')!),
                ),
                TextButton(
                  onPressed: () async {
                    final date = await showDatePicker(context: context, initialDate: _startDate, firstDate: DateTime(2000), lastDate: DateTime.now());
                    if (date != null) setState(() => _startDate = date);
                  },
                  child: Text(_startDate.toIso8601String().split('T')[0]),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Text(AppLocalizations.of(context)!.translate('end_date')!),
                ),
                TextButton(
                  onPressed: () async {
                    final date = await showDatePicker(context: context, initialDate: _endDate, firstDate: DateTime(2000), lastDate: DateTime.now());
                    if (date != null) setState(() => _endDate = date);
                  },
                  child: Text(_endDate.toIso8601String().split('T')[0]),
                ),
              ],
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: _isRunning ? '' : AppLocalizations.of(context)!.translate('run_backtest')!,
              isLoading: _isRunning,
              onPressed: _runBacktest,
            ),
          ],
        ),
      ),
    );
  }
}