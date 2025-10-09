import 'package:flutter/material.dart';
import '../../services/market_service.dart';
import '../../widgets/design_system.dart';
import '../../localization/app_localizations.dart';

class ConverterScreen extends StatefulWidget {
  @override
  _ConverterScreenState createState() => _ConverterScreenState();
}

class _ConverterScreenState extends State<ConverterScreen> {
  final MarketService _marketService = MarketService();
  String _from = 'USD';
  String _to = 'BRL';
  double _amount = 0.0;
  double _result = 0.0;

  Future<void> _convert() async {
    // Use API for conversion rate
    // _result = _amount * rate;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.translate('converter')!)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    value: _from,
                    items: ['USD', 'EUR', 'BTC'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (value) => setState(() => _from = value!),
                  ),
                ),
                const Icon(Icons.swap_horiz_rounded),
                Expanded(
                  child: DropdownButton<String>(
                    value: _to,
                    items: ['BRL', 'EUR', 'ETH'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (value) => setState(() => _to = value!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: AppLocalizations.of(context)!.translate('amount')!,
              icon: Icons.numbers_rounded,
              onChanged: (value) => _amount = double.tryParse(value) ?? 0.0,
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: AppLocalizations.of(context)!.translate('convert')!,
              onPressed: _convert,
            ),
            const SizedBox(height: 16),
            Text('${AppLocalizations.of(context)!.translate('result')!}: $_result'),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: SparklineChart(data: [1.0, 1.1, 1.05, 1.2, 1.15, 1.3]),
            ),
          ],
        ),
      ),
    );
  }
}