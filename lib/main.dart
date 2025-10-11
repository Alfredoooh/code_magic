import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth_screen.dart';
import 'home_screens.dart';

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
  String _language = 'pt';

  void updateTheme(String theme) {
    setState(() {
      _themeMode = theme == 'dark' ? ThemeMode.dark : ThemeMode.light;
    });
  }

  void updateLanguage(String lang) {
    setState(() {
      _language = lang;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'K Paga',
      themeMode: _themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: Colors.orange,
        scaffoldBackgroundColor: Colors.white,
        cardColor: Color(0xFFF5F5F5),
        dividerColor: Color(0xFFE0E0E0),
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.orange,
        scaffoldBackgroundColor: Color(0xFF000000),
        cardColor: Color(0xFF1C1C1E),
        dividerColor: Color(0xFF38383A),
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF1C1C1E),
          elevation: 0,
        ),
      ),
      home: AuthGate(
        onThemeChange: updateTheme,
        onLanguageChange: updateLanguage,
        currentLanguage: _language,
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthGate extends StatelessWidget {
  final Function(String) onThemeChange;
  final Function(String) onLanguageChange;
  final String currentLanguage;

  AuthGate({
    required this.onThemeChange,
    required this.onLanguageChange,
    required this.currentLanguage,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return MainScreen(
            onThemeChange: onThemeChange,
            onLanguageChange: onLanguageChange,
            currentLanguage: currentLanguage,
          );
        }
        return LoginScreen();
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  final Function(String) onThemeChange;
  final Function(String) onLanguageChange;
  final String currentLanguage;

  MainScreen({
    required this.onThemeChange,
    required this.onLanguageChange,
    required this.currentLanguage,
  });

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  late List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _updateUserStatus(true);
    _screens = [
      HomeScreen(
        onThemeChange: widget.onThemeChange,
        onLanguageChange: widget.onLanguageChange,
        currentLanguage: widget.currentLanguage,
      ),
      MarketplaceScreen(),
      NewsScreen(),
      ChatScreen(),
    ];
  }

  @override
  void dispose() {
    _updateUserStatus(false);
    super.dispose();
  }

  void _updateUserStatus(bool isOnline) {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      FirebaseFirestore.instance.collection('userStatus').doc(user.uid).set({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  Widget _buildNavigator(int index) {
    return Navigator(
      key: _navigatorKeys[index],
      onGenerateRoute: (routeSettings) {
        return MaterialPageRoute(
          builder: (context) => _screens[index],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return !await _navigatorKeys[_currentIndex].currentState!.maybePop();
      },
      child: Scaffold(
        body: Stack(
          children: List.generate(4, (index) {
            return Offstage(
              offstage: _currentIndex != index,
              child: _buildNavigator(index),
            );
          }),
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) => setState(() => _currentIndex = index),
          backgroundColor: Theme.of(context).cardColor,
          indicatorColor: Colors.orange.withOpacity(0.2),
          destinations: [
            NavigationDestination(
              icon: Icon(CupertinoIcons.home),
              selectedIcon: Icon(CupertinoIcons.house_fill, color: Colors.orange),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(CupertinoIcons.bag),
              selectedIcon: Icon(CupertinoIcons.bag_fill, color: Colors.orange),
              label: 'Marketplace',
            ),
            NavigationDestination(
              icon: Icon(CupertinoIcons.news),
              selectedIcon: Icon(CupertinoIcons.news_solid, color: Colors.orange),
              label: 'Novidades',
            ),
            NavigationDestination(
              icon: Icon(CupertinoIcons.chat_bubble),
              selectedIcon: Icon(CupertinoIcons.chat_bubble_fill, color: Colors.orange),
              label: 'Chat',
            ),
          ],
        ),
      ),
    );
  }
}