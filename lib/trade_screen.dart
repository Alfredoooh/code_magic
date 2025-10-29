import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'theme/app_theme.dart';
import 'theme/app_colors.dart';
import 'theme/app_widgets.dart';
import 'trade_logic_controller.dart';
import 'trade_chart_view.dart';
import 'trade_controls.dart';
import 'custom_keyboard_screen.dart';
import 'market_selector_screen.dart';

class TradeScreen extends StatefulWidget {
  final String token;
  final String? initialMarket;

  const TradeScreen({
    Key? key,
    required this.token,
    this.initialMarket,
  }) : super(key: key);

  @override
  State<TradeScreen> createState() => _TradeScreenState();
}

class _TradeScreenState extends State<TradeScreen> with TickerProviderStateMixin {
  late TradeLogicController _controller;
  bool _chartExpanded = false;
  bool _showMLBanner = true;
  late AnimationController _mlBannerController;
  late Animation<double> _mlBannerAnimation;

  @override
  void initState() {
    super.initState();
    _controller = TradeLogicController(
      token: widget.token,
      initialMarket: widget.initialMarket,
      onStateChanged: () {
        if (mounted) setState(() {});
      },
    );
    _controller.initialize();

    _mlBannerController = AnimationController(
      vsync: this,
      duration: AppMotion.medium,
    );
    _mlBannerAnimation = CurvedAnimation(
      parent: _mlBannerController,
      curve: AppMotion.emphasizedDecelerate,
    );
    
    // Inicia a animação
    if (_controller.mlPrediction != null && _showMLBanner) {
      _mlBannerController.forward();
    }
  }

  @override
  void dispose() {
    _mlBannerController.dispose();
    _controller.dispose();
    super.dispose();
  }

  String _abbreviateMarketName(String name) {
    if (name.length <= 15) return name;
    return '${name.substring(0, 12)}...';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: GestureDetector(
          onTap: () {
            AppHaptics.light();
            _showMarketSelector();
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _abbreviateMarketName(_controller.selectedMarketName),
                style: context.textStyles.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.pending_actions_rounded),
            onPressed: () {
              AppHaptics.light();
              AppSnackbar.info(context, 'Posições pendentes');
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: () {
              AppHaptics.light();
              _showTradeSettings();
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${_controller.balance.toStringAsFixed(2)} ${_controller.currency}',
                  style: context.textStyles.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _controller.priceChange >= 0
                        ? AppColors.success.withOpacity(0.15)
                        : AppColors.error.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: Text(
                    '${_controller.priceChange >= 0 ? '+' : ''}${_controller.priceChange.toStringAsFixed(2)}%',
                    style: context.textStyles.labelSmall?.copyWith(
                      color: _controller.priceChange >= 0
                          ? AppColors.success
                          : AppColors.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: ScrollConfiguration(
        behavior: const ScrollBehavior().copyWith(overscroll: false),
        child: Column(
          children: [
            if (_controller.mlPrediction != null && _showMLBanner)
              _buildMLPredictionBanner(),
            
            Expanded(
              flex: _chartExpanded ? 5 : 3,
              child: TradeChartView(
                controller: _controller,
                isExpanded: _chartExpanded,
                onExpandToggle: () {
                  AppHaptics.medium();
                  setState(() => _chartExpanded = !_chartExpanded);
                },
              ),
            ),
            
            if (!_chartExpanded)
              TradeControls(
                controller: _controller,
                onStakeTap: () => _showStakeKeyboard(),
                onDurationTap: () => _showDurationSelector(),
                onPlaceTrade: (direction) => _controller.placeTrade(direction),
              ),
          ],
        ),
      ),
    );
  }

  void _showTradeSettings() {
    AppModalBottomSheet.show(
      context: context,
      title: 'Trade Settings',
      showHandle: true,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xl),
          child: Column(
            children: [
              AppListTile(
                title: 'Trade Type',
                subtitle: _controller.tradeTypeLabel,
                leading: const Icon(Icons.category_rounded),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  AppHaptics.selection();
                  Navigator.pop(context);
                  _showTradeTypeSelector();
                },
              ),
              if (_controller.tradeType == 'accumulator') ...[
                const Divider(),
                AppListTile(
                  title: 'Growth Rate',
                  subtitle: '${(_controller.growthRate * 100).toStringAsFixed(0)}%',
                  leading: const Icon(Icons.trending_up_rounded),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    AppHaptics.selection();
                    Navigator.pop(context);
                    _showGrowthRateSelector();
                  },
                ),
              ],
              if (_controller.tradeType == 'vanillaoptions') ...[
                const Divider(),
                AppListTile(
                  title: 'Strike Price',
                  subtitle: '\$${_controller.strikePrice.toStringAsFixed(2)}',
                  leading: const Icon(Icons.gps_fixed_rounded),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    AppHaptics.selection();
                    Navigator.pop(context);
                    _showStrikePriceKeyboard();
                  },
                ),
              ],
              const Divider(),
              AppListTile(
                title: 'Duration Type',
                subtitle: _controller.durationLabel,
                leading: const Icon(Icons.schedule_rounded),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  AppHaptics.selection();
                  Navigator.pop(context);
                  _showDurationSelector();
                },
              ),
              const Divider(),
              AppListTile(
                title: 'Duration Value',
                subtitle: '${_controller.durationValue} ${_controller.durationLabel}',
                leading: const Icon(Icons.timer_rounded),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  AppHaptics.selection();
                  Navigator.pop(context);
                  _showDurationValuePicker();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTradeTypeSelector() {
    AppModalBottomSheet.show(
      context: context,
      title: 'Select Trade Type',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppListTile(
            title: 'Rise/Fall',
            subtitle: 'Predict market direction',
            leading: const Icon(Icons.swap_vert_rounded),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              AppHaptics.selection();
              _controller.setTradeType('risefall');
              Navigator.pop(context);
            },
          ),
          AppListTile(
            title: 'Accumulators',
            subtitle: 'Accumulate growth over time',
            leading: const Icon(Icons.addchart_rounded),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              AppHaptics.selection();
              _controller.setTradeType('accumulator');
              Navigator.pop(context);
            },
          ),
          AppListTile(
            title: 'Vanilla Options',
            subtitle: 'Strike price options',
            leading: const Icon(Icons.trending_up_rounded),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {
              AppHaptics.selection();
              _controller.setTradeType('vanillaoptions');
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showGrowthRateSelector() {
    AppModalBottomSheet.show(
      context: context,
      title: 'Select Growth Rate',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [1, 2, 3, 4, 5].map((rate) {
          return AppListTile(
            title: '$rate%',
            trailing: _controller.growthRate == (rate / 100)
                ? const Icon(Icons.check_rounded, color: AppColors.success)
                : null,
            onTap: () {
              AppHaptics.selection();
              _controller.setGrowthRate(rate / 100);
              Navigator.pop(context);
            },
          );
        }).toList(),
      ),
    );
  }

  void _showStrikePriceKeyboard() {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => CustomKeyboardScreen(
          title: 'Set Strike Price',
          initialValue: _controller.strikePrice,
          minValue: 0.01,
          prefix: '\$ ',
          onConfirm: (value) {
            _controller.setStrikePrice(value);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  Widget _buildMLPredictionBanner() {
    final prediction = _controller.mlPrediction;
    if (prediction == null) return const SizedBox.shrink();

    final direction = prediction['direction'] as String? ?? 'N/A';
    final confidence = prediction['confidence'] as double? ?? 0.0;
    final probability = prediction['probability'] as double? ?? 0.0;
    final strength = prediction['strength'] as double? ?? 0.0;
    final recommendedAction = prediction['recommended_action'] as String? ?? 'hold';
    final stake = _controller.mlRecommendedStake;

    final isRise = direction.toLowerCase() == 'rise';
    final directionColor = isRise ? AppColors.success : AppColors.error;
    final confidenceColor = confidence > 0.7
        ? AppColors.success
        : confidence > 0.5
            ? AppColors.warning
            : AppColors.error;

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, -1),
        end: Offset.zero,
      ).animate(_mlBannerAnimation),
      child: FadeTransition(
        opacity: _mlBannerAnimation,
        child: Container(
          margin: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.info.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: AppColors.info.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                AppHaptics.selection();
                _showMLDetailsBottomSheet();
              },
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: AppColors.info.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                          ),
                          child: const Icon(
                            Icons.psychology_rounded,
                            color: AppColors.info,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'ML Prediction:',
                                    style: context.textStyles.labelMedium?.copyWith(
                                      color: context.colors.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  AppBadge(
                                    text: direction.toUpperCase(),
                                    color: directionColor,
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.xxs),
                              Row(
                                children: [
                                  Icon(
                                    Icons.analytics_rounded,
                                    size: 14,
                                    color: confidenceColor,
                                  ),
                                  const SizedBox(width: AppSpacing.xxs),
                                  Text(
                                    'Confidence: ${(confidence * 100).toStringAsFixed(0)}%',
                                    style: context.textStyles.bodySmall?.copyWith(
                                      color: confidenceColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Icon(
                                    Icons.speed_rounded,
                                    size: 14,
                                    color: context.colors.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: AppSpacing.xxs),
                                  Text(
                                    'Strength: ${(strength * 100).toStringAsFixed(0)}%',
                                    style: context.textStyles.bodySmall,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () {
                            AppHaptics.light();
                            setState(() {
                              _showMLBanner = false;
                              _mlBannerController.reverse();
                            });
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: context.colors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Recommended Stake',
                                style: context.textStyles.labelSmall,
                              ),
                              Text(
                                '\$${stake.toStringAsFixed(2)}',
                                style: context.textStyles.titleSmall?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Action',
                                style: context.textStyles.labelSmall,
                              ),
                              Text(
                                _formatRecommendedAction(recommendedAction),
                                style: context.textStyles.titleSmall?.copyWith(
                                  color: _getActionColor(recommendedAction),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.touch_app_rounded,
                          size: 14,
                          color: context.colors.onSurfaceVariant,
                        ),
                        const SizedBox(width: AppSpacing.xxs),
                        Text(
                          'Tap for detailed analysis',
                          style: context.textStyles.labelSmall?.copyWith(
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _formatRecommendedAction(String action) {
    switch (action) {
      case 'strong_buy':
        return 'Strong Buy';
      case 'buy':
        return 'Buy';
      case 'moderate_buy':
        return 'Moderate Buy';
      case 'hold':
        return 'Hold';
      case 'avoid':
        return 'Avoid';
      default:
        return action.toUpperCase();
    }
  }

  Color _getActionColor(String action) {
    switch (action) {
      case 'strong_buy':
      case 'buy':
        return AppColors.success;
      case 'moderate_buy':
        return AppColors.warning;
      case 'hold':
        return AppColors.info;
      case 'avoid':
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }

  void _showMLDetailsBottomSheet() {
    final prediction = _controller.mlPrediction;
    if (prediction == null) return;

    final patterns = (prediction['patterns'] as List?)?.cast<String>() ?? [];
    final riskReward = prediction['risk_reward'] as Map<String, dynamic>? ?? {};
    final marketConditions = prediction['market_conditions'] as Map<String, dynamic>? ?? {};

    AppModalBottomSheet.show(
      context: context,
      title: 'ML Analysis',
      showHandle: true,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.info.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: const Icon(Icons.auto_graph_rounded, color: AppColors.info),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Detailed Analysis', style: context.textStyles.titleLarge),
                        Text(
                          'ML prediction breakdown',
                          style: context.textStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xl),

              if (patterns.isNotEmpty) ...[
                Text('Detected Patterns', style: context.textStyles.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: patterns.map((p) => AppBadge(
                    text: p.replaceAll('_', ' ').toUpperCase(),
                    color: AppColors.secondary,
                  )).toList(),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],

              Text('Risk/Reward Analysis', style: context.textStyles.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              _buildInfoCard(
                icon: Icons.trending_up_rounded,
                label: 'Potential Reward',
                value: '\$${(riskReward['reward'] ?? 0.0).toStringAsFixed(2)}',
                color: AppColors.success,
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildInfoCard(
                icon: Icons.trending_down_rounded,
                label: 'Potential Risk',
                value: '\$${(riskReward['risk'] ?? 0.0).toStringAsFixed(2)}',
                color: AppColors.error,
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildInfoCard(
                icon: Icons.balance_rounded,
                label: 'Risk/Reward Ratio',
                value: '1:${(riskReward['ratio'] ?? 1.0).toStringAsFixed(2)}',
                color: AppColors.warning,
              ),
              const SizedBox(height: AppSpacing.xl),

              Text('Market Conditions', style: context.textStyles.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              _buildInfoCard(
                icon: Icons.show_chart_rounded,
                label: 'Volatility',
                value: '${((marketConditions['volatility'] ?? 0.0) * 100).toStringAsFixed(0)}%',
                color: AppColors.warning,
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildInfoCard(
                icon: Icons.insights_rounded,
                label: 'RSI',
                value: '${((marketConditions['rsi'] ?? 0.5) * 100).toStringAsFixed(0)}',
                color: AppColors.info,
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildInfoCard(
                icon: Icons.mood_rounded,
                label: 'Market Sentiment',
                value: '${(marketConditions['sentiment'] ?? 50.0).toStringAsFixed(0)}',
                color: AppColors.primary,
              ),
              const SizedBox(height: AppSpacing.xl),

              Text('ML Performance', style: context.textStyles.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              _buildInfoCard(
                icon: Icons.percent_rounded,
                label: 'Accuracy',
                value: '${(_controller.mlAccuracy * 100).toStringAsFixed(1)}%',
                color: AppColors.success,
              ),
              const SizedBox(height: AppSpacing.sm),
              _buildInfoCard(
                icon: Icons.numbers_rounded,
                label: 'Total Predictions',
                value: _controller.mlTotalPredictions.toString(),
                color: AppColors.secondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(label, style: context.textStyles.bodyMedium),
          ),
          Text(
            value,
            style: context.textStyles.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  void _showMarketSelector() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => MarketSelectorScreen(
          currentMarket: _controller.selectedMarket,
          allMarkets: _controller.allMarkets,
          onMarketSelected: (market) {
            _controller.changeMarket(market);
            Navigator.pop(context);
          },
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);
          return SlideTransition(position: offsetAnimation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 350),
        fullscreenDialog: true,
      ),
    );
  }

  void _showStakeKeyboard() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => CustomKeyboardScreen(
          title: 'Definir Stake',
          initialValue: _controller.stake,
          minValue: 0.35,
          prefix: '\$ ',
          onConfirm: (value) {
            if (value >= 0.35) {
              _controller.setStake(value);
              Navigator.pop(context);
            } else {
              AppSnackbar.error(context, 'Stake mínimo é \$0.35');
            }
          },
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);
          return SlideTransition(position: offsetAnimation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 350),
        fullscreenDialog: true,
      ),
    );
  }

  void _showDurationSelector() {
    AppModalBottomSheet.show(
      context: context,
      title: 'Select Duration Type',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDurationOption('Ticks', 't'),
          _buildDurationOption('Seconds', 's'),
          _buildDurationOption('Minutes', 'm'),
          _buildDurationOption('Hours', 'h'),
          _buildDurationOption('Days', 'd'),
        ],
      ),
    );
  }

  Widget _buildDurationOption(String label, String type) {
    return AppListTile(
      title: label,
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () {
        AppHaptics.selection();
        _controller.setDurationType(type);
        Navigator.pop(context);
        _showDurationValuePicker();
      },
    );
  }

  void _showDurationValuePicker() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => CustomKeyboardScreen(
          title: 'Value (${_controller.durationLabel})',
          initialValue: _controller.durationValue.toDouble(),
          minValue: 1,
          isInteger: true,
          onConfirm: (value) {
            final durationInt = value.toInt();
            if (durationInt >= 1) {
              _controller.setDurationValue(durationInt);
              Navigator.pop(context);
            } else {
              AppSnackbar.error(context, 'Valor mínimo é 1');
            }
          },
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);
          return SlideTransition(position: offsetAnimation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 350),
        fullscreenDialog: true,
      ),
    );
  }
}