import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'styles.dart';

class BotsScreen extends StatefulWidget {
  final String token;
  
  const BotsScreen({Key? key, required this.token}) : super(key: key);

  @override
  State<BotsScreen> createState() => _BotsScreenState();
}

class _BotsScreenState extends State<BotsScreen> with AutomaticKeepAliveClientMixin {
  WebSocketChannel? _channel;
  WebViewController? _webViewController;
  bool _showChart = true;
  String _selectedStrategy = 'diff_accumulator';
  bool _botRunning = false;
  String _selectedMarket = 'R_100';
  List<int> _tickDigits = [];
  int _totalTrades = 0;
  double _profit = 0.0;
  int _winRate = 0;
  
  final Map<String, String> _strategies = {
    'diff_accumulator': 'Diff Accumulator',
    'martingale': 'Martingale',
    'anti_martingale': 'Anti-Martingale',
    'dalembert': 'D\'Alembert',
    'fibonacci': 'Fibonacci',
    'labouchere': 'Labouchere',
    'paroli': 'Paroli',
    'oscar_grind': 'Oscar\'s Grind',
    'reverse_martingale': 'Reverse Martingale',
    'one_three_two_six': '1-3-2-6 System',
    'win_loss_pattern': 'Win/Loss Pattern',
    'tick_prediction': 'Tick Prediction',
    'trend_following': 'Trend Following',
    'mean_reversion': 'Mean Reversion',
    'breakout': 'Breakout Strategy',
    'scalping': 'Scalping',
    'grid_trading': 'Grid Trading',
    'hedge': 'Hedge Strategy',
    'arbitrage': 'Arbitrage',
    'momentum': 'Momentum',
    'volatility': 'Volatility Trading',
  };

  final Map<String, String> _markets = {
    'R_100': 'Volatility 100',
    'R_50': 'Volatility 50',
    'R_25': 'Volatility 25',
    'R_10': 'Volatility 10',
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
    const container = document.getElementById('chart');
    const chart = LightweightCharts.createChart(container, {
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
      rightPriceScale: { borderColor: '#1a1a1a' },
      timeScale: { borderColor: '#1a1a1a', timeVisible: true },
    });

    const series = chart.addCandlestickSeries({
      upColor: '#00C7BE',
      downColor: '#FF4757',
      borderVisible: false,
      wickUpColor: '#00C7BE',
      wickDownColor: '#FF4757',
    });

    const ws = new WebSocket('wss://ws.derivws.com/websockets/v3?app_id=71954');
    let candles = [];

    ws.onopen = () => {
      ws.send(JSON.stringify({
        ticks_history: '$_selectedMarket',
        adjust_start_time: 1,
        count: 500,
        end: 'latest',
        start: 1,
        style: 'candles',
        granularity: 60
      }));
    };

    ws.onmessage = (e) => {
      const data = JSON.parse(e.data);
      if (data.msg_type === 'candles' || data.msg_type === 'history') {
        candles = (data.candles || []).map(c => ({
          time: c.epoch,
          open: parseFloat(c.open),
          high: parseFloat(c.high),
          low: parseFloat(c.low),
          close: parseFloat(c.close)
        }));
        series.setData(candles);
      }
    };

    window.addEventListener('resize', () => {
      chart.applyOptions({
        width: window.innerWidth,
        height: window.innerHeight
      });
    });
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

      _channel!.stream.listen((message) {
        final data = json.decode(message);
        if (data['msg_type'] == 'tick') {
          final price = double.parse(data['tick']['quote'].toString());
          final digit = ((price * 100).toInt() % 10);
          setState(() {
            _tickDigits.add(digit);
            if (_tickDigits.length > 100) _tickDigits.removeAt(0);
          });
        }
      });

      _channel!.sink.add(json.encode({
        'ticks': _selectedMarket,
        'subscribe': 1,
      }));
    } catch (e) {
      print('Erro WebSocket: $e');
    }
  }

  List<Map<String, dynamic>> _getDigitStats() {
    if (_tickDigits.isEmpty) return [];
    
    final counts = List.filled(10, 0);
    for (var digit in _tickDigits) {
      counts[digit]++;
    }
    
    final total = _tickDigits.length;
    return List.generate(10, (i) => {
      'digit': i,
      'count': counts[i],
      'percentage': (counts[i] / total * 100).toStringAsFixed(1),
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    final digitStats = _getDigitStats();
    final maxCount = digitStats.isEmpty ? 1 : digitStats.map((e) => e['count'] as int).reduce((a, b) => a > b ? a : b);
    
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF141414),
        title: const Text('Trading Bots'),
        actions: [
          IconButton(
            icon: Icon(_showChart ? Icons.bar_chart : Icons.show_chart),
            onPressed: () => setState(() => _showChart = !_showChart),
          ),
        ],
      ),
      body: Column(
        children: [
          // Gráfico ou Análise de Dígitos
          Expanded(
            flex: 2,
            child: _showChart 
              ? WebViewWidget(controller: _webViewController!)
              : Container(
                  color: const Color(0xFF0A0A0A),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Análise de Últimos Dígitos',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_tickDigits.length} ticks analisados',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: digitStats.isEmpty
                          ? const Center(
                              child: Text(
                                'Aguardando dados...',
                                style: TextStyle(color: Colors.white54),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: digitStats.map((stat) {
                                final height = (stat['count'] as int) / maxCount;
                                final color = _getDigitColor(stat['digit'] as int);
                                
                                return Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 2),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text(
                                          '${stat['percentage']}%',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 11,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Expanded(
                                          child: Container(
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              color: color,
                                              borderRadius: const BorderRadius.vertical(
                                                top: Radius.circular(4),
                                              ),
                                            ),
                                            alignment: Alignment.bottomCenter,
                                            child: FractionallySizedBox(
                                              heightFactor: height,
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: color,
                                                  borderRadius: const BorderRadius.vertical(
                                                    top: Radius.circular(4),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${stat['digit']}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
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

          // Painel de Controle do Bot
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF141414),
                border: Border(
                  top: BorderSide(color: Color(0xFF1a1a1a), width: 1),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Mercado
                    const Text(
                      'Mercado',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedMarket,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        filled: true,
                        fillColor: const Color(0xFF1a1a1a),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      dropdownColor: const Color(0xFF1a1a1a),
                      style: const TextStyle(color: Colors.white),
                      items: _markets.entries.map((e) => DropdownMenuItem(
                        value: e.key,
                        child: Text(e.value),
                      )).toList(),
                      onChanged: (v) => setState(() => _selectedMarket = v!),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Estratégia
                    const Text(
                      'Estratégia',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedStrategy,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        filled: true,
                        fillColor: const Color(0xFF1a1a1a),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      dropdownColor: const Color(0xFF1a1a1a),
                      style: const TextStyle(color: Colors.white),
                      items: _strategies.entries.map((e) => DropdownMenuItem(
                        value: e.key,
                        child: Text(e.value),
                      )).toList(),
                      onChanged: (v) => setState(() => _selectedStrategy = v!),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Estatísticas
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Trades',
                            _totalTrades.toString(),
                            Icons.swap_horiz,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Lucro',
                            '\$${_profit.toStringAsFixed(2)}',
                            Icons.attach_money,
                            valueColor: _profit >= 0 ? AppStyles.green : AppStyles.red,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),
                    
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Win Rate',
                            '$_winRate%',
                            Icons.trending_up,
                            valueColor: _winRate >= 50 ? AppStyles.green : AppStyles.red,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Status',
                            _botRunning ? 'Ativo' : 'Parado',
                            _botRunning ? Icons.play_circle : Icons.stop_circle,
                            valueColor: _botRunning ? AppStyles.green : Colors.white54,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Botão Iniciar/Parar
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _botRunning = !_botRunning;
                            if (_botRunning) {
                              AppStyles.showSnackBar(context, 'Bot iniciado com $_selectedStrategy');
                            } else {
                              AppStyles.showSnackBar(context, 'Bot parado', isError: true);
                            }
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _botRunning ? AppStyles.red : AppStyles.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _botRunning ? 'PARAR BOT' : 'INICIAR BOT',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, {Color? valueColor}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a1a),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.white54),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getDigitColor(int digit) {
    final colors = [
      const Color(0xFF007AFF), // 0
      const Color(0xFF30D158), // 1
      const Color(0xFFFF453A), // 2
      const Color(0xFFFFD60A), // 3
      const Color(0xFFBF5AF2), // 4
      const Color(0xFF00C7BE), // 5
      const Color(0xFFFF9F0A), // 6
      const Color(0xFF5E5CE6), // 7
      const Color(0xFFFF375F), // 8
      const Color(0xFF32D74B), // 9
    ];
    return colors[digit];
  }
}