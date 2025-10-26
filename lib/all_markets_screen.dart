// all_markets_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'markets_screen.dart';
import 'market_detail_screen.dart';
import 'styles.dart';

class AllMarketsScreen extends StatefulWidget {
  final String token;
  final Map<String, MarketInfo> allMarkets;
  final Map<String, MarketData> marketData;
  final WebSocketChannel? channel;

  const AllMarketsScreen({
    Key? key,
    required this.token,
    required this.allMarkets,
    required this.marketData,
    this.channel,
  }) : super(key: key);

  @override
  State<AllMarketsScreen> createState() => _AllMarketsScreenState();
}

class _AllMarketsScreenState extends State<AllMarketsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'Boom/Crash';

  final List<String> _categories = [
    'Boom/Crash',
    'Volatility',
    'Jump',
    'Step',
    'Crypto',
  ];

  final Map<String, MarketInfo> _cryptoMarkets = {
    'cryBTCUSD': MarketInfo(
      'Bitcoin',
      'https://cryptologos.cc/logos/bitcoin-btc-logo.png',
      'Crypto',
    ),
    'cryETHUSD': MarketInfo(
      'Ethereum',
      'https://cryptologos.cc/logos/ethereum-eth-logo.png',
      'Crypto',
    ),
  };

  @override
  void initState() {
    super.initState();
    _subscribeToAllMarkets();
  }

  void _subscribeToAllMarkets() {
    if (widget.channel != null) {
      for (var symbol in [...widget.allMarkets.keys, ..._cryptoMarkets.keys]) {
        widget.channel!.sink.add(
          json.encode({'ticks': symbol, 'subscribe': 1}),
        );
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MapEntry<String, MarketInfo>> _getFilteredMarkets(String category) {
    Map<String, MarketInfo> allMarketsMap = {
      ...widget.allMarkets,
      ..._cryptoMarkets,
    };

    var markets = allMarketsMap.entries.where((entry) {
      final matchesCategory = entry.value.category == category;
      final matchesSearch = _searchQuery.isEmpty ||
          entry.value.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          entry.key.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    markets.sort((a, b) => a.value.name.compareTo(b.value.name));
    return markets;
  }

  void _openMarketDetail(String symbol) {
    AppHaptics.light();
    final info = widget.allMarkets[symbol] ?? _cryptoMarkets[symbol];
    if (info != null) {
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              MarketDetailScreen(
            symbol: symbol,
            marketInfo: info,
            marketData: widget.marketData[symbol],
            token: widget.token,
            channel: widget.channel,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 1.0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
              child: child,
            );
          },
          transitionDuration: AppMotion.medium,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
        title: const Text('Todos os Mercados'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search Bar
          FadeInWidget(
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar mercados...',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () {
                            AppHaptics.light();
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                            });
                          },
                        )
                      : null,
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                },
              ),
            ),
          ),

          // Category Chips
          FadeInWidget(
            delay: const Duration(milliseconds: 100),
            child: SizedBox(
              height: 50,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = _selectedCategory == category;

                  return Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: FilterChip(
                      selected: isSelected,
                      label: Text(category),
                      onSelected: (selected) {
                        if (selected) {
                          AppHaptics.selection();
                          setState(() => _selectedCategory = category);
                        }
                      },
                      backgroundColor: context.colors.surfaceContainer,
                      selectedColor: context.colors.primary,
                      labelStyle: TextStyle(
                        color: isSelected
                            ? context.colors.onPrimary
                            : context.colors.onSurface,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                      ),
                      side: BorderSide(
                        color: isSelected
                            ? context.colors.primary
                            : context.colors.outlineVariant,
                        width: 1,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Markets Count
          FadeInWidget(
            delay: const Duration(milliseconds: 200),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  Icon(
                    Icons.analytics_rounded,
                    size: 16,
                    color: context.colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '${_getFilteredMarkets(_selectedCategory).length} mercados',
                    style: context.textStyles.bodySmall?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Markets List
          Expanded(
            child: Builder(
              builder: (context) {
                final markets = _getFilteredMarkets(_selectedCategory);

                if (markets.isEmpty) {
                  return FadeInWidget(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.xl),
                            decoration: BoxDecoration(
                              color: context.colors.surfaceContainer,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.search_off_rounded,
                              color: context.colors.onSurfaceVariant,
                              size: 48,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          Text(
                            'Nenhum mercado encontrado',
                            style: context.textStyles.bodyLarge?.copyWith(
                              color: context.colors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            'Tente buscar por outro termo',
                            style: context.textStyles.bodySmall?.copyWith(
                              color: context.colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  itemCount: markets.length,
                  itemBuilder: (context, index) {
                    final entry = markets[index];
                    final symbol = entry.key;
                    final info = entry.value;
                    final data = widget.marketData[symbol];

                    return StaggeredListItem(
                      index: index,
                      child: _buildMarketCard(symbol, info, data),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketCard(String symbol, MarketInfo info, MarketData? data) {
    final isPositive = (data?.change ?? 0) >= 0;
    final changeColor = isPositive ? AppColors.success : AppColors.error;

    return GestureDetector(
      onTap: () => _openMarketDetail(symbol),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: context.colors.surfaceContainer,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: context.colors.outlineVariant,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: context.colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                child: Image.network(
                  info.iconUrl,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.currency_bitcoin_rounded,
                      color: context.colors.primary,
                      size: 24,
                    );
                  },
                ),
              ),
            ),

            const SizedBox(width: AppSpacing.md),

            // Name and Symbol
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    info.name,
                    style: context.textStyles.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    symbol,
                    style: context.textStyles.bodySmall?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // Price and Change
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  data != null ? data.price.toStringAsFixed(2) : '...',
                  style: context.textStyles.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                if (data != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: changeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPositive
                              ? Icons.arrow_upward_rounded
                              : Icons.arrow_downward_rounded,
                          color: changeColor,
                          size: 12,
                        ),
                        const SizedBox(width: AppSpacing.xxs),
                        Text(
                          '${data.change.abs().toStringAsFixed(2)}%',
                          style: context.textStyles.labelSmall?.copyWith(
                            color: changeColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            const SizedBox(width: AppSpacing.sm),

            // Arrow
            Icon(
              Icons.chevron_right_rounded,
              color: context.colors.onSurfaceVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}