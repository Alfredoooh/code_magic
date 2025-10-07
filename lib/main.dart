import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/auth_gate.dart';
import 'screens/main_screen.dart';
import 'services/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await ThemeService.init();
  runApp(ChatApp());
}

class ChatApp extends StatefulWidget {
  @override
  State<ChatApp> createState() => _ChatAppState();
}

class _ChatAppState extends State<ChatApp> {
  @override
  void initState() {
    super.initState();
    ThemeService.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    ThemeService.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Easify',
      theme: ThemeService.getThemeData(),
      home: AuthGate(),
      debugShowCheckedModeBanner: false,
      routes: {
        '/main': (context) => MainScreen(),
      },
    );
  }
}
