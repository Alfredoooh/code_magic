// screens/marketplace_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class MarketplaceScreen extends StatelessWidget {
  final Map<String, dynamic>? userData;

  MarketplaceScreen({this.userData});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CupertinoPageScaffold(
      backgroundColor: isDark ? Color(0xFF0E0E0E) : Color(0xFFF5F5F5),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: isDark ? Color(0xFF1C1C1E) : Colors.white,
        middle: Text('Marketplace'),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_bag_rounded,
              size: 100,
              color: Color(0xFFFF444F).withOpacity(0.5),
            ),
            SizedBox(height: 20),
            Text(
              'Marketplace',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Color(0xFF0E0E0E),
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Em breve você poderá comprar e vender aqui',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
