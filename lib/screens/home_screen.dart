// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/custom_icons.dart';
import '../widgets/custom_drawer.dart';
import '../widgets/post_feed.dart';
import '../widgets/new_post_modal.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final bgColor = isDark ? const Color(0xFF242526) : Colors.white;
    final iconColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);

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
          'facebook',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1877F2),
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
              CupertinoPageRoute(builder: (_) => const SearchScreen()),
            ),
          ),
          IconButton(
            icon: SvgIcon(svgString: CustomIcons.inbox, color: iconColor),
            onPressed: () => Navigator.of(context).push(
              CupertinoPageRoute(builder: (_) => const MessagesScreen()),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: isDark ? const Color(0xFF3E4042) : const Color(0xFFDADADA),
            height: 0.5,
          ),
        ),
      ),
      body: const PostFeed(),
      bottomNavigationBar: Container(
        height: 56,
        decoration: BoxDecoration(
          color: bgColor,
          border: Border(
            top: BorderSide(
              color: isDark ? const Color(0xFF3E4042) : const Color(0xFFDADADA),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              context,
              CustomIcons.home,
              'Início',
              () {},
              true,
            ),
            _buildNavItem(
              context,
              CustomIcons.users,
              'Usuários',
              () => Navigator.of(context).push(
                CupertinoPageRoute(builder: (_) => const UsersScreen()),
              ),
              false,
            ),
            _buildNavItem(
              context,
              CustomIcons.marketplace,
              'Marketplace',
              () => Navigator.of(context).push(
                CupertinoPageRoute(builder: (_) => const MarketplaceScreen()),
              ),
              false,
            ),
            _buildNavItem(
              context,
              CustomIcons.bell,
              'Notificações',
              () => Navigator.of(context).push(
                CupertinoPageRoute(builder: (_) => const NotificationsScreen()),
              ),
              false,
            ),
            _buildNavItem(
              context,
              CustomIcons.menu,
              'Opções',
              () => Scaffold.of(context).openDrawer(),
              false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    String iconSvg,
    String label,
    VoidCallback onTap,
    bool isActive,
  ) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final color = isActive
        ? const Color(0xFF1877F2)
        : (isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B));

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 56,
          decoration: isActive
              ? const BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Color(0xFF1877F2),
                      width: 3,
                    ),
                  ),
                )
              : null,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgIcon(svgString: iconSvg, color: color, size: 26),
            ],
          ),
        ),
      ),
    );
  }

  void _showNewPostModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const NewPostModal(),
    );
  }
}

// Placeholder screens
class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Pesquisar')),
    body: const Center(child: Text('Pesquisar')),
  );
}

class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Usuários')),
    body: const Center(child: Text('Usuários')),
  );
}

class MarketplaceScreen extends StatelessWidget {
  const MarketplaceScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Marketplace')),
    body: const Center(child: Text('Marketplace')),
  );
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Notificações')),
    body: const Center(child: Text('Notificações')),
  );
}