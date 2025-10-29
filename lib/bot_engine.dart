// bot_engine.dart
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'bot_configuration.dart';
import 'bot_strategies.dart';
import 'bot_analysis.dart';

class TradingBot {
  final BotConfiguration config;
  final WebSocketChannel channel;
  final Function(BotStatus) onStatusUpdate;

  // Estado do bot
  bool isRunning = false;
  bool isPaused = false;
  double currentStake;
  int totalTrades = 0;
  int wins = 0;
  int losses = 0;
  double totalProfit = 0.0;
  double sessionProfit = 0.0;
  String? currentContractId;
  int consecutiveWins = 0;
  int consecutiveLosses = 0;
  DateTime? lastTradeTime;
  DateTime? startTime;

  // Dados de análise técnica
  List<double> priceHistory = [];
  List<double> rsiValues = [];
  double currentRSI = 50.0;
  double currentMACD = 0.0;
  double previousMACD = 0.0;
  double supportLevel = 0.0;
  double resistanceLevel = 0.0;

  // Performance tracking
  List<TradeRecord> tradeHistory = [];
  double maxDrawdown = 0.0;
  double peakProfit = 0.0;
  double avgWin = 0.0;
  double avgLoss = 0.0;

  // Martingale
  double lossStreakAmount = 0.0;

  // Progressive Reinvestment
  int currentCycle = 0;
  int currentRound = 0;
  double cycleStartStake = 0.0;
  double cycleTotalLosses = 0.0;

  // Trendy Adaptive
  bool trendDetected = false;
  String trendPhase = 'observation';  // observation, execution, recovery
  double profitBank = 0.0;

  // ACS-R v3.0
  List<String> last5Results = [];  // Últimos 5 resultados ('Over', 'Rise', etc)
  String activeDirection = 'neutral';
  bool shouldPauseForAnalysis = false;
  double acsrProfitBank = 0.0;
  double acsrLossAccumulated = 0.0;

  TradingBot({
    required this.config,
    required this.channel,
    required this.onStatusUpdate,
  }) : currentStake = (config.initialStake < 0.35 ? 0.35 : config.initialStake) {
    cycleStartStake = currentStake;
  }

  void start() {
    if (isRunning) return;
    isRunning = true;
    isPaused = false;
    startTime = DateTime.now();
    _resetStrategy();
    onStatusUpdate(getStatus());
    _scheduleTrade();
  }

  void pause() {
    isPaused = true;
    onStatusUpdate(getStatus());
  }

  void resume() {
    isPaused = false;
    onStatusUpdate(getStatus());
    if (currentContractId == null) {
      _scheduleTrade();
    }
  }

  void stop() {
    isRunning = false;
    isPaused = false;
    currentContractId = null;
    onStatusUpdate(getStatus());
  }

  void reset() {
    totalTrades = 0;
    wins = 0;
    losses = 0;
    totalProfit = 0.0;
    sessionProfit = 0.0;
    currentStake = config.initialStake;
    consecutiveWins = 0;
    consecutiveLosses = 0;
    tradeHistory.clear();
    maxDrawdown = 0.0;
    peakProfit = 0.0;
    avgWin = 0.0;
    avgLoss = 0.0;
    _resetStrategy();
    onStatusUpdate(getStatus());
  }

  void _resetStrategy() {
    lossStreakAmount = 0.0;
    
    // Progressive
    currentCycle = 0;
    currentRound = 0;
    cycleStartStake = config.initialStake;
    cycleTotalLosses = 0.0;
    
    // Trendy
    trendDetected = false;
    trendPhase = 'observation';
    profitBank = 0.0;
    
    // ACS-R
    last5Results.clear();
    activeDirection = 'neutral';
    shouldPauseForAnalysis = false;
    acsrProfitBank = 0.0;
    acsrLossAccumulated = 0.0;
  }

  void updatePrice(double price) {
    priceHistory.add(price);
    if (priceHistory.length > 1000) {
      priceHistory.removeAt(0);
    }

    if (priceHistory.length >= 14) {
      currentRSI = BotAnalysis.calculateRSI(priceHistory);
      rsiValues.add(currentRSI);
      if (rsiValues.length > 500) rsiValues.removeAt(0);
    }

    if (priceHistory.length >= 26) {
      final macdData = BotAnalysis.calculateMACD(priceHistory);
      previousMACD = currentMACD;
      currentMACD = macdData['macd']!;
    }

    if (priceHistory.length >= 50) {
      final sr = BotAnalysis.calculateSupportResistance(priceHistory);
      supportLevel = sr['support']!;
      resistanceLevel = sr['resistance']!;
    }
  }

  Future<void> _scheduleTrade() async {
    if (!isRunning || isPaused || currentContractId != null) return;

    // ACS-R: Pausar após 2 perdas consecutivas
    if (config.strategy == BotStrategy.adaptiveCompoundRecovery && shouldPauseForAnalysis) {
      await Future.delayed(Duration(seconds: 3));
      shouldPauseForAnalysis = false;
    }

    // Verificar tempo mínimo entre trades
    if (lastTradeTime != null) {
      final timeSinceLast = DateTime.now().difference(lastTradeTime!);
      if (timeSinceLast < config.minTimeBetweenTrades) {
        await Future.delayed(config.minTimeBetweenTimes - timeSinceLast);
      }
    }

    // Verificar limites
    if (!_checkLimits()) {
      stop();
      return;
    }

    // Verificar condições de entrada
    if (!await _checkEntryConditions()) {
      await Future.delayed(const Duration(seconds: 1));
      if (isRunning && !isPaused) _scheduleTrade();
      return;
    }

    // Calcular stake
    _calculateStake();

    // Executar trade
    _executeTrade();
  }

  bool _checkLimits() {
    if (sessionProfit <= -config.maxLoss) return false;

    if (config.targetProfit > 0 && sessionProfit >= config.targetProfit) {
      if (config.resetAfterProfit) {
        reset();
        return true;
      }
      return false;
    }

    if (consecutiveLosses >= config.maxConsecutiveLosses) return false;
    if (config.maxTrades > 0 && totalTrades >= config.maxTrades) return false;

    final maxStakeLimit = config.maxStake ?? double.infinity;
    if (currentStake > maxStakeLimit) return false;

    // Progressive: Verificar total de ciclos
    if (config.strategy == BotStrategy.progressiveReinvestment) {
      if (currentCycle >= config.totalCycles) return false;
    }

    return true;
  }

  Future<bool> _checkEntryConditions() async {
    for (var condition in config.entryConditions) {
      switch (condition) {
        case EntryCondition.immediate:
          continue;
        case EntryCondition.rsiOversold:
          if (currentRSI > 30) return false;
          break;
        case EntryCondition.rsiOverbought:
          if (currentRSI < 70) return false;
          break;
        case EntryCondition.macdCross:
          if (!BotAnalysis.detectMACDCross(currentMACD, previousMACD)) return false;
          break;
        case EntryCondition.bollingerBreak:
          if (!BotAnalysis.detectBollingerBreak(priceHistory)) return false;
          break;
        case EntryCondition.supportResistance:
          if (!BotAnalysis.detectSupportResistanceTouch(
              priceHistory, supportLevel, resistanceLevel)) return false;
          break;
        case EntryCondition.patternDetection:
          if (!BotAnalysis.detectPattern(priceHistory)) return false;
          break;
        case EntryCondition.priceAction:
          if (!BotAnalysis.detectPriceAction(priceHistory)) return false;
          break;
        case EntryCondition.volumeSpike:
          if (!BotAnalysis.detectVolumeSpike(priceHistory)) return false;
          break;
        case EntryCondition.trendConfirmation:
          if (!BotAnalysis.detectTrend(priceHistory)) return false;
          break;
        case EntryCondition.trendSequence:
          final trend = BotAnalysis.detectTrendSequence(
            priceHistory,
            config.trendFilter,
          );
          if (!trend['detected']) return false;
          break;
        case EntryCondition.winStreak:
          if (consecutiveWins < config.trendFilter) return false;
          break;
      }
    }
    return true;
  }

  void _calculateStake() {
    switch (config.strategy) {
      case BotStrategy.martingale:
        currentStake = BotStrategies.calculateMartingaleStake(
          config: config,
          consecutiveLosses: consecutiveLosses,
          lossStreakAmount: lossStreakAmount,
        );
        break;

      case BotStrategy.progressiveReinvestment:
        final lastWon = tradeHistory.isNotEmpty ? tradeHistory.last.won : false;
        final lastStake = tradeHistory.isNotEmpty ? tradeHistory.last.stake : config.initialStake;
        final lastProfit = tradeHistory.isNotEmpty ? tradeHistory.last.profit.abs() : 0.0;

        final result = BotStrategies.calculateProgressiveReinvestmentStake(
          config: config,
          currentCycle: currentCycle,
          currentRound: currentRound,
          cycleStartStake: cycleStartStake,
          totalLossesInCycle: cycleTotalLosses,
          lastTradeWon: lastWon,
          lastStake: lastStake,
          lastProfit: lastProfit,
        );

        currentStake = result['stake'];
        currentCycle = result['cycle'];
        currentRound = result['round'];
        cycleStartStake = result['cycleStartStake'];
        
        if (result['newCycle']) {
          cycleTotalLosses = 0.0;
        }
        break;

      case BotStrategy.trendyAdaptive:
        final lastProfit = tradeHistory.isNotEmpty ? tradeHistory.last.profit.abs() : 0.0;

        final result = BotStrategies.calculateTrendyAdaptiveStake(
          config: config,
          consecutiveWins: consecutiveWins,
          consecutiveLosses: consecutiveLosses,
          currentStake: currentStake,
          lastProfit: lastProfit,
          trendDetected: trendDetected,
          profitBank: profitBank,
          phase: trendPhase,
        );

        currentStake = result['stake'];
        trendDetected = result['trendDetected'];
        profitBank = result['profitBank'];
        trendPhase = result['phase'];
        break;

      case BotStrategy.adaptiveCompoundRecovery:
        final lastProfit = tradeHistory.isNotEmpty ? tradeHistory.last.profit.abs() : 0.0;

        // Atualizar last5Results com base no histórico de preços
        if (priceHistory.length >= 2) {
          final lastPrice = priceHistory.last;
          final prevPrice = priceHistory[priceHistory.length - 2];
          
          // Simplificado: Rise/Fall baseado no preço
          if (lastPrice > prevPrice) {
            last5Results.add('Rise');
          } else if (lastPrice < prevPrice) {
            last5Results.add('Fall');
          } else {
            last5Results.add('Equal');
          }
          
          // Manter apenas últimos 5
          if (last5Results.length > 5) {
            last5Results.removeAt(0);
          }
        }

        final result = BotStrategies.calculateACSRStake(
          config: config,
          consecutiveWins: consecutiveWins,
          consecutiveLosses: consecutiveLosses,
          currentStake: currentStake,
          lastProfit: lastProfit,
          lossAccumulated: acsrLossAccumulated,
          profitBank: acsrProfitBank,
          last5Results: last5Results,
        );

        currentStake = result['stake'];
        acsrProfitBank = result['profitBank'];
        activeDirection = result['activeDirection'];
        shouldPauseForAnalysis = result['shouldPause'];
        break;
    }

    // Limitar stake
    final minStake = max(config.initialStake, 0.35);
    final maxStake = config.maxStake ?? double.infinity;
    if (currentStake.isNaN || currentStake.isInfinite) currentStake = minStake;
    currentStake = currentStake.clamp(minStake, maxStake);
  }

  void _executeTrade() {
    lastTradeTime = DateTime.now();

    final payload = {
      'proposal': 1,
      'amount': currentStake,
      'basis': 'stake',
      'contract_type': config.contractType,
      'currency': 'USD',
      'duration': config.duration,
      'duration_unit': config.durationUnit,
      'symbol': config.market,
    };

    try {
      channel.sink.add(json.encode(payload));
    } catch (e) {
      print('Falha ao enviar proposta: $e');
    }

    onStatusUpdate(getStatus());
  }

  void handleProposalResponse(String proposalId) {
    try {
      channel.sink.add(json.encode({
        'buy': proposalId,
        'price': currentStake,
      }));
    } catch (e) {
      print('Falha ao enviar buy: $e');
    }
  }

  void handleBuyResponse(Map<String, dynamic> contract) {
    currentContractId = contract['contract_id'].toString();
    totalTrades++;

    try {
      channel.sink.add(json.encode({
        'proposal_open_contract': 1,
        'contract_id': currentContractId,
        'subscribe': 1,
      }));
    } catch (e) {
      print('Falha ao subscrever contract updates: $e');
    }

    onStatusUpdate(getStatus());
  }

  void handleContractUpdate(Map<String, dynamic> contract) {
    if (contract['contract_id'].toString() != currentContractId) return;

    final status = contract['status'];
    if (status == 'won' || status == 'lost') {
      _handleTradeResult(contract);
    }
  }

  void _handleTradeResult(Map<String, dynamic> contract) {
    final profit = double.tryParse(contract['profit']?.toString() ?? '0') ?? 0.0;
    final won = contract['status'] == 'won';
    final stakeUsed = double.tryParse(contract['stake']?.toString() ?? currentStake.toString()) ?? currentStake;

    totalProfit += profit;
    sessionProfit += profit;

    if (won) {
      wins++;
      consecutiveLosses = 0;
      consecutiveWins++;
      avgWin = ((avgWin * (wins - 1)) + profit) / max(wins, 1);

      lossStreakAmount = 0.0;
      acsrLossAccumulated = 0.0;
    } else {
      losses++;
      consecutiveWins = 0;
      consecutiveLosses++;
      final lossAmount = profit.abs();
      avgLoss = ((avgLoss * (losses - 1)) + lossAmount) / max(losses, 1);

      lossStreakAmount += stakeUsed;
      cycleTotalLosses += stakeUsed;
      acsrLossAccumulated += stakeUsed;
    }

    tradeHistory.add(TradeRecord(
      timestamp: DateTime.now(),
      stake: stakeUsed,
      profit: profit,
      won: won,
      market: config.market,
      rsi: currentRSI,
      cycleNumber: currentCycle,
      roundInCycle: currentRound,
    ));

    if (sessionProfit > peakProfit) peakProfit = sessionProfit;
    final currentDrawdown = (peakProfit - sessionProfit) / max(peakProfit, 1);
    if (currentDrawdown > maxDrawdown) maxDrawdown = currentDrawdown;

    currentContractId = null;
    onStatusUpdate(getStatus());

    if (isRunning && !isPaused) _scheduleTrade();
  }

  BotStatus getStatus() {
    return BotStatus(
      name: config.name,
      isRunning: isRunning,
      isPaused: isPaused,
      currentStake: currentStake,
      totalTrades: totalTrades,
      wins: wins,
      losses: losses,
      totalProfit: totalProfit,
      sessionProfit: sessionProfit,
      consecutiveWins: consecutiveWins,
      consecutiveLosses: consecutiveLosses,
      winRate: wins / max(totalTrades, 1),
      avgWin: avgWin,
      avgLoss: avgLoss,
      maxDrawdown: maxDrawdown,
      currentRSI: currentRSI,
      inRecoveryMode: false,
      recoveryTarget: 0,
      tradeHistory: tradeHistory,
      currentCycle: currentCycle,
      currentRound: currentRound,
      cycleProfit: sessionProfit,
      trendDetected: trendDetected,
      trendDirection: activeDirection,
    );
  }
}