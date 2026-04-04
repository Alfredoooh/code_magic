// lib/services/app_state.dart
import 'package:flutter/material.dart';
import '../models/config.dart';
import '../models/models.dart';
import 'api_service.dart';

class AppState extends ChangeNotifier {
  AppConfig? config;
  ApiService? api;

  bool loading = true;
  String? error;

  List<Sport> sports = [];
  int activeSportId = 0;
  String activeSportName = '';

  List<SportEvent> events = [];
  bool eventsLoading = false;

  List<BetItem> betslip = [];
  List<HistoryTicket> history = [];

  // ── Init ──────────────────────────────────────────────────────
  Future<void> init(AppConfig cfg) async {
    config = cfg;
    api = ApiService(cfg);
    try {
      await api!.init();
      sports = await api!.getSports();
      if (sports.isNotEmpty) {
        activeSportId = sports.first.id;
        activeSportName = sports.first.name;
        await loadEvents();
      }
      loading = false;
      error = null;
    } catch (e) {
      loading = false;
      error = e.toString().replaceFirst('Exception: ', '');
    }
    notifyListeners();
  }

  // ── Events ────────────────────────────────────────────────────
  Future<void> selectSport(Sport sport) async {
    activeSportId = sport.id;
    activeSportName = sport.name;
    events = [];
    notifyListeners();
    await loadEvents();
  }

  Future<void> loadEvents() async {
    if (api == null) return;
    eventsLoading = true;
    notifyListeners();
    try {
      events = await api!.getTopEvents(activeSportId);
    } catch (e) {
      events = [];
    }
    eventsLoading = false;
    notifyListeners();
  }

  // ── Betslip ───────────────────────────────────────────────────
  void toggleBet(SportEvent ev, int col, Odd odd) {
    final existing = betslip.indexWhere(
        (b) => b.eventId == ev.sportEventId && b.col == col);
    final sameEvent = betslip.indexWhere((b) => b.eventId == ev.sportEventId);

    if (existing >= 0) {
      betslip.removeAt(existing);
    } else {
      if (sameEvent >= 0) betslip.removeAt(sameEvent);
      betslip.add(BetItem(
        eventId: ev.sportEventId,
        col: col,
        home: ev.home,
        away: ev.away,
        label: odd.label,
        oddValue: odd.value,
      ));
    }
    notifyListeners();
  }

  bool isBetSelected(String eventId, int col) =>
      betslip.any((b) => b.eventId == eventId && b.col == col);

  void removeBet(int i) {
    betslip.removeAt(i);
    notifyListeners();
  }

  void clearBetslip() {
    betslip.clear();
    notifyListeners();
  }

  double get totalOdds =>
      betslip.fold(1.0, (a, b) => a * b.oddValue);

  double potentialGross(double stake) => totalOdds * stake;
  double potentialTax(double stake) => potentialGross(stake) * 0.15;
  double potentialNet(double stake) =>
      potentialGross(stake) - potentialTax(stake);

  void placeBet(double stake) {
    final ticket = HistoryTicket(
      id: '#BT-${DateTime.now().millisecondsSinceEpoch}',
      events: betslip.map((b) => '${b.home} vs ${b.away} (${b.label})').join(' + '),
      stake: stake,
      totalOdds: totalOdds,
      net: potentialNet(stake),
      date: DateTime.now(),
      status: 'pending',
    );
    history.insert(0, ticket);
    betslip.clear();
    notifyListeners();
  }

  // ── Ticket lookup ─────────────────────────────────────────────
  Future<Map<String, dynamic>?> lookupTicket(String ref) async {
    try {
      return await api!.searchTicket(ref);
    } catch (_) {
      return null;
    }
  }
}