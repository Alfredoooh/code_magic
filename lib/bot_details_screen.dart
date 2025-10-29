// lib/bot_details_screen.dart
// Tela de detalhes e controle do bot com chart em tempo real
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'bot_engine.dart';
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

  @override
  void initState() {
    super.initState();
    _updateTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) {
        setState(() {});
        _updateChart();
      }
    });
  }

  void _updateChart() {
    if (_chartController != null) {
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
            onPressed: () {
              widget.bot.stop();
              AppHaptics.success();
              Navigator.pop(context);
              widget.onUpdate();
              setState(() {});
              AppSnackbar.success(context, 'Bot parado com sucesso');
            },
          ),
        ],
      ),
    );
  }

  void _showConfigDialog() {
    final stakeController = TextEditingController(
      text: widget.bot.config.initialStake.toStringAsFixed(2),
    );
    final maxStakeController = TextEditingController(
      text: widget.bot.config.maxStake?.toStringAsFixed(2) ?? '10.00',
    );
    final targetProfitController = TextEditingController(
      text: widget.bot.config.targetProfit.toStringAsFixed(2),
    );

    showDialog(
      context: context,
      builder: (context) => AppDialog(
        title: 'Configurar Bot',
        icon: Icons.settings_rounded,
        iconColor: AppColors.primary,
        contentWidget: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              controller: stakeController,
              label: 'Stake Inicial (\$)',
              hint: '0.35',
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              prefix: Icon(Icons.attach_money_rounded),
            ),
            SizedBox(height: AppSpacing.lg),
            AppTextField(
              controller: maxStakeController,
              label: 'Stake Máximo (\$)',
              hint: '10.00',
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              prefix: Icon(Icons.trending_up_rounded),
            ),
            SizedBox(height: AppSpacing.lg),
            AppTextField(
              controller: targetProfitController,
              label: 'Target Profit (\$)',
              hint: '5.00',
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              prefix: Icon(Icons.flag_rounded),
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
            onPressed: () {
              final newStake = double.tryParse(
                stakeController.text.replaceAll(',', '.'),
              );
              final newMaxStake = double.tryParse(
                maxStakeController.text.replaceAll(',', '.'),
              );
              final newTargetProfit = double.tryParse(
                targetProfitController.text.replaceAll(',', '.'),
              );

              if (newStake != null && newStake >= 0.35 &&
                  newMaxStake != null && newMaxStake >= newStake &&
                  newTargetProfit != null && newTargetProfit > 0) {
                AppHaptics.heavy();
                setState(() {
                  widget.bot.config.initialStake = newStake;
                  widget.bot.currentStake = newStake;
                  widget.bot.config.maxStake = newMaxStake;
                  widget.bot.config.targetProfit = newTargetProfit;
                });
                widget.onUpdate();
                Navigator.pop(context);
                AppSnackbar.success(context, 'Configurações atualizadas');
              } else {
                AppHaptics.error();
                AppSnackbar.error(context, 'Valores inválidos');
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.bot.getStatus();
    final winRate = status.winRate * 100;

    return Scaffold(
      backgroundColor: context.colors.surface,
      appBar: SecondaryAppBar(
        title: widget.bot.config.name,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () {
              AppHaptics.light();
              _showConfigDialog();
            },
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeInWidget(
                child: _buildDerivChart(),
              ),

              SizedBox(height: AppSpacing.lg),

              FadeInWidget(
                delay: Duration(milliseconds: 100),
                child: _buildStatusCard(status, winRate),
              ),

              SizedBox(height: AppSpacing.lg),

              FadeInWidget(
                delay: Duration(milliseconds: 200),
                child: _buildControlButtons(),
              ),

              SizedBox(height: AppSpacing.xl),

              FadeInWidget(
                delay: Duration(milliseconds: 300),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estatísticas',
                      style: context.textStyles.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: AppSpacing.md),
                    _buildStatisticsGrid(status, winRate),
                  ],
                ),
              ),

              SizedBox(height: AppSpacing.xl),

              FadeInWidget(
                delay: Duration(milliseconds: 400),
                child: _buildTradeHistory(status),
              ),

              SizedBox(height: AppSpacing.massive),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDerivChart() {
    final marketData = widget.marketPrices[widget.bot.config.market] ?? [];
    final chartData = marketData.isEmpty ? [100.0] : marketData;

    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: context.colors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: context.colors.outlineVariant,
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        child: DerivAreaChart(
          points: chartData,
          autoScale: true,
          showGradient: false,
          market: widget.bot.config.market,
          height: 280,
          onControllerCreated: (controller, market) {
            _chartController = controller;
          },
        ),
      ),
    );
  }

  Widget _buildStatusCard(BotStatus status, double winRate) {
    final isProfit = status.sessionProfit >= 0;

    return GlassCard(
      child: Container(
        padding: EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              isProfit 
                  ? AppColors.success.withOpacity(0.1)
                  : AppColors.error.withOpacity(0.1),
              context.colors.surfaceContainer,
            ],
          ),
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
          border: Border.all(
            color: isProfit 
                ? AppColors.success.withOpacity(0.3)
                : AppColors.error.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lucro da Sessão',
                        style: context.textStyles.bodyMedium?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(height: AppSpacing.xs),
                      Text(
                        '${isProfit ? '+' : ''}\$${status.sessionProfit.toStringAsFixed(2)}',
                        style: context.textStyles.displaySmall?.copyWith(
                          color: isProfit ? AppColors.success : AppColors.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButtonWithBackground(
                  icon: status.isRunning
                      ? Icons.play_arrow_rounded
                      : Icons.pause_rounded,
                  onPressed: () {},
                  backgroundColor: status.isRunning
                      ? AppColors.success.withOpacity(0.2)
                      : context.colors.surfaceContainerHighest,
                  iconColor: status.isRunning
                      ? AppColors.success
                      : context.colors.onSurfaceVariant,
                  size: 64,
                ),
              ],
            ),
            SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: _buildQuickStat(
                    'Win Rate',
                    '${winRate.toStringAsFixed(1)}%',
                    Icons.percent_rounded,
                  ),
                ),
                Expanded(
                  child: _buildQuickStat(
                    'Trades',
                    status.totalTrades.toString(),
                    Icons.swap_horiz_rounded,
                  ),
                ),
                Expanded(
                  child: _buildQuickStat(
                    'Streak',
                    '${status.consecutiveWins - status.consecutiveLosses}',
                    Icons.local_fire_department_rounded,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: context.colors.primary,
          size: 20,
        ),
        SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: context.textStyles.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: AppSpacing.xxs),
        Text(
          label,
          style: context.textStyles.bodySmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
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
                ? (widget.bot.isPaused
                    ? Icons.play_arrow_rounded
                    : Icons.pause_rounded)
                : Icons.rocket_launch_rounded,
            onPressed: () {
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
              onPressed: () {
                _showStopConfirmation();
              },
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
        StaggeredListItem(
          index: 0,
          child: _buildStatCard(
            'Total Profit',
            '\$${status.totalProfit.toStringAsFixed(2)}',
            status.totalProfit >= 0 ? AppColors.success : AppColors.error,
            Icons.account_balance_wallet_rounded,
          ),
        ),
        StaggeredListItem(
          index: 1,
          child: _buildStatCard(
            'Win Rate',
            '${winRate.toStringAsFixed(1)}%',
            winRate >= 50 ? AppColors.success : AppColors.error,
            Icons.trending_up_rounded,
          ),
        ),
        StaggeredListItem(
          index: 2,
          child: _buildStatCard(
            'Avg Win',
            '\$${status.avgWin.toStringAsFixed(2)}',
            AppColors.success,
            Icons.arrow_upward_rounded,
          ),
        ),
        StaggeredListItem(
          index: 3,
          child: _buildStatCard(
            'Avg Loss',
            '\$${status.avgLoss.toStringAsFixed(2)}',
            AppColors.error,
            Icons.arrow_downward_rounded,
          ),
        ),
        StaggeredListItem(
          index: 4,
          child: _buildStatCard(
            'Current RSI',
            status.currentRSI.toStringAsFixed(0),
            AppColors.info,
            Icons.speed_rounded,
          ),
        ),
        StaggeredListItem(
          index: 5,
          child: _buildStatCard(
            'Stake Atual',
            '\$${status.currentStake.toStringAsFixed(2)}',
            context.colors.primary,
            Icons.attach_money_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return ElevatedCard(
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
            TertiaryButton(
              text: 'Filtrar',
              icon: Icons.filter_list_rounded,
              onPressed: () {
                AppHaptics.light();
                AppSnackbar.info(context, 'Ver todos os ${status.tradeHistory.length} trades');
              },
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

            return StaggeredListItem(
              index: index,
              child: Container(
                margin: EdgeInsets.only(bottom: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: context.colors.surfaceContainer,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                  border: Border.all(
                    color: isWin
                        ? AppColors.success.withOpacity(0.3)
                        : AppColors.error.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: AppListTile(
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isWin
                          ? AppColors.success.withOpacity(0.1)
                          : AppColors.error.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isWin
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      color: isWin ? AppColors.success : AppColors.error,
                      size: 24,
                    ),
                  ),
                  title: isWin ? 'WIN' : 'LOSS',
                  subtitle: 'Stake: \$${trade.stake.toStringAsFixed(2)} • ${trade.timestamp.hour}:${trade.timestamp.minute.toString().padLeft(2, '0')}',
                  trailing: Text(
                    '${trade.profit >= 0 ? '+' : ''}\$${trade.profit.toStringAsFixed(2)}',
                    style: context.textStyles.titleMedium?.copyWith(
                      color: isWin ? AppColors.success : AppColors.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}