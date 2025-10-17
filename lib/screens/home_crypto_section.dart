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
            ? Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CupertinoActivityIndicator(),
                ),
              )
            : Column(
                children: [
                  Container(
                    height: 100,
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
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1C1C1E) : CupertinoColors.white,
        borderRadius: BorderRadius.circular(24), // Bordas mais curvadas
        border: Border.all(
          color: isDark 
              ? Color(0xFF2C2C2E) 
              : CupertinoColors.systemGrey6,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Ícone oficial da criptomoeda
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: isDark ? Color(0xFF0E0E0E) : Color(0xFFF8F8F8),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(
                color: isDark 
                    ? Color(0xFF2C2C2E) 
                    : CupertinoColors.systemGrey5,
                width: 1,
              ),
            ),
            child: Center(
              child: iconUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(26),
                      child: Image.network(
                        iconUrl,
                        width: 36,
                        height: 36,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return CupertinoActivityIndicator();
                        },
                        errorBuilder: (context, error, stack) => Icon(
                          CupertinoIcons.money_dollar_circle_fill,
                          color: Color(0xFFFF444F),
                          size: 28,
                        ),
                      ),
                    )
                  : Icon(
                      CupertinoIcons.money_dollar_circle_fill,
                      color: Color(0xFFFF444F),
                      size: 28,
                    ),
            ),
          ),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  crypto.symbol,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: isDark ? CupertinoColors.white : CupertinoColors.black,
                    letterSpacing: 0.3,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '\$${crypto.price.toStringAsFixed(crypto.price < 1 ? 6 : 2)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: CupertinoColors.systemGrey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: (isPositive 
                  ? CupertinoColors.systemGreen 
                  : CupertinoColors.systemRed).withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${isPositive ? '+' : ''}${crypto.priceChange.toStringAsFixed(2)}%',
              style: TextStyle(
                color: isPositive 
                    ? CupertinoColors.systemGreen 
                    : CupertinoColors.systemRed,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
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
          gradient: LinearGradient(
            colors: [
              CupertinoColors.activeBlue.withOpacity(0.1),
              CupertinoColors.activeBlue.withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24), // Bordas mais curvadas
          border: Border.all(
            color: CupertinoColors.activeBlue.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.activeBlue.withOpacity(0.1),
              blurRadius: 12,
              offset: Offset(0, 4),
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
                size: 36,
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

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        cryptoData.length + 1,
        (index) => AnimatedContainer(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
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
}