// lib/market_detail_screen.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
  final List<Map<String, dynamic>> _candlestickData = [];
  StreamSubscription? _streamSubscription;
  bool _isLoading = true;
  late WebViewController _webViewController;

  @override
  void initState() {
    super.initState();
    _currentData = widget.marketData;
    _initializeWebView();
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

  void _initializeWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..loadHtmlString(_buildCandlestickChartHtml());
  }

  String _buildCandlestickChartHtml() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? '#1C1B1F' : '#FFFFFF';
    final textColor = isDark ? '#E6E1E5' : '#1C1B1F';

    return '''
    <!DOCTYPE html>
    <html>
    <head>
      <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
      <script src="https://cdn.jsdelivr.net/npm/lightweight-charts@4.1.1/dist/lightweight-charts.standalone.production.js"></script>
      <style>
        body {
          margin: 0;
          padding: 0;
          background-color: $bgColor;
          overflow: hidden;
        }
        #chart {
          width: 100%;
          height: 100vh;
        }
      </style>
    </head>
    <body>
      <div id="chart"></div>
      <script>
        const chart = LightweightCharts.createChart(document.getElementById('chart'), {
          layout: {
            background: { color: '$bgColor' },
            textColor: '$textColor',
          },
          grid: {
            vertLines: { color: '$textColor' + '20' },
            horzLines: { color: '$textColor' + '20' },
          },
          crosshair: {
            mode: LightweightCharts.CrosshairMode.Normal,
          },
          timeScale: {
            borderColor: '$textColor' + '40',
            timeVisible: true,
            secondsVisible: true,
          },
          rightPriceScale: {
            borderColor: '$textColor' + '40',
          },
        });

        const candlestickSeries = chart.addCandlestickSeries({
          upColor: '#26a69a',
          downColor: '#ef5350',
          borderVisible: false,
          wickUpColor: '#26a69a',
          wickDownColor: '#ef5350',
        });

        chart.timeScale().fitContent();

        // Function to update chart data
        function updateChart(data) {
          try {
            candlestickSeries.setData(data);
            chart.timeScale().fitContent();
          } catch (e) {
            console.error('Error updating chart:', e);
          }
        }

        // Initial empty state
        updateChart([]);
      </script>
    </body>
    </html>
    ''';
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
              final epoch = tick['epoch'] ?? (DateTime.now().millisecondsSinceEpoch ~/ 1000);

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

                  // Update candlestick data
                  _updateCandlestick(epoch, quote);
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

  void _updateCandlestick(int epoch, double price) {
    final time = epoch;
    
    // Group by 5-second intervals
    final candleTime = (time ~/ 5) * 5;

    if (_candlestickData.isEmpty || _candlestickData.last['time'] != candleTime) {
      // New candle
      _candlestickData.add({
        'time': candleTime,
        'open': price,
        'high': price,
        'low': price,
        'close': price,
      });
    } else {
      // Update current candle
      final lastCandle = _candlestickData.last;
      lastCandle['high'] = price > lastCandle['high'] ? price : lastCandle['high'];
      lastCandle['low'] = price < lastCandle['low'] ? price : lastCandle['low'];
      lastCandle['close'] = price;
    }

    // Keep only last 100 candles
    if (_candlestickData.length > 100) {
      _candlestickData.removeAt(0);
    }

    // Update chart
    _updateChartData();
  }

  void _updateChartData() {
    final jsonData = json.encode(_candlestickData);
    _webViewController.runJavaScript('updateChart($jsonData)');
  }

  void _openTrade() {
    AppHaptics.heavy();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => TradeScreen(
          token: widget.token,
          initialMarket: widget.symbol,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
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
                              // Transparent container with icon only
                              SizedBox(
                                width: 96,
                                height: 96,
                                child: CachedNetworkImage(
                                  imageUrl: widget.marketInfo.iconUrl,
                                  fit: BoxFit.contain,
                                  placeholder: (context, url) => Center(
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  errorWidget: (context, error, stackTrace) {
                                    return Center(
                                      child: Text(
                                        widget.symbol.substring(0, 2),
                                        style: context.textStyles.displayMedium?.copyWith(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    );
                                  },
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

                      // Candlestick Chart
                      FadeInWidget(
                        delay: const Duration(milliseconds: 100),
                        child: AnimatedCard(
                          padding: EdgeInsets.zero,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            child: Container(
                              height: 300,
                              color: context.colors.surfaceVariant,
                              child: _candlestickData.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.candlestick_chart_rounded,
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
                                    )
                                  : WebViewWidget(controller: _webViewController),
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