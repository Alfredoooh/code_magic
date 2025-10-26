// lib/home_screen.dart
import 'package:flutter/material.dart';
import 'styles.dart' hide EdgeInsets;
import 'markets_screen.dart';
import 'posts_screen.dart';
import 'trade_screen.dart';
import 'bots_screen.dart';
import 'portfolio_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final String token;

  const HomeScreen({Key? key, required this.token}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      MarketsScreen(token: widget.token),
      _TradingCenterScreen(token: widget.token),
      PostsScreen(token: widget.token),
    ];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openSearchScreen() {
    AppHaptics.light();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _SearchScreen(token: widget.token),
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
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () {
            AppHaptics.light();
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
        title: Text(_getAppBarTitle()),
        actions: [
          if (_currentIndex == 0) // Mostrar busca apenas na tela de Mercados
            IconButton(
              icon: const Icon(Icons.search_rounded),
              onPressed: _openSearchScreen,
            ),
        ],
      ),
      drawer: _buildDrawer(),
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          AppHaptics.selection();
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
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
                    borderRadius: BorderRadius.circular(AppShapes.large),
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
                  borderRadius: BorderRadius.circular(AppShapes.small),
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
                  MaterialPageRoute(
                    builder: (context) => PortfolioScreen(token: widget.token),
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
                  borderRadius: BorderRadius.circular(AppShapes.small),
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
                  MaterialPageRoute(
                    builder: (context) => BotsScreen(token: widget.token),
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
                  borderRadius: BorderRadius.circular(AppShapes.small),
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
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
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
                  borderRadius: BorderRadius.circular(AppShapes.small),
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

// Tela Central de Negociação
class _TradingCenterScreen extends StatelessWidget {
  final String token;

  const _TradingCenterScreen({required this.token});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FadeInWidget(
                child: Icon(
                  Icons.candlestick_chart_rounded,
                  size: 120,
                  color: context.colors.primary.withOpacity(0.3),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              FadeInWidget(
                delay: const Duration(milliseconds: 100),
                child: Text(
                  'Central de Negociação',
                  style: context.textStyles.headlineMedium,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              FadeInWidget(
                delay: const Duration(milliseconds: 200),
                child: Text(
                  'Escolha como deseja operar no mercado',
                  style: context.textStyles.bodyLarge?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppSpacing.massive),
              FadeInWidget(
                delay: const Duration(milliseconds: 300),
                child: SizedBox(
                  width: double.infinity,
                  child: AnimatedPrimaryButton(
                    text: 'Negociar Manualmente',
                    icon: Icons.touch_app_rounded,
                    onPressed: () {
                      AppHaptics.heavy();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TradeScreen(token: token),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              FadeInWidget(
                delay: const Duration(milliseconds: 400),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      AppHaptics.heavy();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BotsScreen(token: token),
                        ),
                      );
                    },
                    icon: const Icon(Icons.smart_toy_rounded),
                    label: const Text('Automatizar com Bots'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.md,
                        horizontal: AppSpacing.xl,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              FadeInWidget(
                delay: const Duration(milliseconds: 500),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppShapes.medium),
                    border: Border.all(
                      color: AppColors.info.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_rounded,
                        color: AppColors.info,
                        size: 24,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          'Bots automatizam suas operações com estratégias inteligentes',
                          style: context.textStyles.bodySmall?.copyWith(
                            color: AppColors.info,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Tela de Pesquisa
class _SearchScreen extends StatefulWidget {
  final String token;

  const _SearchScreen({required this.token});

  @override
  State<_SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<_SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<String> _searchResults = [];

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _searchFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    // Simulação de busca
    final markets = ['R_100', 'R_50', 'R_25', 'R_75', 'BOOM500', 'BOOM1000', 'CRASH500'];
    setState(() {
      _searchResults = markets
          .where((m) => m.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          style: context.textStyles.bodyLarge,
          decoration: InputDecoration(
            hintText: 'Pesquisar mercados...',
            border: InputBorder.none,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded),
                    onPressed: () {
                      AppHaptics.light();
                      setState(() {
                        _searchController.clear();
                        _searchResults = [];
                      });
                    },
                  )
                : null,
          ),
          onChanged: _performSearch,
        ),
      ),
      body: _searchController.text.isEmpty
          ? EmptyStateWithAction(
              icon: Icons.search_rounded,
              title: 'Pesquisar Mercados',
              subtitle: 'Digite para buscar mercados disponíveis',
            )
          : _searchResults.isEmpty
              ? EmptyStateWithAction(
                  icon: Icons.search_off_rounded,
                  title: 'Nenhum resultado',
                  subtitle: 'Tente buscar por outro termo',
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    return StaggeredListItem(
                      index: index,
                      child: InfoCard(
                        icon: Icons.show_chart_rounded,
                        title: _searchResults[index],
                        subtitle: 'Mercado sintético',
                        color: AppColors.primary,
                        onTap: () {
                          AppHaptics.selection();
                          AppSnackbar.info(context, 'Mercado ${_searchResults[index]} selecionado');
                        },
                      ),
                    );
                  },
                ),
    );
  }
}