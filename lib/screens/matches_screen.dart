import 'dart:async';
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

class _MatchesScreenState extends State<MatchesScreen> with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late AnimationController _blinkController;
  Timer? _autoRefreshTimer;

  final Map<String, List<FootballMatch>> _cacheJogosPorFiltro = {};

  final List<String> _ligasPrioritarias = [
    'LaLiga',
    'Premier League',
    'Serie A',
    'Bundesliga',
    'Ligue 1',
    'UEFA Champions League',
    'UEFA Europa League',
    'Liga Portugal',
  ];

  String _selectedFilter = 'hoje';
  String? _lastFiltro;
  bool _isLoadingNewTab = false;
  int _contentKey = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMatches();
      _startAutoRefresh();
    });
  }

  void _startAutoRefresh() {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        _refreshCurrentTab();
      }
    });
  }

  Future<void> _refreshCurrentTab() async {
    _cacheJogosPorFiltro.remove(_selectedFilter);
    await _loadMatches();
  }

  @override
  void dispose() {
    _blinkController.dispose();
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(MatchesScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_lastFiltro != _selectedFilter) {
      _lastFiltro = _selectedFilter;
      if (mounted) {
        setState(() {
          _contentKey++;
        });
      }
    }
  }

  Future<void> _loadMatches() async {
    if (!mounted) return;

    if (_cacheJogosPorFiltro.containsKey(_selectedFilter)) {
      if (mounted) {
        setState(() {
          _isLoadingNewTab = false;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoadingNewTab = true;
      });
    }

    final _apiService = FootballApiService();

    try {
      final matches = await _apiService.getTodayMatches();

      if (mounted) {
        setState(() {
          _cacheJogosPorFiltro[_selectedFilter] = matches;
          _isLoadingNewTab = false;
          _contentKey++;
        });
      }
    } catch (e) {
      debugPrint('❌ Erro ao carregar jogos: $e');
      if (mounted) {
        setState(() {
          _isLoadingNewTab = false;
          _cacheJogosPorFiltro[_selectedFilter] = [];
        });
      }
    }
  }

  List<FootballMatch> _filteredMatches() {
    final matches = _cacheJogosPorFiltro[_selectedFilter] ?? [];
    
    if (_selectedFilter == 'ontem') {
      return matches.where((m) => m.isFinished).toList();
    } else if (_selectedFilter == 'direto') {
      return matches.where((m) => m.isLive).toList();
    } else if (_selectedFilter == 'amanha') {
      return [];
    }
    return matches;
  }

  int _contarJogosAoVivo() {
    final matches = _cacheJogosPorFiltro[_selectedFilter] ?? [];
    return matches.where((m) => m.isLive).length;
  }

  int _getPrioridadeLiga(String ligaNome) {
    final index = _ligasPrioritarias.indexWhere(
      (liga) => ligaNome.toLowerCase().contains(liga.toLowerCase())
    );
    return index == -1 ? 999 : index;
  }

  Map<String, List<FootballMatch>> _groupedMatches() {
    final filtered = _filteredMatches();
    final Map<String, List<FootballMatch>> grouped = {};

    for (var match in filtered) {
      if (!grouped.containsKey(match.competition)) {
        grouped[match.competition] = [];
      }
      grouped[match.competition]!.add(match);
    }

    return grouped;
  }

  void _onFilterChanged(String newFilter) {
    if (_selectedFilter == newFilter) return;

    if (_cacheJogosPorFiltro.containsKey(newFilter)) {
      setState(() {
        _selectedFilter = newFilter;
        _contentKey++;
      });
    } else {
      setState(() {
        _selectedFilter = newFilter;
        _isLoadingNewTab = true;
        _contentKey++;
      });
      _loadMatches();
    }
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

  void _showQuickMatchDetails(BuildContext context, FootballMatch match) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _QuickMatchDetailsModal(
        match: match,
        bgColor: widget.bgColor,
        surfaceColor: widget.surfaceColor,
        textColor: widget.textColor,
        subTextColor: widget.subTextColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
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
          child: _buildToggleButtons(isDark),
        ),
        Expanded(
          child: _buildContent(),
        ),
      ],
    );
  }

  Widget _buildToggleButtons(bool isDark) {
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
                onTap: () => _onFilterChanged('ontem'),
                isDark: isDark,
              ),
            ),
            Expanded(
              child: _IOSStyleTabButton(
                label: 'Hoje',
                isSelected: _selectedFilter == 'hoje',
                onTap: () => _onFilterChanged('hoje'),
                isDark: isDark,
              ),
            ),
            Expanded(
              child: _IOSStyleTabButton(
                label: aoVivoCount > 0 ? 'Ao Vivo ($aoVivoCount)' : 'Ao Vivo',
                isSelected: _selectedFilter == 'direto',
                onTap: () => _onFilterChanged('direto'),
                isDark: isDark,
                isLive: true,
              ),
            ),
            Expanded(
              child: _IOSStyleTabButton(
                label: 'Amanhã',
                isSelected: _selectedFilter == 'amanha',
                onTap: () => _onFilterChanged('amanha'),
                isDark: isDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final matches = _cacheJogosPorFiltro[_selectedFilter];

    if (_isLoadingNewTab && matches == null) {
      return Center(
        child: CircularProgressIndicator(
          color: const Color(0xFF2374E1),
        ),
      );
    }

    if (matches == null) {
      return const Center(
        child: Text(
          'Sem ligação à rede\nPor favor, tente mais tarde',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14),
        ),
      );
    }

    return _buildCachedContent();
  }

  Widget _buildCachedContent() {
    final groupedMatches = _groupedMatches();

    if (groupedMatches.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.3),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Ionicons.football_outline,
                  size: 64,
                  color: widget.borderColor.withOpacity(0.3),
                ),
                const SizedBox(height: 16),
                Text(
                  'Nenhum jogo ${_getTituloFiltro(_selectedFilter)}',
                  style: TextStyle(color: widget.subTextColor),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final sortedCompetitions = groupedMatches.keys.toList()
      ..sort((a, b) {
        final prioA = _getPrioridadeLiga(a);
        final prioB = _getPrioridadeLiga(b);
        return prioA.compareTo(prioB);
      });

    return ListView.builder(
      key: ValueKey('lista_$_selectedFilter'),
      padding: EdgeInsets.zero,
      itemCount: sortedCompetitions.length,
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      itemBuilder: (context, index) {
        final competition = sortedCompetitions[index];
        final matches = groupedMatches[competition]!;
        final isLastLiga = index == sortedCompetitions.length - 1;
        return _buildCompetitionSection(competition, matches, isLastLiga);
      },
    );
  }

  String _getTituloFiltro(String filtro) {
    switch (filtro) {
      case 'direto':
        return 'ao vivo no momento';
      case 'ontem':
        return 'de ontem';
      case 'amanha':
        return 'de amanhã';
      default:
        return 'disponível';
    }
  }

  String _truncarNomeLiga(String nome) {
    if (nome.length <= 30) return nome;
    return '${nome.substring(0, 27)}...';
  }

  Widget _buildCompetitionSection(String competition, List<FootballMatch> matches, bool isLastLiga) {
    return Column(
      children: [
        _AnimatedBouncyButton(
          onPressed: () {
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
                    _truncarNomeLiga(competition),
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
      onLongPress: () => _showQuickMatchDetails(context, match),
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
  final bool isLive;

  const _IOSStyleTabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
    this.isLive = false,
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

class _QuickMatchDetailsModal extends StatelessWidget {
  final FootballMatch match;
  final Color bgColor;
  final Color surfaceColor;
  final Color textColor;
  final Color subTextColor;

  const _QuickMatchDetailsModal({
    required this.match,
    required this.bgColor,
    required this.surfaceColor,
    required this.textColor,
    required this.subTextColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Detalhes Rápidos',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                IconButton(
                  icon: const Icon(Ionicons.close),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  color: textColor,
                ),
              ],
            ),
          ),
          Divider(height: 1, color: isDark ? Colors.white24 : Colors.black12),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          match.homeTeamCrest != null
                              ? CachedNetworkImage(
                                  imageUrl: match.homeTeamCrest!,
                                  width: 56,
                                  height: 56,
                                  errorWidget: (context, url, error) => Icon(
                                    Ionicons.shield_outline,
                                    size: 56,
                                    color: subTextColor,
                                  ),
                                )
                              : Icon(
                                  Ionicons.shield_outline,
                                  size: 56,
                                  color: subTextColor,
                                ),
                          const SizedBox(height: 12),
                          Text(
                            match.homeTeam,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        '${match.homeScore ?? '0'} : ${match.awayScore ?? '0'}',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF2374E1),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          match.awayTeamCrest != null
                              ? CachedNetworkImage(
                                  imageUrl: match.awayTeamCrest!,
                                  width: 56,
                                  height: 56,
                                  errorWidget: (context, url, error) => Icon(
                                    Ionicons.shield_outline,
                                    size: 56,
                                    color: subTextColor,
                                  ),
                                )
                              : Icon(
                                  Ionicons.shield_outline,
                                  size: 56,
                                  color: subTextColor,
                                ),
                          const SizedBox(height: 12),
                          Text(
                            match.awayTeam,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                if (!match.isLive && !match.isFinished) ...[
                  Text(
                    'Jogo ainda não começou',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: subTextColor,
                    ),
                  ),
                ] else ...[
                  _StatRow(
                    label: 'Posse de Bola',
                    homeValue: 50,
                    awayValue: 50,
                    isPercentage: true,
                    isDark: isDark,
                    textColor: textColor,
                  ),
                  const SizedBox(height: 20),
                  _StatRow(
                    label: 'Passes Certos',
                    homeValue: 0,
                    awayValue: 0,
                    isPercentage: true,
                    isDark: isDark,
                    textColor: textColor,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            const Text(
                              'Cartões',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '-',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          children: [
                            const Text(
                              'Cartões',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '-',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final int homeValue;
  final int awayValue;
  final bool isPercentage;
  final bool isDark;
  final Color textColor;

  const _StatRow({
    required this.label,
    required this.homeValue,
    required this.awayValue,
    this.isPercentage = false,
    required this.isDark,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final total = homeValue + awayValue;
    final homeProgress = total > 0 ? homeValue / total : 0.5;

    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Text(
              isPercentage ? '$homeValue%' : '$homeValue',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: homeProgress,
                  backgroundColor: isDark ? const Color(0xFFFF7043) : const Color(0xFFFF6F00),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDark ? const Color(0xFF42A5F5) : const Color(0xFF1976D2),
                  ),
                  minHeight: 8,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              isPercentage ? '$awayValue%' : '$awayValue',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AnimatedBouncyButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;

  const _AnimatedBouncyButton({
    required this.child,
    required this.onPressed,
  });

  @override
  State<_AnimatedBouncyButton> createState() => _AnimatedBouncyButtonState();
}

class _AnimatedBouncyButtonState extends State<_AnimatedBouncyButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.95)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.95, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 50,
      ),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    await _controller.forward();
    _controller.reset();
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}