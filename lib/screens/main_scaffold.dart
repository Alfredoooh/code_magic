import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';
import '../widgets/app_header.dart';
import '../widgets/bottom_nav_bar.dart';
import 'feed_screen.dart';
import 'matches_screen.dart';
import 'tv_screen.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({Key? key}) : super(key: key);

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> with TickerProviderStateMixin {
  int _selectedBottomTab = 0;
  bool _isDrawerOpen = false;
  bool _isDarkTheme = true;

  late AnimationController _drawerAnimationController;
  late Animation<double> _drawerSlideAnimation;
  late Animation<double> _contentSlideAnimation;

  // Lista de widgets para manter o estado
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    
    // Inicializa as telas uma única vez
    _screens = [
      FeedScreen(
        bgColor: _bgColor,
        surfaceColor: _surfaceColor,
        textColor: _textColor,
        subTextColor: _subTextColor,
        borderColor: _borderColor,
        isDarkTheme: _isDarkTheme,
      ),
      MatchesScreen(
        bgColor: _bgColor,
        surfaceColor: _surfaceColor,
        textColor: _textColor,
        subTextColor: _subTextColor,
        borderColor: _borderColor,
      ),
      TvScreen(
        bgColor: _bgColor,
        surfaceColor: _surfaceColor,
        textColor: _textColor,
        subTextColor: _subTextColor,
        borderColor: _borderColor,
      ),
    ];
    
    _drawerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _drawerSlideAnimation = Tween<double>(begin: -1.0, end: 0.0).animate(
      CurvedAnimation(parent: _drawerAnimationController, curve: Curves.easeInOut),
    );
    _contentSlideAnimation = Tween<double>(begin: 0.0, end: 0.2).animate(
      CurvedAnimation(parent: _drawerAnimationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _drawerAnimationController.dispose();
    super.dispose();
  }

  void _toggleDrawer() {
    setState(() => _isDrawerOpen = !_isDrawerOpen);
    if (_isDrawerOpen) {
      _drawerAnimationController.forward();
    } else {
      _drawerAnimationController.reverse();
    }
  }

  Color get _bgColor => _isDarkTheme ? const Color(0xFF0A0A0A) : const Color(0xFFFAFBFD);
  Color get _surfaceColor => _isDarkTheme ? const Color(0xFF1A1A1A) : Colors.white;
  Color get _textColor => _isDarkTheme ? const Color(0xFFE4E6EB) : const Color(0xFF050505);
  Color get _subTextColor => _isDarkTheme ? const Color(0xFFB0B3B8) : const Color(0xFF65676B);
  Color get _borderColor => _isDarkTheme ? const Color(0xFF3A3B3C) : const Color(0xFFDDDFE2);

  void _onBottomNavTap(int index) {
    setState(() => _selectedBottomTab = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _contentSlideAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(MediaQuery.of(context).size.width * _contentSlideAnimation.value, 0),
                child: Transform.scale(
                  scale: 1.0 - (_contentSlideAnimation.value * 0.1),
                  alignment: Alignment.centerLeft,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(_contentSlideAnimation.value * 20),
                    child: Container(
                      color: _bgColor,
                      child: SafeArea(
                        bottom: false,
                        child: Column(
                          children: [
                            AppHeader(
                              onMenuTap: _toggleDrawer,
                              onSearchTap: () {},
                              bgColor: _bgColor,
                              borderColor: _borderColor,
                              textColor: _textColor,
                              isDarkTheme: _isDarkTheme,
                            ),
                            Expanded(
                              child: IndexedStack(
                                index: _selectedBottomTab,
                                children: _screens,
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: BottomNavBar(
              selectedIndex: _selectedBottomTab,
              onItemSelected: _onBottomNavTap,
              surfaceColor: _surfaceColor,
              borderColor: _borderColor,
              subTextColor: _subTextColor,
            ),
          ),
          if (_isDrawerOpen)
            GestureDetector(
              onTap: _toggleDrawer,
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.black.withOpacity(0.45)),
            ),
          if (_isDrawerOpen)
            AnimatedBuilder(
              animation: _drawerSlideAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(MediaQuery.of(context).size.width * _drawerSlideAnimation.value, 0),
                  child: AppDrawer(
                    isDarkTheme: _isDarkTheme,
                    onThemeToggle: () {
                      setState(() => _isDarkTheme = !_isDarkTheme);
                    },
                    onClose: _toggleDrawer,
                    surfaceColor: _surfaceColor,
                    textColor: _textColor,
                    subTextColor: _subTextColor,
                    borderColor: _borderColor,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}