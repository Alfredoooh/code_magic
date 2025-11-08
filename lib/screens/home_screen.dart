// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_icons.dart';
import '../widgets/custom_drawer.dart';
import '../widgets/post_feed.dart';
import '../widgets/new_post_modal.dart';
import 'search_screen.dart';
import 'messages_screen.dart';
import 'invest_screen.dart';
import 'users_screen.dart';
import 'marketplace_screen.dart';
import 'marketplace/add_book_screen.dart';
import 'bets_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  late AnimationController _drawerSlideController;

  final List<Widget?> _pages = [const PostFeed(), null, null, null, null];

  static const Color _activeBlue = Color(0xFF1877F2);

  final List<String> _tabTitles = [
    'Início',
    'Usuários',
    'Marketplace',
    'Bets',
    'Investir',
  ];

  @override
  void initState() {
    super.initState();
    _drawerSlideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
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
      case 3:
        _pages[3] = const BetsScreen();
        break;
      case 4:
        _pages[4] = const InvestScreen();
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

  void _handlePlusButton(BuildContext context) {
    if (_currentIndex == 0) {
      _showNewPostModal(context);
    } else if (_currentIndex == 2) {
      final authProvider = context.read<AuthProvider>();
      final bool canAddBook = authProvider.userData?['isPro'] == true || 
                              authProvider.userData?['isPremium'] == true;

      if (canAddBook) {
        _navigateHorizontally(context, const AddBookScreen());
      } else {
        _showProRequiredDialog(context);
      }
    }
  }

  void _showProRequiredDialog(BuildContext context) {
    final themeProv = context.read<ThemeProvider>();
    final isDark = themeProv.isDarkMode;
    final textColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);
    final hintColor = isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF242526) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1877F2).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.workspace_premium,
                color: Color(0xFF1877F2),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Recurso Pro',
              style: TextStyle(
                color: textColor,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Text(
          'Apenas usuários Pro ou Premium podem adicionar livros ao Marketplace. Atualize sua conta para desbloquear este recurso!',
          style: TextStyle(
            color: hintColor,
            fontSize: 15,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Entendi',
              style: TextStyle(
                color: hintColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1877F2),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Ver Planos'),
          ),
        ],
      ),
    );
  }

  // Método para navegação horizontal simples
  void _navigateHorizontally(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProv = context.watch<ThemeProvider>();
    final isDark = themeProv.isDarkMode;
    final bgColor = isDark ? const Color(0xFF242526) : Colors.white;
    final iconColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);
    final unselectedColor = isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B);
    final topBorderColor = isDark ? const Color(0xFF3E4042) : const Color(0xFFDADADA);

    final isWideScreen = MediaQuery.of(context).size.width > 600;
    final bool showSearchButton = _currentIndex != 1;

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
          Row(
            children: [
              if (isWideScreen)
                AnimatedBuilder(
                  animation: _drawerSlideController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(
                        MediaQuery.of(context).size.width * 0.75 * _drawerSlideController.value,
                        0,
                      ),
                      child: child,
                    );
                  },
                  child: Container(
                    width: 80,
                    color: Colors.transparent,
                    child: SafeArea(
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
                                    offset: const Offset(4, 0),
                                  ),
                                ],
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildVerticalTabItem(index: 0, svg: CustomIcons.home, unselectedColor: unselectedColor),
                                  _buildVerticalTabItem(index: 1, svg: CustomIcons.users, unselectedColor: unselectedColor),
                                  _buildVerticalTabItem(index: 2, svg: CustomIcons.marketplace, unselectedColor: unselectedColor),
                                  _buildVerticalTabItem(index: 3, svg: CustomIcons.roulette, unselectedColor: unselectedColor),
                                  _buildVerticalTabItem(index: 4, svg: CustomIcons.trendingUp, unselectedColor: unselectedColor),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),

              Expanded(
                child: AnimatedBuilder(
                  animation: _drawerSlideController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(
                        MediaQuery.of(context).size.width * 0.75 * _drawerSlideController.value,
                        0,
                      ),
                      child: child,
                    );
                  },
                  child: Column(
                    children: [
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
                                    if (!isWideScreen)
                                      IconButton(
                                        icon: SvgIcon(svgString: CustomIcons.menu, color: iconColor),
                                        onPressed: _toggleDrawer,
                                      ),
                                    if (isWideScreen) const SizedBox(width: 16),
                                    Text(
                                      _tabTitles[_currentIndex],
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.w700,
                                        color: iconColor,
                                      ),
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      icon: SvgIcon(svgString: CustomIcons.plus, color: iconColor),
                                      onPressed: () => _handlePlusButton(context),
                                    ),
                                    if (showSearchButton)
                                      IconButton(
                                        icon: SvgIcon(svgString: CustomIcons.search, color: iconColor),
                                        onPressed: () => _navigateHorizontally(context, const SearchScreen()),
                                      ),
                                    IconButton(
                                      icon: SvgIcon(svgString: CustomIcons.inbox, color: iconColor),
                                      onPressed: () => _navigateHorizontally(context, const MessagesScreen()),
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

                      Expanded(
                        child: IndexedStack(
                          index: _currentIndex,
                          children: List.generate(5, (i) => _getPage(i)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          AnimatedBuilder(
            animation: _drawerSlideController,
            builder: (context, child) {
              if (_drawerSlideController.value == 0) return const SizedBox.shrink();
              return GestureDetector(
                onTap: _toggleDrawer,
                child: Container(
                  color: Colors.black.withOpacity(0.4 * _drawerSlideController.value),
                ),
              );
            },
          ),
        ],
      ),

      bottomNavigationBar: !isWideScreen
          ? AnimatedBuilder(
              animation: _drawerSlideController,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(
                    MediaQuery.of(context).size.width * 0.75 * _drawerSlideController.value,
                    0,
                  ),
                  child: child,
                );
              },
              child: Container(
                color: Colors.transparent,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Container(
                  height: 56,
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
                      _buildTabItem(index: 3, svg: CustomIcons.roulette, unselectedColor: unselectedColor),
                      _buildTabItem(index: 4, svg: CustomIcons.trendingUp, unselectedColor: unselectedColor),
                    ],
                  ),
                ),
              ),
            )
          : null,
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

  Widget _buildVerticalTabItem({
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