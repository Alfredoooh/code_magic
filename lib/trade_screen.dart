// trade_screen.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
  WebSocketChannel? _channel;
  WebViewController? _webViewController;
  String _selectedMarket = 'R_100';
  String _contractType = 'MULTUP';
  double _currentPrice = 0.0;
  double _priceChange = 0.0;
  bool _isConnected = false;
  double _stake = 10.0;
  int _multiplier = 100;
  String _currency = 'USD';
  double _balance = 0.00;
  bool _isTrading = false;
  List<Map<String, dynamic>> _activePositions = [];
  double _estimatedPayout = 0.0;

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
    'BOOM600N': 'Boom 600',
    'BOOM900': 'Boom 900',
    'BOOM1000': 'Boom 1000',
    'CRASH300N': 'Crash 300',
    'CRASH500': 'Crash 500',
    'CRASH600N': 'Crash 600',
    'CRASH900': 'Crash 900',
    'CRASH1000': 'Crash 1000',
    'STPRNG': 'Step Index',
    'JD10': 'Jump 10',
    'JD25': 'Jump 25',
    'JD50': 'Jump 50',
    'JD75': 'Jump 75',
    'JD100': 'Jump 100',
  };

  @override
  void initState() {
    super.initState();
    if (widget.initialMarket != null) {
      _selectedMarket = widget.initialMarket!;
    }
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
    let chart, series, ws, symbol = '$_selectedMarket', candles = [];
    let isScrolling = false;
    
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
      
      series = chart.addCandlestickSeries({
        upColor: '#00C896',
        downColor: '#FF4444',
        wickUpColor: '#00C896',
        wickDownColor: '#FF4444',
      });
      
      chart.timeScale().subscribeVisibleLogicalRangeChange(() => {
        isScrolling = true;
        clearTimeout(window.scrollTimeout);
        window.scrollTimeout = setTimeout(() => {
          isScrolling = false;
        }, 2000);
      });
      
      connect();
      window.addEventListener('resize', () => {
        chart.applyOptions({ width: window.innerWidth, height: window.innerHeight });
      });
    }
    
    function connect() {
      ws = new WebSocket('wss://ws.derivws.com/websockets/v3?app_id=71954');
      ws.onopen = () => {
        ws.send(JSON.stringify({
          ticks_history: symbol,
          count: 500,
          end: 'latest',
          start: 1,
          style: 'candles',
          granularity: 60
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
          time: c.epoch,
          open: parseFloat(c.open),
          high: parseFloat(c.high),
          low: parseFloat(c.low),
          close: parseFloat(c.close)
        }));
        updateChart();
      } else if (data.tick) {
        const price = parseFloat(data.tick.quote);
        const time = data.tick.epoch;
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
      if (series && candles.length > 0) {
        series.setData(candles);
        if (!isScrolling) {
          chart.timeScale().scrollToRealTime();
        }
      }
    }
    
    function sendPrice(price) {
      if (candles.length > 1) {
        const prev = candles[candles.length - 2].close;
        const change = ((price - prev) / prev) * 100;
        FlutterChannel.postMessage(JSON.stringify({
          type: 'price',
          price: price,
          change: change
        }));
      }
    }
    
    function changeMarket(newSymbol) {
      symbol = newSymbol;
      candles = [];
      if (ws) ws.close();
      connect();
    }
    
    window.changeMarket = changeMarket;
    init();
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
              _currency = data['authorize']['currency'];
            });
          } else if (data['msg_type'] == 'proposal') {
            setState(() {
              _estimatedPayout = double.parse(data['proposal']['payout'].toString());
            });
          } else if (data['msg_type'] == 'buy') {
            final contract = data['buy'];
            setState(() {
              _activePositions.add({
                'contract_id': contract['contract_id'],
                'buy_price': contract['buy_price'],
                'payout': contract['payout'],
                'type': _contractType,
                'profit': 0.0,
              });
              _isTrading = false;
            });
            
            _channel!.sink.add(json.encode({
              'proposal_open_contract': 1,
              'contract_id': contract['contract_id'],
              'subscribe': 1,
            }));

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Trade aberto: ${contract['longcode']}'),
                backgroundColor: const Color(0xFF00C896),
                duration: const Duration(seconds: 2),
              ),
            );
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

      _channel!.sink.add(json.encode({'authorize': widget.token}));
    } catch (e) {
      setState(() => _isConnected = false);
    }
  }

  void _updatePosition(Map<String, dynamic> contract) {
    final index = _activePositions.indexWhere(
      (p) => p['contract_id'] == contract['contract_id']
    );
    
    if (index != -1) {
      setState(() {
        _activePositions[index]['profit'] = contract['profit'];
        _activePositions[index]['status'] = contract['status'];
        
        if (contract['status'] == 'won' || contract['status'] == 'lost') {
          final profit = contract['profit'];
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Trade ${contract['status'].toUpperCase()}: ${profit >= 0 ? '+' : ''}\$${profit.toStringAsFixed(2)}'
              ),
              backgroundColor: contract['status'] == 'won' 
                  ? const Color(0xFF00C896) 
                  : const Color(0xFFFF4444),
            ),
          );
          
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) {
              setState(() => _activePositions.removeAt(index));
            }
          });
        }
      });
    }
  }

  void _changeMarket(String market) {
    setState(() => _selectedMarket = market);
    _webViewController?.runJavaScript('changeMarket("$market")');
  }

  void _placeTrade(String type) {
    if (_isTrading || !_isConnected) return;
    
    setState(() {
      _isTrading = true;
      _contractType = type;
    });

    Map<String, dynamic> params = {
      'proposal': 1,
      'amount': _stake,
      'basis': 'stake',
      'contract_type': type,
      'currency': _currency,
      'symbol': _selectedMarket,
    };

    // Configurar parâmetros específicos por tipo de contrato
    if (type == 'MULTUP' || type == 'MULTDOWN') {
      params['multiplier'] = _multiplier;
    } else if (type == 'CALL' || type == 'PUT') {
      params['duration'] = 5;
      params['duration_unit'] = 't';
    } else if (type.startsWith('DIGIT')) {
      params['duration'] = 5;
      params['duration_unit'] = 't';
      if (type == 'DIGITMATCH' || type == 'DIGITDIFF') {
        params['barrier'] = '5';
      }
    }

    _channel!.sink.add(json.encode(params));

    Future.delayed(const Duration(milliseconds: 500), () {
      _channel!.sink.add(json.encode({
        'buy': 1,
        'price': _stake,
        'parameters': params,
      }));
    });
  }

  void _showTradeOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Tipo de Contrato',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(
              child: GridView.count(
                controller: scrollController,
                crossAxisCount: 2,
                padding: const EdgeInsets.all(16),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  _buildContractTypeCard('Up', Icons.arrow_upward, const Color(0xFF00C896), 'MULTUP'),
                  _buildContractTypeCard('Down', Icons.arrow_downward, const Color(0xFFFF4444), 'MULTDOWN'),
                  _buildContractTypeCard('Rise', Icons.trending_up, const Color(0xFF00C896), 'CALL'),
                  _buildContractTypeCard('Fall', Icons.trending_down, const Color(0xFFFF4444), 'PUT'),
                  _buildContractTypeCard('Even', Icons.looks_two, const Color(0xFF0066FF), 'DIGITEVEN'),
                  _buildContractTypeCard('Odd', Icons.looks_one, const Color(0xFF0066FF), 'DIGITODD'),
                  _buildContractTypeCard('Matches', Icons.check_circle, const Color(0xFF00C896), 'DIGITMATCH'),
                  _buildContractTypeCard('Differs', Icons.cancel, const Color(0xFFFF4444), 'DIGITDIFF'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContractTypeCard(String label, IconData icon, Color color, String type) {
    return GestureDetector(
      onTap: () {
        setState(() => _contractType = type);
        Navigator.pop(context);
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _contractType == type ? color : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: GestureDetector(
          onTap: () {
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
                    _changeMarket(e.key);
                    Navigator.pop(context);
                  },
                )).toList(),
              ),
            );
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _allMarkets[_selectedMarket] ?? '',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 4),
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
                  '${_balance.toStringAsFixed(2)} $_currency',
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
      ),
      body: Column(
        children: [
          // Gráfico
          Expanded(
            child: Stack(
              children: [
                WebViewWidget(controller: _webViewController!),
                // Posições ativas
                if (_activePositions.isNotEmpty)
                  Positioned(
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
                        children: _activePositions.map((pos) {
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
                  ),
              ],
            ),
          ),

          // Painel de Trading
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFF1A1A1A),
              border: Border(top: BorderSide(color: Color(0xFF2A2A2A))),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  // Opções de configuração
                  Row(
                    children: [
                      Expanded(
                        child: _buildOption(
                          'Stake: \$${_stake.toStringAsFixed(2)}',
                          () => _showStakeDialog(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildOption(
                          'Tipo: ${_getContractName()}',
                          () => _showTradeOptions(),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Botões de Trade
                  Row(
                    children: [
                      Expanded(
                        child: _buildTradeButton(
                          _getButtonLabel(true),
                          _estimatedPayout > 0 ? '+\$${_estimatedPayout.toStringAsFixed(2)}' : '\$${_stake.toStringAsFixed(2)}',
                          const Color(0xFF00C896),
                          () => _placeTrade(_contractType),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTradeButton(
                          _getButtonLabel(false),
                          _estimatedPayout > 0 ? '+\$${_estimatedPayout.toStringAsFixed(2)}' : '\$${_stake.toStringAsFixed(2)}',
                          const Color(0xFFFF4444),
                          () => _placeTrade(_getOppositeType()),
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

  String _getContractName() {
    switch (_contractType) {
      case 'MULTUP': return 'Up';
      case 'MULTDOWN': return 'Down';
      case 'CALL': return 'Rise';
      case 'PUT': return 'Fall';
      case 'DIGITEVEN': return 'Even';
      case 'DIGITODD': return 'Odd';
      case 'DIGITMATCH': return 'Match';
      case 'DIGITDIFF': return 'Differ';
      default: return 'Trade';
    }
  }

  String _getButtonLabel(bool isGreen) {
    if (_contractType == 'MULTUP' || _contractType == 'MULTDOWN') {
      return isGreen ? 'UP' : 'DOWN';
    } else if (_contractType == 'CALL' || _contractType == 'PUT') {
      return isGreen ? 'RISE' : 'FALL';
    } else if (_contractType == 'DIGITEVEN' || _contractType == 'DIGITODD') {
      return isGreen ? 'EVEN' : 'ODD';
    } else {
      return isGreen ? 'MATCHES' : 'DIFFERS';
    }
  }

  String _getOppositeType() {
    switch (_contractType) {
      case 'MULTUP': return 'MULTDOWN';
      case 'MULTDOWN': return 'MULTUP';
      case 'CALL': return 'PUT';
      case 'PUT': return 'CALL';
      case 'DIGITEVEN': return 'DIGITODD';
      case 'DIGITODD': return 'DIGITEVEN';
      case 'DIGITMATCH': return 'DIGITDIFF';
      case 'DIGITDIFF': return 'DIGITMATCH';
      default: return _contractType;
    }
  }

  Widget _buildOption(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildTradeButton(String label, String payout, Color color, VoidCallback onPressed) {
    return Material(
      color: _isTrading ? color.withOpacity(0.5) : color,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: _isTrading ? null : onPressed,
        borderRadius: BorderRadius.circular(12),
        splashColor: Colors.white.withOpacity(0.2),
        highlightColor: Colors.white.withOpacity(0.1),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            children: [
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
                payout,
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
}