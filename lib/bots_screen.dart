// lib/bots_screen.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'bot_engine.dart';
import 'bot_details_screen.dart';
import 'bot_create_screen.dart';

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
  Map<String, List<double>> _marketPrices = {};
  Timer? _priceUpdateTimer;
  final Map<String, List<WebViewController>> _chartControllers = {};
  final int _chartPointsCount = 60;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
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
      _loadDefaultBots();
      _subscribeToMarkets();
    } catch (e) {
      setState(() => _isConnected = false);
    }
  }

  void _loadDefaultBots() {
    if (_channel == null) return;
    
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

  void _subscribeToMarkets() {
    final markets = {'R_100', 'R_50', 'R_25', 'R_75', 'BOOM500', 'BOOM1000', 'CRASH500'};
    for (var market in markets) {
      _channel!.sink.add(json.encode({'ticks': market, 'subscribe': 1}));
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

        if (_marketPrices[symbol]!.length > 500) {
          _marketPrices[symbol] = _marketPrices[symbol]!.sublist(_marketPrices[symbol]!.length - 500);
        }

        for (var bot in _bots) {
          if (bot.config.market == symbol) {
            bot.updatePrice(price);
          }
        }

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
            } catch (_) {}
          }
        }
        break;

      case 'proposal':
        final id = data['proposal']['id'];
        _proposalIds[id] = id;
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
            setState(() => _balance -= bot.currentStake);
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
        setState(() => _balance = double.parse(data['balance']['balance'].toString()));
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
        builder: (context) => BotDetailsScreen(
          bot: bot,
          chartControllers: _chartControllers,
          marketPrices: _marketPrices,
          chartPointsCount: _chartPointsCount,
        ),
      ),
    );
  }

  void _showCreateBotDialog() {
    if (_channel == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateBotScreen(
          channel: _channel!,
          onBotCreated: (bot) => setState(() => _bots.add(bot)),
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
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
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
            child: _buildStatItem('Bots Ativos', activeBots.toString(), Icons.smart_toy, const Color(0xFF0066FF)),
          ),
          Container(width: 1, height: 40, color: Colors.white12),
          Expanded(
            child: _buildStatItem('Total Bots', _bots.length.toString(), Icons.grid_view, Colors.white70),
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
        Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11), textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildBotCard(TradingBot bot) {
    final status = bot.getStatus();
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
            color: bot.isRunning ? const Color(0xFF0066FF) : Colors.white.withOpacity(0.05),
            width: bot.isRunning ? 2 : 1,
          ),
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
                  child: Icon(_getStrategyIcon(bot.config.strategy), color: Colors.white, size: 28),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(bot.config.name, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(bot.config.description, style: const TextStyle(color: Colors.white54, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (status.tradeHistory.isNotEmpty) _buildMiniChart(status.tradeHistory, bot),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(child: _buildMetric('Trades', status.totalTrades.toString(), Colors.white70)),
                  Expanded(child: _buildMetric('Win Rate', '${winRate.toStringAsFixed(1)}%', winRate >= 50 ? const Color(0xFF00C896) : const Color(0xFFFF4444))),
                  Expanded(child: _buildMetric('Profit', '${isProfit ? '+' : ''}\$${status.sessionProfit.toStringAsFixed(2)}', isProfit ? const Color(0xFF00C896) : const Color(0xFFFF4444))),
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
                        bot.isPaused ? bot.resume() : bot.pause();
                      } else {
                        bot.start();
                      }
                      setState(() {});
                    },
                    icon: Icon(bot.isRunning ? (bot.isPaused ? Icons.play_arrow : Icons.pause) : Icons.play_arrow),
                    label: Text(bot.isRunning ? (bot.isPaused ? 'Continuar' : 'Pausar') : 'Iniciar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: bot.isRunning ? (bot.isPaused ? const Color(0xFF00C896) : const Color(0xFFFF9800)) : const Color(0xFF00C896),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                if (bot.isRunning) ...[
                  const SizedBox(width: 8),
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
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniChart(List<TradeRecord> history, TradingBot bot) {
    final cumulative = <double>[];
    double sum = 0;
    for (var profit in history.map((t) => t.profit)) {
      sum += profit;
      cumulative.add(sum);
    }

    return Container(
      height: 60,
      decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(8)),
      child: DerivAreaChart(
        points: cumulative,
        autoScale: true,
        showGradient: false,
        market: bot.config.market,
        onControllerCreated: (controller, market) {
          if (market == null) return;
          _chartControllers.putIfAbsent(market, () => []);
          if (!_chartControllers[market]!.contains(controller)) {
            _chartControllers[market]!.add(controller);
          }
        },
      ),
    );
  }

  Widget _buildMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  IconData _getStrategyIcon(BotStrategy strategy) {
    switch (strategy) {
      case BotStrategy.martingale: return Icons.trending_up;
      case BotStrategy.fibonacci: return Icons.stairs;
      case BotStrategy.dalembert: return Icons.analytics;
      case BotStrategy.labouchere: return Icons.calculate;
      case BotStrategy.oscarGrind: return Icons.slow_motion_video;
      case BotStrategy.paroli: return Icons.flash_on;
      case BotStrategy.antiMartingale: return Icons.trending_down;
      case BotStrategy.kellyFraction: return Icons.functions;
      case BotStrategy.pinkham: return Icons.healing;
      case BotStrategy.oneThreeTwoSix: return Icons.format_list_numbered;
      case BotStrategy.percentage: return Icons.percent;
      case BotStrategy.compound: return Icons.workspaces;
      case BotStrategy.recovery: return Icons.restore;
      case BotStrategy.adaptive: return Icons.settings_suggest;
      case BotStrategy.mlBased: return Icons.psychology;
    }
  }
}