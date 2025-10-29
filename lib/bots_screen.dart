import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'theme/app_theme.dart';
import 'theme/app_colors.dart';
import 'theme/app_widgets.dart';
import 'bot_engine.dart';
import 'bot_configuration.dart';
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
      // ============================================
      // 1. MARTINGALE PRO
      // ============================================
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
          estimatedPayout: 0.95,
        ),
        channel: _channel!,
        onStatusUpdate: (status) => setState(() {}),
      ),

      // ============================================
      // 2. PROGRESSIVE REINVESTMENT
      // ============================================
      TradingBot(
        config: BotConfiguration(
          name: 'Progressive Reinvestment',
          description: 'Reinveste lucros e recupera perdas automaticamente',
          strategy: BotStrategy.progressiveReinvestment,
          initialStake: 0.50,
          market: 'R_50',
          contractType: 'PUT',
          recoveryMode: RecoveryMode.moderate,
          entryConditions: [EntryCondition.immediate],
          maxStake: 40.0,
          targetProfit: 20.0,
          estimatedPayout: 0.95,
          roundsPerCycle: 3,
          totalCycles: 10,
          extraProfitPercent: 10.0,
          autoRecovery: true,
        ),
        channel: _channel!,
        onStatusUpdate: (status) => setState(() {}),
      ),

      // ============================================
      // 3. TRENDY ADAPTIVE
      // ============================================
      TradingBot(
        config: BotConfiguration(
          name: 'Trendy Adaptive',
          description: 'Lucro por tendência com ajuste dinâmico de stake',
          strategy: BotStrategy.trendyAdaptive,
          initialStake: 0.75,
          market: 'R_75',
          contractType: 'CALL',
          recoveryMode: RecoveryMode.conservative,
          entryConditions: [EntryCondition.trendSequence],
          useRSI: true,
          maxStake: 35.0,
          targetProfit: 15.0,
          estimatedPayout: 0.95,
          trendMultiplier: 1.5,
          recoveryMultiplier: 1.2,
          trendFilter: 2,
          profitReinvestPercent: 50.0,
        ),
        channel: _channel!,
        onStatusUpdate: (status) => setState(() {}),
      ),

      // ============================================
      // 4. ACS-R v3.0 (ADAPTIVE COMPOUND SMART RECOVERY)
      // ============================================
      TradingBot(
        config: BotConfiguration(
          name: 'ACS-R v3.0',
          description: 'Adaptação inteligente com aprendizado de padrão',
          strategy: BotStrategy.adaptiveCompoundRecovery,
          initialStake: 1.00,
          market: 'R_100',
          contractType: 'CALL',
          recoveryMode: RecoveryMode.intelligent,
          entryConditions: [EntryCondition.patternDetection],
          useRSI: true,
          usePatternRecognition: true,
          maxStake: 50.0,
          targetProfit: 25.0,
          estimatedPayout: 0.95,
          consistencyMultiplier: 1.15,
          confidenceFilter: 2,
          patternConfidence: 0.6,
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
    AppHaptics.selection();
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
    AppModalBottomSheet.show(
      context: context,
      title: 'Opções de Bots',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppListTile(
            leading: const Icon(Icons.add_circle_outline),
            title: 'Criar Novo Bot',
            subtitle: 'Configure um bot personalizado',
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              Navigator.pop(context);
              _showCreateBotDialog();
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          AppListTile(
            leading: const Icon(Icons.play_circle_outline),
            title: 'Iniciar Múltiplos Bots',
            subtitle: 'Ativar todos os bots disponíveis',
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              Navigator.pop(context);
              _startMultipleBots();
            },
          ),
        ],
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
    AppHaptics.medium();
    int startedBots = 0;
    for (var bot in _bots) {
      if (!bot.isRunning && _balance >= bot.currentStake) {
        bot.start();
        startedBots++;
      }
    }
    setState(() {});

    if (startedBots > 0) {
      AppSnackbar.success(context, '$startedBots bots iniciados');
    } else {
      AppSnackbar.warning(context, 'Nenhum bot disponível para iniciar');
    }
  }

  void _showEditStakeDialog(TradingBot bot) {
    AppHaptics.light();
    final stakeController = TextEditingController(text: bot.config.initialStake.toStringAsFixed(2));
    final maxStakeController = TextEditingController(text: bot.config.maxStake?.toStringAsFixed(2) ?? '50.00');

    showDialog(
      context: context,
      builder: (context) => AppDialog(
        title: 'Editar Configurações',
        icon: Icons.edit_rounded,
        iconColor: AppColors.primary,
        contentWidget: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              controller: stakeController,
              label: 'Stake Inicial (\$)',
              hint: '0.35',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              prefix: const Icon(Icons.attach_money_rounded),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: maxStakeController,
              label: 'Stake Máximo (\$)',
              hint: '50.00',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              prefix: const Icon(Icons.trending_up_rounded),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
            ),
          ],
        ),
        actions: [
          TertiaryButton(
            text: 'Cancelar',
            onPressed: () {
              AppHaptics.light();
              Navigator.pop(context);
            },
          ),
          PrimaryButton(
            text: 'Salvar',
            icon: Icons.check_rounded,
            onPressed: () {
              final newStake = double.tryParse(stakeController.text.replaceAll(',', '.'));
              final newMaxStake = double.tryParse(maxStakeController.text.replaceAll(',', '.'));

              if (newStake != null && newStake >= 0.35 && newMaxStake != null && newMaxStake >= newStake) {
                setState(() {
                  bot.config.initialStake = newStake;
                  bot.currentStake = newStake;
                  bot.config.maxStake = newMaxStake;
                });
                AppHaptics.success();
                Navigator.pop(context);
                AppSnackbar.success(context, 'Configurações atualizadas');
              } else {
                AppHaptics.error();
                AppSnackbar.error(
                  context,
                  'Stake mínimo é \$0.35 e Max Stake deve ser maior que Stake Inicial',
                );
              }
            },
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
      backgroundColor: context.surface,
      appBar: SecondaryAppBar(
        title: 'Trading Bots',
        showBackButton: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline_rounded),
            onPressed: _showOptionsMenu,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStatisticsHeader(activeBots, totalProfit),
          Expanded(
            child: _isConnected
                ? _bots.isEmpty
                    ? EmptyState(
                        icon: Icons.smart_toy_outlined,
                        title: 'Nenhum bot configurado',
                        subtitle: 'Crie seu primeiro bot de trading',
                        actionText: 'Criar Bot',
                        onAction: _showCreateBotDialog,
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        physics: const BouncingScrollPhysics(),
                        itemCount: _bots.length,
                        separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
                        itemBuilder: (context, index) => StaggeredListItem(
                          index: index,
                          delay: const Duration(milliseconds: 50),
                          child: _buildBotCard(_bots[index]),
                        ),
                      )
                : LoadingOverlay(
                    isLoading: true,
                    message: 'Conectando aos servidores...',
                    child: const SizedBox(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsHeader(int activeBots, double totalProfit) {
    return FadeInWidget(
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.lg),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: context.colors.surfaceContainer,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(
            color: context.colors.outlineVariant,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildStatItem(
                'Bots Ativos',
                activeBots.toString(),
                Icons.smart_toy_rounded,
                AppColors.primary,
              ),
            ),
            Container(
              width: 1,
              height: 40,
              color: context.colors.outlineVariant,
            ),
            Expanded(
              child: _buildStatItem(
                'Total Bots',
                _bots.length.toString(),
                Icons.grid_view_rounded,
                context.colors.onSurfaceVariant,
              ),
            ),
            Container(
              width: 1,
              height: 40,
              color: context.colors.outlineVariant,
            ),
            Expanded(
              child: _buildStatItem(
                'Lucro Total',
                '${totalProfit >= 0 ? '+' : ''}\$${totalProfit.toStringAsFixed(2)}',
                Icons.trending_up_rounded,
                totalProfit >= 0 ? AppColors.success : AppColors.error,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: AppSpacing.sm),
        Text(
          value,
          style: context.textStyles.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          label,
          style: context.textStyles.labelSmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildBotCard(TradingBot bot) {
    final status = bot.getStatus();
    final winRate = status.winRate * 100;
    final isProfit = status.sessionProfit >= 0;

    return AnimatedCard(
      onTap: () => _showBotDetails(bot),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: context.colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(
            color: bot.isRunning ? AppColors.primary : context.colors.outlineVariant,
            width: bot.isRunning ? 2 : 1,
          ),
        ),
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
                        ? AppColors.primary
                        : context.colors.surfaceContainer,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Icon(
                    _getStrategyIcon(bot.config.strategy),
                    color: bot.isRunning
                        ? Colors.white
                        : context.colors.onSurfaceVariant,
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
                              style: context.textStyles.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
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
                        style: context.textStyles.bodySmall?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
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
                color: context.colors.surfaceContainer,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildMetric(
                      'Trades',
                      status.totalTrades.toString(),
                      context.colors.onSurfaceVariant,
                    ),
                  ),
                  Expanded(
                    child: _buildMetric(
                      'Win Rate',
                      '${winRate.toStringAsFixed(1)}%',
                      winRate >= 50 ? AppColors.success : AppColors.error,
                    ),
                  ),
                  Expanded(
                    child: _buildMetric(
                      'Profit',
                      '${isProfit ? '+' : ''}\$${status.sessionProfit.toStringAsFixed(2)}',
                      isProfit ? AppColors.success : AppColors.error,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: context.colors.surfaceContainer,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.attach_money_rounded,
                        color: context.colors.onSurfaceVariant,
                        size: 16,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'Stake Atual',
                        style: context.textStyles.bodySmall?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        '\$${status.currentStake.toStringAsFixed(2)}',
                        style: context.textStyles.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (!bot.isRunning) ...[
                        const SizedBox(width: AppSpacing.sm),
                        IconButtonWithBackground(
                          icon: Icons.edit_rounded,
                          onPressed: () => _showEditStakeDialog(bot),
                          backgroundColor: AppColors.primary.withOpacity(0.15),
                          iconColor: AppColors.primary,
                          size: 32,
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
        Text(
          label,
          style: context.textStyles.labelSmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          value,
          style: context.textStyles.titleSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  IconData _getStrategyIcon(BotStrategy strategy) {
    switch (strategy) {
      case BotStrategy.martingale:
        return Icons.trending_up_rounded;
      case BotStrategy.progressiveReinvestment:
        return Icons.autorenew_rounded;
      case BotStrategy.trendyAdaptive:
        return Icons.insights_rounded;
      case BotStrategy.adaptiveCompoundRecovery:
        return Icons.psychology_rounded;
      default:
        return Icons.smart_toy_rounded;
    }
  }
}