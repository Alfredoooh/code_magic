import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

class AppHeader extends StatelessWidget {
  final VoidCallback onMenuTap;
  final VoidCallback onSearchTap;
  final Color bgColor;
  final Color borderColor;
  final Color textColor;
  final bool isDarkTheme;

  const AppHeader({
    Key? key,
    required this.onMenuTap,
    required this.onSearchTap,
    required this.bgColor,
    required this.borderColor,
    required this.textColor,
    required this.isDarkTheme,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isDarkTheme ? bgColor : Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: onMenuTap,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: borderColor.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Ionicons.menu_outline,
                  size: 22,
                  color: textColor,
                ),
              ),
            ),
            Image.asset(
              'assets/logo.png',
              width: 36,
              height: 36,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2374E1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Ionicons.football,
                    color: Colors.white,
                    size: 20,
                  ),
                );
              },
            ),
            GestureDetector(
              onTap: onSearchTap,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: borderColor.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Ionicons.search_outline,
                  size: 20,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}