import 'package:flutter/material.dart';
import 'theme.dart';

// ─── DRAWER ITEM ─────────────────────────────────────────────────────────────
class DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const DrawerItem({
    super.key,
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: isActive ? T.accentBg : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? T.accent : T.sub,
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: T.dmSans(
                size: 14,
                w: FontWeight.w500,
                color: isActive ? T.accent : T.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
