import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  // Pulse animation controllers for each tab
  final List<AnimationController> _pulseControllers = [];
  final List<Animation<double>> _pulseAnimations = [];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _updateUserStatus(true);
    _checkAndShowWarningModal();

    // Initialize animation controller for smooth transitions
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    // Initialize pulse animation controllers for each tab
    for (int i = 0; i < 4; i++) {
      final controller = AnimationController(
        duration: Duration(milliseconds: 400),
        vsync: this,
      );
      final animation = Tween<double>(begin: 1.0, end: 1.3).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.easeOut,
        ),
      );
      _pulseControllers.add(controller);
      _pulseAnimations.add(animation);
    }

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

  Future<void> _checkAndShowWarningModal() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenWarning = prefs.getBool('has_seen_trading_warning') ?? false;

    if (!hasSeenWarning) {
      // Delay to ensure the screen is built
      await Future.delayed(Duration(milliseconds: 500));
      _showTradingWarningModal();
    }
  }

  void _showTradingWarningModal() {
    showCupertinoModalPopup(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => _TradingWarningSheet(
        onDismiss: () async {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('has_seen_trading_warning', true);
        },
      ),
    );
  }

  @override
  void dispose() {
    _updateUserStatus(false);
    _animationController.dispose();
    for (var controller in _pulseControllers) {
      controller.dispose();
    }
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
    // Trigger pulse animation
    _pulseControllers[index].forward().then((_) {
      _pulseControllers[index].reverse();
    });

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
          curve: Curves.easeInOutCubic,
          offset: showBottomBar ? Offset.zero : Offset(0, 1),
          child: AnimatedOpacity(
            duration: Duration(milliseconds: 200),
            opacity: showBottomBar ? 1.0 : 0.0,
            curve: Curves.easeOut,
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? Color(0xFF0A0A0A) : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Container(
                  height: 62,
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(4, (index) {
                      return _buildNavItem(index, isDark);
                    }),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, bool isDark) {
    final isSelected = _currentIndex == index;
    final icons = [
      Icons.home_outlined,
      Icons.currency_bitcoin,
      Icons.layers_rounded,
      Icons.chat_bubble_rounded,
    ];
    final selectedIcons = [
      Icons.home,
      Icons.currency_bitcoin,
      Icons.layers_rounded,
      Icons.chat_bubble,
    ];
    final labels = ['Início', 'Dados', 'Atualidade', 'Conversas'];

    return Expanded(
      child: GestureDetector(
        onTap: () => _onTabTapped(index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _pulseAnimations[index],
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimations[index].value,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Color(0xFFFF444F).withOpacity(isDark ? 0.12 : 0.08)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isSelected ? selectedIcons[index] : icons[index],
                      color: isSelected
                          ? Color(0xFFFF444F)
                          : isDark
                              ? Colors.grey[500]
                              : Colors.grey[600],
                      size: isSelected ? 26 : 24,
                    ),
                    SizedBox(height: 2),
                    Text(
                      labels[index],
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected
                            ? Color(0xFFFF444F)
                            : isDark
                                ? Colors.grey[500]
                                : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
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

// iOS-style Trading Warning Modal Sheet
class _TradingWarningSheet extends StatefulWidget {
  final VoidCallback onDismiss;

  const _TradingWarningSheet({required this.onDismiss});

  @override
  State<_TradingWarningSheet> createState() => _TradingWarningSheetState();
}

class _TradingWarningSheetState extends State<_TradingWarningSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 400),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() async {
    await _controller.reverse();
    widget.onDismiss();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Stack(
          children: [
            // Background overlay
            GestureDetector(
              onTap: () {}, // Prevent dismissal by tapping outside
              child: Container(
                color: Colors.black.withOpacity(0.4 * _animation.value),
              ),
            ),
            // Sheet
            Align(
              alignment: Alignment.bottomCenter,
              child: Transform.translate(
                offset: Offset(0, (1 - _animation.value) * 400),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? Color(0xFF1C1C1E) : Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Handle bar
                        SizedBox(height: 12),
                        Container(
                          width: 36,
                          height: 5,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[700] : Colors.grey[300],
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        SizedBox(height: 24),
                        
                        // Warning icon with animation
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: Duration(milliseconds: 600),
                          curve: Curves.elasticOut,
                          builder: (context, value, child) {
                            return Transform.scale(
                              scale: value,
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Color(0xFFFF444F).withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.warning_rounded,
                                  size: 45,
                                  color: Color(0xFFFF444F),
                                ),
                              ),
                            );
                          },
                        ),
                        
                        SizedBox(height: 24),
                        
                        // Title
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            'Aviso Importante sobre Trading',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        
                        SizedBox(height: 16),
                        
                        // Content
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24),
                          child: Container(
                            padding: EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: isDark ? Color(0xFF2C2C2E) : Colors.grey[100],
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildWarningPoint(
                                  icon: Icons.trending_down,
                                  text: 'Operações em qualquer corretora podem garantir ganhos ou perdas. Por tanto, apelamos em usar as ferramentas do app para controlar os riscos.',
                                  isDark: isDark,
                                ),
                                SizedBox(height: 16),
                                _buildWarningPoint(
                                  icon: Icons.psychology_outlined,
                                  text: 'Não deixe a emoção controlar suas decisões. Trading emocional é uma das principais causas de perdas significativas.',
                                  isDark: isDark,
                                ),
                                SizedBox(height: 16),
                                _buildWarningPoint(
                                  icon: Icons.shield_outlined,
                                  text: 'Nunca invista mais do que pode perder. Use stop loss e gerencie seu risco adequadamente.',
                                  isDark: isDark,
                                ),
                                SizedBox(height: 16),
                                _buildWarningPoint(
                                  icon: Icons.school_outlined,
                                  text: 'Educação contínua é essencial. Utilize nossos recursos educacionais antes de operar com capital real.',
                                  isDark: isDark,
                                ),
                                SizedBox(height: 16),
                                _buildWarningPoint(
                                  icon: Icons.account_balance_wallet_outlined,
                                  text: 'Diversifique seus investimentos e nunca coloque todos os seus fundos em uma única operação.',
                                  isDark: isDark,
                                ),
                              ],
                            ),
                          ),
                        ),
                        
                        SizedBox(height: 24),
                        
                        // Disclaimer
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            'Ao continuar, você reconhece ter lido e compreendido os riscos associados ao trading de criptomoedas e outros ativos.',
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        
                        SizedBox(height: 24),
                        
                        // Button
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24),
                          child: SizedBox(
                            width: double.infinity,
                            child: CupertinoButton(
                              color: Color(0xFFFF444F),
                              borderRadius: BorderRadius.circular(14),
                              padding: EdgeInsets.symmetric(vertical: 16),
                              onPressed: _dismiss,
                              child: Text(
                                'Entendi',
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        
                        SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildWarningPoint({
    required IconData icon,
    required String text,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Color(0xFFFF444F).withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 18,
            color: Color(0xFFFF444F),
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: isDark ? Colors.grey[300] : Colors.grey[800],
            ),
          ),
        ),
      ],
    );
  }
}