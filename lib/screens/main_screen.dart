import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import 'chats_screen.dart';
import 'marketplace_screen.dart';
import 'news_screen.dart';
import 'more_screen.dart';
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
  late AnimationController _bottomBarAnimationController;
  late AnimationController _pulseController;
  late Animation<double> _animation;
  late Animation<Offset> _bottomBarSlideAnimation;
  Map<String, dynamic>? _userData;
  int _pulsedIndex = -1;

  final List<bool> _hasNavigatedInTab = [false, false, false, false];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _updateUserStatus(true);
    _checkFirstTimeUser();

    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    // Bottom bar slide animation (iOS style)
    _bottomBarAnimationController = AnimationController(
      duration: Duration(milliseconds: 320),
      vsync: this,
    );
    _bottomBarSlideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: Offset(0, 1),
    ).animate(CurvedAnimation(
      parent: _bottomBarAnimationController,
      curve: Curves.easeInOutCubic,
    ));

    // Pulse animation for tab icons
    _pulseController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );

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

  Future<void> _checkFirstTimeUser() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenWarning = prefs.getBool('hasSeenTradingWarning') ?? false;
    
    if (!hasSeenWarning) {
      Future.delayed(Duration(milliseconds: 800), () {
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => TradingWarningScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              const begin = Offset(0.0, 1.0);
              const end = Offset.zero;
              const curve = Curves.easeInOutCubic;
              var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
              var offsetAnimation = animation.drive(tween);
              return SlideTransition(position: offsetAnimation, child: child);
            },
            transitionDuration: Duration(milliseconds: 400),
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _updateUserStatus(false);
    _animationController.dispose();
    _bottomBarAnimationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    final isFirstRouteInCurrentTab = !await _navigatorKeys[_currentIndex].currentState!.maybePop();

    if (isFirstRouteInCurrentTab) {
      if (_currentIndex != 0) {
        _onTabTapped(0);
        return false;
      }
      return true;
    }
    return false;
  }

  void _onTabTapped(int index) {
    // Trigger pulse animation on tapped icon
    setState(() => _pulsedIndex = index);
    _pulseController.forward(from: 0).then((_) {
      setState(() => _pulsedIndex = -1);
    });

    if (_currentIndex == index) {
      _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
      setState(() => _hasNavigatedInTab[index] = false);
    } else {
      setState(() => _currentIndex = index);
      _animationController.forward(from: 0);
    }
  }

  bool _shouldShowBottomBar() {
    final navigatorState = _navigatorKeys[_currentIndex].currentState;
    if (navigatorState != null) {
      final canPop = navigatorState.canPop();
      
      // Animate bottom bar with iOS-style slide
      if (canPop) {
        _bottomBarAnimationController.forward();
      } else {
        _bottomBarAnimationController.reverse();
      }
      
      return !canPop;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final showBottomBar = _shouldShowBottomBar();

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
        bottomNavigationBar: SlideTransition(
          position: _bottomBarSlideAnimation,
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
              backgroundColor: isDark ? Color(0xFF000000) : Colors.white,
              indicatorColor: Color(0xFFFF444F).withOpacity(0.12),
              labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
              elevation: 0,
              animationDuration: Duration(milliseconds: 220),
              destinations: [
                _buildNavDestination(
                  index: 0,
                  icon: Icons.house_rounded,
                  label: 'Início',
                ),
                _buildNavDestination(
                  index: 1,
                  icon: Icons.currency_bitcoin,
                  label: 'Dados',
                ),
                _buildNavDestination(
                  index: 2,
                  icon: Icons.layers_rounded,
                  label: 'Atualidade',
                ),
                _buildNavDestination(
                  index: 3,
                  icon: Icons.chat_bubble_rounded,
                  label: 'Conversas',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  NavigationDestination _buildNavDestination({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _currentIndex == index;
    final isPulsing = _pulsedIndex == index;

    return NavigationDestination(
      icon: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final scale = isPulsing
              ? 1.0 + (Curves.easeOut.transform(_pulseController.value) * 0.25)
              : 1.0;
          
          return Transform.scale(
            scale: scale,
            child: Icon(icon, size: 24),
          );
        },
      ),
      selectedIcon: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          final scale = isPulsing
              ? 1.0 + (Curves.easeOut.transform(_pulseController.value) * 0.25)
              : 1.0;
          
          return Transform.scale(
            scale: scale,
            child: Icon(icon, color: Color(0xFFFF444F), size: 26),
          );
        },
      ),
      label: label,
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