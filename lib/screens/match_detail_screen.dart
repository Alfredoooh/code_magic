import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/football_api_service.dart';

class MatchDetailsScreen extends StatefulWidget {
  final int matchId;
  final Color bgColor;
  final Color surfaceColor;
  final Color textColor;
  final Color subTextColor;
  final Color borderColor;

  const MatchDetailsScreen({
    Key? key,
    required this.matchId,
    required this.bgColor,
    required this.surfaceColor,
    required this.textColor,
    required this.subTextColor,
    required this.borderColor,
  }) : super(key: key);

  @override
  State<MatchDetailsScreen> createState() => _MatchDetailsScreenState();
}

class _MatchDetailsScreenState extends State<MatchDetailsScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  MatchDetails? _matchDetails;
  final FootballApiService _apiService = FootballApiService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadMatchDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMatchDetails() async {
    setState(() => _isLoading = true);
    final details = await _apiService.getMatchDetails(widget.matchId);
    if (mounted) {
      setState(() {
        _matchDetails = details;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.bgColor,
      appBar: AppBar(
        backgroundColor: widget.surfaceColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Ionicons.arrow_back, color: widget.textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Detalhes da Partida',
          style: TextStyle(color: widget.textColor, fontWeight: FontWeight.w600),
        ),
        bottom: _isLoading || _matchDetails == null
            ? null
            : TabBar(
                controller: _tabController,
                labelColor: const Color(0xFF2374E1),
                unselectedLabelColor: widget.subTextColor,
                indicatorColor: const Color(0xFF2374E1),
                labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                tabs: const [
                  Tab(text: 'Visão geral'),
                  Tab(text: 'Eventos'),
                  Tab(text: 'Formação'),
                  Tab(text: 'Estatísticas'),
                ],
              ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(const Color(0xFF2374E1)),
              ),
            )
          : _matchDetails == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Ionicons.alert_circle_outline, size: 64, color: widget.borderColor),
                      const SizedBox(height: 16),
                      Text(
                        'Erro ao carregar detalhes',
                        style: TextStyle(fontSize: 15, color: widget.subTextColor),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(),
                    _buildEventsTab(),
                    _buildFormationTab(),
                    _buildStatsTab(),
                  ],
                ),
    );
  }

  Widget _buildOverviewTab() {
    final match = _matchDetails!;
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildMatchHeader(match),
          const SizedBox(height: 16),
          _buildMatchInfo(match),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildEventsTab() {
    final match = _matchDetails!;
    
    if (match.events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Ionicons.list_outline, size: 64, color: widget.borderColor),
            const SizedBox(height: 16),
            Text(
              'Nenhum evento registrado',
              style: TextStyle(fontSize: 15, color: widget.subTextColor),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildMatchScoreHeader(match),
          const SizedBox(height: 8),
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.surfaceColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'EVENTOS DO JOGO',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: widget.subTextColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                ...match.events.map((event) => _buildEventItem(event, match)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormationTab() {
    final match = _matchDetails!;
    
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildMatchScoreHeader(match),
          const SizedBox(height: 16),
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: widget.surfaceColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Text(
                          match.homeTeam,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: widget.textColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2374E1).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '4-3-3',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF2374E1),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        Text(
                          match.awayTeam,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: widget.textColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '4-4-2',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  height: 400,
                  decoration: BoxDecoration(
                    color: Colors.green.shade800,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Stack(
                    children: [
                      // Campo de futebol estilizado
                      Center(
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                      // Meio de campo
                      Positioned(
                        top: 0,
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            width: double.infinity,
                            height: 2,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Center(
                        child: Text(
                          'Formações disponíveis em breve',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsTab() {
    final match = _matchDetails!;
    
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildMatchScoreHeader(match),
          const SizedBox(height: 16),
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.surfaceColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ESTATÍSTICAS',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: widget.subTextColor,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 20),
                _buildStatRow('Posse de bola', 55, 45),
                _buildStatRow('Finalizações', 12, 8),
                _buildStatRow('No alvo', 5, 3),
                _buildStatRow('Escanteios', 6, 4),
                _buildStatRow('Faltas', 10, 14),
                _buildStatRow('Cartões amarelos', 2, 3),
                _buildStatRow('Cartões vermelhos', 0, 0),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, int homeValue, int awayValue) {
    final total = homeValue + awayValue;
    final homePercent = total > 0 ? homeValue / total : 0.5;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$homeValue',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: widget.textColor,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: widget.subTextColor,
                ),
              ),
              Text(
                '$awayValue',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: widget.textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Row(
              children: [
                Expanded(
                  flex: (homePercent * 100).round(),
                  child: Container(
                    height: 6,
                    color: const Color(0xFF2374E1),
                  ),
                ),
                Expanded(
                  flex: ((1 - homePercent) * 100).round(),
                  child: Container(
                    height: 6,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchScoreHeader(MatchDetails match) {
    return Container(
      color: widget.surfaceColor,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                if (match.homeTeamCrest != null)
                  CachedNetworkImage(
                    imageUrl: match.homeTeamCrest!,
                    width: 48,
                    height: 48,
                    errorWidget: (context, url, error) => Icon(
                      Ionicons.shield_outline,
                      size: 48,
                      color: widget.textColor,
                    ),
                  )
                else
                  Icon(Ionicons.shield_outline, size: 48, color: widget.textColor),
                const SizedBox(height: 8),
                Text(
                  match.homeTeam,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: widget.textColor,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Text(
                  match.homeScore != null && match.awayScore != null
                      ? '${match.homeScore} : ${match.awayScore}'
                      : 'vs',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: widget.textColor,
                  ),
                ),
                const SizedBox(height: 4),
                if (match.isLive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'AO VIVO',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Text(
                    match.isFinished ? 'FINALIZADO' : 'AGENDADO',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: widget.subTextColor,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              children: [
                if (match.awayTeamCrest != null)
                  CachedNetworkImage(
                    imageUrl: match.awayTeamCrest!,
                    width: 48,
                    height: 48,
                    errorWidget: (context, url, error) => Icon(
                      Ionicons.shield_outline,
                      size: 48,
                      color: widget.textColor,
                    ),
                  )
                else
                  Icon(Ionicons.shield_outline, size: 48, color: widget.textColor),
                const SizedBox(height: 8),
                Text(
                  match.awayTeam,
                  style: TextStyle(
                    fontSize: 12,
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
    );
  }

  Widget _buildMatchHeader(MatchDetails match) {
    return Container(
      color: widget.surfaceColor,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              if (match.competitionEmblem != null)
                CachedNetworkImage(
                  imageUrl: match.competitionEmblem!,
                  width: 24,
                  height: 24,
                  errorWidget: (context, url, error) => Icon(
                    Ionicons.football,
                    size: 24,
                    color: widget.subTextColor,
                  ),
                )
              else
                Icon(Ionicons.football, size: 24, color: widget.subTextColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  match.competition,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: widget.subTextColor,
                  ),
                ),
              ),
              if (match.isLive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'AO VIVO',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: widget.borderColor, width: 2),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: match.homeTeamCrest != null
                          ? CachedNetworkImage(
                              imageUrl: match.homeTeamCrest!,
                              fit: BoxFit.contain,
                              errorWidget: (context, url, error) => Icon(
                                Ionicons.shield_outline,
                                color: widget.textColor,
                                size: 40,
                              ),
                            )
                          : Icon(
                              Ionicons.shield_outline,
                              color: widget.textColor,
                              size: 40,
                            ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      match.homeTeam,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: widget.textColor,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Text(
                      match.homeScore != null && match.awayScore != null
                          ? '${match.homeScore} - ${match.awayScore}'
                          : 'vs',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: widget.textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      match.isFinished ? 'FINALIZADO' : 
                      match.isLive ? 'AO VIVO' : 
                      '${match.utcDate.toLocal().hour.toString().padLeft(2, '0')}:${match.utcDate.toLocal().minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: match.isLive ? Colors.red : widget.subTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(color: widget.borderColor, width: 2),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: match.awayTeamCrest != null
                          ? CachedNetworkImage(
                              imageUrl: match.awayTeamCrest!,
                              fit: BoxFit.contain,
                              errorWidget: (context, url, error) => Icon(
                                Ionicons.shield_outline,
                                color: widget.textColor,
                                size: 40,
                              ),
                            )
                          : Icon(
                              Ionicons.shield_outline,
                              color: widget.textColor,
                              size: 40,
                            ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      match.awayTeam,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
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
        ],
      ),
    );
  }

  Widget _buildMatchInfo(MatchDetails match) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'INFORMAÇÕES',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: widget.subTextColor,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 16),
          if (match.venue != null) _buildInfoRow(Ionicons.location_outline, 'Estádio', match.venue!),
          if (match.referee != null) _buildInfoRow(Ionicons.person_outline, 'Árbitro', match.referee!),
          _buildInfoRow(
            Ionicons.calendar_outline,
            'Data',
            '${match.utcDate.toLocal().day.toString().padLeft(2, '0')}/${match.utcDate.toLocal().month.toString().padLeft(2, '0')}/${match.utcDate.toLocal().year}',
          ),
          _buildInfoRow(
            Ionicons.time_outline,
            'Horário',
            '${match.utcDate.toLocal().hour.toString().padLeft(2, '0')}:${match.utcDate.toLocal().minute.toString().padLeft(2, '0')}',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: widget.subTextColor),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: widget.subTextColor,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: widget.textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventItem(MatchEvent event, MatchDetails match) {
    final isHomeTeam = event.team == match.homeTeam;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: widget.borderColor.withOpacity(0.3), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Lado esquerdo (time da casa)
          if (isHomeTeam) ...[
            Expanded(
              flex: 5,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          event.player,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: widget.textColor,
                          ),
                          textAlign: TextAlign.right,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (event.type != 'GOAL' && event.type != 'CARD')
                          Text(
                            event.type,
                            style: TextStyle(
                              fontSize: 11,
                              color: widget.subTextColor,
                            ),
                            textAlign: TextAlign.right,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildEventIcon(event),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF2374E1).withOpacity(0.1),
              ),
              child: Center(
                child: Text(
                  "${event.minute}'",
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2374E1),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Expanded(flex: 5, child: SizedBox()),
          ] else ...[
            // Lado direito (time visitante)
            const Expanded(flex: 5, child: SizedBox()),
            const SizedBox(width: 8),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red.withOpacity(0.1),
              ),
              child: Center(
                child: Text(
                  "${event.minute}'",
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.red,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 5,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  _buildEventIcon(event),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.player,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: widget.textColor,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (event.type != 'GOAL' && event.type != 'CARD')
                          Text(
                            event.type,
                            style: TextStyle(
                              fontSize: 11,
                              color: widget.subTextColor,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEventIcon(MatchEvent event) {
    IconData icon;
    Color color;
    
    switch (event.type) {
      case 'GOAL':
        icon = Ionicons.football;
        color = Colors.green;
        break;
      case 'CARD':
        icon = Ionicons.card;
        color = Colors.red;
        break;
      case 'SUBSTITUTION':
        icon = Ionicons.swap_horizontal;
        color = const Color(0xFF2374E1);
        break;
      default:
        icon = Ionicons.information_circle;
        color = widget.subTextColor;
    }
    
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withOpacity(0.1),
      ),
      child: Icon(icon, size: 18, color: color),
    );
  }
}