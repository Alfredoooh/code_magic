import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'styles.dart';
import 'bot_config_screen.dart';
import 'bot_strategies.dart';
import 'bot_engine.dart';
import 'markets_data.dart';
import 'trade_history_screen.dart';

class BotsScreen extends StatefulWidget {
  final String token;
  
  const BotsScreen({Key? key, required this.token}) : super(key: key);

  @override
  State<BotsScreen> createState() => _BotsScreenState();
}

class _BotsScreenState extends State<BotsScreen> with AutomaticKeepAliveClientMixin {
  WebSocketChannel? _channel;
  WebViewController? _webViewController;
  String _chartView = 'candles';
  String _selectedMarket = 'R_100';
  List<int> _tickDigits = [];
  double _currentPrice = 0.0;
  
  BotEngine? _botEngine;
  BotConfig _botConfig = BotConfig();
  List<TradeResult> _tradeHistory = [];
  
  final Map<String, String> _strategies = {
    'auto_trade_fall_rise': 'Auto Trade: Queda → Subida 1min',
    'auto_trade_fall_down': 'Auto Trade: Queda → Descida 1min',
    'accumulation_advanced': 'Acumulação Avançada Pro',
    'loss_recovery_zero': 'Recuperação Perda Sem Lucro',
    'loss_recovery_profit': 'Recuperação Perda + Lucro',
    'smart_martingale': 'Martingale Inteligente',
    'anti_martingale_pro': 'Anti-Martingale Pro',
    'fibonacci_advanced': 'Fibonacci Avançado',
    'grid_trading_dynamic': 'Grid Trading Dinâmico',
    'scalping_ultra': 'Scalping Ultra Rápido',
    'trend_ai': 'Tendência com IA',
    'breakout_advanced': 'Breakout Avançado',
    'mean_reversion_pro': 'Mean Reversion Pro',
    'volatility_hunter': 'Caçador de Volatilidade',
    'arbitrage_multi': 'Arbitragem Multi-Mercado',
    'hedge_dynamic': 'Hedge Dinâmico',
    'momentum_accelerated': 'Momentum Acelerado',
    'pattern_recognition': 'Reconhecimento de Padrões',
    'price_action_pro': 'Price Action Profissional',
    'volume_analysis': 'Análise de Volume',
  };

  final Map<String, String> _markets = {
    // Volatility Indices
    'R_10': 'Volatility 10 Index',
    'R_25': 'Volatility 25 Index',
    'R_50': 'Volatility 50 Index',
    'R_75': 'Volatility 75 Index',
    'R_100': 'Volatility 100 Index',
    '1HZ10V': 'Volatility 10 (1s) Index',
    '1HZ25V': 'Volatility 25 (1s) Index',
    '1HZ50V': 'Volatility 50 (1s) Index',
    '1HZ75V': 'Volatility 75 (1s) Index',
    '1HZ100V': 'Volatility 100 (1s) Index',
    
    // Crash/Boom Indices
    'BOOM1000': 'Boom 1000 Index',
    'BOOM500': 'Boom 500 Index',
    'BOOM300': 'Boom 300 Index',
    'CRASH1000': 'Crash 1000 Index',
    'CRASH500': 'Crash 500 Index',
    'CRASH300': 'Crash 300 Index',
    
    // Step Indices
    'stpRNG': 'Step Index',
    
    // Jump Indices
    'JD10': 'Jump 10 Index',
    'JD25': 'Jump 25 Index',
    'JD50': 'Jump 50 Index',
    'JD75': 'Jump 75 Index',
    'JD100': 'Jump 100 Index',
    
    // Range Break Indices
    'RDBEAR': 'Range Break Bear',
    'RDBULL': 'Range Break Bull',
    
    // Forex Majors
    'frxEURUSD': 'EUR/USD',
    'frxGBPUSD': 'GBP/USD',
    'frxUSDJPY': 'USD/JPY',
    'frxAUDUSD': 'AUD/USD',
    'frxUSDCHF': 'USD/CHF',
    'frxUSDCAD': 'USD/CAD',
    'frxNZDUSD': 'NZD/USD',
    'frxEURGBP': 'EUR/GBP',
    'frxEURJPY': 'EUR/JPY',
    'frxGBPJPY': 'GBP/JPY',
    
    // Commodities
    'frxXAUUSD': 'Gold/USD',
    'frxXAGUSD': 'Silver/USD',
    'frxBROUSD': 'Oil/USD',
    
    // Crypto
    'cryBTCUSD': 'Bitcoin',
    'cryETHUSD': 'Ethereum',
    'cryLTCUSD': 'Litecoin',
    'cryBCHUSD': 'Bitcoin Cash',
    
    // Stock Indices
    'OTC_AEX': 'Netherlands 25',
    'OTC_AS51': 'Australia 200',
    'OTC_DJI': 'Wall Street 30',
    'OTC_FCHI': 'France 40',
    'OTC_FTSE': 'UK 100',
    'OTC_GDAXI': 'Germany 40',
    'OTC_HSI': 'Hong Kong 50',
    'OTC_N225': 'Japan 225',
    'OTC_SPC': 'US 500',
    'OTC_SSMI': 'Swiss 20',
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
    _botEngine?.stop();
    super.dispose();
  }

  void _initBotEngine() {
    _botEngine = BotEngine(
      config: _botConfig,
      market: _selectedMarket,
      onTrade: (trade) {
        setState(() {
          _tradeHistory.add(trade);
        });
      },
      onLog: (log) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(log),
              duration: const Duration(seconds: 2),
              backgroundColor: const Color(0xFF141414),
            ),
          );
        }
      },
    );
  }

  void _initWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0A0A0A))
      ..addJavaScriptChannel(
        'PriceChannel',
        onMessageReceived: (JavaScriptMessage message) {
          final data = json.decode(message.message);
          if (data['type'] == 'price') {
            setState(() => _currentPrice = data['price']);
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
    class ChartManager {
      constructor() {
        this.chart = null;
        this.series = null;
        this.ws = null;
        this.symbol = '$_selectedMarket';
        this.interval = 60;
        this.type = 'candlestick';
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
          rightPriceScale: { borderColor: '#1a1a1a' },
          timeScale: { borderColor: '#1a1a1a', timeVisible: true },
        });

        this.createSeries();
        this.connect();

        window.addEventListener('resize', () => {
          this.chart.applyOptions({
            width: window.innerWidth,
            height: window.innerHeight
          });
        });
      }

      createSeries() {
        if (this.series) this.chart.removeSeries(this.series);

        if (this.type === 'candlestick') {
          this.series = this.chart.addCandlestickSeries({
            upColor: '#00C7BE',
            downColor: '#FF4757',
            borderVisible: false,
            wickUpColor: '#00C7BE',
            wickDownColor: '#FF4757',
          });
        } else if (this.type === 'line') {
          this.series = this.chart.addLineSeries({
            color: '#007AFF',
            lineWidth: 2,
          });
        } else if (this.type === 'area') {
          this.series = this.chart.addAreaSeries({
            topColor: 'rgba(0, 122, 255, 0.4)',
            bottomColor: 'rgba(0, 122, 255, 0)',
            lineColor: '#007AFF',
            lineWidth: 2,
          });
        }

        if (this.candles.length > 0) this.updateChart();
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
          count: 500,
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

          if (this.candles.length > 500) this.candles.shift();
          this.updateChart();
          this.sendPrice(price);
        }
      }

      updateChart() {
        if (!this.series || this.candles.length === 0) return;
        
        if (this.type === 'candlestick') {
          this.series.setData(this.candles);
        } else {
          const data = this.candles.map(c => ({
            time: c.time,
            value: c.close
          }));
          this.series.setData(data);
        }
        
        this.chart.timeScale().fitContent();
      }

      sendPrice(price) {
        PriceChannel.postMessage(JSON.stringify({
          type: 'price',
          price: price
        }));
      }

      changeMarket(symbol) {
        this.symbol = symbol;
        this.candles = [];
        this.subscribe();
      }

      changeType(type) {
        this.type = type;
        this.createSeries();
      }
    }

    const chartManager = new ChartManager();
    window.chartManager = chartManager;
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
          setState(() => _currentPrice = price);
          
          final digit = ((price * 100).toInt() % 10);
          setState(() {
            _tickDigits.add(digit);
            if (_tickDigits.length > 100) _tickDigits.removeAt(0);
          });
          
          // Processar tick no bot engine
          _botEngine?.processTick(price);
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
      'percentage': (counts[i] / total * 100),
    });
  }

  void _changeMarket(String market) {
    setState(() => _selectedMarket = market);
    _webViewController?.runJavaScript('chartManager.changeMarket("$market")');
    _channel?.sink.add(json.encode({'forget_all': 'ticks'}));
    Future.delayed(const Duration(milliseconds: 200), () {
      _channel?.sink.add(json.encode({
        'ticks': market,
        'subscribe': 1,
      }));
    });
    
    // Reiniciar bot engine com novo mercado
    if (_botEngine?.isRunning ?? false) {
      _botEngine?.stop();
      _initBotEngine();
      _botEngine?.start();
    }
  }

  void _openConfigScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BotConfigScreen(
          initialConfig: _botConfig,
          onSave: (config) {
            setState(() => _botConfig = config);
            _initBotEngine();
            AppStyles.showSnackBar(context, 'Configurações salvas!');
          },
        ),
      ),
    );
  }

  void _changeChartType(String type) {
    setState(() => _chartView = type);
    if (type != 'bars') {
      _webViewController?.runJavaScript('chartManager.changeType("$type")');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    final digitStats = _getDigitStats();
    final maxPercentage = digitStats.isEmpty ? 1.0 : digitStats.map((e) => e['percentage'] as double).reduce((a, b) => a > b ? a : b);
    
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF141414),
        title: const Text('Trading Bots Pro'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            onPressed: _openConfigScreen,
            tooltip: 'Configurações Avançadas',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.show_chart_rounded),
            onSelected: _changeChartType,
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'candles', child: Text('Candlestick')),
              const PopupMenuItem(value: 'bars', child: Text('Barras (Dígitos)')),
              const PopupMenuItem(value: 'line', child: Text('Linha')),
              const PopupMenuItem(value: 'area', child: Text('Área')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Gráfico ou Análise de Dígitos
          Expanded(
            flex: 2,
            child: _chartView == 'bars'
              ? _buildDigitBars(digitStats, maxPercentage)
              : WebViewWidget(controller: _webViewController!),
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
                    // Seletor de Mercado por Categoria
                    _buildMarketSelector(),
                    
                    const SizedBox(height: 16),
                    
                    // Preço Atual e Status
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoCard(
                            'Preço Atual',
                            '\$${_currentPrice.toStringAsFixed(2)}',
                            Icons.attach_money_rounded,
                            color: const Color(0xFF007AFF),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildInfoCard(
                            'Bot Status',
                            (_botEngine?.isRunning ?? false) ? 'Ativo' : 'Parado',
                            (_botEngine?.isRunning ?? false) ? Icons.play_circle_rounded : Icons.stop_circle_rounded,
                            color: (_botEngine?.isRunning ?? false) ? AppStyles.green : Colors.white54,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Estatísticas
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Trades',
                            (_botEngine?.tradesCount ?? 0).toString(),
                            Icons.swap_horiz_rounded,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Lucro',
                            '\$${(_botEngine?.totalProfit ?? 0.0).toStringAsFixed(2)}',
                            Icons.attach_money_rounded,
                            valueColor: (_botEngine?.totalProfit ?? 0) >= 0 ? AppStyles.green : AppStyles.red,
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
                            '${_botEngine?.winRate ?? 0}%',
                            Icons.trending_up_rounded,
                            valueColor: (_botEngine?.winRate ?? 0) >= 50 ? AppStyles.green : AppStyles.red,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            'Histórico',
                            _tradeHistory.length.toString(),
                            Icons.history_rounded,
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Botões de Controle
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 56,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                if (_botEngine == null) _initBotEngine();
                                
                                setState(() {
                                  if (_botEngine!.isRunning) {
                                    _botEngine!.stop();
                                    AppStyles.showSnackBar(context, 'Bot parado', isError: true);
                                  } else {
                                    _botEngine!.start();
                                    AppStyles.showSnackBar(context, 'Bot iniciado!');
                                  }
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: (_botEngine?.isRunning ?? false) ? AppStyles.red : AppStyles.green,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: Icon((_botEngine?.isRunning ?? false) ? Icons.stop_rounded : Icons.play_arrow_rounded),
                              label: Text(
                                (_botEngine?.isRunning ?? false) ? 'PARAR' : 'INICIAR',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          height: 56,
                          width: 56,
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _botEngine?.reset();
                                _tradeHistory.clear();
                              });
                              AppStyles.showSnackBar(context, 'Bot resetado');
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1a1a1a),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            child: const Icon(Icons.refresh_rounded, size: 28),
                          ),
                        ),
                      ],
                    ),
                    
                    if (_tradeHistory.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Últimos Trades',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TradeHistoryScreen(
                                    trades: _tradeHistory,
                                    stats: _botEngine?.getStats() ?? {},
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.history_rounded, size: 18),
                            label: const Text('Ver Tudo'),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF007AFF),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ..._tradeHistory.reversed.take(5).map((trade) => _buildTradeItem(trade)),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDigitBars(List<Map<String, dynamic>> digitStats, double maxPercentage) {
    return Container(
      color: const Color(0xFF0A0A0A),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Análise de Últimos Dígitos',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${_tickDigits.length} ticks',
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 13,
                ),
              ),
            ],
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
                    final percentage = stat['percentage'] as double;
                    final height = percentage / maxPercentage;
                    final color = _getBarColor(percentage, maxPercentage);
                    
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              '${percentage.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Expanded(
                              child: Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.transparent,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(6),
                                  ),
                                ),
                                alignment: Alignment.bottomCenter,
                                child: FractionallySizedBox(
                                  heightFactor: height,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: color,
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(6),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: color.withOpacity(0.4),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: color, width: 2),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${stat['digit']}',
                                style: TextStyle(
                                  color: color,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
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
    );
  }

  Color _getBarColor(double percentage, double maxPercentage) {
    final ratio = percentage / maxPercentage;
    if (ratio > 0.8) return const Color(0xFF00C7BE); // Alto - Ciano
    if (ratio > 0.6) return const Color(0xFF007AFF); // Médio-Alto - Azul
    if (ratio > 0.4) return const Color(0xFFFFD60A); // Médio - Amarelo
    if (ratio > 0.2) return const Color(0xFFFF9F0A); // Médio-Baixo - Laranja
    return const Color(0xFFFF4757); // Baixo - Vermelho
  }

  Widget _buildMarketSelector() {
    final categories = MarketData.getAllCategories();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Selecionar Mercado',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final category = categories[index];
              final marketInfo = MarketData.getMarketInfo(_selectedMarket);
              final isSelected = marketInfo?['category'] == category;
              
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      final markets = MarketData.getMarketsByCategory(category);
                      if (markets.isNotEmpty) {
                        _changeMarket(markets.first);
                      }
                    }
                  },
                  backgroundColor: const Color(0xFF1a1a1a),
                  selectedColor: const Color(0xFF007AFF),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
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
          style: const TextStyle(color: Colors.white, fontSize: 14),
          items: _markets.entries.map((e) => DropdownMenuItem(
            value: e.key,
            child: Text(e.value),
          )).toList(),
          onChanged: (v) => _changeMarket(v!),
        ),
      ],
    );
  }
  
  Widget _buildInfoCard(String label, String value, IconData icon, {Color? color}) {
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
              Icon(icon, size: 16, color: color ?? Colors.white54),
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
              color: color ?? Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
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
  
  Widget _buildTradeItem(TradeResult trade) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a1a),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: trade.won ? AppStyles.green.withOpacity(0.3) : AppStyles.red.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            trade.won ? Icons.check_circle_rounded : Icons.cancel_rounded,
            color: trade.won ? AppStyles.green : AppStyles.red,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      trade.direction,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '\$${trade.stake.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    if (trade.wasRecovery) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD60A).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'REC',
                          style: TextStyle(
                            color: Color(0xFFFFD60A),
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                    if (trade.accumulationLevel > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF007AFF).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'ACC ${trade.accumulationLevel}',
                          style: const TextStyle(
                            color: Color(0xFF007AFF),
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  trade.strategy,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${trade.profit >= 0 ? "+" : ""}\$${trade.profit.toStringAsFixed(2)}',
                style: TextStyle(
                  color: trade.won ? AppStyles.green : AppStyles.red,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${trade.timestamp.hour}:${trade.timestamp.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  color: Colors.white38,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}