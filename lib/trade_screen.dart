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
  bool _hasStopLoss = false;
  bool _hasTakeProfit = false;
  String _accountType = 'Real';
  double _balance = 0.00;
  
  final Map<String, String> _markets = {
    'R_100': 'Volatility 100 Index',
    'R_50': 'Volatility 50 Index',
    'R_25': 'Volatility 25 Index',
    'R_10': 'Volatility 10 Index',
    'BOOM1000': 'Boom 1000 Index',
    'BOOM500': 'Boom 500 Index',
    'CRASH1000': 'Crash 1000 Index',
    'CRASH500': 'Crash 500 Index',
    '1HZ100V': 'Volatility 100 (1s) Index',
    '1HZ50V': 'Volatility 50 (1s) Index',
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
  <meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=5">
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { 
      background: #0A0A0A; 
      color: #fff; 
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      overflow: hidden;
    }
    #chart { width: 100vw; height: 100vh; }
  </style>
</head>
<body>
  <div id="chart"></div>
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
        }
      }

      updateChart() {
        if (!this.series || this.candles.length === 0) return;
        this.series.setData(this.candles);
        this.chart.timeScale().fitContent();
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
            setState(() => _balance = double.parse(data['authorize']['balance'].toString()));
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

  void _changeMarket(String market) {
    setState(() => _selectedMarket = market);
    _webViewController?.runJavaScript('chart.changeMarket("$market")');
  }

  void _placeTrade(String direction) {
    final payout = (_stake * _multiplier).toStringAsFixed(2);
    AppStyles.showSnackBar(
      context,
      '$direction: \$${_stake.toStringAsFixed(2)} → Possível retorno: \$$payout USDC',
    );
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Multipliers',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
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
                          '${_balance.toStringAsFixed(2)} USDC',
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
                          Icons.keyboard_arrow_down,
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
            child: Stack(
              children: [
                WebViewWidget(controller: _webViewController!),
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.show_chart, color: Colors.white, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          '1 M',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 12,
                  left: 12,
                  child: IconButton(
                    icon: const Icon(Icons.fullscreen, color: Colors.white),
                    onPressed: () {},
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black.withOpacity(0.6),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Painel de Trading
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
                          'Montante: ${_stake.toStringAsFixed(2)} USDC',
                          () => _showStakeDialog(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildTradeOption('x$_multiplier', () => _showMultiplierDialog()),
                      const SizedBox(width: 8),
                      _buildTradeOption('Sem TP', () {}),
                      const SizedBox(width: 8),
                      _buildTradeOption('Sem SL', () {}),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Botões Up/Down
                  Row(
                    children: [
                      Expanded(
                        child: _buildTradeButton(
                          'Up',
                          '${_stake.toStringAsFixed(0)} USDC',
                          const Color(0xFF00C7BE),
                          Icons.arrow_upward,
                          () => _placeTrade('UP'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTradeButton(
                          'Down',
                          '${_stake.toStringAsFixed(0)} USDC',
                          const Color(0xFFFF4757),
                          Icons.arrow_downward,
                          () => _placeTrade('DOWN'),
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
      color: color,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a1a),
        title: const Text('Definir Montante', style: TextStyle(color: Colors.white)),
        content: TextField(
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Digite o valor',
            hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
            prefixText: '\$ ',
            prefixStyle: const TextStyle(color: Colors.white),
          ),
          onSubmitted: (value) {
            setState(() => _stake = double.tryParse(value) ?? 11.0);
            Navigator.pop(context);
          },
        ),
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