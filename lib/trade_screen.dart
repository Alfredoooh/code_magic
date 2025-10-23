// trade_screen.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
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
  State<TradeScreen> createState() => _TradeScreenState();
}

class _TradeScreenState extends State<TradeScreen> {
  late TradingLogic _tradingLogic;
  late MLPredictor _mlPredictor;
  WebViewController? _webViewController;
  
  String _selectedMarket = 'R_100';
  String _selectedTradeType = 'rise_fall';
  double _currentPrice = 0.0;
  double _priceChange = 0.0;
  bool _isConnected = false;
  double _stake = 10.0;
  bool _isTrading = false;
  bool _soundEnabled = false;
  bool _chartExpanded = false;
  String _chartType = 'candlestick';
  int _tickPrediction = 5;
  List<double> _tickHistory = [];
  
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  final Map<String, String> _allMarkets = {
    'R_10': 'Volatility 10',
    'R_25': 'Volatility 25',
    'R_50': 'Volatility 50',
    'R_75': 'Volatility 75',
    'R_100': 'Volatility 100',
    '1HZ10V': 'Vol 10 (1s)',
    '1HZ25V': 'Vol 25 (1s)',
    '1HZ50V': 'Vol 50 (1s)',
    '1HZ75V': 'Vol 75 (1s)',
    '1HZ100V': 'Vol 100 (1s)',
    'BOOM300N': 'Boom 300',
    'BOOM500': 'Boom 500',
    'CRASH300N': 'Crash 300',
    'CRASH500': 'Crash 500',
  };

  final List<Map<String, dynamic>> _tradeTypes = [
    {'id': 'rise_fall', 'label': 'Rise/Fall'},
    {'id': 'higher_lower', 'label': 'Higher/Lower'},
    {'id': 'turbos', 'label': 'Turbos'},
    {'id': 'accumulators', 'label': 'Accumulators'},
  ];

  final List<Map<String, dynamic>> _tickTradeTypes = [
    {'id': 'even_odd', 'label': 'Even/Odd'},
    {'id': 'match_differ', 'label': 'Match/Differ'},
    {'id': 'over_under', 'label': 'Over/Under'},
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
        if (mounted) setState(() {});
      },
    );
    
    _mlPredictor = MLPredictor(
      onPrediction: (prediction) {
        if (mounted) {
          setState(() {});
        }
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
              _currentPrice = data['price'];
              _priceChange = data['change'] ?? 0.0;
            });
            
            _mlPredictor.addPriceData(_currentPrice);
            
            if (_isTickBasedTrade()) {
              _tickHistory.add(_currentPrice);
              if (_tickHistory.length > 100) {
                _tickHistory.removeAt(0);
              }
            }
          } else if (data['type'] == 'chart_data') {
            _mlPredictor.addChartData(List<double>.from(data['prices']));
          }
        },
      )
      ..loadHtmlString(_getChartHTML());
  }

  String _getChartHTML() {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=5">
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { background: #000; color: #fff; overflow: hidden; touch-action: pan-x pan-y; }
    #chart { width: 100vw; height: 100vh; }
  </style>
</head>
<body>
  <div id="chart"></div>
  <script src="https://unpkg.com/lightweight-charts@4.0.0/dist/lightweight-charts.standalone.production.js"></script>
  <script>
    let chart, series, ws, symbol = '$_selectedMarket', candles = [], ticks = [];
    let isScrolling = false, chartType = 'candlestick';
    
    function init() {
      chart = LightweightCharts.createChart(document.getElementById('chart'), {
        width: window.innerWidth,
        height: window.innerHeight,
        layout: { background: { color: '#000' }, textColor: '#888' },
        grid: { vertLines: { color: '#1a1a1a' }, horzLines: { color: '#1a1a1a' } },
        timeScale: { 
          borderColor: '#1a1a1a', 
          timeVisible: true,
          rightOffset: 5,
          barSpacing: 8,
          fixLeftEdge: true,
          fixRightEdge: false
        },
        handleScroll: { mouseWheel: true, pressedMouseMove: true, horzTouchDrag: true },
        handleScale: { mouseWheel: true, pinch: true },
      });
      
      createSeries('candlestick');
      
      chart.timeScale().subscribeVisibleLogicalRangeChange(() => {
        isScrolling = true;
        clearTimeout(window.scrollTimeout);
        window.scrollTimeout = setTimeout(() => { isScrolling = false; }, 2000);
      });
      
      connect();
      window.addEventListener('resize', () => {
        chart.applyOptions({ width: window.innerWidth, height: window.innerHeight });
      });
    }
    
    function createSeries(type) {
      if (series) chart.removeSeries(series);
      
      if (type === 'candlestick') {
        series = chart.addCandlestickSeries({
          upColor: '#00C896', downColor: '#FF4444',
          wickUpColor: '#00C896', wickDownColor: '#FF4444',
        });
      } else if (type === 'line') {
        series = chart.addLineSeries({
          color: '#0066FF', lineWidth: 2,
        });
      } else if (type === 'area') {
        series = chart.addAreaSeries({
          topColor: 'rgba(0, 102, 255, 0.4)',
          bottomColor: 'rgba(0, 102, 255, 0.0)',
          lineColor: '#0066FF', lineWidth: 2,
        });
      }
      
      chartType = type;
      updateChart();
    }
    
    function connect() {
      ws = new WebSocket('wss://ws.derivws.com/websockets/v3?app_id=71954');
      ws.onopen = () => {
        ws.send(JSON.stringify({
          ticks_history: symbol, count: 500, end: 'latest', start: 1,
          style: 'candles', granularity: 60
        }));
        setTimeout(() => {
          ws.send(JSON.stringify({ ticks: symbol, subscribe: 1 }));
        }, 300);
      };
      ws.onmessage = (e) => handleMessage(JSON.parse(e.data));
      ws.onclose = () => setTimeout(connect, 3000);
    }
    
    function handleMessage(data) {
      if (data.candles || data.history) {
        candles = (data.candles || []).map(c => ({
          time: c.epoch, open: parseFloat(c.open), high: parseFloat(c.high),
          low: parseFloat(c.low), close: parseFloat(c.close)
        }));
        updateChart();
        sendChartData();
      } else if (data.tick) {
        const price = parseFloat(data.tick.quote);
        const time = data.tick.epoch;
        ticks.push({ time, price });
        if (ticks.length > 100) ticks.shift();
        
        const candleTime = Math.floor(time / 60) * 60;
        let candle = candles.find(c => c.time === candleTime);
        if (!candle) {
          candle = { time: candleTime, open: price, high: price, low: price, close: price };
          candles.push(candle);
        } else {
          candle.high = Math.max(candle.high, price);
          candle.low = Math.min(candle.low, price);
          candle.close = price;
        }
        
        if (candles.length > 500) candles.shift();
        updateChart();
        sendPrice(price);
      }
    }
    
    function updateChart() {
      if (!series || candles.length === 0) return;
      
      if (chartType === 'candlestick') {
        series.setData(candles);
      } else {
        const lineData = candles.map(c => ({ time: c.time, value: c.close }));
        series.setData(lineData);
      }
      
      if (!isScrolling) chart.timeScale().scrollToRealTime();
    }
    
    function sendPrice(price) {
      if (candles.length > 1) {
        const prev = candles[candles.length - 2].close;
        const change = ((price - prev) / prev) * 100;
        FlutterChannel.postMessage(JSON.stringify({
          type: 'price', price: price, change: change
        }));
      }
    }
    
    function sendChartData() {
      const prices = candles.map(c => c.close);
      FlutterChannel.postMessage(JSON.stringify({
        type: 'chart_data', prices: prices
      }));
    }
    
    function changeMarket(newSymbol) {
      symbol = newSymbol;
      candles = [];
      ticks = [];
      if (ws) ws.close();
      connect();
    }
    
    function changeChartType(type) {
      createSeries(type);
    }
    
    function addTradeMarker(type, price) {
      if (!series) return;
      const color = type === 'buy' ? '#00C896' : '#FF4444';
      const position = type === 'buy' ? 'belowBar' : 'aboveBar';
      const shape = type === 'buy' ? 'arrowUp' : 'arrowDown';
      
      series.createPriceLine({
        price: price,
        color: color,
        lineWidth: 2,
        lineStyle: 2,
        axisLabelVisible: true,
      });
    }
    
    window.changeMarket = changeMarket;
    window.changeChartType = changeChartType;
    window.addTradeMarker = addTradeMarker;
    init();
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
    final won = result['won'] as bool;
    final profit = result['profit'] as double;
    
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
            won ? 'GANHOU: +\$${profit.toStringAsFixed(2)}' 
                : 'PERDEU: -\$${profit.abs().toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: won ? const Color(0xFF00C896) : const Color(0xFFFF4444),
          duration: const Duration(seconds: 2),
        ),
      );
    }
    
    _mlPredictor.addTradeResult(won, profit);
  }

  void _placeTrade(String direction) async {
    if (_isTrading || !_tradingLogic.isConnected) return;
    
    setState(() => _isTrading = true);
    
    bool success = false;
    
    switch (_selectedTradeType) {
      case 'rise_fall':
        success = await _tradingLogic.placeRiseFall(
          market: _selectedMarket,
          stake: _stake,
          direction: direction,
        );
        break;
      case 'higher_lower':
        success = await _tradingLogic.placeHigherLower(
          market: _selectedMarket,
          stake: _stake,
          direction: direction,
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
        success = await _tradingLogic.placeAccumulator(
          market: _selectedMarket,
          stake: _stake,
        );
        break;
      case 'even_odd':
        success = await _tradingLogic.placeDigit(
          market: _selectedMarket,
          stake: _stake,
          type: direction == 'buy' ? 'DIGITEVEN' : 'DIGITODD',
        );
        break;
      case 'match_differ':
        success = await _tradingLogic.placeDigit(
          market: _selectedMarket,
          stake: _stake,
          type: direction == 'buy' ? 'DIGITMATCH' : 'DIGITDIFF',
          barrier: _tickPrediction.toString(),
        );
        break;
      case 'over_under':
        success = await _tradingLogic.placeDigit(
          market: _selectedMarket,
          stake: _stake,
          type: direction == 'buy' ? 'DIGITOVER' : 'DIGITUNDER',
          barrier: _tickPrediction.toString(),
        );
        break;
    }
    
    if (success && _webViewController != null) {
      _webViewController!.runJavaScript(
        'addTradeMarker("$direction", $_currentPrice)'
      );
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
            flex: _chartExpanded ? 4 : 3,
            child: Stack(
              children: [
                WebViewWidget(controller: _webViewController!),
                _buildChartControls(),
                if (_tradingLogic.activePositions.isNotEmpty)
                  _buildPositionsOverlay(),
              ],
            ),
          ),
          _buildTradingPanel(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFF1A1A1A),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: GestureDetector(
        onTap: _showMarketSelector,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _allMarkets[_selectedMarket] ?? '',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const Icon(Icons.keyboard_arrow_down, size: 20),
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
                  color: _priceChange >= 0 
                      ? const Color(0xFF00C896).withOpacity(0.2)
                      : const Color(0xFFFF4444).withOpacity(0.2),
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
    final direction = prediction['direction'] as String;
    final confidence = prediction['confidence'] as double;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: const Color(0xFF0D47A1).withOpacity(0.3),
      child: Row(
        children: [
          const Icon(Icons.psychology, color: Color(0xFF2196F3), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'ML: ${direction.toUpperCase()} (${(confidence * 100).toStringAsFixed(0)}%) - Stake: \$${stake.toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white70, size: 18),
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
            icon: _chartExpanded ? Icons.fullscreen_exit : Icons.fullscreen,
            onPressed: () => setState(() => _chartExpanded = !_chartExpanded),
          ),
          const SizedBox(height: 8),
          _buildChartControlButton(
            icon: Icons.show_chart,
            onPressed: _showChartTypeSelector,
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
          children: _tradingLogic.activePositions.map((pos) {
            final profit = pos['profit'] ?? 0.0;
            final isProfit = profit >= 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ID: ${pos['contract_id'].toString().substring(0, 8)}...',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
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
            _buildStakeSelector(),
            if (_selectedTradeType == 'over_under') ...[
              const SizedBox(height: 12),
              _buildPredictionSelector(),
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
      height: 40,
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
            child: ChoiceChip(
              label: Text(type['label']),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedTradeType = type['id']);
                }
              },
              backgroundColor: const Color(0xFF2A2A2A),
              selectedColor: const Color(0xFF0066FF),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
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
      child: ChoiceChip(
        label: Icon(
          _soundEnabled ? Icons.volume_up : Icons.volume_off,
          size: 18,
          color: Colors.white,
        ),
        selected: _soundEnabled,
        onSelected: (selected) => setState(() => _soundEnabled = selected),
        backgroundColor: const Color(0xFF2A2A2A),
        selectedColor: const Color(0xFF00C896),
        padding: const EdgeInsets.all(8),
        shape: const CircleBorder(),
      ),
    );
  }

  Widget _buildStakeSelector() {
    return GestureDetector(
      onTap: _showStakeDialog,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Stake',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            Text(
              '\$${_stake.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Prediction',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove, color: Colors.white),
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
                icon: const Icon(Icons.add, color: Colors.white),
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

  Widget _buildTradeButtons() {
    if (_selectedTradeType == 'accumulators') {
      return _buildSingleTradeButton('BUY', const Color(0xFF0066FF), 'buy');
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

  Widget _buildTradeButton(String label, Color color, String direction) {
    return Material(
      color: _isTrading ? color.withOpacity(0.5) : color,
      borderRadius: BorderRadius.circular(100),
      child: InkWell(
        onTap: _isTrading ? null : () => _placeTrade(direction),
        borderRadius: BorderRadius.circular(100),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSingleTradeButton(String label, Color color, String direction) {
    return Material(
      color: _isTrading ? color.withOpacity(0.5) : color,
      borderRadius: BorderRadius.circular(100),
      child: InkWell(
        onTap: _isTrading ? null : () => _placeTrade(direction),
        borderRadius: BorderRadius.circular(100),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
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
      default:
        return isLeft ? 'BUY' : 'SELL';
    }
  }

  void _showMarketSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(16),
        children: _allMarkets.entries.map((e) => ListTile(
          title: Text(e.value, style: const TextStyle(color: Colors.white)),
          selected: e.key == _selectedMarket,
          selectedTileColor: const Color(0xFF0066FF).withOpacity(0.2),
          onTap: () {
            setState(() => _selectedMarket = e.key);
            _webViewController?.runJavaScript('changeMarket("${e.key}")');
            Navigator.pop(context);
          },
        )).toList(),
      ),
    );
  }

  void _showChartTypeSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Tipo de Gráfico',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.candlestick_chart, color: Colors.white),
            title: const Text('Candlestick', style: TextStyle(color: Colors.white)),
            selected: _chartType == 'candlestick',
            onTap: () => _changeChartType('candlestick'),
          ),
          ListTile(
            leading: const Icon(Icons.show_chart, color: Colors.white),
            title: const Text('Line', style: TextStyle(color: Colors.white)),
            selected: _chartType == 'line',
            onTap: () => _changeChartType('line'),
          ),
          ListTile(
            leading: const Icon(Icons.area_chart, color: Colors.white),
            title: const Text('Area', style: TextStyle(color: Colors.white)),
            selected: _chartType == 'area',
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

  void _showStakeDialog() {
    final controller = TextEditingController(text: _stake.toStringAsFixed(2));
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Definir Stake', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Digite o valor',
            hintStyle: TextStyle(color: Colors.white54),
            prefixText: '\$ ',
            prefixStyle: TextStyle(color: Colors.white),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white24),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF0066FF)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              final value = double.tryParse(controller.text);
              if (value != null && value >= 1.0) {
                setState(() => _stake = value);
                Navigator.pop(context);
              }
            },
            child: const Text('OK', style: TextStyle(color: Color(0xFF0066FF))),
          ),
        ],
      ),
    );
  }

  void _showMLInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Row(
          children: [
            Icon(Icons.psychology, color: Color(0xFF2196F3)),
            SizedBox(width: 8),
            Text('Machine Learning', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'O sistema de ML analisa:',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Padrões do gráfico\n• Histórico de preços\n• Volatilidade\n• Tendências de mercado\n• Seu histórico de trades\n• Gestão de banca',
              style: TextStyle(color: Colors.white70, height: 1.5),
            ),
            const SizedBox(height: 12),
            Text(
              'Precisão atual: ${(_mlPredictor.accuracy * 100).toStringAsFixed(1)}%',
              style: const TextStyle(color: Color(0xFF00C896), fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Total de análises: ${_mlPredictor.totalPredictions}',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Color(0xFF0066FF))),
          ),
        ],
      ),
    );
  }
}