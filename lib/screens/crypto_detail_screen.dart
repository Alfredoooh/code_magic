// lib/screens/crypto_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../widgets/app_ui_components.dart';
import '../widgets/app_colors.dart';
import 'crypto_list_screen.dart';

class CryptoDetailScreen extends StatefulWidget {
  final CryptoData crypto;

  const CryptoDetailScreen({Key? key, required this.crypto}) : super(key: key);

  @override
  _CryptoDetailScreenState createState() => _CryptoDetailScreenState();
}

class _CryptoDetailScreenState extends State<CryptoDetailScreen> {
  late WebViewController _chartController;
  late WebViewController _newsController;
  late WebViewController _technicalController;
  String _signal = 'NEUTRO';
  Color _signalColor = Colors.grey;

  @override
  void initState() {
    super.initState();
    _initWebViews();
    _calculateSignal();
  }

  void _calculateSignal() {
    if (widget.crypto.priceChange > 5) {
      _signal = 'COMPRAR';
      _signalColor = AppColors.success;
    } else if (widget.crypto.priceChange < -5) {
      _signal = 'VENDER';
      _signalColor = AppColors.error;
    } else {
      _signal = 'NEUTRO';
      _signalColor = AppColors.warning;
    }
  }

  void _initWebViews() {
    final symbol = 'BINANCE:${widget.crypto.symbol}USDT';

    _chartController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadHtmlString('''
        <!DOCTYPE html>
        <html>
          <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>body { margin: 0; padding: 0; }</style>
          </head>
          <body>
            <div class="tradingview-widget-container">
              <div id="tradingview_chart"></div>
              <script type="text/javascript" src="https://s3.tradingview.com/tv.js"></script>
              <script type="text/javascript">
                new TradingView.widget({
                  "width": "100%",
                  "height": 400,
                  "symbol": "$symbol",
                  "interval": "D",
                  "timezone": "Etc/UTC",
                  "theme": "dark",
                  "style": "1",
                  "locale": "br",
                  "toolbar_bg": "#f1f3f6",
                  "enable_publishing": false,
                  "hide_side_toolbar": false,
                  "allow_symbol_change": true,
                  "container_id": "tradingview_chart"
                });
              </script>
            </div>
          </body>
        </html>
      ''');

    _newsController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadHtmlString('''
        <!DOCTYPE html>
        <html>
          <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>body { margin: 0; padding: 0; }</style>
          </head>
          <body>
            <div class="tradingview-widget-container">
              <div class="tradingview-widget-container__widget"></div>
              <script type="text/javascript" src="https://s3.tradingview.com/external-embedding/embed-widget-timeline.js" async>
              {
                "feedMode": "symbol",
                "symbol": "$symbol",
                "colorTheme": "dark",
                "isTransparent": false,
                "displayMode": "regular",
                "width": "100%",
                "height": 400,
                "locale": "br"
              }
              </script>
            </div>
          </body>
        </html>
      ''');

    _technicalController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadHtmlString('''
        <!DOCTYPE html>
        <html>
          <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>body { margin: 0; padding: 0; }</style>
          </head>
          <body>
            <div class="tradingview-widget-container">
              <div class="tradingview-widget-container__widget"></div>
              <script type="text/javascript" src="https://s3.tradingview.com/external-embedding/embed-widget-technical-analysis.js" async>
              {
                "interval": "1m",
                "width": "100%",
                "isTransparent": false,
                "height": 400,
                "symbol": "$symbol",
                "showIntervalTabs": true,
                "locale": "br",
                "colorTheme": "dark"
              }
              </script>
            </div>
          </body>
        </html>
      ''');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppSecondaryAppBar(
        title: widget.crypto.symbol,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Price Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCard,
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Preço Atual',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '\$${widget.crypto.price < 1 ? widget.crypto.price.toStringAsFixed(6) : widget.crypto.price.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : Colors.black,
                              letterSpacing: -1,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: _signalColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _signalColor, width: 2),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                _signal == 'COMPRAR'
                                    ? Icons.trending_up_rounded
                                    : _signal == 'VENDER'
                                        ? Icons.trending_down_rounded
                                        : Icons.remove_rounded,
                                color: _signalColor,
                                size: 20,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _signal,
                                style: TextStyle(
                                  color: _signalColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: widget.crypto.priceChange >= 0
                            ? AppColors.success.withOpacity(0.15)
                            : AppColors.error.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: widget.crypto.priceChange >= 0
                              ? AppColors.success.withOpacity(0.3)
                              : AppColors.error.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        '${widget.crypto.priceChange >= 0 ? '+' : ''}${widget.crypto.priceChange.toStringAsFixed(2)}% (24h)',
                        style: TextStyle(
                          color: widget.crypto.priceChange >= 0 ? AppColors.success : AppColors.error,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Chart Section
              _buildSection(
                'Gráfico de Preço',
                isDark,
                SizedBox(
                  height: 400,
                  child: WebViewWidget(controller: _chartController),
                ),
              ),

              const SizedBox(height: 16),

              // Technical Analysis Section
              _buildSection(
                'Análise Técnica',
                isDark,
                SizedBox(
                  height: 400,
                  child: WebViewWidget(controller: _technicalController),
                ),
              ),

              const SizedBox(height: 16),

              // News Section
              _buildSection(
                'Notícias e Timeline',
                isDark,
                SizedBox(
                  height: 400,
                  child: WebViewWidget(controller: _newsController),
                ),
              ),

              const SizedBox(height: 16),

              // Market Stats
              _buildSection(
                'Estatísticas de Mercado',
                isDark,
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildStatRow(
                        'Volume 24h',
                        '\$${_formatNumber(widget.crypto.volume)}',
                        isDark,
                      ),
                      Divider(
                        height: 24,
                        color: isDark ? AppColors.darkSeparator : AppColors.separator,
                      ),
                      _buildStatRow(
                        'Máxima 24h',
                        '\$${widget.crypto.high24h.toStringAsFixed(2)}',
                        isDark,
                      ),
                      Divider(
                        height: 24,
                        color: isDark ? AppColors.darkSeparator : AppColors.separator,
                      ),
                      _buildStatRow(
                        'Mínima 24h',
                        '\$${widget.crypto.low24h.toStringAsFixed(2)}',
                        isDark,
                      ),
                      Divider(
                        height: 24,
                        color: isDark ? AppColors.darkSeparator : AppColors.separator,
                      ),
                      _buildStatRow(
                        'Variação 24h',
                        '${widget.crypto.priceChange >= 0 ? '+' : ''}${widget.crypto.priceChange.toStringAsFixed(2)}%',
                        isDark,
                        valueColor: widget.crypto.priceChange >= 0 ? AppColors.success : AppColors.error,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, bool isDark, Widget child) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(AppDesignConfig.cardRadius),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: AppSectionTitle(text: title, fontSize: 17),
          ),
          child,
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, bool isDark, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 15,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: valueColor ?? (isDark ? Colors.white : Colors.black),
            letterSpacing: -0.2,
          ),
        ),
      ],
    );
  }

  String _formatNumber(double number) {
    if (number >= 1000000000) {
      return '${(number / 1000000000).toStringAsFixed(2)}B';
    } else if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(2)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(2)}K';
    }
    return number.toStringAsFixed(2);
  }
}