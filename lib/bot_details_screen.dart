// bot_details_screen.dart - ATUALIZADO COM ESTRATÉGIAS
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'bot_engine.dart';
import 'bot_configuration.dart';
import 'deriv_chart_widget.dart';
import 'theme/app_theme.dart';
import 'theme/app_colors.dart';
import 'theme/app_widgets.dart';

class BotDetailsScreen extends StatefulWidget {
  final TradingBot bot;
  final Function() onUpdate;
  final Map<String, List<double>> marketPrices;

  const BotDetailsScreen({
    Key? key,
    required this.bot,
    required this.onUpdate,
    required this.marketPrices,
  }) : super(key: key);

  @override
  State<BotDetailsScreen> createState() => _BotDetailsScreenState();
}

class _BotDetailsScreenState extends State<BotDetailsScreen> {
  Timer? _updateTimer;
  WebViewController? _chartController;
  final ScrollController _scrollController = ScrollController();
  bool _isChartVisible = true;

  @override
  void initState() {
    super.initState();
    _updateTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) {
        setState(() {});
        _updateChart();
      }
    });
    _scrollController.addListener(_handleScroll);
  }

  void _handleScroll() {
    if (_scrollController.hasClients) {
      final offset = _scrollController.offset;
      final chartHeight = MediaQuery.of(context).size.width;
      setState(() => _isChartVisible = offset < chartHeight);
    }
  }

  void _updateChart() {
    if (_chartController != null && _isChartVisible) {
      final marketData = widget.marketPrices[widget.bot.config.market] ?? [];
      if (marketData.isNotEmpty) {
        final jsArray = marketData.map((p) => p.toString()).join(',');
        final script = "try{ updateData([${jsArray}]); }catch(e){};";
        try {
          _chartController!.runJavaScript(script);
        } catch (_) {}
      }
    }
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _showStopConfirmation() {
    AppHaptics.heavy();
    showDialog(
      context: context,
      builder: (context) => AppDialog(
        title: 'Parar Bot?',
        icon: Icons.stop_circle_rounded,
        iconColor: AppColors.error,
        contentWidget: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tem certeza que deseja parar este bot?'),
            SizedBox(height: AppSpacing.sm),
            Text(
              'Todas as operações em andamento serão finalizadas.',
              style: TextStyle(fontSize: 12),
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
            text: 'Parar',
            icon: Icons.stop_rounded,
            onPressed: () async {
              widget.bot.stop();
              AppHaptics.success();
              Navigator.pop(context);
              widget.onUpdate();
              setState(() {});
              AppSnackbar.success(context, 'Bot parado');
            },
          ),
        ],
      ),
    );
  }

  void _showConfigDialog() {
    String selectedMarket = widget.bot.config.market;
    final stakeController = TextEditingController(
      text: widget.bot.config.initialStake.toStringAsFixed(2),
    );
    final maxStakeController = TextEditingController(
      text: widget.bot.config.maxStake?.toStringAsFixed(2) ?? '',
    );
    final targetProfitController = TextEditingController(
      text: widget.bot.config.targetProfit.toStringAsFixed(2),
    );

    AppHaptics.light();
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AppDialog(
          title: 'Configurações',
          icon: Icons.tune_rounded,
          iconColor: AppColors.primary,
          contentWidget: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mercado',
                  style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: AppSpacing.sm),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: context.colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                    border: Border.all(color: context.colors.outlineVariant, width: 1),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: selectedMarket,
                      isExpanded: true,
                      icon: Icon(Icons.keyboard_arrow_down_rounded),
                      items: _getAvailableMarkets().map((market) {
                        return DropdownMenuItem<String>(
                          value: market['value'] as String,
                          child: Row(
                            children: [
                              Icon(market['icon'] as IconData, size: 20, color: context.colors.primary),
                              SizedBox(width: AppSpacing.sm),
                              Text(market['name'] as String),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => selectedMarket = value);
                          AppHaptics.light();
                        }
                      },
                    ),
                  ),
                ),
                SizedBox(height: AppSpacing.xl),
                Text(
                  'Valores de Trading',
                  style: context.textStyles.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: AppSpacing.sm),
                AppTextField(
                  controller: stakeController,
                  label: 'Stake Inicial (\$)',
                  hint: 'Ex: 0.35',
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  prefix: Icon(Icons.attach_money_rounded, size: 20),
                ),
                SizedBox(height: AppSpacing.lg),
                AppTextField(
                  controller: maxStakeController,
                  label: 'Stake Máximo (\$) - Opcional',
                  hint: 'Ex: 10.00',
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  prefix: Icon(Icons.trending_up_rounded, size: 20),
                ),
                SizedBox(height: AppSpacing.lg),
                AppTextField(
                  controller: targetProfitController,
                  label: 'Target Profit (\$)',
                  hint: 'Ex: 5.00',
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  prefix: Icon(Icons.flag_rounded, size: 20),
                ),
              ],
            ),
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
              onPressed: () {
                final newStake = double.tryParse(stakeController.text.replaceAll(',', '.'));
                final newMaxStake = maxStakeController.text.isEmpty 
                    ? null 
                    : double.tryParse(maxStakeController.text.replaceAll(',', '.'));
                final newTargetProfit = double.tryParse(targetProfitController.text.replaceAll(',', '.'));

                if (newStake != null && newStake >= 0.35 &&
                    (newMaxStake == null || newMaxStake >= newStake) &&
                    newTargetProfit != null && newTargetProfit > 0) {
                  AppHaptics.success();
                  setState(() {
                    widget.bot.config.market = selectedMarket;
                    widget.bot.config.initialStake = newStake;
                    widget.bot.currentStake = newStake;
                    widget.bot.config.maxStake = newMaxStake;
                    widget.bot.config.targetProfit = newTargetProfit;
                  });
                  widget.onUpdate();

                  if (_chartController != null) {
                    final escaped = selectedMarket.replaceAll("'", "\\'").replaceAll('"', '\\"');
                    final script = "try{ setMarket('$escaped'); }catch(e){ console.log('setMarket err', e); };";
                    _chartController!.runJavaScript(script);
                  }

                  Navigator.pop(context);
                  AppSnackbar.success(context, 'Configurações salvas');
                } else {
                  AppHaptics.error();
                  AppSnackbar.error(context, 'Valores inválidos');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> _getAvailableMarkets() {
    return [
      {'name': 'Volatility 10 Index', 'value': 'R_10', 'icon': Icons.show_chart_rounded},
      {'name': 'Volatility 25 Index', 'value': 'R_25', 'icon': Icons.show_chart_rounded},
      {'name': 'Volatility 50 Index', 'value': 'R_50', 'icon': Icons.show_chart_rounded},
      {'name': 'Volatility 75 Index', 'value': 'R_75', 'icon': Icons.show_chart_rounded},
      {'name': 'Volatility 100 Index', 'value': 'R_100', 'icon': Icons.show_chart_rounded},
      {'name': 'Volatility 10 (1s) Index', 'value': '1HZ10V', 'icon': Icons.speed_rounded},
      {'name': 'Volatility 25 (1s) Index', 'value': '1HZ25V', 'icon': Icons.speed_rounded},
      {'name': 'Volatility 50 (1s) Index', 'value': '1HZ50V', 'icon': Icons.speed_rounded},
      {'name': 'Volatility 75 (1s) Index', 'value': '1HZ75V', 'icon': Icons.speed_rounded},
      {'name': 'Volatility 100 (1s) Index', 'value': '1HZ100V', 'icon': Icons.speed_rounded},
      {'name': 'Crash 300 Index', 'value': 'CRASH300N', 'icon': Icons.trending_down_rounded},
      {'name': 'Crash 500 Index', 'value': 'CRASH500', 'icon': Icons.trending_down_rounded},
      {'name': 'Crash 1000 Index', 'value': 'CRASH1000', 'icon': Icons.trending_down_rounded},
      {'name': 'Boom 300 Index', 'value': 'BOOM300N', 'icon': Icons.trending_up_rounded},
      {'name': 'Boom 500 Index', 'value': 'BOOM500', 'icon': Icons.trending_up_rounded},
      {'name': 'Boom 1000 Index', 'value': 'BOOM1000', 'icon': Icons.trending_up_rounded},
      {'name': 'Jump 10 Index', 'value': 'JD10', 'icon': Icons.arrow_upward_rounded},
      {'name': 'Jump 25 Index', 'value': 'JD25', 'icon': Icons.arrow_upward_rounded},
      {'name': 'Jump 50 Index', 'value': 'JD50', 'icon': Icons.arrow_upward_rounded},
      {'name': 'Jump 75 Index', 'value': 'JD75', 'icon': Icons.arrow_upward_rounded},
      {'name': 'Jump 100 Index', 'value': 'JD100', 'icon': Icons.arrow_upward_rounded},
      {'name': 'Step Index', 'value': 'stpRNG', 'icon': Icons.stairs_rounded},
      {'name': 'Range Break 100 Index', 'value': 'RDBULL', 'icon': Icons.analytics_rounded},
      {'name': 'Range Break 200 Index', 'value': 'RDBEAR', 'icon': Icons.analytics_rounded},
    ];
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.bot.getStatus();
    final winRate = status.winRate * 100;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: context.colors.surface,
      appBar: AppBar(
        backgroundColor: context.colors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Theme.of(context).brightness == Brightness.dark 
              ? Brightness.light 
              : Brightness.dark,
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded),
          onPressed: () {
            AppHaptics.light();
            Navigator.pop(context);
          },
        ),
        title: Text(
          widget.bot.config.name,
          style: context.textStyles.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.tune_rounded),
            onPressed: _showConfigDialog,
          ),
        ],
      ),
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _buildSquareChart(screenWidth)),
          SliverPadding(
            padding: EdgeInsets.all(AppSpacing.lg),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildProfitCard(status),
                SizedBox(height: AppSpacing.lg),
                _buildControlButtons(),
                SizedBox(height: AppSpacing.xl),
                _buildStrategyCard(status),
                SizedBox(height: AppSpacing.xl),
                Text('Estatísticas', style: context.textStyles.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                SizedBox(height: AppSpacing.md),
                _buildStatisticsGrid(status, winRate),
                SizedBox(height: AppSpacing.xl),
                _buildTradeHistory(status),
                SizedBox(height: AppSpacing.massive),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStrategyCard(BotStatus status) {
    final strategy = widget.bot.config.strategy;
    
    String title;
    IconData icon;
    Color color;
    List<Widget> metrics;

    switch (strategy) {
      case BotStrategy.martingale:
        title = '🎯 Martingale Pro';
        icon = Icons.trending_up_rounded;
        color = AppColors.primary;
        metrics = [
          _buildStrategyMetric('Perdas Acumuladas', '\$${widget.bot.lossStreakAmount.toStringAsFixed(2)}', Icons.warning_rounded, AppColors.warning),
          _buildStrategyMetric('Perdas Consecutivas', '${status.consecutiveLosses}', Icons.close_rounded, AppColors.error),
          _buildStrategyMetric('Payout Estimado', '${(widget.bot.config.estimatedPayout * 100).toStringAsFixed(0)}%', Icons.percent_rounded, AppColors.info),
        ];
        break;

      case BotStrategy.progressiveReinvestment:
        title = '🔄 Progressive Reinvestment';
        icon = Icons.autorenew_rounded;
        color = AppColors.secondary;
        metrics = [
          _buildStrategyMetric('Ciclo Atual', '${status.currentCycle}/${widget.bot.config.totalCycles}', Icons.repeat_rounded, AppColors.primary),
          _buildStrategyMetric('Rodada no Ciclo', '${status.currentRound}/${widget.bot.config.roundsPerCycle}', Icons.layers_rounded, AppColors.info),
          _buildStrategyMetric('Lucro do Ciclo', '\$${status.cycleProfit.toStringAsFixed(2)}', Icons.monetization_on_rounded, status.cycleProfit >= 0 ? AppColors.success : AppColors.error),
          _buildStrategyMetric('Perdas no Ciclo', '\$${widget.bot.cycleTotalLosses.toStringAsFixed(2)}', Icons.trending_down_rounded, AppColors.warning),
        ];
        break;

      case BotStrategy.trendyAdaptive:
        title = '📊 Trendy Adaptive';
        icon = Icons.insights_rounded;
        color = AppColors.tertiary;
        metrics = [
          _buildStrategyMetric('Fase', _getTrendPhase(widget.bot.trendPhase), Icons.timeline_rounded, AppColors.info),
          _buildStrategyMetric('Tendência Detectada', status.trendDetected ? 'Sim' : 'Não', Icons.check_circle_rounded, status.trendDetected ? AppColors.success : AppColors.error),
          _buildStrategyMetric('Banco de Lucro', '\$${widget.bot.profitBank.toStringAsFixed(2)}', Icons.savings_rounded, AppColors.success),
          _buildStrategyMetric('Multiplicador Mt', '${widget.bot.config.trendMultiplier}x', Icons.close_fullscreen_rounded, AppColors.primary),
        ];
        break;

      case BotStrategy.adaptiveCompoundRecovery:
        title = '🧠 ACS-R v3.0';
        icon = Icons.psychology_rounded;
        color = AppColors.info;
        metrics = [
          _buildStrategyMetric('Direção Ativa', status.trendDirection, Icons.navigation_rounded, AppColors.primary),
          _buildStrategyMetric('Banco de Lucro', '\$${widget.bot.acsrProfitBank.toStringAsFixed(2)}', Icons.account_balance_wallet_rounded, AppColors.success),
          _buildStrategyMetric('Perdas Acumuladas', '\$${widget.bot.acsrLossAccumulated.toStringAsFixed(2)}', Icons.warning_amber_rounded, AppColors.warning),
          _buildStrategyMetric('Padrões Detectados', '${widget.bot.last5Results.length}/5', Icons.pattern_rounded, AppColors.info),
        ];
        break;

      default:
        return SizedBox.shrink();
    }

    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Parâmetros da Estratégia',
                      style: context.textStyles.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.lg),
          ...metrics,
        ],
      ),
    );
  }

  Widget _buildStrategyMetric(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              label,
              style: context.textStyles.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant),
            ),
          ),
          Text(
            value,
            style: context.textStyles.titleSmall?.copyWith(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _getTrendPhase(String phase) {
    switch (phase) {
      case 'observation':
        return 'Observação';
      case 'execution':
        return 'Execução';
      case 'recovery':
        return 'Recuperação';
      default:
        return 'Desconhecida';
    }
  }

  Widget _buildSquareChart(double size) {
    final marketData = widget.marketPrices[widget.bot.config.market] ?? [];
    final chartData = marketData.isEmpty ? [100.0] : marketData;

    return SizedBox(
      width: size,
      height: size,
      child: DerivAreaChart(
        points: chartData,
        autoScale: true,
        showGradient: false,
        market: widget.bot.config.market,
        height: size,
        onControllerCreated: (controller, market) {
          _chartController = controller;
        },
      ),
    );
  }

  Widget _buildProfitCard(BotStatus status) {
    final isProfit = status.sessionProfit >= 0;
    final profitColor = isProfit ? AppColors.success : AppColors.error;

    return Container(
      padding: EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: profitColor.withOpacity(0.3), width: 2),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isProfit ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                          color: profitColor,
                          size: 20,
                        ),
                        SizedBox(width: AppSpacing.xs),
                        Text(
                          'Lucro da Sessão',
                          style: context.textStyles.bodyMedium?.copyWith(
                            color: context.colors.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpacing.sm),
                    Text(
                      '${isProfit ? '+' : ''}\$${status.sessionProfit.toStringAsFixed(2)}',
                      style: context.textStyles.displaySmall?.copyWith(
                        color: profitColor,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -1,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: status.isRunning
                      ? AppColors.success.withOpacity(0.15)
                      : context.colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: status.isRunning ? AppColors.success : context.colors.onSurfaceVariant,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: AppSpacing.xs),
                    Text(
                      status.isRunning ? 'Ativo' : 'Parado',
                      style: context.textStyles.labelMedium?.copyWith(
                        color: status.isRunning ? AppColors.success : context.colors.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(child: _buildMiniStat('Win Rate', '${(status.winRate * 100).toStringAsFixed(1)}%', Icons.percent_rounded)),
              Container(width: 1, height: 40, color: context.colors.outlineVariant),
              Expanded(child: _buildMiniStat('Trades', status.totalTrades.toString(), Icons.swap_horiz_rounded)),
              Container(width: 1, height: 40, color: context.colors.outlineVariant),
              Expanded(child: _buildMiniStat('Streak', '${status.consecutiveWins - status.consecutiveLosses}', Icons.local_fire_department_rounded)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: context.colors.primary, size: 18),
        SizedBox(height: AppSpacing.xs),
        Text(value, style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        Text(label, style: context.textStyles.bodySmall?.copyWith(color: context.colors.onSurfaceVariant)),
      ],
    );
  }

  Widget _buildControlButtons() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: PrimaryButton(
            text: widget.bot.isRunning
                ? (widget.bot.isPaused ? 'Continuar' : 'Pausar')
                : 'Iniciar Trade',
            icon: widget.bot.isRunning
                ? (widget.bot.isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded)
                : Icons.rocket_launch_rounded,
            onPressed: () async {
              AppHaptics.medium();
              if (widget.bot.isRunning) {
                widget.bot.isPaused ? widget.bot.resume() : widget.bot.pause();
              } else {
                widget.bot.start();
              }
              widget.onUpdate();
              setState(() {});
            },
            expanded: true,
          ),
        ),
        if (widget.bot.isRunning) ...[
          SizedBox(width: AppSpacing.md),
          Expanded(
            flex: 1,
            child: IconButtonWithBackground(
              icon: Icons.stop_rounded,
              onPressed: _showStopConfirmation,
              backgroundColor: AppColors.error,
              iconColor: Colors.white,
              size: 56,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatisticsGrid(BotStatus status, double winRate) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
      childAspectRatio: 1.4,
      children: [
        _buildStatCard('Total Profit', '\$${status.totalProfit.toStringAsFixed(2)}', status.totalProfit >= 0 ? AppColors.success : AppColors.error, Icons.account_balance_wallet_rounded),
        _buildStatCard('Win Rate', '${winRate.toStringAsFixed(1)}%', winRate >= 50 ? AppColors.success : AppColors.error, Icons.trending_up_rounded),
        _buildStatCard('Avg Win', '\$${status.avgWin.toStringAsFixed(2)}', AppColors.success, Icons.arrow_upward_rounded),
        _buildStatCard('Avg Loss', '\$${status.avgLoss.toStringAsFixed(2)}', AppColors.error, Icons.arrow_downward_rounded),
        _buildStatCard('Current RSI', status.currentRSI.toStringAsFixed(0), AppColors.info, Icons.speed_rounded),
        _buildStatCard('Stake Atual', '\$${status.currentStake.toStringAsFixed(2)}', context.colors.primary, Icons.attach_money_rounded),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: context.colors.outlineVariant, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: context.textStyles.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            label,
            style: context.textStyles.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTradeHistory(BotStatus status) {
    if (status.tradeHistory.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Histórico de Trades',
            style: context.textStyles.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: AppSpacing.md),
          EmptyState(
            icon: Icons.history_rounded,
            title: 'Nenhum trade ainda',
            subtitle: 'Os trades aparecerão aqui',
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Histórico de Trades',
              style: context.textStyles.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${status.tradeHistory.length} trades',
              style: context.textStyles.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        SizedBox(height: AppSpacing.md),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: status.tradeHistory.take(20).length,
          itemBuilder: (context, index) {
            final trade = status.tradeHistory[status.tradeHistory.length - 1 - index];
            final isWin = trade.won;

            return Container(
              margin: EdgeInsets.only(bottom: AppSpacing.sm),
              padding: EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: context.colors.surfaceContainer,
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(
                  color: isWin
                      ? AppColors.success.withOpacity(0.3)
                      : AppColors.error.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isWin
                          ? AppColors.success.withOpacity(0.15)
                          : AppColors.error.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isWin
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      color: isWin ? AppColors.success : AppColors.error,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isWin ? 'WIN' : 'LOSS',
                          style: context.textStyles.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Stake: \$${trade.stake.toStringAsFixed(2)} • ${trade.timestamp.hour}:${trade.timestamp.minute.toString().padLeft(2, '0')}',
                          style: context.textStyles.bodySmall?.copyWith(
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${trade.profit >= 0 ? '+' : ''}\$${trade.profit.toStringAsFixed(2)}',
                    style: context.textStyles.titleMedium?.copyWith(
                      color: isWin ? AppColors.success : AppColors.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}