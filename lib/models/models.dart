// lib/models/models.dart

class Sport {
  final int id;
  final String name;
  Sport({required this.id, required this.name});

  factory Sport.fromJson(Map<String, dynamic> j) => Sport(
        id: j['id'] ?? j['sportId'] ?? 0,
        name: j['name'] ?? '',
      );
}

class Odd {
  final String label;
  final double value;
  final String shortCode;
  final bool suspended;
  final int outcomeId;

  Odd({
    required this.label,
    required this.value,
    required this.shortCode,
    required this.suspended,
    required this.outcomeId,
  });

  factory Odd.fromJson(Map<String, dynamic> j) => Odd(
        label: j['oddsShortCode'] ?? j['name'] ?? '?',
        value: (j['oddsValue'] ?? j['odds'] ?? 0).toDouble(),
        shortCode: j['oddsShortCode'] ?? '',
        suspended: j['isSuspended'] ?? false,
        outcomeId: j['oddsOutcomeId'] ?? j['id'] ?? 0,
      );
}

class OddsType {
  final String marketName;
  final List<Odd> odds;
  OddsType({required this.marketName, required this.odds});

  factory OddsType.fromJson(Map<String, dynamic> j) => OddsType(
        marketName: j['marketName'] ?? '',
        odds: ((j['listOfOdds'] ?? []) as List)
            .map((o) => Odd.fromJson(o))
            .toList(),
      );
}

class Participant {
  final String name;
  Participant({required this.name});
  factory Participant.fromJson(Map<String, dynamic> j) =>
      Participant(name: j['name'] ?? '');
}

class SportEvent {
  final String sportEventId;
  final String competitionName;
  final DateTime? begin;
  final bool isLive;
  final List<Participant> participants;
  final List<OddsType> oddsTypes;

  SportEvent({
    required this.sportEventId,
    required this.competitionName,
    required this.begin,
    required this.isLive,
    required this.participants,
    required this.oddsTypes,
  });

  String get home => participants.isNotEmpty ? participants[0].name : 'Casa';
  String get away => participants.length > 1 ? participants[1].name : 'Fora';
  List<Odd> get mainOdds =>
      oddsTypes.isNotEmpty ? oddsTypes[0].odds.take(3).toList() : [];

  factory SportEvent.fromJson(Map<String, dynamic> j,
      {String competition = ''}) {
    final parts = ((j['participants'] ?? []) as List)
        .map((p) => Participant.fromJson(p))
        .toList();
    final oddsRaw = ((j['listOfOddsByType'] ?? []) as List)
        .map((o) => OddsType.fromJson(o))
        .toList();
    DateTime? begin;
    if (j['begin'] != null) {
      try {
        begin = DateTime.parse(j['begin']);
      } catch (_) {}
    }
    return SportEvent(
      sportEventId: j['sportEventId']?.toString() ?? '',
      competitionName: competition,
      begin: begin,
      isLive: j['isLive'] ?? false,
      participants: parts,
      oddsTypes: oddsRaw,
    );
  }
}

class BetItem {
  final String eventId;
  final int col;
  final String home;
  final String away;
  final String label;
  final double oddValue;

  BetItem({
    required this.eventId,
    required this.col,
    required this.home,
    required this.away,
    required this.label,
    required this.oddValue,
  });
}

class HistoryTicket {
  final String id;
  final String events;
  final double stake;
  final double totalOdds;
  final double net;
  final DateTime date;
  String status;

  HistoryTicket({
    required this.id,
    required this.events,
    required this.stake,
    required this.totalOdds,
    required this.net,
    required this.date,
    this.status = 'pending',
  });
}