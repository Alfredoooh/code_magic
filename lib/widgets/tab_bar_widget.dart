import 'package:flutter/material.dart';

class TabBarWidget extends StatelessWidget {
  final int selectedTab;
  final Function(int) onTabSelected;
  final Color bgColor;
  final Color textColor;
  final Color subTextColor;

  const TabBarWidget({
    Key? key,
    required this.selectedTab,
    required this.onTabSelected,
    required this.bgColor,
    required this.textColor,
    required this.subTextColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: bgColor,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _buildTabButton('Para você', 0),
          const SizedBox(width: 24),
          _buildTabButton('Hoje', 1),
          const SizedBox(width: 24),
          _buildTabButton('Mercado', 2),
        ],
      ),
    );
  }

  Widget _buildTabButton(String text, int index) {
    final isActive = selectedTab == index;
    return GestureDetector(
      onTap: () => onTabSelected(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              color: isActive ? textColor : subTextColor,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            height: 3,
            width: 40,
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF2374E1) : Colors.transparent,
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
        ],
      ),
    );
  }
}