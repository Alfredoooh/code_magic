import 'package:flutter/material.dart';
import '../services/market_service.dart';
import '../widgets/design_system.dart';
import '../localization/app_localizations.dart';

class ResearcherScreen extends StatefulWidget {
  @override
  _ResearcherScreenState createState() => _ResearcherScreenState();
}

class _ResearcherScreenState extends State<ResearcherScreen> {
  final _searchController = TextEditingController();
  final MarketService _marketService = MarketService();
  Map<String, dynamic> _result = {};

  Future<void> _search() async {
    if (_searchController.text.isEmpty) return;
    // Use NLU or simple search
    final quote = await _marketService.getStockQuote(_searchController.text);
    setState(() {
      _result = quote;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.translate('researcher')!)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CustomTextField(
              controller: _searchController,
              label: AppLocalizations.of(context)!.translate('search_query')!,
              icon: Icons.search_rounded,
              onSubmitted: (_) => _search(),
            ),
            const SizedBox(height: 16),
            CustomButton(text: AppLocalizations.of(context)!.translate('search')!, onPressed: _search),
            const SizedBox(height: 24),
            if (_result.isNotEmpty)
              GlassCard(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppLocalizations.of(context)!.translate('results')!, style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 8),
                      Text('Price: \$${_result['price']}'),
                      Text('Change: ${_result['change']}%'),
                      // More details
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}