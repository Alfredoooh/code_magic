import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ionicons/ionicons.dart';
import '../svg_icons.dart';

class AppHeader extends StatelessWidget {
  final VoidCallback onMenuTap;
  final VoidCallback onSearchTap;
  final Color bgColor;
  final Color borderColor;
  final Color textColor;

  const AppHeader({
    Key? key,
    required this.onMenuTap,
    required this.onSearchTap,
    required this.bgColor,
    required this.borderColor,
    required this.textColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: bgColor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: onMenuTap,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: borderColor,
                ),
                child: Center(
                  child: SvgPicture.string(
                    SvgIcons.profileFilled,
                    width: 18,
                    height: 18,
                    colorFilter: ColorFilter.mode(textColor, BlendMode.srcIn),
                  ),
                ),
              ),
            ),
            Image.asset(
              'assets/logo.png',
              width: 32,
              height: 32,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 32,
                  height: 32,
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
              child: SvgPicture.string(
                SvgIcons.search,
                width: 24,
                height: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}