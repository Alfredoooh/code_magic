// bot_analytics.dart
import 'dart:math';
import 'bot_engine.dart';

class BotAnalytics {
  static PerformanceMetrics calculatePerformance(List<TradeRecord> history) {
    if (history.isEmpty) {
      return PerformanceMetrics.empty();
    }

    final wins = history.where((t) => t.won).length;
    final losses = history.length - wins;
    final winRate = wins / history.length;

    final totalProfit = history.fold(0.0, (sum, t) => sum + t.profit);
    final avgProfit = totalProfit / history.length;

    final winProfits = history.where((t) => t.won).map((t) => t.profit).toList();
    final lossProfits = history.where((t) => !t.won).map((t) => t.profit).toList();

    final avgWin = winProfits.isEmpty ? 0.0 : winProfits.reduce((a, b) => a + b) / winProfits.length;
    final avgLoss = lossProfits.isEmpty ? 0.0 : lossProfits.reduce((a, b) => a + b) / lossProfits.length;

    final profitFactor = avgLoss == 0 ? 0.0 : (avgWin * wins).abs() / (avgLoss * losses).abs();

    // Calcular drawdown
    final cumulative = <double>[];
    double sum = 0;
    for (var trade in history) {
      sum += trade.profit;
      cumulative.add(sum);
    }

    double maxDrawdown = 0;
    double peak = cumulative.first;
    for (var value in cumulative) {
      if (value > peak) peak = value;
      final drawdown = (peak - value) / max(peak, 1);
      if (drawdown > maxDrawdown) maxDrawdown = drawdown;
    }

    // Sharpe Ratio (simplificado)
    final returns = <double>[];
    for (int i = 1; i < cumulative.length; i++) {
      returns.add(cumulative[i] - cumulative[i - 1]);
    }
    final avgReturn = returns.isEmpty ? 0.0 : returns.reduce((a, b) => a + b) / returns.length;
    final stdDev = returns.isEmpty ? 1.0 : sqrt(returns.map((r) => pow(r - avgReturn, 2)).reduce((a, b) => a + b) / returns.length);
    final sharpeRatio = stdDev == 0 ? 0.0 : avgReturn / stdDev;

    // Expectancy
    final expectancy = (winRate * avgWin) - ((1 - winRate) * avgLoss.abs());

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

    return PerformanceMetrics(
      totalTrades: history.length,
      wins: wins,
      losses: losses,
      winRate: winRate,
      totalProfit: totalProfit,
      avgProfit: avgProfit,
      avgWin: avgWin,
      avgLoss: avgLoss,
      profitFactor: profitFactor,
      maxDrawdown: maxDrawdown,
      sharpeRatio: sharpeRatio,
      expectancy: expectancy,
      longestWinStreak: longestWinStreak,
      longestLossStreak: longestLossStreak,
      riskRewardRatio: avgLoss == 0 ? 0.0 : avgWin / avgLoss.abs(),
    );
  }

  static List<double> getCumulativeProfits(List<TradeRecord> history) {
    final cumulative = <double>[];
    double sum = 0;
    for (var trade in history) {
      sum += trade.profit;
      cumulative.add(sum);
    }
    return cumulative;
  }

  static List<double> getMovingWinRate(List<TradeRecord> history, int windowSize) {
    final rates = <double>[];
    for (int i = windowSize; i <= history.length; i++) {
      final window = history.sublist(i - windowSize, i);
      final wins = window.where((t) => t.won).length;
      rates.add(wins / windowSize);
    }
    return rates;
  }

  static Map<String, dynamic> predictNextTrade(List<TradeRecord> history) {
    if (history.length < 10) {
      return {'confidence': 0.5, 'direction': 'CALL', 'recommendedStake': 10.0};
    }

    final recent = history.sublist(max(0, history.length - 20));
    final recentWins = recent.where((t) => t.won).length;
    final recentWinRate = recentWins / recent.length;

    // Analisar padrões de RSI
    final avgRSI = recent.map((t) => t.rsi).reduce((a, b) => a + b) / recent.length;

    String direction = 'CALL';
    double confidence = 0.5;

    if (avgRSI < 30) {
      direction = 'CALL';
      confidence = 0.7;
    } else if (avgRSI > 70) {
      direction = 'PUT';
      confidence = 0.7;
    }

    // Ajustar por win rate recente
    confidence = (confidence + recentWinRate) / 2;

    // Recomendar stake baseado em performance
    final avgStake = recent.map((t) => t.stake).reduce((a, b) => a + b) / recent.length;
    double recommendedStake = avgStake;

    if (recentWinRate > 0.6) {
      recommendedStake = avgStake * 1.2;
    } else if (recentWinRate < 0.4) {
      recommendedStake = avgStake * 0.8;
    }

    return {
      'confidence': confidence,
      'direction': direction,
      'recommendedStake': recommendedStake,
      'recentWinRate': recentWinRate,
      'avgRSI': avgRSI,
    };
  }

  static String getPerformanceGrade(PerformanceMetrics metrics) {
    double score = 0;

    // Win rate (30%)
    if (metrics.winRate > 0.6) score += 30;
    else if (metrics.winRate > 0.5) score += 20;
    else if (metrics.winRate > 0.4) score += 10;

    // Profit factor (25%)
    if (metrics.profitFactor > 2.0) score += 25;
    else if (metrics.profitFactor > 1.5) score += 18;
    else if (metrics.profitFactor > 1.0) score += 12;

    // Drawdown (20%)
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

    if (score >= 80) return 'S+';
    if (score >= 70) return 'S';
    if (score >= 60) return 'A';
    if (score >= 50) return 'B';
    if (score >= 40) return 'C';
    if (score >= 30) return 'D';
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
      recommendations.add('⚠️ Profit factor negativo. Estratégia não está lucrativa.');
    }

    if (metrics.riskRewardRatio < 1.0) {
      recommendations.add('⚠️ Risk/Reward desfavorável. Aumente o take profit ou reduza stop loss.');
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