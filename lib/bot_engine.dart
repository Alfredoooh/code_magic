import 'dart:async';
import 'bot_strategies.dart';

class BotEngine {
  final BotConfig config;
  final String market;
  final Function(TradeResult) onTrade;
  final Function(String) onLog;
  
  bool _isRunning = false;
  final List<TradeResult> _history = [];
  final List<double> _prices = [];
  final List<int> _digits = [];
  final List<TradingStrategy> _strategies = [];
  
  int _tradesCount = 0;
  double _totalProfit = 0.0;
  int _consecutiveLosses = 0;
  int _accumulationLevel = 0;
  
  BotEngine({
    required this.config,
    required this.market,
    required this.onTrade,
    required this.onLog,
  }) {
    _initStrategies();
  }
  
  void _initStrategies() {
    _strategies.clear();
    _strategies.add(AutoTradeFallRiseStrategy());
    _strategies.add(AccumulationAdvancedStrategy());
    _strategies.add(PatternRecognitionStrategy());
    _strategies.add(VolatilityHunterStrategy());
  }
  
  bool get isRunning => _isRunning;
  List<TradeResult> get history => List.unmodifiable(_history);
  int get tradesCount => _tradesCount;
  double get totalProfit => _totalProfit;
  int get winRate => _history.isEmpty ? 0 : (_history.where((t) => t.won).length / _history.length * 100).round();
  
  void start() {
    if (_isRunning) return;
    _isRunning = true;
    onLog('🚀 Bot iniciado em $market');
  }
  
  void stop() {
    _isRunning = false;
    onLog('🛑 Bot parado');
  }
  
  void processTick(double price) {
    if (!_isRunning) return;
    
    _prices.add(price);
    if (_prices.length > 500) _prices.removeAt(0);
    
    final digit = ((price * 100).toInt() % 10);
    _digits.add(digit);
    if (_digits.length > 500) _digits.removeAt(0);
    
    _checkSafetyLimits();
    _analyzeAndTrade();
  }
  
  void _checkSafetyLimits() {
    // Máximo de trades por dia
    if (_tradesCount >= config.maxTradesPerDay) {
      stop();
      onLog('⚠️ Limite diário de trades atingido');
      return;
    }
    
    // Perdas consecutivas
    if (_consecutiveLosses >= config.maxConsecutiveLosses) {
      stop();
      onLog('⚠️ Limite de perdas consecutivas atingido');
      return;
    }
    
    // Drawdown
    if (config.stopOnDrawdown) {
      final initialBalance = config.initialStake * 100;
      final currentBalance = initialBalance + _totalProfit;
      final drawdown = ((initialBalance - currentBalance) / initialBalance * 100);
      
      if (drawdown >= config.maxDrawdownPercent) {
        stop();
        onLog('⚠️ Drawdown máximo atingido: ${drawdown.toStringAsFixed(2)}%');
        return;
      }
    }
    
    // Stop Loss
    if (_totalProfit <= -config.stopLoss) {
      stop();
      onLog('🛑 Stop Loss atingido');
      return;
    }
    
    // Take Profit
    if (_totalProfit >= config.takeProfit) {
      stop();
      onLog('🎯 Take Profit atingido!');
      return;
    }
  }
  
  void _analyzeAndTrade() {
    if (_prices.length < 20) return;
    
    final analysis = MarketAnalysis(_prices, _digits);
    
    // Tentar cada estratégia
    for (var strategy in _strategies) {
      final decision = strategy.analyze(analysis, config, _history);
      
      if (decision != null && decision.confidence >= 0.6) {
        _executeTrade(decision, strategy.name);
        break; // Apenas uma trade por tick
      }
    }
  }
  
  void _executeTrade(TradeDecision decision, String strategyName) {
    _tradesCount++;
    
    // Simular resultado (em produção, isso viria da API)
    final won = _simulateTradeResult(decision);
    final payout = won ? decision.stake * 1.95 : 0.0;
    final profit = payout - decision.stake;
    
    final trade = TradeResult(
      timestamp: DateTime.now(),
      market: market,
      direction: decision.direction,
      stake: decision.stake,
      payout: payout,
      profit: profit,
      won: won,
      strategy: strategyName,
      accumulationLevel: _accumulationLevel,
      wasRecovery: config.lossRecoveryEnabled && _consecutiveLosses > 0,
    );
    
    _history.add(trade);
    _totalProfit += profit;
    
    if (won) {
      _consecutiveLosses = 0;
      if (config.accumulationEnabled) {
        _accumulationLevel++;
        if (_accumulationLevel >= config.maxAccumulations) {
          _accumulationLevel = 0;
          onLog('✨ Ciclo de acumulação completo!');
        }
      }
    } else {
      _consecutiveLosses++;
      _accumulationLevel = 0;
    }
    
    onTrade(trade);
    
    final emoji = won ? '✅' : '❌';
    onLog('$emoji ${trade.direction} \$${trade.stake.toStringAsFixed(2)} → ${won ? "WIN" : "LOSS"} (${profit >= 0 ? "+" : ""}\$${profit.toStringAsFixed(2)})');
    
    if (trade.wasRecovery && won) {
      onLog('💰 Perda recuperada com sucesso!');
    }
  }
  
  bool _simulateTradeResult(TradeDecision decision) {
    // Simulação baseada na confiança da decisão
    final random = DateTime.now().millisecond / 1000;
    return random < decision.confidence;
  }
  
  void reset() {
    _history.clear();
    _prices.clear();
    _digits.clear();
    _tradesCount = 0;
    _totalProfit = 0.0;
    _consecutiveLosses = 0;
    _accumulationLevel = 0;
    onLog('🔄 Bot resetado');
  }
  
  Map<String, dynamic> getStats() {
    if (_history.isEmpty) {
      return {
        'total_trades': 0,
        'wins': 0,
        'losses': 0,
        'win_rate': 0,
        'profit': 0.0,
        'best_trade': 0.0,
        'worst_trade': 0.0,
        'avg_profit': 0.0,
      };
    }
    
    final wins = _history.where((t) => t.won).length;
    final losses = _history.length - wins;
    final profits = _history.map((t) => t.profit).toList();
    
    return {
      'total_trades': _history.length,
      'wins': wins,
      'losses': losses,
      'win_rate': (wins / _history.length * 100).round(),
      'profit': _totalProfit,
      'best_trade': profits.reduce((a, b) => a > b ? a : b),
      'worst_trade': profits.reduce((a, b) => a < b ? a : b),
      'avg_profit': _totalProfit / _history.length,
    };
  }
}