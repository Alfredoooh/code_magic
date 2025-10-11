import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/auth_screen.dart';
import 'screens/main_screen.dart';
import 'services/theme_service.dart';
import 'services/language_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(ChatApp());
}

class ChatApp extends StatefulWidget {
  @override
  State<ChatApp> createState() => _ChatAppState();
}

class _ChatAppState extends State<ChatApp> {
  ThemeMode _themeMode = ThemeMode.dark;
  String _language = 'pt';

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
        setState(() {
          _themeMode = doc.data()?['theme'] == 'light' ? ThemeMode.light : ThemeMode.dark;
          _language = doc.data()?['language'] ?? 'pt';
        });
      }
    }
  }

  void updateTheme(ThemeMode mode) {
    setState(() => _themeMode = mode);
  }

  void updateLanguage(String lang) {
    setState(() => _language = lang);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'K Paga',
      themeMode: _themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: Color(0xFFFF444F),
        scaffoldBackgroundColor: Color(0xFFF5F5F5),
        cardColor: Colors.white,
        dividerColor: Color(0xFFE0E0E0),
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFFF5F5F5),
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black87),
          titleTextStyle: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Color(0xFFFF444F),
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Color(0xFFFF444F),
        scaffoldBackgroundColor: Color(0xFF0E0E0E),
        cardColor: Color(0xFF1A1A1A),
        dividerColor: Color(0xFF2C2C2C),
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF0E0E0E),
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF1A1A1A),
          selectedItemColor: Color(0xFFFF444F),
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),
      ),
      home: AuthGate(
        onThemeChanged: updateTheme,
        onLanguageChanged: updateLanguage,
        currentLanguage: _language,
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthGate extends StatelessWidget {
  final Function(ThemeMode) onThemeChanged;
  final Function(String) onLanguageChanged;
  final String currentLanguage;

  const AuthGate({
    required this.onThemeChanged,
    required this.onLanguageChanged,
    required this.currentLanguage,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return MainScreen(
            onThemeChanged: onThemeChanged,
            onLanguageChanged: onLanguageChanged,
            currentLanguage: currentLanguage,
          );
        }
        return AuthScreen();
      },
    );
  }
}