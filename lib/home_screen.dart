import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'theme/app_theme.dart';
import 'theme/app_colors.dart';
import 'theme/app_widgets.dart';
import 'markets_screen.dart';
import 'posts_screen.dart';
import 'trade_screen.dart';
import 'bots_screen.dart';
import 'portfolio_screen.dart';
import 'settings_screen.dart';
import 'trading_center_screen.dart';
import 'search_screen.dart';

class HomeScreen extends StatefulWidget {
  final String token;

  const HomeScreen({Key? key, required this.token}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      MarketsScreen(token: widget.token),
      TradingCenterScreen(token: widget.token),
      PostsScreen(token: widget.token),
    ];

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.03),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.85,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _openSearchScreen() {
    AppHaptics.light();
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => SearchScreen(token: widget.token),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);
          return SlideTransition(position: offsetAnimation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  String _getAppBarTitle() {
    switch (_currentIndex) {
      case 0:
        return 'ZoomTrade';
      case 1:
        return 'Negociação';
      case 2:
        return 'Extras';
      default:
        return 'ZoomTrade';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: context.surface,
      appBar: AppBar(
        backgroundColor: context.colors.surfaceContainer,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () {
            AppHaptics.light();
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        title: Text(
          _getAppBarTitle(),
          style: context.textStyles.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        actions: [
          if (_currentIndex == 0)
            IconButton(
              icon: const Icon(Icons.search_rounded),
              onPressed: _openSearchScreen,
            ),
        ],
      ),
      drawer: _buildDrawer(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: context.colors.surfaceContainerLow,
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          AppHaptics.selection();
          setState(() => _currentIndex = index);
          _animationController.reset();
          _animationController.forward();
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.circle_outlined),
            selectedIcon: Icon(Icons.circle),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(Icons.candlestick_chart_outlined),
            selectedIcon: Icon(Icons.candlestick_chart),
            label: 'Negociar',
          ),
          NavigationDestination(
            icon: Icon(Icons.more_horiz),
            selectedIcon: Icon(Icons.apps_rounded),
            label: 'Extras',
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // App Header with Icon and Name
                Container(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + AppSpacing.xl,
                    bottom: AppSpacing.xl,
                    left: AppSpacing.lg,
                    right: AppSpacing.lg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.show_chart_rounded,
                        size: 48,
                        color: AppColors.primary,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'ZoomTrade',
                        style: context.textStyles.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: context.colors.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                FadeInWidget(
                  delay: const Duration(milliseconds: 50),
                  child: ListTile(
                    leading: const Icon(Icons.account_balance_wallet_outlined),
                    title: const Text('Portfólio'),
                    subtitle: const Text('Visualize seus investimentos'),
                    onTap: () {
                      AppHaptics.selection();
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) => PortfolioScreen(token: widget.token),
                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
                            const begin = Offset(1.0, 0.0);
                            const end = Offset.zero;
                            const curve = Curves.easeInOut;
                            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                            var offsetAnimation = animation.drive(tween);
                            return SlideTransition(position: offsetAnimation, child: child);
                          },
                          transitionDuration: const Duration(milliseconds: 350),
                        ),
                      );
                    },
                  ),
                ),
                FadeInWidget(
                  delay: const Duration(milliseconds: 100),
                  child: ListTile(
                    leading: const Icon(Icons.smart_toy_outlined),
                    title: const Text('Meus Bots'),
                    subtitle: const Text('Gerencie bots de trading'),
                    onTap: () {
                      AppHaptics.selection();
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) => BotsScreen(token: widget.token),
                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
                            const begin = Offset(1.0, 0.0);
                            const end = Offset.zero;
                            const curve = Curves.easeInOut;
                            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                            var offsetAnimation = animation.drive(tween);
                            return SlideTransition(position: offsetAnimation, child: child);
                          },
                          transitionDuration: const Duration(milliseconds: 350),
                        ),
                      );
                    },
                  ),
                ),
                const Divider(),
                FadeInWidget(
                  delay: const Duration(milliseconds: 150),
                  child: ListTile(
                    leading: const Icon(Icons.settings_outlined),
                    title: const Text('Configurações'),
                    subtitle: const Text('Preferências do app'),
                    onTap: () {
                      AppHaptics.selection();
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) => SettingsScreen(onThemeChanged: () {}),
                          transitionsBuilder: (context, animation, secondaryAnimation, child) {
                            const begin = Offset(1.0, 0.0);
                            const end = Offset.zero;
                            const curve = Curves.easeInOut;
                            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                            var offsetAnimation = animation.drive(tween);
                            return SlideTransition(position: offsetAnimation, child: child);
                          },
                          transitionDuration: const Duration(milliseconds: 350),
                        ),
                      );
                    },
                  ),
                ),
                FadeInWidget(
                  delay: const Duration(milliseconds: 200),
                  child: ListTile(
                    leading: const Icon(Icons.help_outline_rounded),
                    title: const Text('Ajuda & Suporte'),
                    subtitle: const Text('Central de ajuda'),
                    onTap: () {
                      AppHaptics.selection();
                      Navigator.pop(context);
                      AppSnackbar.info(context, 'Central de ajuda em breve');
                    },
                  ),
                ),
              ],
            ),
          ),
          // Version at bottom
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              'v1',
              style: context.textStyles.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}