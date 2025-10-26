// bot_engine.dart (corrigido e melhorado)
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:web_socket_channel/web_socket_channel.dart';

enum BotStrategy {
  martingale,
  fibonacci,
  dalembert,
  labouchere,
  oscarGrind,
  paroli,
  antiMartingale,
  kellyFraction,
  pinkham,
  oneThreeTwoSix,
  percentage,
  compound,
  recovery,
  adaptive,
  mlBased,
}

enum RecoveryMode {
  none,
  conservative,
  moderate,
  aggressive,
  intelligent,
}

enum EntryCondition {
  immediate,
  rsiOversold,
  rsiOverbought,
  macdCross,
  bollingerBreak,
  supportResistance,
  patternDetection,
  priceAction,
  volumeSpike,
  trendConfirmation,
}

enum ExitCondition {
  targetProfit,
  targetLoss,
  timeLimit,
  trailingStop,
  breakeven,
  reversalSignal,
  volatilitySpike,
}

class BotConfiguration {
  String name;
  String description;
  BotStrategy strategy;

  /// Stake inicial mínimo do sistema é 0.35 — forçado no construtor/uso.
  double initialStake;

  String market;
  String contractType;
  int duration;
  String durationUnit;

  // Configurações avançadas
  RecoveryMode recoveryMode;
  List<EntryCondition> entryConditions;
  List<ExitCondition> exitConditions;

  // Limites de risco
  /// maxStake é opcional: se null, não há limite imposto pelo config
  double? maxStake;
  double maxLoss;
  double targetProfit;
  int maxConsecutiveLosses;
  int maxTrades;

  // Estimativa de payout (por exemplo 0.95 = 95% do stake como retorno líquido)
  /// Muito importante para martingale correto quando payout != 1.0
  double estimatedPayout;

  // Configurações de temporização
  Duration minTimeBetweenTrades;
  Duration maxTradeDuration;

  // Análise técnica
  bool useRSI;
  bool useMACD;
  bool useBollinger;
  bool useSupportResistance;
  bool usePatternRecognition;

  // Gestão de banca
  double bankrollPercentage;
  bool compoundGains;
  bool resetAfterProfit;
  double resetProfitThreshold;

  // ML e IA
  bool useMLPredictions;
  double mlConfidenceThreshold;

  BotConfiguration({
    required this.name,
    required this.description,
    required this.strategy,
    required double initialStake,
    required this.market,
    required this.contractType,
    this.duration = 5,
    this.durationUnit = 't',
    this.recoveryMode = RecoveryMode.moderate,
    this.entryConditions = const [EntryCondition.immediate],
    this.exitConditions = const [ExitCondition.targetProfit, ExitCondition.targetLoss],
    this.maxStake,
    this.maxLoss = 500.0,
    this.targetProfit = 100.0,
    this.maxConsecutiveLosses = 5,
    this.maxTrades = 100,
    this.estimatedPayout = 0.95,
    this.minTimeBetweenTrades = const Duration(seconds: 2),
    this.maxTradeDuration = const Duration(minutes: 5),
    this.useRSI = true,
    this.useMACD = false,
    this.useBollinger = false,
    this.useSupportResistance = false,
    this.usePatternRecognition = false,
    this.bankrollPercentage = 2.0,
    this.compoundGains = true,
    this.resetAfterProfit = false,
    this.resetProfitThreshold = 50.0,
    this.useMLPredictions = false,
    this.mlConfidenceThreshold = 0.7,
  }) : initialStake = (initialStake < 0.35 ? 0.35 : initialStake);
}

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

  // Estratégia específica
  List<int> fibonacciSequence = [1, 1, 2, 3, 5, 8, 13, 21, 34, 55];
  int fibonacciIndex = 0;
  List<double> labouchereSequence = [1, 2, 3, 4];
  double dalembertUnit = 10.0;
  int dalembertStep = 0;
  double oscarGrindUnit = 10.0;
  int oscarGrindTarget = 1;
  int paroliStreak = 0;

  // Recuperação
  double recoveryTarget = 0.0;
  double recoveryStake = 0.0;
  bool inRecoveryMode = false;

  // Performance tracking
  List<TradeRecord> tradeHistory = [];
  double maxDrawdown = 0.0;
  double peakProfit = 0.0;
  double avgWin = 0.0;
  double avgLoss = 0.0;
  double sharpeRatio = 0.0;

  // Soma das stakes perdidas na sequência atual (usada pelo Martingale realista)
  double lossStreakAmount = 0.0;

  TradingBot({
    required this.config,
    required this.channel,
    required this.onStatusUpdate,
  }) : currentStake = (config.initialStake < 0.35 ? 0.35 : config.initialStake);

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
    lossStreakAmount = 0.0;
    _resetStrategy();
    onStatusUpdate(getStatus());
  }

  void _resetStrategy() {
    fibonacciIndex = 0;
    labouchereSequence = [1, 2, 3, 4];
    dalembertStep = 0;
    oscarGrindTarget = 1;
    paroliStreak = 0;
    recoveryTarget = 0.0;
    inRecoveryMode = false;
    lossStreakAmount = 0.0;
  }

  void updatePrice(double price) {
    priceHistory.add(price);
    if (priceHistory.length > 1000) {
      priceHistory.removeAt(0);
    }

    if (priceHistory.length >= 14) {
      currentRSI = _calculateRSI();
      rsiValues.add(currentRSI);
      if (rsiValues.length > 500) rsiValues.removeAt(0);
    }

    if (priceHistory.length >= 26) {
      final ema12 = _calculateEMA(priceHistory, 12);
      final ema26 = _calculateEMA(priceHistory, 26);
      previousMACD = currentMACD;
      currentMACD = ema12 - ema26;
    }

    if (priceHistory.length >= 50) {
      _updateSupportResistance();
    }
  }

  Future<void> _scheduleTrade() async {
    if (!isRunning || isPaused || currentContractId != null) return;

    // Verificar tempo mínimo entre trades
    if (lastTradeTime != null) {
      final timeSinceLast = DateTime.now().difference(lastTradeTime!);
      if (timeSinceLast < config.minTimeBetweenTrades) {
        await Future.delayed(config.minTimeBetweenTrades - timeSinceLast);
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
    // Verificar perda máxima
    if (sessionProfit <= -config.maxLoss) return false;

    // Verificar lucro alvo
    if (config.targetProfit > 0 && sessionProfit >= config.targetProfit) {
      if (config.resetAfterProfit) {
        reset();
        return true;
      }
      return false;
    }

    // Verificar perdas consecutivas
    if (consecutiveLosses >= config.maxConsecutiveLosses) return false;

    // Verificar número máximo de trades
    if (config.maxTrades > 0 && totalTrades >= config.maxTrades) return false;

    // Verificar stake máximo (quando definido)
    final maxStakeLimit = config.maxStake ?? double.infinity;
    if (currentStake > maxStakeLimit) return false;

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
          if (!_detectMACDCross()) return false;
          break;
        case EntryCondition.bollingerBreak:
          if (!_detectBollingerBreak()) return false;
          break;
        case EntryCondition.supportResistance:
          if (!_detectSupportResistanceTouch()) return false;
          break;
        case EntryCondition.patternDetection:
          if (!_detectPattern()) return false;
          break;
        case EntryCondition.priceAction:
          if (!_detectPriceAction()) return false;
          break;
        case EntryCondition.volumeSpike:
          if (!_detectVolumeSpike()) return false;
          break;
        case EntryCondition.trendConfirmation:
          if (!_detectTrend()) return false;
          break;
      }
    }
    return true;
  }

  void _calculateStake() {
    switch (config.strategy) {
      case BotStrategy.martingale:
        _calculateMartingaleStake();
        break;
      case BotStrategy.fibonacci:
        _calculateFibonacciStake();
        break;
      case BotStrategy.dalembert:
        _calculateDalembertStake();
        break;
      case BotStrategy.labouchere:
        _calculateLabouchereStake();
        break;
      case BotStrategy.oscarGrind:
        _calculateOscarGrindStake();
        break;
      case BotStrategy.paroli:
        _calculateParoliStake();
        break;
      case BotStrategy.antiMartingale:
        _calculateAntiMartingaleStake();
        break;
      case BotStrategy.kellyFraction:
        _calculateKellyStake();
        break;
      case BotStrategy.pinkham:
        _calculatePinkhamStake();
        break;
      case BotStrategy.oneThreeTwoSix:
        _calculateOneThreeTwoSixStake();
        break;
      case BotStrategy.percentage:
        _calculatePercentageStake();
        break;
      case BotStrategy.compound:
        _calculateCompoundStake();
        break;
      case BotStrategy.recovery:
        _calculateRecoveryStake();
        break;
      case BotStrategy.adaptive:
        _calculateAdaptiveStake();
        break;
      case BotStrategy.mlBased:
        _calculateMLStake();
        break;
    }

    // Aplicar modo de recuperação
    if (inRecoveryMode) {
      _applyRecoveryMode();
    }

    // Limitar stake entre initialStake e maxStake (quando definido)
    final minStake = max(config.initialStake, 0.35);
    final maxStake = config.maxStake ?? double.infinity;
    if (currentStake.isNaN || currentStake.isInfinite) currentStake = minStake;
    currentStake = currentStake.clamp(minStake, maxStake);
  }

  /// Martingale realista: em vez de simplesmente dobrar, calcula a stake necessária
  /// para recuperar a soma das perdas da sequência atual (lossStreakAmount) e
  /// ainda obter um lucro alvo (aqui usamos config.initialStake como lucro alvo),
  /// levando em conta o payout estimado (ex: 0.95 para 95%).
  void _calculateMartingaleStake() {
    final payout = config.estimatedPayout;
    final minStake = max(config.initialStake, 0.35);

    if (consecutiveLosses == 0) {
      currentStake = minStake;
      lossStreakAmount = 0.0;
      return;
    }

    // Desejamos recuperar as perdas acumuladas e ainda ter um lucro alvo (initialStake)
    final desiredProfit = config.initialStake;

    // Fórmula: stake * payout >= lossStreakAmount + desiredProfit
    // stake >= (lossStreakAmount + desiredProfit) / payout
    final required = (lossStreakAmount + desiredProfit) / max(0.0001, payout);

    // Para evitar saltos brutais, também podemos limitar crescimento (ex: factor cap)
    // Aqui permitimos o required, mas não ultrapassamos maxStake (aplicado depois).
    currentStake = max(minStake, required);
  }

  void _calculateFibonacciStake() {
    if (consecutiveLosses > 0) {
      fibonacciIndex = min(fibonacciIndex + 1, fibonacciSequence.length - 1);
    } else {
      fibonacciIndex = max(fibonacciIndex - 1, 0);
    }
    currentStake = config.initialStake * fibonacciSequence[fibonacciIndex];
  }

  void _calculateDalembertStake() {
    if (consecutiveLosses > 0) {
      dalembertStep++;
    } else if (consecutiveWins > 0 && dalembertStep > 0) {
      dalembertStep--;
    }
    currentStake = dalembertUnit + (dalembertStep * dalembertUnit);
  }

  void _calculateLabouchereStake() {
    if (labouchereSequence.isEmpty) {
      labouchereSequence = [1, 2, 3, 4];
    }

    if (labouchereSequence.length == 1) {
      currentStake = config.initialStake * labouchereSequence[0];
    } else {
      currentStake = config.initialStake * (labouchereSequence.first + labouchereSequence.last);
    }
  }

  void _calculateOscarGrindStake() {
    if (consecutiveWins > 0) {
      currentStake = oscarGrindUnit * oscarGrindTarget;
    } else {
      currentStake = oscarGrindUnit;
    }
  }

  void _calculateParoliStake() {
    if (consecutiveWins > 0 && consecutiveWins < 3) {
      currentStake = config.initialStake * pow(2, consecutiveWins).toDouble();
    } else {
      currentStake = config.initialStake;
      paroliStreak = 0;
    }
  }

  void _calculateAntiMartingaleStake() {
    if (consecutiveWins > 0) {
      currentStake = config.initialStake * pow(2, consecutiveWins).toDouble();
    } else {
      currentStake = config.initialStake;
    }
  }

  void _calculateKellyStake() {
    final winRate = wins / max(totalTrades, 1);
    final avgWinAmount = avgWin;
    final avgLossAmount = avgLoss.abs();

    if (avgWinAmount > 0 && avgLossAmount > 0) {
      final kelly = (winRate * avgWinAmount - (1 - winRate) * avgLossAmount) / avgWinAmount;
      final fraction = (kelly * 0.25).clamp(0.01, 0.5); // Quarter Kelly
      currentStake = (config.initialStake) * fraction;
    } else {
      currentStake = config.initialStake;
    }
  }

  void _calculatePinkhamStake() {
    if (sessionProfit < 0) {
      final lossAmount = sessionProfit.abs();
      currentStake = config.initialStake + (lossAmount * 0.1);
    } else {
      currentStake = config.initialStake;
    }
  }

  void _calculateOneThreeTwoSixStake() {
    final sequence = [1, 3, 2, 6];
    final index = consecutiveWins % 4;
    currentStake = config.initialStake * sequence[index];
  }

  void _calculatePercentageStake() {
    currentStake = max(0.01, config.initialStake * (config.bankrollPercentage / 100));
  }

  void _calculateCompoundStake() {
    if (config.compoundGains && sessionProfit > 0) {
      final factor = 1 + (sessionProfit / max(config.initialStake, 1)) * 0.01;
      currentStake = config.initialStake * factor;
    } else {
      currentStake = config.initialStake;
    }
  }

  void _calculateRecoveryStake() {
    if (sessionProfit < 0) {
      inRecoveryMode = true;
      recoveryTarget = sessionProfit.abs();
      final payoutRatio = config.estimatedPayout;
      recoveryStake = (recoveryTarget / max(0.01, payoutRatio)).clamp(config.initialStake, config.maxStake ?? double.infinity);
      currentStake = recoveryStake;
    } else {
      inRecoveryMode = false;
      currentStake = config.initialStake;
    }
  }

  void _calculateAdaptiveStake() {
    final recentWinRate = _calculateRecentWinRate(20);
    if (recentWinRate > 0.6) {
      currentStake = config.initialStake * 1.5;
    } else if (recentWinRate < 0.4) {
      currentStake = config.initialStake * 0.75;
    } else {
      currentStake = config.initialStake;
    }
    final volatility = _calculateVolatility();
    if (volatility > 0.02) currentStake *= 0.8;
  }

  void _calculateMLStake() {
    currentStake = config.initialStake;
  }

  void _applyRecoveryMode() {
    switch (config.recoveryMode) {
      case RecoveryMode.none:
        break;
      case RecoveryMode.conservative:
        if (consecutiveLosses >= 2) currentStake = config.initialStake * 1.5;
        break;
      case RecoveryMode.moderate:
        if (consecutiveLosses >= 2) currentStake = config.initialStake * pow(1.5, consecutiveLosses).toDouble();
        break;
      case RecoveryMode.aggressive:
        if (consecutiveLosses >= 1) currentStake = config.initialStake * pow(2, consecutiveLosses).toDouble();
        break;
      case RecoveryMode.intelligent:
        if (sessionProfit < 0) {
          final lossAmount = sessionProfit.abs();
          final payoutRatio = config.estimatedPayout;
          final neededWins = (lossAmount / (config.initialStake * payoutRatio)).ceil();
          currentStake = config.initialStake * (1 + (neededWins * 0.2));
        }
        break;
    }
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
      // Falha em enviar: registar e prosseguir
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
    // contract['profit'] pode estar no payload — alguns sistemas retornam profit líquido
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

      // quando ganha, zera lossStreakAmount
      lossStreakAmount = 0.0;

      if (config.strategy == BotStrategy.labouchere && labouchereSequence.length > 1) {
        if (labouchereSequence.length >= 2) {
          labouchereSequence.removeAt(0);
          if (labouchereSequence.isNotEmpty) labouchereSequence.removeLast();
        }
      }
      if (config.strategy == BotStrategy.oscarGrind) oscarGrindTarget++;
    } else {
      losses++;
      consecutiveWins = 0;
      consecutiveLosses++;
      // profit aqui pode ser negativo (ou zero) — calcular perda real
      final lossAmount = -profit; // se profit = -stake então lossAmount = stake
      avgLoss = ((avgLoss * (losses - 1)) + lossAmount) / max(losses, 1);

      // acumular perda na sequência para martingale
      lossStreakAmount += stakeUsed;

      if (config.strategy == BotStrategy.labouchere) {
        final last = labouchereSequence.isNotEmpty ? labouchereSequence.last : 1.0;
        labouchereSequence.add((last + 1).toDouble());
      }
    }

    tradeHistory.add(TradeRecord(
      timestamp: DateTime.now(),
      stake: stakeUsed,
      profit: profit,
      won: won,
      market: config.market,
      rsi: currentRSI,
    ));

    if (sessionProfit > peakProfit) peakProfit = sessionProfit;
    final currentDrawdown = (peakProfit - sessionProfit) / max(peakProfit, 1);
    if (currentDrawdown > maxDrawdown) maxDrawdown = currentDrawdown;

    if (inRecoveryMode && sessionProfit >= 0) {
      inRecoveryMode = false;
      _resetStrategy();
    }

    currentContractId = null;
    onStatusUpdate(getStatus());

    if (isRunning && !isPaused) _scheduleTrade();
  }

  double _calculateRSI() {
    if (priceHistory.length < 15) return 50.0;
    double gains = 0.0, lossesLocal = 0.0;
    for (int i = priceHistory.length - 14; i < priceHistory.length; i++) {
      final change = priceHistory[i] - priceHistory[i - 1];
      if (change > 0) gains += change;
      else lossesLocal += -change;
    }
    final avgGain = gains / 14;
    final avgLoss = lossesLocal / 14;
    if (avgGain == 0 && avgLoss == 0) return 50.0;
    if (avgLoss == 0) return 100.0;
    final rs = avgGain / avgLoss;
    final rsi = 100.0 - (100.0 / (1.0 + rs));
    return rsi.clamp(0.0, 100.0);
  }

  void _updateSupportResistance() {
    final recent = priceHistory.sublist(max(0, priceHistory.length - 50));
    List<double> localMins = [];
    List<double> localMaxs = [];
    for (int i = 2; i < recent.length - 2; i++) {
      if (recent[i] < recent[i - 1] && recent[i] < recent[i + 1]) localMins.add(recent[i]);
      if (recent[i] > recent[i - 1] && recent[i] > recent[i + 1]) localMaxs.add(recent[i]);
    }
    if (localMins.isNotEmpty) supportLevel = localMins.reduce(min);
    if (localMaxs.isNotEmpty) resistanceLevel = localMaxs.reduce(max);
  }

  bool _detectMACDCross() {
    if (priceHistory.length < 27) return false;
    final macdNow = currentMACD;
    final macdPrev = previousMACD;
    if (macdPrev < 0 && macdNow >= 0) return true;
    return false;
  }

  bool _detectBollingerBreak() {
    if (priceHistory.length < 20) return false;
    final recent = priceHistory.sublist(priceHistory.length - 20);
    final sma = recent.reduce((a, b) => a + b) / recent.length;
    final variance = recent.map((p) => pow(p - sma, 2)).reduce((a, b) => a + b) / recent.length;
    final stdDev = sqrt(max(variance, 0.0));
    final upperBand = sma + (2 * stdDev);
    final lowerBand = sma - (2 * stdDev);
    final current = priceHistory.last;
    return current > upperBand || current < lowerBand;
  }

  bool _detectSupportResistanceTouch() {
    if (supportLevel == 0 || resistanceLevel == 0) return false;
    final current = priceHistory.last;
    final threshold = current * 0.0015;
    return (current - supportLevel).abs() < threshold || (current - resistanceLevel).abs() < threshold;
  }

  bool _detectPattern() {
    if (priceHistory.length < 30) return false;
    final recent = priceHistory.sublist(priceHistory.length - 30);
    final peaks = <double>[];
    final bottoms = <double>[];
    for (int i = 1; i < recent.length - 1; i++) {
      if (recent[i] > recent[i - 1] && recent[i] > recent[i + 1]) peaks.add(recent[i]);
      if (recent[i] < recent[i - 1] && recent[i] < recent[i + 1]) bottoms.add(recent[i]);
    }
    if (peaks.length >= 2) {
      final last = peaks.last;
      final prev = peaks[peaks.length - 2];
      if ((last - prev).abs() / max(prev, 1) < 0.02) return true;
    }
    if (bottoms.length >= 2) {
      final lastB = bottoms.last;
      final prevB = bottoms[bottoms.length - 2];
      if ((lastB - prevB).abs() / max(prevB, 1) < 0.02) return true;
    }
    return false;
  }

  bool _detectPriceAction() {
    if (priceHistory.length < 5) return false;
    final recent = priceHistory.sublist(priceHistory.length - 5);
    int bullish = 0, bearish = 0;
    for (int i = 1; i < recent.length; i++) {
      if (recent[i] > recent[i - 1]) bullish++;
      else if (recent[i] < recent[i - 1]) bearish++;
    }
    return bullish >= 4 || bearish >= 4;
  }

  bool _detectVolumeSpike() {
    if (priceHistory.length < 10) return false;
    final recent = priceHistory.sublist(priceHistory.length - 10);
    double mean = recent.reduce((a, b) => a + b) / recent.length;
    final last = recent.last;
    final percent = ((last - mean).abs() / max(mean, 1));
    return percent > 0.015;
  }

  bool _detectTrend() {
    if (priceHistory.length < 20) return false;
    final recent = priceHistory.sublist(priceHistory.length - 20);
    final sma = recent.reduce((a, b) => a + b) / recent.length;
    final current = priceHistory.last;
    return (current - sma).abs() / sma > 0.005;
  }

  double _calculateRecentWinRate(int trades) {
    if (tradeHistory.isEmpty) {
      return wins / max(totalTrades, 1);
    }
    final take = min(trades, tradeHistory.length);
    final recent = tradeHistory.sublist(tradeHistory.length - take);
    final recentWins = recent.where((t) => t.won).length;
    return recentWins / max(take, 1);
  }

  double _calculateVolatility() {
    if (priceHistory.length < 20) return 0.0;
    final recent = priceHistory.sublist(priceHistory.length - 20);
    final mean = recent.reduce((a, b) => a + b) / recent.length;
    final variance = recent.map((p) => pow(p - mean, 2)).reduce((a, b) => a + b) / recent.length;
    return sqrt(max(variance, 0.0)) / max(mean, 1);
  }

  /// Tornado público conforme solicitado pelo seu comentário.
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
      inRecoveryMode: inRecoveryMode,
      recoveryTarget: recoveryTarget,
      tradeHistory: tradeHistory,
    );
  }

  // Helper: EMA (usado para MACD)
  double _calculateEMA(List<double> prices, int period) {
    if (prices.length < period) return prices.last;
    final multiplier = 2.0 / (period + 1);
    double ema = prices[prices.length - period];
    for (int i = prices.length - period + 1; i < prices.length; i++) {
      ema = (prices[i] - ema) * multiplier + ema;
    }
    return ema;
  }
}

class TradeRecord {
  final DateTime timestamp;
  final double stake;
  final double profit;
  final bool won;
  final String market;
  final double rsi;

  TradeRecord({
    required this.timestamp,
    required this.stake,
    required this.profit,
    required this.won,
    required this.market,
    required this.rsi,
  });
}

class BotStatus {
  final String name;
  final bool isRunning;
  final bool isPaused;
  final double currentStake;
  final int totalTrades;
  final int wins;
  final int losses;
  final double totalProfit;
  final double sessionProfit;
  final int consecutiveWins;
  final int consecutiveLosses;
  final double winRate;
  final double avgWin;
  final double avgLoss;
  final double maxDrawdown;
  final double currentRSI;
  final bool inRecoveryMode;
  final double recoveryTarget;
  final List<TradeRecord> tradeHistory;

  BotStatus({
    required this.name,
    required this.isRunning,
    required this.isPaused,
    required this.currentStake,
    required this.totalTrades,
    required this.wins,
    required this.losses,
    required this.totalProfit,
    required this.sessionProfit,
    required this.consecutiveWins,
    required this.consecutiveLosses,
    required this.winRate,
    required this.avgWin,
    required this.avgLoss,
    required this.maxDrawdown,
    required this.currentRSI,
    required this.inRecoveryMode,
    required this.recoveryTarget,
    required this.tradeHistory,
  });
}