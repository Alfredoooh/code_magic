import 'package:flutter/material.dart';
import '../widgets/design_system.dart';
import '../localization/app_localizations.dart';

class PaperTradingScreen extends StatefulWidget {
  @override
  _PaperTradingScreenState createState() => _PaperTradingScreenState();
}

class _PaperTradingScreenState extends State<PaperTradingScreen> {
  double _balance = 100000.0;
  List<Map<String, dynamic>> _positions = [];

  void _placeOrder(String asset, double amount, double price, String type) {
    // Simulate order execution
    setState(() {
      _balance -= amount * price;
      _positions.add({'asset': asset, 'amount': amount, 'price': price, 'type': type});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.translate('paper_trading')!)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${AppLocalizations.of(context)!.translate('balance')!}: \$${ _balance.toStringAsFixed(2)}', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 24),
            Text(AppLocalizations.of(context)!.translate('positions')!, style: Theme.of(context).textTheme.headlineSmall),
            Expanded(
              child: ListView.builder(
                itemCount: _positions.length,
                itemBuilder: (context, index) {
                  final pos = _positions[index];
                  return ListTile(
                    title: Text(pos['asset']),
                    subtitle: Text('Amount: ${pos['amount']} at \$${pos['price']} - ${pos['type']}'),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: AppLocalizations.of(context)!.translate('place_order')!,
              onPressed: () {
                // Open order ticket dialog
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(AppLocalizations.of(context)!.translate('place_order')!),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomTextField(label: AppLocalizations.of(context)!.translate('asset')!, icon: Icons.trending_up_rounded),
                        CustomTextField(label: AppLocalizations.of(context)!.translate('amount')!, icon: Icons.numbers_rounded),
                        CustomTextField(label: AppLocalizations.of(context)!.translate('price')!, icon: Icons.attach_money_rounded),
                      ],
                    ),
                    actions: [
                      CustomButton(text: AppLocalizations.of(context)!.translate('buy')!, color: success, onPressed: () {
                        // Parse inputs and call _placeOrder
                        Navigator.pop(context);
                      }),
                      CustomButton(text: AppLocalizations.of(context)!.translate('sell')!, color: danger, onPressed: () {
                        // Parse and call
                        Navigator.pop(context);
                      }),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}