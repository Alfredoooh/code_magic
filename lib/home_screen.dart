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
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
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
        return 'Publicações';
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
      body: SlideTransition(
        position: _slideAnimation,
        child: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          AppHaptics.selection();
          setState(() => _currentIndex = index);
          _animationController.reset();
          _animationController.forward();
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(Icons.swap_horiz_rounded),
            selectedIcon: Icon(Icons.swap_horiz_rounded),
            label: 'Negociar',
          ),
          NavigationDestination(
            icon: Icon(Icons.article_outlined),
            selectedIcon: Icon(Icons.article_rounded),
            label: 'Publicações',
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary,
                  AppColors.primary.withOpacity(0.7),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: const Icon(
                    Icons.person_rounded,
                    size: 32,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Usuário',
                  style: context.textStyles.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'usuario@email.com',
                  style: context.textStyles.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          FadeInWidget(
            delay: const Duration(milliseconds: 50),
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: const Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary),
              ),
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
              leading: Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: const Icon(Icons.smart_toy_rounded, color: AppColors.secondary),
              ),
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
              leading: Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: const Icon(Icons.settings_rounded, color: AppColors.info),
              ),
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
              leading: Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: const Icon(Icons.help_rounded, color: AppColors.warning),
              ),
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
    );
  }
}