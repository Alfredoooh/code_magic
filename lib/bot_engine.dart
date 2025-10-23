// bot_engine.dart
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
  double maxStake;
  double maxLoss;
  double targetProfit;
  int maxConsecutiveLosses;
  int maxTrades;
  
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
    required this.initialStake,
    required this.market,
    required this.contractType,
    this.duration = 5,
    this.durationUnit = 't',
    this.recoveryMode = RecoveryMode.moderate,
    this.entryConditions = const [EntryCondition.immediate],
    this.exitConditions = const [ExitCondition.targetProfit, ExitCondition.targetLoss],
    this.maxStake = 1000.0,
    this.maxLoss = 500.0,
    this.targetProfit = 100.0,
    this.maxConsecutiveLosses = 5,
    this.maxTrades = 100,
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
  });
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
  
  TradingBot({
    required this.config,
    required this.channel,
    required this.onStatusUpdate,
  }) : currentStake = config.initialStake;
  
  void start() {
    if (isRunning) return;
    
    isRunning = true;
    isPaused = false;
    startTime = DateTime.now();
    _resetStrategy();
    onStatusUpdate(_getStatus());
    _scheduleTrade();
  }
  
  void pause() {
    isPaused = true;
    onStatusUpdate(_getStatus());
  }
  
  void resume() {
    isPaused = false;
    onStatusUpdate(_getStatus());
    if (currentContractId == null) {
      _scheduleTrade();
    }
  }
  
  void stop() {
    isRunning = false;
    isPaused = false;
    currentContractId = null;
    onStatusUpdate(_getStatus());
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
    _resetStrategy();
    onStatusUpdate(_getStatus());
  }
  
  void _resetStrategy() {
    fibonacciIndex = 0;
    labouchereSequence = [1, 2, 3, 4];
    dalembertStep = 0;
    oscarGrindTarget = 1;
    paroliStreak = 0;
    recoveryTarget = 0.0;
    inRecoveryMode = false;
  }
  
  void updatePrice(double price) {
    priceHistory.add(price);
    if (priceHistory.length > 500) {
      priceHistory.removeAt(0);
    }
    
    if (priceHistory.length >= 14) {
      currentRSI = _calculateRSI();
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
      // Tentar novamente em 1 segundo
      await Future.delayed(const Duration(seconds: 1));
      _scheduleTrade();
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
    
    // Verificar stake máximo
    if (currentStake > config.maxStake) return false;
    
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
    
    // Limitar stake
    currentStake = currentStake.clamp(config.initialStake, config.maxStake);
  }
  
  void _calculateMartingaleStake() {
    if (consecutiveLosses > 0) {
      currentStake = config.initialStake * pow(2, consecutiveLosses).toDouble();
    } else {
      currentStake = config.initialStake;
    }
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
      currentStake = config.initialStake * 
        (labouchereSequence.first + labouchereSequence.last);
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
    
    if (avgLossAmount > 0) {
      final kelly = (winRate * avgWinAmount - (1 - winRate) * avgLossAmount) / avgWinAmount;
      final fraction = kelly * 0.25; // Quarter Kelly para segurança
      currentStake = (config.initialStake * 100) * fraction.clamp(0.01, 0.1);
    } else {
      currentStake = config.initialStake;
    }
  }
  
  void _calculatePinkhamStake() {
    // Sistema de recuperação gradual
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
    final balance = config.initialStake * 50; // Simular balance
    currentStake = balance * (config.bankrollPercentage / 100);
  }
  
  void _calculateCompoundStake() {
    if (config.compoundGains && sessionProfit > 0) {
      currentStake = config.initialStake * (1 + sessionProfit / 100);
    } else {
      currentStake = config.initialStake;
    }
  }
  
  void _calculateRecoveryStake() {
    if (sessionProfit < 0) {
      inRecoveryMode = true;
      recoveryTarget = sessionProfit.abs();
      
      // Calcular stake necessário para recuperar
      final payoutRatio = 0.95; // 95% de payout típico
      recoveryStake = recoveryTarget / payoutRatio;
      currentStake = recoveryStake;
    } else {
      inRecoveryMode = false;
      currentStake = config.initialStake;
    }
  }
  
  void _calculateAdaptiveStake() {
    // Ajustar baseado em performance recente
    final recentWinRate = _calculateRecentWinRate(20);
    
    if (recentWinRate > 0.6) {
      currentStake = config.initialStake * 1.5;
    } else if (recentWinRate < 0.4) {
      currentStake = config.initialStake * 0.75;
    } else {
      currentStake = config.initialStake;
    }
    
    // Ajustar por volatilidade
    final volatility = _calculateVolatility();
    if (volatility > 0.02) {
      currentStake *= 0.8; // Reduzir em alta volatilidade
    }
  }
  
  void _calculateMLStake() {
    // Usar predições de ML para ajustar stake
    // (Integração com MLPredictor seria necessária)
    currentStake = config.initialStake;
  }
  
  void _applyRecoveryMode() {
    switch (config.recoveryMode) {
      case RecoveryMode.none:
        break;
        
      case RecoveryMode.conservative:
        if (consecutiveLosses >= 2) {
          currentStake = config.initialStake * 1.5;
        }
        break;
        
      case RecoveryMode.moderate:
        if (consecutiveLosses >= 2) {
          currentStake = config.initialStake * pow(1.5, consecutiveLosses).toDouble();
        }
        break;
        
      case RecoveryMode.aggressive:
        if (consecutiveLosses >= 1) {
          currentStake = config.initialStake * pow(2, consecutiveLosses).toDouble();
        }
        break;
        
      case RecoveryMode.intelligent:
        if (sessionProfit < 0) {
          final lossAmount = sessionProfit.abs();
          final payoutRatio = 0.95;
          final neededWins = (lossAmount / (config.initialStake * payoutRatio)).ceil();
          currentStake = config.initialStake * (1 + (neededWins * 0.2));
        }
        break;
    }
  }
  
  void _executeTrade() {
    lastTradeTime = DateTime.now();
    
    channel.sink.add(json.encode({
      'proposal': 1,
      'amount': currentStake,
      'basis': 'stake',
      'contract_type': config.contractType,
      'currency': 'USD',
      'duration': config.duration,
      'duration_unit': config.durationUnit,
      'symbol': config.market,
    }));
    
    onStatusUpdate(_getStatus());
  }
  
  void handleProposalResponse(String proposalId) {
    channel.sink.add(json.encode({
      'buy': proposalId,
      'price': currentStake,
    }));
  }
  
  void handleBuyResponse(Map<String, dynamic> contract) {
    currentContractId = contract['contract_id'].toString();
    totalTrades++;
    
    // Subscrever para atualizações
    channel.sink.add(json.encode({
      'proposal_open_contract': 1,
      'contract_id': currentContractId,
      'subscribe': 1,
    }));
    
    onStatusUpdate(_getStatus());
  }
  
  void handleContractUpdate(Map<String, dynamic> contract) {
    if (contract['contract_id'].toString() != currentContractId) return;
    
    final status = contract['status'];
    if (status == 'won' || status == 'lost') {
      _handleTradeResult(contract);
    }
  }
  
  void _handleTradeResult(Map<String, dynamic> contract) {
    final profit = double.parse(contract['profit'].toString());
    final won = contract['status'] == 'won';
    
    totalProfit += profit;
    sessionProfit += profit;
    
    // Atualizar estatísticas
    if (won) {
      wins++;
      consecutiveLosses = 0;
      consecutiveWins++;
      avgWin = ((avgWin * (wins - 1)) + profit) / wins;
      
      // Atualizar estratégias específicas
      if (config.strategy == BotStrategy.labouchere && labouchereSequence.length > 1) {
        labouchereSequence.removeAt(0);
        labouchereSequence.removeAt(labouchereSequence.length - 1);
      }
      
      if (config.strategy == BotStrategy.oscarGrind) {
        oscarGrindTarget++;
      }
    } else {
      losses++;
      consecutiveWins = 0;
      consecutiveLosses++;
      avgLoss = ((avgLoss * (losses - 1)) + profit) / losses;
      
      // Atualizar estratégias específicas
      if (config.strategy == BotStrategy.labouchere) {
        labouchereSequence.add((labouchereSequence.last + 1).toInt());
      }
    }
    
    // Registrar trade
    tradeHistory.add(TradeRecord(
      timestamp: DateTime.now(),
      stake: currentStake,
      profit: profit,
      won: won,
      market: config.market,
      rsi: currentRSI,
    ));
    
    // Atualizar drawdown
    if (sessionProfit > peakProfit) {
      peakProfit = sessionProfit;
    }
    final currentDrawdown = (peakProfit - sessionProfit) / max(peakProfit, 1);
    if (currentDrawdown > maxDrawdown) {
      maxDrawdown = currentDrawdown;
    }
    
    // Verificar se saiu do modo de recuperação
    if (inRecoveryMode && sessionProfit >= 0) {
      inRecoveryMode = false;
      _resetStrategy();
    }
    
    currentContractId = null;
    onStatusUpdate(_getStatus());
    
    // Agendar próximo trade
    if (isRunning && !isPaused) {
      _scheduleTrade();
    }
  }
  
  double _calculateRSI() {
    if (priceHistory.length < 14) return 50.0;
    
    double gains = 0, losses = 0;
    for (int i = priceHistory.length - 14; i < priceHistory.length; i++) {
      double change = priceHistory[i] - priceHistory[i - 1];
      if (change > 0) gains += change;
      else losses -= change;
    }
    
    double avgGain = gains / 14;
    double avgLoss = losses / 14;
    
    if (avgLoss == 0) return 100.0;
    double rs = avgGain / avgLoss;
    return 100.0 - (100.0 / (1.0 + rs));
  }
  
  void _updateSupportResistance() {
    final recent = priceHistory.sublist(max(0, priceHistory.length - 50));
    
    List<double> localMins = [];
    List<double> localMaxs = [];
    
    for (int i = 2; i < recent.length - 2; i++) {
      if (recent[i] < recent[i - 1] && recent[i] < recent[i + 1]) {
        localMins.add(recent[i]);
      }
      if (recent[i] > recent[i - 1] && recent[i] > recent[i + 1]) {
        localMaxs.add(recent[i]);
      }
    }
    
    if (localMins.isNotEmpty) supportLevel = localMins.reduce(max);
    if (localMaxs.isNotEmpty) resistanceLevel = localMaxs.reduce(min);
  }
  
  bool _detectMACDCross() {
    // Implementação simplificada
    return Random().nextDouble() > 0.5;
  }
  
  bool _detectBollingerBreak() {
    if (priceHistory.length < 20) return false;
    
    final recent = priceHistory.sublist(priceHistory.length - 20);
    final sma = recent.reduce((a, b) => a + b) / 20;
    final variance = recent.map((p) => pow(p - sma, 2)).reduce((a, b) => a + b) / 20;
    final stdDev = sqrt(variance);
    
    final upperBand = sma + (2 * stdDev);
    final lowerBand = sma - (2 * stdDev);
    final current = priceHistory.last;
    
    return current > upperBand || current < lowerBand;
  }
  
  bool _detectSupportResistanceTouch() {
    if (supportLevel == 0 || resistanceLevel == 0) return false;
    
    final current = priceHistory.last;
    final threshold = current * 0.001; // 0.1% threshold
    
    return (current - supportLevel).abs() < threshold ||
           (current - resistanceLevel).abs() < threshold;
  }
  
  bool _detectPattern() {
    // Implementação simplificada de detecção de padrões
    return Random().nextDouble() > 0.7;
  }
  
  bool _detectPriceAction() {
    if (priceHistory.length < 5) return false;
    
    final recent = priceHistory.sublist(priceHistory.length - 5);
    int bullish = 0;
    
    for (int i = 1; i < recent.length; i++) {
      if (recent[i] > recent[i - 1]) bullish++;
    }
    
    return bullish >= 3 || bullish <= 1; // Forte tendência em qualquer direção
  }
  
  bool _detectVolumeSpike() {
    // Implementação simplificada
    return Random().nextDouble() > 0.8;
  }
  
  bool _detectTrend() {
    if (priceHistory.length < 20) return false;
    
    final recent = priceHistory.sublist(priceHistory.length - 20);
    final sma = recent.reduce((a, b) => a + b) / 20;
    final current = priceHistory.last;
    
    return (current - sma).abs() / sma > 0.005; // Tendência de 0.5%
  }
  
  double _calculateRecentWinRate(int trades) {
    if (tradeHistory.length < trades) {
      return wins / max(totalTrades, 1);
    }
    
    final recent = tradeHistory.sublist(tradeHistory.length - trades);
    final recentWins = recent.where((t) => t.won).length;
    return recentWins / trades;
  }
  
  double _calculateVolatility() {
    if (priceHistory.length < 20) return 0.0;
    
    final recent = priceHistory.sublist(priceHistory.length - 20);
    final mean = recent.reduce((a, b) => a + b) / 20;
    final variance = recent.map((p) => pow(p - mean, 2)).reduce((a, b) => a + b) / 20;
    return sqrt(variance) / mean;
  }
  
  BotStatus _getStatus() {
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