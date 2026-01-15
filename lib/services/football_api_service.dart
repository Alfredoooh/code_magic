import 'dart:convert';
import 'package:http/http.dart' as http;

class FootballApiService {
  static const String _apiKey = '81e164bfa4364ff783bc397c30f39627';
  static const String _baseUrl = 'https://api.football-data.org/v4';

  Future<List<FootballMatch>> getTodayMatches() async {
    try {
      final today = DateTime.now();
      final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      
      final response = await http.get(
        Uri.parse('$_baseUrl/matches?date=$dateStr'),
        headers: {'X-Auth-Token': _apiKey},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final matches = (data['matches'] as List)
            .map((match) => FootballMatch.fromJson(match))
            .toList();
        return matches;
      }
      return [];
    } catch (e) {
      print('Error fetching matches: $e');
      return [];
    }
  }

  Future<MatchDetails?> getMatchDetails(int matchId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/matches/$matchId'),
        headers: {'X-Auth-Token': _apiKey},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return MatchDetails.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error fetching match details: $e');
      return null;
    }
  }
}

class FootballMatch {
  final int id;
  final String homeTeam;
  final String awayTeam;
  final String? homeTeamCrest;
  final String? awayTeamCrest;
  final int? homeScore;
  final int? awayScore;
  final String status;
  final String competition;
  final String? competitionEmblem;
  final DateTime utcDate;
  final String? venue;

  FootballMatch({
    required this.id,
    required this.homeTeam,
    required this.awayTeam,
    this.homeTeamCrest,
    this.awayTeamCrest,
    this.homeScore,
    this.awayScore,
    required this.status,
    required this.competition,
    this.competitionEmblem,
    required this.utcDate,
    this.venue,
  });

  factory FootballMatch.fromJson(Map<String, dynamic> json) {
    return FootballMatch(
      id: json['id'],
      homeTeam: json['homeTeam']['name'] ?? json['homeTeam']['shortName'] ?? 'Home',
      awayTeam: json['awayTeam']['name'] ?? json['awayTeam']['shortName'] ?? 'Away',
      homeTeamCrest: json['homeTeam']['crest'],
      awayTeamCrest: json['awayTeam']['crest'],
      homeScore: json['score']['fullTime']['home'],
      awayScore: json['score']['fullTime']['away'],
      status: json['status'],
      competition: json['competition']['name'],
      competitionEmblem: json['competition']['emblem'],
      utcDate: DateTime.parse(json['utcDate']),
      venue: json['venue'],
    );
  }

  bool get isLive => status == 'IN_PLAY' || status == 'PAUSED';
  bool get isFinished => status == 'FINISHED';
  bool get isScheduled => status == 'TIMED' || status == 'SCHEDULED';

  String get displayScore {
    if (homeScore != null && awayScore != null) {
      return '$homeScore - $awayScore';
    }
    return 'vs';
  }

  String get timeDisplay {
    if (isLive) return 'AO VIVO';
    if (isFinished) return 'FT';
    final hour = utcDate.toLocal().hour.toString().padLeft(2, '0');
    final minute = utcDate.toLocal().minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class MatchDetails {
  final int id;
  final String homeTeam;
  final String awayTeam;
  final String? homeTeamCrest;
  final String? awayTeamCrest;
  final int? homeScore;
  final int? awayScore;
  final String status;
  final String competition;
  final String? competitionEmblem;
  final DateTime utcDate;
  final String? venue;
  final String? referee;
  final List<MatchEvent> events;
  final Map<String, dynamic>? stats;

  MatchDetails({
    required this.id,
    required this.homeTeam,
    required this.awayTeam,
    this.homeTeamCrest,
    this.awayTeamCrest,
    this.homeScore,
    this.awayScore,
    required this.status,
    required this.competition,
    this.competitionEmblem,
    required this.utcDate,
    this.venue,
    this.referee,
    this.events = const [],
    this.stats,
  });

  factory MatchDetails.fromJson(Map<String, dynamic> json) {
    final events = <MatchEvent>[];
    if (json['goals'] != null) {
      for (var goal in json['goals']) {
        events.add(MatchEvent(
          minute: goal['minute'],
          type: 'GOAL',
          team: goal['team']['name'],
          player: goal['scorer']['name'],
        ));
      }
    }

    return MatchDetails(
      id: json['id'],
      homeTeam: json['homeTeam']['name'],
      awayTeam: json['awayTeam']['name'],
      homeTeamCrest: json['homeTeam']['crest'],
      awayTeamCrest: json['awayTeam']['crest'],
      homeScore: json['score']['fullTime']['home'],
      awayScore: json['score']['fullTime']['away'],
      status: json['status'],
      competition: json['competition']['name'],
      competitionEmblem: json['competition']['emblem'],
      utcDate: DateTime.parse(json['utcDate']),
      venue: json['venue'],
      referee: json['referees']?.isNotEmpty == true ? json['referees'][0]['name'] : null,
      events: events,
    );
  }

  bool get isLive => status == 'IN_PLAY' || status == 'PAUSED';
  bool get isFinished => status == 'FINISHED';
}

class MatchEvent {
  final int minute;
  final String type;
  final String team;
  final String player;

  MatchEvent({
    required this.minute,
    required this.type,
    required this.team,
    required this.player,
  });
}