// lib/bots_screen.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'styles.dart';
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
    AppHaptics.light();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppShapes.extraLarge)),
        ),
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.colors.outlineVariant,
                borderRadius: BorderRadius.circular(AppShapes.full),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('Opções', style: context.textStyles.headlineSmall),
            const SizedBox(height: AppSpacing.lg),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppShapes.medium),
                ),
                child: const Icon(Icons.add_circle_outline, color: AppColors.primary),
              ),
              title: const Text('Criar Novo Bot'),
              subtitle: const Text('Configure um novo bot de trading'),
              onTap: () {
                Navigator.pop(context);
                _showCreateBotDialog();
              },
            ),
            const SizedBox(height: AppSpacing.sm),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppShapes.medium),
                ),
                child: const Icon(Icons.play_circle_outline, color: AppColors.success),
              ),
              title: const Text('Iniciar Múltiplos Bots'),
              subtitle: const Text('Ative todos os bots disponíveis'),
              onTap: () {
                Navigator.pop(context);
                _startMultipleBots();
              },
            ),
            const SizedBox(height: AppSpacing.md),
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
    AppHaptics.heavy();
    int started = 0;
    for (var bot in _bots) {
      if (!bot.isRunning && _balance >= bot.currentStake) {
        bot.start();
        started++;
      }
    }
    setState(() {});
    if (started > 0) {
      AppSnackbar.success(context, '$started bots iniciados com sucesso!');
    } else {
      AppSnackbar.warning(context, 'Nenhum bot disponível para iniciar');
    }
  }

  void _showEditStakeDialog(TradingBot bot) {
    AppHaptics.light();
    final stakeController = TextEditingController(text: bot.config.initialStake.toStringAsFixed(2));
    final maxStakeController = TextEditingController(text: bot.config.maxStake.toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Configurações'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: stakeController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Stake Inicial (\$)',
                hintText: '0.35',
                prefixIcon: Icon(Icons.attach_money_rounded),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: maxStakeController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Stake Máximo (\$)',
                hintText: '50.00',
                prefixIcon: Icon(Icons.account_balance_wallet_rounded),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              AppHaptics.light();
              Navigator.pop(context);
            },
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final newStake = double.tryParse(stakeController.text.replaceAll(',', '.'));
              final newMaxStake = double.tryParse(maxStakeController.text.replaceAll(',', '.'));

              if (newStake != null && newStake >= 0.35 && newMaxStake != null && newMaxStake >= newStake) {
                AppHaptics.heavy();
                setState(() {
                  bot.config.initialStake = newStake;
                  bot.currentStake = newStake;
                  bot.config.maxStake = newMaxStake;
                });
                Navigator.pop(context);
                AppSnackbar.success(context, 'Configurações atualizadas!');
              } else {
                AppHaptics.error();
                AppSnackbar.error(context, 'Stake mínimo é \$0.35 e Max Stake deve ser maior');
              }
            },
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
      appBar: AppBar(
        title: const Text('Trading Bots'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: _showOptionsMenu,
          ),
        ],
      ),
      body: _isConnected
          ? Column(
              children: [
                FadeInWidget(
                  child: _buildStatisticsHeader(activeBots, totalProfit),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      await Future.delayed(AppMotion.long);
                      setState(() {});
                      if (mounted) {
                        AppSnackbar.success(context, 'Dados atualizados');
                      }
                    },
                    child: ListView.separated(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      itemCount: _bots.length,
                      separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
                      itemBuilder: (context, index) => StaggeredListItem(
                        index: index,
                        child: _buildBotCard(_bots[index]),
                      ),
                    ),
                  ),
                ),
              ],
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Conectando ao servidor...',
                    style: context.textStyles.bodyLarge?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatisticsHeader(int activeBots, double totalProfit) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: StatsCard(
              label: 'Bots Ativos',
              value: activeBots.toString(),
              icon: Icons.smart_toy_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: StatsCard(
              label: 'Total',
              value: _bots.length.toString(),
              icon: Icons.grid_view_rounded,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: StatsCard(
              label: 'Lucro',
              value: '${totalProfit >= 0 ? '+' : ''}\$${totalProfit.toStringAsFixed(2)}',
              icon: Icons.trending_up_rounded,
              color: totalProfit >= 0 ? AppColors.success : AppColors.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotCard(TradingBot bot) {
    final status = bot.getStatus();
    final winRate = status.winRate * 100;
    final isProfit = status.sessionProfit >= 0;

    return AnimatedCard(
      onTap: () {
        AppHaptics.selection();
        _showBotDetails(bot);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: bot.isRunning 
                      ? AppColors.primary.withOpacity(0.15)
                      : context.colors.surfaceVariant,
                  borderRadius: BorderRadius.circular(AppShapes.medium),
                ),
                child: Icon(
                  _getStrategyIcon(bot.config.strategy),
                  color: bot.isRunning ? AppColors.primary : context.colors.onSurfaceVariant,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            bot.config.name,
                            style: context.textStyles.titleMedium,
                          ),
                        ),
                        if (bot.isRunning)
                          AppBadge(
                            text: 'Ativo',
                            color: AppColors.success,
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      bot.config.description,
                      style: context.textStyles.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: context.colors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppShapes.medium),
            ),
            child: Row(
              children: [
                Expanded(child: _buildMetric('Trades', status.totalTrades.toString(), context.colors.onSurfaceVariant)),
                Expanded(child: _buildMetric('Win Rate', '${winRate.toStringAsFixed(1)}%', winRate >= 50 ? AppColors.success : AppColors.error)),
                Expanded(child: _buildMetric('Profit', '${isProfit ? '+' : ''}\$${status.sessionProfit.toStringAsFixed(2)}', isProfit ? AppColors.success : AppColors.error)),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.attach_money_rounded, size: 16, color: context.colors.onSurfaceVariant),
                  const SizedBox(width: AppSpacing.xs),
                  Text('Stake:', style: context.textStyles.bodySmall),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '\$${status.currentStake.toStringAsFixed(2)}',
                    style: context.textStyles.titleSmall?.copyWith(color: AppColors.primary),
                  ),
                ],
              ),
              if (!bot.isRunning)
                IconButton(
                  icon: const Icon(Icons.edit_rounded, size: 20),
                  onPressed: () => _showEditStakeDialog(bot),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primary.withOpacity(0.15),
                    foregroundColor: AppColors.primary,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: context.textStyles.labelSmall),
        const SizedBox(height: AppSpacing.xxs),
        Text(value, style: context.textStyles.titleSmall?.copyWith(color: color)),
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