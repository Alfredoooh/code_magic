// trade_screen.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:audioplayers/audioplayers.dart';
import 'trading_logic.dart';
import 'ml_predictor.dart';

class TradeScreen extends StatefulWidget {
  final String token;
  final String? initialMarket;

  const TradeScreen({
    Key? key,
    required this.token,
    this.initialMarket,
  }) : super(key: key);

  @override
  State createState() => _TradeScreenState();
}

class _TradeScreenState extends State<TradeScreen> with TickerProviderStateMixin {
  late TradingLogic _tradingLogic;
  late MLPredictor _mlPredictor;
  WebViewController? _webViewController;

  String _selectedMarket = 'R_100';
  String _selectedTradeType = 'rise_fall';
  double _currentPrice = 0.0;
  double _priceChange = 0.0;
  double _stake = 10.0;
  bool _isTrading = false;
  bool _soundEnabled = false;
  bool _chartExpanded = false;
  String _chartType = 'candlestick';
  int _tickPrediction = 5;

  // Accumulator state
  bool _hasActiveAccumulator = false;
  String? _activeAccumulatorId;

  // Duration settings
  String _durationType = 't'; // t=ticks, s=seconds, m=minutes, h=hours, d=days
  int _durationValue = 5;

  // Entry price marker
  double? _entryPrice;
  String? _entryDirection;

  // Multipliers
  int _multiplier = 5; // e.g., 5x by default
  double _multiplierStopLossPercent = 50.0; // optional param for UI
  double _multiplierTakeProfitPercent = 0.0; // optional param for UI

  final AudioPlayer _audioPlayer = AudioPlayer();

  // Expanded markets (organized by category)
  final Map<String, String> _allMarkets = {
    // Volatility Indices (Synthetic)
    'R_10': 'Volatility 10 (R_10)',
    'R_25': 'Volatility 25 (R_25)',
    'R_50': 'Volatility 50 (R_50)',
    'R_75': 'Volatility 75 (R_75)',
    'R_100': 'Volatility 100 (R_100)',
    // 1-second variations (if available)
    '1HZ10V': 'Vol 10 (1s)',
    '1HZ25V': 'Vol 25 (1s)',
    '1HZ50V': 'Vol 50 (1s)',
    '1HZ75V': 'Vol 75 (1s)',
    '1HZ100V': 'Vol 100 (1s)',

    // Boom/Crash (Synthetic)
    'BOOM300N': 'Boom 300',
    'BOOM500': 'Boom 500',
    'CRASH300N': 'Crash 300',
    'CRASH500': 'Crash 500',

    // Forex
    'EURUSD': 'Forex EUR/USD',
    'GBPUSD': 'Forex GBP/USD',
    'USDJPY': 'Forex USD/JPY',
    'AUDUSD': 'Forex AUD/USD',
    'USDCAD': 'Forex USD/CAD',
    'USDCHF': 'Forex USD/CHF',

    // Crypto (CFDs / synthetic)
    'BTCUSD': 'Bitcoin (BTC/USD)',
    'ETHUSD': 'Ethereum (ETH/USD)',
    'LTCUSD': 'Litecoin (LTC/USD)',
    'XRPUSD': 'Ripple (XRP/USD)',

    // Major indices
    'SP500': 'US 500 (S&P 500)',
    'NAS100': 'US 100 (Nasdaq)',
    'DE30': 'Germany 30 (DAX)',
    'UK100': 'UK 100 (FTSE)',
    'JP225': 'Japan 225 (Nikkei)',

    // Commodities
    'GOLD': 'Gold (XAU/USD)',
    'SILVER': 'Silver (XAG/USD)',
    'OIL': 'Crude Oil (Brent)',

    // Stocks (representative)
    'AAPL': 'Apple (AAPL)',
    'TSLA': 'Tesla (TSLA)',
    'AMZN': 'Amazon (AMZN)',

    // Synthetic indexes long-term / 24h etc (examples)
    'SYNTHETIC_10': 'Synthetic 10 Index',
    'SYNTHETIC_25': 'Synthetic 25 Index',
    'SYNTHETIC_50': 'Synthetic 50 Index',

    // Multipliers demo markets (same names; kept for discoverability)
    'MULT_BTCUSD': 'Multiplier BTC/USD (alias)',
    'MULT_EURUSD': 'Multiplier EUR/USD (alias)',
  };

  final List<Map<String, dynamic>> _tradeTypes = [
    {'id': 'rise_fall', 'label': 'Rise/Fall', 'icon': Icons.trending_up_rounded},
    {'id': 'higher_lower', 'label': 'Higher/Lower', 'icon': Icons.compare_arrows_rounded},
    {'id': 'turbos', 'label': 'Turbos', 'icon': Icons.rocket_launch_rounded},
    {'id': 'accumulators', 'label': 'Accumulators', 'icon': Icons.layers_rounded},
    {'id': 'multipliers', 'label': 'Multipliers', 'icon': Icons.auto_graph}, // nova opção
  ];

  final List<Map<String, dynamic>> _tickTradeTypes = [
    {'id': 'even_odd', 'label': 'Even/Odd', 'icon': Icons.filter_9_plus_rounded},
    {'id': 'match_differ', 'label': 'Match/Differ', 'icon': Icons.compare_rounded},
    {'id': 'over_under', 'label': 'Over/Under', 'icon': Icons.height_rounded},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialMarket != null) {
      _selectedMarket = widget.initialMarket!;
    }

    _tradingLogic = TradingLogic(
      token: widget.token,
      onBalanceUpdate: (balance, currency) {
        if (mounted) setState(() {});
      },
      onTradeResult: (result) {
        _handleTradeResult(result);
      },
      onPositionUpdate: (positions) {
        if (mounted) {
          // Verificar se ainda tem accumulator ativo
          if (_hasActiveAccumulator) {
            final stillActive = positions.any((p) => p['contract_id'] == _activeAccumulatorId);
            if (!stillActive) {
              setState(() {
                _hasActiveAccumulator = false;
                _activeAccumulatorId = null;
              });
            }
          }
          setState(() {});
        }
      },
    );

    _mlPredictor = MLPredictor(
      onPrediction: (prediction) {
        if (mounted) setState(() {});
      },
    );

    _tradingLogic.connect();
    _initWebView();
  }

  @override
  void dispose() {
    _tradingLogic.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _initWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..addJavaScriptChannel(
        'FlutterChannel',
        onMessageReceived: (JavaScriptMessage message) {
          final data = json.decode(message.message);
          if (data['type'] == 'price') {
            setState(() {
              _currentPrice = (data['price'] as num).toDouble();
              _priceChange = (data['change'] ?? 0.0) is num ? (data['change'] as num).toDouble() : 0.0;
            });
            _mlPredictor.addPriceData(_currentPrice);
          } else if (data['type'] == 'chart_data') {
            _mlPredictor.addChartData(List<double>.from(data['prices']));
          }
        },
      )
      ..loadHtmlString(_getChartHTML());
  }

  String _getChartHTML() {
    final isTickChart = _isTickBasedTrade();
    // Minimal placeholder chart HTML — your real HTML goes here.
    return '''
<!doctype html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <style>body{background-color:black;color:white;font-family:sans-serif}</style>
</head>
<body>
  <div id="chart">Chart placeholder (${isTickChart ? "tick based" : "time based"}) for $_selectedMarket</div>
  <script>
    // This page should post messages like:
    // FlutterChannel.postMessage(JSON.stringify({type:'price', price: 123.45, change: 0.12}));
    function addEntryMarker(direction, price) {
      console.log('entry', direction, price);
    }
    function changeMarket(m) {
      console.log('change market to', m);
    }
    function changeChartType(t) {
      console.log('change chart type', t);
    }
  </script>
</body>
</html>
''';
  }

  bool _isTickBasedTrade() {
    return _selectedTradeType == 'even_odd' ||
        _selectedTradeType == 'match_differ' ||
        _selectedTradeType == 'over_under';
  }

  void _handleTradeResult(Map<String, dynamic> result) async {
    final won = result['won'] as bool? ?? false;
    final profit = (result['profit'] as num?)?.toDouble() ?? 0.0;

    if (_soundEnabled) {
      if (won) {
        await _audioPlayer.play(AssetSource('sounds/win.mp3'));
      } else {
        await _audioPlayer.play(AssetSource('sounds/lose.mp3'));
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            won ? 'GANHOU: +\$${profit.toStringAsFixed(2)}' : 'PERDEU: -\$${profit.abs().toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: won ? const Color(0xFF00C896) : const Color(0xFFFF4444),
          duration: const Duration(seconds: 2),
        ),
      );

      // Limpar marcador de entrada
      setState(() {
        _entryPrice = null;
        _entryDirection = null;
      });
    }

    _mlPredictor.addTradeResult(won, profit);
  }

  void _placeTrade(String direction) async {
    if (_isTrading || !_tradingLogic.isConnected) return;

    // Accumulator: verificar se já tem ativo
    if (_selectedTradeType == 'accumulators') {
      if (_hasActiveAccumulator && direction == 'sell') {
        // Fechar accumulator
        await _tradingLogic.closeAccumulator(_activeAccumulatorId!);
        setState(() {
          _hasActiveAccumulator = false;
          _activeAccumulatorId = null;
        });
        return;
      } else if (_hasActiveAccumulator) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Você já tem um Accumulator ativo. Feche-o primeiro.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    setState(() => _isTrading = true);

    bool success = false;
    String? contractId;

    switch (_selectedTradeType) {
      case 'rise_fall':
        success = await _tradingLogic.placeRiseFall(
          market: _selectedMarket,
          stake: _stake,
          direction: direction,
          duration: _durationValue,
          durationType: _durationType,
        );
        break;
      case 'higher_lower':
        success = await _tradingLogic.placeHigherLower(
          market: _selectedMarket,
          stake: _stake,
          direction: direction,
          duration: _durationValue,
          durationType: _durationType,
        );
        break;
      case 'turbos':
        success = await _tradingLogic.placeTurbo(
          market: _selectedMarket,
          stake: _stake,
          direction: direction,
        );
        break;
      case 'accumulators':
        final result = await _tradingLogic.placeAccumulator(
          market: _selectedMarket,
          stake: _stake,
        );
        success = result['success'] as bool? ?? false;
        if (success) {
          contractId = result['contract_id'] as String?;
          setState(() {
            _hasActiveAccumulator = true;
            _activeAccumulatorId = contractId;
          });
        }
        break;
      case 'even_odd':
        success = await _tradingLogic.placeDigit(
          market: _selectedMarket,
          stake: _stake,
          type: direction == 'buy' ? 'DIGITEVEN' : 'DIGITODD',
          duration: _durationValue,
        );
        break;
      case 'match_differ':
        success = await _tradingLogic.placeDigit(
          market: _selectedMarket,
          stake: _stake,
          type: direction == 'buy' ? 'DIGITMATCH' : 'DIGITDIFF',
          barrier: _tickPrediction.toString(),
          duration: _durationValue,
        );
        break;
      case 'over_under':
        success = await _tradingLogic.placeDigit(
          market: _selectedMarket,
          stake: _stake,
          type: direction == 'buy' ? 'DIGITOVER' : 'DIGITUNDER',
          barrier: _tickPrediction.toString(),
          duration: _durationValue,
        );
        break;

      // Nova opção: Multipliers
      case 'multipliers':
        try {
          // Tentativa padrão — adapte a assinatura conforme sua TradingLogic
          final res = await _tradingLogic.placeMultiplier(
            market: _selectedMarket,
            stake: _stake,
            direction: direction,
            multiplier: _multiplier,
            // opcional: stop/take profit se sua lógica suportar
            stopLossPercent: _multiplierStopLossPercent,
            takeProfitPercent: _multiplierTakeProfitPercent,
          );
          // res pode ser bool ou map dependendo da implementação
          if (res is bool) {
            success = res;
          } else if (res is Map) {
            success = res['success'] as bool? ?? false;
            contractId = res['contract_id'] as String?;
          }
        } catch (e) {
          // Se o método não existir ou falhar, avise de forma amigável.
          success = false;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao abrir Multiplier: ${e.toString()}'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        break;

      default:
        // fallback
        success = false;
        break;
    }

    if (success && _webViewController != null) {
      setState(() {
        _entryPrice = _currentPrice;
        _entryDirection = direction;
      });

      try {
        _webViewController!.runJavaScript('addEntryMarker("$direction", $_currentPrice)');
      } catch (_) {}
    }

    setState(() => _isTrading = false);
  }

  @override
  Widget build(BuildContext context) {
    final mlPrediction = _mlPredictor.currentPrediction;
    final mlStake = _mlPredictor.recommendedStake(_tradingLogic.balance);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          if (mlPrediction != null) _buildMLPredictionBar(mlPrediction, mlStake),
          Expanded(
            flex: _chartExpanded ? 5 : 3,
            child: Stack(
              children: [
                if (_webViewController != null) WebViewWidget(controller: _webViewController!),
                if (_chartExpanded) _buildTechnicalAnalysisTools(),
                _buildChartControls(),
                if (_tradingLogic.activePositions.isNotEmpty) _buildPositionsOverlay(),
              ],
            ),
          ),
          if (!_chartExpanded) _buildTradingPanel(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF1A1A1A),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: GestureDetector(
        onTap: _showMarketSelector,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _allMarkets[_selectedMarket] ?? _selectedMarket,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
          ],
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_tradingLogic.balance.toStringAsFixed(2)} ${_tradingLogic.currency}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _priceChange >= 0 ? const Color(0xFF00C896).withOpacity(0.2) : const Color(0xFFFF4444).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${_priceChange >= 0 ? '+' : ''}${_priceChange.toStringAsFixed(2)}%',
                  style: TextStyle(
                    color: _priceChange >= 0 ? const Color(0xFF00C896) : const Color(0xFFFF4444),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMLPredictionBar(Map<String, dynamic> prediction, double stake) {
    final direction = prediction['direction'] as String? ?? 'N/A';
    final confidence = prediction['confidence'] as double? ?? 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0D47A1).withOpacity(0.3),
        border: Border(
          bottom: BorderSide(color: const Color(0xFF2196F3).withOpacity(0.3)),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.psychology_rounded, color: Color(0xFF2196F3), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'ML: ${direction.toUpperCase()} (${(confidence * 100).toStringAsFixed(0)}%) - Stake: \$${stake.toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, color: Colors.white70, size: 18),
            onPressed: () => _showMLInfo(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildChartControls() {
    return Positioned(
      top: 12,
      right: 12,
      child: Column(
        children: [
          _buildChartControlButton(
            icon: _chartExpanded ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded,
            onPressed: () {
              setState(() => _chartExpanded = !_chartExpanded);
              // Recarregar gráfico ao expandir/recolher se for tick-based
              if (_isTickBasedTrade()) {
                _webViewController?.reload();
              }
            },
          ),
          const SizedBox(height: 8),
          _buildChartControlButton(
            icon: Icons.show_chart_rounded,
            onPressed: _showChartTypeSelector,
          ),
        ],
      ),
    );
  }

  Widget _buildTechnicalAnalysisTools() {
    return Positioned(
      left: 12,
      top: 12,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAnalysisItem('RSI', '${(_mlPredictor.currentPrediction?['market_conditions']?['rsi'] ?? 0.5) * 100}'),
            _buildAnalysisItem('Trend', _mlPredictor.currentPrediction?['market_conditions']?['trend'] ?? 0.0),
            _buildAnalysisItem('Vol', _mlPredictor.currentPrediction?['market_conditions']?['volatility'] ?? 0.0),
            if (_entryPrice != null) ...[
              const Divider(color: Colors.white24, height: 16),
              _buildAnalysisItem('Entry', _entryPrice!, isPrice: true),
              _buildAnalysisItem('P/L', (_currentPrice - _entryPrice!) * (_entryDirection == 'buy' ? 1 : -1), isPrice: true),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisItem(String label, dynamic value, {bool isPrice = false}) {
    String displayValue;
    Color valueColor = Colors.white;

    if (isPrice) {
      final numValue = value is double ? value : double.tryParse(value.toString()) ?? 0.0;
      displayValue = numValue.toStringAsFixed(2);
      if (label == 'P/L') {
        valueColor = numValue >= 0 ? const Color(0xFF00C896) : const Color(0xFFFF4444);
        displayValue = '${numValue >= 0 ? '+' : ''}$displayValue';
      }
    } else if (value is double) {
      displayValue = value.toStringAsFixed(2);
    } else {
      displayValue = value.toString();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
          Text(
            displayValue,
            style: TextStyle(color: valueColor, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildChartControlButton({required IconData icon, required VoidCallback onPressed}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 20),
        onPressed: onPressed,
        padding: const EdgeInsets.all(8),
        constraints: const BoxConstraints(),
      ),
    );
  }

  Widget _buildPositionsOverlay() {
    return Positioned(
      bottom: 12,
      left: 12,
      right: 12,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.85),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(
          children: _tradingLogic.activePositions.map<Widget>((pos) {
            final profit = (pos['profit'] as num?)?.toDouble() ?? 0.0;
            final isProfit = profit >= 0;
            final idStr = pos['contract_id']?.toString() ?? '';
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'ID: ${idStr.length > 8 ? idStr.substring(0, 8) + '...' : idStr}',
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                    ),
                  ),
                  Text(
                    '${isProfit ? '+' : ''}\$${profit.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: isProfit ? const Color(0xFF00C896) : const Color(0xFFFF4444),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTradingPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        border: Border(top: BorderSide(color: Color(0xFF2A2A2A))),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildTradeTypeSelector(),
            const SizedBox(height: 12),
            _buildStakeAndDurationRow(),
            if (_selectedTradeType == 'match_differ' || _selectedTradeType == 'over_under') ...[
              const SizedBox(height: 12),
              _buildPredictionSelector(),
            ],
            if (_selectedTradeType == 'multipliers') ...[
              const SizedBox(height: 12),
              _buildMultiplierControls(),
            ],
            const SizedBox(height: 16),
            _buildTradeButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildTradeTypeSelector() {
    final allTypes = [..._tradeTypes, ..._tickTradeTypes];

    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: allTypes.length + 1,
        itemBuilder: (context, index) {
          if (index == allTypes.length) {
            return _buildSoundToggle();
          }

          final type = allTypes[index];
          final isSelected = _selectedTradeType == type['id'];

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedTradeType = type['id'];
                    // Recarregar chart se mudou para tick-based
                    if (_isTickBasedTrade()) {
                      _webViewController?.reload();
                    }
                  });
                },
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF0066FF) : const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF0066FF) : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        type['icon'],
                        color: isSelected ? Colors.white : Colors.white70,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        type['label'],
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white70,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSoundToggle() {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _soundEnabled = !_soundEnabled),
          borderRadius: BorderRadius.circular(22),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _soundEnabled ? const Color(0xFF00C896) : const Color(0xFF2A2A2A),
              shape: BoxShape.circle,
              border: Border.all(
                color: _soundEnabled ? const Color(0xFF00C896) : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Icon(
              _soundEnabled ? Icons.volume_up_rounded : Icons.volume_off_rounded,
              size: 20,
              color: _soundEnabled ? Colors.white : Colors.white70,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStakeAndDurationRow() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: GestureDetector(
            onTap: _showStakeKeyboard,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.attach_money_rounded, color: Colors.white70, size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _stake.toStringAsFixed(2),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_selectedTradeType != 'accumulators' && _selectedTradeType != 'turbos') ...[
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: _showDurationSelector,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.access_time_rounded, color: Colors.white70, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '$_durationValue${_getDurationLabel()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        // Quando multipliers selecionado, mostrar botão para ajustar multiplier
        if (_selectedTradeType == 'multipliers') ...[
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _showMultiplierSelector,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.multiple_stop_rounded, color: Colors.white70, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '${_multiplier}x',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  String _getDurationLabel() {
    switch (_durationType) {
      case 't':
        return 't';
      case 's':
        return 's';
      case 'm':
        return 'm';
      case 'h':
        return 'h';
      case 'd':
        return 'd';
      default:
        return 't';
    }
  }

  Widget _buildPredictionSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(Icons.tag_rounded, color: Colors.white70, size: 16),
              SizedBox(width: 8),
              Text('Prediction', style: TextStyle(color: Colors.white70, fontSize: 14)),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_rounded, color: Colors.white),
                onPressed: () {
                  if (_tickPrediction > 0) {
                    setState(() => _tickPrediction--);
                  }
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  _tickPrediction.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                onPressed: () {
                  if (_tickPrediction < 9) {
                    setState(() => _tickPrediction++);
                  }
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMultiplierControls() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.flash_on_rounded, color: Colors.white70),
              const SizedBox(width: 10),
              const Text('Multiplier', style: TextStyle(color: Colors.white70)),
              const Spacer(),
              Text('${_multiplier}x', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          Slider(
            value: _multiplier.toDouble(),
            min: 1,
            max: 100,
            divisions: 99,
            label: '${_multiplier}x',
            onChanged: (v) {
              setState(() {
                _multiplier = v.round();
              });
            },
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _showMultiplierSelector,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0066FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Ajustar Multiplier',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTradeButtons() {
    if (_selectedTradeType == 'accumulators') {
      return _buildAccumulatorButton();
    }

    final leftLabel = _getButtonLabel(true);
    final rightLabel = _getButtonLabel(false);

    return Row(
      children: [
        Expanded(
          child: _buildTradeButton(
            leftLabel,
            const Color(0xFF00C896),
            'buy',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildTradeButton(
            rightLabel,
            const Color(0xFFFF4444),
            'sell',
          ),
        ),
      ],
    );
  }

  Widget _buildAccumulatorButton() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isTrading ? null : () => _placeTrade(_hasActiveAccumulator ? 'sell' : 'buy'),
        borderRadius: BorderRadius.circular(100),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: _hasActiveAccumulator
                ? const LinearGradient(
                    colors: [Color(0xFFFF4444), Color(0xFFCC0000)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : const LinearGradient(
                    colors: [Color(0xFF0066FF), Color(0xFF0044CC)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            borderRadius: BorderRadius.circular(100),
            boxShadow: [
              BoxShadow(
                color: (_hasActiveAccumulator ? const Color(0xFFFF4444) : const Color(0xFF0066FF)).withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_hasActiveAccumulator ? Icons.close_rounded : Icons.add_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                _hasActiveAccumulator ? 'SELL / CLOSE' : 'BUY / OPEN',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTradeButton(String label, Color color, String direction) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isTrading ? null : () => _placeTrade(direction),
        borderRadius: BorderRadius.circular(100),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: _isTrading ? color.withOpacity(0.5) : color,
            borderRadius: BorderRadius.circular(100),
            boxShadow: _isTrading
                ? []
                : [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  String _getButtonLabel(bool isLeft) {
    switch (_selectedTradeType) {
      case 'rise_fall':
        return isLeft ? 'RISE' : 'FALL';
      case 'higher_lower':
        return isLeft ? 'HIGHER' : 'LOWER';
      case 'turbos':
        return isLeft ? 'UP' : 'DOWN';
      case 'even_odd':
        return isLeft ? 'EVEN' : 'ODD';
      case 'match_differ':
        return isLeft ? 'MATCH' : 'DIFFER';
      case 'over_under':
        return isLeft ? 'OVER' : 'UNDER';
      case 'multipliers':
        // mostrar labels mais descritivos para multipliers
        return isLeft ? 'BUY x${_multiplier}' : 'SELL x${_multiplier}';
      default:
        return isLeft ? 'BUY' : 'SELL';
    }
  }

  void _showMarketSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControllerAttached: true,
      builder: (context) => TweenAnimationBuilder(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, (1 - value) * 50),
            child: Opacity(opacity: value as double, child: child),
          );
        },
        child: Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A1A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
              ),
              const Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'Selecionar Mercado',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: _allMarkets.entries.map((e) {
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          setState(() => _selectedMarket = e.key);
                          _webViewController?.runJavaScript('changeMarket("${e.key}")');
                          Navigator.pop(context);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: e.key == _selectedMarket ? const Color(0xFF0066FF).withOpacity(0.2) : const Color(0xFF2A2A2A),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: e.key == _selectedMarket ? const Color(0xFF0066FF) : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.show_chart_rounded, color: e.key == _selectedMarket ? const Color(0xFF0066FF) : Colors.white70),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  e.value,
                                  style: TextStyle(
                                    color: e.key == _selectedMarket ? Colors.white : Colors.white70,
                                    fontSize: 15,
                                    fontWeight: e.key == _selectedMarket ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                              if (e.key == _selectedMarket) const Icon(Icons.check_circle_rounded, color: Color(0xFF0066FF)),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showChartTypeSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Tipo de Gráfico', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.candlestick_chart_rounded, color: Colors.white),
            title: const Text('Candlestick', style: TextStyle(color: Colors.white)),
            selected: _chartType == 'candlestick',
            selectedTileColor: const Color(0xFF0066FF).withOpacity(0.2),
            onTap: () => _changeChartType('candlestick'),
          ),
          ListTile(
            leading: const Icon(Icons.show_chart_rounded, color: Colors.white),
            title: const Text('Line', style: TextStyle(color: Colors.white)),
            selected: _chartType == 'line',
            selectedTileColor: const Color(0xFF0066FF).withOpacity(0.2),
            onTap: () => _changeChartType('line'),
          ),
          ListTile(
            leading: const Icon(Icons.area_chart_rounded, color: Colors.white),
            title: const Text('Area', style: TextStyle(color: Colors.white)),
            selected: _chartType == 'area',
            selectedTileColor: const Color(0xFF0066FF).withOpacity(0.2),
            onTap: () => _changeChartType('area'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _changeChartType(String type) {
    setState(() => _chartType = type);
    _webViewController?.runJavaScript('changeChartType("$type")');
    Navigator.pop(context);
  }

  void _showStakeKeyboard() {
    final controller = TextEditingController(text: _stake.toStringAsFixed(2));
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      isScrollControllerAttached: false,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Definir Stake', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  prefixText: '$ ',
                  prefixStyle: const TextStyle(color: Colors.white70, fontSize: 24),
                  hintText: '0.00',
                  hintStyle: const TextStyle(color: Colors.white24),
                  enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white24), borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFF0066FF), width: 2), borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFF2A2A2A),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancelar', style: TextStyle(color: Colors.white54, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        final value = double.tryParse(controller.text);
                        if (value != null && value >= 0.01) {
                          setState(() => _stake = value);
                          Navigator.pop(context);
                        }
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFF0066FF),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Confirmar', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDurationSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Duração', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          _buildDurationOption('Ticks', 't', Icons.access_time_rounded),
          _buildDurationOption('Seconds', 's', Icons.timer_rounded),
          _buildDurationOption('Minutes', 'm', Icons.schedule_rounded),
          _buildDurationOption('Hours', 'h', Icons.hourglass_empty_rounded),
          _buildDurationOption('Days', 'd', Icons.calendar_today_rounded),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDurationOption(String label, String type, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(label, style: const TextStyle(color: Colors.white)),
      selected: _durationType == type,
      selectedTileColor: const Color(0xFF0066FF).withOpacity(0.2),
      onTap: () {
        setState(() => _durationType = type);
        Navigator.pop(context);
        _showDurationValuePicker();
      },
    );
  }

  void _showDurationValuePicker() {
    final controller = TextEditingController(text: _durationValue.toString());
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Valor (${_getDurationLabel()})', style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: '5',
                  hintStyle: const TextStyle(color: Colors.white24),
                  enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Colors.white24), borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFF0066FF), width: 2), borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFF2A2A2A),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancelar', style: TextStyle(color: Colors.white54, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        final value = int.tryParse(controller.text);
                        if (value != null && value >= 1) {
                          setState(() => _durationValue = value);
                          Navigator.pop(context);
                        }
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFF0066FF),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Confirmar', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMultiplierSelector() {
    final controller = TextEditingController(text: _multiplier.toString());
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Ajustar Multiplier', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  hintText: '5',
                  hintStyle: TextStyle(color: Colors.white24),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: const Color(0xFF2A2A2A),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        final value = int.tryParse(controller.text);
                        if (value != null && value >= 1 && value <= 1000) {
                          setState(() => _multiplier = value);
                          Navigator.pop(context);
                        }
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: const Color(0xFF0066FF),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Confirmar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showMLInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.psychology_rounded, color: Color(0xFF2196F3)),
            SizedBox(width: 8),
            Text('Machine Learning', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('O sistema de ML analisa:', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('• Padrões do gráfico\n• Histórico de preços\n• Volatilidade\n• Tendências de mercado\n• Seu histórico de trades\n• Gestão de banca', style: TextStyle(color: Colors.white70, height: 1.5)),
            const SizedBox(height: 12),
            Text('Precisão atual: ${(_mlPredictor.accuracy * 100).toStringAsFixed(1)}%', style: const TextStyle(color: Color(0xFF00C896), fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Total de análises: ${_mlPredictor.totalPredictions}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Color(0xFF0066FF), fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}