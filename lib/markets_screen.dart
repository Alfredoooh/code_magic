// lib/markets_screen.dart - Material Design 3
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'theme/app_theme.dart';
import 'theme/app_colors.dart';
import 'theme/app_widgets.dart';
import 'routes.dart';
import 'trade_screen.dart';
import 'all_markets_screen.dart';
import 'news_detail_screen.dart';
import 'market_detail_screen.dart';

class MarketsScreen extends StatefulWidget {
  final String token;

  const MarketsScreen({Key? key, required this.token}) : super(key: key);

  @override
  State<MarketsScreen> createState() => _MarketsScreenState();
}

class _MarketsScreenState extends State<MarketsScreen>
    with AutomaticKeepAliveClientMixin {
  WebSocketChannel? _channel;
  final Map<String, MarketData> _marketData = {};
  bool _isConnected = false;
  List<NewsItem> _newsItems = [];
  bool _isLoadingNews = true;
  String? _newsError;

  final List<String> _topMarkets = [
    'R_100',
    'BOOM1000',
    'CRASH1000',
    '1HZ100V',
    'STPRNG'
  ];

  final Map<String, MarketInfo> _allMarkets = {
    'R_10': MarketInfo('Volatility 10',
        'https://raw.githubusercontent.com/alfredoooh/database/main/gallery/icons/v10.png',
        'Volatility'),
    'R_25': MarketInfo('Volatility 25',
        'https://raw.githubusercontent.com/alfredoooh/database/main/gallery/icons/v25.png',
        'Volatility'),
    'R_50': MarketInfo('Volatility 50',
        'https://raw.githubusercontent.com/alfredoooh/database/main/gallery/icons/v50.png',
        'Volatility'),
    'R_75': MarketInfo('Volatility 75',
        'https://raw.githubusercontent.com/alfredoooh/database/main/gallery/icons/v75.png',
        'Volatility'),
    'R_100': MarketInfo('Volatility 100',
        'https://raw.githubusercontent.com/alfredoooh/database/main/gallery/icons/v100.png',
        'Volatility'),
    '1HZ10V': MarketInfo('Volatility 10 (1s)',
        'https://raw.githubusercontent.com/alfredoooh/database/main/gallery/icons/v10-1s.png',
        'Volatility'),
    '1HZ25V': MarketInfo('Volatility 25 (1s)',
        'https://raw.githubusercontent.com/alfredoooh/database/main/gallery/icons/v25-1s.png',
        'Volatility'),
    '1HZ50V': MarketInfo('Volatility 50 (1s)',
        'https://raw.githubusercontent.com/alfredoooh/database/main/gallery/icons/v50-1s.png',
        'Volatility'),
    '1HZ75V': MarketInfo('Volatility 75 (1s)',
        'https://raw.githubusercontent.com/alfredoooh/database/main/gallery/icons/v75-1s.png',
        'Volatility'),
    '1HZ100V': MarketInfo('Volatility 100 (1s)',
        'https://raw.githubusercontent.com/alfredoooh/database/main/gallery/icons/v100-1s.png',
        'Volatility'),
    'BOOM300N': MarketInfo('Boom 300',
        'https://raw.githubusercontent.com/alfredoooh/database/main/gallery/icons/boom300.png',
        'Boom/Crash'),
    'BOOM500': MarketInfo('Boom 500',
        'https://raw.githubusercontent.com/alfredoooh/database/main/gallery/icons/boom500.png',
        'Boom/Crash'),
    'BOOM600N': MarketInfo('Boom 600',
        'https://raw.githubusercontent.com/alfredoooh/database/main/gallery/icons/boom600.png',
        'Boom/Crash'),
    'BOOM900': MarketInfo('Boom 900',
        'https://raw.githubusercontent.com/alfredoooh/database/main/gallery/icons/boom900.png',
        'Boom/Crash'),
    'BOOM1000': MarketInfo('Boom 1000',
        'https://raw.githubusercontent.com/alfredoooh/database/main/gallery/icons/boom1000.png',
        'Boom/Crash'),
    'CRASH300N': MarketInfo('Crash 300',
        'https://raw.githubusercontent.com/alfredoooh/database/main/gallery/icons/crash300.png',
        'Boom/Crash'),
    'CRASH500': MarketInfo('Crash 500',
        'https://raw.githubusercontent.com/alfredoooh/database/main/gallery/icons/crash500.png',
        'Boom/Crash'),
    'CRASH600N': MarketInfo('Crash 600',
        'https://raw.githubusercontent.com/alfredoooh/database/main/gallery/icons/crash600.png',
        'Boom/Crash'),
    'CRASH900': MarketInfo('Crash 900',
        'https://raw.githubusercontent.com/alfredoooh/database/main/gallery/icons/crash900.png',
        'Boom/Crash'),
    'CRASH1000': MarketInfo('Crash 1000',
        'https://raw.githubusercontent.com/alfredoooh/database/main/gallery/icons/crash1000.png',
        'Boom/Crash'),
    'STPRNG': MarketInfo('Step Index',
        'https://raw.githubusercontent.com/alfredoooh/database/main/gallery/icons/step.png',
        'Step'),
    'JD10': MarketInfo('Jump 10',
        'https://raw.githubusercontent.com/alfredoooh/database/main/gallery/icons/jump10.png',
        'Jump'),
    'JD25': MarketInfo('Jump 25',
        'https://raw.githubusercontent.com/alfredoooh/database/main/gallery/icons/jump25.png',
        'Jump'),
    'JD50': MarketInfo('Jump 50',
        'https://raw.githubusercontent.com/alfredoooh/database/main/gallery/icons/jump50.png',
        'Jump'),
    'JD75': MarketInfo('Jump 75',
        'https://raw.githubusercontent.com/alfredoooh/database/main/gallery/icons/jump75.png',
        'Jump'),
    'JD100': MarketInfo('Jump 100',
        'https://raw.githubusercontent.com/alfredoooh/database/main/gallery/icons/jump100.png',
        'Jump'),
  };

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
    _fetchCryptoNews();
  }

  @override
  void dispose() {
    _channel?.sink.close();
    super.dispose();
  }

  Future<void> _fetchCryptoNews() async {
    setState(() {
      _isLoadingNews = true;
      _newsError = null;
    });

    try {
      final response = await http.get(
        Uri.parse(
          'https://cryptopanic.com/api/v1/posts/?auth_token=YOUR_API_TOKEN&public=true&kind=news',
        ),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List;

        setState(() {
          _newsItems = results.map((item) {
            return NewsItem(
              title: item['title'] ?? '',
              summary: item['title'] ?? '',
              source: item['source']?['title'] ?? 'Unknown',
              favicon:
                  'https://www.google.com/s2/favicons?domain=${item['source']?['domain'] ?? 'example.com'}&sz=128',
              time: _formatTime(item['published_at'] ?? ''),
              url: item['url'] ?? '',
              category: item['currencies']?.isNotEmpty == true
                  ? (item['currencies'][0]['code'] ?? 'NEWS')
                  : 'NEWS',
              imageUrl: item['currencies']?.isNotEmpty == true
                  ? 'https://cryptologos.cc/logos/${item['currencies'][0]['code'].toString().toLowerCase()}-${item['currencies'][0]['slug']}-logo.png'
                  : null,
            );
          }).toList();
          _isLoadingNews = false;
        });
      } else {
        setState(() {
          _newsError =
              'Failed to load news. Status: ${response.statusCode}';
          _isLoadingNews = false;
        });
      }
    } catch (e) {
      setState(() {
        _newsError = 'Connection error: ${e.toString()}';
        _isLoadingNews = false;
      });
    }
  }

  String _formatTime(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      final diff = DateTime.now().difference(date);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${(diff.inDays / 7).floor()}w ago';
    } catch (e) {
      return 'Recently';
    }
  }

  void _connectWebSocket() {
    try {
      _channel = WebSocketChannel.connect(
        Uri.parse('wss://ws.derivws.com/websockets/v3?app_id=71954'),
      );

      setState(() => _isConnected = true);

      _channel!.stream.listen(
        (message) {
          final data = json.decode(message);

          if (data['msg_type'] == 'tick') {
            final tick = data['tick'];
            final symbol = tick['symbol'];
            final quote = double.parse(tick['quote'].toString());

            setState(() {
              if (_marketData.containsKey(symbol)) {
                final oldPrice = _marketData[symbol]!.price;
                _marketData[symbol] = MarketData(
                  price: quote,
                  change: ((quote - oldPrice) / oldPrice) * 100,
                  timestamp: DateTime.now(),
                );
              } else {
                _marketData[symbol] = MarketData(
                  price: quote,
                  change: 0.0,
                  timestamp: DateTime.now(),
                );
              }
            });
          }
        },
        onError: (error) {
          debugPrint('WebSocket error: $error');
          setState(() => _isConnected = false);
        },
        onDone: () {
          setState(() => _isConnected = false);
          Future.delayed(const Duration(seconds: 3), _connectWebSocket);
        },
      );

      for (var symbol in _topMarkets) {
        _channel!.sink.add(json.encode({'ticks': symbol, 'subscribe': 1}));
      }
    } catch (e) {
      debugPrint('WebSocket connection error: $e');
      setState(() => _isConnected = false);
    }
  }

  void _openAllMarkets() {
    AppHaptics.selection();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AllMarketsScreen(
          token: widget.token,
          allMarkets: _allMarkets,
          marketData: _marketData,
          channel: _channel,
        ),
      ),
    );
  }

  void _openNewsDetail(NewsItem news) {
    AppHaptics.selection();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => NewsDetailScreen(news: news),
      ),
    );
  }

  void _openMarketDetail(String symbol) {
    AppHaptics.selection();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MarketDetailScreen(
          symbol: symbol,
          marketInfo: _allMarkets[symbol]!,
          marketData: _marketData[symbol],
          token: widget.token,
          channel: _channel,
        ),
      ),
    );
  }

  Future<void> _handleRefresh() async {
    AppHaptics.medium();
    await _fetchCryptoNews();
    if (mounted) {
      AppSnackbar.success(context, 'Markets updated! 📈');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: context.surface,
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  FadeInWidget(
                    child: _buildConnectionStatus(),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FadeInWidget(
                    delay: const Duration(milliseconds: 50),
                    child: _buildTopMarketsSection(),
                  ),
                  const SizedBox(height: AppSpacing.xxxl),
                  FadeInWidget(
                    delay: const Duration(milliseconds: 100),
                    child: _buildNewsSection(),
                  ),
                  const SizedBox(height: AppSpacing.massive),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionStatus() {
    if (!_isConnected) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.warning.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: AppColors.warning.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.cloud_off_rounded,
              color: AppColors.warning,
              size: 20,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Reconnecting to market data...',
                style: context.textStyles.bodySmall?.copyWith(
                  color: AppColors.warning,
                ),
              ),
            ),
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.warning),
              ),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildTopMarketsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                // Bitcoin PNG icon instead of Material icon
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
                  child: CachedNetworkImage(
                    imageUrl: 'https://cryptologos.cc/logos/bitcoin-btc-logo.png',
                    width: 24,
                    height: 24,
                    fit: BoxFit.contain,
                    errorWidget: (context, error, stackTrace) => Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.show_chart_rounded,
                        color: AppColors.primary,
                        size: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Top Markets',
                  style: context.textStyles.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            TertiaryButton(
              text: 'View All',
              icon: Icons.arrow_forward_rounded,
              onPressed: _openAllMarkets,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        ...(_topMarkets.asMap().entries.map((entry) {
          final index = entry.key;
          final symbol = entry.value;
          final info = _allMarkets[symbol]!;
          final data = _marketData[symbol];
          return StaggeredListItem(
            index: index,
            delay: const Duration(milliseconds: 50),
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _buildMarketCard(symbol, info, data),
            ),
          );
        }).toList()),
      ],
    );
  }

  Widget _buildMarketCard(String symbol, MarketInfo info, MarketData? data) {
    final isPositive = (data?.change ?? 0) >= 0;
    final changeColor = isPositive ? AppColors.success : AppColors.error;

    return AnimatedCard(
      onTap: () => _openMarketDetail(symbol),
      child: Row(
        children: [
          // Circular container with icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: context.colors.surfaceContainerHighest,
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(8),
            child: ClipOval(
              child: CachedNetworkImage(
                imageUrl: info.iconUrl,
                fit: BoxFit.contain,
                placeholder: (context, url) => Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                errorWidget: (context, error, stackTrace) => Container(
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      symbol.substring(0, 1),
                      style: context.textStyles.titleMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info.name,
                  style: context.textStyles.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Row(
                  children: [
                    Text(
                      symbol,
                      style: context.textStyles.labelSmall?.copyWith(
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    AppBadge(
                      text: info.category,
                      color: AppColors.secondary,
                      outlined: true,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Price
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                data != null ? '\$${data.price.toStringAsFixed(2)}' : '...',
                style: context.textStyles.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
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
                    color: changeColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    border: Border.all(
                      color: changeColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositive
                            ? Icons.arrow_upward_rounded
                            : Icons.arrow_downward_rounded,
                        size: 12,
                        color: changeColor,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${data.change.abs().toStringAsFixed(2)}%',
                        style: context.textStyles.labelSmall?.copyWith(
                          color: changeColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNewsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.newspaper_rounded,
              color: AppColors.info,
              size: 24,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Latest News',
              style: context.textStyles.titleLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        if (_isLoadingNews)
          const LoadingOverlay(
            isLoading: true,
            message: 'Loading news...',
            child: SizedBox(height: 200),
          )
        else if (_newsError != null)
          EmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Failed to load news',
            subtitle: _newsError!,
            actionText: 'Try Again',
            onAction: _fetchCryptoNews,
          )
        else if (_newsItems.isEmpty)
          EmptyState(
            icon: Icons.newspaper_rounded,
            title: 'No news available',
            subtitle: 'Check back later for the latest updates',
          )
        else
          _buildNewsGrid(),
      ],
    );
  }

  Widget _buildNewsGrid() {
    return Column(
      children: [
        // Featured news
        if (_newsItems.isNotEmpty)
          StaggeredListItem(
            index: 0,
            child: _buildFeaturedNews(_newsItems[0]),
          ),

        const SizedBox(height: AppSpacing.md),

        // Two column grid
        if (_newsItems.length > 1)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_newsItems.length > 1)
                Expanded(
                  child: StaggeredListItem(
                    index: 1,
                    delay: const Duration(milliseconds: 50),
                    child: _buildSmallNews(_newsItems[1]),
                  ),
                ),
              if (_newsItems.length > 2)
                const SizedBox(width: AppSpacing.md),
              if (_newsItems.length > 2)
                Expanded(
                  child: StaggeredListItem(
                    index: 2,
                    delay: const Duration(milliseconds: 100),
                    child: _buildSmallNews(_newsItems[2]),
                  ),
                ),
            ],
          ),

        const SizedBox(height: AppSpacing.md),

        // Horizontal scroll
        if (_newsItems.length > 3)
          SizedBox(
            height: 240,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: _newsItems.length - 3,
              separatorBuilder: (context, index) =>
                  const SizedBox(width: AppSpacing.md),
              itemBuilder: (context, index) {
                return StaggeredListItem(
                  index: index + 3,
                  delay: const Duration(milliseconds: 30),
                  child: _buildHorizontalNews(_newsItems[index + 3]),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildFeaturedNews(NewsItem news) {
    return Hero(
      tag: 'news_${news.url}',
      child: AnimatedCard(
        onTap: () => _openNewsDetail(news),
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (news.imageUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSpacing.radiusMd),
                ),
                child: CachedNetworkImage(
                  imageUrl: news.imageUrl!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 200,
                    color: context.colors.surfaceContainerHighest,
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (context, error, stackTrace) => Container(
                    height: 200,
                    color: context.colors.surfaceContainerHighest,
                    child: Icon(
                      Icons.broken_image_rounded,
                      size: 48,
                      color: context.colors.onSurfaceVariant.withOpacity(0.3),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppBadge(
                    text: news.category.toUpperCase(),
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    news.title,
                    style: context.textStyles.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: CachedNetworkImage(
                          imageUrl: news.favicon,
                          width: 16,
                          height: 16,
                          errorWidget: (context, error, stackTrace) => Icon(
                            Icons.public_rounded,
                            size: 16,
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          '${news.source} • ${news.time}',
                          style: context.textStyles.labelSmall?.copyWith(
                            color: context.colors.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallNews(NewsItem news) {
    return AnimatedCard(
      onTap: () => _openNewsDetail(news),
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (news.imageUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppSpacing.radiusMd),
              ),
              child: CachedNetworkImage(
                imageUrl: news.imageUrl!,
                height: 100,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 100,
                  color: context.colors.surfaceContainerHighest,
                  child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (context, error, stackTrace) => Container(
                  height: 100,
                  color: context.colors.surfaceContainerHighest,
                  child: Icon(
                    Icons.broken_image_rounded,
                    size: 32,
                    color: context.colors.onSurfaceVariant.withOpacity(0.3),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  news.title,
                  style: context.textStyles.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: CachedNetworkImage(
                        imageUrl: news.favicon,
                        width: 12,
                        height: 12,
                        errorWidget: (context, error, stackTrace) => Icon(
                          Icons.public_rounded,
                          size: 12,
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xxs),
                    Expanded(
                      child: Text(
                        news.source,
                        style: context.textStyles.labelSmall?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalNews(NewsItem news) {
    return AnimatedCard(
      onTap: () => _openNewsDetail(news),
      padding: EdgeInsets.zero,
      child: SizedBox(
        width: 300,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (news.imageUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppSpacing.radiusMd),
                ),
                child: CachedNetworkImage(
                  imageUrl: news.imageUrl!,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 140,
                    color: context.colors.surfaceContainerHighest,
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (context, error, stackTrace) => Container(
                    height: 140,
                    color: context.colors.surfaceContainerHighest,
                    child: Icon(
                      Icons.broken_image_rounded,
                      size: 32,
                      color: context.colors.onSurfaceVariant.withOpacity(0.3),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    news.title,
                    style: context.textStyles.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: CachedNetworkImage(
                          imageUrl: news.favicon,
                          width: 12,
                          height: 12,
                          errorWidget: (context, error, stackTrace) => Icon(
                            Icons.public_rounded,
                            size: 12,
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xxs),
                      Expanded(
                        child: Text(
                          '${news.source} • ${news.time}',
                          style: context.textStyles.labelSmall?.copyWith(
                            color: context.colors.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Models
class MarketInfo {
  final String name;
  final String iconUrl;
  final String category;

  MarketInfo(this.name, this.iconUrl, this.category);
}

class MarketData {
  final double price;
  final double change;
  final DateTime timestamp;

  MarketData({
    required this.price,
    required this.change,
    required this.timestamp,
  });
}

class NewsItem {
  final String title;
  final String summary;
  final String source;
  final String favicon;
  final String time;
  final String url;
  final String category;
  final String? imageUrl;

  NewsItem({
    required this.title,
    required this.summary,
    required this.source,
    required this.favicon,
    required this.time,
    required this.url,
    required this.category,
    this.imageUrl,
  });

  factory NewsItem.fromJson(Map<String, dynamic> json) {
    return NewsItem(
      title: json['title'] ?? '',
      summary: json['summary'] ?? json['title'] ?? '',
      source: json['source'] ?? 'Unknown',
      favicon: json['favicon'] ?? '',
      time: json['time'] ?? '',
      url: json['url'] ?? '',
      category: json['category'] ?? 'NEWS',
      imageUrl: json['image_url'] ?? json['imageUrl'] ?? json['thumbnail'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'summary': summary,
      'source': source,
      'favicon': favicon,
      'time': time,
      'url': url,
      'category': category,
      'image_url': imageUrl,
    };
  }
}