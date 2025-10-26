// trade_logic_controller.dart
// ========================================
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'trading_logic.dart';
import 'ml_predictor.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';

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

  // Markets organized by categories
  final Map<String, Map<String, String>> marketCategories = {
    'Volatility Indices': {
      'R_10': 'Volatility 10 Index',
      'R_25': 'Volatility 25 Index',
      'R_50': 'Volatility 50 Index',
      'R_75': 'Volatility 75 Index',
      'R_100': 'Volatility 100 Index',
    },
    'Volatility 1s': {
      '1HZ10V': 'Volatility 10 (1s) Index',
      '1HZ25V': 'Volatility 25 (1s) Index',
      '1HZ50V': 'Volatility 50 (1s) Index',
      '1HZ75V': 'Volatility 75 (1s) Index',
      '1HZ100V': 'Volatility 100 (1s) Index',
    },
    'Crash/Boom': {
      'BOOM300N': 'Boom 300 Index',
      'BOOM500': 'Boom 500 Index',
      'CRASH300N': 'Crash 300 Index',
      'CRASH500': 'Crash 500 Index',
    },
    'Forex': {
      'EURUSD': 'EUR/USD',
      'GBPUSD': 'GBP/USD',
      'USDJPY': 'USD/JPY',
    },
    'Cryptocurrencies': {
      'BTCUSD': 'Bitcoin',
      'ETHUSD': 'Ethereum',
    },
  };

  // Flatten all markets for quick lookup
  Map<String, String> get allMarkets {
    final Map<String, String> result = {};
    marketCategories.forEach((category, markets) {
      result.addAll(markets);
    });
    return result;
  }

  final List<Map<String, dynamic>> tradeTypes = [
    {
      'id': 'rise_fall',
      'label': 'Rise/Fall',
      'icon': Icons.trending_up_rounded,
      'description': 'Predict if price will rise or fall',
      'color': AppColors.primary,
    },
    {
      'id': 'higher_lower',
      'label': 'Higher/Lower',
      'icon': Icons.compare_arrows_rounded,
      'description': 'Compare price at end with current',
      'color': AppColors.secondary,
    },
    {
      'id': 'turbos',
      'label': 'Turbos',
      'icon': Icons.rocket_launch_rounded,
      'description': 'Fast-paced short-term trades',
      'color': AppColors.tertiary,
    },
    {
      'id': 'accumulators',
      'label': 'Accumulators',
      'icon': Icons.layers_rounded,
      'description': 'Accumulate profits over time',
      'color': AppColors.success,
    },
    {
      'id': 'multipliers',
      'label': 'Multipliers',
      'icon': Icons.auto_graph,
      'description': 'Multiply your potential profit',
      'color': AppColors.info,
    },
    {
      'id': 'even_odd',
      'label': 'Even/Odd',
      'icon': Icons.filter_9_plus_rounded,
      'description': 'Predict if last digit is even or odd',
      'color': AppColors.warning,
    },
    {
      'id': 'match_differ',
      'label': 'Match/Differ',
      'icon': Icons.compare_rounded,
      'description': 'Match or differ from prediction',
      'color': AppColors.error,
    },
    {
      'id': 'over_under',
      'label': 'Over/Under',
      'icon': Icons.height_rounded,
      'description': 'Predict if value is over or under',
      'color': AppColors.primary,
    },
  ];

  TradeLogicController({
    required this.token,
    this.initialMarket,
    required this.onStateChanged,
  }) {
    if (initialMarket != null && allMarkets.containsKey(initialMarket)) {
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

  // Getters
  double get balance => _tradingLogic.balance;
  String get currency => _tradingLogic.currency;
  bool get isConnected => _tradingLogic.isConnected;
  List<Map<String, dynamic>> get activePositions => _tradingLogic.activePositions;
  Map<String, dynamic>? get mlPrediction => _mlPredictor.currentPrediction;
  double get mlRecommendedStake => _mlPredictor.recommendedStake(balance);
  double get mlAccuracy => _mlPredictor.accuracy;
  int get mlTotalPredictions => _mlPredictor.totalPredictions;

  String get selectedMarketName => allMarkets[selectedMarket] ?? selectedMarket;
  
  Map<String, dynamic>? get selectedTradeTypeData {
    try {
      return tradeTypes.firstWhere((t) => t['id'] == selectedTradeType);
    } catch (e) {
      return null;
    }
  }

  String get durationLabel {
    switch (durationType) {
      case 't': return 'Ticks';
      case 's': return 'Seconds';
      case 'm': return 'Minutes';
      case 'h': return 'Hours';
      case 'd': return 'Days';
      default: return 'Ticks';
    }
  }

  String get durationShortLabel {
    switch (durationType) {
      case 't': return 't';
      case 's': return 's';
      case 'm': return 'm';
      case 'h': return 'h';
      case 'd': return 'd';
      default: return 't';
    }
  }

  // Price color based on change direction
  Color getPriceColor(BuildContext context) {
    if (priceChange > 0) {
      return AppColors.success;
    } else if (priceChange < 0) {
      return AppColors.error;
    }
    return Theme.of(context).colorScheme.onSurface;
  }

  // Trade type color
  Color getTradeTypeColor() {
    final tradeData = selectedTradeTypeData;
    return tradeData?['color'] as Color? ?? AppColors.primary;
  }

  // Check if current trade type needs duration
  bool get needsDuration {
    return !['turbos', 'accumulators'].contains(selectedTradeType);
  }

  // Check if current trade type needs barrier/prediction
  bool get needsBarrier {
    return ['match_differ', 'over_under'].contains(selectedTradeType);
  }

  // Check if current trade type needs multiplier
  bool get needsMultiplier {
    return selectedTradeType == 'multipliers';
  }

  // Validate stake amount
  String? validateStake() {
    if (stake <= 0) {
      return 'Stake must be greater than 0';
    }
    if (stake > balance) {
      return 'Insufficient balance';
    }
    return null;
  }

  // Update methods
  void updatePrice(double price, double change) {
    currentPrice = price;
    priceChange = change;
    _mlPredictor.addPriceData(price);
    onStateChanged();
  }

  void changeMarket(String market) {
    if (allMarkets.containsKey(market)) {
      selectedMarket = market;
      _mlPredictor.setMarket(market);
      onStateChanged();
    }
  }

  void changeTradeType(String type) {
    selectedTradeType = type;
    
    // Reset specific settings when changing trade type
    if (type != 'multipliers') {
      multiplier = 5;
      multiplierStopLossPercent = 50.0;
      multiplierTakeProfitPercent = 0.0;
    }
    if (!needsBarrier) {
      tickPrediction = 5;
    }
    
    onStateChanged();
  }

  void setStake(double value) {
    if (value >= 0) {
      stake = value;
      onStateChanged();
    }
  }

  void setDurationType(String type) {
    durationType = type;
    // Adjust duration value based on type
    switch (type) {
      case 't':
        durationValue = durationValue > 10 ? 5 : durationValue;
        break;
      case 's':
        durationValue = durationValue < 15 ? 15 : durationValue;
        break;
      case 'm':
        durationValue = durationValue > 1440 ? 5 : durationValue;
        break;
      case 'h':
        durationValue = durationValue > 24 ? 1 : durationValue;
        break;
      case 'd':
        durationValue = durationValue > 365 ? 1 : durationValue;
        break;
    }
    onStateChanged();
  }

  void setDurationValue(int value) {
    if (value > 0) {
      durationValue = value;
      onStateChanged();
    }
  }

  void setMultiplier(int value) {
    if (value >= 1 && value <= 1000) {
      multiplier = value;
      onStateChanged();
    }
  }

  void setMultiplierStopLoss(double percent) {
    if (percent >= 0 && percent <= 100) {
      multiplierStopLossPercent = percent;
      onStateChanged();
    }
  }

  void setMultiplierTakeProfit(double percent) {
    if (percent >= 0) {
      multiplierTakeProfitPercent = percent;
      onStateChanged();
    }
  }

  void setTickPrediction(int value) {
    if (value >= 0 && value <= 9) {
      tickPrediction = value;
      onStateChanged();
    }
  }

  void toggleSound() {
    soundEnabled = !soundEnabled;
    AppHaptics.selection();
    onStateChanged();
  }

  Future<void> _handleTradeResult(Map<String, dynamic> result) async {
    final won = result['won'] as bool? ?? false;
    final profit = (result['profit'] as num?)?.toDouble() ?? 0.0;

    // Play sound feedback
    if (soundEnabled) {
      try {
        if (won) {
          await _audioPlayer.play(AssetSource('sounds/win.mp3'));
        } else {
          await _audioPlayer.play(AssetSource('sounds/lose.mp3'));
        }
      } catch (e) {
        debugPrint('Error playing sound: $e');
      }
    }

    // Haptic feedback
    if (won) {
      AppHaptics.success();
    } else {
      AppHaptics.error();
    }

    entryPrice = null;
    entryDirection = null;
    onStateChanged();

    _mlPredictor.addTradeResult(won, profit);
  }

  Future<void> placeTrade(String direction) async {
    if (isTrading || !isConnected) return;

    // Validate stake
    final stakeError = validateStake();
    if (stakeError != null) {
      debugPrint('Stake validation error: $stakeError');
      return;
    }

    // Handle accumulator sell
    if (selectedTradeType == 'accumulators') {
      if (hasActiveAccumulator && direction == 'sell') {
        await _tradingLogic.closeAccumulator(activeAccumulatorId!);
        hasActiveAccumulator = false;
        activeAccumulatorId = null;
        AppHaptics.light();
        onStateChanged();
        return;
      }
    }

    isTrading = true;
    AppHaptics.selection();
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
        AppHaptics.success();
      } else {
        AppHaptics.error();
      }
    } catch (e) {
      debugPrint('Trade placement error: $e');
      success = false;
      AppHaptics.error();
    }

    isTrading = false;
    onStateChanged();
  }

  // Get button label based on trade type and position
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
      case 'accumulators':
        return hasActiveAccumulator ? 'CLOSE' : 'START';
      default:
        return isLeft ? 'BUY' : 'SELL';
    }
  }

  // Get button icon
  IconData getButtonIcon(bool isLeft) {
    switch (selectedTradeType) {
      case 'rise_fall':
      case 'higher_lower':
      case 'turbos':
        return isLeft ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;
      case 'multipliers':
        return isLeft ? Icons.add_circle_rounded : Icons.remove_circle_rounded;
      case 'accumulators':
        return hasActiveAccumulator ? Icons.stop_rounded : Icons.play_arrow_rounded;
      default:
        return isLeft ? Icons.check_rounded : Icons.close_rounded;
    }
  }

  // Calculate potential profit
  double getPotentialProfit() {
    // Simplified calculation - actual depends on contract type
    switch (selectedTradeType) {
      case 'multipliers':
        return stake * multiplier;
      case 'turbos':
        return stake * 1.95; // Typical payout
      default:
        return stake * 1.85; // Average payout ratio
    }
  }

  // Get position summary text
  String getPositionSummary() {
    final count = activePositions.length;
    if (count == 0) return 'No active positions';
    if (count == 1) return '1 active position';
    return '$count active positions';
  }
}