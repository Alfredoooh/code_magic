// market_selector_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'styles.dart' hide EdgeInsets;

class MarketSelectorScreen extends StatelessWidget {
  final String currentMarket;
  final Map<String, String> allMarkets;
  final Function(String) onMarketSelected;

  const MarketSelectorScreen({
    Key? key,
    required this.currentMarket,
    required this.allMarkets,
    required this.onMarketSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: context.colors.surface,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: context.colors.surfaceContainer,
        middle: Text(
          'Selecionar Mercado',
          style: context.textStyles.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      child: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.lg),
          itemCount: allMarkets.length,
          itemBuilder: (context, index) {
            final entry = allMarkets.entries.elementAt(index);
            final isSelected = entry.key == currentMarket;

            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {
                  AppHaptics.light();
                  onMarketSelected(entry.key);
                },
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? context.colors.primaryContainer 
                        : context.colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppSpacing.xl),
                    border: Border.all(
                      color: isSelected 
                          ? context.colors.primary 
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.chart_bar_square,
                        color: isSelected 
                            ? context.colors.primary 
                            : context.colors.onSurfaceVariant,
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: context.textStyles.bodyLarge?.copyWith(
                            color: isSelected 
                                ? context.colors.onPrimaryContainer 
                                : context.colors.onSurfaceVariant,
                            fontWeight: isSelected 
                                ? FontWeight.bold 
                                : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          CupertinoIcons.check_mark_circled_solid,
                          color: context.colors.primary,
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}