// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../widgets/custom_icons.dart';
import '../widgets/custom_drawer.dart';
import '../widgets/post_feed.dart';
import '../widgets/new_post_modal.dart';
import 'search_screen.dart';
import 'messages_screen.dart';
import 'notifications_screen.dart';
import 'users_screen.dart';
import 'marketplace_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  // Animation controller para o efeito de deslize do drawer
  late AnimationController _drawerSlideController;
  late Animation<Offset> _drawerSlideAnimation;

  final List<Widget?> _pages = [const PostFeed(), null, null, const NotificationsScreen()];

  static const Color _activeBlue = Color(0xFF1877F2);

  @override
  void initState() {
    super.initState();
    _drawerSlideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    
    // Animação de deslize para a direita (efeito iOS)
    _drawerSlideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0.6, 0), // Desliza 60% para a direita
    ).animate(CurvedAnimation(
      parent: _drawerSlideController,
      curve: Curves.easeOut,
    ));
  }

  @override
  void dispose() {
    _drawerSlideController.dispose();
    super.dispose();
  }

  Widget _getPage(int index) {
    if (_pages[index] != null) return _pages[index]!;
    switch (index) {
      case 1:
        _pages[1] = const UsersScreen();
        break;
      case 2:
        _pages[2] = const MarketplaceScreen();
        break;
      default:
        _pages[index] = const SizedBox.shrink();
    }
    return _pages[index]!;
  }

  void _onTap(int index) {
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);
  }

  void _toggleDrawer() {
    if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
      _drawerSlideController.reverse();
      Navigator.of(context).pop();
    } else {
      _scaffoldKey.currentState?.openDrawer();
      _drawerSlideController.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProv = context.watch<ThemeProvider>();
    final isDark = themeProv.isDarkMode;
    final bgColor = isDark ? const Color(0xFF242526) : Colors.white;
    final iconColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);
    final unselectedColor = isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B);
    final topBorderColor = isDark ? const Color(0xFF3E4042) : const Color(0xFFDADADA);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: bgColor,
      drawer: const CustomDrawer(),
      onDrawerChanged: (isOpened) {
        if (isOpened) {
          _drawerSlideController.forward();
        } else {
          _drawerSlideController.reverse();
        }
      },
      body: Stack(
        children: [
          // Conteúdo principal com animação de deslize
          SlideTransition(
            position: _drawerSlideAnimation,
            child: Column(
              children: [
                // AppBar customizado
                Container(
                  color: bgColor,
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      children: [
                        SizedBox(
                          height: 56,
                          child: Row(
                            children: [
                              IconButton(
                                icon: SvgIcon(svgString: CustomIcons.menu, color: iconColor),
                                onPressed: _toggleDrawer,
                              ),
                              const Spacer(),
                              IconButton(
                                icon: SvgIcon(svgString: CustomIcons.plus, color: iconColor),
                                onPressed: () => _showNewPostModal(context),
                              ),
                              IconButton(
                                icon: SvgIcon(svgString: CustomIcons.search, color: iconColor),
                                onPressed: () => Navigator.of(context).push(
                                  CupertinoPageRoute(builder: (_) => SearchScreen()),
                                ),
                              ),
                              IconButton(
                                icon: SvgIcon(svgString: CustomIcons.inbox, color: iconColor),
                                onPressed: () => Navigator.of(context).push(
                                  CupertinoPageRoute(builder: (_) => MessagesScreen()),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          color: topBorderColor,
                          height: 0.5,
                        ),
                      ],
                    ),
                  ),
                ),

                // Body
                Expanded(
                  child: IndexedStack(
                    index: _currentIndex,
                    children: List.generate(4, (i) => _getPage(i)),
                  ),
                ),
              ],
            ),
          ),

          // Overlay escuro quando o drawer está aberto
          if (_drawerSlideController.value > 0)
            GestureDetector(
              onTap: _toggleDrawer,
              child: AnimatedBuilder(
                animation: _drawerSlideController,
                builder: (context, child) {
                  return IgnorePointer(
                    ignoring: _drawerSlideController.value == 0,
                    child: Container(
                      color: Colors.black.withOpacity(0.4 * _drawerSlideController.value),
                    ),
                  );
                },
              ),
            ),
        ],
      ),

      // Floating TabBar com bordas totalmente curvas
      bottomNavigationBar: SlideTransition(
        position: _drawerSlideAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: topBorderColor, width: 0.5),
              boxShadow: [
                BoxShadow(
                  color: isDark 
                      ? Colors.black.withOpacity(0.3)
                      : Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTabItem(index: 0, svg: CustomIcons.home, unselectedColor: unselectedColor),
                _buildTabItem(index: 1, svg: CustomIcons.users, unselectedColor: unselectedColor),
                _buildTabItem(index: 2, svg: CustomIcons.marketplace, unselectedColor: unselectedColor),
                _buildTabItem(index: 3, svg: CustomIcons.bell, unselectedColor: unselectedColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem({
    required int index,
    required String svg,
    required Color unselectedColor,
  }) {
    final bool active = _currentIndex == index;
    final Color iconColor = active ? _activeBlue : unselectedColor;

    return Expanded(
      child: InkWell(
        onTap: () => _onTap(index),
        borderRadius: BorderRadius.circular(100),
        child: Center(
          child: SvgIcon(
            svgString: svg, 
            size: 24, 
            color: iconColor,
          ),
        ),
      ),
    );
  }
}

void _showNewPostModal(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const NewPostModal(),
  );
}