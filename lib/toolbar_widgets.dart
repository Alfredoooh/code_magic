import 'package:flutter/material.dart';
import 'theme.dart';

// ─── TOOLBAR WIDGETS ─────────────────────────────────────────────────────────
class TbIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const TbIconBtn({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.transparent,
        ),
        child: Icon(icon, size: 20, color: T.sub),
      ),
    );
  }
}

class TbColorBtn extends StatelessWidget {
  final Color color;
  final VoidCallback onTap;

  const TbColorBtn({super.key, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 38,
        width: 38,
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: Colors.transparent,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'A',
              style: T.dmSans(size: 16, w: FontWeight.w900, color: T.sub),
            ),
            const SizedBox(height: 2),
            Container(
              width: 16,
              height: 3,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TbDiv extends StatelessWidget {
  const TbDiv({super.key});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: T.divider,
    );
  }
}

class TbFmtBtn extends StatelessWidget {
  final String label;
  final bool bold;
  final bool italic;
  final bool underline;
  final bool strike;
  final bool active;
  final VoidCallback onTap;

  const TbFmtBtn({
    super.key,
    required this.label,
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.strike = false,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 38,
        width: 38,
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          color: active ? T.accentBg : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
            fontStyle: italic ? FontStyle.italic : FontStyle.normal,
            decoration: underline
                ? TextDecoration.underline
                : strike
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
            color: active ? T.accent : T.sub,
          ),
        ),
      ),
    );
  }
}

class TbAlignBtn extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const TbAlignBtn({
    super.key,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 38,
        height: 38,
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          color: active ? T.accentBg : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Icon(
          icon,
          size: 17,
          color: active ? T.accent : T.sub,
        ),
      ),
    );
  }
}

class TbIconBtnSm extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const TbIconBtnSm({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: Colors.transparent,
        ),
        child: Icon(icon, size: 17, color: T.sub),
      ),
    );
  }
}

class TbChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback onTap;

  const TbChip({super.key, required this.label, this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 32,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(horizontal: 11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: T.divider, width: 1.5),
          color: Colors.transparent,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: T.dmSans(
                size: 12,
                w: FontWeight.w600,
                color: T.ink,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            if (icon != null) ...[
              const SizedBox(width: 4),
              Icon(icon!, size: 11, color: T.sub),
            ],
          ],
        ),
      ),
    );
  }
}
