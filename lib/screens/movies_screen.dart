import 'package:flutter/material.dart';
import '../widgets/design_system.dart';
import '../localization/app_localizations.dart';

class MoviesScreen extends StatelessWidget {
  final List<Map<String, dynamic>> _movies = [
    {'title': 'The Big Short', 'price': 4.99},
    // Add more
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.translate('movies')!)),
      body: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2),
        itemCount: _movies.length,
        itemBuilder: (context, index) {
          final movie = _movies[index];
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Text(movie['title']),
                  const SizedBox(height: 8),
                  CustomButton(text: '\$${movie['price']}', onPressed: () {
                    // Purchase logic
                  }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}