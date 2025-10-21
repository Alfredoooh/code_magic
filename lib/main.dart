import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'styles.dart';
import 'login_screen.dart';
import 'trade_screen.dart';
import 'bots_screen.dart';
import 'drawer_menu.dart';
import 'settings_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const DerivTradingApp());
}

class DerivTradingApp extends StatelessWidget {
  const DerivTradingApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ZoomTrade',
      theme: AppStyles.lightTheme,
      darkTheme: AppStyles.darkTheme,
      themeMode: ThemeMode.dark,
      debugShowCheckedModeBanner: false,
      home: const LoginScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  final String token;
  final String? accountId;
  
  const MainScreen({
    Key? key, 
    required this.token,
    this.accountId,
  }) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentIndex = 0;
  
  late final List<GlobalKey<NavigatorState>> _navigatorKeys;
  late final AnimationController _drawerAnimationController;
  late final Animation<double> _drawerScaleAnimation;
  late final Animation<double> _drawerSlideAnimation;
  late final Animation<BorderRadius?> _drawerBorderAnimation;

  @override
  void initState() {
    super.initState();
    
    // Navigator keys para cada tab (mantém estado)
    _navigatorKeys = [
      GlobalKey<NavigatorState>(),
      GlobalKey<NavigatorState>(),
    ];

    // Animação do drawer com efeito iOS
    _drawerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _drawerScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.85,
    ).animate(CurvedAnimation(
      parent: _drawerAnimationController,
      curve: Curves.easeInOut,
    ));

    _drawerSlideAnimation = Tween<double>(
      begin: 0.0,
      end: 260.0,
    ).animate(CurvedAnimation(
      parent: _drawerAnimationController,
      curve: Curves.easeInOut,
    ));

    _drawerBorderAnimation = BorderRadiusTween(
      begin: BorderRadius.circular(0),
      end: BorderRadius.circular(20),
    ).animate(CurvedAnimation(
      parent: _drawerAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _drawerAnimationController.dispose();
    super.dispose();
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
    _drawerAnimationController.forward();
  }

  void _closeDrawer() {
    _scaffoldKey.currentState?.closeDrawer();
    _drawerAnimationController.reverse();
  }

  Widget _buildNavigator(int index) {
    return Navigator(
      key: _navigatorKeys[index],
      onGenerateRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) {
            switch (index) {
              case 0:
                return TradeScreen(token: widget.token);
              case 1:
                return BotsScreen(token: widget.token);
              default:
                return TradeScreen(token: widget.token);
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.black,
      drawer: DrawerMenu(token: widget.token),
      onDrawerChanged: (isOpened) {
        if (!isOpened) {
          _drawerAnimationController.reverse();
        }
      },
      drawerScrimColor: Colors.transparent,
      body: AnimatedBuilder(
        animation: _drawerAnimationController,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(_drawerSlideAnimation.value, 0),
            child: Transform.scale(
              scale: _drawerScaleAnimation.value,
              child: ClipRRect(
                borderRadius: _drawerBorderAnimation.value ?? BorderRadius.zero,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppStyles.bgPrimary,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: AbsorbPointer(
                    absorbing: _drawerAnimationController.value > 0.1,
                    child: Stack(
                      children: [
                        // Navigator Stack para manter estado das tabs
                        IndexedStack(
                          index: _currentIndex,
                          children: List.generate(
                            _navigatorKeys.length,
                            (index) => _buildNavigator(index),
                          ),
                        ),
                        
                        // Bottom Navigation Bar
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: _buildBottomNavigationBar(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: AppStyles.bgSecondary,
        border: Border(
          top: BorderSide(color: AppStyles.border, width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                index: 0,
                icon: Icons.candlestick_chart_rounded,
                label: 'Trade',
              ),
              _buildNavItem(
                index: 1,
                icon: Icons.smart_toy_rounded,
                label: 'Bots',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _currentIndex == index;
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_currentIndex != index) {
            setState(() => _currentIndex = index);
            HapticFeedback.lightImpact();
          }
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ícone com animação
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: EdgeInsets.all(isSelected ? 8 : 6),
                decoration: BoxDecoration(
                  color: isSelected 
                      ? AppStyles.iosBlue.withOpacity(0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isSelected 
                      ? AppStyles.iosBlue 
                      : AppStyles.textSecondary,
                  size: isSelected ? 26 : 24,
                ),
              ),
              
              const SizedBox(height: 4),
              
              // Label
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                style: TextStyle(
                  color: isSelected 
                      ? AppStyles.iosBlue 
                      : AppStyles.textSecondary,
                  fontSize: isSelected ? 12 : 11,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
                child: Text(label),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Função auxiliar para abrir o drawer (use nas telas)
class DrawerController {
  static void openDrawer(BuildContext context) {
    final scaffoldState = Scaffold.of(context);
    scaffoldState.openDrawer();
  }
}