// lib/trade_screen.dart - MATERIAL DESIGN 3 EXPRESSIVE
import 'dart:async';
import 'package:flutter/material.dart';
import 'styles.dart';
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

    // Animação do banner ML
    _mlBannerController = AnimationController(
      vsync: this,
      duration: AppMotion.medium,
    );
    _mlBannerAnimation = CurvedAnimation(
      parent: _mlBannerController,
      curve: AppMotion.emphasizedDecelerate,
    );
    _mlBannerController.forward();
  }

  @override
  void dispose() {
    _mlBannerController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: GestureDetector(
          onTap: () {
            AppHaptics.light();
            _showMarketSelector();
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_controller.selectedMarketName),
              const SizedBox(width: AppSpacing.xs),
              const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
            ],
          ),
        ),
        actions: [
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
                    borderRadius: BorderRadius.circular(AppShapes.full),
                  ),
                  child: Text(
                    '${_controller.priceChange >= 0 ? '+' : ''}${_controller.priceChange.toStringAsFixed(2)}%',
                    style: context.textStyles.labelSmall?.copyWith(
                      color: _controller.priceChange >= 0 ? AppColors.success : AppColors.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ML Prediction Banner (abaixo do AppBar)
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
    );
  }

  Widget _buildMLPredictionBanner() {
    final prediction = _controller.mlPrediction!;
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
            gradient: LinearGradient(
              colors: [
                AppColors.info.withOpacity(0.15),
                AppColors.primary.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(AppShapes.medium),
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
              borderRadius: BorderRadius.circular(AppShapes.medium),
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
                            borderRadius: BorderRadius.circular(AppShapes.small),
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
                            setState(() => _showMLBanner = false);
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
                        color: context.colors.surfaceVariant,
                        borderRadius: BorderRadius.circular(AppShapes.small),
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
    final prediction = _controller.mlPrediction!;
    final patterns = (prediction['patterns'] as List<dynamic>?)?.cast<String>() ?? [];
    final riskReward = prediction['risk_reward'] as Map<String, dynamic>? ?? {};
    final marketConditions = prediction['market_conditions'] as Map<String, dynamic>? ?? {};

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppShapes.extraLarge)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.colors.outlineVariant,
                borderRadius: BorderRadius.circular(AppShapes.full),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.info.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(AppShapes.medium),
                    ),
                    child: const Icon(Icons.auto_graph_rounded, color: AppColors.info),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ML Analysis', style: context.textStyles.headlineSmall),
                        Text(
                          'Detailed prediction breakdown',
                          style: context.textStyles.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Flexible(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                shrinkWrap: true,
                children: [
                  // Padrões Detectados
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
                    const SizedBox(height: AppSpacing.lg),
                  ],

                  // Risk/Reward
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
                  const SizedBox(height: AppSpacing.lg),

                  // Market Conditions
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
                  const SizedBox(height: AppSpacing.lg),

                  // ML Stats
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
                  
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ],
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
        color: context.colors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppShapes.medium),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppShapes.small),
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
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => MarketSelectorScreen(
          currentMarket: _controller.selectedMarket,
          allMarkets: _controller.allMarkets,
          onMarketSelected: (market) {
            _controller.changeMarket(market);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _showStakeKeyboard() {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => CustomKeyboardScreen(
          title: 'Definir Stake',
          initialValue: _controller.stake,
          prefix: '\$ ',
          onConfirm: (value) {
            _controller.setStake(value);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _showDurationSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppShapes.extraLarge)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.md),
            Text('Select Duration Type', style: context.textStyles.titleLarge),
            const SizedBox(height: AppSpacing.lg),
            _buildDurationOption('Ticks', 't'),
            _buildDurationOption('Seconds', 's'),
            _buildDurationOption('Minutes', 'm'),
            _buildDurationOption('Hours', 'h'),
            _buildDurationOption('Days', 'd'),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationOption(String label, String type) {
    return ListTile(
      title: Text(label),
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
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => CustomKeyboardScreen(
          title: 'Value (${_controller.durationLabel})',
          initialValue: _controller.durationValue.toDouble(),
          isInteger: true,
          onConfirm: (value) {
            _controller.setDurationValue(value.toInt());
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}