// lib/screens/home_crypto_section.dart
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../widgets/app_ui_components.dart';

class CryptoData {
  final String symbol;
  final String name;
  final double price;
  final double priceChange;
  final double volume24h;
  final List<double> sparkline;

  CryptoData({
    required this.symbol,
    required this.name,
    required this.price,
    required this.priceChange,
    required this.volume24h,
    required this.sparkline,
  });

  factory CryptoData.fromBinance(Map<String, dynamic> json) {
    final symbol = json['symbol'].toString().replaceAll('USDT', '');
    final price = double.parse(json['lastPrice'].toString());
    final priceChange = double.parse(json['priceChangePercent'].toString());
    final volume = double.parse(json['quoteVolume'].toString());

    List<double> sparkline = [];
    for (int i = 0; i < 20; i++) {
      sparkline.add(price * (1 + (priceChange / 100) * (i / 20)));
    }

    return CryptoData(
      symbol: symbol,
      name: _getCryptoName(symbol),
      price: price,
      priceChange: priceChange,
      volume24h: volume,
      sparkline: sparkline,
    );
  }

  static String _getCryptoName(String symbol) {
    final names = {
      'BTC': 'Bitcoin',
      'ETH': 'Ethereum',
      'BNB': 'BNB',
      'SOL': 'Solana',
      'XRP': 'XRP',
      'ADA': 'Cardano',
      'DOGE': 'Dogecoin',
      'MATIC': 'Polygon',
      'DOT': 'Polkadot',
      'AVAX': 'Avalanche',
      'LINK': 'Chainlink',
      'UNI': 'Uniswap',
      'LTC': 'Litecoin',
      'ATOM': 'Cosmos',
      'TRX': 'Tron',
      'SHIB': 'Shiba Inu',
      'APT': 'Aptos',
      'ARB': 'Arbitrum',
      'OP': 'Optimism',
      'FTM': 'Fantom',
    };
    return names[symbol] ?? symbol;
  }
}

class HomeCryptoSection extends StatefulWidget {
  final List<CryptoData> cryptoData;
  final bool loadingCrypto;
  final bool isDark;
  final PageController pageController;
  final int currentPage;
  final VoidCallback onViewMore;

  const HomeCryptoSection({
    required this.cryptoData,
    required this.loadingCrypto,
    required this.isDark,
    required this.pageController,
    required this.currentPage,
    required this.onViewMore,
    Key? key,
  }) : super(key: key);

  @override
  _HomeCryptoSectionState createState() => _HomeCryptoSectionState();
}

class _HomeCryptoSectionState extends State<HomeCryptoSection> {
  Timer? _updateTimer;
  Map<String, double> _previousPrices = {};
  Map<String, bool> _priceIncreasing = {};

  @override
  void initState() {
    super.initState();
    _startRealTimeUpdates();
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  void _startRealTimeUpdates() {
    _updateTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {
          for (var crypto in widget.cryptoData) {
            if (_previousPrices.containsKey(crypto.symbol)) {
              _priceIncreasing[crypto.symbol] = 
                  crypto.price > _previousPrices[crypto.symbol]!;
            }
            _previousPrices[crypto.symbol] = crypto.price;
          }
        });
      }
    });
  }

  // Ícones oficiais em PNG de alta qualidade
  static final Map<String, String> cryptoIcons = {
    'BTC': 'https://cryptologos.cc/logos/bitcoin-btc-logo.png',
    'ETH': 'https://cryptologos.cc/logos/ethereum-eth-logo.png',
    'BNB': 'https://cryptologos.cc/logos/bnb-bnb-logo.png',
    'SOL': 'https://cryptologos.cc/logos/solana-sol-logo.png',
    'XRP': 'https://cryptologos.cc/logos/xrp-xrp-logo.png',
    'ADA': 'https://cryptologos.cc/logos/cardano-ada-logo.png',
    'DOGE': 'https://cryptologos.cc/logos/dogecoin-doge-logo.png',
    'MATIC': 'https://cryptologos.cc/logos/polygon-matic-logo.png',
    'DOT': 'https://cryptologos.cc/logos/polkadot-new-dot-logo.png',
    'AVAX': 'https://cryptologos.cc/logos/avalanche-avax-logo.png',
    'LINK': 'https://cryptologos.cc/logos/chainlink-link-logo.png',
    'UNI': 'https://cryptologos.cc/logos/uniswap-uni-logo.png',
    'LTC': 'https://cryptologos.cc/logos/litecoin-ltc-logo.png',
    'ATOM': 'https://cryptologos.cc/logos/cosmos-atom-logo.png',
    'TRX': 'https://cryptologos.cc/logos/tron-trx-logo.png',
    'USDT': 'https://cryptologos.cc/logos/tether-usdt-logo.png',
    'USDC': 'https://cryptologos.cc/logos/usd-coin-usdc-logo.png',
    'SHIB': 'https://cryptologos.cc/logos/shiba-inu-shib-logo.png',
    'APT': 'https://cryptologos.cc/logos/aptos-apt-logo.png',
    'ARB': 'https://cryptologos.cc/logos/arbitrum-arb-logo.png',
    'OP': 'https://cryptologos.cc/logos/optimism-ethereum-op-logo.png',
    'FTM': 'https://cryptologos.cc/logos/fantom-ftm-logo.png',
    'NEAR': 'https://cryptologos.cc/logos/near-protocol-near-logo.png',
    'FIL': 'https://cryptologos.cc/logos/filecoin-fil-logo.png',
    'AAVE': 'https://cryptologos.cc/logos/aave-aave-logo.png',
    'ALGO': 'https://cryptologos.cc/logos/algorand-algo-logo.png',
    'VET': 'https://cryptologos.cc/logos/vechain-vet-logo.png',
    'ICP': 'https://cryptologos.cc/logos/internet-computer-icp-logo.png',
    'CRO': 'https://cryptologos.cc/logos/cronos-cro-logo.png',
    'QNT': 'https://cryptologos.cc/logos/quant-qnt-logo.png',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppSectionTitle(text: 'Criptomoedas', fontSize: 24),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'AO VIVO',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.green,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16),
        widget.loadingCrypto
            ? Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            : Column(
                children: [
                  Container(
                    height: 120,
                    child: PageView.builder(
                      controller: widget.pageController,
                      physics: BouncingScrollPhysics(),
                      itemCount: widget.cryptoData.length + 1,
                      itemBuilder: (context, index) {
                        if (index == widget.cryptoData.length) {
                          return Padding(
                            padding: EdgeInsets.only(right: 12),
                            child: _buildViewMoreCard(),
                          );
                        }
                        final crypto = widget.cryptoData[index];
                        final iconUrl = cryptoIcons[crypto.symbol] ?? '';
                        return Padding(
                          padding: EdgeInsets.only(right: 12),
                          child: _buildCryptoCard(crypto, iconUrl),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 12),
                  _buildPageIndicator(),
                ],
              ),
      ],
    );
  }

  Widget _buildCryptoCard(CryptoData crypto, String iconUrl) {
    final isPositive = crypto.priceChange >= 0;
    final isPriceIncreasing = _priceIncreasing[crypto.symbol] ?? true;

    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      child: AppCard(
        padding: EdgeInsets.all(16),
        borderRadius: 24,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Ícone oficial da criptomoeda com par USDT
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: widget.isDark ? Color(0xFF0E0E0E) : Color(0xFFF8F8F8),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: widget.isDark 
                              ? Color(0xFF2C2C2E) 
                              : Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: iconUrl.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: Image.network(
                                  iconUrl,
                                  width: 32,
                                  height: 32,
                                  fit: BoxFit.contain,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.primary,
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stack) => Icon(
                                    Icons.currency_bitcoin,
                                    color: AppColors.primary,
                                    size: 24,
                                  ),
                                ),
                              )
                            : Icon(
                                Icons.currency_bitcoin,
                                color: AppColors.primary,
                                size: 24,
                              ),
                      ),
                    ),
                    // Par USDT (Tether)
                    Positioned(
                      right: -4,
                      bottom: -4,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: widget.isDark ? AppColors.darkCard : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: widget.isDark ? AppColors.darkBackground : Colors.white,
                            width: 2,
                          ),
                        ),
                        child: ClipOval(
                          child: Image.network(
                            cryptoIcons['USDT']!,
                            width: 16,
                            height: 16,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stack) => Icon(
                              Icons.attach_money,
                              color: Colors.green,
                              size: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            crypto.symbol,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: widget.isDark ? Colors.white : Colors.black,
                              letterSpacing: 0.3,
                            ),
                          ),
                          Text(
                            '/USDT',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey,
                            ),
                          ),
                          SizedBox(width: 6),
                          // Indicador de movimento em tempo real
                          AnimatedContainer(
                            duration: Duration(milliseconds: 500),
                            child: Icon(
                              isPriceIncreasing 
                                  ? Icons.trending_up 
                                  : Icons.trending_down,
                              size: 14,
                              color: isPriceIncreasing 
                                  ? Colors.green 
                                  : Colors.red,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 2),
                      Text(
                        crypto.name,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: (isPositive ? Colors.green : Colors.red)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isPositive 
                            ? Icons.arrow_upward 
                            : Icons.arrow_downward,
                        size: 12,
                        color: isPositive ? Colors.green : Colors.red,
                      ),
                      SizedBox(width: 4),
                      Text(
                        '${crypto.priceChange.abs().toStringAsFixed(2)}%',
                        style: TextStyle(
                          color: isPositive ? Colors.green : Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Preço',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '\$${crypto.price.toStringAsFixed(crypto.price < 1 ? 6 : 2)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: widget.isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Volume 24h',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      '\$${(crypto.volume24h / 1000000).toStringAsFixed(1)}M',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: widget.isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewMoreCard() {
    return GestureDetector(
      onTap: widget.onViewMore,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.blue.withOpacity(0.1),
              Colors.blue.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Colors.blue.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.arrow_forward_rounded,
                color: Colors.blue,
                size: 36,
              ),
              SizedBox(height: 8),
              Text(
                'Ver mais',
                style: TextStyle(
                  color: Colors.blue,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        widget.cryptoData.length + 1,
        (index) => AnimatedContainer(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          width: widget.currentPage == index ? 24 : 8,
          height: 8,
          margin: EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: widget.currentPage == index
                ? AppColors.primary
                : Colors.grey.withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}