// lib/services/deriv_service.dart
import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http/http.dart' as http;

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
  String? _forgetProposalId;

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
          print('WebSocket error: $error');
          _isConnected = false;
          _connectionController.add(false);
        },
        onDone: () {
          print('WebSocket closed');
          _isConnected = false;
          _connectionController.add(false);
        },
      );
    } catch (e) {
      print('Connection error: $e');
      _isConnected = false;
      _connectionController.add(false);
      rethrow;
    }
  }

  /// LOGIN COM TOKEN (OAuth ou API Token)
  Future<void> connectWithToken(String token) async {
    if (token.isEmpty) {
      throw Exception('Token vazio');
    }
    
    print('Conectando com token: ${token.substring(0, 10)}...');
    _currentToken = token;
    _connect();
    await Future.delayed(Duration(milliseconds: 800));
    _sendMessage({'authorize': token});
  }

  /// OBTER TOKEN A PARTIR DE EMAIL/PASSWORD
  Future<String?> getApiTokenFromCredentials(String email, String password) async {
    try {
      print('Tentando obter token com credenciais...');
      
      // Conectar temporariamente
      _connect();
      await Future.delayed(Duration(milliseconds: 800));

      final completer = Completer<String?>();
      StreamSubscription? sub;
      bool completed = false;

      sub = _channel!.stream.listen((message) {
        if (completed) return;
        
        try {
          final data = jsonDecode(message);
          print('Resposta recebida: ${data['msg_type']}');
          
          if (data['msg_type'] == 'authorize' && data['authorize'] != null) {
            final token = data['authorize']['token'];
            if (token != null && !completed) {
              completed = true;
              print('Token obtido com sucesso');
              completer.complete(token);
              sub?.cancel();
            }
          } else if (data['error'] != null && !completed) {
            completed = true;
            print('Erro: ${data['error']['message']}');
            completer.complete(null);
            sub?.cancel();
          }
        } catch (e) {
          print('Erro ao processar mensagem: $e');
        }
      });

      // Enviar credenciais
      _sendMessage({
        'authorize': email,
        'password': password,
      });

      // Timeout de 10 segundos
      final token = await completer.future.timeout(
        Duration(seconds: 10),
        onTimeout: () {
          print('Timeout ao obter token');
          return null;
        },
      );

      sub?.cancel();
      return token;

    } catch (e) {
      print('Erro ao obter token: $e');
      return null;
    }
  }

  /// LOGIN DIRETO COM EMAIL/PASSWORD (Fallback)
  Future<Map<String, dynamic>> loginWithCredentials(String email, String password) async {
    try {
      print('Login direto com credenciais...');
      
      _connect();
      await Future.delayed(Duration(milliseconds: 800));

      _sendMessage({
        'authorize': email,
        'password': password,
      });

      // Aguardar conexão
      await Future.delayed(Duration(seconds: 3));

      if (_isConnected) {
        return {
          'success': true,
          'token': _currentToken,
          'message': 'Login realizado'
        };
      } else {
        return {
          'success': false,
          'error': 'Falha na autenticação'
        };
      }

    } catch (e) {
      print('Erro no login: $e');
      return {
        'success': false,
        'error': e.toString()
      };
    }
  }

  void _handleMessage(dynamic message) {
    try {
      final data = jsonDecode(message);

      if (data['error'] != null) {
        print('API Error: ${data['error']['message']} (${data['error']['code']})');
        
        if (data['error']['code'] == 'InvalidToken' || 
            data['error']['code'] == 'AuthorizationRequired') {
          _isConnected = false;
          _connectionController.add(false);
        }
        return;
      }

      switch (data['msg_type']) {
        case 'authorize':
          _handleAuthorize(data);
          break;
        case 'balance':
          _handleBalance(data);
          break;
        case 'active_symbols':
          _handleActiveSymbols(data);
          break;
        case 'tick':
          _handleTick(data);
          break;
        case 'proposal':
          _handleProposal(data);
          break;
        case 'buy':
          _handleBuy(data);
          break;
        case 'proposal_open_contract':
          _handleContract(data);
          break;
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
        'balance': (authData['balance'] ?? 0).toDouble(),
        'account_type': authData['account_type'] ?? 'demo',
        'email': authData['email'],
      };

      _balance = _accountInfo!['balance'];
      _balanceController.add(_balance);
      _accountController.add(_accountInfo);

      if (_currentToken == null && authData['token'] != null) {
        _currentToken = authData['token'];
      }

      print('✅ Autorizado: ${_accountInfo!['loginid']} | Saldo: $_balance ${_accountInfo!['currency']}');

      getActiveSymbols();
      subscribeToBalance();
    }
  }

  void _handleBalance(Map<String, dynamic> data) {
    if (data['balance'] != null) {
      final balanceData = data['balance'];
      if (balanceData is Map) {
        _balance = ((balanceData['balance'] ?? balanceData['amount'] ?? 0) as num).toDouble();
      } else {
        _balance = (balanceData as num).toDouble();
      }
      _balanceController.add(_balance);
    }
  }

  void _handleActiveSymbols(Map<String, dynamic> data) {
    if (data['active_symbols'] != null) {
      _activeSymbols = List<Map<String, dynamic>>.from(data['active_symbols']);
      print('Loaded ${_activeSymbols.length} symbols');
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

      _contractHistory.add({
        'contract_id': buyData['contract_id'],
        'buy_price': (buyData['buy_price'] ?? 0).toDouble(),
        'payout': (buyData['payout'] ?? 0).toDouble(),
        'timestamp': DateTime.now().toIso8601String(),
        'status': 'open',
      });

      _contractController.add(buyData);

      if (buyData['contract_id'] != null) {
        _sendMessage({
          'proposal_open_contract': 1,
          'contract_id': buyData['contract_id'],
          'subscribe': 1,
        });
      }

      print('✅ Trade executado: ${buyData['contract_id']}');
    }
  }

  void _handleContract(Map<String, dynamic> data) {
    if (data['proposal_open_contract'] != null) {
      final contract = data['proposal_open_contract'];

      if (contract['status'] == 'sold' || 
          contract['status'] == 'won' || 
          contract['status'] == 'lost') {
        
        final buyPrice = (contract['buy_price'] ?? 0).toDouble();
        final sellPrice = (contract['sell_price'] ?? contract['bid_price'] ?? 0).toDouble();
        final profit = sellPrice - buyPrice;

        if (profit > 0) {
          _totalProfit += profit;
          _winCount++;
          print('✅ WIN: +\$${profit.toStringAsFixed(2)}');
        } else if (profit < 0) {
          _totalLoss += profit.abs();
          _lossCount++;
          print('❌ LOSS: -\$${profit.abs().toStringAsFixed(2)}');
        }

        final index = _contractHistory.indexWhere((c) => c['contract_id'] == contract['contract_id']);
        if (index != -1) {
          _contractHistory[index]['status'] = contract['status'];
          _contractHistory[index]['sell_price'] = sellPrice;
          _contractHistory[index]['profit'] = profit;
        }

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
      final jsonMessage = jsonEncode(message);
      _channel!.sink.add(jsonMessage);
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

  void forgetProposal() {
    if (_forgetProposalId != null) {
      _sendMessage({'forget': _forgetProposalId});
      _forgetProposalId = null;
    }
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
    forgetProposal();

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

    if (barrier != null && barrier.isNotEmpty) {
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

    print('📊 P&L resetado');
  }

  void disconnect() {
    print('🔌 Desconectando...');
    _forgetTickId = null;
    _forgetProposalId = null;
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