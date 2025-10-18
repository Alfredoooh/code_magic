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
  final StreamController<Map<String, dynamic>> _plController = StreamController<Map<String, dynamic>>.broadcast();

  String? _currentToken;
  bool _isConnected = false;
  double _balance = 0.0;
  Map<String, dynamic>? _accountInfo;
  List<Map<String, dynamic>> _activeSymbols = [];
  String? _forgetTickId;
  
  // P&L Tracking
  double _totalProfit = 0.0;
  double _totalLoss = 0.0;
  int _winCount = 0;
  int _lossCount = 0;
  List<Map<String, dynamic>> _contractHistory = [];

  Stream<bool> get connectionState => _connectionController.stream;
  Stream<double> get balanceStream => _balanceController.stream;
  Stream<Map<String, dynamic>?> get accountInfo => _accountController.stream;
  Stream<Map<String, dynamic>> get tickStream => _tickController.stream;
  Stream<Map<String, dynamic>> get proposalStream => _proposalController.stream;
  Stream<Map<String, dynamic>> get contractStream => _contractController.stream;
  Stream<Map<String, dynamic>> get plStream => _plController.stream;

  bool get isConnected => _isConnected;
  double get balance => _balance;
  String? get currentToken => _currentToken;
  List<Map<String, dynamic>> get activeSymbols => _activeSymbols;
  double get totalProfit => _totalProfit;
  double get totalLoss => _totalLoss;
  int get winCount => _winCount;
  int get lossCount => _lossCount;
  List<Map<String, dynamic>> get contractHistory => _contractHistory;

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
      final buyData = data['buy'];
      
      // Track contract for P&L
      _contractHistory.add({
        'contract_id': buyData['contract_id'],
        'buy_price': buyData['buy_price']?.toDouble() ?? 0.0,
        'payout': buyData['payout']?.toDouble() ?? 0.0,
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'open',
      });
      
      _contractController.add(buyData);
      
      // Subscribe to contract updates
      if (buyData['contract_id'] != null) {
        _sendMessage({
          'proposal_open_contract': 1,
          'contract_id': buyData['contract_id'],
          'subscribe': 1,
        });
      }
    }
  }

  void _handleContract(Map<String, dynamic> data) {
    if (data['proposal_open_contract'] != null) {
      final contract = data['proposal_open_contract'];
      
      // Update P&L when contract closes
      if (contract['status'] == 'sold' || contract['status'] == 'won' || contract['status'] == 'lost') {
        final buyPrice = contract['buy_price']?.toDouble() ?? 0.0;
        final sellPrice = contract['sell_price']?.toDouble() ?? contract['bid_price']?.toDouble() ?? 0.0;
        final profit = sellPrice - buyPrice;
        
        if (profit > 0) {
          _totalProfit += profit;
          _winCount++;
        } else if (profit < 0) {
          _totalLoss += profit.abs();
          _lossCount++;
        }
        
        // Update contract history
        final index = _contractHistory.indexWhere((c) => c['contract_id'] == contract['contract_id']);
        if (index != -1) {
          _contractHistory[index]['status'] = contract['status'];
          _contractHistory[index]['sell_price'] = sellPrice;
          _contractHistory[index]['profit'] = profit;
        }
        
        // Emit P&L update
        _plController.add({
          'total_profit': _totalProfit,
          'total_loss': _totalLoss,
          'net_profit': _totalProfit - _totalLoss,
          'win_count': _winCount,
          'loss_count': _lossCount,
          'win_rate': (_winCount + _lossCount) > 0 ? (_winCount / (_winCount + _lossCount)) * 100 : 0.0,
        });
      }
      
      _contractController.add(contract);
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

  void resetPL() {
    _totalProfit = 0.0;
    _totalLoss = 0.0;
    _winCount = 0;
    _lossCount = 0;
    _contractHistory.clear();
    
    _plController.add({
      'total_profit': 0.0,
      'total_loss': 0.0,
      'net_profit': 0.0,
      'win_count': 0,
      'loss_count': 0,
      'win_rate': 0.0,
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
    _plController.close();
  }
}