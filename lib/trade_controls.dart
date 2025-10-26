// lib/trade_controls.dart - MATERIAL DESIGN 3 EXPRESSIVE
import 'package:flutter/material.dart';
import 'styles.dart' hide EdgeInsets;
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
    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.surface,
        border: Border(
          top: BorderSide(
            color: context.colors.outlineVariant,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTradeTypeSelector(context),
            SizedBox(height: AppSpacing.md),
            _buildStakeAndDurationRow(context),
            if (controller.selectedTradeType == 'match_differ' ||
                controller.selectedTradeType == 'over_under') ...[
              SizedBox(height: AppSpacing.md),
              _buildPredictionSelector(context),
            ],
            SizedBox(height: AppSpacing.lg),
            _buildTradeButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTradeTypeSelector(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...controller.tradeTypes.asMap().entries.map((entry) {
            final type = entry.value;
            final isSelected = controller.selectedTradeType == type['id'];

            return Padding(
              padding: EdgeInsets.only(right: AppSpacing.sm),
              child: AnimatedContainer(
                duration: AppMotion.short,
                curve: AppMotion.standardEasing,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      AppHaptics.selection();
                      controller.changeTradeType(type['id'] as String);
                    },
                    borderRadius: BorderRadius.circular(AppShapes.full),
                    child: Ink(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : context.colors.surfaceVariant,
                        borderRadius: BorderRadius.circular(AppShapes.full),
                        border: isSelected
                            ? Border.all(color: AppColors.primary, width: 2)
                            : null,
                      ),
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              type['icon'] as IconData,
                              color: isSelected
                                  ? AppColors.onPrimary
                                  : context.colors.onSurfaceVariant,
                              size: 18,
                            ),
                            SizedBox(width: AppSpacing.xs),
                            Text(
                              type['label'] as String,
                              style: context.textStyles.labelLarge?.copyWith(
                                color: isSelected
                                    ? AppColors.onPrimary
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
              ),
            );
          }).toList(),
          // Sound Toggle Button
          SizedBox(width: AppSpacing.xs),
          _buildSoundToggle(context),
        ],
      ),
    );
  }

  Widget _buildSoundToggle(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          AppHaptics.light();
          controller.toggleSound();
        },
        customBorder: const CircleBorder(),
        child: Ink(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: controller.soundEnabled
                ? AppColors.success.withOpacity(0.15)
                : context.colors.surfaceVariant,
            shape: BoxShape.circle,
            border: controller.soundEnabled
                ? Border.all(color: AppColors.success, width: 2)
                : null,
          ),
          child: Icon(
            controller.soundEnabled
                ? Icons.volume_up_rounded
                : Icons.volume_off_rounded,
            color: controller.soundEnabled
                ? AppColors.success
                : context.colors.onSurfaceVariant,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildStakeAndDurationRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: AnimatedCard(
            onTap: () {
              AppHaptics.light();
              onStakeTap();
            },
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(AppShapes.small),
                  ),
                  child: const Icon(
                    Icons.attach_money_rounded,
                    color: AppColors.success,
                    size: 20,
                  ),
                ),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stake',
                        style: context.textStyles.labelSmall,
                      ),
                      Text(
                        '\$${controller.stake.toStringAsFixed(2)}',
                        style: context.textStyles.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.edit_rounded,
                  color: context.colors.onSurfaceVariant,
                  size: 18,
                ),
              ],
            ),
          ),
        ),
        if (controller.selectedTradeType != 'accumulators' &&
            controller.selectedTradeType != 'turbos') ...[
          SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 2,
            child: AnimatedCard(
              onTap: () {
                AppHaptics.light();
                onDurationTap();
              },
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: AppColors.info.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(AppShapes.small),
                    ),
                    child: const Icon(
                      Icons.schedule_rounded,
                      color: AppColors.info,
                      size: 20,
                    ),
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Duration',
                          style: context.textStyles.labelSmall,
                        ),
                        Text(
                          '${controller.durationValue}${controller.durationLabel}',
                          style: context.textStyles.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPredictionSelector(BuildContext context) {
    return AnimatedCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppShapes.small),
                ),
                child: const Icon(
                  Icons.psychology_rounded,
                  color: AppColors.warning,
                  size: 20,
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              Text(
                'Prediction',
                style: context.textStyles.titleSmall,
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_rounded),
                color: AppColors.error,
                iconSize: 32,
                onPressed: () {
                  if (controller.tickPrediction > 0) {
                    AppHaptics.light();
                    controller.setTickPrediction(controller.tickPrediction - 1);
                  }
                },
              ),
              Container(
                width: 48,
                alignment: Alignment.center,
                child: Text(
                  controller.tickPrediction.toString(),
                  style: context.textStyles.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_rounded),
                color: AppColors.success,
                iconSize: 32,
                onPressed: () {
                  if (controller.tickPrediction < 9) {
                    AppHaptics.light();
                    controller.setTickPrediction(controller.tickPrediction + 1);
                  }
                },
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
            AppColors.success,
            'buy',
            Icons.arrow_upward_rounded,
          ),
        ),
        SizedBox(width: AppSpacing.md),
        Expanded(
          child: _buildTradeButton(
            context,
            controller.getButtonLabel(false),
            AppColors.error,
            'sell',
            Icons.arrow_downward_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildAccumulatorButton(BuildContext context) {
    final color = controller.hasActiveAccumulator ? AppColors.error : AppColors.primary;
    final label = controller.hasActiveAccumulator ? 'CLOSE' : 'OPEN';
    final icon = controller.hasActiveAccumulator
        ? Icons.close_rounded
        : Icons.add_rounded;

    return AnimatedPrimaryButton(
      text: label,
      icon: icon,
      onPressed: controller.isTrading
          ? null
          : () {
              AppHaptics.heavy();
              onPlaceTrade(controller.hasActiveAccumulator ? 'sell' : 'buy');
            },
    );
  }

  Widget _buildTradeButton(
    BuildContext context,
    String label,
    Color color,
    String direction,
    IconData icon,
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
        borderRadius: BorderRadius.circular(AppShapes.large),
        child: AnimatedContainer(
          duration: AppMotion.short,
          curve: AppMotion.standardEasing,
          padding: EdgeInsets.symmetric(
            vertical: AppSpacing.lg,
            horizontal: AppSpacing.xl,
          ),
          decoration: BoxDecoration(
            gradient: controller.isTrading
                ? null
                : LinearGradient(
                    colors: [
                      color,
                      color.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            color: controller.isTrading ? color.withOpacity(0.5) : null,
            borderRadius: BorderRadius.circular(AppShapes.large),
            boxShadow: controller.isTrading
                ? null
                : [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: 28,
              ),
              SizedBox(width: AppSpacing.sm),
              Text(
                label,
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
}