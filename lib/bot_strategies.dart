class BotConfig {
  // Básico
  double initialStake = 0.35;
  double maxStake = 100.0;
  double stopLoss = 50.0;
  double takeProfit = 100.0;
  
  // Recuperação de Perdas
  bool lossRecoveryEnabled = true;
  String lossRecoveryMode = 'with_profit'; // zero_profit, with_profit, aggressive
  double lossRecoveryMultiplier = 2.0;
  double lossRecoveryProfit = 20.0; // % de lucro desejado na recuperação
  
  // Acumulação Avançada
  bool accumulationEnabled = false;
  int maxAccumulations = 5;
  double accumulationProfitPercent = 50.0;
  bool tradeWithAccumulatedProfit = true;
  bool autoReinvest = false;
  
  // Auto Trade
  bool autoTradeEnabled = false;
  String autoTradeTrigger = 'fall_1min'; // fall_1min, rise_1min, volatility_spike, price_level
  String autoTradeDirection = 'opposite'; // opposite, same, smart
  double autoTradeThreshold = 0.5; // % de mudança para trigger
  int autoTradeAnalysisPeriod = 60; // segundos
  
  // Martingale
  bool martingaleEnabled = false;
  double martingaleMultiplier = 2.0;
  int martingaleMaxLevels = 5;
  bool martingaleResetOnWin = true;
  
  // Análise
  int analysisTickPeriod = 100;
  bool useTrendAnalysis = true;
  bool useVolatilityAnalysis = true;
  bool useDigitPatterns = false;
  
  // Segurança
  int maxTradesPerDay = 100;
  int maxConsecutiveLosses = 5;
  bool stopOnDrawdown = true;
  double maxDrawdownPercent = 20.0;
  
  BotConfig copy() {
    return BotConfig()
      ..initialStake = initialStake
      ..maxStake = maxStake
      ..stopLoss = stopLoss
      ..takeProfit = takeProfit
      ..lossRecoveryEnabled = lossRecoveryEnabled
      ..lossRecoveryMode = lossRecoveryMode
      ..lossRecoveryMultiplier = lossRecoveryMultiplier
      ..lossRecoveryProfit = lossRecoveryProfit
      ..accumulationEnabled = accumulationEnabled
      ..maxAccumulations = maxAccumulations
      ..accumulationProfitPercent = accumulationProfitPercent
      ..tradeWithAccumulatedProfit = tradeWithAccumulatedProfit
      ..autoReinvest = autoReinvest
      ..autoTradeEnabled = autoTradeEnabled
      ..autoTradeTrigger = autoTradeTrigger
      ..autoTradeDirection = autoTradeDirection
      ..autoTradeThreshold = autoTradeThreshold
      ..autoTradeAnalysisPeriod = autoTradeAnalysisPeriod
      ..martingaleEnabled = martingaleEnabled
      ..martingaleMultiplier = martingaleMultiplier
      ..martingaleMaxLevels = martingaleMaxLevels
      ..martingaleResetOnWin = martingaleResetOnWin
      ..analysisTickPeriod = analysisTickPeriod
      ..useTrendAnalysis = useTrendAnalysis
      ..useVolatilityAnalysis = useVolatilityAnalysis
      ..useDigitPatterns = useDigitPatterns
      ..maxTradesPerDay = maxTradesPerDay
      ..maxConsecutiveLosses = maxConsecutiveLosses
      ..stopOnDrawdown = stopOnDrawdown
      ..maxDrawdownPercent = maxDrawdownPercent;
  }
}

class TradeResult {
  final DateTime timestamp;
  final String market;
  final String direction; // CALL, PUT
  final double stake;
  final double payout;
  final double profit;
  final bool won;
  final String strategy;
  final int accumulationLevel;
  final bool wasRecovery;
  
  TradeResult({
    required this.timestamp,
    required this.market,
    required this.direction,
    required this.stake,
    required this.payout,
    required this.profit,
    required this.won,
    required this.strategy,
    this.accumulationLevel = 0,
    this.wasRecovery = false,
  });
}

class MarketAnalysis {
  final List<double> prices;
  final List<int> digits;
  
  MarketAnalysis(this.prices, this.digits);
  
  // Análise de Tendência
  String getTrend() {
    if (prices.length < 10) return 'neutral';
    
    final recent = prices.sublist(prices.length - 10);
    final avg = recent.reduce((a, b) => a + b) / recent.length;
    final last = recent.last;
    
    if (last > avg * 1.005) return 'bullish';
    if (last < avg * 0.995) return 'bearish';
    return 'neutral';
  }
  
  // Volatilidade
  double getVolatility() {
    if (prices.length < 20) return 0.0;
    
    final recent = prices.sublist(prices.length - 20);
    final avg = recent.reduce((a, b) => a + b) / recent.length;
    final variance = recent.map((p) => (p - avg) * (p - avg)).reduce((a, b) => a + b) / recent.length;
    return variance;
  }
  
  // Padrão de Dígitos
  Map<int, int> getDigitFrequency() {
    final freq = <int, int>{};
    for (var i = 0; i < 10; i++) freq[i] = 0;
    for (var digit in digits) freq[digit] = (freq[digit] ?? 0) + 1;
    return freq;
  }
  
  // Detectar Spike
  bool detectSpike(double threshold) {
    if (prices.length < 5) return false;
    
    final last5 = prices.sublist(prices.length - 5);
    final maxChange = last5.map((p) => (p - last5.first).abs() / last5.first).reduce((a, b) => a > b ? a : b);
    return maxChange > threshold;
  }
  
  // Próxima direção sugerida
  String suggestDirection() {
    final trend = getTrend();
    final volatility = getVolatility();
    
    if (volatility > 0.001) {
      return trend == 'bullish' ? 'CALL' : 'PUT';
    }
    
    if (prices.length >= 3) {
      final isRising = prices.last > prices[prices.length - 2] && prices[prices.length - 2] > prices[prices.length - 3];
      return isRising ? 'CALL' : 'PUT';
    }
    
    return 'CALL';
  }
}

abstract class TradingStrategy {
  String get name;
  
  TradeDecision? analyze(MarketAnalysis analysis, BotConfig config, List<TradeResult> history);
}

class TradeDecision {
  final String direction; // CALL, PUT
  final double stake;
  final String reason;
  final double confidence; // 0-1
  
  TradeDecision({
    required this.direction,
    required this.stake,
    required this.reason,
    required this.confidence,
  });
}

// Estratégia: Auto Trade com Queda/Subida
class AutoTradeFallRiseStrategy extends TradingStrategy {
  @override
  String get name => 'Auto Trade: Queda → Subida';
  
  @override
  TradeDecision? analyze(MarketAnalysis analysis, BotConfig config, List<TradeResult> history) {
    if (!config.autoTradeEnabled) return null;
    if (analysis.prices.length < config.autoTradeAnalysisPeriod) return null;
    
    final recent = analysis.prices.sublist(analysis.prices.length - config.autoTradeAnalysisPeriod);
    final priceChange = (recent.last - recent.first) / recent.first * 100;
    
    // Detectou queda?
    if (priceChange < -config.autoTradeThreshold) {
      final direction = config.autoTradeDirection == 'opposite' ? 'CALL' : 
                       config.autoTradeDirection == 'same' ? 'PUT' : 
                       analysis.suggestDirection();
      
      return TradeDecision(
        direction: direction,
        stake: _calculateStake(config, history),
        reason: 'Queda de ${priceChange.toStringAsFixed(2)}% detectada',
        confidence: 0.8,
      );
    }
    
    return null;
  }
  
  double _calculateStake(BotConfig config, List<TradeResult> history) {
    double stake = config.initialStake;
    
    // Lógica de recuperação de perda
    if (config.lossRecoveryEnabled && history.isNotEmpty) {
      final lastTrade = history.last;
      if (!lastTrade.won) {
        final totalLoss = history.where((t) => !t.won).fold(0.0, (sum, t) => sum + t.profit.abs());
        
        if (config.lossRecoveryMode == 'zero_profit') {
          stake = totalLoss / 0.95; // Recuperar apenas a perda
        } else if (config.lossRecoveryMode == 'with_profit') {
          final targetProfit = totalLoss * (config.lossRecoveryProfit / 100);
          stake = (totalLoss + targetProfit) / 0.95;
        } else {
          stake = lastTrade.stake * config.lossRecoveryMultiplier;
        }
      }
    }
    
    // Martingale
    if (config.martingaleEnabled && history.isNotEmpty) {
      final consecutiveLosses = _getConsecutiveLosses(history);
      if (consecutiveLosses > 0 && consecutiveLosses <= config.martingaleMaxLevels) {
        stake *= config.martingaleMultiplier * consecutiveLosses;
      }
    }
    
    // Acumulação
    if (config.accumulationEnabled && config.tradeWithAccumulatedProfit) {
      final totalProfit = history.fold(0.0, (sum, t) => sum + t.profit);
      if (totalProfit > 0) {
        stake += totalProfit * (config.accumulationProfitPercent / 100);
      }
    }
    
    return stake.clamp(config.initialStake, config.maxStake);
  }
  
  int _getConsecutiveLosses(List<TradeResult> history) {
    int count = 0;
    for (var i = history.length - 1; i >= 0; i--) {
      if (history[i].won) break;
      count++;
    }
    return count;
  }
}

// Estratégia: Acumulação Avançada
class AccumulationAdvancedStrategy extends TradingStrategy {
  @override
  String get name => 'Acumulação Avançada Pro';
  
  @override
  TradeDecision? analyze(MarketAnalysis analysis, BotConfig config, List<TradeResult> history) {
    if (!config.accumulationEnabled) return null;
    
    final wins = history.where((t) => t.won).toList();
    if (wins.length >= config.maxAccumulations) return null;
    
    final direction = analysis.suggestDirection();
    final totalProfit = history.fold(0.0, (sum, t) => sum + t.profit);
    
    double stake = config.initialStake;
    if (config.tradeWithAccumulatedProfit && totalProfit > 0) {
      stake += totalProfit * (config.accumulationProfitPercent / 100);
    }
    
    return TradeDecision(
      direction: direction,
      stake: stake.clamp(config.initialStake, config.maxStake),
      reason: 'Acumulação ${wins.length + 1}/${config.maxAccumulations}',
      confidence: 0.75,
    );
  }
}

// Estratégia: Pattern Recognition
class PatternRecognitionStrategy extends TradingStrategy {
  @override
  String get name => 'Reconhecimento de Padrões';
  
  @override
  TradeDecision? analyze(MarketAnalysis analysis, BotConfig config, List<TradeResult> history) {
    if (!config.useDigitPatterns) return null;
    if (analysis.digits.length < 20) return null;
    
    final freq = analysis.getDigitFrequency();
    final sortedDigits = freq.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    
    final mostFrequent = sortedDigits.first.key;
    final leastFrequent = sortedDigits.last.key;
    
    final direction = analysis.prices.last.toStringAsFixed(2).endsWith(mostFrequent.toString()) ? 'PUT' : 'CALL';
    
    return TradeDecision(
      direction: direction,
      stake: config.initialStake,
      reason: 'Padrão: Dígito $mostFrequent frequente',
      confidence: 0.7,
    );
  }
}

// Estratégia: Volatility Hunter
class VolatilityHunterStrategy extends TradingStrategy {
  @override
  String get name => 'Caçador de Volatilidade';
  
  @override
  TradeDecision? analyze(MarketAnalysis analysis, BotConfig config, List<TradeResult> history) {
    if (!config.useVolatilityAnalysis) return null;
    
    final volatility = analysis.getVolatility();
    if (volatility < 0.0005) return null; // Muito baixa
    
    final spike = analysis.detectSpike(config.autoTradeThreshold / 100);
    if (!spike) return null;
    
    final direction = analysis.suggestDirection();
    
    return TradeDecision(
      direction: direction,
      stake: config.initialStake * 1.5,
      reason: 'Alta volatilidade detectada',
      confidence: 0.85,
    );
  }
}