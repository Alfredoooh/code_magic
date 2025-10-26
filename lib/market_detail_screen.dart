// lib/market_detail_screen.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'theme/app_theme.dart';
import 'theme/app_colors.dart';
import 'theme/app_widgets.dart';
import 'markets_screen.dart';
import 'trade_screen.dart';

class MarketDetailScreen extends StatefulWidget {
  final String symbol;
  final MarketInfo marketInfo;
  final MarketData? marketData;
  final String token;
  final WebSocketChannel? channel;

  const MarketDetailScreen({
    Key? key,
    required this.symbol,
    required this.marketInfo,
    this.marketData,
    required this.token,
    this.channel,
  }) : super(key: key);

  @override
  State<MarketDetailScreen> createState() => _MarketDetailScreenState();
}

class _MarketDetailScreenState extends State<MarketDetailScreen> {
  MarketData? _currentData;
  final List<double> _priceHistory = [];
  StreamSubscription? _streamSubscription;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _currentData = widget.marketData;

    // Adicionar alguns dados iniciais se já tiver marketData
    if (widget.marketData != null) {
      _priceHistory.add(widget.marketData!.price);
    }

    _subscribeToMarket();

    // Timer de timeout para indicar carregamento
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _isLoading) {
        setState(() => _isLoading = false);
      }
    });
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }

  void _subscribeToMarket() {
    if (widget.channel == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      widget.channel!.sink.add(json.encode({
        'ticks': widget.symbol,
        'subscribe': 1,
      }));

      _streamSubscription = widget.channel!.stream.listen(
        (message) {
          try {
            final data = json.decode(message);

            if (data['msg_type'] == 'tick' && data['tick']['symbol'] == widget.symbol) {
              final tick = data['tick'];
              final quote = double.parse(tick['quote'].toString());

              if (mounted) {
                setState(() {
                  _isLoading = false;

                  if (_currentData != null) {
                    final oldPrice = _currentData!.price;
                    _currentData = MarketData(
                      price: quote,
                      change: ((quote - oldPrice) / (oldPrice == 0 ? 1 : oldPrice)) * 100,
                      timestamp: DateTime.now(),
                    );
                  } else {
                    _currentData = MarketData(
                      price: quote,
                      change: 0.0,
                      timestamp: DateTime.now(),
                    );
                  }

                  _priceHistory.add(quote);
                  if (_priceHistory.length > 100) {
                    _priceHistory.removeAt(0);
                  }
                });
              }
            }
          } catch (e) {
            debugPrint('Error parsing market data: $e');
          }
        },
        onError: (error) {
          debugPrint('WebSocket error: $error');
          if (mounted) {
            setState(() => _isLoading = false);
          }
        },
      );
    } catch (e) {
      debugPrint('Error subscribing to market: $e');
      setState(() => _isLoading = false);
    }
  }

  void _openTrade() {
    AppHaptics.heavy();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => TradeScreen(
          token: widget.token,
          initialMarket: widget.symbol,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPositive = (_currentData?.change ?? 0) >= 0;
    final changeColor = isPositive ? AppColors.success : AppColors.error;

    return Scaffold(
      backgroundColor: context.surface,
      appBar: SecondaryAppBar(
        title: widget.marketInfo.name,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              AppHaptics.light();
              _subscribeToMarket();
              AppSnackbar.info(context, 'Atualizando dados...');
            },
          ),
        ],
      ),
      body: _isLoading && _currentData == null
          ? LoadingOverlay(
              isLoading: true,
              message: 'Carregando dados do mercado...',
              child: const SizedBox(),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      // Market Icon & Price
                      FadeInWidget(
                        child: Center(
                          child: Column(
                            children: [
                              Container(
                                width: 96,
                                height: 96,
                                decoration: BoxDecoration(
                                  color: context.colors.surfaceVariant,
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                                  child: Image.network(
                                    widget.marketInfo.iconUrl,
                                    width: 96,
                                    height: 96,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: AppColors.primary.withOpacity(0.15),
                                        child: const Icon(
                                          Icons.show_chart_rounded,
                                          color: AppColors.primary,
                                          size: 48,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xl),
                              Text(
                                _currentData != null
                                    ? '\$${_currentData!.price.toStringAsFixed(2)}'
                                    : 'Carregando...',
                                style: context.textStyles.displayLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              if (_currentData != null)
                                AppBadge(
                                  text: '${isPositive ? '+' : ''}${_currentData!.change.toStringAsFixed(2)}%',
                                  color: changeColor,
                                ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xxl),

                      // Chart
                      FadeInWidget(
                        delay: const Duration(milliseconds: 100),
                        child: AnimatedCard(
                          child: Container(
                            height: 240,
                            padding: const EdgeInsets.all(AppSpacing.md),
                            child: _priceHistory.length > 2
                                ? CustomPaint(
                                    painter: SimpleChartPainter(_priceHistory, changeColor),
                                  )
                                : Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.show_chart_rounded,
                                          size: 48,
                                          color: context.colors.onSurfaceVariant.withOpacity(0.5),
                                        ),
                                        const SizedBox(height: AppSpacing.md),
                                        Text(
                                          'Aguardando dados do gráfico...',
                                          style: context.textStyles.bodyMedium?.copyWith(
                                            color: context.colors.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.xxl),

                      // Market Info
                      FadeInWidget(
                        delay: const Duration(milliseconds: 200),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Informações do Mercado',
                              style: context.textStyles.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            _buildInfoCard(
                              icon: Icons.tag_rounded,
                              label: 'Símbolo',
                              value: widget.symbol,
                              color: AppColors.primary,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            _buildInfoCard(
                              icon: Icons.category_rounded,
                              label: 'Categoria',
                              value: widget.marketInfo.category,
                              color: AppColors.secondary,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            _buildInfoCard(
                              icon: Icons.label_rounded,
                              label: 'Nome Completo',
                              value: widget.marketInfo.name,
                              color: AppColors.tertiary,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            _buildInfoCard(
                              icon: Icons.access_time_rounded,
                              label: 'Última Atualização',
                              value: _currentData != null ? _formatTime(_currentData!.timestamp) : 'N/A',
                              color: AppColors.info,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.massive),
                    ],
                  ),
                ),

                // Trade Button
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: context.surface,
                    border: Border(
                      top: BorderSide(
                        color: context.colors.outlineVariant,
                        width: 1,
                      ),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 12,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: SizedBox(
                      width: double.infinity,
                      child: PrimaryButton(
                        text: 'Negociar ${widget.symbol}',
                        icon: Icons.trending_up_rounded,
                        onPressed: _openTrade,
                        expanded: true,
                      ),
                    ),
                  ),
                ),
              ],
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: context.textStyles.labelSmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  value,
                  style: context.textStyles.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inSeconds < 60) return '${diff.inSeconds}s atrás';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m atrás';
    if (diff.inHours < 24) return '${diff.inHours}h atrás';
    return '${diff.inDays}d atrás';
  }
}

class SimpleChartPainter extends CustomPainter {
  final List<double> prices;
  final Color color;

  SimpleChartPainter(this.prices, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (prices.length < 2) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final minPrice = prices.reduce((a, b) => a < b ? a : b);
    final maxPrice = prices.reduce((a, b) => a > b ? a : b);
    final priceRange = maxPrice - minPrice;

    if (priceRange == 0) {
      // Linha reta no meio se não há variação
      final y = size.height / 2;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
      return;
    }

    final path = Path();
    final spacing = size.width / (prices.length - 1);

    for (var i = 0; i < prices.length; i++) {
      final x = i * spacing;
      final normalizedY = (prices[i] - minPrice) / priceRange;
      final y = size.height - (normalizedY * size.height * 0.8) - (size.height * 0.1);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);

    // Fill area under the line
    final fillPath = Path.from(path);
    fillPath.lineTo(size.width, size.height);
    fillPath.lineTo(0, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withOpacity(0.3),
          color.withOpacity(0.05),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);

    // Draw points
    final pointPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (var i = 0; i < prices.length; i++) {
      if (i % 5 == 0 || i == prices.length - 1) {
        final x = i * spacing;
        final normalizedY = (prices[i] - minPrice) / priceRange;
        final y = size.height - (normalizedY * size.height * 0.8) - (size.height * 0.1);

        canvas.drawCircle(Offset(x, y), 4, pointPaint);
        canvas.drawCircle(
          Offset(x, y),
          6,
          Paint()
            ..color = color.withOpacity(0.3)
            ..style = PaintingStyle.fill,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}