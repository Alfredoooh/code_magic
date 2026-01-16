import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/football_api_service.dart';
import 'match_detail_screen.dart';

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

class _MatchesScreenState extends State<MatchesScreen> with SingleTickerProviderStateMixin {
  String _selectedFilter = 'hoje';
  bool _isLoading = true;
  List<FootballMatch> _matches = [];
  final FootballApiService _apiService = FootballApiService();
  late AnimationController _blinkController;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _loadMatches();
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  Future<void> _loadMatches() async {
    setState(() => _isLoading = true);
    final matches = await _apiService.getTodayMatches();
    if (mounted) {
      setState(() {
        _matches = matches;
        _isLoading = false;
      });
    }
  }

  List<FootballMatch> get _filteredMatches {
    if (_selectedFilter == 'ontem') {
      return _matches.where((m) => m.isFinished).toList();
    } else if (_selectedFilter == 'direto') {
      return _matches.where((m) => m.isLive).toList();
    } else if (_selectedFilter == 'amanha') {
      return [];
    }
    return _matches;
  }

  int _contarJogosAoVivo() {
    return _matches.where((m) => m.isLive).length;
  }

  Map<String, List<FootballMatch>> get _groupedMatches {
    final filtered = _filteredMatches;
    final Map<String, List<FootballMatch>> grouped = {};
    
    for (var match in filtered) {
      if (!grouped.containsKey(match.competition)) {
        grouped[match.competition] = [];
      }
      grouped[match.competition]!.add(match);
    }
    
    return grouped;
  }

  void _openMatchDetails(FootballMatch match) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MatchDetailsScreen(
          matchId: match.id,
          bgColor: widget.bgColor,
          surfaceColor: widget.surfaceColor,
          textColor: widget.textColor,
          subTextColor: widget.subTextColor,
          borderColor: widget.borderColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      color: widget.bgColor,
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: widget.surfaceColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _buildIOSStyleTabs(isDark),
          ),
          Expanded(child: _buildMatchesList()),
        ],
      ),
    );
  }

  Widget _buildIOSStyleTabs(bool isDark) {
    final aoVivoCount = _contarJogosAoVivo();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: isDark 
              ? widget.surfaceColor.withOpacity(0.6)
              : const Color(0xFFE5E5EA),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Expanded(
              child: _IOSStyleTabButton(
                label: 'Ontem',
                isSelected: _selectedFilter == 'ontem',
                onTap: () => setState(() => _selectedFilter = 'ontem'),
                isDark: isDark,
              ),
            ),
            Expanded(
              child: _IOSStyleTabButton(
                label: 'Hoje',
                isSelected: _selectedFilter == 'hoje',
                onTap: () => setState(() => _selectedFilter = 'hoje'),
                isDark: isDark,
              ),
            ),
            Expanded(
              child: _IOSStyleTabButton(
                label: aoVivoCount > 0 ? 'Ao Vivo ($aoVivoCount)' : 'Ao Vivo',
                isSelected: _selectedFilter == 'direto',
                onTap: () => setState(() => _selectedFilter = 'direto'),
                isDark: isDark,
              ),
            ),
            Expanded(
              child: _IOSStyleTabButton(
                label: 'Amanhã',
                isSelected: _selectedFilter == 'amanha',
                onTap: () => setState(() => _selectedFilter = 'amanha'),
                isDark: isDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchesList() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF2374E1)),
        ),
      );
    }

    final groupedMatches = _groupedMatches;

    if (groupedMatches.isEmpty) {
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

    return RefreshIndicator(
      onRefresh: _loadMatches,
      child: ListView.builder(
        padding: EdgeInsets.zero,
        itemCount: groupedMatches.length,
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        itemBuilder: (context, index) {
          final competition = groupedMatches.keys.elementAt(index);
          final matches = groupedMatches[competition]!;
          final isLastLiga = index == groupedMatches.length - 1;
          return _buildCompetitionSection(competition, matches, isLastLiga);
        },
      ),
    );
  }

  Widget _buildCompetitionSection(String competition, List<FootballMatch> matches, bool isLastLiga) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            // Navegar para detalhes da liga se necessário
          },
          child: Container(
            color: widget.surfaceColor,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                if (matches.first.competitionEmblem != null)
                  CachedNetworkImage(
                    imageUrl: matches.first.competitionEmblem!,
                    width: 24,
                    height: 24,
                    errorWidget: (context, url, error) => Icon(
                      Ionicons.trophy,
                      size: 24,
                      color: widget.subTextColor,
                    ),
                  )
                else
                  Icon(Ionicons.trophy, size: 24, color: widget.subTextColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    competition,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: widget.textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${matches.length}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Ionicons.chevron_forward,
                  size: 18,
                  color: widget.subTextColor,
                ),
              ],
            ),
          ),
        ),
        Divider(
          height: 1,
          thickness: 1,
          color: widget.borderColor.withOpacity(0.2),
        ),
        ...matches.asMap().entries.map((entry) {
          final idx = entry.key;
          final match = entry.value;
          final isLast = idx == matches.length - 1;
          return _buildMatchItem(match, isLast);
        }),
        if (!isLastLiga)
          Container(
            height: 8,
            color: widget.borderColor.withOpacity(0.1),
          ),
      ],
    );
  }

  Widget _buildMatchItem(FootballMatch match, bool isLast) {
    final isAoVivoTab = _selectedFilter == 'direto';
    
    return GestureDetector(
      onTap: () => _openMatchDetails(match),
      child: Column(
        children: [
          Container(
            color: widget.surfaceColor,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              match.homeTeam,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: widget.textColor,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(color: widget.borderColor.withOpacity(0.2)),
                            ),
                            padding: const EdgeInsets.all(4),
                            child: match.homeTeamCrest != null
                                ? CachedNetworkImage(
                                    imageUrl: match.homeTeamCrest!,
                                    fit: BoxFit.contain,
                                    errorWidget: (context, url, error) => Icon(
                                      Ionicons.shield_outline,
                                      size: 16,
                                      color: widget.textColor,
                                    ),
                                  )
                                : Icon(
                                    Ionicons.shield_outline,
                                    size: 16,
                                    color: widget.textColor,
                                  ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        match.homeScore != null && match.awayScore != null
                            ? '${match.homeScore} : ${match.awayScore}'
                            : '-:-',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF2374E1),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(color: widget.borderColor.withOpacity(0.2)),
                            ),
                            padding: const EdgeInsets.all(4),
                            child: match.awayTeamCrest != null
                                ? CachedNetworkImage(
                                    imageUrl: match.awayTeamCrest!,
                                    fit: BoxFit.contain,
                                    errorWidget: (context, url, error) => Icon(
                                      Ionicons.shield_outline,
                                      size: 16,
                                      color: widget.textColor,
                                    ),
                                  )
                                : Icon(
                                    Ionicons.shield_outline,
                                    size: 16,
                                    color: widget.textColor,
                                  ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              match.awayTeam,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: widget.textColor,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (match.isLive) ...[
                      AnimatedBuilder(
                        animation: _blinkController,
                        builder: (context, child) {
                          return Text(
                            "${match.timeDisplay}${_blinkController.value > 0.5 ? "'" : ""}",
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF00C853),
                            ),
                          );
                        },
                      ),
                    ] else if (match.isFinished) ...[
                      const Text(
                        'Finalizado',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.red,
                        ),
                      ),
                    ] else ...[
                      Text(
                        match.timeDisplay,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: widget.subTextColor,
                        ),
                      ),
                    ],
                  ],
                ),
                if (match.isLive && !isAoVivoTab) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: const Text(
                      'AO VIVO',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!isLast)
            Divider(
              height: 1,
              thickness: 1,
              color: widget.borderColor.withOpacity(0.2),
            ),
        ],
      ),
    );
  }
}

class _IOSStyleTabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _IOSStyleTabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected 
              ? (isDark ? const Color(0xFF2C2C2E) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.15),
              blurRadius: isDark ? 8 : 4,
              offset: const Offset(0, 1),
            ),
          ] : [],
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isSelected
                  ? (isDark ? Colors.white : Colors.black)
                  : (isDark ? const Color(0xFF8E8E93) : const Color(0xFF3C3C43).withOpacity(0.6)),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}