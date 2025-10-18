// lib/screens/main_screen.dart
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_screen.dart';
import 'chats_screen.dart';
import 'marketplace_screen.dart';
import 'news_screen.dart';
import 'goals_screen.dart';
import '../widgets/app_ui_components.dart';

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

    _navigatorKeys = List.generate(5, (index) => GlobalKey<NavigatorState>());

    _screens = [
      HomeScreen(
        onThemeChanged: widget.onThemeChanged,
        onLocaleChanged: widget.onLocaleChanged,
        currentLocale: widget.currentLocale,
      ),
      GoalsScreen(),
      MarketplaceScreen(),
      NewsScreen(),
      ChatsScreen(currentUser: FirebaseAuth.instance.currentUser),
    ];
  }

  void _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists && mounted) {
        setState(() => _userData = doc.data());
      }
    }
  }

  void _updateUserStatus(bool online) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({
          'isOnline': online,
          'last_seen': FieldValue.serverTimestamp(),
        });
      } catch (e) {}
    }
  }

  Future<void> _checkFirstTimeUser() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenWarning = prefs.getBool('hasSeenTradingWarning') ?? false;

    if (!hasSeenWarning && mounted) {
      Future.delayed(Duration(milliseconds: 800), () {
        if (!mounted) return;
        _showTradingWarning();
      });
    }
  }

  void _showTradingWarning() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.orange, size: 28),
            SizedBox(width: 12),
            Text('Aviso Importante'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trading envolve riscos significativos. Este aplicativo é apenas para fins educacionais.',
              style: TextStyle(fontSize: 15, height: 1.5),
            ),
            SizedBox(height: 16),
            Text(
              '• Nunca invista mais do que pode perder\n• Busque conhecimento antes de operar\n• Consulte profissionais certificados',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          AppPrimaryButton(
            text: 'Entendi',
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('hasSeenTradingWarning', true);
              Navigator.pop(context);
            },
            height: 48,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _updateUserStatus(false);
    _bottomBarAnimationController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    final isFirstRouteInCurrentTab =
        !await _navigatorKeys[_currentIndex].currentState!.maybePop();

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
      } catch (_) {}

      bool rootCanPop = false;
      try {
        rootCanPop = Navigator.of(context, rootNavigator: true).canPop();
      } catch (_) {}

      // Verifica se há um dialog aberto
      bool hasDialog = false;
      try {
        hasDialog = ModalRoute.of(context)?.isCurrent == false;
      } catch (_) {}

      // Mostra bottom bar se não houver navegação ou se for apenas um dialog
      final shouldShow = !(currentCanPop || (rootCanPop && !hasDialog));

      if (_showBottomBar != shouldShow && mounted) {
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
                  return MaterialPageRoute(builder: (_) => _screens[index]);
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
            child: _showBottomBar
                ? _buildBottomBar(context, isDark)
                : SizedBox.shrink(),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, bool isDark) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.darkCard.withOpacity(0.9)
                : AppColors.lightCard.withOpacity(0.9),
            border: Border(
              top: BorderSide(
                color: isDark ? AppColors.darkSeparator : AppColors.separator,
                width: 0.5,
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Container(
              height: 65,
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(
                    icon: Icons.home_outlined,
                    activeIcon: Icons.home_rounded,
                    label: 'Início',
                    index: 0,
                    isDark: isDark,
                  ),
                  _buildNavItem(
                    icon: Icons.track_changes_outlined,
                    activeIcon: Icons.track_changes_rounded,
                    label: 'Metas',
                    index: 1,
                    isDark: isDark,
                  ),
                  _buildCenterNavItem(isDark),
                  _buildNavItem(
                    icon: Icons.article_outlined,
                    activeIcon: Icons.article_rounded,
                    label: 'Sheets',
                    index: 3,
                    isDark: isDark,
                  ),
                  _buildNavItem(
                    icon: Icons.chat_bubble_outline,
                    activeIcon: Icons.chat_bubble_rounded,
                    label: 'Conversas',
                    index: 4,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    required bool isDark,
  }) {
    final isActive = _currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabTapped(index),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isActive ? activeIcon : icon,
                color: isActive
                    ? AppColors.primary
                    : (isDark ? Colors.white60 : Colors.black54),
                size: 24,
              ),
              SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive
                      ? AppColors.primary
                      : (isDark ? Colors.white60 : Colors.black54),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenterNavItem(bool isDark) {
    final isActive = _currentIndex == 2;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabTapped(2),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 50,
                height: 32,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isActive
                        ? [AppColors.primary, AppColors.primary.withOpacity(0.8)]
                        : [
                            isDark ? AppColors.darkBorder : Colors.grey[300]!,
                            isDark ? AppColors.darkBorder : Colors.grey[300]!,
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: Offset(0, 2),
                          ),
                        ]
                      : [],
                ),
                child: Icon(
                  Icons.trending_up_rounded,
                  color: isActive
                      ? Colors.white
                      : (isDark ? Colors.white60 : Colors.black54),
                  size: 22,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Negociar',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive
                      ? AppColors.primary
                      : (isDark ? Colors.white60 : Colors.black54),
                ),
              ),
            ],
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