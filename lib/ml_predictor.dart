// ml_predictor.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// MLPredictor
/// - Mantive a interface pública (constructor, métodos) exatamente como no seu ficheiro original.
/// - Adicionei: setMarket(String) para adaptar fontes externas por símbolo,
///   persistência automática do estado do modelo em arquivo JSON,
///   e protecções adicionais para erros de rede/IO.
///
/// Nota: para persistência é usado path_provider; adicione em pubspec.yaml:
///   path_provider: ^2.0.0
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

  // Rede Neural Profunda (simplificada)
  List<List<double>> _weightsLayer1 = [];
  List<List<double>> _weightsLayer2 = [];
  List<double> _weightsOutput = [];
  List<double> _biasLayer1 = [];
  List<double> _biasLayer2 = [];
  double _biasOutput = 0.0;

  double _learningRate = 0.001;
  final int _inputSize = 25; // mantém o mesmo contrato de features
  final int _hiddenSize1 = 48;
  final int _hiddenSize2 = 24;

  // LSTM simplificado
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

  // Timers para fetch online (controlar cancelamento)
  Timer? _onlineTimer;

  // Persistência
  int _autosaveCounter = 0;
  final int _autosaveEvery = 10; // salvar a cada N atualizações de trade
  String _persistFileName = 'ml_model_state.json';

  // Símbolo/mercado atual (novo)
  String? _currentMarketSymbol;

  // -- Indices das features (para evitar confusão com índices numéricos espalhados) --
  static const int FI_SMA5 = 0;
  static const int FI_SMA10 = 1;
  static const int FI_SMA20 = 2;
  static const int FI_EMA12 = 3;
  static const int FI_EMA26 = 4;
  static const int FI_TREND = 5;
  static const int FI_TREND_STRENGTH = 6;
  static const int FI_ADX = 7;
  static const int FI_PARABOLIC_SAR = 8;
  static const int FI_RSI = 9;
  static const int FI_STOCH = 10;
  static const int FI_CCI = 11;
  static const int FI_WILLIAMS = 12;
  static const int FI_MACD = 13;
  static const int FI_VOLATILITY = 14;
  static const int FI_ATR = 15;
  static const int FI_BB = 16;
  static const int FI_CANDLE_PATTERN = 17;
  static const int FI_PRICE_ACTION = 18;
  static const int FI_SUPPORT = 19;
  static const int FI_RESISTANCE = 20;
  static const int FI_ROC = 21;
  static const int FI_MOMENTUM = 22;
  static const int FI_FEAR_GREED = 23;
  static const int FI_VOL_SCORE = 24;

  MLPredictor({required this.onPrediction}) {
    _initializeAdvancedModel();
    // carregar estado persistido (não bloqueante)
    _loadPersistedState();
    _startOnlineDataFetching();
  }

  // Permite ativar/desativar fetch online sem alterar constructor
  set onlineDataEnabled(bool v) {
    _onlineDataEnabled = v;
    if (!v) {
      _onlineTimer?.cancel();
      _onlineTimer = null;
    } else {
      _startOnlineDataFetching();
    }
  }

  bool get onlineDataEnabled => _onlineDataEnabled;

  /// PUBLIC: informar qual símbolo/mercado está sendo analisado
  /// - Ajusta automaticamente se deve usar dados externos (CoinGecko/Fear&Greed)
  /// - Limpa histórico para evitar poluição entre mercados (opcional)
  void setMarket(String marketSymbol, {bool clearHistory = true}) {
    _currentMarketSymbol = marketSymbol;
    final s = marketSymbol.toUpperCase();

    // Heurística simples para detectar synthetic/volatility/boom/crash
    final isSynthetic = s.startsWith('R_') ||
        s.contains('VOL') ||
        s.contains('BOOM') ||
        s.contains('CRASH') ||
        s.startsWith('SYNTHETIC') ||
        s.contains('1HZ') ||
        s.contains('SYN');

    // Desliga dados externos para synthetic (ruído)
    onlineDataEnabled = !isSynthetic;

    if (clearHistory) {
      _priceHistory.clear();
      _tradeHistory.clear();
      currentPrediction = null;
    }
  }

  void _initializeAdvancedModel() {
    final random = Random();

    // Inicializar camada 1 (input -> hidden1)
    _weightsLayer1 = List.generate(_inputSize,
        (_) => List.generate(_hiddenSize1, (_) => (random.nextDouble() * 2 - 1) * 0.1));
    _biasLayer1 = List.generate(_hiddenSize1, (_) => (random.nextDouble() - 0.5) * 0.01);

    // Inicializar camada 2 (hidden1 -> hidden2)
    _weightsLayer2 = List.generate(_hiddenSize1,
        (_) => List.generate(_hiddenSize2, (_) => (random.nextDouble() * 2 - 1) * 0.1));
    _biasLayer2 = List.generate(_hiddenSize2, (_) => (random.nextDouble() - 0.5) * 0.01);

    // Inicializar camada de saída (hidden2 -> output)
    _weightsOutput = List.generate(_hiddenSize2, (_) => (random.nextDouble() * 2 - 1) * 0.1);
    _biasOutput = (random.nextDouble() - 0.5) * 0.01;

    // Inicializar LSTM
    _cellState = List.filled(_hiddenSize2, 0.0);
    _hiddenState = List.filled(_hiddenSize2, 0.0);

    // Inicializar ensemble de modelos especializados com pesos equilibrados
    _ensembleModels = [
      {'type': 'trend_follower', 'weight': 0.25, 'accuracy': 0.5},
      {'type': 'mean_reversion', 'weight': 0.25, 'accuracy': 0.5},
      {'type': 'momentum', 'weight': 0.25, 'accuracy': 0.5},
      {'type': 'pattern_recognition', 'weight': 0.25, 'accuracy': 0.5},
    ];
  }

  void _startOnlineDataFetching() {
    // Cancela timer anterior
    _onlineTimer?.cancel();
    if (!_onlineDataEnabled) return;

    // Buscar dados de mercado a cada 3 minutos (mais responsivo)
    _onlineTimer = Timer.periodic(const Duration(minutes: 3), (_) async {
      await _fetchMarketSentiment();
      await _fetchEconomicCalendar();
    });

    // Buscar imediatamente (não aguardando)
    _fetchMarketSentiment();
    _fetchEconomicCalendar();
  }

  Future<void> _fetchMarketSentiment() async {
    if (!_onlineDataEnabled) return;
    try {
      // Fear & Greed (Crypto)
      final fngResp = await http
          .get(Uri.parse('https://api.alternative.me/fng/?limit=1'))
          .timeout(const Duration(seconds: 5));
      if (fngResp.statusCode == 200) {
        final data = json.decode(fngResp.body);
        final entry = data['data'] != null && data['data'].isNotEmpty ? data['data'][0] : null;
        final val = entry != null ? double.tryParse(entry['value'].toString()) ?? 50.0 : 50.0;
        _marketSentiment = {
          'fear_greed_index': val.clamp(0.0, 100.0),
          'classification': entry != null ? entry['value_classification'] : 'neutral',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        };
      }
      // Complemento: CoinGecko market data for momentum / volume (opcional)
      final cgResp = await http
          .get(Uri.parse(
              'https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&ids=bitcoin,ethereum&order=market_cap_desc&per_page=2&page=1&sparkline=false'))
          .timeout(const Duration(seconds: 5));
      if (cgResp.statusCode == 200) {
        final list = json.decode(cgResp.body) as List<dynamic>;
        if (list.isNotEmpty) {
          double avgChange = 0.0;
          int count = 0;
          for (var item in list) {
            final ch = (item['price_change_percentage_24h'] ?? 0.0);
            avgChange += (ch is num ? ch.toDouble() : 0.0);
            count++;
          }
          if (count > 0) avgChange /= count;
          _marketSentiment['coingecko_24h_pct'] = avgChange;
        }
      }
    } catch (e) {
      // fallback silencioso
      _marketSentiment = _marketSentiment.isNotEmpty
          ? _marketSentiment
          : {'fear_greed_index': 50.0, 'classification': 'neutral'};
    }
  }

  Future<void> _fetchEconomicCalendar() async {
    if (!_onlineDataEnabled) return;
    try {
      _economicCalendar = {
        'high_impact_events': 0,
        'medium_impact_events': 0,
        'volatility_expected': 'medium',
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
    } catch (e) {
      _economicCalendar = {'volatility_expected': 'medium'};
    }
  }

  // API pública: adiciona um preço (tick)
  void addPriceData(double price) {
    _priceHistory.add(price);

    // manter buffer limitado
    if (_priceHistory.length > 2000) {
      _priceHistory.removeRange(0, _priceHistory.length - 2000);
    }

    // lançar análise quando houver dados suficientes
    if (_priceHistory.length >= 100) {
      try {
        _analyzePrediction();
      } catch (e) {
        // não interromper fluxo por erro interno
      }
    }
  }

  // API pública: adicionar uma sequência de preços (ex: candles fechados)
  void addChartData(List<double> prices) {
    if (prices.isEmpty) return;
    _priceHistory.addAll(prices);
    if (_priceHistory.length > 2000) {
      _priceHistory = _priceHistory.sublist(_priceHistory.length - 2000);
    }
    if (_priceHistory.length >= 100) {
      try {
        _analyzePrediction();
      } catch (e) {}
    }
  }

  // API pública: adicionar resultado de trade (mantive assinatura)
  void addTradeResult(bool won, double profit) {
    _tradeHistory.add({
      'won': won,
      'profit': profit,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'market_conditions': _getCurrentMarketConditions(),
    });

    if (_tradeHistory.length > 1000) _tradeHistory.removeAt(0);

    // Atualizar estatísticas
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
    accuracy = correctPredictions / max(totalPredictions, 1);

    // Treinar modelo (simplificado) com base no resultado
    try {
      _trainDeepModel(won);
    } catch (e) {}

    // Atualizar ensemble e padrões
    _updateEnsembleWeights(won);
    _updatePatternSuccessRate(won);

    // Persistência automática (salva cada N updates)
    _autosaveCounter++;
    if (_autosaveCounter >= _autosaveEvery) {
      _autosaveCounter = 0;
      _persistStateToFile(); // não await para não bloquear
    }
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

    final features = _extractAdvancedFeatures();

    final deepPrediction = _predictDeepNetwork(features);
    final lstmPrediction = _predictLSTM(features);
    final ensemblePrediction = _predictEnsemble(features);

    // Combinar previsões com pesos adaptativos
    final finalPrediction = (deepPrediction * 0.45 + lstmPrediction * 0.25 + ensemblePrediction * 0.30);

    final confidence = _calculateAdvancedConfidence(features, finalPrediction, [
      deepPrediction,
      lstmPrediction,
      ensemblePrediction
    ]);

    final patterns = _detectAdvancedPatterns();

    final riskReward = _calculateRiskReward();

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

    // Emitir callback público
    try {
      onPrediction(currentPrediction!);
    } catch (e) {
      // Não quebrar se o listener falhar
    }
  }

  // Extrai exatamente 25 features (normalizadas onde faz sentido)
  List<double> _extractAdvancedFeatures() {
    final prices = _priceHistory;
    final len = prices.length;
    final recent100 = prices.sublist(max(0, len - 100));
    final recent50 = prices.sublist(max(0, len - 50));
    final recent20 = prices.sublist(max(0, len - 20));
    final last = prices.isNotEmpty ? prices.last : 1.0;

    double safeNorm(double value, double ref) {
      if (ref == 0) return 0.0;
      return (value / ref).clamp(-10.0, 10.0); // corta extremos
    }

    final sma5 = _calculateSMA(recent20, 5);
    final sma10 = _calculateSMA(recent20, 10);
    final sma20 = _calculateSMA(recent50, 20);
    final ema12 = _calculateEMA(recent50, 12);
    final ema26 = _calculateEMA(recent50, 26);
    final trend = _calculateTrend(recent50);
    final trendStrength = _calculateTrendStrength(recent50);
    final adx = _calculateADX(recent50);
    final sar = _calculateParabolicSAR(recent50);
    final rsi = _calculateRSI(recent50);
    final stoch = _calculateStochastic(recent50);
    final cci = _calculateCCI(recent50);
    final williams = _calculateWilliamsR(recent50);
    final macd = _calculateMACD(recent50);
    final vol = _calculateVolatility(recent50);
    final atr = _calculateATR(recent50);
    final bb = _calculateBollingerBands(recent50);
    final candlePattern = _detectCandlePattern(recent20);
    final priceAction = _calculatePriceAction(recent20);
    final support = _calculateSupport(recent50);
    final resistance = _calculateResistance(recent50);
    final roc = _calculateROC(recent20);
    final momentum = _calculateMomentum(recent20);
    final fear = (_marketSentiment['fear_greed_index'] as num?)?.toDouble() ?? 50.0;
    final volScore = _getVolatilityScore();

    return [
      safeNorm(sma5, last),
      safeNorm(sma10, last),
      safeNorm(sma20, last),
      safeNorm(ema12, last),
      safeNorm(ema26, last),
      trend.clamp(-1.0, 1.0),
      trendStrength.clamp(-1.0, 1.0),
      adx.clamp(0.0, 1.0),
      (sar / 2.0).clamp(0.0, 2.0),
      rsi.clamp(0.0, 1.0),
      stoch.clamp(0.0, 1.0),
      cci.clamp(-1.0, 1.0),
      williams.clamp(-1.0, 1.0),
      macd.clamp(-5.0, 5.0) / 5.0,
      vol.clamp(0.0, 1.0),
      atr.clamp(0.0, 1.0),
      bb.clamp(0.0, 1.0),
      candlePattern.clamp(0.0, 1.0),
      priceAction.clamp(0.0, 1.0),
      safeNorm(support, last),
      safeNorm(resistance, last),
      roc.clamp(-1.0, 1.0),
      momentum.clamp(-1.0, 1.0),
      (fear / 100.0).clamp(0.0, 1.0),
      volScore.clamp(0.0, 1.0),
    ];
  }

  double _predictDeepNetwork(List<double> features) {
    final nInput = min(features.length, _inputSize);
    List<double> layer1Output = List.filled(_hiddenSize1, 0.0);
    for (int j = 0; j < _hiddenSize1; j++) {
      double sum = _biasLayer1[j];
      for (int i = 0; i < nInput; i++) {
        sum += features[i] * _weightsLayer1[i][j];
      }
      layer1Output[j] = _relu(sum);
    }

    List<double> layer2Output = List.filled(_hiddenSize2, 0.0);
    for (int j = 0; j < _hiddenSize2; j++) {
      double sum = _biasLayer2[j];
      for (int i = 0; i < _hiddenSize1; i++) {
        sum += layer1Output[i] * _weightsLayer2[i][j];
      }
      layer2Output[j] = _relu(sum);
    }

    double output = _biasOutput;
    for (int i = 0; i < _hiddenSize2; i++) {
      output += layer2Output[i] * _weightsOutput[i];
    }

    return _sigmoid(output);
  }

  double _predictLSTM(List<double> features) {
    final input = features.sublist(0, min(features.length, _hiddenSize2));
    for (int i = 0; i < _hiddenSize2; i++) {
      final x = (i < input.length ? input[i] : 0.0);
      final f = _sigmoid(0.2 * _hiddenState[i] + 0.8 * x);
      final inp = _sigmoid(0.1 * _hiddenState[i] + 0.9 * x);
      final o = _sigmoid(0.3 * _hiddenState[i] + 0.7 * x);
      _cellState[i] = _cellState[i] * f + inp * _tanh(x);
      _hiddenState[i] = o * _tanh(_cellState[i]);
    }
    double sum = 0.0;
    for (var v in _hiddenState) sum += v;
    return _sigmoid(sum / max(1, _hiddenState.length));
  }

  double _predictEnsemble(List<double> features) {
    final trendFollower = _predictTrendFollower(features);
    final meanReversion = _predictMeanReversion(features);
    final momentum = _predictMomentum(features);
    final patternRecog = _predictPatternRecognition(features);

    double weightedSum = 0.0;
    weightedSum += trendFollower * _ensembleModels[0]['weight'];
    weightedSum += meanReversion * _ensembleModels[1]['weight'];
    weightedSum += momentum * _ensembleModels[2]['weight'];
    weightedSum += patternRecog * _ensembleModels[3]['weight'];

    return weightedSum.clamp(0.0, 1.0);
  }

  double _predictTrendFollower(List<double> features) {
    final trend = features[FI_TREND];
    final trendStrength = features[FI_TREND_STRENGTH];
    final sma20 = features[FI_SMA20];
    final ema12 = features[FI_EMA12];

    double score = (trend + trendStrength) * 0.4 + (ema12 - sma20) * 0.6;
    return _sigmoid(score * 3.0);
  }

  double _predictMeanReversion(List<double> features) {
    final rsi = features[FI_RSI];
    final bb = features[FI_BB];
    final support = features[FI_SUPPORT];
    final resistance = features[FI_RESISTANCE];

    double overBought = rsi > 0.8 ? 1.0 : 0.0;
    double overSold = rsi < 0.2 ? 1.0 : 0.0;
    double score = (overSold - overBought) + (0.5 - (bb - 0.5)).abs() * 0.5;
    return _sigmoid(score * 4.0);
  }

  double _predictMomentum(List<double> features) {
    final roc = features[FI_ROC];
    final momentum = features[FI_MOMENTUM];
    final macd = features[FI_MACD];

    double score = roc * 0.45 + momentum * 0.35 + macd * 0.2;
    return _sigmoid(score * 3.5);
  }

  double _predictPatternRecognition(List<double> features) {
    final candlePattern = features[FI_CANDLE_PATTERN];
    final priceAction = features[FI_PRICE_ACTION];

    double score = candlePattern * 0.6 + priceAction * 0.4;
    return _sigmoid(score * 3.0);
  }

  void _trainDeepModel(bool won) {
    if (_priceHistory.length < 100) return;

    final features = _extractAdvancedFeatures();
    final y = won ? 1.0 : 0.0;
    final pred = _predictDeepNetwork(features);
    final error = y - pred;

    final lr = _learningRate * (1.0 + (accuracy - 0.5).abs());

    for (int i = 0; i < _weightsOutput.length; i++) {
      final grad = (i < _hiddenState.length ? _hiddenState[i] : 0.01) * error;
      _weightsOutput[i] += lr * grad;
    }
    _biasOutput += lr * error * 0.5;

    for (int i = 0; i < _weightsOutput.length; i++) {
      _weightsOutput[i] *= 0.9999;
    }

    if (accuracy > 0.65) {
      _learningRate = max(_learningRate * 0.995, 1e-6);
    } else if (accuracy < 0.45) {
      _learningRate = min(_learningRate * 1.005, 0.01);
    }
  }

  void _updateEnsembleWeights(bool won) {
    for (var model in _ensembleModels) {
      if (won) {
        model['accuracy'] = (model['accuracy'] * 0.96) + 0.04;
      } else {
        model['accuracy'] = (model['accuracy'] * 0.96);
      }
      model['accuracy'] = (model['accuracy'] as double).clamp(0.01, 0.99);
    }

    double totalAccuracy =
        _ensembleModels.fold(0.0, (sum, m) => sum + (m['accuracy'] as double));
    if (totalAccuracy <= 0) totalAccuracy = 1.0;
    for (var model in _ensembleModels) {
      model['weight'] = (model['accuracy'] as double) / totalAccuracy;
    }
  }

  void _updatePatternSuccessRate(bool won) {
    if (currentPrediction == null) return;
    final patterns = (currentPrediction!['patterns'] as List<dynamic>?)?.cast<String>() ?? [];
    for (var p in patterns) {
      _patternSuccessRate[p] = (_patternSuccessRate[p] ?? 0) + (won ? 1 : -1);
    }
  }

  double _calculateAdvancedConfidence(
      List<double> features, double prediction, List<double> modelPredictions) {
    double confidence = 0.5;

    final variance = _calculateVariance(modelPredictions);
    final consensus = 1.0 - min(variance * 4.0, 1.0);
    confidence += consensus * 0.20;

    confidence += accuracy * 0.25;

    final strength = (prediction - 0.5).abs() * 2.0;
    confidence += strength * 0.15;

    final volatility = (features[FI_VOLATILITY]).clamp(0.0, 1.0);
    final fear = ( _marketSentiment['fear_greed_index'] as num?)?.toDouble() ?? 50.0;
    final marketScore = (1.0 - volatility) * 0.5 + (fear / 100.0) * 0.5;
    confidence += marketScore * 0.15;

    final recentWinRate = _calculateRecentWinRate();
    confidence += recentWinRate * 0.15;

    final patterns = _detectAdvancedPatterns();
    final patternConfidence = patterns.isEmpty
        ? 0.0
        : patterns
            .map((p) => ((_patternSuccessRate[p] ?? 0).clamp(-50, 50) / 50.0))
            .reduce((a, b) => a + b) /
            patterns.length;
    confidence += patternConfidence.clamp(0.0, 1.0) * 0.10;

    return confidence.clamp(0.0, 1.0);
  }

  List<String> _detectAdvancedPatterns() {
    List<String> patterns = [];
    if (_priceHistory.length < 50) return patterns;
    final recent = _priceHistory.sublist(_priceHistory.length - 50);

    if (_detectHeadAndShoulders(recent)) patterns.add('head_shoulders');
    if (_detectDoublePeak(recent)) patterns.add('double_top');
    if (_detectDoubleBottom(recent)) patterns.add('double_bottom');
    if (_detectTriangle(recent)) patterns.add('triangle');
    if (_detectFlag(recent)) patterns.add('flag');
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
    final ratio = potentialRisk > 0 ? (potentialReward / potentialRisk) : 1.0;

    return {'risk': potentialRisk, 'reward': potentialReward, 'ratio': ratio.isFinite ? ratio : 1.0};
  }

  String _getRecommendedAction(double confidence, Map<String, double> riskReward) {
    final ratio = riskReward['ratio'] ?? 1.0;
    if (confidence > 0.78 && ratio > 2.0) return 'strong_buy';
    if (confidence > 0.65 && ratio > 1.5) return 'buy';
    if (confidence > 0.55 && ratio > 1.0) return 'moderate_buy';
    if (confidence < 0.45) return 'avoid';
    return 'hold';
  }

  double recommendedStake(double balance) {
    if (_initialBalance == 0) _initialBalance = balance;
    if (balance > _peakBalance) _peakBalance = balance;

    final currentDrawdown = _peakBalance > 0 ? (_peakBalance - balance) / _peakBalance : 0.0;
    _maxDrawdown = max(_maxDrawdown, currentDrawdown);

    final winRate = accuracy;
    final avgWin = _totalProfit / max(correctPredictions, 1);
    final avgLoss = _totalLoss / max(totalPredictions - correctPredictions, 1);
    final kellyFraction = avgLoss > 0 ? (winRate - (1 - winRate) / (avgWin / max(avgLoss, 1e-6))) : 0.02;

    double baseStake = balance * max(kellyFraction * 0.5, 0.005);

    if (currentPrediction != null) {
      final conf = (currentPrediction!['confidence'] as double?) ?? 0.5;
      final rr = (currentPrediction!['risk_reward'] as Map<String, double>?) ?? {'ratio': 1.0};
      baseStake *= (0.5 + conf * 0.5);
      baseStake *= min(rr['ratio']! / 2.0, 1.5);
    }

    if (_consecutiveLosses >= 3) {
      baseStake *= pow(0.75, (_consecutiveLosses - 2)).toDouble();
    } else if (_consecutiveWins >= 3) {
      baseStake *= (1.0 + min(_consecutiveWins * 0.08, 0.4));
    }

    if (currentDrawdown > 0.2) baseStake *= (1.0 - currentDrawdown);

    final maxStake = balance * 0.15;
    final minStake = balance * 0.002;

    return baseStake.clamp(minStake, maxStake);
  }

  // ---------- Indicadores e utilitários (corrigidos / normalizados) ----------
  double _calculateSMA(List<double> prices, int period) {
    if (prices.isEmpty) return 0.0;
    if (prices.length < period) period = prices.length;
    final subset = prices.sublist(prices.length - period);
    final avg = subset.reduce((a, b) => a + b) / subset.length;
    return avg;
  }

  double _calculateEMA(List<double> prices, int period) {
    if (prices.isEmpty) return 0.0;
    if (prices.length < period) return prices.last;
    final multiplier = 2.0 / (period + 1);
    double ema = _calculateSMA(prices.sublist(0, period), period);
    for (int i = period; i < prices.length; i++) {
      ema = (prices[i] - ema) * multiplier + ema;
    }
    return ema;
  }

  double _calculateRSI(List<double> prices) {
    if (prices.length < 15) return 0.5;
    double gains = 0, losses = 0;
    for (int i = prices.length - 14; i < prices.length; i++) {
      double change = prices[i] - prices[i - 1];
      if (change > 0) gains += change;
      else losses += change.abs();
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
    final last = prices.last == 0 ? 1.0 : prices.last;
    return (ema12 - ema26) / last;
  }

  double _calculateVolatility(List<double> prices) {
    if (prices.length < 2) return 0.0;
    double mean = prices.reduce((a, b) => a + b) / prices.length;
    double variance = prices.map((p) => pow(p - mean, 2)).reduce((a, b) => a + b) / prices.length;
    return sqrt(variance) / max(1e-8, mean);
  }

  double _calculateATR(List<double> prices) {
    if (prices.length < 2) return 0.0;
    List<double> tr = [];
    for (int i = 1; i < prices.length; i++) {
      tr.add((prices[i] - prices[i - 1]).abs());
    }
    final window = min(14, tr.length);
    final sum = tr.sublist(tr.length - window).reduce((a, b) => a + b);
    return (sum / window) / max(1e-8, prices.last);
  }

  double _calculateTrend(List<double> prices) {
    if (prices.length < 2) return 0.0;
    return (prices.last - prices.first) / max(1e-8, prices.first);
  }

  double _calculateTrendStrength(List<double> prices) {
    if (prices.length < 5) return 0.0;
    int up = 0;
    for (int i = 1; i < prices.length; i++) {
      if (prices[i] > prices[i - 1]) up++;
    }
    return ((up / (prices.length - 1)) - 0.5) * 2.0;
  }

  double _detectCandlePattern(List<double> prices) {
    if (prices.length < 3) return 0.0;
    final last = prices.last;
    final prev = prices[prices.length - 2];
    final prevPrev = prices[prices.length - 3];
    if (prevPrev == 0) return 0.0;
    if ((last - prev).abs() / prev > 0.02) return 0.8;
    return 0.5;
  }

  double _calculateSupport(List<double> prices) {
    if (prices.isEmpty) return 0.0;
    return prices.reduce(min);
  }

  double _calculateResistance(List<double> prices) {
    if (prices.isEmpty) return 0.0;
    return prices.reduce(max);
  }

  double _calculateStochastic(List<double> prices) {
    if (prices.length < 14) return 0.5;
    final period = prices.sublist(prices.length - 14);
    final low = period.reduce(min);
    final high = period.reduce(max);
    if (high == low) return 0.5;
    return (prices.last - low) / (high - low);
  }

  double _calculateCCI(List<double> prices) {
    if (prices.length < 20) return 0.0;
    final recent = prices.sublist(prices.length - 20);
    final tp = recent.reduce((a, b) => a + b) / recent.length;
    final sma = tp;
    final mad = recent.map((p) => (p - sma).abs()).reduce((a, b) => a + b) / recent.length;
    if (mad == 0) return 0.0;
    return ((tp - sma) / (0.015 * mad)) / 100.0;
  }

  double _calculateWilliamsR(List<double> prices) {
    if (prices.length < 14) return -0.5;
    final period = prices.sublist(prices.length - 14);
    final high = period.reduce(max);
    final low = period.reduce(min);
    if (high == low) return -0.5;
    return -((high - prices.last) / (high - low));
  }

  double _calculateADX(List<double> prices) {
    if (prices.length < 6) return 0.5;
    double sum = 0.0;
    int n = min(14, prices.length - 1);
    for (int i = 1; i <= n; i++) {
      sum += (prices[prices.length - i] - prices[prices.length - i - 1]).abs();
    }
    return (sum / max(1, n)) / max(1e-8, prices.last);
  }

  double _calculateParabolicSAR(List<double> prices) {
    if (prices.length < 5) return 1.0;
    final isUp = prices.last > prices[prices.length - 5];
    return isUp ? 1.05 : 0.95;
  }

  double _calculateBollingerBands(List<double> prices) {
    if (prices.length < 20) return 0.5;
    final sma = _calculateSMA(prices, 20);
    final std = sqrt(_calculateVariance(prices.sublist(prices.length - 20)));
    final upper = sma + 2 * std;
    final lower = sma - 2 * std;
    if ((upper - lower).abs() < 1e-8) return 0.5;
    return ((prices.last - lower) / (upper - lower)).clamp(0.0, 1.0);
  }

  double _calculatePriceAction(List<double> prices) {
    if (prices.length < 5) return 0.5;
    final recent = prices.sublist(prices.length - 5);
    final range = recent.reduce(max) - recent.reduce(min);
    final change = prices.last - recent.first;
    if (range == 0) return 0.5;
    return ((change / range) + 1.0) / 2.0;
  }

  double _calculateROC(List<double> prices) {
    if (prices.length < 10) return 0.0;
    final old = prices[prices.length - 10];
    if (old == 0) return 0.0;
    return (prices.last - old) / old;
  }

  double _calculateMomentum(List<double> prices) {
    if (prices.length < 10) return 0.0;
    return (prices.last - prices[prices.length - 10]) / max(1e-8, prices.last);
  }

  double _getVolatilityScore() {
    final volatilityMap = {'low': 0.3, 'medium': 0.5, 'high': 0.8};
    return volatilityMap[_economicCalendar['volatility_expected']] ?? 0.5;
  }

  double _calculateRecentWinRate() {
    if (_tradeHistory.length < 10) return 0.5;
    final recent = _tradeHistory.sublist(max(0, _tradeHistory.length - 20));
    final wins = recent.where((t) => t['won'] == true).length;
    return wins / max(1, recent.length);
  }

  double _calculateVariance(List<double> values) {
    if (values.isEmpty) return 0.0;
    final mean = values.reduce((a, b) => a + b) / values.length;
    final sumsq = values.map((v) => pow(v - mean, 2)).reduce((a, b) => a + b);
    return sumsq / values.length;
  }

  bool _detectHeadAndShoulders(List<double> prices) {
    if (prices.length < 20) return false;
    final peaks = _findPeaks(prices);
    if (peaks.length < 3) return false;
    return peaks[1] > peaks[0] && peaks[1] > peaks[2] && ((peaks[0] - peaks[2]).abs() / max(1e-8, peaks[0]) < 0.12);
  }

  bool _detectDoublePeak(List<double> prices) {
    if (prices.length < 15) return false;
    final peaks = _findPeaks(prices);
    if (peaks.length < 2) return false;
    return ((peaks[0] - peaks[1]).abs() / max(1e-8, peaks[0])) < 0.03;
  }

  bool _detectDoubleBottom(List<double> prices) {
    if (prices.length < 15) return false;
    final bottoms = _findBottoms(prices);
    if (bottoms.length < 2) return false;
    return ((bottoms[0] - bottoms[1]).abs() / max(1e-8, bottoms[0])) < 0.03;
  }

  bool _detectTriangle(List<double> prices) {
    if (prices.length < 20) return false;
    final highs = _findPeaks(prices);
    final lows = _findBottoms(prices);
    if (highs.length < 3 || lows.length < 3) return false;
    final highRange = highs.first - highs.last;
    final lowRange = lows.last - lows.first;
    return highRange.abs() > 0 && lowRange.abs() > 0;
  }

  bool _detectFlag(List<double> prices) {
    if (prices.length < 15) return false;
    final half = prices.length ~/ 2;
    final first = prices.sublist(0, half);
    final second = prices.sublist(half);
    final firstMove = (first.last - first.first).abs() / max(1e-8, first.first);
    final secondMove = (second.last - second.first).abs() / max(1e-8, second.first);
    return firstMove > 0.03 && secondMove < 0.013;
  }

  bool _detectWedge(List<double> prices) {
    if (prices.length < 20) return false;
    final highs = _findPeaks(prices);
    final lows = _findBottoms(prices);
    if (highs.length < 3 || lows.length < 3) return false;
    final highSlope = (highs.last - highs.first) / max(1, highs.length);
    final lowSlope = (lows.last - lows.first) / max(1, lows.length);
    return (highSlope.abs() < 0.05 && lowSlope.abs() < 0.05) && (highSlope * lowSlope < 0);
  }

  List<double> _findPeaks(List<double> prices) {
    List<double> peaks = [];
    for (int i = 1; i < prices.length - 1; i++) {
      if (prices[i] > prices[i - 1] && prices[i] > prices[i + 1]) peaks.add(prices[i]);
    }
    return peaks;
  }

  List<double> _findBottoms(List<double> prices) {
    List<double> bottoms = [];
    for (int i = 1; i < prices.length - 1; i++) {
      if (prices[i] < prices[i - 1] && prices[i] < prices[i + 1]) bottoms.add(prices[i]);
    }
    return bottoms;
  }

  // Ativação
  double _sigmoid(double x) {
    return 1.0 / (1.0 + exp(-x));
  }

  double _relu(double x) {
    return x > 0 ? x : 0.0;
  }

  double _tanh(double x) {
    return (exp(x) - exp(-x)) / (exp(x) + exp(-x));
  }

  double _normalize(double value, double reference) {
    if (reference == 0) return 0.0;
    return value / reference;
  }

  // ---------- Persistence helpers ----------
  Future<void> _persistStateToFile() async {
    try {
      final state = saveModelState();
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_persistFileName');
      await file.writeAsString(json.encode(state));
    } catch (e) {
      // fallback: não bloquear a aplicação
    }
  }

  Future<void> _loadPersistedState() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_persistFileName');
      if (await file.exists()) {
        final raw = await file.readAsString();
        final Map<String, dynamic> state = json.decode(raw);
        loadModelState(state);
      }
    } catch (e) {
      // ignore and proceed with fresh model
    }
  }

  // ---------- Report / persistência (mantive assinaturas) ----------
  Map<String, dynamic> getMLReport() {
    return {
      'accuracy': accuracy,
      'total_predictions': totalPredictions,
      'correct_predictions': correctPredictions,
      'win_rate': correctPredictions / max(totalPredictions, 1),
      'total_profit': _totalProfit,
      'total_loss': _totalLoss,
      'net_profit': _totalProfit - _totalLoss,
      'consecutive_wins': _consecutiveWins,
      'consecutive_losses': _consecutiveLosses,
      'max_drawdown': _maxDrawdown,
      'learning_rate': _learningRate,
      'ensemble_models': _ensembleModels,
      'pattern_success_rate': _patternSuccessRate,
      'market_sentiment': _marketSentiment,
      'current_prediction': currentPrediction,
      'model_version': '2.1_robust',
      'features_count': _inputSize,
      'hidden_layers': [_hiddenSize1, _hiddenSize2],
      'online_data_enabled': _onlineDataEnabled,
      'market_symbol': _currentMarketSymbol,
    };
  }

  Map<String, dynamic> saveModelState() {
    return {
      'weights_layer1': _weightsLayer1,
      'weights_layer2': _weightsLayer2,
      'weights_output': _weightsOutput,
      'bias_layer1': _biasLayer1,
      'bias_layer2': _biasLayer2,
      'bias_output': _biasOutput,
      'cell_state': _cellState,
      'hidden_state': _hiddenState,
      'learning_rate': _learningRate,
      'accuracy': accuracy,
      'total_predictions': totalPredictions,
      'correct_predictions': correctPredictions,
      'pattern_success_rate': _patternSuccessRate,
      'ensemble_models': _ensembleModels,
      'market_sentiment': _marketSentiment,
      'economic_calendar': _economicCalendar,
      'current_market_symbol': _currentMarketSymbol,
    };
  }

  void loadModelState(Map<String, dynamic> state) {
    try {
      _weightsLayer1 = List<List<double>>.from(
          (state['weights_layer1'] as List).map((l) => List<double>.from(l)));
      _weightsLayer2 = List<List<double>>.from(
          (state['weights_layer2'] as List).map((l) => List<double>.from(l)));
      _weightsOutput = List<double>.from(state['weights_output'] as List);
      _biasLayer1 = List<double>.from(state['bias_layer1'] as List);
      _biasLayer2 = List<double>.from(state['bias_layer2'] as List);
      _biasOutput = (state['bias_output'] as num).toDouble();
      _cellState = List<double>.from(state['cell_state'] as List);
      _hiddenState = List<double>.from(state['hidden_state'] as List);
      _learningRate = (state['learning_rate'] as num).toDouble();
      accuracy = (state['accuracy'] as num).toDouble();
      totalPredictions = (state['total_predictions'] as num).toInt();
      correctPredictions = (state['correct_predictions'] as num).toInt();
      _patternSuccessRate = Map<String, int>.from(state['pattern_success_rate'] ?? {});
      _ensembleModels = List<Map<String, dynamic>>.from(state['ensemble_models'] ?? _ensembleModels);
      _marketSentiment = Map<String, dynamic>.from(state['market_sentiment'] ?? {});
      _economicCalendar = Map<String, dynamic>.from(state['economic_calendar'] ?? {});
      _currentMarketSymbol = state['current_market_symbol'] as String?;
    } catch (e) {
      // fallback: re-inicializar
      _initializeAdvancedModel();
    }
  }

  void resetModel() {
    _initializeAdvancedModel();
    _priceHistory.clear();
    _tradeHistory.clear();
    currentPrediction = null;
    accuracy = 0.0;
    totalPredictions = 0;
    correctPredictions = 0;
    _totalProfit = 0.0;
    _totalLoss = 0.0;
    _consecutiveLosses = 0;
    _consecutiveWins = 0;
    _patternSuccessRate.clear();
  }

  void dispose() {
    _onlineTimer?.cancel();
    _onlineTimer = null;
  }
}