import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/auth_screen.dart';
import 'screens/main_screen.dart';
import 'models/user_model.dart';
import 'services/theme_service.dart';
import 'services/language_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(ChatApp());
}

class ChatApp extends StatefulWidget {
  @override
  _ChatAppState createState() => _ChatAppState();
}

class _ChatAppState extends State<ChatApp> {
  ThemeMode _themeMode = ThemeMode.dark;
  String _locale = 'pt';

  @override
  void initState() {
    super.initState();
    _loadUserPreferences();
  }

  void _loadUserPreferences() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _themeMode = data['theme'] == 'light' ? ThemeMode.light : ThemeMode.dark;
          _locale = data['language'] ?? 'pt';
        });
      }
    }
  }

  void updateTheme(ThemeMode mode) {
    setState(() => _themeMode = mode);
  }

  void updateLocale(String locale) {
    setState(() => _locale = locale);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'K Paga',
      theme: ThemeService.lightTheme,
      darkTheme: ThemeService.darkTheme,
      themeMode: _themeMode,
      home: AuthGate(
        onThemeChanged: updateTheme,
        onLocaleChanged: updateLocale,
        currentLocale: _locale,
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthGate extends StatelessWidget {
  final Function(ThemeMode) onThemeChanged;
  final Function(String) onLocaleChanged;
  final String currentLocale;

  const AuthGate({
    required this.onThemeChanged,
    required this.onLocaleChanged,
    required this.currentLocale,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return MainScreen(
            onThemeChanged: onThemeChanged,
            onLocaleChanged: onLocaleChanged,
            currentLocale: currentLocale,
          );
        }
        return AuthScreen();
      },
    );
  }
}