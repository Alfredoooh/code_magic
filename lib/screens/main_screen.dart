import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../services/theme_service.dart';
import '../services/user_data_service.dart';
import 'tabs/home_tab.dart';
import 'tabs/hub_tab.dart';
import 'tabs/converter_tab.dart';
import 'tabs/news_tab.dart';
import 'tabs/chats_tab.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _tabs = [
    const HomeTab(),
    const HubTab(),
    const ConverterTab(),
    const NewsTab(),
    const ChatsTab(),
  ];

  @override
  void initState() {
    super.initState();
    UserDataService.updateLastActivity('Opened app');
  }

  void _onTabSelected(int index) {
    setState(() {
      _selectedIndex = index;
    });

    final tabNames = ['Home', 'Hub', 'Converter', 'News', 'Chats'];
    UserDataService.updateLastActivity('Opened ${tabNames[index]} tab');
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = ThemeService.currentTheme == AppTheme.deepDark
        ? const Color(0xFF000000)
        : ThemeService.currentTheme == AppTheme.dark
            ? const Color(0xFF1C1C1E)
            : const Color(0xFFF2F2F7);

    final tabBarBgColor = ThemeService.currentTheme == AppTheme.deepDark
        ? const Color(0xFF1C1C1E)
        : ThemeService.currentTheme == AppTheme.dark
            ? const Color(0xFF2C2C2E)
            : const Color(0xFFFFFFFF);

    final iconColor = ThemeService.currentTheme == AppTheme.light
        ? const Color(0xFF8E8E93)
        : const Color(0xFF8E8E93);

    return Scaffold(
      backgroundColor: bgColor,
      body: _tabs[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: tabBarBgColor,
          border: Border(
            top: BorderSide(
              color: iconColor.withOpacity(0.2),
              width: 0.5,
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTabItem(
                  icon: CupertinoIcons.home,
                  label: 'Início',
                  index: 0,
                  iconColor: iconColor,
                ),
                _buildTabItem(
                  icon: CupertinoIcons.square_grid_2x2,
                  label: 'Hub',
                  index: 1,
                  iconColor: iconColor,
                ),
                _buildTabItem(
                  icon: CupertinoIcons.arrow_2_squarepath,
                  label: 'Conversor',
                  index: 2,
                  iconColor: iconColor,
                ),
                _buildTabItem(
                  icon: CupertinoIcons.news,
                  label: 'Atualidade',
                  index: 3,
                  iconColor: iconColor,
                ),
                _buildTabItem(
                  icon: CupertinoIcons.chat_bubble_2,
                  label: 'Chats',
                  index: 4,
                  iconColor: iconColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem({
    required IconData icon,
    required String label,
    required int index,
    required Color iconColor,
  }) {
    final isSelected = _selectedIndex == index;
    final activeColor = const Color(0xFF1877F2);

    return GestureDetector(
      onTap: () => _onTabSelected(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 26,
              color: isSelected ? activeColor : iconColor,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isSelected ? activeColor : iconColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
