import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/auth_screen.dart';
import 'screens/main_screen.dart';
import 'models/app_theme.dart';
import 'models/app_localizations.dart';

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
  Locale _locale = Locale('pt', 'PT');

  @override
  void initState() {
    super.initState();
    _loadUserPreferences();
  }

  void _loadUserPreferences() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      if (userDoc.exists) {
        final data = userDoc.data()!;
        setState(() {
          _themeMode = data['theme'] == 'light' ? ThemeMode.light : ThemeMode.dark;
          String lang = data['language'] ?? 'pt';
          _locale = Locale(lang, lang == 'pt' ? 'PT' : lang == 'en' ? 'US' : 'ES');
        });
      }
    }
  }

  void updateTheme(ThemeMode mode) {
    setState(() => _themeMode = mode);
  }

  void updateLocale(Locale locale) {
    setState(() => _locale = locale);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'K Paga',
      themeMode: _themeMode,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      locale: _locale,
      supportedLocales: [
        Locale('pt', 'PT'),
        Locale('en', 'US'),
        Locale('es', 'ES'),
      ],
      localizationsDelegates: [
        AppLocalizations.delegate,
      ],
      home: AuthGate(
        onThemeChanged: updateTheme,
        onLocaleChanged: updateLocale,
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthGate extends StatelessWidget {
  final Function(ThemeMode) onThemeChanged;
  final Function(Locale) onLocaleChanged;

  AuthGate({required this.onThemeChanged, required this.onLocaleChanged});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return MainScreen(
            onThemeChanged: onThemeChanged,
            onLocaleChanged: onLocaleChanged,
          );
        }
        return AuthScreen();
      },
    );
  }
}