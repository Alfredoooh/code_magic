// lib/bot_details_screen.dart
// Tela de detalhes e controle do bot com chart em tempo real
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'bot_engine.dart';
import 'deriv_chart_widget.dart';
import 'styles.dart' hide EdgeInsets;

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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: context.colors.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppShapes.extraLarge),
          ),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
          left: AppSpacing.xl,
          right: AppSpacing.xl,
          top: AppSpacing.xl,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Configurar Bot',
                    style: context.textStyles.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () {
                      AppHaptics.light();
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.xl),
              TextField(
                controller: stakeController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Stake Inicial (\$)',
                  prefixIcon: Icon(Icons.attach_money_rounded),
                  helperText: 'Valor mínimo: \$0.35',
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
              ),
              SizedBox(height: AppSpacing.lg),
              TextField(
                controller: maxStakeController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Stake Máximo (\$)',
                  prefixIcon: Icon(Icons.trending_up_rounded),
                  helperText: 'Limite de segurança',
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
              ),
              SizedBox(height: AppSpacing.lg),
              TextField(
                controller: targetProfitController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Target Profit (\$)',
                  prefixIcon: Icon(Icons.flag_rounded),
                  helperText: 'Bot para quando atingir',
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                ],
              ),
              SizedBox(height: AppSpacing.xxl),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        AppHaptics.light();
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: FilledButton(
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
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Salvar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.bot.getStatus();
    final winRate = status.winRate * 100;

    return Scaffold(
      backgroundColor: context.colors.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            AppHaptics.light();
            Navigator.pop(context);
          },
        ),
        title: Text(widget.bot.config.name),
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
                delay: const Duration(milliseconds: 100),
                child: _buildStatusCard(status, winRate),
              ),

              SizedBox(height: AppSpacing.lg),

              FadeInWidget(
                delay: const Duration(milliseconds: 200),
                child: _buildControlButtons(),
              ),

              SizedBox(height: AppSpacing.xl),

              FadeInWidget(
                delay: const Duration(milliseconds: 300),
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
                delay: const Duration(milliseconds: 400),
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
        borderRadius: BorderRadius.circular(AppShapes.extraLarge),
        border: Border.all(
          color: context.colors.outlineVariant,
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppShapes.extraLarge),
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

    return Container(
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
        borderRadius: BorderRadius.circular(AppShapes.extraLarge),
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
              Container(
                padding: EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: status.isRunning
                      ? AppColors.success.withOpacity(0.2)
                      : context.colors.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  status.isRunning
                      ? Icons.play_arrow_rounded
                      : Icons.pause_rounded,
                  color: status.isRunning
                      ? AppColors.success
                      : context.colors.onSurfaceVariant,
                  size: 32,
                ),
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
          child: AnimatedPrimaryButton(
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
          ),
        ),
        if (widget.bot.isRunning) ...[
          SizedBox(width: AppSpacing.md),
          Expanded(
            flex: 1,
            child: FilledButton(
              onPressed: () {
                AppHaptics.heavy();
                widget.bot.stop();
                widget.onUpdate();
                setState(() {});
                AppSnackbar.info(context, 'Bot parado');
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.error,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Icon(Icons.stop_rounded, size: 24),
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
    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppShapes.extraLarge),
        border: Border.all(
          color: context.colors.outlineVariant,
          width: 1,
        ),
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
          Container(
            padding: EdgeInsets.all(AppSpacing.xxl),
            decoration: BoxDecoration(
              color: context.colors.surfaceContainer,
              borderRadius: BorderRadius.circular(AppShapes.extraLarge),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.history_rounded,
                    size: 48,
                    color: context.colors.onSurfaceVariant,
                  ),
                  SizedBox(height: AppSpacing.md),
                  Text(
                    'Nenhum trade ainda',
                    style: context.textStyles.bodyLarge?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
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
            TextButton.icon(
              onPressed: () {
                AppHaptics.light();
                AppSnackbar.info(context, 'Ver todos os ${status.tradeHistory.length} trades');
              },
              icon: const Icon(Icons.filter_list_rounded, size: 18),
              label: const Text('Filtrar'),
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
                  borderRadius: BorderRadius.circular(AppShapes.extraLarge),
                  border: Border.all(
                    color: isWin
                        ? AppColors.success.withOpacity(0.3)
                        : AppColors.error.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
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
                  title: Row(
                    children: [
                      Text(
                        isWin ? 'WIN' : 'LOSS',
                        style: context.textStyles.titleSmall?.copyWith(
                          color: isWin ? AppColors.success : AppColors.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: AppSpacing.sm),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xxs,
                        ),
                        decoration: BoxDecoration(
                          color: context.colors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(AppShapes.small),
                        ),
                        child: Text(
                          '${trade.timestamp.hour}:${trade.timestamp.minute.toString().padLeft(2, '0')}',
                          style: context.textStyles.labelSmall?.copyWith(
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Text(
                    'Stake: \$${trade.stake.toStringAsFixed(2)}',
                    style: context.textStyles.bodySmall?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
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