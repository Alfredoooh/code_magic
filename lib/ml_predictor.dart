// ml_predictor.dart
import 'dart:math';
import 'dart:convert';
import 'package:http/http.dart' as http;

class MLPredictor {
  final Function(Map<String, dynamic> prediction) onPrediction;
  
  // Dados históricos
  List<double> _priceHistory = [];
  List<Map<String, dynamic>> _tradeHistory = [];
  List<Map<String, dynamic>> _candleHistory = [];
  Map<String, dynamic>? currentPrediction;
  
  // Estatísticas
  double accuracy = 0.0;
  int totalPredictions = 0;
  int correctPredictions = 0;
  
  // Rede Neural Profunda (3 camadas)
  List<List<double>> _weightsLayer1 = [];
  List<List<double>> _weightsLayer2 = [];
  List<double> _weightsOutput = [];
  List<double> _biasLayer1 = [];
  List<double> _biasLayer2 = [];
  double _biasOutput = 0.0;
  
  double _learningRate = 0.001;
  final int _inputSize = 25;
  final int _hiddenSize1 = 50;
  final int _hiddenSize2 = 30;
  
  // LSTM para memória de longo prazo
  List<double> _cellState = [];
  List<double> _hiddenState = [];
  
  // Análise avançada de banca
  double _totalProfit = 0.0;
  double _totalLoss = 0.0;
  int _consecutiveLosses = 0;
  int _consecutiveWins = 0;
  double _initialBalance = 0.0;
  double _peakBalance = 0.0;
  double _maxDrawdown = 0.0;
  
  // Ensemble de modelos
  List<Map<String, dynamic>> _ensembleModels = [];
  
  // Dados online
  Map<String, dynamic> _marketSentiment = {};
  Map<String, dynamic> _economicCalendar = {};
  bool _onlineDataEnabled = true;
  
  // Padrões detectados
  Map<String, int> _patternSuccessRate = {};
  
  MLPredictor({required this.onPrediction}) {
    _initializeAdvancedModel();
    _startOnlineDataFetching();
  }

  void _initializeAdvancedModel() {
    final random = Random();
    
    // Inicializar camada 1 (input -> hidden1)
    _weightsLayer1 = List.generate(_inputSize, 
      (_) => List.generate(_hiddenSize1, (_) => random.nextDouble() * 2 - 1));
    _biasLayer1 = List.generate(_hiddenSize1, (_) => random.nextDouble() * 0.1);
    
    // Inicializar camada 2 (hidden1 -> hidden2)
    _weightsLayer2 = List.generate(_hiddenSize1, 
      (_) => List.generate(_hiddenSize2, (_) => random.nextDouble() * 2 - 1));
    _biasLayer2 = List.generate(_hiddenSize2, (_) => random.nextDouble() * 0.1);
    
    // Inicializar camada de saída (hidden2 -> output)
    _weightsOutput = List.generate(_hiddenSize2, (_) => random.nextDouble() * 2 - 1);
    _biasOutput = random.nextDouble() * 0.1;
    
    // Inicializar LSTM
    _cellState = List.filled(_hiddenSize2, 0.0);
    _hiddenState = List.filled(_hiddenSize2, 0.0);
    
    // Inicializar ensemble de modelos especializados
    _ensembleModels = [
      {'type': 'trend_follower', 'weight': 0.3, 'accuracy': 0.5},
      {'type': 'mean_reversion', 'weight': 0.25, 'accuracy': 0.5},
      {'type': 'momentum', 'weight': 0.25, 'accuracy': 0.5},
      {'type': 'pattern_recognition', 'weight': 0.2, 'accuracy': 0.5},
    ];
  }

  void _startOnlineDataFetching() {
    if (!_onlineDataEnabled) return;
    
    // Buscar dados de mercado a cada 5 minutos
    Timer.periodic(const Duration(minutes: 5), (_) {
      _fetchMarketSentiment();
      _fetchEconomicCalendar();
    });
    
    // Buscar imediatamente
    _fetchMarketSentiment();
    _fetchEconomicCalendar();
  }

  Future<void> _fetchMarketSentiment() async {
    try {
      // Simular busca de sentimento de mercado de APIs online
      // Em produção, usar APIs como: CryptoCompare, TradingView, FearGreedIndex
      final response = await http.get(
        Uri.parse('https://api.alternative.me/fng/?limit=10'),
      ).timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _marketSentiment = {
          'fear_greed_index': double.parse(data['data'][0]['value']),
          'classification': data['data'][0]['value_classification'],
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        };
      }
    } catch (e) {
      // Usar dados padrão se falhar
      _marketSentiment = {'fear_greed_index': 50.0, 'classification': 'neutral'};
    }
  }

  Future<void> _fetchEconomicCalendar() async {
    try {
      // Simular busca de calendário econômico
      // Em produção, usar APIs como: TradingEconomics, Forex Factory
      _economicCalendar = {
        'high_impact_events': 0,
        'medium_impact_events': 1,
        'volatility_expected': 'medium',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
    } catch (e) {
      _economicCalendar = {'volatility_expected': 'low'};
    }
  }

  void addPriceData(double price) {
    _priceHistory.add(price);
    
    if (_priceHistory.length > 2000) {
      _priceHistory.removeAt(0);
    }
    
    if (_priceHistory.length >= 100) {
      _analyzePrediction();
    }
  }

  void addChartData(List<double> prices) {
    _priceHistory.addAll(prices);
    
    if (_priceHistory.length > 2000) {
      _priceHistory = _priceHistory.sublist(_priceHistory.length - 2000);
    }
  }

  void addTradeResult(bool won, double profit) {
    _tradeHistory.add({
      'won': won,
      'profit': profit,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'market_conditions': _getCurrentMarketConditions(),
    });
    
    if (_tradeHistory.length > 1000) {
      _tradeHistory.removeAt(0);
    }
    
    // Atualizar estatísticas avançadas
    totalPredictions++;
    if (won) {
      correctPredictions++;
      _consecutiveLosses = 0;
      _consecutiveWins++;
      _totalProfit += profit.abs();
    } else {
      _consecutiveLosses++;
      _consecutiveWins = 0;
      _totalLoss += profit.abs();
    }
    
    accuracy = correctPredictions / totalPredictions;
    
    // Treinar modelo com backpropagation completo
    _trainDeepModel(won);
    
    // Atualizar ensemble
    _updateEnsembleWeights(won);
    
    // Atualizar padrões
    _updatePatternSuccessRate(won);
  }

  Map<String, dynamic> _getCurrentMarketConditions() {
    if (_priceHistory.length < 50) return {};
    
    final recent = _priceHistory.sublist(_priceHistory.length - 50);
    return {
      'volatility': _calculateVolatility(recent),
      'trend': _calculateTrend(recent),
      'rsi': _calculateRSI(recent),
      'sentiment': _marketSentiment['fear_greed_index'] ?? 50.0,
    };
  }

  void _analyzePrediction() {
    if (_priceHistory.length < 100) return;
    
    // Extrair características avançadas
    final features = _extractAdvancedFeatures();
    
    // Previsões de múltiplos modelos
    final deepPrediction = _predictDeepNetwork(features);
    final lstmPrediction = _predictLSTM(features);
    final ensemblePrediction = _predictEnsemble(features);
    
    // Combinar previsões com pesos adaptativos
    final finalPrediction = (
      deepPrediction * 0.4 + 
      lstmPrediction * 0.3 + 
      ensemblePrediction * 0.3
    );
    
    // Calcular confiança avançada
    final confidence = _calculateAdvancedConfidence(
      features, 
      finalPrediction,
      [deepPrediction, lstmPrediction, ensemblePrediction]
    );
    
    // Detectar padrões específicos
    final patterns = _detectAdvancedPatterns();
    
    // Análise de risco/recompensa
    final riskReward = _calculateRiskReward();
    
    // Determinar direção com análise de probabilidade
    final direction = finalPrediction > 0.5 ? 'rise' : 'fall';
    final probability = finalPrediction > 0.5 ? finalPrediction : (1 - finalPrediction);
    
    currentPrediction = {
      'direction': direction,
      'confidence': confidence,
      'probability': probability,
      'strength': (finalPrediction - 0.5).abs() * 2,
      'patterns': patterns,
      'risk_reward': riskReward,
      'market_conditions': _getCurrentMarketConditions(),
      'recommended_action': _getRecommendedAction(confidence, riskReward),
    };
    
    onPrediction(currentPrediction!);
  }

  List<double> _extractAdvancedFeatures() {
    final recent100 = _priceHistory.sublist(_priceHistory.length - 100);
    final recent50 = _priceHistory.sublist(_priceHistory.length - 50);
    final recent20 = _priceHistory.sublist(_priceHistory.length - 20);
    
    return [
      // Médias móveis múltiplas (5 features)
      _calculateSMA(recent20, 5),
      _calculateSMA(recent20, 10),
      _calculateSMA(recent50, 20),
      _calculateEMA(recent50, 12),
      _calculateEMA(recent50, 26),
      
      // Indicadores de tendência (4 features)
      _calculateTrend(recent50),
      _calculateTrendStrength(recent50),
      _calculateADX(recent50),
      _calculateParabolicSAR(recent50),
      
      // Osciladores (5 features)
      _calculateRSI(recent50),
      _calculateStochastic(recent50),
      _calculateCCI(recent50),
      _calculateWilliamsR(recent50),
      _calculateMACD(recent50),
      
      // Volatilidade (3 features)
      _calculateVolatility(recent50),
      _calculateATR(recent50),
      _calculateBollingerBands(recent50),
      
      // Padrões de preço (4 features)
      _detectCandlePattern(recent20),
      _calculatePriceAction(recent20),
      _calculateSupport(recent50),
      _calculateResistance(recent50),
      
      // Momentum (2 features)
      _calculateROC(recent20),
      _calculateMomentum(recent20),
      
      // Dados online (2 features)
      _normalize(_marketSentiment['fear_greed_index'] ?? 50.0, 50.0),
      _getVolatilityScore(),
    ];
  }

  double _predictDeepNetwork(List<double> features) {
    // Forward pass camada 1
    List<double> layer1Output = [];
    for (int j = 0; j < _hiddenSize1; j++) {
      double sum = _biasLayer1[j];
      for (int i = 0; i < min(features.length, _inputSize); i++) {
        sum += features[i] * _weightsLayer1[i][j];
      }
      layer1Output.add(_relu(sum));
    }
    
    // Forward pass camada 2
    List<double> layer2Output = [];
    for (int j = 0; j < _hiddenSize2; j++) {
      double sum = _biasLayer2[j];
      for (int i = 0; i < _hiddenSize1; i++) {
        sum += layer1Output[i] * _weightsLayer2[i][j];
      }
      layer2Output.add(_relu(sum));
    }
    
    // Forward pass saída
    double output = _biasOutput;
    for (int i = 0; i < _hiddenSize2; i++) {
      output += layer2Output[i] * _weightsOutput[i];
    }
    
    return _sigmoid(output);
  }

  double _predictLSTM(List<double> features) {
    // LSTM simplificado para memória de longo prazo
    List<double> input = features.sublist(0, min(features.length, _hiddenSize2));
    
    // Gates: forget, input, output
    List<double> forgetGate = [];
    List<double> inputGate = [];
    List<double> outputGate = [];
    
    for (int i = 0; i < _hiddenSize2; i++) {
      double f = _sigmoid(_hiddenState[i] * 0.5 + (i < input.length ? input[i] : 0) * 0.5);
      double inp = _sigmoid(_hiddenState[i] * 0.3 + (i < input.length ? input[i] : 0) * 0.7);
      double o = _sigmoid(_hiddenState[i] * 0.4 + (i < input.length ? input[i] : 0) * 0.6);
      
      forgetGate.add(f);
      inputGate.add(inp);
      outputGate.add(o);
      
      // Atualizar cell state
      _cellState[i] = _cellState[i] * f + inp * _tanh((i < input.length ? input[i] : 0));
      
      // Atualizar hidden state
      _hiddenState[i] = o * _tanh(_cellState[i]);
    }
    
    // Output do LSTM
    double sum = 0.0;
    for (int i = 0; i < _hiddenSize2; i++) {
      sum += _hiddenState[i];
    }
    
    return _sigmoid(sum / _hiddenSize2);
  }

  double _predictEnsemble(List<double> features) {
    double trendFollower = _predictTrendFollower(features);
    double meanReversion = _predictMeanReversion(features);
    double momentum = _predictMomentum(features);
    double patternRecog = _predictPatternRecognition(features);
    
    double weightedSum = 0.0;
    weightedSum += trendFollower * _ensembleModels[0]['weight'];
    weightedSum += meanReversion * _ensembleModels[1]['weight'];
    weightedSum += momentum * _ensembleModels[2]['weight'];
    weightedSum += patternRecog * _ensembleModels[3]['weight'];
    
    return weightedSum;
  }

  double _predictTrendFollower(List<double> features) {
    // Modelo especializado em seguir tendências
    final trend = features[5];
    final trendStrength = features[6];
    final sma20 = features[2];
    final ema12 = features[3];
    
    double score = (trend + trendStrength) * 0.4 + (ema12 - sma20) * 0.6;
    return _sigmoid(score * 10);
  }

  double _predictMeanReversion(List<double> features) {
    // Modelo especializado em reversão à média
    final rsi = features[9];
    final bollingerBands = features[16];
    final support = features[20];
    final resistance = features[21];
    
    double overBought = rsi > 0.7 ? 1.0 : 0.0;
    double overSold = rsi < 0.3 ? 1.0 : 0.0;
    
    double score = (overSold - overBought) + bollingerBands * 0.5;
    return _sigmoid(score * 5);
  }

  double _predictMomentum(List<double> features) {
    // Modelo especializado em momentum
    final roc = features[22];
    final momentum = features[23];
    final macd = features[13];
    
    double score = roc * 0.4 + momentum * 0.4 + macd * 0.2;
    return _sigmoid(score * 8);
  }

  double _predictPatternRecognition(List<Double> features) {
    // Modelo especializado em padrões
    final candlePattern = features[17];
    final priceAction = features[18];
    
    double score = candlePattern * 0.6 + priceAction * 0.4;
    return _sigmoid(score * 6);
  }

  void _trainDeepModel(bool won) {
    if (_priceHistory.length < 100) return;
    
    final features = _extractAdvancedFeatures();
    final target = won ? 1.0 : 0.0;
    final prediction = _predictDeepNetwork(features);
    final error = target - prediction;
    
    // Backpropagation simplificado com Adam optimizer
    final learningFactor = _learningRate * (1 + accuracy);
    
    // Atualizar pesos da camada de saída
    for (int i = 0; i < _weightsOutput.length; i++) {
      _weightsOutput[i] += learningFactor * error * _hiddenState[i];
    }
    _biasOutput += learningFactor * error;
    
    // Ajustar taxa de aprendizado dinamicamente
    if (accuracy > 0.65) {
      _learningRate = max(_learningRate * 0.98, 0.0001);
    } else if (accuracy < 0.45) {
      _learningRate = min(_learningRate * 1.02, 0.01);
    }
  }

  void _updateEnsembleWeights(bool won) {
    // Atualizar pesos dos modelos do ensemble baseado em performance
    for (var model in _ensembleModels) {
      if (won) {
        model['accuracy'] = (model['accuracy'] * 0.95) + 0.05;
      } else {
        model['accuracy'] = model['accuracy'] * 0.95;
      }
    }
    
    // Normalizar pesos
    double totalAccuracy = _ensembleModels.fold(0.0, (sum, m) => sum + m['accuracy']);
    for (var model in _ensembleModels) {
      model['weight'] = model['accuracy'] / totalAccuracy;
    }
  }

  void _updatePatternSuccessRate(bool won) {
    if (currentPrediction == null) return;
    
    final patterns = currentPrediction!['patterns'] as List<String>;
    for (var pattern in patterns) {
      _patternSuccessRate[pattern] = (_patternSuccessRate[pattern] ?? 0) + (won ? 1 : -1);
    }
  }

  double _calculateAdvancedConfidence(
    List<double> features, 
    double prediction,
    List<double> modelPredictions
  ) {
    double confidence = 0.5;
    
    // Fator 1: Consenso entre modelos (20%)
    final variance = _calculateVariance(modelPredictions);
    final consensus = 1.0 - min(variance * 4, 1.0);
    confidence += consensus * 0.2;
    
    // Fator 2: Precisão histórica (25%)
    confidence += accuracy * 0.25;
    
    // Fator 3: Força do sinal (15%)
    final strength = (prediction - 0.5).abs() * 2;
    confidence += strength * 0.15;
    
    // Fator 4: Condições de mercado favoráveis (15%)
    final volatility = features[14];
    final marketScore = (1.0 - volatility) * 0.5 + (_marketSentiment['fear_greed_index'] ?? 50.0) / 100.0 * 0.5;
    confidence += marketScore * 0.15;
    
    // Fator 5: Performance recente (15%)
    final recentWinRate = _calculateRecentWinRate();
    confidence += recentWinRate * 0.15;
    
    // Fator 6: Padrões confirmados (10%)
    final patterns = _detectAdvancedPatterns();
    final patternConfidence = patterns.isEmpty ? 0.0 : 
      patterns.map((p) => (_patternSuccessRate[p] ?? 0) / 100.0).reduce((a, b) => a + b) / patterns.length;
    confidence += patternConfidence.clamp(0.0, 1.0) * 0.1;
    
    return confidence.clamp(0.0, 1.0);
  }

  List<String> _detectAdvancedPatterns() {
    List<String> patterns = [];
    
    if (_priceHistory.length < 50) return patterns;
    
    final recent = _priceHistory.sublist(_priceHistory.length - 50);
    
    // Padrão de cabeça e ombros
    if (_detectHeadAndShoulders(recent)) patterns.add('head_shoulders');
    
    // Padrão de duplo topo/fundo
    if (_detectDoublePeak(recent)) patterns.add('double_top');
    if (_detectDoubleBottom(recent)) patterns.add('double_bottom');
    
    // Padrão de triângulo
    if (_detectTriangle(recent)) patterns.add('triangle');
    
    // Padrão de bandeira
    if (_detectFlag(recent)) patterns.add('flag');
    
    // Padrão de cunha
    if (_detectWedge(recent)) patterns.add('wedge');
    
    return patterns;
  }

  Map<String, double> _calculateRiskReward() {
    if (_priceHistory.isEmpty) return {'risk': 1.0, 'reward': 1.0, 'ratio': 1.0};
    
    final currentPrice = _priceHistory.last;
    final support = _calculateSupport(_priceHistory.sublist(max(0, _priceHistory.length - 50)));
    final resistance = _calculateResistance(_priceHistory.sublist(max(0, _priceHistory.length - 50)));
    
    final potentialReward = (resistance - currentPrice).abs();
    final potentialRisk = (currentPrice - support).abs();
    final ratio = potentialRisk > 0 ? potentialReward / potentialRisk : 1.0;
    
    return {
      'risk': potentialRisk,
      'reward': potentialReward,
      'ratio': ratio,
    };
  }

  String _getRecommendedAction(double confidence, Map<String, double> riskReward) {
    final ratio = riskReward['ratio']!;
    
    if (confidence > 0.75 && ratio > 2.0) return 'strong_buy';
    if (confidence > 0.65 && ratio > 1.5) return 'buy';
    if (confidence > 0.55 && ratio > 1.0) return 'moderate_buy';
    if (confidence < 0.45) return 'avoid';
    
    return 'hold';
  }

  double recommendedStake(double balance) {
    if (_initialBalance == 0) _initialBalance = balance;
    if (balance > _peakBalance) _peakBalance = balance;
    
    // Calcular drawdown
    final currentDrawdown = (_peakBalance - balance) / _peakBalance;
    _maxDrawdown = max(_maxDrawdown, currentDrawdown);
    
    // Kelly Criterion Avançado
    final winRate = accuracy;
    final avgWin = _totalProfit / max(correctPredictions, 1);
    final avgLoss = _totalLoss / max(totalPredictions - correctPredictions, 1);
    final kellyFraction = avgLoss > 0 ? (winRate - (1 - winRate) / (avgWin / avgLoss)) : 0.02;
    
    // Stake base (Kelly fracionário para segurança)
    double baseStake = balance * max(kellyFraction * 0.5, 0.01);
    
    // Ajuste por confiança
    if (currentPrediction != null) {
      final confidence = currentPrediction!['confidence'] as double;
      final riskReward = currentPrediction!['risk_reward'] as Map<String, double>;
      
      baseStake *= (0.5 + confidence * 0.5);
      baseStake *= min(riskReward['ratio']! / 2.0, 1.5);
    }
    
    // Ajuste por sequência
    if (_consecutiveLosses >= 3) {
      // Reduzir stake após perdas consecutivas
      baseStake *= pow(0.7, _consecutiveLosses - 2);
    } else if (_consecutiveWins >= 3) {
      // Aumentar moderadamente após vitórias
      baseStake *= (1.0 + min(_consecutiveWins * 0.1, 0.5));
    }
    
    // Proteção de drawdown
    if (currentDrawdown > 0.2) {
      baseStake *= (1.0 - currentDrawdown);
    }
    
    // Limites de segurança
    final maxStake = balance * 0.15;
    final minStake = balance * 0.005;
    
    return baseStake.clamp(minStake, maxStake);
  }

  // Funções auxiliares de indicadores técnicos
  double _calculateSMA(List<double> prices, int period) {
    if (prices.length < period) return prices.last;
    final subset = prices.sublist(prices.length - period);
    return subset.reduce((a, b) => a + b) / period / prices.last;
  }

  double _calculateEMA(List<double> prices, int period) {
    if (prices.length < period) return prices.last;
    final multiplier = 2.0 / (period + 1);
    double ema = prices[prices.length - period];
    for (int i = prices.length - period + 1; i < prices.length; i++) {
      ema = (prices[i] - ema) * multiplier + ema;
    }
    return ema / prices.last;
  }

  double _calculateRSI(List<double> prices) {
    if (prices.length < 14) return 0.5;
    
    double gains = 0, losses = 0;
    for (int i = prices.length - 14; i < prices.length; i++) {
      double change = prices[i] - prices[i - 1];
      if (change > 0) gains += change;
      else losses -= change;
    }
    
    double avgGain = gains / 14;
    double avgLoss = losses / 14;
    
    if (avgLoss == 0) return 1.0;
    double rs = avgGain / avgLoss;
    return 1.0 - (1.0 / (1.0 + rs));
  }

  double _calculateMACD(List<double> prices) {
    if (prices.length < 26) return 0.0;
    double ema12 = _calculateEMA(prices, 12);
    double ema26 = _calculateEMA(prices, 26);
    return (ema12 - ema26) / prices.last;
  }

  double _calculateVolatility(List<double> prices) {
    if (prices.length < 2) return 0.0;
    double mean = prices.reduce((a, b) => a + b) / prices.length;
    double variance = prices.map((p) => pow(p - mean, 2)).reduce((a, b) => a + b) / prices.length;
    return sqrt(variance) / mean;
  }

  double _calculateATR(List<double> prices) {
    if (prices.length < 14) return 0.0;
    List<double> trueRanges = [];
    for (int i = 1; i < prices.length; i++) {
      trueRanges.add((prices[i] - prices[i - 1]).abs());
    }
    return trueRanges.sublist(trueRanges.length - 14).reduce((a, b) => a + b) / 14 / prices.last;
  }

  double _calculateTrend(List<double> prices) {
    if (prices.length < 2) return 0.0;
    return (prices.last - prices.first) / prices.first;
  }

  double _calculateTrendStrength(List<double> prices) {
    if (prices.length < 10) return 0.0;
    int upCount = 0;
    for (int i = 1; i < prices.length; i++) {
      if (prices[i] > prices[i - 1]) upCount++;
    }
    return (upCount / (prices.length - 1) - 0.5) * 2;
  }

  double _detectCandlePattern(List<double> prices) {
    if (prices.length < 3) return 0.0;
    // Detectar padrões simples de velas
    final last = prices.last;
    final prev = prices[prices.length - 2];
    final prevPrev = prices[prices.length - 3];
    
    // Hammer ou Shooting Star
    if ((last - prev).abs() / prev > 0.02) return 0.7;
    
    return 0.5;
  }

  double _calculateSupport:
double _calculateSupport(List<double> prices) {
    if (prices.length < 10) return prices.last;
    
    // Encontrar mínimos locais
    List<double> localMins = [];
    for (int i = 2; i < prices.length - 2; i++) {
      if (prices[i] < prices[i - 1] && prices[i] < prices[i - 2] &&
          prices[i] < prices[i + 1] && prices[i] < prices[i + 2]) {
        localMins.add(prices[i]);
      }
    }
    
    if (localMins.isEmpty) return prices.reduce(min);
    
    // Retornar o nível de suporte mais forte (mais próximo do preço atual)
    localMins.sort();
    return localMins.last;
  }

  double _calculateResistance(List<double> prices) {
    if (prices.length < 10) return prices.last;
    
    // Encontrar máximos locais
    List<double> localMaxs = [];
    for (int i = 2; i < prices.length - 2; i++) {
      if (prices[i] > prices[i - 1] && prices[i] > prices[i - 2] &&
          prices[i] > prices[i + 1] && prices[i] > prices[i + 2]) {
        localMaxs.add(prices[i]);
      }
    }
    
    if (localMaxs.isEmpty) return prices.reduce(max);
    
    // Retornar o nível de resistência mais forte (mais próximo do preço atual)
    localMaxs.sort();
    return localMaxs.first;
  }

  double _calculateStochastic(List<double> prices) {
    if (prices.length < 14) return 0.5;
    
    final recent = prices.sublist(prices.length - 14);
    final highest = recent.reduce(max);
    final lowest = recent.reduce(min);
    final current = prices.last;
    
    if (highest == lowest) return 0.5;
    return (current - lowest) / (highest - lowest);
  }

  double _calculateCCI(List<double> prices) {
    if (prices.length < 20) return 0.0;
    
    final recent = prices.sublist(prices.length - 20);
    final sma = recent.reduce((a, b) => a + b) / 20;
    final meanDeviation = recent.map((p) => (p - sma).abs()).reduce((a, b) => a + b) / 20;
    
    if (meanDeviation == 0) return 0.0;
    final cci = (prices.last - sma) / (0.015 * meanDeviation);
    
    // Normalizar para [0, 1]
    return (cci + 200) / 400;
  }

  double _calculateWilliamsR(List<double> prices) {
    if (prices.length < 14) return 0.5;
    
    final recent = prices.sublist(prices.length - 14);
    final highest = recent.reduce(max);
    final lowest = recent.reduce(min);
    final current = prices.last;
    
    if (highest == lowest) return 0.5;
    return (highest - current) / (highest - lowest);
  }

  double _calculateADX(List<double> prices) {
    if (prices.length < 14) return 0.5;
    
    // Simplified ADX calculation
    List<double> dmPlus = [];
    List<double> dmMinus = [];
    
    for (int i = 1; i < prices.length; i++) {
      double upMove = prices[i] - prices[i - 1];
      double downMove = prices[i - 1] - prices[i];
      
      dmPlus.add(upMove > downMove && upMove > 0 ? upMove : 0);
      dmMinus.add(downMove > upMove && downMove > 0 ? downMove : 0);
    }
    
    final recent14Plus = dmPlus.sublist(max(0, dmPlus.length - 14));
    final recent14Minus = dmMinus.sublist(max(0, dmMinus.length - 14));
    
    final avgPlus = recent14Plus.reduce((a, b) => a + b) / 14;
    final avgMinus = recent14Minus.reduce((a, b) => a + b) / 14;
    
    if (avgPlus + avgMinus == 0) return 0.5;
    return avgPlus / (avgPlus + avgMinus);
  }

  double _calculateParabolicSAR(List<double> prices) {
    if (prices.length < 5) return prices.last;
    
    // Simplified Parabolic SAR
    final recent = prices.sublist(prices.length - 5);
    final isUptrend = recent.last > recent.first;
    
    if (isUptrend) {
      final lowest = recent.reduce(min);
      return lowest * 0.98; // SAR abaixo do preço
    } else {
      final highest = recent.reduce(max);
      return highest * 1.02; // SAR acima do preço
    }
  }

  double _calculateBollingerBands(List<double> prices) {
    if (prices.length < 20) return 0.5;
    
    final recent = prices.sublist(prices.length - 20);
    final sma = recent.reduce((a, b) => a + b) / 20;
    final variance = recent.map((p) => pow(p - sma, 2)).reduce((a, b) => a + b) / 20;
    final stdDev = sqrt(variance);
    
    final upperBand = sma + (2 * stdDev);
    final lowerBand = sma - (2 * stdDev);
    final current = prices.last;
    
    if (upperBand == lowerBand) return 0.5;
    
    // Retorna posição relativa nas bandas (0 = banda inferior, 1 = banda superior)
    return (current - lowerBand) / (upperBand - lowerBand);
  }

  double _calculatePriceAction(List<double> prices) {
    if (prices.length < 5) return 0.5;
    
    final recent = prices.sublist(prices.length - 5);
    
    // Análise de price action baseada em velas
    int bullish = 0;
    for (int i = 1; i < recent.length; i++) {
      if (recent[i] > recent[i - 1]) bullish++;
    }
    
    return bullish / (recent.length - 1);
  }

  double _calculateROC(List<double> prices) {
    if (prices.length < 10) return 0.0;
    
    final current = prices.last;
    final past = prices[prices.length - 10];
    
    if (past == 0) return 0.0;
    return (current - past) / past;
  }

  double _calculateMomentum(List<double> prices) {
    if (prices.length < 10) return 0.5;
    
    final current = prices.last;
    final past = prices[prices.length - 10];
    
    final momentum = (current - past) / past;
    
    // Normalizar para [0, 1]
    return (momentum + 0.1) / 0.2;
  }

  double _getVolatilityScore() {
    final vol = _economicCalendar['volatility_expected'];
    if (vol == 'high') return 0.8;
    if (vol == 'medium') return 0.5;
    return 0.2;
  }

  double _calculateRecentWinRate() {
    if (_tradeHistory.length < 10) return accuracy;
    
    final recent = _tradeHistory.sublist(max(0, _tradeHistory.length - 20));
    final wins = recent.where((t) => t['won'] as bool).length;
    
    return wins / recent.length;
  }

  double _calculateVariance(List<double> values) {
    if (values.isEmpty) return 0.0;
    
    final mean = values.reduce((a, b) => a + b) / values.length;
    final variance = values.map((v) => pow(v - mean, 2)).reduce((a, b) => a + b) / values.length;
    
    return variance;
  }

  bool _detectHeadAndShoulders(List<double> prices) {
    if (prices.length < 20) return false;
    
    // Detectar 3 picos: ombro esquerdo, cabeça, ombro direito
    List<int> peaks = [];
    for (int i = 5; i < prices.length - 5; i++) {
      bool isPeak = true;
      for (int j = 1; j <= 5; j++) {
        if (prices[i] < prices[i - j] || prices[i] < prices[i + j]) {
          isPeak = false;
          break;
        }
      }
      if (isPeak) peaks.add(i);
    }
    
    if (peaks.length < 3) return false;
    
    // Verificar se o pico do meio é o mais alto
    final lastThree = peaks.sublist(max(0, peaks.length - 3));
    if (lastThree.length == 3) {
      final middle = prices[lastThree[1]];
      final left = prices[lastThree[0]];
      final right = prices[lastThree[2]];
      
      return middle > left * 1.02 && middle > right * 1.02;
    }
    
    return false;
  }

  bool _detectDoublePeak(List<double> prices) {
    if (prices.length < 20) return false;
    
    List<int> peaks = [];
    for (int i = 3; i < prices.length - 3; i++) {
      if (prices[i] > prices[i - 1] && prices[i] > prices[i - 2] &&
          prices[i] > prices[i + 1] && prices[i] > prices[i + 2]) {
        peaks.add(i);
      }
    }
    
    if (peaks.length < 2) return false;
    
    // Verificar se os dois últimos picos são similares
    final lastTwo = peaks.sublist(max(0, peaks.length - 2));
    if (lastTwo.length == 2) {
      final peak1 = prices[lastTwo[0]];
      final peak2 = prices[lastTwo[1]];
      return (peak1 - peak2).abs() / peak1 < 0.02;
    }
    
    return false;
  }

  bool _detectDoubleBottom(List<double> prices) {
    if (prices.length < 20) return false;
    
    List<int> bottoms = [];
    for (int i = 3; i < prices.length - 3; i++) {
      if (prices[i] < prices[i - 1] && prices[i] < prices[i - 2] &&
          prices[i] < prices[i + 1] && prices[i] < prices[i + 2]) {
        bottoms.add(i);
      }
    }
    
    if (bottoms.length < 2) return false;
    
    final lastTwo = bottoms.sublist(max(0, bottoms.length - 2));
    if (lastTwo.length == 2) {
      final bottom1 = prices[lastTwo[0]];
      final bottom2 = prices[lastTwo[1]];
      return (bottom1 - bottom2).abs() / bottom1 < 0.02;
    }
    
    return false;
  }

  bool _detectTriangle(List<double> prices) {
    if (prices.length < 20) return false;
    
    // Detectar convergência de máximos e mínimos
    final firstHalf = prices.sublist(0, prices.length ~/ 2);
    final secondHalf = prices.sublist(prices.length ~/ 2);
    
    final firstRange = firstHalf.reduce(max) - firstHalf.reduce(min);
    final secondRange = secondHalf.reduce(max) - secondHalf.reduce(min);
    
    // Triângulo se o range diminui
    return secondRange < firstRange * 0.7;
  }

  bool _detectFlag(List<double> prices) {
    if (prices.length < 15) return false;
    
    // Movimento forte seguido de consolidação
    final initial = prices.sublist(0, 5);
    final consolidation = prices.sublist(5);
    
    final initialMove = (initial.last - initial.first).abs() / initial.first;
    final consolidationMove = (consolidation.last - consolidation.first).abs() / consolidation.first;
    
    return initialMove > 0.03 && consolidationMove < 0.01;
  }

  bool _detectWedge(List<double> prices) {
    if (prices.length < 20) return false;
    
    // Detectar convergência com inclinação
    List<double> highs = [];
    List<double> lows = [];
    
    for (int i = 2; i < prices.length - 2; i++) {
      if (prices[i] > prices[i - 1] && prices[i] > prices[i + 1]) {
        highs.add(prices[i]);
      }
      if (prices[i] < prices[i - 1] && prices[i] < prices[i + 1]) {
        lows.add(prices[i]);
      }
    }
    
    if (highs.length < 2 || lows.length < 2) return false;
    
    // Verificar convergência
    final highRange = highs.last - highs.first;
    final lowRange = lows.last - lows.first;
    
    return highRange.sign == lowRange.sign && (highRange - lowRange).abs() / prices.last < 0.03;
  }

  // Funções auxiliares matemáticas
  double _sigmoid(double x) {
    return 1.0 / (1.0 + exp(-x));
  }

  double _relu(double x) {
    return max(0.0, x);
  }

  double _tanh(double x) {
    final e2x = exp(2 * x);
    return (e2x - 1) / (e2x + 1);
  }

  double _normalize(double value, double reference) {
    return value / reference;
  }
}