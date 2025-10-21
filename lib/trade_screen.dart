import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'styles.dart';

class TradeScreen extends StatefulWidget {
  final String token;
  
  const TradeScreen({Key? key, required this.token}) : super(key: key);

  @override
  State<TradeScreen> createState() => _TradeScreenState();
}

class _TradeScreenState extends State<TradeScreen> with AutomaticKeepAliveClientMixin {
  WebSocketChannel? _channel;
  WebViewController? _webViewController;
  String _selectedMarket = 'R_100';
  double _currentPrice = 0.0;
  double _priceChange = 0.0;
  bool _isConnected = false;
  double _stake = 11.0;
  int _multiplier = 40;
  String _accountType = 'Real';
  double _balance = 0.00;
  bool _isTrading = false;
  bool _chartExpanded = false;
  List<Map<String, dynamic>> _activePositions = [];
  
  final Map<String, String> _markets = {
    'R_100': 'Volatility 100 Index',
    'R_50': 'Volatility 50 Index',
    'R_25': 'Volatility 25 Index',
    'R_10': 'Volatility 10 Index',
    'BOOM1000': 'Boom 1000 Index',
    'BOOM500': 'Boom 500 Index',
    'CRASH1000': 'Crash 1000 Index',
    'CRASH500': 'Crash 500 Index',
    '1HZ100V': 'Vol 100 (1s) Index',
    '1HZ50V': 'Vol 50 (1s) Index',
  };

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
    _initWebView();
  }

  @override
  void dispose() {
    _channel?.sink.close();
    super.dispose();
  }

  void _initWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0A0A0A))
      ..addJavaScriptChannel(
        'FlutterChannel',
        onMessageReceived: (JavaScriptMessage message) {
          final data = json.decode(message.message);
          if (data['type'] == 'price') {
            setState(() {
              _currentPrice = data['price'];
              _priceChange = data['change'] ?? 0.0;
            });
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
  <meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=5,user-scalable=yes">
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { 
      background: #0A0A0A; 
      color: #fff; 
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      overflow: hidden;
      touch-action: pan-x pan-y;
    }
    #chart { 
      width: 100vw; 
      height: 100vh; 
      position: relative;
    }
    .indicators {
      position: absolute;
      top: 10px;
      right: 10px;
      z-index: 1000;
      background: rgba(0,0,0,0.7);
      padding: 8px;
      border-radius: 8px;
      font-size: 11px;
      color: #888;
    }
  </style>
</head>
<body>
  <div id="chart">
    <div class="indicators">
      <div>Vol: <span id="volume">-</span></div>
      <div>RSI: <span id="rsi">-</span></div>
    </div>
  </div>
  <script src="https://unpkg.com/lightweight-charts@4.0.0/dist/lightweight-charts.standalone.production.js"></script>
  <script>
    class Chart {
      constructor() {
        this.chart = null;
        this.series = null;
        this.ws = null;
        this.symbol = '$_selectedMarket';
        this.interval = 60;
        this.candles = [];
        this.init();
      }

      init() {
        const container = document.getElementById('chart');
        
        this.chart = LightweightCharts.createChart(container, {
          width: window.innerWidth,
          height: window.innerHeight,
          layout: {
            background: { color: '#0A0A0A' },
            textColor: '#666',
          },
          grid: {
            vertLines: { color: '#1a1a1a' },
            horzLines: { color: '#1a1a1a' }
          },
          rightPriceScale: {
            borderColor: '#1a1a1a',
            textColor: '#888',
          },
          timeScale: {
            borderColor: '#1a1a1a',
            timeVisible: true,
            secondsVisible: false,
            rightOffset: 12,
            barSpacing: 10,
          },
          crosshair: {
            mode: 1,
            vertLine: {
              color: '#666',
              width: 1,
              style: 3,
              labelBackgroundColor: '#00C7BE',
            },
            horzLine: {
              color: '#666',
              width: 1,
              style: 3,
              labelBackgroundColor: '#00C7BE',
            },
          },
          handleScroll: {
            mouseWheel: true,
            pressedMouseMove: true,
            horzTouchDrag: true,
            vertTouchDrag: true,
          },
          handleScale: {
            axisPressedMouseMove: true,
            mouseWheel: true,
            pinch: true,
          },
        });

        this.series = this.chart.addCandlestickSeries({
          upColor: '#00C7BE',
          downColor: '#FF4757',
          borderVisible: false,
          wickUpColor: '#00C7BE',
          wickDownColor: '#FF4757',
          priceLineVisible: true,
          lastValueVisible: true,
        });

        this.connect();

        window.addEventListener('resize', () => {
          this.chart.applyOptions({
            width: window.innerWidth,
            height: window.innerHeight
          });
        });

        // Touch gestures
        let touchStartDistance = 0;
        container.addEventListener('touchstart', (e) => {
          if (e.touches.length === 2) {
            touchStartDistance = Math.hypot(
              e.touches[0].pageX - e.touches[1].pageX,
              e.touches[0].pageY - e.touches[1].pageY
            );
          }
        });

        container.addEventListener('touchmove', (e) => {
          if (e.touches.length === 2) {
            const touchDistance = Math.hypot(
              e.touches[0].pageX - e.touches[1].pageX,
              e.touches[0].pageY - e.touches[1].pageY
            );
            const scale = touchDistance / touchStartDistance;
            touchStartDistance = touchDistance;
          }
        });
      }

      connect() {
        this.ws = new WebSocket('wss://ws.derivws.com/websockets/v3?app_id=71954');
        
        this.ws.onopen = () => this.subscribe();
        this.ws.onmessage = (e) => this.handleMessage(JSON.parse(e.data));
        this.ws.onclose = () => setTimeout(() => this.connect(), 3000);
      }

      subscribe() {
        this.ws.send(JSON.stringify({
          ticks_history: this.symbol,
          adjust_start_time: 1,
          count: 1000,
          end: 'latest',
          start: 1,
          style: 'candles',
          granularity: this.interval
        }));

        setTimeout(() => {
          this.ws.send(JSON.stringify({
            ticks: this.symbol,
            subscribe: 1
          }));
        }, 300);
      }

      handleMessage(data) {
        if (data.error) return;

        if (data.msg_type === 'candles' || data.msg_type === 'history') {
          this.candles = (data.candles || []).map(c => ({
            time: c.epoch,
            open: parseFloat(c.open),
            high: parseFloat(c.high),
            low: parseFloat(c.low),
            close: parseFloat(c.close)
          }));
          this.updateChart();
        } else if (data.msg_type === 'tick') {
          const price = parseFloat(data.tick.quote);
          const time = data.tick.epoch;
          const candleTime = Math.floor(time / this.interval) * this.interval;

          let candle = this.candles.find(c => c.time === candleTime);
          if (!candle) {
            candle = { time: candleTime, open: price, high: price, low: price, close: price };
            this.candles.push(candle);
          } else {
            candle.high = Math.max(candle.high, price);
            candle.low = Math.min(candle.low, price);
            candle.close = price;
          }

          if (this.candles.length > 1000) this.candles.shift();
          this.updateChart();
          this.sendPrice(price);
          this.updateIndicators();
        }
      }

      updateChart() {
        if (!this.series || this.candles.length === 0) return;
        this.series.setData(this.candles);
        this.chart.timeScale().scrollToRealTime();
      }

      updateIndicators() {
        if (this.candles.length < 14) return;
        const closes = this.candles.slice(-14).map(c => c.close);
        const rsi = this.calculateRSI(closes);
        document.getElementById('rsi').textContent = rsi.toFixed(1);
      }

      calculateRSI(prices, period = 14) {
        let gains = 0, losses = 0;
        for (let i = 1; i < prices.length; i++) {
          const change = prices[i] - prices[i - 1];
          if (change > 0) gains += change;
          else losses -= change;
        }
        const avgGain = gains / period;
        const avgLoss = losses / period;
        const rs = avgGain / avgLoss;
        return 100 - (100 / (1 + rs));
      }

      sendPrice(price) {
        if (this.candles.length > 1) {
          const prev = this.candles[this.candles.length - 2].close;
          const change = ((price - prev) / prev) * 100;
          FlutterChannel.postMessage(JSON.stringify({
            type: 'price',
            price: price,
            change: change
          }));
        }
      }

      changeMarket(symbol) {
        this.symbol = symbol;
        this.candles = [];
        this.subscribe();
      }

      changeInterval(interval) {
        this.interval = interval;
        this.candles = [];
        this.subscribe();
      }
    }

    const chart = new Chart();
    window.chart = chart;
  </script>
</body>
</html>
    ''';
  }

  void _connectWebSocket() {
    try {
      _channel = WebSocketChannel.connect(
        Uri.parse('wss://ws.derivws.com/websockets/v3?app_id=71954'),
      );

      setState(() => _isConnected = true);

      _channel!.stream.listen(
        (message) {
          final data = json.decode(message);
          
          if (data['msg_type'] == 'authorize') {
            setState(() {
              _balance = double.parse(data['authorize']['balance'].toString());
              _accountType = data['authorize']['currency'];
            });
          } else if (data['msg_type'] == 'buy') {
            final contract = data['buy'];
            setState(() {
              _activePositions.add({
                'contract_id': contract['contract_id'],
                'buy_price': contract['buy_price'],
                'payout': contract['payout'],
                'start_time': DateTime.now(),
              });
              _isTrading = false;
            });
            AppStyles.showSnackBar(context, 'Trade aberto: ${contract['longcode']}');
            
            // Subscribe para updates do contrato
            _channel!.sink.add(json.encode({
              'proposal_open_contract': 1,
              'contract_id': contract['contract_id'],
              'subscribe': 1,
            }));
          } else if (data['msg_type'] == 'proposal_open_contract') {
            _updatePosition(data['proposal_open_contract']);
          }
        },
        onError: (error) => setState(() => _isConnected = false),
        onDone: () {
          setState(() => _isConnected = false);
          Future.delayed(const Duration(seconds: 3), _connectWebSocket);
        },
      );

      // Autorizar com token
      _channel!.sink.add(json.encode({
        'authorize': widget.token,
      }));
    } catch (e) {
      setState(() => _isConnected = false);
    }
  }

  void _updatePosition(Map<String, dynamic> contract) {
    final index = _activePositions.indexWhere((p) => p['contract_id'] == contract['contract_id']);
    if (index != -1) {
      setState(() {
        _activePositions[index]['current_spot'] = contract['current_spot'];
        _activePositions[index]['profit'] = contract['profit'];
        _activePositions[index]['status'] = contract['status'];
        
        if (contract['status'] == 'won' || contract['status'] == 'lost') {
          AppStyles.showSnackBar(
            context,
            'Trade finalizado: ${contract['status'].toUpperCase()} | Lucro: \$${contract['profit']}',
            isError: contract['status'] == 'lost',
          );
          Future.delayed(const Duration(seconds: 3), () {
            setState(() => _activePositions.removeAt(index));
          });
        }
      });
    }
  }

  void _changeMarket(String market) {
    setState(() => _selectedMarket = market);
    _webViewController?.runJavaScript('chart.changeMarket("$market")');
  }

  void _placeTrade(String direction) {
    if (_isTrading || !_isConnected) return;
    
    setState(() => _isTrading = true);

    // Primeiro fazer proposal para ver payout
    _channel!.sink.add(json.encode({
      'proposal': 1,
      'amount': _stake,
      'basis': 'stake',
      'contract_type': direction == 'BUY' ? 'CALL' : 'PUT',
      'currency': _accountType,
      'duration': 5,
      'duration_unit': 't',
      'symbol': _selectedMarket,
      'multiplier': _multiplier,
    }));

    // Depois comprar
    Future.delayed(const Duration(milliseconds: 500), () {
      _channel!.sink.add(json.encode({
        'buy': 1,
        'price': _stake,
        'parameters': {
          'contract_type': direction == 'BUY' ? 'CALL' : 'PUT',
          'currency': _accountType,
          'duration': 5,
          'duration_unit': 't',
          'symbol': _selectedMarket,
          'amount': _stake,
          'basis': 'stake',
          'multiplier': _multiplier,
        },
      }));
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.fromLTRB(16, MediaQuery.of(context).padding.top + 12, 16, 12),
            decoration: const BoxDecoration(
              color: Color(0xFF141414),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.menu_rounded, color: Colors.white),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Multipliers',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            _markets[_selectedMarket] ?? '',
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _accountType,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          '${_balance.toStringAsFixed(2)} ${_accountType}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: const Color(0xFF1a1a1a),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (context) => Container(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: _markets.entries.map((e) => ListTile(
                            title: Text(
                              e.value,
                              style: const TextStyle(color: Colors.white),
                            ),
                            selected: e.key == _selectedMarket,
                            selectedTileColor: AppStyles.iosBlue.withOpacity(0.2),
                            onTap: () {
                              _changeMarket(e.key);
                              Navigator.pop(context);
                            },
                          )).toList(),
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1a1a1a),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _markets[_selectedMarket] ?? '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Colors.white70,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Gráfico
          Expanded(
            flex: _chartExpanded ? 3 : 2,
            child: Stack(
              children: [
                WebViewWidget(controller: _webViewController!),
                Positioned(
                  top: 12,
                  right: 12,
                  child: IconButton(
                    icon: Icon(
                      _chartExpanded ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded,
                      color: Colors.white,
                    ),
                    onPressed: () => setState(() => _chartExpanded = !_chartExpanded),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withOpacity(0.6),
                    ),
                  ),
                ),
                // Posições ativas
                if (_activePositions.isNotEmpty)
                  Positioned(
                    bottom: 12,
                    left: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: _activePositions.map((pos) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'ID: ${pos['contract_id'].toString().substring(0, 8)}...',
                                style: const TextStyle(color: Colors.white70, fontSize: 11),
                              ),
                              Text(
                                '\$${pos['profit']?.toStringAsFixed(2) ?? '0.00'}',
                                style: TextStyle(
                                  color: (pos['profit'] ?? 0) >= 0 ? AppStyles.green : AppStyles.red,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        )).toList(),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Painel de Trading
          if (!_chartExpanded)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF141414),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    // Configurações
                    Row(
                      children: [
                        Expanded(
                          child: _buildTradeOption(
                            'Stake: ${_stake.toStringAsFixed(2)}',
                            () => _showStakeDialog(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildTradeOption('x$_multiplier', () => _showMultiplierDialog()),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Botões BUY/SELL
                    Row(
                      children: [
                        Expanded(
                          child: _buildTradeButton(
                            'BUY',
                            '${_stake.toStringAsFixed(0)}',
                            const Color(0xFF00C7BE),
                            Icons.arrow_upward_rounded,
                            () => _placeTrade('BUY'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTradeButton(
                            'SELL',
                            '${_stake.toStringAsFixed(0)}',
                            const Color(0xFFFF4757),
                            Icons.arrow_downward_rounded,
                            () => _placeTrade('SELL'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTradeOption(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1a1a1a),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildTradeButton(
    String label,
    String amount,
    Color color,
    IconData icon,
    VoidCallback onPressed,
  ) {
    return Material(
      color: _isTrading ? color.withOpacity(0.5) : color,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: _isTrading ? null : onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
              Icon(icon, color: Colors.white, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                amount,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showStakeDialog() {
    final controller = TextEditingController(text: _stake.toStringAsFixed(2));
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a1a),
        title: const Text('Definir Stake', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Digite o valor',
            hintStyle: TextStyle(color: Colors.white54),
            prefixText: '\$ ',
            prefixStyle: TextStyle(color: Colors.white),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              setState(() => _stake = double.tryParse(controller.text) ?? 11.0);
              Navigator.pop(context);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showMultiplierDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a1a),
        title: const Text('Multiplicador', style: TextStyle(color: Colors.white)),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [10, 20, 40, 50, 100, 200].map((mult) => 
            ElevatedButton(
              onPressed: () {
                setState(() => _multiplier = mult);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _multiplier == mult ? AppStyles.iosBlue : Colors.grey[800],
              ),
              child: Text('x$mult'),
            ),
          ).toList(),
        ),
      ),
    );
  }
}