import 'dart:convert';
import 'package:http/http.dart' as http;

class FootballApiService {
  static const String _apiKey = 'db4bdf819b3fa280cbd0d5c2bd9073bb';
  static const String _baseUrl = 'https://v3.football.api-sports.io';
  
  // IDs das principais ligas
  static const int laLigaId = 140;
  static const int premierLeagueId = 39;
  static const int serieAId = 135;
  static const int bundesligaId = 78;
  static const int ligue1Id = 61;

  /// Retorna jogos de hoje
  Future<List<FootballMatch>> getTodayMatches() async {
    try {
      final today = DateTime.now();
      final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final response = await http.get(
        Uri.parse('$_baseUrl/fixtures?date=$dateStr'),
        headers: {
          'x-rapidapi-key': _apiKey,
          'x-rapidapi-host': 'v3.football.api-sports.io'
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final matches = (data['response'] as List)
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

  /// Retorna jogos ao vivo
  Future<List<FootballMatch>> getLiveMatches() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/fixtures?live=all'),
        headers: {
          'x-rapidapi-key': _apiKey,
          'x-rapidapi-host': 'v3.football.api-sports.io'
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final matches = (data['response'] as List)
            .map((match) => FootballMatch.fromJson(match))
            .toList();
        return matches;
      }
      return [];
    } catch (e) {
      print('Error fetching live matches: $e');
      return [];
    }
  }

  /// Retorna jogos de uma liga específica
  Future<List<FootballMatch>> getLeagueMatches({
    required int leagueId,
    String? from,
    String? to,
    int season = 2024,
  }) async {
    try {
      String url = '$_baseUrl/fixtures?league=$leagueId&season=$season';
      if (from != null) url += '&from=$from';
      if (to != null) url += '&to=$to';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'x-rapidapi-key': _apiKey,
          'x-rapidapi-host': 'v3.football.api-sports.io'
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final matches = (data['response'] as List)
            .map((match) => FootballMatch.fromJson(match))
            .toList();
        return matches;
      }
      return [];
    } catch (e) {
      print('Error fetching league matches: $e');
      return [];
    }
  }

  /// Retorna detalhes de um jogo específico
  Future<MatchDetails?> getMatchDetails(int fixtureId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/fixtures?id=$fixtureId'),
        headers: {
          'x-rapidapi-key': _apiKey,
          'x-rapidapi-host': 'v3.football.api-sports.io'
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['response'] != null && (data['response'] as List).isNotEmpty) {
          return MatchDetails.fromJson(data['response'][0]);
        }
      }
      return null;
    } catch (e) {
      print('Error fetching match details: $e');
      return null;
    }
  }

  /// Retorna estatísticas de um jogo
  Future<Map<String, dynamic>?> getMatchStatistics(int fixtureId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/fixtures/statistics?fixture=$fixtureId'),
        headers: {
          'x-rapidapi-key': _apiKey,
          'x-rapidapi-host': 'v3.football.api-sports.io'
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      }
      return null;
    } catch (e) {
      print('Error fetching match statistics: $e');
      return null;
    }
  }

  /// Retorna eventos de um jogo (golos, cartões, etc)
  Future<List<MatchEvent>> getMatchEvents(int fixtureId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/fixtures/events?fixture=$fixtureId'),
        headers: {
          'x-rapidapi-key': _apiKey,
          'x-rapidapi-host': 'v3.football.api-sports.io'
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final events = (data['response'] as List)
            .map((event) => MatchEvent.fromJson(event))
            .toList();
        return events;
      }
      return [];
    } catch (e) {
      print('Error fetching match events: $e');
      return [];
    }
  }
}

class FootballMatch {
  final int id;
  final String homeTeam;
  final String awayTeam;
  final String? homeTeamLogo;
  final String? awayTeamLogo;
  final int? homeScore;
  final int? awayScore;
  final String statusShort;
  final String statusLong;
  final int? elapsed;
  final String league;
  final String? leagueLogo;
  final DateTime date;
  final String? venue;

  FootballMatch({
    required this.id,
    required this.homeTeam,
    required this.awayTeam,
    this.homeTeamLogo,
    this.awayTeamLogo,
    this.homeScore,
    this.awayScore,
    required this.statusShort,
    required this.statusLong,
    this.elapsed,
    required this.league,
    this.leagueLogo,
    required this.date,
    this.venue,
  });

  factory FootballMatch.fromJson(Map<String, dynamic> json) {
    return FootballMatch(
      id: json['fixture']['id'],
      homeTeam: json['teams']['home']['name'],
      awayTeam: json['teams']['away']['name'],
      homeTeamLogo: json['teams']['home']['logo'],
      awayTeamLogo: json['teams']['away']['logo'],
      homeScore: json['goals']['home'],
      awayScore: json['goals']['away'],
      statusShort: json['fixture']['status']['short'],
      statusLong: json['fixture']['status']['long'],
      elapsed: json['fixture']['status']['elapsed'],
      league: json['league']['name'],
      leagueLogo: json['league']['logo'],
      date: DateTime.parse(json['fixture']['date']),
      venue: json['fixture']['venue']?['name'],
    );
  }

  bool get isLive => ['1H', '2H', 'ET', 'P', 'BT', 'HT', 'LIVE'].contains(statusShort);
  bool get isFinished => ['FT', 'AET', 'PEN'].contains(statusShort);
  bool get isScheduled => ['TBD', 'NS'].contains(statusShort);

  String get displayScore {
    if (homeScore != null && awayScore != null) {
      return '$homeScore - $awayScore';
    }
    return 'vs';
  }

  String get timeDisplay {
    if (isLive && elapsed != null) return "$elapsed'";
    if (isFinished) return getStatusText(statusShort);
    final hour = date.toLocal().hour.toString().padLeft(2, '0');
    final minute = date.toLocal().minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  static String getStatusText(String status) {
    const statusMap = {
      'TBD': 'A definir',
      'NS': 'Não iniciado',
      '1H': '1º Tempo',
      'HT': 'Intervalo',
      '2H': '2º Tempo',
      'ET': 'Prorrogação',
      'P': 'Pênaltis',
      'FT': 'Finalizado',
      'AET': 'Fim (Prorrog.)',
      'PEN': 'Fim (Pênaltis)',
      'BT': 'Break Time',
      'SUSP': 'Suspenso',
      'INT': 'Interrompido',
      'PST': 'Adiado',
      'CANC': 'Cancelado',
      'ABD': 'Abandonado',
      'AWD': 'Walkover',
      'WO': 'Walkover',
      'LIVE': 'Ao Vivo'
    };
    return statusMap[status] ?? status;
  }
}

class MatchDetails {
  final int id;
  final String homeTeam;
  final String awayTeam;
  final String? homeTeamLogo;
  final String? awayTeamLogo;
  final int? homeScore;
  final int? awayScore;
  final String statusShort;
  final String statusLong;
  final int? elapsed;
  final String league;
  final String? leagueLogo;
  final DateTime date;
  final String? venue;
  final String? referee;
  final String? city;
  final int? round;

  MatchDetails({
    required this.id,
    required this.homeTeam,
    required this.awayTeam,
    this.homeTeamLogo,
    this.awayTeamLogo,
    this.homeScore,
    this.awayScore,
    required this.statusShort,
    required this.statusLong,
    this.elapsed,
    required this.league,
    this.leagueLogo,
    required this.date,
    this.venue,
    this.referee,
    this.city,
    this.round,
  });

  factory MatchDetails.fromJson(Map<String, dynamic> json) {
    return MatchDetails(
      id: json['fixture']['id'],
      homeTeam: json['teams']['home']['name'],
      awayTeam: json['teams']['away']['name'],
      homeTeamLogo: json['teams']['home']['logo'],
      awayTeamLogo: json['teams']['away']['logo'],
      homeScore: json['goals']['home'],
      awayScore: json['goals']['away'],
      statusShort: json['fixture']['status']['short'],
      statusLong: json['fixture']['status']['long'],
      elapsed: json['fixture']['status']['elapsed'],
      league: json['league']['name'],
      leagueLogo: json['league']['logo'],
      date: DateTime.parse(json['fixture']['date']),
      venue: json['fixture']['venue']?['name'],
      referee: json['fixture']['referee'],
      city: json['fixture']['venue']?['city'],
      round: json['league']['round'],
    );
  }

  bool get isLive => ['1H', '2H', 'ET', 'P', 'BT', 'HT', 'LIVE'].contains(statusShort);
  bool get isFinished => ['FT', 'AET', 'PEN'].contains(statusShort);
}

class MatchEvent {
  final int time;
  final String type;
  final String detail;
  final String team;
  final String player;
  final String? assist;
  final String? comments;

  MatchEvent({
    required this.time,
    required this.type,
    required this.detail,
    required this.team,
    required this.player,
    this.assist,
    this.comments,
  });

  factory MatchEvent.fromJson(Map<String, dynamic> json) {
    return MatchEvent(
      time: json['time']['elapsed'] ?? 0,
      type: json['type'],
      detail: json['detail'],
      team: json['team']['name'],
      player: json['player']['name'],
      assist: json['assist']?['name'],
      comments: json['comments'],
    );
  }

  String get icon {
    if (type == 'Goal') return 'Goal';
    if (detail == 'Yellow Card') return 'Yellow';
    if (detail == 'Red Card') return 'Red';
    if (type == 'subst') return 'Sub';
    return 'Event';
  }
}