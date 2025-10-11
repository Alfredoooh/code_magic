import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_screen.dart';
import 'chats_screen.dart';
import 'marketplace_screen.dart';
import 'news_screen.dart';
import '../services/language_service.dart';

class MainScreen extends StatefulWidget {
  final Function(ThemeMode) onThemeChanged;
  final Function(String) onLocaleChanged;
  final String currentLocale;

  const MainScreen({
    required this.onThemeChanged,
    required this.onLocaleChanged,
    required this.currentLocale,
  });

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  late List<Widget> _screens;
  late List<GlobalKey<NavigatorState>> _navigatorKeys;
  late PageController _pageController;
  Map<String, dynamic>? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _updateUserStatus(true);
    _pageController = PageController();
    
    // Initialize navigator keys for each tab to maintain state
    _navigatorKeys = [
      GlobalKey<NavigatorState>(),
      GlobalKey<NavigatorState>(),
      GlobalKey<NavigatorState>(),
      GlobalKey<NavigatorState>(),
    ];
    
    _screens = [
      HomeScreen(
        onThemeChanged: widget.onThemeChanged,
        onLocaleChanged: widget.onLocaleChanged,
        currentLocale: widget.currentLocale,
      ),
      MarketplaceScreen(),
      NewsScreen(),
      ChatsScreen(),
    ];
  }

  void _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        setState(() => _userData = doc.data());
      }
    }
  }

  void _updateUserStatus(bool online) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({
        'isOnline': online,
        'last_seen': FieldValue.serverTimestamp(),
      });
    }
  }

  @override
  void dispose() {
    _updateUserStatus(false);
    _pageController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    // Try to pop the current tab's navigator
    final isFirstRouteInCurrentTab = !await _navigatorKeys[_currentIndex].currentState!.maybePop();
    
    if (isFirstRouteInCurrentTab) {
      // If we're on the first route of the current tab
      if (_currentIndex != 0) {
        // If not on Home tab, go to Home
        setState(() => _currentIndex = 0);
        _pageController.jumpToPage(0);
        return false;
      }
      // If on Home tab, allow back button to exit
      return true;
    }
    
    // Navigator popped a route, don't exit
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: PageView.builder(
          controller: _pageController,
          physics: NeverScrollableScrollPhysics(),
          itemCount: _screens.length,
          onPageChanged: (index) {
            setState(() => _currentIndex = index);
          },
          itemBuilder: (context, index) {
            return Navigator(
              key: _navigatorKeys[index],
              onGenerateRoute: (routeSettings) {
                return MaterialPageRoute(
                  builder: (context) => _screens[index],
                );
              },
            );
          },
        ),
        bottomNavigationBar: Container(
          height: 62,
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (index) {
              if (_currentIndex == index) {
                // If tapping the same tab, pop to first route
                _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
              } else {
                setState(() => _currentIndex = index);
                _pageController.jumpToPage(index);
              }
            },
            height: 62,
            backgroundColor: Theme.of(context).brightness == Brightness.dark 
                ? Color(0xFF1A1A1A) 
                : Colors.white,
            indicatorColor: Color(0xFFFF444F).withOpacity(0.15),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            elevation: 0,
            destinations: [
              NavigationDestination(
                icon: Icon(Icons.home_rounded, size: 24),
                selectedIcon: Icon(Icons.home_rounded, color: Color(0xFFFF444F), size: 26),
                label: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.shopping_bag_rounded, size: 24),
                selectedIcon: Icon(Icons.shopping_bag_rounded, color: Color(0xFFFF444F), size: 26),
                label: 'Mercado',
              ),
              NavigationDestination(
                icon: Icon(Icons.article_rounded, size: 24),
                selectedIcon: Icon(Icons.article_rounded, color: Color(0xFFFF444F), size: 26),
                label: 'Notícias',
              ),
              NavigationDestination(
                icon: Icon(Icons.chat_rounded, size: 24),
                selectedIcon: Icon(Icons.chat_rounded, color: Color(0xFFFF444F), size: 26),
                label: 'Chat',
              ),
            ],
          ),
        ),
      ),
    );
  }
}