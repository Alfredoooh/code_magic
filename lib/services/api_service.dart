// lib/services/api_service.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import '../models/config.dart';
import '../models/models.dart';

class ApiService {
  final AppConfig config;

  String? _keycloakToken;
  DateTime? _tokenExpiry;
  String? _sessionToken;
  int _nonce = 0;

  ApiService(this.config) {
    _nonce = DateTime.now().millisecondsSinceEpoch;
  }

  // ── Keycloak auth ─────────────────────────────────────────────
  // Extraído de keycloakAuth() no main.js:
  //   body: grant_type + username + password + scope
  //   header: Authorization: Basic base64(authId:authKey)
  Future<void> _authenticate() async {
    if (_keycloakToken != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(_tokenExpiry!.subtract(const Duration(seconds: 30)))) {
      return;
    }

    final basic = base64.encode(
        utf8.encode('${config.authId}:${config.authKey}'));
    final body = {
      'grant_type': 'password',
      'username': config.authUsername,
      'password': config.authPassword,
      'scope': 'openid info',
    };

    final res = await http.post(
      Uri.parse('${config.authService}auth/realms/master/protocol/openid-connect/token'),
      headers: {
        'content-type': 'application/x-www-form-urlencoded',
        'Authorization': 'Basic $basic',
      },
      body: body,
    ).timeout(const Duration(seconds: 15));

    if (res.statusCode != 200) {
      final err = jsonDecode(res.body);
      throw Exception(err['error_description'] ?? 'Keycloak auth failed ${res.statusCode}');
    }

    final data = jsonDecode(res.body);
    _keycloakToken = data['access_token'];
    final expiresIn = (data['expires_in'] ?? 300) as int;
    _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn));
  }

  // ── Session create ────────────────────────────────────────────
  Future<void> _createSession() async {
    await _authenticate();

    final res = await http.post(
      Uri.parse('${config.basePath}/session/create'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_keycloakToken',
      },
      body: jsonEncode({
        'application': 'Player Sale Point Application',
        'applicationVersion': '1.0.0',
        'language': 'por',
      }),
    ).timeout(const Duration(seconds: 15));

    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Session create failed: ${res.statusCode}');
    }

    final data = jsonDecode(res.body);
    _sessionToken = data['token'];
  }

  Future<String> _getSession() async {
    if (_sessionToken == null) await _createSession();
    return _sessionToken!;
  }

  // ── SHA-256 security params ───────────────────────────────────
  // token + apiPrivateKey + nonce → SHA-256
  Future<Map<String, String>> _securityParams() async {
    final token = await _getSession();
    _nonce++;
    final raw = '$token${config.apiPrivateKey}$_nonce';
    final hash = sha256.convert(utf8.encode(raw)).toString();
    return {
      'token': token,
      'nonce': _nonce.toString(),
      'hash': hash,
    };
  }

  // ── GET helper ────────────────────────────────────────────────
  Future<Map<String, dynamic>> _get(String url,
      Map<String, String> params) async {
    await _authenticate();
    final sec = await _securityParams();
    final allParams = {...params, ...sec};
    final uri = Uri.parse(url).replace(queryParameters: allParams);

    final res = await http.get(uri, headers: {
      'Authorization': 'Bearer $_keycloakToken',
      'Accept': 'application/json',
    }).timeout(const Duration(seconds: 20));

    if (res.statusCode == 401 || res.statusCode == 403) {
      // Token expirado — reset e retry
      _sessionToken = null;
      _keycloakToken = null;
      return _get(url, params);
    }
    if (res.statusCode != 200) {
      throw Exception('API error ${res.statusCode}: $url');
    }
    return jsonDecode(res.body);
  }

  // ── PATCH helper ──────────────────────────────────────────────
  Future<Map<String, dynamic>> _patch(String url,
      Map<String, dynamic> body) async {
    await _authenticate();
    final sec = await _securityParams();
    final uri = Uri.parse(url).replace(queryParameters: sec);

    final res = await http.patch(uri,
        headers: {
          'Authorization': 'Bearer $_keycloakToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body)).timeout(const Duration(seconds: 20));

    if (res.statusCode == 401 || res.statusCode == 403) {
      _sessionToken = null;
      _keycloakToken = null;
      return _patch(url, body);
    }
    if (res.statusCode != 200) {
      throw Exception('API patch error ${res.statusCode}');
    }
    return jsonDecode(res.body);
  }

  // ── getSports ─────────────────────────────────────────────────
  Future<List<Sport>> getSports() async {
    final data = await _get(
      '${config.sportsbookUrl}/games/oddsBetting/sports',
      {'language': 'por', 'max': '100', 'onlyActive': 'false'},
    );
    final list = data['sports'] ?? data['list'] ?? [];
    return (list as List).map((s) => Sport.fromJson(s)).toList();
  }

  // ── getTopEvents (PATCH como no app original) ─────────────────
  Future<List<SportEvent>> getTopEvents(int sportId) async {
    try {
      final data = await _patch(
        '${config.sportsbookUrl}/games/oddsBetting/events/top',
        {
          'language': 'por',
          'timeZone': 'Africa/Luanda',
          'sportFilter': {
            'listOfSports': [sportId]
          },
        },
      );
      return _parseEvents(data);
    } catch (_) {
      return getEvents(sportId);
    }
  }

  // ── getEvents ─────────────────────────────────────────────────
  Future<List<SportEvent>> getEvents(int sportId) async {
    final data = await _get(
      '${config.sportsbookUrl}/games/oddsBetting/events/$sportId',
      {
        'language': 'por',
        'timeZone': 'Africa/Luanda',
        'maxItem': '20',
        'beginItem': '0',
      },
    );
    return _parseEvents(data);
  }

  // ── parseEvents ───────────────────────────────────────────────
  List<SportEvent> _parseEvents(Map<String, dynamic> data) {
    final events = <SportEvent>[];
    final raw = data['topEvents'] ?? data['events'] ?? data['list'] ?? data;

    void walk(dynamic node, String comp) {
      if (node == null) return;
      if (node is List) {
        for (final item in node) {
          walk(item, comp);
        }
      } else if (node is Map<String, dynamic>) {
        if (node.containsKey('sportEventId')) {
          events.add(SportEvent.fromJson(node, competition: comp));
        } else if (node.containsKey('list')) {
          final name = node['name'] as String? ?? comp;
          walk(node['list'], name);
        } else {
          node.forEach((_, v) => walk(v, comp));
        }
      }
    }

    walk(raw, '');
    return events;
  }

  // ── searchTicket ──────────────────────────────────────────────
  Future<Map<String, dynamic>> searchTicket(String reference) async {
    final basev2e = config.basePath.replaceFirst('/v2/', '/v2-e/');
    final data = await _get(
      '$basev2e/tickets/$reference',
      {'language': 'por'},
    );
    return data['ticket'] ?? data;
  }

  // ── init (pre-auth) ───────────────────────────────────────────
  Future<void> init() async {
    await _authenticate();
    await _createSession();
  }
}