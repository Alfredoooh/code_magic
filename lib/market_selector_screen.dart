// market_selector_screen.dart
import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'theme/app_colors.dart';
import 'theme/app_widgets.dart';

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
    return Scaffold(
      backgroundColor: context.surface,
      appBar: SecondaryAppBar(
        title: 'Selecionar Mercado',
      ),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.lg),
          physics: const BouncingScrollPhysics(),
          itemCount: allMarkets.length,
          itemBuilder: (context, index) {
            final entry = allMarkets.entries.elementAt(index);
            final isSelected = entry.key == currentMarket;

            return StaggeredListItem(
              index: index,
              delay: const Duration(milliseconds: 50),
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: AnimatedCard(
                  onTap: () {
                    AppHaptics.selection();
                    onMarketSelected(entry.key);
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? context.colors.primaryContainer 
                          : context.colors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                      border: Border.all(
                        color: isSelected 
                            ? context.colors.primary 
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? context.colors.primary.withOpacity(0.2)
                                : context.colors.surfaceContainer,
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          ),
                          child: Icon(
                            Icons.show_chart_rounded,
                            color: isSelected 
                                ? context.colors.primary 
                                : context.colors.onSurfaceVariant,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.value,
                                style: context.textStyles.bodyLarge?.copyWith(
                                  color: isSelected 
                                      ? context.colors.onPrimaryContainer 
                                      : context.colors.onSurface,
                                  fontWeight: isSelected 
                                      ? FontWeight.w700 
                                      : FontWeight.w500,
                                ),
                              ),
                              if (isSelected) ...[
                                const SizedBox(height: AppSpacing.xxs),
                                Text(
                                  'Mercado Atual',
                                  style: context.textStyles.bodySmall?.copyWith(
                                    color: context.colors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        if (isSelected)
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.xs),
                            decoration: BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 16,
                            ),
                          )
                        else
                          Icon(
                            Icons.chevron_right_rounded,
                            color: context.colors.onSurfaceVariant.withOpacity(0.5),
                            size: 20,
                          ),
                      ],
                    ),
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

// Alternative version with search capability
class MarketSelectorWithSearchScreen extends StatefulWidget {
  final String currentMarket;
  final Map<String, String> allMarkets;
  final Function(String) onMarketSelected;

  const MarketSelectorWithSearchScreen({
    Key? key,
    required this.currentMarket,
    required this.allMarkets,
    required this.onMarketSelected,
  }) : super(key: key);

  @override
  State<MarketSelectorWithSearchScreen> createState() => _MarketSelectorWithSearchScreenState();
}

class _MarketSelectorWithSearchScreenState extends State<MarketSelectorWithSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  late Map<String, String> _filteredMarkets;

  @override
  void initState() {
    super.initState();
    _filteredMarkets = widget.allMarkets;
    _searchController.addListener(_filterMarkets);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterMarkets() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredMarkets = widget.allMarkets;
      } else {
        _filteredMarkets = Map.fromEntries(
          widget.allMarkets.entries.where(
            (entry) => entry.value.toLowerCase().contains(query),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.surface,
      appBar: SecondaryAppBar(
        title: 'Selecionar Mercado',
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: SearchField(
              hint: 'Buscar mercado...',
              controller: _searchController,
              onClear: () {
                _searchController.clear();
                AppHaptics.light();
              },
            ),
          ),

          // Markets List
          Expanded(
            child: _filteredMarkets.isEmpty
                ? EmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'Nenhum mercado encontrado',
                    subtitle: 'Tente buscar com outro termo',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    physics: const BouncingScrollPhysics(),
                    itemCount: _filteredMarkets.length,
                    itemBuilder: (context, index) {
                      final entry = _filteredMarkets.entries.elementAt(index);
                      final isSelected = entry.key == widget.currentMarket;

                      return StaggeredListItem(
                        index: index,
                        delay: const Duration(milliseconds: 30),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: AnimatedCard(
                            onTap: () {
                              AppHaptics.selection();
                              widget.onMarketSelected(entry.key);
                              Navigator.pop(context);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              decoration: BoxDecoration(
                                color: isSelected 
                                    ? context.colors.primaryContainer 
                                    : context.colors.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                                border: Border.all(
                                  color: isSelected 
                                      ? context.colors.primary 
                                      : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(AppSpacing.sm),
                                    decoration: BoxDecoration(
                                      color: isSelected 
                                          ? context.colors.primary.withOpacity(0.2)
                                          : context.colors.surfaceContainer,
                                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                                    ),
                                    child: Icon(
                                      Icons.show_chart_rounded,
                                      color: isSelected 
                                          ? context.colors.primary 
                                          : context.colors.onSurfaceVariant,
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.lg),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          entry.value,
                                          style: context.textStyles.bodyLarge?.copyWith(
                                            color: isSelected 
                                                ? context.colors.onPrimaryContainer 
                                                : context.colors.onSurface,
                                            fontWeight: isSelected 
                                                ? FontWeight.w700 
                                                : FontWeight.w500,
                                          ),
                                        ),
                                        if (isSelected) ...[
                                          const SizedBox(height: AppSpacing.xxs),
                                          AppBadge(
                                            text: 'Atual',
                                            color: AppColors.success,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  if (isSelected)
                                    Container(
                                      padding: const EdgeInsets.all(AppSpacing.xs),
                                      decoration: BoxDecoration(
                                        color: AppColors.success,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.check_rounded,
                                        color: Colors.white,
                                        size: 16,
                                      ),
                                    )
                                  else
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      color: context.colors.onSurfaceVariant.withOpacity(0.5),
                                      size: 20,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}