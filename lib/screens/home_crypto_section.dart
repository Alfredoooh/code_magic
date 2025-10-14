// lib/screens/home_crypto_section.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CryptoData {
  final String symbol;
  final double price;
  final double priceChange;
  final List<double> sparkline;

  CryptoData({
    required this.symbol,
    required this.price,
    required this.priceChange,
    required this.sparkline,
  });

  factory CryptoData.fromBinance(Map<String, dynamic> json) {
    final symbol = json['symbol'].toString().replaceAll('USDT', '');
    final price = double.parse(json['lastPrice'].toString());
    final priceChange = double.parse(json['priceChangePercent'].toString());
    
    List<double> sparkline = [];
    for (int i = 0; i < 20; i++) {
      sparkline.add(price * (1 + (priceChange / 100) * (i / 20)));
    }
    
    return CryptoData(
      symbol: symbol,
      price: price,
      priceChange: priceChange,
      sparkline: sparkline,
    );
  }
}

class HomeCryptoSection extends StatelessWidget {
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
              Text(
                'Criptomoedas',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? CupertinoColors.white : CupertinoColors.black,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16),
        loadingCrypto
            ? Center(child: CupertinoActivityIndicator())
            : Column(
                children: [
                  Container(
                    height: 90,
                    child: PageView.builder(
                      controller: pageController,
                      physics: BouncingScrollPhysics(),
                      itemCount: cryptoData.length + 1,
                      itemBuilder: (context, index) {
                        if (index == cryptoData.length) {
                          return Padding(
                            padding: EdgeInsets.only(right: 12),
                            child: _buildViewMoreCard(),
                          );
                        }
                        final crypto = cryptoData[index];
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
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1A1A1A) : CupertinoColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: isDark ? Color(0xFF0E0E0E) : CupertinoColors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: iconUrl.isNotEmpty
                  ? Image.network(
                      iconUrl,
                      width: 50,
                      height: 50,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stack) => Icon(
                        CupertinoIcons.money_dollar_circle_fill,
                        color: Color(0xFFFF444F),
                        size: 26,
                      ),
                    )
                  : Icon(
                      CupertinoIcons.money_dollar_circle_fill,
                      color: Color(0xFFFF444F),
                      size: 26,
                    ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  crypto.symbol,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? CupertinoColors.white : CupertinoColors.black,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '\$${crypto.price.toStringAsFixed(crypto.price < 1 ? 4 : 2)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: CupertinoColors.systemGrey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isPositive ? '+' : ''}${crypto.priceChange.toStringAsFixed(2)}%',
            style: TextStyle(
              color: isPositive ? CupertinoColors.systemGreen : CupertinoColors.systemRed,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewMoreCard() {
    return GestureDetector(
      onTap: onViewMore,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Color(0xFF1A1A1A) : CupertinoColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: CupertinoColors.activeBlue.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.arrow_right_circle_fill,
                color: CupertinoColors.activeBlue,
                size: 32,
              ),
              SizedBox(height: 8),
              Text(
                'Ver mais',
                style: TextStyle(
                  color: CupertinoColors.activeBlue,
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
}


  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        cryptoData.length + 1,
        (index) => Container(
          width: currentPage == index ? 24 : 8,
          height: 8,
          margin: EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: currentPage == index
                ? CupertinoColors.activeBlue
                : CupertinoColors.systemGrey.withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }