// bot_strategies.dart
import 'dart:math';
import 'bot_configuration.dart';

class BotStrategies {
  /// ============================================
  /// MARTINGALE REALISTA
  /// ============================================
  static double calculateMartingaleStake({
    required BotConfiguration config,
    required int consecutiveLosses,
    required double lossStreakAmount,
  }) {
    final payout = config.estimatedPayout;
    final minStake = max(config.initialStake, 0.35);

    if (consecutiveLosses == 0) {
      return minStake;
    }

    final desiredProfit = config.initialStake;
    final required = (lossStreakAmount + desiredProfit) / max(0.0001, payout);

    return max(minStake, required);
  }

  /// ============================================
  /// PROGRESSIVE REINVESTMENT
  /// Implementação CORRETA conforme especificação
  /// ============================================
  static Map<String, dynamic> calculateProgressiveReinvestmentStake({
    required BotConfiguration config,
    required int currentCycle,
    required int currentRound,
    required double cycleStartStake,
    required double totalLossesInCycle,
    required bool lastTradeWon,
    required double lastStake,
    required double lastProfit,
  }) {
    final payout = config.estimatedPayout;
    final N = config.roundsPerCycle;  // Número de rodadas por ciclo
    final L = config.extraProfitPercent / 100.0;  // Lucro extra (%)
    final R = 1 + payout;  // Multiplicador de retorno (ex: 1.95 se payout = 95%)

    double newStake;
    bool shouldStartNewCycle = false;
    int nextCycle = currentCycle;
    int nextRound = currentRound;
    double nextCycleStartStake = cycleStartStake;

    // ===== CASO 1: VITÓRIA =====
    if (lastTradeWon && currentRound > 0) {
      // Reinvestir TUDO (stake + lucro) na próxima rodada
      newStake = lastStake + lastProfit;
      nextRound = currentRound + 1;

      // Se completou todas as N rodadas do ciclo com sucesso
      if (nextRound > N) {
        shouldStartNewCycle = true;
        nextCycle = currentCycle + 1;
        nextRound = 1;
        newStake = config.initialStake;  // Resetar para stake inicial
        nextCycleStartStake = config.initialStake;
      }
    }
    // ===== CASO 2: PERDA durante o ciclo =====
    else if (!lastTradeWon && currentRound > 0) {
      // Total perdido no ciclo (P)
      final P = totalLossesInCycle;
      
      // Calcular novo stake inicial usando a FÓRMULA EXATA:
      // S₀' = (P × (1 + L%)) / ((R^N) - 1)
      final numerator = P * (1 + L);
      final denominator = pow(R, N) - 1;
      newStake = numerator / max(0.01, denominator);

      // Iniciar novo ciclo com stake recalculado
      shouldStartNewCycle = true;
      nextCycle = currentCycle + 1;
      nextRound = 1;
      nextCycleStartStake = newStake;
    }
    // ===== CASO 3: Primeira rodada do ciclo =====
    else {
      newStake = cycleStartStake;
      nextRound = 1;
    }

    // Limitar stake
    final minStake = max(config.initialStake, 0.35);
    final maxStake = config.maxStake ?? double.infinity;
    newStake = newStake.clamp(minStake, maxStake);

    return {
      'stake': newStake,
      'cycle': nextCycle,
      'round': nextRound,
      'newCycle': shouldStartNewCycle,
      'cycleStartStake': nextCycleStartStake,
    };
  }

  /// ============================================
  /// TRENDY ADAPTIVE
  /// Implementação CORRETA com 3 fases
  /// ============================================
  static Map<String, dynamic> calculateTrendyAdaptiveStake({
    required BotConfiguration config,
    required int consecutiveWins,
    required int consecutiveLosses,
    required double currentStake,
    required double lastProfit,
    required bool trendDetected,
    required double profitBank,
    required String phase,  // 'observation', 'execution', 'recovery'
  }) {
    final Mt = config.trendMultiplier;  // Ex: 1.5
    final Mr = config.recoveryMultiplier;  // Ex: 1.2
    final F = config.trendFilter;  // Ex: 2 vitórias para confirmar tendência

    double newStake;
    double newProfitBank = profitBank;
    bool newTrendDetected = trendDetected;
    String newPhase = phase;

    // ===== FASE 1: OBSERVAÇÃO E DETECÇÃO DE TENDÊNCIA =====
    if (phase == 'observation') {
      if (consecutiveWins >= F) {
        newTrendDetected = true;
        newPhase = 'execution';
        // Aplicar multiplicador de tendência
        final halfProfit = lastProfit * 0.5;
        newStake = (currentStake + halfProfit) * Mt;
        newProfitBank += (lastProfit - halfProfit);  // Guardar outra metade
      } else {
        newStake = config.initialStake;
      }
    }
    // ===== FASE 2: EXECUÇÃO COM STAKE PROGRESSIVO =====
    else if (phase == 'execution' && consecutiveWins > 0) {
      // Fórmula: S_next = (S_current + (lucro × 0.5)) × Mt
      final halfProfit = lastProfit * 0.5;
      final otherHalf = lastProfit - halfProfit;
      
      newStake = (currentStake + halfProfit) * Mt;
      newProfitBank += otherHalf;  // Guardar metade do lucro
    }
    // ===== FASE 3: REAJUSTE APÓS PERDA =====
    else if (consecutiveLosses > 0) {
      // Fórmula: S_next = S_current × Mr (apenas 1 vez)
      newStake = currentStake * Mr;
      newTrendDetected = false;
      newPhase = 'observation';  // Voltar para observação
    }
    // ===== INÍCIO =====
    else {
      newStake = config.initialStake;
      newPhase = 'observation';
    }

    // Limitar stake
    final minStake = max(config.initialStake, 0.35);
    final maxStake = config.maxStake ?? double.infinity;
    newStake = newStake.clamp(minStake, maxStake);

    return {
      'stake': newStake,
      'trendDetected': newTrendDetected,
      'profitBank': newProfitBank,
      'phase': newPhase,
    };
  }

  /// ============================================
  /// ACS-R v3.0 - ADAPTIVE COMPOUND & SMART RECOVERY
  /// Implementação CORRETA com 4 módulos
  /// ============================================
  static Map<String, dynamic> calculateACSRStake({
    required BotConfiguration config,
    required int consecutiveWins,
    required int consecutiveLosses,
    required double currentStake,
    required double lastProfit,
    required double lossAccumulated,
    required double profitBank,
    required List<String> last5Results,  // ['Over', 'Over', 'Under', 'Over', 'Over']
  }) {
    final Mc = config.consistencyMultiplier;  // Ex: 1.15
    final Mr = config.recoveryMultiplier;  // Ex: 1.25
    final F = config.confidenceFilter;  // Ex: 2 vitórias
    final minConfidence = config.patternConfidence;  // Ex: 0.6 (60%)

    double newStake;
    double newProfitBank = profitBank;
    String activeDirection = 'neutral';
    bool shouldPause = false;

    // ===== MÓDULO 1: LEITURA DE PADRÃO =====
    if (last5Results.length >= 5) {
      final patternCount = <String, int>{};
      for (var result in last5Results) {
        patternCount[result] = (patternCount[result] ?? 0) + 1;
      }
      
      final maxEntry = patternCount.entries.reduce(
        (a, b) => a.value > b.value ? a : b,
      );
      
      final confidence = maxEntry.value / 5.0;
      if (confidence >= minConfidence) {
        activeDirection = maxEntry.key;  // Ex: 'Over', 'Rise', 'Even'
      }
    }

    // ===== MÓDULO 2: EXECUÇÃO E LUCRO COMPOSTO =====
    if (consecutiveWins >= F && activeDirection != 'neutral') {
      // Adicionar metade do lucro ao stake, outra metade ao banco
      final halfProfit = lastProfit * 0.5;
      final otherHalf = lastProfit - halfProfit;
      
      newStake = (currentStake + halfProfit) * Mc;
      newProfitBank += otherHalf;
    }
    // ===== MÓDULO 3: RECUPERAÇÃO INTELIGENTE =====
    else if (consecutiveLosses > 0) {
      // Fórmula: S_next = (S_current × Mr) + (perda_acumulada × 0.3)
      newStake = (currentStake * Mr) + (lossAccumulated * 0.3);
      
      // Se houver 2 perdas consecutivas, pausar por 1 rodada
      if (consecutiveLosses >= 2) {
        shouldPause = true;
      }
    }
    // ===== INÍCIO =====
    else {
      newStake = config.initialStake;
    }

    // ===== MÓDULO 4: GESTÃO DE CICLO =====
    // (Implementado no bot_engine.dart através dos limites)

    // Limitar stake
    final minStake = max(config.initialStake, 0.35);
    final maxStake = config.maxStake ?? double.infinity;
    newStake = newStake.clamp(minStake, maxStake);

    return {
      'stake': newStake,
      'profitBank': newProfitBank,
      'activeDirection': activeDirection,
      'shouldPause': shouldPause,
    };
  }
}