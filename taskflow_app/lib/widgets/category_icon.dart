import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../models/task.dart';

class CategoryIcon extends StatelessWidget {
  final TaskCategory category;
  final double size;
  final bool showBackground;

  const CategoryIcon({
    super.key,
    required this.category,
    this.size = 20,
    this.showBackground = true,
  });

  IconData get _icon {
    switch (category) {
      case TaskCategory.personal:
        return LucideIcons.user;
      case TaskCategory.work:
        return LucideIcons.briefcase;
      case TaskCategory.health:
        return LucideIcons.heart_pulse;
      case TaskCategory.finance:
        return LucideIcons.wallet;
      case TaskCategory.education:
        return LucideIcons.graduation_cap;
      case TaskCategory.shopping:
        return LucideIcons.shopping_cart;
      case TaskCategory.other:
        return LucideIcons.tag;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!showBackground) {
      return Icon(_icon, size: size, color: category.color);
    }

    return Container(
      width: size * 1.8,
      height: size * 1.8,
      decoration: BoxDecoration(
        color: category.color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(size * 0.5),
      ),
      child: Icon(_icon, size: size, color: category.color),
    );
  }
}
