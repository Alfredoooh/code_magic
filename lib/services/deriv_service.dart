// lib/services/deriv_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class DerivService {
  static const int appId = 71954;
  static const String wsUrl = 'wss://ws.derivws.com/websockets/v3?app_id=$appId';

  WebSocketChannel? _channel;
  final StreamController<bool> _connectionController = StreamController<bool>.broadcast();
  final StreamController<double> _balanceController = StreamController<double>.broadcast();
  final StreamController<Map<String, dynamic>?> _accountController = StreamController<Map<String, dynamic>?>.broadcast();
  final StreamController<Map<String, dynamic>> _tickController = StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _proposalController = StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _contractController = StreamController<Map<String, dynamic>>.broadcast();
  
  String? _currentToken;
  bool _isConnected = false;
  double _balance = 0.0;
  Map<String, dynamic>? _accountInfo;
  List<Map<String, dynamic>> _activeSymbols = [];
  String? _forgetTickId;

  Stream<bool> get connectionState => _connectionController.stream;
  Stream<double> get balanceStream => _balanceController.stream;
  Stream<Map<String, dynamic>?> get accountInfo => _accountController.stream;
  Stream<Map<String, dynamic>> get tickStream => _tickController.stream;
  Stream<Map<String, dynamic>> get proposalStream => _proposalController.stream;
  Stream<Map<String, dynamic>> get contractStream => _contractController.stream;

  bool get isConnected => _isConnected;
  double get balance => _balance;
  String? get currentToken => _currentToken;
  List<Map<String, dynamic>> get activeSymbols => _activeSymbols;

  void _connect() {
    try {
      _channel?.sink.close();
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      
      _channel!.stream.listen(
        (message) => _handleMessage(message),
        onError: (error) {
          _isConnected = false;
          _connectionController.add(false);
        },
        onDone: () {
          _isConnected = false;
          _connectionController.add(false);
        },
      );
    } catch (e) {
      _isConnected = false;
      _connectionController.add(false);
      rethrow;
    }
  }

  Future<void> connectWithToken(String token) async {
    _currentToken = token;
    _connect();
    await Future.delayed(Duration(milliseconds: 500));
    _sendMessage({'authorize': token});
  }

  Future<void> loginWithCredentials(String email, String password) async {
    _connect();
    await Future.delayed(Duration(milliseconds: 500));
    
    _sendMessage({
      'authorize': email,
      'password': password,
    });
  }

  void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message);
      
      if (data['msg_type'] == 'authorize') {
        _handleAuthorize(data);
      } else if (data['msg_type'] == 'balance') {
        _handleBalance(data);
      } else if (data['msg_type'] == 'active_symbols') {
        _handleActiveSymbols(data);
      } else if (data['msg_type'] == 'tick') {
        _handleTick(data);
      } else if (data['msg_type'] == 'proposal') {
        _handleProposal(data);
      } else if (data['msg_type'] == 'buy') {
        _handleBuy(data);
      } else if (data['msg_type'] == 'proposal_open_contract') {
        _handleContract(data);
      } else if (data['error']) {
        print('Deriv API Error: ${data['error']['message']}');
      }
    } catch (e) {
      print('Error parsing message: $e');
    }
  }

  void _handleAuthorize(Map<String, dynamic> data) {
    if (data['authorize'] != null) {
      _isConnected = true;
      _connectionController.add(true);
      
      final authData = data['authorize'];
      _accountInfo = {
        'loginid': authData['loginid'],
        'currency': authData['currency'],
        'balance': authData['balance']?.toDouble() ?? 0.0,
        'account_type': authData['account_type'] ?? 'demo',
        'email': authData['email'],
      };
      
      _balance = _accountInfo!['balance'];
      _balanceController.add(_balance);
      _accountController.add(_accountInfo);
      
      if (_currentToken == null && authData['token'] != null) {
        _currentToken = authData['token'];
      }
      
      getActiveSymbols();
      subscribeToBalance();
    }
  }

  void _handleBalance(Map<String, dynamic> data) {
    if (data['balance'] != null) {
      final balanceData = data['balance'];
      if (balanceData is Map) {
        _balance = (balanceData['balance'] ?? balanceData['amount'] ?? 0.0).toDouble();
      } else {
        _balance = (balanceData as num).toDouble();
      }
      _balanceController.add(_balance);
    }
  }

  void _handleActiveSymbols(Map<String, dynamic> data) {
    if (data['active_symbols'] != null) {
      _activeSymbols = List<Map<String, dynamic>>.from(data['active_symbols']);
    }
  }

  void _handleTick(Map<String, dynamic> data) {
    if (data['tick'] != null) {
      _tickController.add(data['tick']);
    }
  }

  void _handleProposal(Map<String, dynamic> data) {
    if (data['proposal'] != null) {
      _proposalController.add(data['proposal']);
    }
  }

  void _handleBuy(Map<String, dynamic> data) {
    if (data['buy'] != null) {
      _contractController.add(data['buy']);
    }
  }

  void _handleContract(Map<String, dynamic> data) {
    if (data['proposal_open_contract'] != null) {
      _contractController.add(data['proposal_open_contract']);
    }
  }

  void _sendMessage(Map<String, dynamic> message) {
    if (_channel != null) {
      _channel!.sink.add(jsonEncode(message));
    }
  }

  void getActiveSymbols() {
    _sendMessage({
      'active_symbols': 'brief',
      'product_type': 'basic',
    });
  }

  void subscribeToBalance() {
    _sendMessage({
      'balance': 1,
      'subscribe': 1,
    });
  }

  void subscribeTicks(String symbol) {
    if (_forgetTickId != null) {
      _sendMessage({'forget': _forgetTickId});
    }
    
    _sendMessage({
      'ticks': symbol,
      'subscribe': 1,
    });
  }

  void getProposal({
    required String contractType,
    required String symbol,
    required String currency,
    required double amount,
    required String duration,
    required String durationType,
    String? barrier,
  }) {
    final proposal = {
      'proposal': 1,
      'amount': amount,
      'basis': 'stake',
      'contract_type': contractType,
      'currency': currency,
      'duration': int.parse(duration),
      'duration_unit': durationType,
      'symbol': symbol,
      'subscribe': 1,
    };

    if (barrier != null) {
      proposal['barrier'] = barrier;
    }

    _sendMessage(proposal);
  }

  void buyContract(String proposalId, double price) {
    _sendMessage({
      'buy': proposalId,
      'price': price,
    });
  }

  void getOpenContracts() {
    _sendMessage({
      'portfolio': 1,
    });
  }

  void sellContract(String contractId) {
    _sendMessage({
      'sell': contractId,
    });
  }

  void disconnect() {
    _forgetTickId = null;
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
    _currentToken = null;
    _balance = 0.0;
    _accountInfo = null;
    _activeSymbols = [];
    _connectionController.add(false);
  }

  void dispose() {
    disconnect();
    _connectionController.close();
    _balanceController.close();
    _accountController.close();
    _tickController.close();
    _proposalController.close();
    _contractController.close();
  }
}