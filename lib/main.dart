import 'package:flutter/material.dart';
import 'screens/main_scaffold.dart';

void main() {
  runApp(const FootballFeedApp());
}

class FootballFeedApp extends StatelessWidget {
  const FootballFeedApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Football Feed',
      theme: ThemeData(
        fontFamily: '-apple-system',
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Color(0xFF2374E1)),
        scaffoldBackgroundColor: Color(0xFF0A0A0A),
      ),
      home: const MainScaffold(),
      debugShowCheckedModeBanner: false,
    );
  }
}