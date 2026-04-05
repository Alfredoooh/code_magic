// lib/screens/sports_tab.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/app_state.dart';
import '../widgets/match_card.dart';
import 'sport_chip.dart';

class SportsTab extends StatelessWidget {
  const SportsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);

    return RefreshIndicator(
      onRefresh: () => state.loadEvents(),
      color: const Color(0xFF268CD4),
      backgroundColor: const Color(0xFF1A3A6E),
      child: CustomScrollView(
        slivers: [
          // ── Sport chips ──
          SliverToBoxAdapter(
            child: SizedBox(
              height: 90,
              child: state.sports.isEmpty
                  ? const SizedBox()
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      scrollDirection: Axis.horizontal,
                      itemCount: state.sports.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final sport = state.sports[i];
                        return SportChip(
                          sport: sport,
                          active: sport.id == state.activeSportId,
                          onTap: () => state.selectSport(sport),
                        );
                      },
                    ),
            ),
          ),

          // ── Section header ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Row(
                children: [
                  Text(
                    state.activeSportName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700),
                  ),
                  const Spacer(),
                  if (state.events.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF268CD4).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${state.events.length} jogos',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 11,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── Events ──
          if (state.eventsLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF268CD4),
                ),
              ),
            )
          else if (state.events.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.sports_outlined,
                        color: Colors.white.withOpacity(0.2), size: 64),
                    const SizedBox(height: 12),
                    Text(
                      'Sem jogos disponíveis',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                          fontSize: 15),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (_, i) {
                  if (i == state.events.length) {
                    return const SizedBox(height: 100);
                  }
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                    child: MatchCard(event: state.events[i]),
                  );
                },
                childCount: state.events.length + 1,
              ),
            ),
        ],
      ),
    );
  }
}