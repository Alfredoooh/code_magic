// bot_strategies.dart - ESTRATÉGIAS COMPLETAS E FUNCIONAIS
import 'dart:math';
import 'bot_configuration.dart';

class BotStrategies {
  // ============================================
  // 1. MARTINGALE PRO (Original - Mantido)
  // ============================================
  static double calculateMartingaleStake({
    required BotConfiguration config,
    required int consecutiveLosses,
    required double lossStreakAmount,
  }) {
    if (consecutiveLosses == 0) return config.initialStake;

    final payout = config.estimatedPayout;
    final recoveryStake = lossStreakAmount / payout;
    final safetyMargin = 1.1;
    
    return recoveryStake * safetyMargin;
  }

  // ============================================
  // 2. PROGRESSIVE REINVESTMENT (Reinvestimento Progressivo)
  // ============================================
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
    final N = config.roundsPerCycle; // Rodadas por ciclo
    final R = config.estimatedPayout; // Retorno por operação
    final L = config.extraProfitPercent / 100; // Lucro extra

    double newStake;
    int newCycle = currentCycle;
    int newRound = currentRound;
    bool startNewCycle = false;

    // Se última operação foi vitória
    if (lastTradeWon) {
      newRound++;
      
      // Reinvestir: stake + lucro
      newStake = lastStake + lastProfit;

      // Verificar se completou o ciclo
      if (newRound >= N) {
        // Ciclo completo com sucesso
        newCycle++;
        newRound = 0;
        startNewCycle = true;
        
        // Verificar se atingiu total de ciclos
        if (newCycle >= config.totalCycles) {
          newStake = config.initialStake; // Reset
          newCycle = 0;
        } else {
          newStake = config.initialStake; // Novo ciclo com stake base
        }
      }
    } 
    // Se última operação foi perda
    else {
      // Ciclo interrompido - Recalcular stake para recuperação
      final P = totalLossesInCycle + lastStake; // Total perdido
      
      if (config.autoRecovery && P > 0) {
        // Fórmula: S₀' = P × (1 + L%) / ((R^N) - 1)
        final denominator = pow(1 + R, N) - 1;
        
        if (denominator > 0) {
          newStake = (P * (1 + L)) / denominator;
        } else {
          newStake = P * 1.5; // Fallback seguro
        }
        
        // Aplicar limite de stake máximo
        if (config.maxStake != null && newStake > config.maxStake!) {
          newStake = config.maxStake!;
        }
      } else {
        newStake = config.initialStake;
      }

      // Reiniciar ciclo
      newRound = 0;
      startNewCycle = true;
    }

    // Garantir stake mínimo
    if (newStake < config.initialStake) {
      newStake = config.initialStake;
    }

    return {
      'stake': newStake,
      'cycle': newCycle,
      'round': newRound,
      'newCycle': startNewCycle,
      'cycleStartStake': startNewCycle ? newStake : cycleStartStake,
    };
  }

  // ============================================
  // 3. TRENDY ADAPTIVE (Lucro por Tendência)
  // ============================================
  static Map<String, dynamic> calculateTrendyAdaptiveStake({
    required BotConfiguration config,
    required int consecutiveWins,
    required int consecutiveLosses,
    required double currentStake,
    required double lastProfit,
    required bool trendDetected,
    required double profitBank,
    required String phase,
  }) {
    final Mt = config.trendMultiplier; // Multiplicador de tendência
    final Mr = config.recoveryMultiplier; // Multiplicador de recuperação
    final F = config.trendFilter; // Filtro de confirmação
    final reinvestPercent = config.profitReinvestPercent / 100;

    double newStake;
    bool newTrendDetected = trendDetected;
    double newProfitBank = profitBank;
    String newPhase = phase;

    // FASE 1: OBSERVAÇÃO
    if (phase == 'observation') {
      if (consecutiveWins >= F) {
        // Tendência confirmada
        newTrendDetected = true;
        newPhase = 'execution';
        newStake = config.initialStake * Mt;
      } else {
        newStake = config.initialStake;
      }
    }
    
    // FASE 2: EXECUÇÃO (Tendência Confirmada)
    else if (phase == 'execution') {
      if (consecutiveWins > 0) {
        // Vitória: reinvestir parte do lucro
        final reinvestAmount = lastProfit * reinvestPercent;
        final savedProfit = lastProfit - reinvestAmount;
        
        newProfitBank += savedProfit;
        newStake = (currentStake + reinvestAmount) * Mt;
      } else {
        // Perda: entrar em recuperação
        newPhase = 'recovery';
        newStake = currentStake * Mr;
        newTrendDetected = false;
      }
    }
    
    // FASE 3: RECUPERAÇÃO
    else if (phase == 'recovery') {
      if (consecutiveWins >= 1) {
        // Voltar para observação
        newPhase = 'observation';
        newStake = config.initialStake;
        newTrendDetected = false;
      } else {
        // Continuar recuperação
        newStake = currentStake * Mr;
      }
    } else {
      // Fallback
      newStake = config.initialStake;
      newPhase = 'observation';
    }

    // Aplicar limites
    if (config.maxStake != null && newStake > config.maxStake!) {
      newStake = config.maxStake!;
    }
    if (newStake < config.initialStake) {
      newStake = config.initialStake;
    }

    return {
      'stake': newStake,
      'trendDetected': newTrendDetected,
      'profitBank': newProfitBank,
      'phase': newPhase,
    };
  }

  // ============================================
  // 4. ADAPTIVE COMPOUND & SMART RECOVERY (ACS-R v3.0)
  // ============================================
  static Map<String, dynamic> calculateACSRStake({
    required BotConfiguration config,
    required int consecutiveWins,
    required int consecutiveLosses,
    required double currentStake,
    required double lastProfit,
    required double lossAccumulated,
    required double profitBank,
    required List<String> last5Results,
  }) {
    final Mr = config.recoveryMultiplier; // Multiplicador de recuperação
    final Mc = config.consistencyMultiplier; // Multiplicador de consistência
    final F = config.confidenceFilter; // Filtro de confiança
    final minConfidence = config.patternConfidence;

    double newStake;
    double newProfitBank = profitBank;
    String activeDirection = 'neutral';
    bool shouldPause = false;

    // MÓDULO 1: LEITURA DE PADRÃO
    if (last5Results.length >= 3) {
      final pattern = _analyzePattern(last5Results);
      
      if (pattern['confidence'] >= minConfidence) {
        activeDirection = pattern['direction'];
      }
    }

    // MÓDULO 2: EXECUÇÃO E LUCRO COMPOSTO
    if (consecutiveWins >= F && activeDirection != 'neutral') {
      // Direção confirmada - aumentar stake
      if (consecutiveWins > 0) {
        // Vitória: lucro composto parcial
        final reinvestAmount = lastProfit * 0.5;
        final savedProfit = lastProfit * 0.5;
        
        newProfitBank += savedProfit;
        newStake = (currentStake + reinvestAmount) * Mc;
      } else {
        newStake = currentStake;
      }
    }
    
    // MÓDULO 3: RECUPERAÇÃO INTELIGENTE
    else if (consecutiveLosses > 0) {
      if (consecutiveLosses >= 2) {
        // Pausar e reanalizar após 2 perdas
        shouldPause = true;
        newStake = config.initialStake * Mr;
      } else {
        // Recuperação suave
        final adjustedStake = (currentStake * Mr) + (lossAccumulated * 0.3);
        newStake = adjustedStake;
      }
    }
    
    // Caso padrão
    else {
      newStake = config.initialStake;
    }

    // MÓDULO 4: GESTÃO DE CICLO (aplicado externamente)
    // Aplicar limites
    if (config.maxStake != null && newStake > config.maxStake!) {
      newStake = config.maxStake!;
    }
    if (newStake < config.initialStake) {
      newStake = config.initialStake;
    }

    return {
      'stake': newStake,
      'profitBank': newProfitBank,
      'activeDirection': activeDirection,
      'shouldPause': shouldPause,
    };
  }

  // ============================================
  // FUNÇÃO AUXILIAR: ANÁLISE DE PADRÃO
  // ============================================
  static Map<String, dynamic> _analyzePattern(List<String> results) {
    if (results.isEmpty) {
      return {'confidence': 0.0, 'direction': 'neutral'};
    }

    // Contar ocorrências
    final counts = <String, int>{};
    for (var result in results) {
      counts[result] = (counts[result] ?? 0) + 1;
    }

    // Encontrar padrão dominante
    var maxCount = 0;
    var dominantDirection = 'neutral';
    
    counts.forEach((direction, count) {
      if (count > maxCount) {
        maxCount = count;
        dominantDirection = direction;
      }
    });

    // Calcular confiança
    final confidence = maxCount / results.length;

    return {
      'confidence': confidence,
      'direction': dominantDirection,
    };
  }

  // ============================================
  // VALIDAÇÃO DE CONFIGURAÇÃO
  // ============================================
  static bool validateConfiguration(BotConfiguration config) {
    if (config.initialStake < 0.35) return false;
    if (config.maxStake != null && config.maxStake! < config.initialStake) return false;
    if (config.targetProfit <= 0) return false;
    if (config.maxLoss <= 0) return false;
    
    // Validações específicas por estratégia
    switch (config.strategy) {
      case BotStrategy.progressiveReinvestment:
        if (config.roundsPerCycle < 1) return false;
        if (config.totalCycles < 1) return false;
        break;
        
      case BotStrategy.trendyAdaptive:
        if (config.trendMultiplier < 1.0) return false;
        if (config.trendFilter < 1) return false;
        break;
        
      case BotStrategy.adaptiveCompoundRecovery:
        if (config.consistencyMultiplier < 1.0) return false;
        if (config.patternConfidence < 0 || config.patternConfidence > 1) return false;
        break;
        
      default:
        break;
    }
    
    return true;
  }
}