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

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late List<Widget> _screens;
  late List<GlobalKey<NavigatorState>> _navigatorKeys;
  late AnimationController _animationController;
  late Animation<double> _animation;
  Map<String, dynamic>? _userData;
  
  // Track if each tab's navigator has pushed routes
  final List<bool> _hasNavigatedInTab = [false, false, false, false];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _updateUserStatus(true);

    // Initialize animation controller for smooth transitions
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    // Initialize navigator keys for each tab to maintain state
    _navigatorKeys = List.generate(
      4,
      (index) => GlobalKey<NavigatorState>(),
    );

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
    _animationController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    // Try to pop the current tab's navigator
    final isFirstRouteInCurrentTab = !await _navigatorKeys[_currentIndex].currentState!.maybePop();

    if (isFirstRouteInCurrentTab) {
      // If we're on the first route of the current tab
      if (_currentIndex != 0) {
        // If not on Home tab, go to Home
        _onTabTapped(0);
        return false;
      }
      // If on Home tab, allow back button to exit
      return true;
    }

    // Navigator popped a route, don't exit
    return false;
  }

  void _onTabTapped(int index) {
    if (_currentIndex == index) {
      // If tapping the same tab, pop to first route
      _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
      setState(() => _hasNavigatedInTab[index] = false);
    } else {
      setState(() => _currentIndex = index);
      _animationController.forward(from: 0);
    }
  }

  bool _shouldShowBottomBar() {
    // Check if current tab has navigated to another screen
    final navigatorState = _navigatorKeys[_currentIndex].currentState;
    if (navigatorState != null) {
      final canPop = navigatorState.canPop();
      return !canPop;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: Stack(
          children: List.generate(_screens.length, (index) {
            return Offstage(
              offstage: _currentIndex != index,
              child: Navigator(
                key: _navigatorKeys[index],
                observers: [
                  _NavigatorObserver(
                    onPush: () {
                      setState(() => _hasNavigatedInTab[index] = true);
                    },
                    onPop: () {
                      // Check if we're back to the root
                      Future.microtask(() {
                        if (_navigatorKeys[index].currentState?.canPop() == false) {
                          setState(() => _hasNavigatedInTab[index] = false);
                        }
                      });
                    },
                  ),
                ],
                onGenerateRoute: (routeSettings) {
                  return MaterialPageRoute(
                    builder: (context) => _screens[index],
                  );
                },
              ),
            );
          }),
        ),
        bottomNavigationBar: AnimatedSlide(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          offset: _shouldShowBottomBar() ? Offset.zero : Offset(0, 1),
          child: AnimatedOpacity(
            duration: Duration(milliseconds: 200),
            opacity: _shouldShowBottomBar() ? 1.0 : 0.0,
            child: Container(
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
                onDestinationSelected: _onTabTapped,
                height: 62,
                backgroundColor: isDark ? Color(0xFF1A1A1A) : Colors.white,
                indicatorColor: Color(0xFFFF444F).withOpacity(0.15),
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                elevation: 0,
                animationDuration: Duration(milliseconds: 400),
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
        ),
      ),
    );
  }
}

// Custom Navigator Observer to track navigation
class _NavigatorObserver extends NavigatorObserver {
  final VoidCallback onPush;
  final VoidCallback onPop;

  _NavigatorObserver({
    required this.onPush,
    required this.onPop,
  });

  @override
  void didPush(Route route, Route? previousRoute) {
    super.didPush(route, previousRoute);
    if (previousRoute != null) {
      onPush();
    }
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    super.didPop(route, previousRoute);
    onPop();
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    super.didRemove(route, previousRoute);
    onPop();
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (oldRoute != null && newRoute != null) {
      onPush();
    }
  }
}