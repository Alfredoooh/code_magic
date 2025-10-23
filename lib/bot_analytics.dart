// bot_analytics.dart (corrigido e melhorado)
import 'dart:math';
import 'bot_engine.dart';

class BotAnalytics {
  static PerformanceMetrics calculatePerformance(List<TradeRecord> history) {
    if (history.isEmpty) {
      return PerformanceMetrics.empty();
    }

    final totalTrades = history.length;
    final wins = history.where((t) => t.won).length;
    final losses = totalTrades - wins;
    final winRate = wins / max(totalTrades, 1);

    final totalProfit = history.fold<double>(0.0, (sum, t) => sum + t.profit);
    final avgProfit = totalProfit / max(totalTrades, 1);

    final winProfits = history.where((t) => t.won).map((t) => t.profit).toList();
    final lossProfits = history.where((t) => !t.won).map((t) => t.profit).toList();

    final avgWin = winProfits.isEmpty ? 0.0 : winProfits.reduce((a, b) => a + b) / winProfits.length;
    // avgLoss kept with sign (lossProfits are typically negative if losses recorded negative profit),
    // but if stored positive, we take sign into account below by using abs() where appropriate.
    final avgLoss = lossProfits.isEmpty ? 0.0 : lossProfits.reduce((a, b) => a + b) / lossProfits.length;

    // Profit factor: total gross wins / total gross losses (use absolute values)
    final grossWins = winProfits.fold<double>(0.0, (s, v) => s + v);
    final grossLosses = lossProfits.fold<double>(0.0, (s, v) => s + v.abs());
    final profitFactor = grossLosses == 0.0 ? (grossWins > 0.0 ? double.infinity : 0.0) : (grossWins / grossLosses);

    // Cumulative profits for drawdown/sharpe
    final cumulative = <double>[];
    double sum = 0.0;
    for (var trade in history) {
      sum += trade.profit;
      cumulative.add(sum);
    }

    // Max drawdown (peak-to-trough) as fraction of peak
    double maxDrawdown = 0.0;
    double peak = cumulative.isNotEmpty ? cumulative.first : 0.0;
    for (var value in cumulative) {
      if (value > peak) peak = value;
      final denom = max(peak.abs(), 1.0);
      final drawdown = (peak - value) / denom;
      if (drawdown > maxDrawdown) maxDrawdown = drawdown;
    }

    // Returns series (period returns = difference between consecutive cumulative values)
    final returns = <double>[];
    for (int i = 1; i < cumulative.length; i++) {
      returns.add(cumulative[i] - cumulative[i - 1]);
    }
    final avgReturn = returns.isEmpty ? 0.0 : returns.reduce((a, b) => a + b) / returns.length;
    final variance = returns.isEmpty
        ? 0.0
        : returns.map((r) => pow(r - avgReturn, 2)).reduce((a, b) => a + b) / returns.length;
    final stdDev = sqrt(max(0.0, variance));
    final sharpeRatio = stdDev == 0.0 ? 0.0 : (avgReturn / stdDev);

    // Expectancy: average expectation per trade (wins*avgWin - losses*avgLoss)/totalTrades
    final expectancy = totalTrades == 0
        ? 0.0
        : ((wins * avgWin) - (losses * avgLoss.abs())) / max(totalTrades, 1);

    // Longest win/loss streaks
    int currentWinStreak = 0;
    int currentLossStreak = 0;
    int longestWinStreak = 0;
    int longestLossStreak = 0;

    for (var trade in history) {
      if (trade.won) {
        currentWinStreak++;
        currentLossStreak = 0;
        if (currentWinStreak > longestWinStreak) longestWinStreak = currentWinStreak;
      } else {
        currentLossStreak++;
        currentWinStreak = 0;
        if (currentLossStreak > longestLossStreak) longestLossStreak = currentLossStreak;
      }
    }

    final riskRewardRatio = avgLoss == 0.0 ? (avgWin == 0.0 ? 0.0 : double.infinity) : (avgWin / avgLoss.abs());

    return PerformanceMetrics(
      totalTrades: totalTrades,
      wins: wins,
      losses: losses,
      winRate: winRate,
      totalProfit: totalProfit,
      avgProfit: avgProfit,
      avgWin: avgWin,
      avgLoss: avgLoss,
      profitFactor: profitFactor.isInfinite ? double.maxFinite : profitFactor,
      maxDrawdown: maxDrawdown,
      sharpeRatio: sharpeRatio,
      expectancy: expectancy,
      longestWinStreak: longestWinStreak,
      longestLossStreak: longestLossStreak,
      riskRewardRatio: riskRewardRatio.isInfinite ? double.maxFinite : riskRewardRatio,
    );
  }

  static List<double> getCumulativeProfits(List<TradeRecord> history) {
    final cumulative = <double>[];
    double sum = 0.0;
    for (var trade in history) {
      sum += trade.profit;
      cumulative.add(sum);
    }
    return cumulative;
  }

  static List<double> getMovingWinRate(List<TradeRecord> history, int windowSize) {
    final rates = <double>[];
    if (windowSize <= 0) return rates;
    if (history.length < windowSize) {
      // return single aggregated rate if not enough data
      final wins = history.where((t) => t.won).length;
      rates.add(wins / max(history.length, 1));
      return rates;
    }

    for (int i = windowSize; i <= history.length; i++) {
      final window = history.sublist(i - windowSize, i);
      final wins = window.where((t) => t.won).length;
      rates.add(wins / windowSize);
    }
    return rates;
  }

  static Map<String, dynamic> predictNextTrade(List<TradeRecord> history) {
    // Outputs:
    // { 'confidence': double (0..1), 'direction': 'CALL'|'PUT', 'recommendedStake': double, ... }
    if (history.isEmpty) {
      return {'confidence': 0.5, 'direction': 'CALL', 'recommendedStake': 10.0};
    }

    // Use recent window for prediction
    final recentWindow = 20;
    final recent = history.sublist(max(0, history.length - recentWindow));
    final recentWins = recent.where((t) => t.won).length;
    final recentWinRate = recentWins / max(recent.length, 1);

    // RSI-based bias (if RSI available)
    double avgRSI = 50.0;
    try {
      avgRSI = recent.map((t) => t.rsi).fold<double>(0.0, (a, b) => a + b) / max(recent.length, 1);
    } catch (_) {
      avgRSI = 50.0;
    }

    // Volatility of profits as proxy for market noise: higher volatility => lower confidence
    final profits = recent.map((t) => t.profit).toList();
    final profitMean = profits.isEmpty ? 0.0 : profits.reduce((a, b) => a + b) / profits.length;
    final profitVar = profits.isEmpty ? 0.0 : profits.map((p) => pow(p - profitMean, 2)).reduce((a, b) => a + b) / profits.length;
    final profitStd = sqrt(max(0.0, profitVar));

    // Decide direction: prefer CALL if RSI low (oversold), PUT if RSI high (overbought), else use winRate bias
    String direction = 'CALL';
    if (avgRSI < 35) {
      direction = 'CALL';
    } else if (avgRSI > 65) {
      direction = 'PUT';
    } else {
      direction = recentWinRate >= 0.5 ? 'CALL' : 'PUT';
    }

    // Confidence is combination of recentWinRate, RSI signal strength, and inverse volatility
    final rsiSignal = (0.5 - ((avgRSI - 50.0).abs() / 50.0)) * -1 + 1; // 0..1 stronger when RSI away from 50
    // alternative: stronger when RSI far from 50
    final rsiStrength = ((avgRSI - 50.0).abs() / 50.0).clamp(0.0, 1.0); // 0..1
    // aggregate
    double confidence = 0.4 * recentWinRate + 0.4 * rsiStrength + 0.2 * (1.0 - (profitStd / max(profitStd + 1.0, 1.0)));
    confidence = confidence.clamp(0.0, 1.0);

    // Recommended stake: use recent average stake adjusted by confidence and recent performance
    double avgStake;
    try {
      avgStake = recent.map((t) => t.stake).fold<double>(0.0, (a, b) => a + b) / max(recent.length, 1);
    } catch (_) {
      avgStake = 10.0;
    }

    double recommendedStake = avgStake * (0.5 + confidence * 0.8); // conservative scaling
    // adjust by recent win rate
    if (recentWinRate > 0.6) recommendedStake *= 1.15;
    if (recentWinRate < 0.4) recommendedStake *= 0.85;
    // clamp to sensible bounds derived from data
    final minStake = max(0.01, avgStake * 0.2);
    final maxStake = max(avgStake * 5, avgStake + 100);
    recommendedStake = recommendedStake.clamp(minStake, maxStake);

    return {
      'confidence': double.parse(confidence.toStringAsFixed(3)),
      'direction': direction,
      'recommendedStake': double.parse(recommendedStake.toStringAsFixed(2)),
      'recentWinRate': double.parse(recentWinRate.toStringAsFixed(3)),
      'avgRSI': double.parse(avgRSI.toStringAsFixed(1)),
      'profitStd': double.parse(profitStd.toStringAsFixed(3)),
    };
  }

  static String getPerformanceGrade(PerformanceMetrics metrics) {
    double score = 0.0;

    // Win rate (30%)
    if (metrics.winRate > 0.6) score += 30;
    else if (metrics.winRate > 0.55) score += 22;
    else if (metrics.winRate > 0.5) score += 16;
    else if (metrics.winRate > 0.45) score += 8;

    // Profit factor (25%)
    if (metrics.profitFactor > 2.0) score += 25;
    else if (metrics.profitFactor > 1.5) score += 18;
    else if (metrics.profitFactor > 1.0) score += 12;

    // Drawdown (20%) - smaller drawdown is better
    if (metrics.maxDrawdown < 0.1) score += 20;
    else if (metrics.maxDrawdown < 0.2) score += 15;
    else if (metrics.maxDrawdown < 0.3) score += 10;
    else if (metrics.maxDrawdown < 0.5) score += 5;

    // Sharpe ratio (15%)
    if (metrics.sharpeRatio > 2.0) score += 15;
    else if (metrics.sharpeRatio > 1.0) score += 10;
    else if (metrics.sharpeRatio > 0.5) score += 5;

    // Expectancy (10%)
    if (metrics.expectancy > 5) score += 10;
    else if (metrics.expectancy > 2) score += 7;
    else if (metrics.expectancy > 0) score += 4;

    if (score >= 85) return 'S+';
    if (score >= 75) return 'S';
    if (score >= 65) return 'A';
    if (score >= 55) return 'B';
    if (score >= 45) return 'C';
    if (score >= 35) return 'D';
    return 'F';
  }

  static List<String> getRecommendations(PerformanceMetrics metrics) {
    final recommendations = <String>[];

    if (metrics.winRate < 0.4) {
      recommendations.add('⚠️ Win rate baixo. Considere revisar estratégia de entrada.');
    }

    if (metrics.maxDrawdown > 0.3) {
      recommendations.add('⚠️ Drawdown alto. Reduza o stake ou ajuste recovery mode.');
    }

    if (metrics.profitFactor < 1.0) {
      recommendations.add('⚠️ Profit factor < 1. Estratégia não está lucrativa no agregado.');
    }

    if (metrics.riskRewardRatio < 1.0 && metrics.totalTrades > 10) {
      recommendations.add('⚠️ Risk/Reward desfavorável. Reavalie stop/target.');
    }

    if (metrics.longestLossStreak > 7) {
      recommendations.add('⚠️ Sequência longa de perdas detectada. Considere pausar o bot.');
    }

    if (metrics.sharpeRatio < 0.5) {
      recommendations.add('⚠️ Retornos inconsistentes. Busque sinais de entrada mais confiáveis.');
    }

    if (recommendations.isEmpty) {
      recommendations.add('✅ Bot performando bem! Continue monitorando.');
    }

    return recommendations;
  }
}

class PerformanceMetrics {
  final int totalTrades;
  final int wins;
  final int losses;
  final double winRate;
  final double totalProfit;
  final double avgProfit;
  final double avgWin;
  final double avgLoss;
  final double profitFactor;
  final double maxDrawdown;
  final double sharpeRatio;
  final double expectancy;
  final int longestWinStreak;
  final int longestLossStreak;
  final double riskRewardRatio;

  PerformanceMetrics({
    required this.totalTrades,
    required this.wins,
    required this.losses,
    required this.winRate,
    required this.totalProfit,
    required this.avgProfit,
    required this.avgWin,
    required this.avgLoss,
    required this.profitFactor,
    required this.maxDrawdown,
    required this.sharpeRatio,
    required this.expectancy,
    required this.longestWinStreak,
    required this.longestLossStreak,
    required this.riskRewardRatio,
  });

  factory PerformanceMetrics.empty() {
    return PerformanceMetrics(
      totalTrades: 0,
      wins: 0,
      losses: 0,
      winRate: 0,
      totalProfit: 0,
      avgProfit: 0,
      avgWin: 0,
      avgLoss: 0,
      profitFactor: 0,
      maxDrawdown: 0,
      sharpeRatio: 0,
      expectancy: 0,
      longestWinStreak: 0,
      longestLossStreak: 0,
      riskRewardRatio: 0,
    );
  }
}