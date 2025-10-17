import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import 'chats_screen.dart';
import 'marketplace_screen.dart';
import 'news_screen.dart';
import 'goals_screen.dart';
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
  late AnimationController _bottomBarAnimationController;
  late Animation<Offset> _bottomBarSlideAnimation;
  Map<String, dynamic>? _userData;
  bool _showBottomBar = true;

  final List<bool> _hasNavigatedInTab = [false, false, false, false, false];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _updateUserStatus(true);
    _checkFirstTimeUser();

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

    _navigatorKeys = List.generate(
      5,
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
      GoalsScreen(),
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
    _bottomBarAnimationController.dispose();
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
    if (_currentIndex == index) {
      _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
      setState(() => _hasNavigatedInTab[index] = false);
    } else {
      setState(() => _currentIndex = index);
    }
    _updateBottomBarVisibility();
  }

  void _updateBottomBarVisibility() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final navigatorState = _navigatorKeys[_currentIndex].currentState;
      bool currentCanPop = false;
      try {
        if (navigatorState != null) currentCanPop = navigatorState.canPop();
      } catch (_) {
        currentCanPop = false;
      }

      bool rootCanPop = false;
      try {
        rootCanPop = Navigator.of(context, rootNavigator: true).canPop();
      } catch (_) {
        rootCanPop = false;
      }

      final shouldShow = !(currentCanPop || rootCanPop);

      if (_showBottomBar != shouldShow) {
        setState(() => _showBottomBar = shouldShow);
      }

      if (!shouldShow) {
        _bottomBarAnimationController.forward();
      } else {
        _bottomBarAnimationController.reverse();
      }
    });
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
                      _updateBottomBarVisibility();
                    },
                    onPop: () {
                      Future.microtask(() {
                        if (_navigatorKeys[index].currentState?.canPop() == false) {
                          setState(() => _hasNavigatedInTab[index] = false);
                        }
                        _updateBottomBarVisibility();
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
          child: AnimatedContainer(
            duration: Duration(milliseconds: 260),
            curve: Curves.easeInOut,
            height: _showBottomBar ? null : 0.0,
            child: _showBottomBar ? _buildBottomBar(context, isDark) : SizedBox.shrink(),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, bool isDark) {
    final bgColor = isDark ? Color(0xFF1C1C1E).withOpacity(0.75) : Colors.white.withOpacity(0.75);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
        child: Container(
          decoration: BoxDecoration(
            color: bgColor,
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.1),
                width: 0.5,
              ),
            ),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              navigationBarTheme: NavigationBarThemeData(
                backgroundColor: Colors.transparent,
                indicatorColor: Color(0xFFFF444F).withOpacity(0.15),
                labelTextStyle: MaterialStateProperty.resolveWith((states) {
                  if (states.contains(MaterialState.selected)) {
                    return TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFFF444F),
                    );
                  }
                  return TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white70 : Colors.black54,
                  );
                }),
                iconTheme: MaterialStateProperty.resolveWith((states) {
                  if (states.contains(MaterialState.selected)) {
                    return IconThemeData(
                      size: 24,
                      color: Color(0xFFFF444F),
                    );
                  }
                  return IconThemeData(
                    size: 24,
                    color: isDark ? Colors.white70 : Colors.black54,
                  );
                }),
              ),
            ),
            child: NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: _onTabTapped,
              destinations: [
                NavigationDestination(
                  icon: Icon(Icons.home_rounded),
                  label: 'Início',
                ),
                NavigationDestination(
                  icon: Icon(Icons.shopping_bag_rounded),
                  label: 'Negociar',
                ),
                NavigationDestination(
                  icon: Icon(Icons.newspaper_rounded),
                  label: 'Atualidade',
                ),
                NavigationDestination(
                  icon: Icon(Icons.track_changes_rounded),
                  label: 'Metas',
                ),
                NavigationDestination(
                  icon: Icon(Icons.chat_bubble_rounded),
                  label: 'Conversas',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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