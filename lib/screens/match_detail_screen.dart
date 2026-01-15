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

class _MatchDetailsScreenState extends State<MatchDetailsScreen> {
  bool _isLoading = true;
  MatchDetails? _matchDetails;
  final FootballApiService _apiService = FootballApiService();

  @override
  void initState() {
    super.initState();
    _loadMatchDetails();
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
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final match = _matchDetails!;
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildMatchHeader(match),
          const SizedBox(height: 16),
          _buildMatchInfo(match),
          if (match.events.isNotEmpty) ...[
            const SizedBox(height: 16),
            _buildMatchEvents(match),
          ],
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
            'Informações',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: widget.textColor,
            ),
          ),
          const SizedBox(height: 12),
          if (match.venue != null) _buildInfoRow(Ionicons.location_outline, 'Estádio', match.venue!),
          if (match.referee != null) _buildInfoRow(Ionicons.person_outline, 'Árbitro', match.referee!),
          _buildInfoRow(
            Ionicons.calendar_outline,
            'Data',
            '${match.utcDate.toLocal().day}/${match.utcDate.toLocal().month}/${match.utcDate.toLocal().year}',
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

  Widget _buildMatchEvents(MatchDetails match) {
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
            'Eventos',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: widget.textColor,
            ),
          ),
          const SizedBox(height: 12),
          ...match.events.map((event) => _buildEventItem(event, match)),
        ],
      ),
    );
  }

  Widget _buildEventItem(MatchEvent event, MatchDetails match) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
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
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2374E1),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Icon(
            event.type == 'GOAL' ? Ionicons.football : Ionicons.card,
            size: 20,
            color: event.type == 'GOAL' ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.player,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: widget.textColor,
                  ),
                ),
                Text(
                  event.team,
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.subTextColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}