import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'item_detail.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({Key? key}) : super(key: key);

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
  List<Map<String, dynamic>> _items = [];
  Map<String, double> _realtimePrices = {};
  Map<String, double> _priceChanges24h = {};
  bool _isLoading = true;
  String? _error;
  Timer? _priceUpdateTimer;

  final String _dataUrl = 'https://alfredoooh.github.io/database/data/market_data.json';

  @override
  void initState() {
    super.initState();
    _fetchMarketData();
    _startPriceUpdates();
  }

  @override
  void dispose() {
    _priceUpdateTimer?.cancel();
    super.dispose();
  }

  void _startPriceUpdates() {
    _priceUpdateTimer?.cancel();
    _priceUpdateTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (_items.isNotEmpty) {
        _fetchBinancePrices();
      }
    });
  }

  Future<void> _fetchMarketData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final resp = await http.get(Uri.parse(_dataUrl));
      if (resp.statusCode != 200) {
        throw Exception('HTTP ${resp.statusCode}');
      }
      final Map<String, dynamic> json = jsonDecode(resp.body);
      final items = (json['items'] as List<dynamic>? ?? [])
          .map((e) => e as Map<String, dynamic>)
          .toList();
      
      if (mounted) {
        setState(() {
          _items = items;
          _isLoading = false;
        });
      }

      await _fetchBinancePrices();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Erro ao carregar dados: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchBinancePrices() async {
    if (_items.isEmpty) return;

    try {
      final symbols = _items
          .map((item) {
            final symbol = item['symbol'] as String? ?? '';
            if (symbol.isNotEmpty && !symbol.endsWith('USDT')) {
              return '${symbol}USDT';
            }
            return symbol;
          })
          .where((s) => s.isNotEmpty)
          .toSet()
          .toList();

      if (symbols.isEmpty) return;

      final symbolsParam = symbols.map((s) => '"$s"').join(',');
      final url = 'https://api.binance.com/api/v3/ticker/24hr?symbols=[$symbolsParam]';
      
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 5),
        onTimeout: () => throw TimeoutException('Timeout'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        
        final newPrices = <String, double>{};
        final newChanges = <String, double>{};
        
        for (var ticker in data) {
          final symbol = (ticker['symbol'] as String).replaceAll('USDT', '');
          final price = double.tryParse(ticker['lastPrice'].toString());
          final priceChange = double.tryParse(ticker['priceChangePercent'].toString());
          
          if (price != null) {
            newPrices[symbol] = price;
          }
          if (priceChange != null) {
            newChanges[symbol] = priceChange;
          }
        }

        if (mounted) {
          setState(() {
            _realtimePrices = newPrices;
            _priceChanges24h = newChanges;
          });
        }
      }
    } catch (e) {
      // Falha silenciosa - mantém preços anteriores
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFF000000),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: const Color(0xFF000000),
        border: null,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.pop(context),
          child: const Icon(
            CupertinoIcons.back,
            color: Color(0xFF007AFF),
            size: 24,
          ),
        ),
        middle: const Text(
          'Market',
          style: TextStyle(
            color: Color(0xFFFFFFFF),
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
            fontFamily: 'SF Pro Display',
          ),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            _fetchMarketData();
            _fetchBinancePrices();
          },
          child: const Icon(
            CupertinoIcons.refresh,
            color: Color(0xFF007AFF),
            size: 22,
          ),
        ),
      ),
      child: SafeArea(
        child: _isLoading
            ? const Center(
                child: CupertinoActivityIndicator(
                  radius: 20,
                  color: Color(0xFF007AFF),
                ),
              )
            : _error != null
                ? _buildError()
                : _buildList(),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Color(0xFF1C1C1E),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                CupertinoIcons.exclamationmark_triangle_fill,
                size: 48,
                color: Color(0xFFFF3B30),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Erro ao carregar',
              style: TextStyle(
                color: Color(0xFFFFFFFF),
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                fontFamily: 'SF Pro Display',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Ocorreu um erro desconhecido',
              style: const TextStyle(
                color: Color(0xFF8E8E93),
                fontSize: 15,
                height: 1.4,
                fontFamily: 'SF Pro Text',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            CupertinoButton(
              color: const Color(0xFF007AFF),
              borderRadius: BorderRadius.circular(12),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              onPressed: _fetchMarketData,
              child: const Text(
                'Tentar novamente',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                  fontFamily: 'SF Pro Text',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    if (_items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                CupertinoIcons.chart_bar_square,
                size: 48,
                color: Color(0xFF8E8E93),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Nenhum item disponível',
              style: TextStyle(
                color: Color(0xFFFFFFFF),
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3,
                fontFamily: 'SF Pro Display',
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tente atualizar a página',
              style: TextStyle(
                color: Color(0xFF8E8E93),
                fontSize: 15,
                fontFamily: 'SF Pro Text',
              ),
            ),
          ],
        ),
      );
    }

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1C1C1E),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFF34C759),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Ao vivo',
                        style: TextStyle(
                          color: Color(0xFF34C759),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.2,
                          fontFamily: 'SF Pro Text',
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  '${_items.length} ativos',
                  style: const TextStyle(
                    color: Color(0xFF8E8E93),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'SF Pro Text',
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = _items[index];
                final iconUrl = (item['icon'] ?? '') as String;
                final name = (item['name'] ?? '-') as String;
                final symbol = (item['symbol'] ?? item['id'] ?? '-') as String;
                final symbolShort = (item['symbolShort'] ?? '') as String;
                final link = (item['link'] ?? item['url'] ?? '') as String?;

                final realtimePrice = _realtimePrices[symbol];
                final priceChange = _priceChanges24h[symbol];
                final isPositive = priceChange != null && priceChange > 0;
                final isNegative = priceChange != null && priceChange < 0;

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (_) => ItemDetailScreen(
                          symbol: symbol,
                          display: symbolShort.isNotEmpty ? symbolShort : symbol,
                          name: name,
                          iconUrl: iconUrl,
                          latestPrice: realtimePrice ?? 0.0,
                          sparkline: null,
                          externalLink: link,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C1E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF2C2C2E),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              iconUrl,
                              width: 52,
                              height: 52,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2C2C2E),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  CupertinoIcons.chart_bar_alt_fill,
                                  color: Color(0xFF8E8E93),
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  color: Color(0xFFFFFFFF),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 17,
                                  letterSpacing: -0.4,
                                  height: 1.2,
                                  fontFamily: 'SF Pro Display',
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2C2C2E),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      symbolShort.isNotEmpty ? symbolShort : symbol,
                                      style: const TextStyle(
                                        color: Color(0xFF8E8E93),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 0.2,
                                        fontFamily: 'SF Pro Text',
                                      ),
                                    ),
                                  ),
                                  if (realtimePrice != null) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF34C759),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Text(
                                      'Live',
                                      style: TextStyle(
                                        color: Color(0xFF34C759),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        fontFamily: 'SF Pro Text',
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              realtimePrice != null 
                                  ? '\$${realtimePrice >= 1 ? realtimePrice.toStringAsFixed(2) : realtimePrice.toStringAsFixed(6)}'
                                  : '--',
                              style: const TextStyle(
                                color: Color(0xFFFFFFFF),
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                                letterSpacing: -0.5,
                                height: 1.2,
                                fontFamily: 'SF Pro Display',
                              ),
                            ),
                            const SizedBox(height: 6),
                            if (priceChange != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isPositive
                                      ? const Color(0xFF34C759).withOpacity(0.15)
                                      : isNegative
                                          ? const Color(0xFFFF3B30).withOpacity(0.15)
                                          : const Color(0xFF8E8E93).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isPositive
                                          ? CupertinoIcons.arrow_up
                                          : isNegative
                                              ? CupertinoIcons.arrow_down
                                              : CupertinoIcons.minus,
                                      size: 11,
                                      color: isPositive
                                          ? const Color(0xFF34C759)
                                          : isNegative
                                              ? const Color(0xFFFF3B30)
                                              : const Color(0xFF8E8E93),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${priceChange.abs().toStringAsFixed(2)}%',
                                      style: TextStyle(
                                        color: isPositive
                                            ? const Color(0xFF34C759)
                                            : isNegative
                                                ? const Color(0xFFFF3B30)
                                                : const Color(0xFF8E8E93),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -0.2,
                                        fontFamily: 'SF Pro Text',
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF007AFF).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'USD',
                                  style: TextStyle(
                                    color: Color(0xFF007AFF),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3,
                                    fontFamily: 'SF Pro Text',
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          CupertinoIcons.chevron_right,
                          color: Color(0xFF3A3A3C),
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                );
              },
              childCount: _items.length,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }
}
