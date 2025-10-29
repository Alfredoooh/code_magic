// bot_analysis.dart
import 'dart:math';
import 'bot_configuration.dart';

class BotAnalysis {
  /// ============================================
  /// CÁLCULO DE RSI (Relative Strength Index)
  /// ============================================
  static double calculateRSI(List<double> priceHistory) {
    if (priceHistory.length < 15) return 50.0;
    
    double gains = 0.0;
    double losses = 0.0;
    
    for (int i = priceHistory.length - 14; i < priceHistory.length; i++) {
      final change = priceHistory[i] - priceHistory[i - 1];
      if (change > 0) {
        gains += change;
      } else {
        losses += -change;
      }
    }
    
    final avgGain = gains / 14;
    final avgLoss = losses / 14;
    
    if (avgGain == 0 && avgLoss == 0) return 50.0;
    if (avgLoss == 0) return 100.0;
    
    final rs = avgGain / avgLoss;
    final rsi = 100.0 - (100.0 / (1.0 + rs));
    
    return rsi.clamp(0.0, 100.0);
  }

  /// ============================================
  /// CÁLCULO DE EMA (Exponential Moving Average)
  /// ============================================
  static double calculateEMA(List<double> prices, int period) {
    if (prices.length < period) return prices.last;
    
    final multiplier = 2.0 / (period + 1);
    double ema = prices[prices.length - period];
    
    for (int i = prices.length - period + 1; i < prices.length; i++) {
      ema = (prices[i] - ema) * multiplier + ema;
    }
    
    return ema;
  }

  /// ============================================
  /// CÁLCULO DE MACD
  /// ============================================
  static Map<String, double> calculateMACD(List<double> priceHistory) {
    if (priceHistory.length < 26) {
      return {'macd': 0.0, 'signal': 0.0, 'histogram': 0.0};
    }
    
    final ema12 = calculateEMA(priceHistory, 12);
    final ema26 = calculateEMA(priceHistory, 26);
    final macd = ema12 - ema26;
    
    // Signal line (EMA de 9 períodos do MACD)
    // Simplificado aqui, em produção você guardaria histórico de MACD
    final signal = macd * 0.9; // Aproximação
    final histogram = macd - signal;
    
    return {
      'macd': macd,
      'signal': signal,
      'histogram': histogram,
    };
  }

  /// ============================================
  /// DETECÇÃO DE CRUZAMENTO MACD
  /// ============================================
  static bool detectMACDCross(double currentMACD, double previousMACD) {
    return previousMACD < 0 && currentMACD >= 0;
  }

  /// ============================================
  /// BANDAS DE BOLLINGER
  /// ============================================
  static Map<String, double> calculateBollingerBands(List<double> priceHistory, {int period = 20}) {
    if (priceHistory.length < period) {
      return {
        'upper': priceHistory.last,
        'middle': priceHistory.last,
        'lower': priceHistory.last,
      };
    }
    
    final recent = priceHistory.sublist(priceHistory.length - period);
    final sma = recent.reduce((a, b) => a + b) / recent.length;
    
    final variance = recent
        .map((p) => pow(p - sma, 2))
        .reduce((a, b) => a + b) / recent.length;
    final stdDev = sqrt(max(variance, 0.0));
    
    return {
      'upper': sma + (2 * stdDev),
      'middle': sma,
      'lower': sma - (2 * stdDev),
    };
  }

  /// ============================================
  /// DETECÇÃO DE QUEBRA DE BOLLINGER
  /// ============================================
  static bool detectBollingerBreak(List<double> priceHistory) {
    if (priceHistory.length < 20) return false;
    
    final bands = calculateBollingerBands(priceHistory);
    final current = priceHistory.last;
    
    return current > bands['upper']! || current < bands['lower']!;
  }

  /// ============================================
  /// SUPORTE E RESISTÊNCIA
  /// ============================================
  static Map<String, double> calculateSupportResistance(List<double> priceHistory) {
    if (priceHistory.length < 50) {
      return {'support': priceHistory.first, 'resistance': priceHistory.last};
    }
    
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
    
    final support = localMins.isNotEmpty ? localMins.reduce(min) : recent.first;
    final resistance = localMaxs.isNotEmpty ? localMaxs.reduce(max) : recent.last;
    
    return {'support': support, 'resistance': resistance};
  }

  /// ============================================
  /// DETECÇÃO DE TOQUE EM SUPORTE/RESISTÊNCIA
  /// ============================================
  static bool detectSupportResistanceTouch(
    List<double> priceHistory,
    double supportLevel,
    double resistanceLevel,
  ) {
    if (supportLevel == 0 || resistanceLevel == 0) return false;
    
    final current = priceHistory.last;
    final threshold = current * 0.0015;
    
    return (current - supportLevel).abs() < threshold ||
           (current - resistanceLevel).abs() < threshold;
  }

  /// ============================================
  /// DETECÇÃO DE PADRÃO (Double Top/Bottom)
  /// ============================================
  static bool detectPattern(List<double> priceHistory) {
    if (priceHistory.length < 30) return false;
    
    final recent = priceHistory.sublist(priceHistory.length - 30);
    final peaks = <double>[];
    final bottoms = <double>[];
    
    for (int i = 1; i < recent.length - 1; i++) {
      if (recent[i] > recent[i - 1] && recent[i] > recent[i + 1]) {
        peaks.add(recent[i]);
      }
      if (recent[i] < recent[i - 1] && recent[i] < recent[i + 1]) {
        bottoms.add(recent[i]);
      }
    }
    
    // Double Top
    if (peaks.length >= 2) {
      final last = peaks.last;
      final prev = peaks[peaks.length - 2];
      if ((last - prev).abs() / max(prev, 1) < 0.02) return true;
    }
    
    // Double Bottom
    if (bottoms.length >= 2) {
      final lastB = bottoms.last;
      final prevB = bottoms[bottoms.length - 2];
      if ((lastB - prevB).abs() / max(prevB, 1) < 0.02) return true;
    }
    
    return false;
  }

  /// ============================================
  /// DETECÇÃO DE PRICE ACTION (Tendência clara)
  /// ============================================
  static bool detectPriceAction(List<double> priceHistory) {
    if (priceHistory.length < 5) return false;
    
    final recent = priceHistory.sublist(priceHistory.length - 5);
    int bullish = 0;
    int bearish = 0;
    
    for (int i = 1; i < recent.length; i++) {
      if (recent[i] > recent[i - 1]) {
        bullish++;
      } else if (recent[i] < recent[i - 1]) {
        bearish++;
      }
    }
    
    return bullish >= 4 || bearish >= 4;
  }

  /// ============================================
  /// DETECÇÃO DE VOLUME SPIKE
  /// ============================================
  static bool detectVolumeSpike(List<double> priceHistory) {
    if (priceHistory.length < 10) return false;
    
    final recent = priceHistory.sublist(priceHistory.length - 10);
    final mean = recent.reduce((a, b) => a + b) / recent.length;
    final last = recent.last;
    final percent = ((last - mean).abs() / max(mean, 1));
    
    return percent > 0.015;
  }

  /// ============================================
  /// DETECÇÃO DE TENDÊNCIA
  /// ============================================
  static bool detectTrend(List<double> priceHistory) {
    if (priceHistory.length < 20) return false;
    
    final recent = priceHistory.sublist(priceHistory.length - 20);
    final sma = recent.reduce((a, b) => a + b) / recent.length;
    final current = priceHistory.last;
    
    return (current - sma).abs() / sma > 0.005;
  }

  /// ============================================
  /// CÁLCULO DE WIN RATE RECENTE
  /// ============================================
  static double calculateRecentWinRate(List<TradeRecord> tradeHistory, int trades) {
    if (tradeHistory.isEmpty) return 0.0;
    
    final take = min(trades, tradeHistory.length);
    final recent = tradeHistory.sublist(tradeHistory.length - take);
    final recentWins = recent.where((t) => t.won).length;
    
    return recentWins / max(take, 1);
  }

  /// ============================================
  /// CÁLCULO DE VOLATILIDADE
  /// ============================================
  static double calculateVolatility(List<double> priceHistory) {
    if (priceHistory.length < 20) return 0.0;
    
    final recent = priceHistory.sublist(priceHistory.length - 20);
    final mean = recent.reduce((a, b) => a + b) / recent.length;
    final variance = recent
        .map((p) => pow(p - mean, 2))
        .reduce((a, b) => a + b) / recent.length;
    
    return sqrt(max(variance, 0.0)) / max(mean, 1);
  }

  /// ============================================
  /// DETECÇÃO DE SEQUÊNCIA DE TENDÊNCIA (Para Trendy)
  /// ============================================
  static Map<String, dynamic> detectTrendSequence(
    List<double> priceHistory,
    int filterLength,
  ) {
    if (priceHistory.length < filterLength + 1) {
      return {'detected': false, 'direction': 'neutral', 'strength': 0.0};
    }
    
    final recent = priceHistory.sublist(priceHistory.length - (filterLength + 1));
    int ups = 0;
    int downs = 0;
    
    for (int i = 1; i < recent.length; i++) {
      if (recent[i] > recent[i - 1]) {
        ups++;
      } else if (recent[i] < recent[i - 1]) {
        downs++;
      }
    }
    
    final strength = (ups - downs).abs() / filterLength.toDouble();
    
    if (ups >= filterLength) {
      return {'detected': true, 'direction': 'up', 'strength': strength};
    } else if (downs >= filterLength) {
      return {'detected': true, 'direction': 'down', 'strength': strength};
    }
    
    return {'detected': false, 'direction': 'neutral', 'strength': strength};
  }

  /// ============================================
  /// ANÁLISE DE PADRÃO RECENTE (Para ACS-R)
  /// Retorna lista de direções recentes baseada em preços
  /// ============================================
  static List<String> analyzeRecentPattern(List<double> priceHistory, int length) {
    if (priceHistory.length < length + 1) return [];
    
    final recent = priceHistory.sublist(priceHistory.length - (length + 1));
    List<String> pattern = [];
    
    for (int i = 1; i < recent.length; i++) {
      if (recent[i] > recent[i - 1]) {
        pattern.add('Rise');
      } else if (recent[i] < recent[i - 1]) {
        pattern.add('Fall');
      } else {
        pattern.add('Equal');
      }
    }
    
    return pattern;
  }
}