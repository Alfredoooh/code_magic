// lib/bots_screen.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'bot_engine.dart';

class BotsScreen extends StatefulWidget {
  final String token;

  const BotsScreen({Key? key, required this.token}) : super(key: key);

  @override
  State<BotsScreen> createState() => _BotsScreenState();
}

class _BotsScreenState extends State<BotsScreen> with AutomaticKeepAliveClientMixin {
  WebSocketChannel? _channel;
  bool _isConnected = false;
  List<TradingBot> _bots = [];
  double _balance = 0.0;
  String _currency = 'USD';
  Map<String, String> _proposalIds = {};

  // Dados de preço para análise
  Map<String, List<double>> _marketPrices = {};
  Timer? _priceUpdateTimer;

  // Controllers dos charts por mercado (market -> list of WebViewController)
  final Map<String, List<WebViewController>> _chartControllers = {};

  // Quantos pontos enviar ao chart (últimos N ticks)
  final int _chartPointsCount = 60;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
    _loadDefaultBots();
    _startPriceTracking();
  }

  @override
  void dispose() {
    for (var bot in _bots) {
      bot.stop();
    }
    _priceUpdateTimer?.cancel();
    _channel?.sink.close();

    _chartControllers.clear();

    super.dispose();
  }

  void _loadDefaultBots() {
    // --- Nota: _channel pode ser null aqui inicialmente; alguns bots esperam channel não nulo.
    // Mantive a mesma lista de bots. Se o _channel for nulo no momento da criação em runtime,
    // assume-se que a tua lógica em bot_engine lida com isso. Manter assinatura inalterada.
    _bots = [
      TradingBot(
        config: BotConfiguration(
          name: 'Martingale Pro',
          description: 'Recuperação automática com Martingale inteligente',
          strategy: BotStrategy.martingale,
          initialStake: 10.0,
          market: 'R_100',
          contractType: 'CALL',
          recoveryMode: RecoveryMode.intelligent,
          entryConditions: [EntryCondition.immediate],
          maxConsecutiveLosses: 7,
          maxStake: 500.0,
          targetProfit: 100.0,
        ),
        channel: _channel!,
        onStatusUpdate: (status) => setState(() {}),
      ),

      TradingBot(
        config: BotConfiguration(
          name: 'Fibonacci Master',
          description: 'Estratégia Fibonacci com análise RSI',
          strategy: BotStrategy.fibonacci,
          initialStake: 15.0,
          market: 'R_50',
          contractType: 'PUT',
          recoveryMode: RecoveryMode.moderate,
          entryConditions: [EntryCondition.rsiOversold, EntryCondition.trendConfirmation],
          useRSI: true,
          maxStake: 400.0,
          targetProfit: 150.0,
        ),
        channel: _channel!,
        onStatusUpdate: (status) => setState(() {}),
      ),

      TradingBot(
        config: BotConfiguration(
          name: 'D\'Alembert Safe',
          description: 'Crescimento gradual com segurança',
          strategy: BotStrategy.dalembert,
          initialStake: 20.0,
          market: 'R_75',
          contractType: 'CALL',
          recoveryMode: RecoveryMode.conservative,
          entryConditions: [EntryCondition.supportResistance],
          useSupportResistance: true,
          maxStake: 300.0,
        ),
        channel: _channel!,
        onStatusUpdate: (status) => setState(() {}),
      ),

      TradingBot(
        config: BotConfiguration(
          name: 'Labouchere Elite',
          description: 'Sistema de cancelamento avançado',
          strategy: BotStrategy.labouchere,
          initialStake: 12.0,
          market: 'BOOM500',
          contractType: 'CALL',
          recoveryMode: RecoveryMode.moderate,
          entryConditions: [EntryCondition.priceAction],
          maxStake: 350.0,
        ),
        channel: _channel!,
        onStatusUpdate: (status) => setState(() {}),
      ),

      TradingBot(
        config: BotConfiguration(
          name: 'Oscar\'s Grind',
          description: 'Progressão lenta e constante',
          strategy: BotStrategy.oscarGrind,
          initialStake: 10.0,
          market: 'CRASH500',
          contractType: 'PUT',
          recoveryMode: RecoveryMode.conservative,
          maxStake: 200.0,
          targetProfit: 80.0,
        ),
        channel: _channel!,
        onStatusUpdate: (status) => setState(() {}),
      ),

      TradingBot(
        config: BotConfiguration(
          name: 'Paroli Power',
          description: 'Maximiza sequências vencedoras',
          strategy: BotStrategy.paroli,
          initialStake: 15.0,
          market: 'R_100',
          contractType: 'CALL',
          recoveryMode: RecoveryMode.none,
          entryConditions: [EntryCondition.trendConfirmation],
          maxStake: 250.0,
        ),
        channel: _channel!,
        onStatusUpdate: (status) => setState(() {}),
      ),

      TradingBot(
        config: BotConfiguration(
          name: 'Kelly Criterion',
          description: 'Gestão matemática de banca',
          strategy: BotStrategy.kellyFraction,
          initialStake: 20.0,
          market: 'R_25',
          contractType: 'PUT',
          recoveryMode: RecoveryMode.intelligent,
          bankrollPercentage: 2.5,
          maxStake: 400.0,
        ),
        channel: _channel!,
        onStatusUpdate: (status) => setState(() {}),
      ),

      TradingBot(
        config: BotConfiguration(
          name: '1-3-2-6 System',
          description: 'Sequência otimizada de apostas',
          strategy: BotStrategy.oneThreeTwoSix,
          initialStake: 10.0,
          market: 'R_50',
          contractType: 'CALL',
          recoveryMode: RecoveryMode.moderate,
          maxStake: 300.0,
        ),
        channel: _channel!,
        onStatusUpdate: (status) => setState(() {}),
      ),

      TradingBot(
        config: BotConfiguration(
          name: 'Adaptive AI',
          description: 'Adaptação inteligente ao mercado',
          strategy: BotStrategy.adaptive,
          initialStake: 25.0,
          market: 'R_100',
          contractType: 'CALL',
          recoveryMode: RecoveryMode.intelligent,
          entryConditions: [
            EntryCondition.rsiOversold,
            EntryCondition.priceAction,
            EntryCondition.trendConfirmation,
          ],
          useRSI: true,
          useBollinger: true,
          useSupportResistance: true,
          maxStake: 500.0,
          targetProfit: 200.0,
        ),
        channel: _channel!,
        onStatusUpdate: (status) => setState(() {}),
      ),

      TradingBot(
        config: BotConfiguration(
          name: 'Recovery Master',
          description: 'Especialista em recuperação de perdas',
          strategy: BotStrategy.recovery,
          initialStake: 15.0,
          market: 'R_75',
          contractType: 'PUT',
          recoveryMode: RecoveryMode.aggressive,
          entryConditions: [EntryCondition.immediate],
          maxStake: 600.0,
          maxLoss: 300.0,
          targetProfit: 100.0,
        ),
        channel: _channel!,
        onStatusUpdate: (status) => setState(() {}),
      ),

      TradingBot(
        config: BotConfiguration(
          name: 'Compound Growth',
          description: 'Crescimento exponencial com composição',
          strategy: BotStrategy.compound,
          initialStake: 10.0,
          market: 'BOOM1000',
          contractType: 'CALL',
          recoveryMode: RecoveryMode.moderate,
          compoundGains: true,
          resetAfterProfit: true,
          resetProfitThreshold: 50.0,
          maxStake: 400.0,
        ),
        channel: _channel!,
        onStatusUpdate: (status) => setState(() {}),
      ),

      TradingBot(
        config: BotConfiguration(
          name: 'ML Predictor',
          description: 'Machine Learning com alta precisão',
          strategy: BotStrategy.mlBased,
          initialStake: 30.0,
          market: 'R_100',
          contractType: 'CALL',
          recoveryMode: RecoveryMode.intelligent,
          entryConditions: [
            EntryCondition.rsiOversold,
            EntryCondition.macdCross,
            EntryCondition.patternDetection,
          ],
          useMLPredictions: true,
          mlConfidenceThreshold: 0.75,
          useRSI: true,
          useMACD: true,
          usePatternRecognition: true,
          maxStake: 500.0,
          targetProfit: 250.0,
        ),
        channel: _channel!,
        onStatusUpdate: (status) => setState(() {}),
      ),
    ];
  }

  void _connectWebSocket() {
    try {
      _channel = WebSocketChannel.connect(
        Uri.parse('wss://ws.derivws.com/websockets/v3?app_id=71954'),
      );

      setState(() => _isConnected = true);

      _channel!.stream.listen(
        (message) {
          final data = json.decode(message);
          _handleWebSocketMessage(data);
        },
        onError: (error) => setState(() => _isConnected = false),
        onDone: () {
          setState(() => _isConnected = false);
          Future.delayed(const Duration(seconds: 3), _connectWebSocket);
        },
      );

      _channel!.sink.add(json.encode({'authorize': widget.token}));

      // Subscrever para ticks de todos os mercados
      _subscribeToMarkets();
    } catch (e) {
      setState(() => _isConnected = false);
    }
  }

  void _subscribeToMarkets() {
    final markets = {'R_100', 'R_50', 'R_25', 'R_75', 'BOOM500', 'BOOM1000', 'CRASH500'};
    for (var market in markets) {
      _channel!.sink.add(json.encode({
        'ticks': market,
        'subscribe': 1,
      }));
    }
  }

  void _handleWebSocketMessage(Map<String, dynamic> data) {
    switch (data['msg_type']) {
      case 'authorize':
        setState(() {
          _balance = double.parse(data['authorize']['balance'].toString());
          _currency = data['authorize']['currency'];
        });
        break;

      case 'tick':
        final symbol = data['tick']['symbol'];
        final price = double.parse(data['tick']['quote'].toString());

        if (!_marketPrices.containsKey(symbol)) {
          _marketPrices[symbol] = [];
        }
        _marketPrices[symbol]!.add(price);

        // Limitar histórico para não crescer indefinidamente (ex: 500)
        if (_marketPrices[symbol]!.length > 500) {
          _marketPrices[symbol] = _marketPrices[symbol]!.sublist(_marketPrices[symbol]!.length - 500);
        }

        // Atualizar preço em bots do mesmo mercado
        for (var bot in _bots) {
          if (bot.config.market == symbol) {
            bot.updatePrice(price);
          }
        }

        // --- Enviar últimos pontos para os charts registados deste mercado ---
        final controllers = _chartControllers[symbol];
        if (controllers != null && controllers.isNotEmpty) {
          final allPoints = _marketPrices[symbol]!;
          final lastPoints = allPoints.length > _chartPointsCount
              ? allPoints.sublist(allPoints.length - _chartPointsCount)
              : allPoints;
          final jsArray = lastPoints.map((p) => p.toString()).join(',');
          final script = "try{ updateData([${jsArray}]); }catch(e){};";
          for (var c in controllers) {
            try {
              c.runJavaScript(script);
            } catch (_) {
              // ignore controllers that fail (webview may not be ready)
            }
          }
        }

        break;

      case 'proposal':
        final id = data['proposal']['id'];
        _proposalIds[id] = id;

        // Encontrar bot esperando proposta
        for (var bot in _bots) {
          if (bot.isRunning && bot.currentContractId == null) {
            bot.handleProposalResponse(id);
            break;
          }
        }
        break;

      case 'buy':
        for (var bot in _bots) {
          if (bot.isRunning && bot.currentContractId == null) {
            bot.handleBuyResponse(data['buy']);
            setState(() {
              _balance -= bot.currentStake;
            });
            break;
          }
        }
        break;

      case 'proposal_open_contract':
        for (var bot in _bots) {
          bot.handleContractUpdate(data['proposal_open_contract']);
        }
        break;

      case 'balance':
        setState(() {
          _balance = double.parse(data['balance']['balance'].toString());
        });
        break;
    }
  }

  void _startPriceTracking() {
    _priceUpdateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  void _showBotDetails(TradingBot bot) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BotDetailsScreen(bot: bot),
      ),
    );
  }

  void _showCreateBotDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateBotScreen(
          channel: _channel!,
          onBotCreated: (bot) {
            setState(() => _bots.add(bot));
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final activeBots = _bots.where((b) => b.isRunning).length;
    final totalProfit = _bots.fold(0.0, (sum, bot) => sum + bot.totalProfit);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Trading Bots'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _isConnected ? const Color(0xFF00C896) : Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${_balance.toStringAsFixed(2)} $_currency',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatisticsHeader(activeBots, totalProfit),
          Expanded(
            child: _isConnected
                ? ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _bots.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) => _buildBotCard(_bots[index]),
                  )
                : const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Color(0xFF0066FF)),
                        SizedBox(height: 16),
                        Text('Conectando...', style: TextStyle(color: Colors.white54)),
                      ],
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateBotDialog,
        backgroundColor: const Color(0xFF0066FF),
        icon: const Icon(Icons.add),
        label: const Text('Criar Bot'),
      ),
    );
  }

  Widget _buildStatisticsHeader(int activeBots, double totalProfit) {
    // Use cores sólidas em vez de gradient
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              'Bots Ativos',
              activeBots.toString(),
              Icons.smart_toy,
              const Color(0xFF0066FF),
            ),
          ),
          Container(width: 1, height: 40, color: Colors.white12),
          Expanded(
            child: _buildStatItem(
              'Total Bots',
              _bots.length.toString(),
              Icons.grid_view,
              Colors.white70,
            ),
          ),
          Container(width: 1, height: 40, color: Colors.white12),
          Expanded(
            child: _buildStatItem(
              'Lucro Total',
              '${totalProfit >= 0 ? '+' : ''}\$${totalProfit.toStringAsFixed(2)}',
              Icons.trending_up,
              totalProfit >= 0 ? const Color(0xFF00C896) : const Color(0xFFFF4444),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 11),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildBotCard(TradingBot bot) {
    final status = bot._getStatus();
    final winRate = status.winRate * 100;
    final isProfit = status.sessionProfit >= 0;

    return GestureDetector(
      onTap: () => _showBotDetails(bot),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: bot.isRunning 
                ? const Color(0xFF0066FF) 
                : Colors.white.withOpacity(0.05),
            width: bot.isRunning ? 2 : 1,
          ),
          boxShadow: bot.isRunning
              ? [
                  BoxShadow(
                    color: const Color(0xFF0066FF).withOpacity(0.09),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: bot.isRunning ? const Color(0xFF0066FF) : const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getStrategyIcon(bot.config.strategy),
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              bot.config.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (bot.inRecoveryMode)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.orange.withOpacity(0.9)),
                              ),
                              child: const Text(
                                'RECOVERY',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        bot.config.description,
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _buildChip(bot.config.market, const Color(0xFF0066FF)),
                          const SizedBox(width: 6),
                          _buildChip(
                            bot.config.strategy.toString().split('.').last.toUpperCase(),
                            const Color(0xFF00C896),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Mini gráfico de desempenho (usando DerivAreaChart embebido)
            if (status.tradeHistory.isNotEmpty)
              _buildMiniChart(status.tradeHistory, bot),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetric(
                          'Trades',
                          status.totalTrades.toString(),
                          Colors.white70,
                        ),
                      ),
                      Expanded(
                        child: _buildMetric(
                          'Win Rate',
                          '${winRate.toStringAsFixed(1)}%',
                          winRate >= 50 ? const Color(0xFF00C896) : const Color(0xFFFF4444),
                        ),
                      ),
                      Expanded(
                        child: _buildMetric(
                          'Profit',
                          '${isProfit ? '+' : ''}\$${status.sessionProfit.toStringAsFixed(2)}',
                          isProfit ? const Color(0xFF00C896) : const Color(0xFFFF4444),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetric(
                          'Stake',
                          '\$${status.currentStake.toStringAsFixed(2)}',
                          const Color(0xFF0066FF),
                        ),
                      ),
                      Expanded(
                        child: _buildMetric(
                          'Streak',
                          '${status.consecutiveWins > 0 ? '+' : ''}${status.consecutiveWins > 0 ? status.consecutiveWins : -status.consecutiveLosses}',
                          status.consecutiveWins > 0 ? const Color(0xFF00C896) : const Color(0xFFFF4444),
                        ),
                      ),
                      Expanded(
                        child: _buildMetric(
                          'RSI',
                          status.currentRSI.toStringAsFixed(0),
                          _getRSIColor(status.currentRSI),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (bot.isRunning) {
                        if (bot.isPaused) {
                          bot.resume();
                        } else {
                          bot.pause();
                        }
                      } else {
                        bot.start();
                      }
                      setState(() {});
                    },
                    icon: Icon(
                      bot.isRunning
                          ? (bot.isPaused ? Icons.play_arrow : Icons.pause)
                          : Icons.play_arrow,
                    ),
                    label: Text(
                      bot.isRunning
                          ? (bot.isPaused ? 'Continuar' : 'Pausar')
                          : 'Iniciar',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: bot.isRunning
                          ? (bot.isPaused ? const Color(0xFF00C896) : const Color(0xFFFF9800))
                          : const Color(0xFF00C896),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (bot.isRunning)
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        bot.stop();
                        setState(() {});
                      },
                      icon: const Icon(Icons.stop, size: 20),
                      label: const Text('Parar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF4444),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white70),
                    onPressed: () {
                      bot.reset();
                      setState(() {});
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniChart(List<TradeRecord> history, TradingBot bot) {
    final data = history.map((t) => t.profit).toList();
    final cumulative = <double>[];
    double sum = 0;

    for (var profit in data) {
      sum += profit;
      cumulative.add(sum);
    }

    // Usar o DerivAreaChart embebido — sem preenchimento/gradient
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DerivAreaChart(
        points: cumulative,
        autoScale: true,
        showGradient: false, // sem fill
        market: bot.config.market,
        onControllerCreated: (controller, market) {
          if (market == null) return;
          _chartControllers.putIfAbsent(market, () => []);
          if (!_chartControllers[market]!.contains(controller)) {
            _chartControllers[market]!.add(controller);
            final allPoints = _marketPrices[market] ?? [];
            final lastPoints = allPoints.length > _chartPointsCount
                ? allPoints.sublist(allPoints.length - _chartPointsCount)
                : allPoints;
            if (lastPoints.isNotEmpty) {
              final jsArray = lastPoints.map((p) => p.toString()).join(',');
              final script = "try{ updateData([${jsArray}]); }catch(e){};";
              try {
                controller.runJavaScript(script);
              } catch (_) {}
            }
          }
        },
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 10),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  IconData _getStrategyIcon(BotStrategy strategy) {
    switch (strategy) {
      case BotStrategy.martingale:
        return Icons.trending_up;
      case BotStrategy.fibonacci:
        return Icons.stairs;
      case BotStrategy.dalembert:
        return Icons.analytics;
      case BotStrategy.labouchere:
        return Icons.calculate;
      case BotStrategy.oscarGrind:
        return Icons.slow_motion_video;
      case BotStrategy.paroli:
        return Icons.flash_on;
      case BotStrategy.antiMartingale:
        return Icons.trending_down;
      case BotStrategy.kellyFraction:
        return Icons.functions;
      case BotStrategy.pinkham:
        return Icons.healing;
      case BotStrategy.oneThreeTwoSix:
        return Icons.format_list_numbered;
      case BotStrategy.percentage:
        return Icons.percent;
      case BotStrategy.compound:
        return Icons.workspaces;
      case BotStrategy.recovery:
        return Icons.restore;
      case BotStrategy.adaptive:
        return Icons.settings_suggest;
      case BotStrategy.mlBased:
        return Icons.psychology;
    }
  }

  Color _getRSIColor(double rsi) {
    if (rsi < 30) return const Color(0xFF00C896); // Oversold
    if (rsi > 70) return const Color(0xFFFF4444); // Overbought
    return Colors.white70;
  }
}

// ========== BOT DETAILS SCREEN ==========

class BotDetailsScreen extends StatefulWidget {
  final TradingBot bot;

  const BotDetailsScreen({Key? key, required this.bot}) : super(key: key);

  @override
  State<BotDetailsScreen> createState() => _BotDetailsScreenState();
}

class _BotDetailsScreenState extends State<BotDetailsScreen> {
  String _selectedChart = 'profit';

  @override
  Widget build(BuildContext context) {
    final status = widget.bot._getStatus();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(widget.bot.config.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettings(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(status),
            const SizedBox(height: 16),
            _buildChartSelector(),
            const SizedBox(height: 16),
            _buildMainChart(status),
            const SizedBox(height: 16),
            _buildStatisticsGrid(status),
            const SizedBox(height: 16),
            _buildTradeHistory(status),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(BotStatus status) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Session Profit',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${status.sessionProfit >= 0 ? '+' : ''}\$${status.sessionProfit.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: status.sessionProfit >= 0 
                          ? const Color(0xFF00C896) 
                          : const Color(0xFFFF4444),
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: status.isRunning 
                      ? const Color(0xFF00C896).withOpacity(0.12)
                      : Colors.white.withOpacity(0.06),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  status.isRunning ? Icons.play_arrow : Icons.pause,
                  color: status.isRunning ? const Color(0xFF00C896) : Colors.white54,
                  size: 32,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildQuickStat('Win Rate', '${(status.winRate * 100).toStringAsFixed(1)}%'),
              ),
              Expanded(
                child: _buildQuickStat('Trades', status.totalTrades.toString()),
              ),
              Expanded(
                child: _buildQuickStat('Streak', '${status.consecutiveWins - status.consecutiveLosses}'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
      ],
    );
  }

  Widget _buildChartSelector() {
    return Row(
      children: [
        _buildChartButton('profit', 'Profit', Icons.trending_up),
        const SizedBox(width: 8),
        _buildChartButton('winrate', 'Win Rate', Icons.pie_chart),
        const SizedBox(width: 8),
        _buildChartButton('stake', 'Stake', Icons.attach_money),
      ],
    );
  }

  Widget _buildChartButton(String id, String label, IconData icon) {
    final isSelected = _selectedChart == id;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedChart = id),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0066FF) : const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainChart(BotStatus status) {
    if (status.tradeHistory.isEmpty) {
      return Container(
        height: 250,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text('Sem dados ainda', style: TextStyle(color: Colors.white54)),
        ),
      );
    }

    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: _selectedChart == 'profit'
          ? _buildProfitChart(status.tradeHistory)
          : _selectedChart == 'winrate'
              ? _buildWinRateChart(status.tradeHistory)
              : _buildStakeChart(status.tradeHistory),
    );
  }

  Widget _buildProfitChart(List<TradeRecord> history) {
    final cumulative = <double>[];
    double sum = 0;

    for (var trade in history) {
      sum += trade.profit;
      cumulative.add(sum);
    }

    return DerivAreaChart(
      points: cumulative,
      autoScale: true,
      showGradient: false,
      market: widget.bot.config.market,
      onControllerCreated: (controller, market) {
        if (market == null) return;
        // Registrar controller (se ainda não registado)
        // Evitar duplicados
        final sc = (context.findAncestorStateOfType<_BotsScreenStateWrapper>()?._chartControllers);
        // sc pode ser null; em qualquer caso registamos localmente
        _registerControllerForMarket(controller, market);
      },
      height: 200,
    );
  }

  // Pequena helper para registar controller (evita duplicados)
  void _registerControllerForMarket(WebViewController controller, String market) {
    // Procurar uma referência ao estado pai BotsScreen para manter o mesmo mapa.
    // Caso não exista, usamos um mapa local dentro desta tela (funciona igualmente).
    // Aqui apenas garantimos que _chartControllers do pai é atualizado.
    final botsScreenState = context.findAncestorStateOfType<_BotsScreenState>();
    if (botsScreenState != null) {
      botsScreenState._chartControllers.putIfAbsent(market, () => []);
      if (!botsScreenState._chartControllers[market]!.contains(controller)) {
        botsScreenState._chartControllers[market]!.add(controller);
      }
    } else {
      _chartControllers.putIfAbsent(market, () => []);
      if (!_chartControllers[market]!.contains(controller)) {
        _chartControllers[market]!.add(controller);
      }
    }
  }

  Widget _buildWinRateChart(List<TradeRecord> history) {
    final windowSize = 10;
    final winRates = <double>[];

    for (int i = windowSize; i <= history.length; i++) {
      final window = history.sublist(i - windowSize, i);
      final wins = window.where((t) => t.won).length;
      winRates.add(wins / windowSize * 100);
    }

    return DerivAreaChart(
      points: winRates,
      autoScale: false,
      showGradient: false,
      market: widget.bot.config.market,
      onControllerCreated: (controller, market) {
        if (market == null) return;
        _registerControllerForMarket(controller, market);
      },
      height: 200,
    );
  }

  Widget _buildStakeChart(List<TradeRecord> history) {
    final stakes = history.map((t) => t.stake).toList();

    return DerivAreaChart(
      points: stakes,
      autoScale: true,
      showGradient: false,
      market: widget.bot.config.market,
      onControllerCreated: (controller, market) {
        if (market == null) return;
        _registerControllerForMarket(controller, market);
      },
      height: 200,
    );
  }

  Widget _buildStatisticsGrid(BotStatus status) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard('Total Profit', '\$${status.totalProfit.toStringAsFixed(2)}', 
            status.totalProfit >= 0 ? const Color(0xFF00C896) : const Color(0xFFFF4444)),
        _buildStatCard('Avg Win', '\$${status.avgWin.toStringAsFixed(2)}', const Color(0xFF00C896)),
        _buildStatCard('Avg Loss', '\$${status.avgLoss.toStringAsFixed(2)}', const Color(0xFFFF4444)),
        _buildStatCard('Max Drawdown', '${(status.maxDrawdown * 100).toStringAsFixed(1)}%', Colors.orange),
        _buildStatCard('Current RSI', status.currentRSI.toStringAsFixed(0), const Color(0xFF0066FF)),
        _buildStatCard('Current Stake', '\$${status.currentStake.toStringAsFixed(2)}', Colors.white70),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTradeHistory(BotStatus status) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Trades',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: status.tradeHistory.take(20).length,
          itemBuilder: (context, index) {
            final trade = status.tradeHistory[status.tradeHistory.length - 1 - index];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: trade.won ? const Color(0xFF00C896).withOpacity(0.3) : const Color(0xFFFF4444).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: trade.won ? const Color(0xFF00C896).withOpacity(0.2) : const Color(0xFFFF4444).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      trade.won ? Icons.trending_up : Icons.trending_down,
                      color: trade.won ? const Color(0xFF00C896) : const Color(0xFFFF4444),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trade.won ? 'WIN' : 'LOSS',
                          style: TextStyle(
                            color: trade.won ? const Color(0xFF00C896) : const Color(0xFFFF4444),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${trade.timestamp.hour}:${trade.timestamp.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(color: Colors.white54, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${trade.profit >= 0 ? '+' : ''}\$${trade.profit.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: trade.won ? const Color(0xFF00C896) : const Color(0xFFFF4444),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Stake: \$${trade.stake.toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.white54, fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  void _showSettings() {
    // Implementar configurações do bot
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Bot Settings',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            const Text('Settings coming soon...', style: TextStyle(color: Colors.white54)),
          ],
        ),
      ),
    );
  }
}

// ========== CREATE BOT SCREEN ==========

class CreateBotScreen extends StatefulWidget {
  final WebSocketChannel channel;
  final Function(TradingBot) onBotCreated;

  const CreateBotScreen({
    Key? key,
    required this.channel,
    required this.onBotCreated,
  }) : super(key: key);

  @override
  State<CreateBotScreen> createState() => _CreateBotScreenState();
}

class _CreateBotScreenState extends State<CreateBotScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  double _initialStake = 10.0;
  BotStrategy _selectedStrategy = BotStrategy.martingale;
  String _selectedMarket = 'R_100';
  String _contractType = 'CALL';
  RecoveryMode _recoveryMode = RecoveryMode.moderate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Create Custom Bot'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Bot Name',
                labelStyle: TextStyle(color: Colors.white54),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Description',
                labelStyle: TextStyle(color: Colors.white54),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // NOVO: campo para alterar stake via modal (confirmação explícita)
            const Text('Initial Stake', style: TextStyle(color: Colors.white, fontSize: 16)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Text(
                      '\$${_initialStake.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _openStakeModal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0066FF),
                    minimumSize: const Size(120, 48),
                  ),
                  child: const Text('Alterar Stake'),
                ),
              ],
            ),

            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _createBot,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0066FF),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Create Bot'),
            ),
          ],
        ),
      ),
    );
  }

  void _openStakeModal() {
    final controller = TextEditingController(text: _initialStake.toStringAsFixed(2));
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Definir Initial Stake', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                prefixText: '\$ ',
                prefixStyle: const TextStyle(color: Colors.white70, fontSize: 20),
                hintText: '0.00',
                hintStyle: const TextStyle(color: Colors.white24),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.white24),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFF0066FF), width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFF2A2A2A),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      final value = double.tryParse(controller.text.replaceAll(',', '.'));
                      if (value != null && value >= 0.01) {
                        setState(() {
                          _initialStake = value;
                        });
                        Navigator.pop(context);
                      } else {
                        // inválido: mostramos snackbar sem fechar modal
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Insira um valor válido (>= 0.01)'), backgroundColor: Colors.orange),
                        );
                      }
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFF0066FF),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('OK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _createBot() {
    final bot = TradingBot(
      config: BotConfiguration(
        name: _nameController.text.isEmpty ? 'Custom Bot' : _nameController.text,
        description: _descriptionController.text.isEmpty ? 'Custom strategy' : _descriptionController.text,
        strategy: _selectedStrategy,
        initialStake: _initialStake,
        market: _selectedMarket,
        contractType: _contractType,
        recoveryMode: _recoveryMode,
      ),
      channel: widget.channel,
      onStatusUpdate: (_) {},
    );

    widget.onBotCreated(bot);
    Navigator.pop(context);
  }
}

// =====================
// DerivAreaChart widget
// =====================

class DerivAreaChart extends StatefulWidget {
  final List<double> points;
  final bool autoScale;
  final bool showGradient; // agora controla apenas se preenche; usamos false por padrão para não preencher
  final double? height;

  /// market: optional, used to register the controller per market
  final String? market;

  /// Callback to expose the WebViewController once ready:
  /// (controller, market)
  final void Function(WebViewController controller, String? market)? onControllerCreated;

  const DerivAreaChart({
    Key? key,
    required this.points,
    this.autoScale = true,
    this.showGradient = false,
    this.height,
    this.market,
    this.onControllerCreated,
  }) : super(key: key);

  @override
  State<DerivAreaChart> createState() => _DerivAreaChartState();
}

class _DerivAreaChartState extends State<DerivAreaChart> {
  late final WebViewController _controller;
  String get _initialHtml => _buildHtml(widget.points, widget.autoScale, widget.showGradient);

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF1A1A1A))
      ..addJavaScriptChannel('FlutterChannel', onMessageReceived: (message) {
        // placeholder for JS -> Flutter messages if needed later
      })
      ..loadHtmlString(_initialHtml);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.onControllerCreated != null) {
        widget.onControllerCreated!(_controller, widget.market);
      }
    });
  }

  @override
  void didUpdateWidget(covariant DerivAreaChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    final jsArray = widget.points.map((p) => p.toString()).join(',');
    final script = "try{ updateData([${jsArray}]); }catch(e){};";
    _controller.runJavaScript(script);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height ?? 180,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: WebViewWidget(controller: _controller),
      ),
    );
  }

  String _buildHtml(List<double> points, bool autoScale, bool showGradient) {
    final initialData = points.map((p) => p.toString()).join(',');
    // Não usamos gradient/area fill por padrão; showGradient=false => fill: false
    return '''
<!doctype html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <style>
    html, body { margin:0; padding:0; background:#0F0F0F; }
    #chart { width:100%; height:100%; }
    canvas { display:block; }
  </style>
</head>
<body>
  <canvas id="chart"></canvas>
  <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
  <script>
    const ctx = document.getElementById('chart').getContext('2d');
    Chart.defaults.font.family = 'Arial';
    Chart.defaults.color = '#FFFFFF';
    const dataPoints = [${initialData}];
    const labels = dataPoints.map((_, i) => i.toString());

    const config = {
      type: 'line',
      data: {
        labels: labels,
        datasets: [{
          label: '',
          data: dataPoints,
          fill: ${showGradient ? 'true' : 'false'},
          backgroundColor: '${showGradient ? 'rgba(0,200,150,0.12)' : 'rgba(0,0,0,0)'}',
          borderColor: dataPoints.length>1 && dataPoints[dataPoints.length-1] >= dataPoints[dataPoints.length-2] ? '#00C896' : '#FF4444',
          tension: 0.25,
          pointRadius: 0,
          borderWidth: 2,
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        animation: false,
        scales: {
          x: { display: false },
          y: {
            display: false,
            beginAtZero: ${autoScale ? 'false' : 'true'}
          }
        },
        plugins: {
          legend: { display: false },
          tooltip: { enabled: false }
        }
      }
    };

    const myChart = new Chart(ctx, config);

    function updateData(newPoints) {
      try {
        const labels = newPoints.map((_, i) => i.toString());
        myChart.data.labels = labels;
        myChart.data.datasets[0].data = newPoints;
        if (newPoints.length >= 2) {
          const last = newPoints[newPoints.length - 1];
          const prev = newPoints[newPoints.length - 2];
          myChart.data.datasets[0].borderColor = last >= prev ? '#00C896' : '#FF4444';
        }
        myChart.update();
      } catch (e) {
        console.log('updateData error', e);
      }
    }

    window.updateData = updateData;
  </script>
</body>
</html>
''';
  }
}