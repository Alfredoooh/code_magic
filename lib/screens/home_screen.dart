// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
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
            icon: CustomPaint(
              size: const Size(24, 24),
              painter: IconPainter(CustomIcons.menu, iconColor),
            ),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: Text(
          'facebook',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1877F2),
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: CustomPaint(
              size: const Size(24, 24),
              painter: IconPainter(CustomIcons.plus, iconColor),
            ),
            onPressed: () => _showNewPostModal(context),
          ),
          IconButton(
            icon: CustomPaint(
              size: const Size(24, 24),
              painter: IconPainter(CustomIcons.search, iconColor),
            ),
            onPressed: () => Navigator.pushNamed(context, '/search'),
          ),
          IconButton(
            icon: CustomPaint(
              size: const Size(24, 24),
              painter: IconPainter(CustomIcons.inbox, iconColor),
            ),
            onPressed: () => Navigator.pushNamed(context, '/messages'),
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
              () => Navigator.pushNamed(context, '/users'),
              false,
            ),
            _buildNavItem(
              context,
              CustomIcons.marketplace,
              'Marketplace',
              () => Navigator.pushNamed(context, '/marketplace'),
              false,
            ),
            _buildNavItem(
              context,
              CustomIcons.bell,
              'Notificações',
              () => Navigator.pushNamed(context, '/notifications'),
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
    String iconPath,
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
              ? BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: const Color(0xFF1877F2),
                      width: 3,
                    ),
                  ),
                )
              : null,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CustomPaint(
                size: const Size(26, 26),
                painter: IconPainter(iconPath, color),
              ),
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