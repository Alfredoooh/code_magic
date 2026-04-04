// lib/widgets/sport_chip.dart
import 'package:flutter/material.dart';
import '../models/models.dart';

const _iconMap = {
  'football': 'sport_icon_football',
  'soccer': 'sport_icon_football',
  'futebol': 'sport_icon_football',
  'basketball': 'sport_icon_basketball',
  'basquete': 'sport_icon_basketball',
  'tennis': 'sport_icon_tennis',
  'ténis': 'sport_icon_tennis',
  'handball': 'sport_icon_handball',
  'andebol': 'sport_icon_handball',
  'volleyball': 'sport_icon_volleyball',
  'voleibol': 'sport_icon_volleyball',
  'hockey': 'sport_icon_hockey',
  'hóquei': 'sport_icon_hockey',
  'rugby': 'sport_icon_rugby',
  'baseball': 'sport_icon_baseball',
  'boxing': 'sport_icon_boxe',
  'boxe': 'sport_icon_boxe',
  'golf': 'sport_icon_golf',
  'golfe': 'sport_icon_golf',
  'cricket': 'sport_icon_cricket',
  'table tennis': 'sport_icon_pingpong',
  'ping pong': 'sport_icon_pingpong',
  'waterpolo': 'sport_icon_waterpolo',
  'badminton': 'sport_icon_badminton',
  'cycling': 'sport_icon_bike',
  'ciclismo': 'sport_icon_bike',
  'moto': 'sport_icon_moto',
  'motorsport': 'sport_icon_moto',
};

String _getIcon(String name) {
  final lower = name.toLowerCase();
  for (final entry in _iconMap.entries) {
    if (lower.contains(entry.key)) return entry.value;
  }
  return 'sport_icon_default';
}

class SportChip extends StatelessWidget {
  final Sport sport;
  final bool active;
  final VoidCallback onTap;

  const SportChip({
    super.key,
    required this.sport,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 72,
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFF268CD4).withOpacity(0.2)
              : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active
                ? const Color(0xFF268CD4)
                : Colors.white.withOpacity(0.12),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/icons/${_getIcon(sport.name)}.png',
              width: 28,
              height: 28,
              errorBuilder: (_, __, ___) => Image.asset(
                'assets/icons/sport_icon_default.png',
                width: 28,
                height: 28,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              sport.name,
              style: TextStyle(
                color: active
                    ? const Color(0xFF268CD4)
                    : Colors.white.withOpacity(0.6),
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}