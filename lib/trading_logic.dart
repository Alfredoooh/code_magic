// trading_logic.dart
import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class TradingLogic {
  final String token;
  final Function(double balance, String currency) onBalanceUpdate;
  final Function(Map<String, dynamic> result) onTradeResult;
  final Function(List<Map<String, dynamic>> positions) onPositionUpdate;

  WebSocketChannel? _channel;
  bool isConnected = false;
  double balance = 0.0;
  String currency = 'USD';
  List<Map<String, dynamic>> activePositions = [];

  String? _lastProposalId;
  Map<String, Completer<bool>> _pendingTrades = {};

  TradingLogic({
    required this.token,
    required this.onBalanceUpdate,
    required this.onTradeResult,
    required this.onPositionUpdate,
  });

  void connect() {
    try {
      _channel = WebSocketChannel.connect(
        Uri.parse('wss://ws.derivws.com/websockets/v3?app_id=71954'),
      );

      isConnected = true;

      _channel!.stream.listen(
        (message) => _handleMessage(json.decode(message)),
        onError: (error) => isConnected = false,
        onDone: () {
          isConnected = false;
          Future.delayed(const Duration(seconds: 3), connect);
        },
      );

      _channel!.sink.add(json.encode({'authorize': token}));
    } catch (e) {
      isConnected = false;
    }
  }

  void _handleMessage(Map<String, dynamic> data) {
    switch (data['msg_type']) {
      case 'authorize':
        balance = double.parse(data['authorize']['balance'].toString());
        currency = data['authorize']['currency'];
        onBalanceUpdate(balance, currency);
        break;

      case 'proposal':
        _lastProposalId = data['proposal']['id'];
        break;

      case 'buy':
        final contract = data['buy'];
        final contractId = contract['contract_id'].toString();

        activePositions.add({
          'contract_id': contractId,
          'buy_price': double.parse(contract['buy_price'].toString()),
          'payout': double.parse(contract['payout'].toString()),
          'longcode': contract['longcode'],
          'profit': 0.0,
          'status': 'open',
        });

        onPositionUpdate(activePositions);

        // Subscrever para atualizações do contrato
        _channel!.sink.add(json.encode({
          'proposal_open_contract': 1,
          'contract_id': contractId,
          'subscribe': 1,
        }));

        // Resolver o completer do trade pendente
        if (_pendingTrades.containsKey(contractId)) {
          _pendingTrades[contractId]!.complete(true);
          _pendingTrades.remove(contractId);
        }
        break;

      case 'proposal_open_contract':
        _updatePosition(data['proposal_open_contract']);
        break;

      case 'balance':
        balance = double.parse(data['balance']['balance'].toString());
        onBalanceUpdate(balance, currency);
        break;

      case 'error':
        print('Erro da API: ${data['error']['message']}');
        // Resolver completers pendentes com falha
        _pendingTrades.forEach((key, completer) {
          if (!completer.isCompleted) {
            completer.complete(false);
          }
        });
        _pendingTrades.clear();
        break;
    }
  }

  void _updatePosition(Map<String, dynamic> contract) {
    final contractId = contract['contract_id'].toString();
    final index = activePositions.indexWhere((p) => p['contract_id'] == contractId);

    if (index != -1) {
      final profit = double.parse(contract['profit'].toString());
      final status = contract['status'];

      activePositions[index]['profit'] = profit;
      activePositions[index]['status'] = status;
      activePositions[index]['current_spot'] = contract['current_spot'];

      onPositionUpdate(activePositions);

      if (status == 'won' || status == 'lost') {
        final won = status == 'won';
        onTradeResult({
          'won': won,
          'profit': profit,
          'contract_id': contractId,
        });

        Future.delayed(const Duration(seconds: 3), () {
          activePositions.removeWhere((p) => p['contract_id'] == contractId);
          onPositionUpdate(activePositions);
        });
      }
    }
  }

  Future<bool> placeRiseFall({
    required String market,
    required double stake,
    required String direction,
    int duration = 5,
    String durationType = 't',
  }) async {
    if (!isConnected) return false;

    final contractType = direction == 'buy' ? 'CALL' : 'PUT';

    _channel!.sink.add(json.encode({
      'proposal': 1,
      'amount': stake,
      'basis': 'stake',
      'contract_type': contractType,
      'currency': currency,
      'duration': duration,
      'duration_unit': durationType,
      'symbol': market,
    }));

    await Future.delayed(const Duration(milliseconds: 500));

    if (_lastProposalId == null) return false;

    final completer = Completer<bool>();
    final tempId = DateTime.now().millisecondsSinceEpoch.toString();
    _pendingTrades[tempId] = completer;

    _channel!.sink.add(json.encode({
      'buy': _lastProposalId,
      'price': stake,
    }));

    return completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        _pendingTrades.remove(tempId);
        return false;
      },
    );
  }

  Future<bool> placeHigherLower({
    required String market,
    required double stake,
    required String direction,
    int duration = 15,
    String durationType = 't',
  }) async {
    if (!isConnected) return false;

    final contractType = direction == 'buy' ? 'CALLE' : 'PUTE';

    _channel!.sink.add(json.encode({
      'proposal': 1,
      'amount': stake,
      'basis': 'stake',
      'contract_type': contractType,
      'currency': currency,
      'duration': duration,
      'duration_unit': durationType,
      'symbol': market,
    }));

    await Future.delayed(const Duration(milliseconds: 500));

    if (_lastProposalId == null) return false;

    final completer = Completer<bool>();
    final tempId = DateTime.now().millisecondsSinceEpoch.toString();
    _pendingTrades[tempId] = completer;

    _channel!.sink.add(json.encode({
      'buy': _lastProposalId,
      'price': stake,
    }));

    return completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        _pendingTrades.remove(tempId);
        return false;
      },
    );
  }

  Future<bool> placeTurbo({
    required String market,
    required double stake,
    required String direction,
  }) async {
    if (!isConnected) return false;

    final contractType = direction == 'buy' ? 'MULTUP' : 'MULTDOWN';

    _channel!.sink.add(json.encode({
      'proposal': 1,
      'amount': stake,
      'basis': 'stake',
      'contract_type': contractType,
      'currency': currency,
      'multiplier': 100,
      'symbol': market,
    }));

    await Future.delayed(const Duration(milliseconds: 500));

    if (_lastProposalId == null) return false;

    final completer = Completer<bool>();
    final tempId = DateTime.now().millisecondsSinceEpoch.toString();
    _pendingTrades[tempId] = completer;

    _channel!.sink.add(json.encode({
      'buy': _lastProposalId,
      'price': stake,
    }));

    return completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        _pendingTrades.remove(tempId);
        return false;
      },
    );
  }

  Future<Map<String, dynamic>> placeAccumulator({
    required String market,
    required double stake,
  }) async {
    if (!isConnected) return {'success': false};

    _channel!.sink.add(json.encode({
      'proposal': 1,
      'amount': stake,
      'basis': 'stake',
      'contract_type': 'ACCU',
      'currency': currency,
      'growth_rate': 0.03,
      'symbol': market,
    }));

    await Future.delayed(const Duration(milliseconds: 500));

    if (_lastProposalId == null) return {'success': false};

    final completer = Completer<bool>();
    final tempId = DateTime.now().millisecondsSinceEpoch.toString();
    _pendingTrades[tempId] = completer;

    _channel!.sink.add(json.encode({
      'buy': _lastProposalId,
      'price': stake,
    }));

    final success = await completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        _pendingTrades.remove(tempId);
        return false;
      },
    );

    if (success && activePositions.isNotEmpty) {
      return {
        'success': true,
        'contract_id': activePositions.last['contract_id'],
      };
    }

    return {'success': false};
  }

  Future<bool> closeAccumulator(String contractId) async {
    if (!isConnected) return false;

    _channel!.sink.add(json.encode({
      'sell': contractId,
      'price': 0,
    }));

    await Future.delayed(const Duration(milliseconds: 500));

    // Remover da lista de posições ativas
    activePositions.removeWhere((p) => p['contract_id'] == contractId);
    onPositionUpdate(activePositions);

    return true;
  }

  Future<bool> placeDigit({
    required String market,
    required double stake,
    required String type,
    String? barrier,
    int duration = 5,
  }) async {
    if (!isConnected) return false;

    final Map<String, dynamic> params = {
      'proposal': 1,
      'amount': stake,
      'basis': 'stake',
      'contract_type': type,
      'currency': currency,
      'duration': duration,
      'duration_unit': 't',
      'symbol': market,
    };

    if (barrier != null) {
      params['barrier'] = barrier;
    }

    _channel!.sink.add(json.encode(params));

    await Future.delayed(const Duration(milliseconds: 500));

    if (_lastProposalId == null) return false;

    final completer = Completer<bool>();
    final tempId = DateTime.now().millisecondsSinceEpoch.toString();
    _pendingTrades[tempId] = completer;

    _channel!.sink.add(json.encode({
      'buy': _lastProposalId,
      'price': stake,
    }));

    return completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        _pendingTrades.remove(tempId);
        return false;
      },
    );
  }

  // === NOVA FUNÇÃO: placeMultiplier ===
  // Chamada padrão: await placeMultiplier(market: 'BTCUSD', stake: 1.0, direction: 'buy', multiplier: 5);
  // Retorna um Map {'success': bool, 'contract_id': String?}
  Future<Map<String, dynamic>> placeMultiplier({
    required String market,
    required double stake,
    required String direction,
    required int multiplier,
    double? stopLossPercent,
    double? takeProfitPercent,
  }) async {
    if (!isConnected) return {'success': false};

    final contractType = direction == 'buy' ? 'MULTUP' : 'MULTDOWN';

    final Map<String, dynamic> params = {
      'proposal': 1,
      'amount': stake,
      'basis': 'stake',
      'contract_type': contractType,
      'currency': currency,
      'multiplier': multiplier,
      'symbol': market,
    };

    // Incluir stop/take se fornecidos (ajuste as chaves conforme necessidade da API)
    if (stopLossPercent != null) {
      params['stop_loss'] = stopLossPercent;
    }
    if (takeProfitPercent != null && takeProfitPercent > 0) {
      params['take_profit'] = takeProfitPercent;
    }

    _channel!.sink.add(json.encode(params));

    await Future.delayed(const Duration(milliseconds: 500));

    if (_lastProposalId == null) return {'success': false};

    final completer = Completer<bool>();
    final tempId = DateTime.now().millisecondsSinceEpoch.toString();
    _pendingTrades[tempId] = completer;

    _channel!.sink.add(json.encode({
      'buy': _lastProposalId,
      'price': stake,
    }));

    final success = await completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        _pendingTrades.remove(tempId);
        return false;
      },
    );

    if (success && activePositions.isNotEmpty) {
      return {
        'success': true,
        'contract_id': activePositions.last['contract_id'],
      };
    }

    return {'success': false};
  }
  // === FIM placeMultiplier ===

  void dispose() {
    _channel?.sink.close();
    _pendingTrades.forEach((key, completer) {
      if (!completer.isCompleted) {
        completer.complete(false);
      }
    });
    _pendingTrades.clear();
  }
}