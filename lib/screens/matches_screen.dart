import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import '../models.dart';

class MatchesScreen extends StatefulWidget {
  final Color bgColor;
  final Color surfaceColor;
  final Color textColor;
  final Color subTextColor;
  final Color borderColor;

  const MatchesScreen({
    Key? key,
    required this.bgColor,
    required this.surfaceColor,
    required this.textColor,
    required this.subTextColor,
    required this.borderColor,
  }) : super(key: key);

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  int _selectedFilter = 0; // 0: Hoje, 1: Ao Vivo, 2: Finalizados

  List<Match> get _filteredMatches {
    final matches = RssSources.todayMatches;
    if (_selectedFilter == 1) {
      return matches.where((m) => m.isLive).toList();
    } else if (_selectedFilter == 2) {
      return matches.where((m) => m.isFinished).toList();
    }
    return matches;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: widget.bgColor,
      child: Column(
        children: [
          _buildFilterBar(),
          Expanded(child: _buildMatchesList()),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _buildFilterChip('Hoje', 0),
          const SizedBox(width: 12),
          _buildFilterChip('Ao Vivo', 1),
          const SizedBox(width: 12),
          _buildFilterChip('Finalizados', 2),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int index) {
    final isSelected = _selectedFilter == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2374E1) : widget.surfaceColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF2374E1) : widget.borderColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : widget.textColor,
          ),
        ),
      ),
    );
  }

  Widget _buildMatchesList() {
    final matches = _filteredMatches;

    if (matches.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Ionicons.football_outline, size: 64, color: widget.borderColor),
            const SizedBox(height: 16),
            Text(
              'Nenhuma partida encontrada',
              style: TextStyle(fontSize: 15, color: widget.subTextColor),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: matches.length,
      itemBuilder: (context, index) {
        return _buildMatchCard(matches[index]);
      },
    );
  }

  Widget _buildMatchCard(Match match) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: widget.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: match.isLive
                        ? Colors.red.withOpacity(0.1)
                        : widget.borderColor.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    match.isLive ? 'AO VIVO' : match.competition,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: match.isLive ? Colors.red : widget.subTextColor,
                    ),
                  ),
                ),
                if (!match.isLive && !match.isFinished)
                  Text(
                    match.time,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: widget.subTextColor,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.borderColor.withOpacity(0.3),
                        ),
                        child: Icon(
                          Ionicons.shield_outline,
                          color: widget.textColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        match.homeTeam,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: widget.textColor,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Column(
                  children: [
                    Text(
                      '${match.homeScore} - ${match.awayScore}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: widget.textColor,
                      ),
                    ),
                    if (match.isFinished)
                      Text(
                        'FT',
                        style: TextStyle(
                          fontSize: 12,
                          color: widget.subTextColor,
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.borderColor.withOpacity(0.3),
                        ),
                        child: Icon(
                          Ionicons.shield_outline,
                          color: widget.textColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        match.awayTeam,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: widget.textColor,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (match.isLive) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Transmissão ao vivo',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}