// lib/widgets/match_card.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/app_state.dart';

class MatchCard extends StatelessWidget {
  final SportEvent event;
  const MatchCard({super.key, required this.event});

  String _fmtTime() {
    if (event.begin == null) return '';
    final d = event.begin!.toLocal();
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    String prefix;
    if (d.year == now.year && d.month == now.month && d.day == now.day) {
      prefix = 'Hoje';
    } else if (d.year == tomorrow.year &&
        d.month == tomorrow.month &&
        d.day == tomorrow.day) {
      prefix = 'Amanhã';
    } else {
      prefix =
          '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
    }
    return '$prefix ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final odds = event.mainOdds;

    return Card(
      child: Column(
        children: [
          // ── Header ──
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF0D1B3E).withOpacity(0.5),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    event.competitionName,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 10,
                        fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (event.isLive)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFFD60000),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text('AO VIVO',
                          style: TextStyle(
                              color: Color(0xFFD60000),
                              fontSize: 10,
                              fontWeight: FontWeight.w700)),
                    ],
                  )
                else
                  Text(
                    _fmtTime(),
                    style: const TextStyle(
                        color: Color(0xFFFFCE00),
                        fontSize: 10,
                        fontWeight: FontWeight.w700),
                  ),
              ],
            ),
          ),

          // ── Teams ──
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    event.home,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text('VS',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.3),
                          fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ),
                Expanded(
                  child: Text(
                    event.away,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),

          // ── Odds ──
          if (odds.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Text('Odds indisponíveis',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.3),
                      fontSize: 12)),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Row(
                children: odds
                    .asMap()
                    .entries
                    .map((entry) => Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                                left: entry.key > 0 ? 6 : 0),
                            child: _OddButton(
                              odd: entry.value,
                              col: entry.key,
                              event: event,
                              selected: state.isBetSelected(
                                  event.sportEventId, entry.key),
                              onTap: () => state.toggleBet(
                                  event, entry.key, entry.value),
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
        ],
      ),
    );
  }
}

class _OddButton extends StatelessWidget {
  final Odd odd;
  final int col;
  final SportEvent event;
  final bool selected;
  final VoidCallback onTap;

  const _OddButton({
    required this.odd,
    required this.col,
    required this.event,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (odd.suspended || odd.value <= 0) {
      return Container(
        height: 50,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Icon(Icons.lock_outline_rounded,
              color: Colors.white.withOpacity(0.2), size: 14),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 50,
        decoration: BoxDecoration(
          color: selected
              ? Colors.transparent
              : const Color(0xFFBFE3FC).withOpacity(0.12),
          gradient: selected
              ? const LinearGradient(
                  colors: [Color(0xFFFF1493), Color(0xFFC900D0)],
                )
              : null,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : Colors.white.withOpacity(0.1),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              odd.label,
              style: TextStyle(
                  color: selected
                      ? Colors.white
                      : Colors.white.withOpacity(0.5),
                  fontSize: 10,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 2),
            Text(
              odd.value.toStringAsFixed(2),
              style: TextStyle(
                  color: selected
                      ? Colors.white
                      : const Color(0xFF112F6C),
                  fontSize: 14,
                  fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}