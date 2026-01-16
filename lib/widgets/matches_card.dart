import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import '../services/football_service.dart';

class MatchesCard extends StatefulWidget {
  final Color surfaceColor;
  final Color textColor;
  final Color subTextColor;
  final Color borderColor;

  const MatchesCard({
    Key? key,
    required this.surfaceColor,
    required this.textColor,
    required this.subTextColor,
    required this.borderColor,
  }) : super(key: key);

  @override
  State<MatchesCard> createState() => _MatchesCardState();
}

class _MatchesCardState extends State<MatchesCard> {
  final FootballService _footballService = FootballService();
  List<dynamic> _matches = [];
  int _currentPage = 0;
  bool _isLoading = true;

  // IDs das principais ligas europeias
  final List<int> _topLeagueIds = [
    39,  // Premier League
    140, // La Liga
    135, // Serie A
    78,  // Bundesliga
    61,  // Ligue 1
    2,   // UEFA Champions League
    3,   // UEFA Europa League
  ];

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    setState(() => _isLoading = true);
    
    try {
      final today = DateTime.now();
      final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      
      List<dynamic> allMatches = [];
      
      // Busca partidas de cada liga
      for (int leagueId in _topLeagueIds) {
        try {
          final matches = await _footballService.getFixturesByLeague(leagueId, dateStr);
          if (matches.isNotEmpty) {
            allMatches.addAll(matches);
          }
        } catch (e) {
          print('Erro ao buscar partidas da liga $leagueId: $e');
        }
      }
      
      // Ordena por status (ao vivo primeiro) e depois por horário
      allMatches.sort((a, b) {
        final statusA = a['fixture']['status']['short'];
        final statusB = b['fixture']['status']['short'];
        
        // Prioriza jogos ao vivo
        if (statusA == '1H' || statusA == '2H' || statusA == 'HT') return -1;
        if (statusB == '1H' || statusB == '2H' || statusB == 'HT') return 1;
        
        // Depois ordena por horário
        final timeA = DateTime.parse(a['fixture']['date']);
        final timeB = DateTime.parse(b['fixture']['date']);
        return timeA.compareTo(timeB);
      });
      
      setState(() {
        _matches = allMatches;
        _isLoading = false;
      });
    } catch (e) {
      print('Erro ao carregar partidas: $e');
      setState(() => _isLoading = false);
    }
  }

  String _getStatusText(dynamic fixture) {
    final status = fixture['fixture']['status']['short'];
    final elapsed = fixture['fixture']['status']['elapsed'];
    
    if (status == '1H' || status == '2H') return 'AO VIVO';
    if (status == 'HT') return 'INTERVALO';
    if (status == 'FT') return 'ENCERRADO';
    if (status == 'NS') {
      final date = DateTime.parse(fixture['fixture']['date']).toLocal();
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    }
    return status;
  }

  bool _isLive(dynamic fixture) {
    final status = fixture['fixture']['status']['short'];
    return status == '1H' || status == '2H' || status == 'HT';
  }

  String _getTimeText(dynamic fixture) {
    final status = fixture['fixture']['status']['short'];
    final elapsed = fixture['fixture']['status']['elapsed'];
    
    if (status == 'FT') return 'FT';
    if (status == 'HT') return 'HT';
    if (status == '1H' || status == '2H') return "$elapsed'";
    
    return '';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: widget.surfaceColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_matches.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: widget.surfaceColor,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(Ionicons.football_outline, size: 48, color: widget.subTextColor),
            const SizedBox(height: 12),
            Text(
              'Nenhuma partida hoje',
              style: TextStyle(color: widget.subTextColor, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Ionicons.football_outline, size: 18, color: widget.textColor),
                const SizedBox(width: 8),
                Text(
                  'Jogos de Hoje',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: widget.textColor,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 140,
            child: PageView.builder(
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemCount: _matches.length,
              itemBuilder: (context, index) {
                return _buildMatchItem(_matches[index]);
              },
            ),
          ),
          const SizedBox(height: 12),
          if (_matches.length > 1)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _matches.length > 10 ? 10 : _matches.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentPage == index
                        ? const Color(0xFF2374E1)
                        : widget.borderColor,
                  ),
                ),
              ),
            ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildMatchItem(dynamic match) {
    final homeTeam = match['teams']['home']['name'];
    final awayTeam = match['teams']['away']['name'];
    final homeScore = match['goals']['home'] ?? 0;
    final awayScore = match['goals']['away'] ?? 0;
    final competition = match['league']['name'];
    final isLive = _isLive(match);
    final statusText = _getStatusText(match);
    final timeText = _getTimeText(match);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isLive
                  ? Colors.red.withOpacity(0.1)
                  : widget.borderColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              isLive ? 'AO VIVO' : competition,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isLive ? Colors.red : widget.subTextColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  homeTeam,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: widget.textColor,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: widget.borderColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$homeScore - $awayScore',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: widget.textColor,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  awayTeam,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: widget.textColor,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            timeText.isEmpty ? statusText : timeText,
            style: TextStyle(
              fontSize: 12,
              color: widget.subTextColor,
            ),
          ),
        ],
      ),
    );
  }
}