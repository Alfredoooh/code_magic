// lib/trade_controls.dart - MATERIAL DESIGN 3 EXPRESSIVE
import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'theme/app_colors.dart';
import 'theme/app_widgets.dart';
import 'trade_logic_controller.dart';

class TradeControls extends StatelessWidget {
  final TradeLogicController controller;
  final VoidCallback onStakeTap;
  final VoidCallback onDurationTap;
  final Function(String) onPlaceTrade;

  const TradeControls({
    Key? key,
    required this.controller,
    required this.onStakeTap,
    required this.onDurationTap,
    required this.onPlaceTrade,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      blur: 15,
      opacity: 0.05,
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: context.colors.outlineVariant.withOpacity(0.5),
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTradeTypeSelector(context),
                const SizedBox(height: AppSpacing.md),
                _buildStakeAndDurationRow(context),
                if (controller.needsBarrier) ...[
                  const SizedBox(height: AppSpacing.md),
                  _buildPredictionSelector(context),
                ],
                if (controller.needsMultiplier) ...[
                  const SizedBox(height: AppSpacing.md),
                  _buildMultiplierControls(context),
                ],
                const SizedBox(height: AppSpacing.lg),
                _buildTradeButtons(context),
                if (controller.activePositions.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _buildPositionsSummary(context),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTradeTypeSelector(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          ...controller.tradeTypes.asMap().entries.map((entry) {
            final type = entry.value;
            final isSelected = controller.selectedTradeType == type['id'];
            final color = type['color'] as Color;

            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: FadeInWidget(
                delay: Duration(milliseconds: entry.key * 50),
                child: _buildTradeTypeChip(
                  context,
                  type['id'] as String,
                  type['label'] as String,
                  type['icon'] as IconData,
                  color,
                  isSelected,
                ),
              ),
            );
          }),
          const SizedBox(width: AppSpacing.xs),
          _buildSoundToggle(context),
        ],
      ),
    );
  }

  Widget _buildTradeTypeChip(
    BuildContext context,
    String id,
    String label,
    IconData icon,
    Color color,
    bool isSelected,
  ) {
    return AnimatedContainer(
      duration: AppMotion.short,
      curve: AppMotion.standardEasing,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            AppHaptics.selection();
            controller.changeTradeType(id);
          },
          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          child: Ink(
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: [color, color.withOpacity(0.8)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isSelected ? null : context.colors.surfaceVariant,
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              border: isSelected
                  ? Border.all(color: color, width: 2)
                  : null,
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: color.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    color: isSelected
                        ? Colors.white
                        : context.colors.onSurfaceVariant,
                    size: 18,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    label,
                    style: context.textStyles.labelLarge?.copyWith(
                      color: isSelected
                          ? Colors.white
                          : context.colors.onSurfaceVariant,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSoundToggle(BuildContext context) {
    return IconButtonWithBackground(
      icon: controller.soundEnabled
          ? Icons.volume_up_rounded
          : Icons.volume_off_rounded,
      onPressed: controller.toggleSound,
      backgroundColor: controller.soundEnabled
          ? AppColors.success.withOpacity(0.15)
          : context.colors.surfaceVariant,
      iconColor: controller.soundEnabled
          ? AppColors.success
          : context.colors.onSurfaceVariant,
      size: 48,
    );
  }

  Widget _buildStakeAndDurationRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: controller.needsDuration ? 3 : 1,
          child: _buildStakeCard(context),
        ),
        if (controller.needsDuration) ...[
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 2,
            child: _buildDurationCard(context),
          ),
        ],
      ],
    );
  }

  Widget _buildStakeCard(BuildContext context) {
    return AnimatedCard(
      onTap: () {
        AppHaptics.light();
        onStakeTap();
      },
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: const Icon(
              Icons.account_balance_wallet_rounded,
              color: AppColors.success,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Stake Amount',
                  style: context.textStyles.labelSmall?.copyWith(
                    color: context.colors.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${controller.currency} ${controller.stake.toStringAsFixed(2)}',
                  style: context.textStyles.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.success,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.edit_rounded,
            color: context.colors.onSurfaceVariant.withOpacity(0.5),
            size: 18,
          ),
        ],
      ),
    );
  }

  Widget _buildDurationCard(BuildContext context) {
    return AnimatedCard(
      onTap: () {
        AppHaptics.light();
        onDurationTap();
      },
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.15),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: const Icon(
              Icons.schedule_rounded,
              color: AppColors.info,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Duration',
                  style: context.textStyles.labelSmall?.copyWith(
                    color: context.colors.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${controller.durationValue}${controller.durationShortLabel}',
                  style: context.textStyles.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.info,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPredictionSelector(BuildContext context) {
    return OutlinedCard(
      borderColor: AppColors.warning.withOpacity(0.3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: const Icon(
                  Icons.numbers_rounded,
                  color: AppColors.warning,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Prediction',
                    style: context.textStyles.labelSmall?.copyWith(
                      color: context.colors.onSurface.withOpacity(0.6),
                    ),
                  ),
                  Text(
                    'Last digit',
                    style: context.textStyles.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            children: [
              IconButtonWithBackground(
                icon: Icons.remove_rounded,
                onPressed: controller.tickPrediction > 0
                    ? () {
                        AppHaptics.light();
                        controller.setTickPrediction(controller.tickPrediction - 1);
                      }
                    : null,
                backgroundColor: AppColors.error.withOpacity(0.15),
                iconColor: AppColors.error,
                size: 36,
              ),
              Container(
                width: 48,
                alignment: Alignment.center,
                child: Text(
                  controller.tickPrediction.toString(),
                  style: context.textStyles.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.warning,
                  ),
                ),
              ),
              IconButtonWithBackground(
                icon: Icons.add_rounded,
                onPressed: controller.tickPrediction < 9
                    ? () {
                        AppHaptics.light();
                        controller.setTickPrediction(controller.tickPrediction + 1);
                      }
                    : null,
                backgroundColor: AppColors.success.withOpacity(0.15),
                iconColor: AppColors.success,
                size: 36,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMultiplierControls(BuildContext context) {
    return OutlinedCard(
      borderColor: AppColors.info.withOpacity(0.3),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: AppColors.info.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: const Icon(
                      Icons.auto_graph_rounded,
                      color: AppColors.info,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Multiplier',
                        style: context.textStyles.labelSmall?.copyWith(
                          color: context.colors.onSurface.withOpacity(0.6),
                        ),
                      ),
                      Text(
                        '${controller.multiplier}x',
                        style: context.textStyles.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: AppColors.info,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  IconButtonWithBackground(
                    icon: Icons.remove_rounded,
                    onPressed: controller.multiplier > 1
                        ? () {
                            AppHaptics.light();
                            controller.setMultiplier(controller.multiplier - 1);
                          }
                        : null,
                    backgroundColor: AppColors.error.withOpacity(0.15),
                    iconColor: AppColors.error,
                    size: 36,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  IconButtonWithBackground(
                    icon: Icons.add_rounded,
                    onPressed: controller.multiplier < 1000
                        ? () {
                            AppHaptics.light();
                            controller.setMultiplier(controller.multiplier + 1);
                          }
                        : null,
                    backgroundColor: AppColors.success.withOpacity(0.15),
                    iconColor: AppColors.success,
                    size: 36,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          const LabeledDivider(label: 'Potential'),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Max Profit',
                style: context.textStyles.labelSmall?.copyWith(
                  color: context.colors.onSurface.withOpacity(0.6),
                ),
              ),
              Text(
                '${controller.currency} ${controller.getPotentialProfit().toStringAsFixed(2)}',
                style: context.textStyles.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTradeButtons(BuildContext context) {
    if (controller.selectedTradeType == 'accumulators') {
      return _buildAccumulatorButton(context);
    }

    return Row(
      children: [
        Expanded(
          child: _buildTradeButton(
            context,
            controller.getButtonLabel(true),
            controller.getButtonIcon(true),
            AppColors.success,
            'buy',
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _buildTradeButton(
            context,
            controller.getButtonLabel(false),
            controller.getButtonIcon(false),
            AppColors.error,
            'sell',
          ),
        ),
      ],
    );
  }

  Widget _buildAccumulatorButton(BuildContext context) {
    final isActive = controller.hasActiveAccumulator;
    final color = isActive ? AppColors.error : AppColors.primary;
    final label = controller.getButtonLabel(true);
    final icon = controller.getButtonIcon(true);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: controller.isTrading
            ? null
            : () {
                AppHaptics.heavy();
                onPlaceTrade(isActive ? 'sell' : 'buy');
              },
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: AnimatedContainer(
          duration: AppMotion.medium,
          curve: AppMotion.emphasizedDecelerate,
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.lg,
            horizontal: AppSpacing.xl,
          ),
          decoration: BoxDecoration(
            gradient: controller.isTrading
                ? null
                : LinearGradient(
                    colors: [color, color.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            color: controller.isTrading ? color.withOpacity(0.5) : null,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            boxShadow: controller.isTrading
                ? null
                : [
                    BoxShadow(
                      color: color.withOpacity(0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (controller.isTrading)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              else
                Icon(icon, color: Colors.white, size: 28),
              const SizedBox(width: AppSpacing.sm),
              Text(
                controller.isTrading ? 'PROCESSING...' : label,
                style: context.textStyles.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTradeButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    String direction,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: controller.isTrading
            ? null
            : () {
                AppHaptics.heavy();
                onPlaceTrade(direction);
              },
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: AnimatedContainer(
          duration: AppMotion.medium,
          curve: AppMotion.emphasizedDecelerate,
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.lg,
            horizontal: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            gradient: controller.isTrading
                ? null
                : LinearGradient(
                    colors: [color, color.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            color: controller.isTrading ? color.withOpacity(0.5) : null,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            boxShadow: controller.isTrading
                ? null
                : [
                    BoxShadow(
                      color: color.withOpacity(0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 32),
              const SizedBox(height: AppSpacing.xs),
              Text(
                label,
                style: context.textStyles.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPositionsSummary(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(
          color: AppColors.info.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: AppColors.info,
            size: 16,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            controller.getPositionSummary(),
            style: context.textStyles.labelMedium?.copyWith(
              color: AppColors.info,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}