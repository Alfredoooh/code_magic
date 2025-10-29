// bot_configuration.dart
import 'dart:async';

enum BotStrategy {
  martingale,
  progressiveReinvestment,  // Reinvestimento Progressivo com Recuperação Total
  trendyAdaptive,           // Lucro por Tendência com Ajuste Dinâmico
  adaptiveCompoundRecovery, // Adaptive Compound & Smart Recovery (ACS-R v3.0)
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
  trendSequence,        // Para Trendy
  winStreak,            // Para Progressive
}

enum ExitCondition {
  targetProfit,
  targetLoss,
  timeLimit,
  trailingStop,
  breakeven,
  reversalSignal,
  volatilitySpike,
  cycleComplete,        // Para Progressive
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

  RecoveryMode recoveryMode;
  List<EntryCondition> entryConditions;
  List<ExitCondition> exitConditions;

  double? maxStake;
  double maxLoss;
  double targetProfit;
  int maxConsecutiveLosses;
  int maxTrades;
  double estimatedPayout;

  Duration minTimeBetweenTrades;
  Duration maxTradeDuration;

  bool useRSI;
  bool useMACD;
  bool useBollinger;
  bool useSupportResistance;
  bool usePatternRecognition;

  double bankrollPercentage;
  bool compoundGains;
  bool resetAfterProfit;
  double resetProfitThreshold;

  bool useMLPredictions;
  double mlConfidenceThreshold;

  // ============================================
  // PARÂMETROS PARA PROGRESSIVE REINVESTMENT
  // ============================================
  int roundsPerCycle;           // N (número de rodadas por ciclo, ex: 3)
  int totalCycles;              // C (total de ciclos a executar, ex: 10)
  double extraProfitPercent;    // L% (lucro extra após recuperação, ex: 10%)
  bool autoRecovery;            // Ativa recuperação automática

  // ============================================
  // PARÂMETROS PARA TRENDY ADAPTIVE
  // ============================================
  double trendMultiplier;       // Mt (multiplicador de tendência, ex: 1.5)
  double recoveryMultiplier;    // Mr (multiplicador de recuperação, ex: 1.2)
  int trendFilter;              // F (vitórias consecutivas para confirmar, ex: 2)
  double profitReinvestPercent; // % do lucro a reinvestir (ex: 50%)

  // ============================================
  // PARÂMETROS PARA ACS-R v3.0
  // ============================================
  double consistencyMultiplier; // Mc (aumento após vitórias, ex: 1.15)
  int confidenceFilter;         // Vitórias necessárias para confirmar direção (ex: 2)
  double patternConfidence;     // Confiança mínima no padrão (ex: 0.6 = 60%)

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
    // Progressive Reinvestment
    this.roundsPerCycle = 3,
    this.totalCycles = 10,
    this.extraProfitPercent = 10.0,
    this.autoRecovery = true,
    // Trendy Adaptive
    this.trendMultiplier = 1.5,
    this.recoveryMultiplier = 1.2,
    this.trendFilter = 2,
    this.profitReinvestPercent = 50.0,
    // ACS-R v3.0
    this.consistencyMultiplier = 1.15,
    this.confidenceFilter = 2,
    this.patternConfidence = 0.6,
  }) : initialStake = (initialStake < 0.35 ? 0.35 : initialStake);
}

class TradeRecord {
  final DateTime timestamp;
  final double stake;
  final double profit;
  final bool won;
  final String market;
  final double rsi;
  final int cycleNumber;      // Para Progressive
  final int roundInCycle;     // Para Progressive

  TradeRecord({
    required this.timestamp,
    required this.stake,
    required this.profit,
    required this.won,
    required this.market,
    required this.rsi,
    this.cycleNumber = 0,
    this.roundInCycle = 0,
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

  // Extras para Progressive
  final int currentCycle;
  final int currentRound;
  final double cycleProfit;

  // Extras para Trendy
  final bool trendDetected;
  final String trendDirection;

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
    this.currentCycle = 0,
    this.currentRound = 0,
    this.cycleProfit = 0.0,
    this.trendDetected = false,
    this.trendDirection = 'neutral',
  });
}