// 1. trade_logic_controller.dart
// ========================================
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'trading_logic.dart';
import 'ml_predictor.dart';

class TradeLogicController {
  final String token;
  final String? initialMarket;
  final VoidCallback onStateChanged;

  late TradingLogic _tradingLogic;
  late MLPredictor _mlPredictor;
  final AudioPlayer _audioPlayer = AudioPlayer();

  String selectedMarket = 'R_100';
  String selectedTradeType = 'rise_fall';
  double currentPrice = 0.0;
  double priceChange = 0.0;
  double stake = 10.0;
  bool isTrading = false;
  bool soundEnabled = false;
  
  String durationType = 't';
  int durationValue = 5;
  
  bool hasActiveAccumulator = false;
  String? activeAccumulatorId;
  
  int multiplier = 5;
  double multiplierStopLossPercent = 50.0;
  double multiplierTakeProfitPercent = 0.0;
  
  int tickPrediction = 5;
  
  double? entryPrice;
  String? entryDirection;

  final Map<String, String> allMarkets = {
    'R_10': 'Volatility 10',
    'R_25': 'Volatility 25',
    'R_50': 'Volatility 50',
    'R_75': 'Volatility 75',
    'R_100': 'Volatility 100',
    '1HZ10V': 'Vol 10 (1s)',
    '1HZ25V': 'Vol 25 (1s)',
    '1HZ50V': 'Vol 50 (1s)',
    '1HZ75V': 'Vol 75 (1s)',
    '1HZ100V': 'Vol 100 (1s)',
    'BOOM300N': 'Boom 300',
    'BOOM500': 'Boom 500',
    'CRASH300N': 'Crash 300',
    'CRASH500': 'Crash 500',
    'EURUSD': 'Forex EUR/USD',
    'GBPUSD': 'Forex GBP/USD',
    'USDJPY': 'Forex USD/JPY',
    'BTCUSD': 'Bitcoin',
    'ETHUSD': 'Ethereum',
  };

  final List<Map<String, dynamic>> tradeTypes = [
    {'id': 'rise_fall', 'label': 'Rise/Fall', 'icon': Icons.trending_up_rounded},
    {'id': 'higher_lower', 'label': 'Higher/Lower', 'icon': Icons.compare_arrows_rounded},
    {'id': 'turbos', 'label': 'Turbos', 'icon': Icons.rocket_launch_rounded},
    {'id': 'accumulators', 'label': 'Accumulators', 'icon': Icons.layers_rounded},
    {'id': 'multipliers', 'label': 'Multipliers', 'icon': Icons.auto_graph},
    {'id': 'even_odd', 'label': 'Even/Odd', 'icon': Icons.filter_9_plus_rounded},
    {'id': 'match_differ', 'label': 'Match/Differ', 'icon': Icons.compare_rounded},
    {'id': 'over_under', 'label': 'Over/Under', 'icon': Icons.height_rounded},
  ];

  TradeLogicController({
    required this.token,
    this.initialMarket,
    required this.onStateChanged,
  }) {
    if (initialMarket != null) {
      selectedMarket = initialMarket!;
    }
  }

  void initialize() {
    _tradingLogic = TradingLogic(
      token: token,
      onBalanceUpdate: (balance, currency) => onStateChanged(),
      onTradeResult: (result) => _handleTradeResult(result),
      onPositionUpdate: (positions) {
        if (hasActiveAccumulator) {
          final stillActive = positions.any((p) => p['contract_id'] == activeAccumulatorId);
          if (!stillActive) {
            hasActiveAccumulator = false;
            activeAccumulatorId = null;
          }
        }
        onStateChanged();
      },
    );

    _mlPredictor = MLPredictor(
      onPrediction: (prediction) => onStateChanged(),
    );

    _mlPredictor.setMarket(selectedMarket);
    _tradingLogic.connect();
  }

  void dispose() {
    _tradingLogic.dispose();
    _audioPlayer.dispose();
    _mlPredictor.dispose();
  }

  double get balance => _tradingLogic.balance;
  String get currency => _tradingLogic.currency;
  bool get isConnected => _tradingLogic.isConnected;
  List<Map<String, dynamic>> get activePositions => _tradingLogic.activePositions;
  Map<String, dynamic>? get mlPrediction => _mlPredictor.currentPrediction;
  double get mlRecommendedStake => _mlPredictor.recommendedStake(balance);
  double get mlAccuracy => _mlPredictor.accuracy;
  int get mlTotalPredictions => _mlPredictor.totalPredictions;

  String get selectedMarketName => allMarkets[selectedMarket] ?? selectedMarket;
  String get durationLabel {
    switch (durationType) {
      case 't': return 't';
      case 's': return 's';
      case 'm': return 'm';
      case 'h': return 'h';
      case 'd': return 'd';
      default: return 't';
    }
  }

  void updatePrice(double price, double change) {
    currentPrice = price;
    priceChange = change;
    _mlPredictor.addPriceData(price);
    onStateChanged();
  }

  void changeMarket(String market) {
    selectedMarket = market;
    _mlPredictor.setMarket(market);
    onStateChanged();
  }

  void changeTradeType(String type) {
    selectedTradeType = type;
    onStateChanged();
  }

  void setStake(double value) {
    stake = value;
    onStateChanged();
  }

  void setDurationType(String type) {
    durationType = type;
    onStateChanged();
  }

  void setDurationValue(int value) {
    durationValue = value;
    onStateChanged();
  }

  void setMultiplier(int value) {
    multiplier = value;
    onStateChanged();
  }

  void setTickPrediction(int value) {
    tickPrediction = value;
    onStateChanged();
  }

  void toggleSound() {
    soundEnabled = !soundEnabled;
    onStateChanged();
  }

  Future<void> _handleTradeResult(Map<String, dynamic> result) async {
    final won = result['won'] as bool? ?? false;
    final profit = (result['profit'] as num?)?.toDouble() ?? 0.0;

    if (soundEnabled) {
      if (won) {
        await _audioPlayer.play(AssetSource('sounds/win.mp3'));
      } else {
        await _audioPlayer.play(AssetSource('sounds/lose.mp3'));
      }
    }

    entryPrice = null;
    entryDirection = null;
    onStateChanged();

    _mlPredictor.addTradeResult(won, profit);
  }

  Future<void> placeTrade(String direction) async {
    if (isTrading || !isConnected) return;

    if (selectedTradeType == 'accumulators') {
      if (hasActiveAccumulator && direction == 'sell') {
        await _tradingLogic.closeAccumulator(activeAccumulatorId!);
        hasActiveAccumulator = false;
        activeAccumulatorId = null;
        onStateChanged();
        return;
      }
    }

    isTrading = true;
    onStateChanged();

    bool success = false;

    try {
      switch (selectedTradeType) {
        case 'rise_fall':
          success = await _tradingLogic.placeRiseFall(
            market: selectedMarket,
            stake: stake,
            direction: direction,
            duration: durationValue,
            durationType: durationType,
          );
          break;
        case 'higher_lower':
          success = await _tradingLogic.placeHigherLower(
            market: selectedMarket,
            stake: stake,
            direction: direction,
            duration: durationValue,
            durationType: durationType,
          );
          break;
        case 'turbos':
          success = await _tradingLogic.placeTurbo(
            market: selectedMarket,
            stake: stake,
            direction: direction,
          );
          break;
        case 'accumulators':
          final result = await _tradingLogic.placeAccumulator(
            market: selectedMarket,
            stake: stake,
          );
          success = result['success'] as bool? ?? false;
          if (success) {
            activeAccumulatorId = result['contract_id'] as String?;
            hasActiveAccumulator = true;
          }
          break;
        case 'even_odd':
          success = await _tradingLogic.placeDigit(
            market: selectedMarket,
            stake: stake,
            type: direction == 'buy' ? 'DIGITEVEN' : 'DIGITODD',
            duration: durationValue,
          );
          break;
        case 'match_differ':
          success = await _tradingLogic.placeDigit(
            market: selectedMarket,
            stake: stake,
            type: direction == 'buy' ? 'DIGITMATCH' : 'DIGITDIFF',
            barrier: tickPrediction.toString(),
            duration: durationValue,
          );
          break;
        case 'over_under':
          success = await _tradingLogic.placeDigit(
            market: selectedMarket,
            stake: stake,
            type: direction == 'buy' ? 'DIGITOVER' : 'DIGITUNDER',
            barrier: tickPrediction.toString(),
            duration: durationValue,
          );
          break;
        case 'multipliers':
          final res = await _tradingLogic.placeMultiplier(
            market: selectedMarket,
            stake: stake,
            direction: direction,
            multiplier: multiplier,
            stopLossPercent: multiplierStopLossPercent,
            takeProfitPercent: multiplierTakeProfitPercent,
          );
          if (res is Map) {
            success = res['success'] as bool? ?? false;
          }
          break;
      }

      if (success) {
        entryPrice = currentPrice;
        entryDirection = direction;
      }
    } catch (e) {
      success = false;
    }

    isTrading = false;
    onStateChanged();
  }

  String getButtonLabel(bool isLeft) {
    switch (selectedTradeType) {
      case 'rise_fall':
        return isLeft ? 'RISE' : 'FALL';
      case 'higher_lower':
        return isLeft ? 'HIGHER' : 'LOWER';
      case 'turbos':
        return isLeft ? 'UP' : 'DOWN';
      case 'even_odd':
        return isLeft ? 'EVEN' : 'ODD';
      case 'match_differ':
        return isLeft ? 'MATCH' : 'DIFFER';
      case 'over_under':
        return isLeft ? 'OVER' : 'UNDER';
      case 'multipliers':
        return isLeft ? 'BUY' : 'SELL';
      default:
        return isLeft ? 'BUY' : 'SELL';
    }
  }
}
