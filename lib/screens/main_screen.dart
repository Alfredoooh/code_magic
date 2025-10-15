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

// ---------- MainScreen atualizado ----------
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

    // Bottom bar slide animation
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

  /// IMPORTANT: aqui ampliamos a condição para esconder o bottom bar:
  /// - se o navigator da tab atual puder pop -> escondemos (rota interna)
  /// - OU se o root navigator puder pop -> escondemos (modal/rota global)
  bool _shouldShowBottomBar() {
    final navigatorState = _navigatorKeys[_currentIndex].currentState;
    bool currentCanPop = false;
    try {
      if (navigatorState != null) currentCanPop = navigatorState.canPop();
    } catch (_) { currentCanPop = false; }

    bool rootCanPop = false;
    try {
      rootCanPop = Navigator.of(context, rootNavigator: true).canPop();
    } catch (_) { rootCanPop = false; }

    // Se qualquer um pode pop (rota sobreposta), ocultamos o bottom bar.
    final shouldShow = !(currentCanPop || rootCanPop);

    // animação de slide: quando não mostrar animamos para esconder
    if (!shouldShow) {
      _bottomBarAnimationController.forward();
    } else {
      _bottomBarAnimationController.reverse();
    }

    return shouldShow;
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
        // Bottom bar customizado
        bottomNavigationBar: SlideTransition(
          position: _bottomBarSlideAnimation,
          child: SafeArea(
            top: false,
            child: AnimatedContainer(
              duration: Duration(milliseconds: 260),
              curve: Curves.easeInOut,
              height: showBottomBar ? 72.0 : 0.0, // desaparece totalmente quando hidden
              child: showBottomBar ? _buildBottomBar(context, isDark) : SizedBox.shrink(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, bool isDark) {
    final activeColor = Color(0xFFFF444F);
    final inactiveColor = isDark ? Colors.white70 : Colors.black54;
    final bgColor = isDark ? Color(0xFF000000) : Colors.white;
    final itemCount = 4;

    final icons = [
      CupertinoIcons.home, // Início
      CupertinoIcons.chart_bar, // Dados (sem crypto)
      CupertinoIcons.news_solid, // Atualidade
      CupertinoIcons.bubble_left_bubble_right, // Conversas
    ];

    final labels = ['Início', 'Dados', 'Atualidade', 'Conversas'];

    return Material(
      elevation: 0,
      color: bgColor,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: Offset(0, -2)),
          ],
        ),
        padding: EdgeInsets.only(top: 8, bottom: 8),
        child: LayoutBuilder(builder: (context, constraints) {
          final width = constraints.maxWidth;
          final itemWidth = width / itemCount;
          final indicatorWidth = 36.0;
          final leftForIndex = (int index) => itemWidth * index + (itemWidth / 2) - (indicatorWidth / 2);

          return Stack(
            clipBehavior: Clip.none,
            children: [
              // indicator (traço curvado) posicionado no topo do bar, animado
              AnimatedPositioned(
                duration: Duration(milliseconds: 280),
                curve: Curves.easeInOutCubic,
                left: leftForIndex(_currentIndex),
                top: -6, // colado à borda superior do bottom bar
                child: Visibility(
                  visible: true,
                  child: Container(
                    width: indicatorWidth,
                    height: 6,
                    decoration: BoxDecoration(
                      color: activeColor,
                      borderRadius: BorderRadius.circular(12), // bordas curvas
                      boxShadow: [
                        BoxShadow(
                          color: activeColor.withOpacity(0.16),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Row de itens
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(itemCount, (index) {
                  final isSelected = _currentIndex == index;
                  final isPulsing = _pulsedIndex == index;
                  final scale = isPulsing ? 1.12 : 1.0;

                  return SizedBox(
                    width: itemWidth,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _onTabTapped(index),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedScale(
                            scale: scale,
                            duration: Duration(milliseconds: 220),
                            curve: Curves.easeOut,
                            child: Icon(
                              icons[index],
                              size: isSelected ? 26 : 22,
                              color: isSelected ? activeColor : inactiveColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            labels[index],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700, // mais bold
                              color: isSelected ? activeColor : inactiveColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        }),
      ),
    );
  }
}

// Custom Navigator Observer to track navigation (mantido)
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