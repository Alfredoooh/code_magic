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

class _HomeScreenState extends State<HomeScreen> {
  // índice atual da tab
  int _currentIndex = 0;

  // pages lazy-initializadas — mantém estado porque guardamos as instâncias
  final List<Widget?> _pages = [const PostFeed(), null, null, const NotificationsScreen()];

  static const Color _activeBlue = Color(0xFF1877F2);

  // função para construir a página lazily (evita carregar Users/Marketplace até necessário)
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
    if (_currentIndex == index) return; // caso já esteja ativo, nada
    setState(() => _currentIndex = index);
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
      drawer: const CustomDrawer(),
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: SvgIcon(svgString: CustomIcons.menu, color: iconColor),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text(
          'mydoc', // trocado de MySpace para mydoc
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: _activeBlue,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: topBorderColor,
            height: 0.5,
          ),
        ),
      ),

      // IndexedStack preserva o estado das páginas já instanciadas
      body: IndexedStack(
        index: _currentIndex,
        children: List.generate(4, (i) => _getPage(i)),
      ),

      // Bottom navigation custom para permitir indicador acima do ícone com bordas curvas
      bottomNavigationBar: Container(
        height: 70,
        decoration: BoxDecoration(
          color: bgColor,
          border: Border(
            top: BorderSide(color: topBorderColor, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            _buildTabItem(index: 0, svg: CustomIcons.home, isDark: isDark, unselectedColor: unselectedColor),
            _buildTabItem(index: 1, svg: CustomIcons.users, isDark: isDark, unselectedColor: unselectedColor),
            _buildTabItem(index: 2, svg: CustomIcons.marketplace, isDark: isDark, unselectedColor: unselectedColor),
            _buildTabItem(index: 3, svg: CustomIcons.bell, isDark: isDark, unselectedColor: unselectedColor),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem({
    required int index,
    required String svg,
    required bool isDark,
    required Color unselectedColor,
  }) {
    final bool active = _currentIndex == index;
    final Color iconColor = active ? _activeBlue : unselectedColor;

    return Expanded(
      child: InkWell(
        onTap: () => _onTap(index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // indicador ativo em cima do ícone;
            // tem bordas inferiores curvas (bottom corners arredondadas)
            const SizedBox(height: 8),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: active ? 6 : 6,
              width: active ? 36 : 0,
              // quando não ativo, largura vai a 0 (invisível)
              decoration: BoxDecoration(
                color: active ? _activeBlue : Colors.transparent,
                borderRadius: active
                    ? const BorderRadius.only(
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      )
                    : BorderRadius.zero,
              ),
            ),
            const SizedBox(height: 6),
            // ícone
            SvgIcon(svgString: svg, size: 26, color: iconColor),
            const SizedBox(height: 8),
          ],
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