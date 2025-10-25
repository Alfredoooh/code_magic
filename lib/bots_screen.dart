// lib/bots_screen.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
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
          initialStake: 0.35,
          market: 'R_100',
          contractType: 'CALL',
          recoveryMode: RecoveryMode.intelligent,
          entryConditions: [EntryCondition.immediate],
          maxConsecutiveLosses: 7,
          maxStake: 50.0,
          targetProfit: 10.0,
        ),
        channel: _channel!,
        onStatusUpdate: (status) => setState(() {}),
      ),
      TradingBot(
        config: BotConfiguration(
          name: 'Fibonacci Master',
          description: 'Estratégia Fibonacci com análise RSI',
          strategy: BotStrategy.fibonacci,
          initialStake: 0.50,
          market: 'R_50',
          contractType: 'PUT',
          recoveryMode: RecoveryMode.moderate,
          entryConditions: [EntryCondition.rsiOversold],
          useRSI: true,
          maxStake: 40.0,
          targetProfit: 15.0,
        ),
        channel: _channel!,
        onStatusUpdate: (status) => setState(() {}),
      ),
      TradingBot(
        config: BotConfiguration(
          name: 'D\'Alembert Safe',
          description: 'Crescimento gradual com segurança',
          strategy: BotStrategy.dalembert,
          initialStake: 0.75,
          market: 'R_75',
          contractType: 'CALL',
          recoveryMode: RecoveryMode.conservative,
          maxStake: 30.0,
        ),
        channel: _channel!,
        onStatusUpdate: (status) => setState(() {}),
      ),
      TradingBot(
        config: BotConfiguration(
          name: 'Adaptive AI',
          description: 'Adaptação inteligente ao mercado',
          strategy: BotStrategy.adaptive,
          initialStake: 1.00,
          market: 'R_100',
          contractType: 'CALL',
          recoveryMode: RecoveryMode.intelligent,
          useRSI: true,
          maxStake: 50.0,
          targetProfit: 20.0,
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
          onUpdate: () => setState(() {}),
          marketPrices: _marketPrices,
        ),
      ),
    );
  }

  void _showOptionsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add_circle_outline, color: Color(0xFFFF8C00)),
              title: const Text('Criar Novo Bot', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _showCreateBotDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.play_circle_outline, color: Color(0xFFFF8C00)),
              title: const Text('Iniciar Múltiplos Bots', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _startMultipleBots();
              },
            ),
          ],
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

  void _startMultipleBots() {
    for (var bot in _bots) {
      if (!bot.isRunning && _balance >= bot.currentStake) {
        bot.start();
      }
    }
    setState(() {});
  }

  void _showEditStakeDialog(TradingBot bot) {
    final stakeController = TextEditingController(text: bot.config.initialStake.toStringAsFixed(2));
    final maxStakeController = TextEditingController(text: bot.config.maxStake.toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Editar Configurações', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: stakeController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Stake Inicial (\$)',
                labelStyle: const TextStyle(color: Colors.white54),
                hintText: '0.35',
                hintStyle: const TextStyle(color: Colors.white24),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.white24),
                  borderRadius: BorderRadius.circular(16),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFFFF8C00)),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: maxStakeController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Stake Máximo (\$)',
                labelStyle: const TextStyle(color: Colors.white54),
                hintText: '50.00',
                hintStyle: const TextStyle(color: Colors.white24),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.white24),
                  borderRadius: BorderRadius.circular(16),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFFFF8C00)),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              final newStake = double.tryParse(stakeController.text.replaceAll(',', '.'));
              final newMaxStake = double.tryParse(maxStakeController.text.replaceAll(',', '.'));

              if (newStake != null && newStake >= 0.35 && newMaxStake != null && newMaxStake >= newStake) {
                setState(() {
                  bot.config.initialStake = newStake;
                  bot.currentStake = newStake;
                  bot.config.maxStake = newMaxStake;
                });
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Stake mínimo é \$0.35 e Max Stake deve ser maior que Stake Inicial'),
                    backgroundColor: Color(0xFFFF4444),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF8C00),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Salvar'),
          ),
        ],
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
        elevation: 0,
        backgroundColor: const Color(0xFF1A1A1A),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Trading Bots'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF8C00),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
              ),
              onPressed: _showOptionsMenu,
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
                        CircularProgressIndicator(color: Color(0xFFFF8C00)),
                        SizedBox(height: 16),
                        Text('Conectando...', style: TextStyle(color: Colors.white54)),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsHeader(int activeBots, double totalProfit) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem('Bots Ativos', activeBots.toString(), Icons.smart_toy_rounded, const Color(0xFFFF8C00)),
          ),
          Container(width: 1, height: 40, color: const Color(0xFF2A2A2A)),
          Expanded(
            child: _buildStatItem('Total Bots', _bots.length.toString(), Icons.grid_view_rounded, Colors.white70),
          ),
          Container(width: 1, height: 40, color: const Color(0xFF2A2A2A)),
          Expanded(
            child: _buildStatItem(
              'Lucro Total',
              '${totalProfit >= 0 ? '+' : ''}\$${totalProfit.toStringAsFixed(2)}',
              Icons.trending_up_rounded,
              totalProfit >= 0 ? const Color(0xFFFF8C00) : const Color(0xFFFF4444),
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
    final status = bot.getStatus(); // CORRIGIDO: removido underscore
    final winRate = status.winRate * 100;
    final isProfit = status.sessionProfit >= 0;

    return GestureDetector(
      onTap: () => _showBotDetails(bot),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: bot.isRunning ? const Color(0xFFFF8C00) : const Color(0xFF2A2A2A),
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
                    color: bot.isRunning ? const Color(0xFFFF8C00) : const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(16),
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
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(child: _buildMetric('Trades', status.totalTrades.toString(), Colors.white70)),
                  Expanded(child: _buildMetric('Win Rate', '${winRate.toStringAsFixed(1)}%', winRate >= 50 ? const Color(0xFFFF8C00) : const Color(0xFFFF4444))),
                  Expanded(child: _buildMetric('Profit', '${isProfit ? '+' : ''}\$${status.sessionProfit.toStringAsFixed(2)}', isProfit ? const Color(0xFFFF8C00) : const Color(0xFFFF4444))),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.attach_money_rounded, color: Colors.white70, size: 16),
                      SizedBox(width: 6),
                      Text('Stake Inicial', style: TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        '\$${status.currentStake.toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                      if (!bot.isRunning) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _showEditStakeDialog(bot),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF8C00),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.edit_rounded, color: Colors.white, size: 14),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
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
      case BotStrategy.martingale: return Icons.trending_up_rounded;
      case BotStrategy.fibonacci: return Icons.stairs_rounded;
      case BotStrategy.dalembert: return Icons.analytics_rounded;
      case BotStrategy.adaptive: return Icons.settings_suggest_rounded;
      default: return Icons.smart_toy_rounded;
    }
  }
}