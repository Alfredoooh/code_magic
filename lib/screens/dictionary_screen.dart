import 'package:flutter/material.dart';
import '../widgets/design_system.dart';
import '../localization/app_localizations.dart';

class DictionaryScreen extends StatefulWidget {
  @override
  _DictionaryScreenState createState() => _DictionaryScreenState();
}

class _DictionaryScreenState extends State<DictionaryScreen> {
  final _searchController = TextEditingController();
  Map<String, String> _dictionary = {
    'P/E': 'Price to Earnings ratio...',
    'RSI': 'Relative Strength Index...',
    // Add full dictionary
  };

  List<String> _filteredTerms = [];

  @override
  void initState() {
    super.initState();
    _filteredTerms = _dictionary.keys.toList();
    _searchController.addListener(_filterTerms);
  }

  void _filterTerms() {
    setState(() {
      _filteredTerms = _dictionary.keys.where((term) => term.toLowerCase().contains(_searchController.text.toLowerCase())).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.translate('dictionary')!)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: CustomTextField(
              controller: _searchController,
              label: AppLocalizations.of(context)!.translate('search_term')!,
              icon: Icons.search_rounded,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _filteredTerms.length,
              itemBuilder: (context, index) {
                final term = _filteredTerms[index];
                return ExpansionTile(
                  title: Text(term),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(_dictionary[term]!),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}