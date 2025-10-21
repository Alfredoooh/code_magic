class MarketData {
  static const Map<String, Map<String, dynamic>> markets = {
    // Volatility Indices
    'R_10': {
      'name': 'Volatility 10 Index',
      'category': 'Synthetic',
      'description': '10% volatilidade, 1 tick por segundo',
      'minStake': 0.35,
      'payout': 1.95,
    },
    'R_25': {
      'name': 'Volatility 25 Index',
      'category': 'Synthetic',
      'description': '25% volatilidade, 1 tick por segundo',
      'minStake': 0.35,
      'payout': 1.95,
    },
    'R_50': {
      'name': 'Volatility 50 Index',
      'category': 'Synthetic',
      'description': '50% volatilidade, 1 tick por segundo',
      'minStake': 0.35,
      'payout': 1.95,
    },
    'R_75': {
      'name': 'Volatility 75 Index',
      'category': 'Synthetic',
      'description': '75% volatilidade, 1 tick por segundo',
      'minStake': 0.35,
      'payout': 1.95,
    },
    'R_100': {
      'name': 'Volatility 100 Index',
      'category': 'Synthetic',
      'description': '100% volatilidade, 1 tick por segundo',
      'minStake': 0.35,
      'payout': 1.95,
    },
    '1HZ10V': {
      'name': 'Volatility 10 (1s) Index',
      'category': 'Synthetic',
      'description': 'Ultra rápido - 10% volatilidade',
      'minStake': 0.35,
      'payout': 1.95,
    },
    '1HZ25V': {
      'name': 'Volatility 25 (1s) Index',
      'category': 'Synthetic',
      'description': 'Ultra rápido - 25% volatilidade',
      'minStake': 0.35,
      'payout': 1.95,
    },
    '1HZ50V': {
      'name': 'Volatility 50 (1s) Index',
      'category': 'Synthetic',
      'description': 'Ultra rápido - 50% volatilidade',
      'minStake': 0.35,
      'payout': 1.95,
    },
    '1HZ75V': {
      'name': 'Volatility 75 (1s) Index',
      'category': 'Synthetic',
      'description': 'Ultra rápido - 75% volatilidade',
      'minStake': 0.35,
      'payout': 1.95,
    },
    '1HZ100V': {
      'name': 'Volatility 100 (1s) Index',
      'category': 'Synthetic',
      'description': 'Ultra rápido - 100% volatilidade',
      'minStake': 0.35,
      'payout': 1.95,
    },
    
    // Crash/Boom Indices
    'BOOM1000': {
      'name': 'Boom 1000 Index',
      'category': 'Crash/Boom',
      'description': 'Spike de 1000% em média',
      'minStake': 0.35,
      'payout': 1.95,
    },
    'BOOM500': {
      'name': 'Boom 500 Index',
      'category': 'Crash/Boom',
      'description': 'Spike de 500% em média',
      'minStake': 0.35,
      'payout': 1.95,
    },
    'BOOM300': {
      'name': 'Boom 300 Index',
      'category': 'Crash/Boom',
      'description': 'Spike de 300% em média',
      'minStake': 0.35,
      'payout': 1.95,
    },
    'CRASH1000': {
      'name': 'Crash 1000 Index',
      'category': 'Crash/Boom',
      'description': 'Drop de 1000% em média',
      'minStake': 0.35,
      'payout': 1.95,
    },
    'CRASH500': {
      'name': 'Crash 500 Index',
      'category': 'Crash/Boom',
      'description': 'Drop de 500% em média',
      'minStake': 0.35,
      'payout': 1.95,
    },
    'CRASH300': {
      'name': 'Crash 300 Index',
      'category': 'Crash/Boom',
      'description': 'Drop de 300% em média',
      'minStake': 0.35,
      'payout': 1.95,
    },
    
    // Step Indices
    'stpRNG': {
      'name': 'Step Index',
      'category': 'Step',
      'description': 'Movimentos em steps definidos',
      'minStake': 0.35,
      'payout': 1.95,
    },
    
    // Jump Indices
    'JD10': {
      'name': 'Jump 10 Index',
      'category': 'Jump',
      'description': '10% jump rate',
      'minStake': 0.35,
      'payout': 1.95,
    },
    'JD25': {
      'name': 'Jump 25 Index',
      'category': 'Jump',
      'description': '25% jump rate',
      'minStake': 0.35,
      'payout': 1.95,
    },
    'JD50': {
      'name': 'Jump 50 Index',
      'category': 'Jump',
      'description': '50% jump rate',
      'minStake': 0.35,
      'payout': 1.95,
    },
    'JD75': {
      'name': 'Jump 75 Index',
      'category': 'Jump',
      'description': '75% jump rate',
      'minStake': 0.35,
      'payout': 1.95,
    },
    'JD100': {
      'name': 'Jump 100 Index',
      'category': 'Jump',
      'description': '100% jump rate',
      'minStake': 0.35,
      'payout': 1.95,
    },
    
    // Range Break
    'RDBEAR': {
      'name': 'Range Break Bear',
      'category': 'Range',
      'description': 'Break bearish patterns',
      'minStake': 0.35,
      'payout': 1.95,
    },
    'RDBULL': {
      'name': 'Range Break Bull',
      'category': 'Range',
      'description': 'Break bullish patterns',
      'minStake': 0.35,
      'payout': 1.95,
    },
    
    // Forex Majors
    'frxEURUSD': {
      'name': 'EUR/USD',
      'category': 'Forex',
      'description': 'Euro vs US Dollar',
      'minStake': 0.35,
      'payout': 1.85,
    },
    'frxGBPUSD': {
      'name': 'GBP/USD',
      'category': 'Forex',
      'description': 'British Pound vs US Dollar',
      'minStake': 0.35,
      'payout': 1.85,
    },
    'frxUSDJPY': {
      'name': 'USD/JPY',
      'category': 'Forex',
      'description': 'US Dollar vs Japanese Yen',
      'minStake': 0.35,
      'payout': 1.85,
    },
    'frxAUDUSD': {
      'name': 'AUD/USD',
      'category': 'Forex',
      'description': 'Australian Dollar vs US Dollar',
      'minStake': 0.35,
      'payout': 1.85,
    },
    'frxUSDCHF': {
      'name': 'USD/CHF',
      'category': 'Forex',
      'description': 'US Dollar vs Swiss Franc',
      'minStake': 0.35,
      'payout': 1.85,
    },
    'frxUSDCAD': {
      'name': 'USD/CAD',
      'category': 'Forex',
      'description': 'US Dollar vs Canadian Dollar',
      'minStake': 0.35,
      'payout': 1.85,
    },
    'frxNZDUSD': {
      'name': 'NZD/USD',
      'category': 'Forex',
      'description': 'New Zealand Dollar vs US Dollar',
      'minStake': 0.35,
      'payout': 1.85,
    },
    'frxEURGBP': {
      'name': 'EUR/GBP',
      'category': 'Forex',
      'description': 'Euro vs British Pound',
      'minStake': 0.35,
      'payout': 1.85,
    },
    'frxEURJPY': {
      'name': 'EUR/JPY',
      'category': 'Forex',
      'description': 'Euro vs Japanese Yen',
      'minStake': 0.35,
      'payout': 1.85,
    },
    'frxGBPJPY': {
      'name': 'GBP/JPY',
      'category': 'Forex',
      'description': 'British Pound vs Japanese Yen',
      'minStake': 0.35,
      'payout': 1.85,
    },
    
    // Commodities
    'frxXAUUSD': {
      'name': 'Gold/USD',
      'category': 'Commodities',
      'description': 'Gold spot price',
      'minStake': 0.35,
      'payout': 1.90,
    },
    'frxXAGUSD': {
      'name': 'Silver/USD',
      'category': 'Commodities',
      'description': 'Silver spot price',
      'minStake': 0.35,
      'payout': 1.90,
    },
    'frxBROUSD': {
      'name': 'Oil/USD',
      'category': 'Commodities',
      'description': 'Brent Crude Oil',
      'minStake': 0.35,
      'payout': 1.90,
    },
    
    // Crypto
    'cryBTCUSD': {
      'name': 'Bitcoin',
      'category': 'Cryptocurrency',
      'description': 'BTC/USD pair',
      'minStake': 0.35,
      'payout': 1.90,
    },
    'cryETHUSD': {
      'name': 'Ethereum',
      'category': 'Cryptocurrency',
      'description': 'ETH/USD pair',
      'minStake': 0.35,
      'payout': 1.90,
    },
    'cryLTCUSD': {
      'name': 'Litecoin',
      'category': 'Cryptocurrency',
      'description': 'LTC/USD pair',
      'minStake': 0.35,
      'payout': 1.90,
    },
    'cryBCHUSD': {
      'name': 'Bitcoin Cash',
      'category': 'Cryptocurrency',
      'description': 'BCH/USD pair',
      'minStake': 0.35,
      'payout': 1.90,
    },
    
    // Stock Indices
    'OTC_AEX': {
      'name': 'Netherlands 25',
      'category': 'Indices',
      'description': 'Dutch stock index',
      'minStake': 0.35,
      'payout': 1.85,
    },
    'OTC_AS51': {
      'name': 'Australia 200',
      'category': 'Indices',
      'description': 'Australian stock index',
      'minStake': 0.35,
      'payout': 1.85,
    },
    'OTC_DJI': {
      'name': 'Wall Street 30',
      'category': 'Indices',
      'description': 'Dow Jones Industrial Average',
      'minStake': 0.35,
      'payout': 1.85,
    },
    'OTC_FCHI': {
      'name': 'France 40',
      'category': 'Indices',
      'description': 'CAC 40 index',
      'minStake': 0.35,
      'payout': 1.85,
    },
    'OTC_FTSE': {
      'name': 'UK 100',
      'category': 'Indices',
      'description': 'FTSE 100 index',
      'minStake': 0.35,
      'payout': 1.85,
    },
    'OTC_GDAXI': {
      'name': 'Germany 40',
      'category': 'Indices',
      'description': 'DAX index',
      'minStake': 0.35,
      'payout': 1.85,
    },
    'OTC_HSI': {
      'name': 'Hong Kong 50',
      'category': 'Indices',
      'description': 'Hang Seng Index',
      'minStake': 0.35,
      'payout': 1.85,
    },
    'OTC_N225': {
      'name': 'Japan 225',
      'category': 'Indices',
      'description': 'Nikkei 225',
      'minStake': 0.35,
      'payout': 1.85,
    },
    'OTC_SPC': {
      'name': 'US 500',
      'category': 'Indices',
      'description': 'S&P 500',
      'minStake': 0.35,
      'payout': 1.85,
    },
    'OTC_SSMI': {
      'name': 'Swiss 20',
      'category': 'Indices',
      'description': 'Swiss Market Index',
      'minStake': 0.35,
      'payout': 1.85,
    },
  };
  
  static List<String> getMarketsByCategory(String category) {
    return markets.entries
        .where((e) => e.value['category'] == category)
        .map((e) => e.key)
        .toList();
  }
  
  static List<String> getAllCategories() {
    return markets.values
        .map((m) => m['category'] as String)
        .toSet()
        .toList()
      ..sort();
  }
  
  static Map<String, dynamic>? getMarketInfo(String marketId) {
    return markets[marketId];
  }
}