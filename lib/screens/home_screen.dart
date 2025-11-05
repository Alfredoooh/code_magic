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
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
          'MySpace',
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
            color: isDark ? const Color(0xFF3E4042) : const Color(0xFFDADADA),
            height: 0.5,
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          PostFeed(),
          UsersScreen(),
          MarketplaceScreen(),
          NotificationsScreen(),
        ],
      ),
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
        child: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF1877F2),
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelColor: const Color(0xFF1877F2),
          unselectedLabelColor: isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B),
          tabs: [
            Tab(
              height: 56,
              child: SvgIcon(svgString: CustomIcons.home, size: 26),
            ),
            Tab(
              height: 56,
              child: SvgIcon(svgString: CustomIcons.users, size: 26),
            ),
            Tab(
              height: 56,
              child: SvgIcon(svgString: CustomIcons.marketplace, size: 26),
            ),
            Tab(
              height: 56,
              child: SvgIcon(svgString: CustomIcons.bell, size: 26),
            ),
          ],
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