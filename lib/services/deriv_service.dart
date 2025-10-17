// lib/services/deriv_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'dart:math';

class DerivService {
  static const int _appId = 71954;
  static const String _redirectHttps = 'https://alfredoooh.github.io/database/oauth-redirect/';
  static const String _customScheme = 'com.nexa.madeeasy';
  
  final _secureStorage = const FlutterSecureStorage();
  WebSocketChannel? _channel;
  
  final _connectionController = StreamController<bool>.broadcast();
  final _balanceController = StreamController<Map<String, dynamic>?>.broadcast();
  final _tickController = StreamController<Map<String, dynamic>>.broadcast();
  
  Stream<bool> get connectionStream => _connectionController.stream;
  Stream<Map<String, dynamic>?> get balanceStream => _balanceController.stream;
  Stream<Map<String, dynamic>> get tickStream => _tickController.stream;

  String? _currentToken;
  bool _isConnected = false;

  Future<void> loadSavedToken() async {
    try {
      final token = await _secureStorage.read(key: 'deriv_api_token');
      if (token != null && token.isNotEmpty) {
        await connectWithToken(token);
      }
    } catch (e) {
      // Ignorar erro
    }
  }

  Future<void> connectWithToken(String token) async {
    disconnect();
    
    final uri = Uri.parse('wss://ws.derivws.com/websockets/v3?app_id=$_appId');
    _channel = WebSocketChannel.connect(uri);
    _currentToken = token;

    _channel!.stream.listen(
      (dynamic msg) => _handleMessage(msg?.toString()),
      onError: (_) => _connectionController.add(false),
      onDone: () {
        _isConnected = false;
        _connectionController.add(false);
      },
    );

    await _secureStorage.write(key: 'deriv_api_token', value: token);
    
    // Autorizar
    _sendMessage({'authorize': token});
    
    // Solicitar saldo após conexão
    await Future.delayed(Duration(milliseconds: 500));
    _sendMessage({'balance': 1, 'subscribe': 1});
  }

  void _handleMessage(String? message) {
    if (message == null) return;

    try {
      final data = jsonDecode(message) as Map<String, dynamic>;

      // Autorização bem-sucedida
      if (data.containsKey('authorize')) {
        _isConnected = true;
        _connectionController.add(true);
        
        final auth = data['authorize'];
        if (auth is Map<String, dynamic>) {
          final balance = auth['balance'];
          final currency = auth['currency'];
          final loginid = auth['loginid'];
          
          _balanceController.add({
            'balance': _parseBalance(balance),
            'currency': currency ?? 'USD',
            'loginid': loginid,
          });
        }
      }

      // Atualização de saldo
      if (data.containsKey('balance')) {
        final balanceData = data['balance'];
        double? balance;
        String? currency;
        String? loginid;

        if (balanceData is Map<String, dynamic>) {
          balance = _parseBalance(balanceData['balance']);
          currency = balanceData['currency']?.toString();
          loginid = balanceData['loginid']?.toString();
        } else {
          balance = _parseBalance(balanceData);
        }

        _balanceController.add({
          'balance': balance ?? 0.0,
          'currency': currency ?? 'USD',
          'loginid': loginid,
        });
      }

      // Tick de preço
      if (data.containsKey('tick')) {
        _tickController.add(data['tick']);
      }

      // Proposta
      if (data.containsKey('proposal')) {
        // Implementar lógica de proposta se necessário
      }
    } catch (e) {
      // Ignorar erros de parsing
    }
  }

  double _parseBalance(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  void _sendMessage(Map<String, dynamic> payload) {
    if (_channel != null && _isConnected) {
      _channel!.sink.add(jsonEncode(payload));
    }
  }

  Future<String?> startOAuthFlow() async {
    final state = _generateRandomState();
    final authUri = Uri.parse('https://oauth.deriv.com/oauth2/authorize').replace(
      queryParameters: {
        'app_id': _appId.toString(),
        'redirect_uri': _redirectHttps,
        'state': state,
        'response_type': 'token',
        'scope': 'trade read',
      },
    );

    try {
      final result = await FlutterWebAuth2.authenticate(
        url: authUri.toString(),
        callbackUrlScheme: _customScheme,
      );

      final callbackUri = Uri.parse(result);
      final token = callbackUri.queryParameters['token'] ?? 
                     callbackUri.queryParameters['access_token'];
      
      if (token != null && token.isNotEmpty) {
        await connectWithToken(token);
        return token;
      }
    } catch (e) {
      // Erro ou cancelamento
    }
    return null;
  }

  String _generateRandomState([int length = 24]) {
    final rand = Random.secure();
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    return List.generate(length, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  void subscribeTicks(String symbol) {
    _sendMessage({
      'ticks': symbol,
      'subscribe': 1,
    });
  }

  void unsubscribeTicks(String symbol) {
    _sendMessage({
      'forget': symbol,
    });
  }

  Future<void> buyContract({
    required String contractType,
    required String symbol,
    required double stake,
    required int duration,
    required String durationType,
  }) async {
    _sendMessage({
      'buy': 1,
      'subscribe': 1,
      'price': stake,
      'parameters': {
        'contract_type': contractType,
        'symbol': symbol,
        'duration': duration,
        'duration_unit': durationType,
        'basis': 'stake',
        'amount': stake,
      },
    });
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
    _connectionController.add(false);
    _secureStorage.delete(key: 'deriv_api_token');
  }

  void dispose() {
    disconnect();
    _connectionController.close();
    _balanceController.close();
    _tickController.close();
  }
}