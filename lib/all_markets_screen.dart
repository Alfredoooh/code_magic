// lib/all_markets_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'markets_screen.dart';
import 'market_detail_screen.dart';
import 'theme/app_theme.dart';
import 'theme/app_colors.dart';
import 'theme/app_widgets.dart';

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
  String _sortBy = 'name'; // name, price, change

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Boom/Crash', 'icon': Icons.trending_up_rounded},
    {'name': 'Volatility', 'icon': Icons.show_chart_rounded},
    {'name': 'Jump', 'icon': Icons.electric_bolt_rounded},
    {'name': 'Step', 'icon': Icons.stairs_rounded},
    {'name': 'Crypto', 'icon': Icons.currency_bitcoin_rounded},
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

    // Apply sorting
    markets.sort((a, b) {
      switch (_sortBy) {
        case 'price':
          final priceA = widget.marketData[a.key]?.price ?? 0;
          final priceB = widget.marketData[b.key]?.price ?? 0;
          return priceB.compareTo(priceA);
        case 'change':
          final changeA = widget.marketData[a.key]?.change ?? 0;
          final changeB = widget.marketData[b.key]?.change ?? 0;
          return changeB.abs().compareTo(changeA.abs());
        default:
          return a.value.name.compareTo(b.value.name);
      }
    });

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
      appBar: SecondaryAppBar(
        title: 'Mercados',
        onBack: () {
          AppHaptics.light();
          Navigator.pop(context);
        },
        actions: [
          IconButton(
            icon: Icon(Icons.sort_rounded),
            tooltip: 'Ordenar',
            onPressed: _showSortOptions,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          FadeInWidget(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: SearchField(
                hint: 'Buscar mercados...',
                controller: _searchController,
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                },
                onClear: () {
                  setState(() {
                    _searchController.clear();
                    _searchQuery = '';
                  });
                },
              ),
            ),
          ),

          // Category Chips
          FadeInWidget(
            delay: Duration(milliseconds: 100),
            child: SizedBox(
              height: 56,
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final categoryName = category['name'] as String;
                  final categoryIcon = category['icon'] as IconData;
                  final isSelected = _selectedCategory == categoryName;
                  final marketCount = _getFilteredMarkets(categoryName).length;

                  return Padding(
                    padding: EdgeInsets.only(right: AppSpacing.sm),
                    child: FilterChip(
                      selected: isSelected,
                      avatar: Icon(
                        categoryIcon,
                        size: 18,
                        color: isSelected
                            ? context.colors.onPrimaryContainer
                            : context.colors.onSurface,
                      ),
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(categoryName),
                          if (marketCount > 0) ...[
                            SizedBox(width: AppSpacing.xs),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: AppSpacing.xs,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? context.colors.onPrimaryContainer
                                        .withOpacity(0.2)
                                    : context.colors.onSurface.withOpacity(0.1),
                                borderRadius:
                                    BorderRadius.circular(AppSpacing.radiusSm),
                              ),
                              child: Text(
                                marketCount.toString(),
                                style: context.textStyles.labelSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          AppHaptics.selection();
                          setState(() => _selectedCategory = categoryName);
                        }
                      },
                      selectedColor: context.colors.primaryContainer,
                      checkmarkColor: context.colors.onPrimaryContainer,
                    ),
                  );
                },
              ),
            ),
          ),

          SizedBox(height: AppSpacing.lg),

          // Header with count and sort indicator
          FadeInWidget(
            delay: Duration(milliseconds: 200),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  Icon(
                    Icons.analytics_rounded,
                    size: 16,
                    color: context.colors.onSurfaceVariant,
                  ),
                  SizedBox(width: AppSpacing.xs),
                  Text(
                    '${_getFilteredMarkets(_selectedCategory).length} ${_getFilteredMarkets(_selectedCategory).length == 1 ? 'mercado' : 'mercados'}',
                    style: context.textStyles.bodyMedium?.copyWith(
                      color: context.colors.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Spacer(),
                  if (_sortBy != 'name')
                    AppBadge(
                      text: _sortBy == 'price' ? 'Por Preço' : 'Por Variação',
                      color: context.colors.primary,
                      outlined: true,
                    ),
                ],
              ),
            ),
          ),

          SizedBox(height: AppSpacing.md),

          // Markets Grid/List
          Expanded(
            child: Builder(
              builder: (context) {
                final markets = _getFilteredMarkets(_selectedCategory);

                if (markets.isEmpty) {
                  return FadeInWidget(
                    child: EmptyState(
                      icon: _searchQuery.isNotEmpty
                          ? Icons.search_off_rounded
                          : Icons.store_rounded,
                      title: _searchQuery.isNotEmpty
                          ? 'Nenhum mercado encontrado'
                          : 'Sem mercados disponíveis',
                      subtitle: _searchQuery.isNotEmpty
                          ? 'Tente buscar por outro termo'
                          : 'Não há mercados nesta categoria',
                      actionText: _searchQuery.isNotEmpty ? 'Limpar Busca' : null,
                      onAction: _searchQuery.isNotEmpty
                          ? () {
                              AppHaptics.light();
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            }
                          : null,
                    ),
                  );
                }

                return GridView.builder(
                  padding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.sm,
                  ),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.85,
                    crossAxisSpacing: AppSpacing.md,
                    mainAxisSpacing: AppSpacing.md,
                  ),
                  itemCount: markets.length,
                  itemBuilder: (context, index) {
                    final entry = markets[index];
                    final symbol = entry.key;
                    final info = entry.value;
                    final data = widget.marketData[symbol];

                    return StaggeredListItem(
                      index: index,
                      delay: Duration(milliseconds: 30),
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

    return AnimatedCard(
      onTap: () => _openMarketDetail(symbol),
      child: Container(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon and Symbol
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: context.colors.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    child: Image.network(
                      info.iconUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.currency_bitcoin_rounded,
                          color: context.colors.primary,
                          size: 20,
                        );
                      },
                    ),
                  ),
                ),
                Spacer(),
                if (data != null)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: changeColor.withOpacity(0.15),
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
                          size: 10,
                        ),
                        SizedBox(width: 2),
                        Text(
                          '${data.change.abs().toStringAsFixed(1)}%',
                          style: context.textStyles.labelSmall?.copyWith(
                            color: changeColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            SizedBox(height: AppSpacing.md),

            // Name
            Text(
              info.name,
              style: context.textStyles.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            SizedBox(height: AppSpacing.xxs),

            // Symbol
            Text(
              symbol,
              style: context.textStyles.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),

            Spacer(),

            // Price
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Preço',
                        style: context.textStyles.bodySmall?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(height: AppSpacing.xxs),
                      Text(
                        data != null ? data.price.toStringAsFixed(2) : '...',
                        style: context.textStyles.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: context.colors.onSurfaceVariant,
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showSortOptions() {
    AppModalBottomSheet.show(
      context: context,
      title: 'Ordenar Mercados',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppListTile(
            title: 'Por Nome',
            subtitle: 'Ordem alfabética',
            leading: Icon(Icons.sort_by_alpha_rounded),
            trailing: _sortBy == 'name'
                ? Icon(Icons.check_circle_rounded, color: AppColors.success)
                : null,
            onTap: () {
              AppHaptics.selection();
              setState(() => _sortBy = 'name');
              Navigator.pop(context);
            },
          ),
          AppListTile(
            title: 'Por Preço',
            subtitle: 'Maior para menor',
            leading: Icon(Icons.attach_money_rounded),
            trailing: _sortBy == 'price'
                ? Icon(Icons.check_circle_rounded, color: AppColors.success)
                : null,
            onTap: () {
              AppHaptics.selection();
              setState(() => _sortBy = 'price');
              Navigator.pop(context);
            },
          ),
          AppListTile(
            title: 'Por Variação',
            subtitle: 'Maior volatilidade',
            leading: Icon(Icons.trending_up_rounded),
            trailing: _sortBy == 'change'
                ? Icon(Icons.check_circle_rounded, color: AppColors.success)
                : null,
            onTap: () {
              AppHaptics.selection();
              setState(() => _sortBy = 'change');
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}