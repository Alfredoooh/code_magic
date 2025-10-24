// lib/bots_screen_part2.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'bot_engine.dart';

// ========== BOT DETAILS SCREEN ==========

class BotDetailsScreen extends StatefulWidget {
  final TradingBot bot;
  final Map<String, List<WebViewController>> chartControllers;
  final Map<String, List<double>> marketPrices;
  final int chartPointsCount;

  const BotDetailsScreen({
    Key? key,
    required this.bot,
    required this.chartControllers,
    required this.marketPrices,
    required this.chartPointsCount,
  }) : super(key: key);

  @override
  State<BotDetailsScreen> createState() => _BotDetailsScreenState();
}

class _BotDetailsScreenState extends State<BotDetailsScreen> {
  String _selectedChart = 'profit';

  @override
  Widget build(BuildContext context) {
    final status = widget.bot.getStatus();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: Text(widget.bot.config.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _showSettings(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusCard(status),
            const SizedBox(height: 16),
            _buildChartSelector(),
            const SizedBox(height: 16),
            _buildMainChart(status),
            const SizedBox(height: 16),
            _buildStatisticsGrid(status),
            const SizedBox(height: 16),
            _buildTradeHistory(status),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(BotStatus status) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Session Profit',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${status.sessionProfit >= 0 ? '+' : ''}\$${status.sessionProfit.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: status.sessionProfit >= 0 
                          ? const Color(0xFF00C896) 
                          : const Color(0xFFFF4444),
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: status.isRunning 
                      ? const Color(0xFF00C896).withOpacity(0.12)
                      : Colors.white.withOpacity(0.06),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  status.isRunning ? Icons.play_arrow : Icons.pause,
                  color: status.isRunning ? const Color(0xFF00C896) : Colors.white54,
                  size: 32,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildQuickStat('Win Rate', '${(status.winRate * 100).toStringAsFixed(1)}%'),
              ),
              Expanded(
                child: _buildQuickStat('Trades', status.totalTrades.toString()),
              ),
              Expanded(
                child: _buildQuickStat('Streak', '${status.consecutiveWins - status.consecutiveLosses}'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
      ],
    );
  }

  Widget _buildChartSelector() {
    return Row(
      children: [
        _buildChartButton('profit', 'Profit', Icons.trending_up),
        const SizedBox(width: 8),
        _buildChartButton('winrate', 'Win Rate', Icons.pie_chart),
        const SizedBox(width: 8),
        _buildChartButton('stake', 'Stake', Icons.attach_money),
      ],
    );
  }

  Widget _buildChartButton(String id, String label, IconData icon) {
    final isSelected = _selectedChart == id;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedChart = id),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0066FF) : const Color(0xFF2A2A2A),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainChart(BotStatus status) {
    if (status.tradeHistory.isEmpty) {
      return Container(
        height: 250,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text('Sem dados ainda', style: TextStyle(color: Colors.white54)),
        ),
      );
    }

    return Container(
      height: 250,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: _selectedChart == 'profit'
          ? _buildProfitChart(status.tradeHistory)
          : _selectedChart == 'winrate'
              ? _buildWinRateChart(status.tradeHistory)
              : _buildStakeChart(status.tradeHistory),
    );
  }

  Widget _buildProfitChart(List<TradeRecord> history) {
    final cumulative = <double>[];
    double sum = 0;

    for (var trade in history) {
      sum += trade.profit;
      cumulative.add(sum);
    }

    return DerivAreaChart(
      points: cumulative,
      autoScale: true,
      showGradient: false,
      market: widget.bot.config.market,
      onControllerCreated: (controller, market) {
        if (market == null) return;
        _registerControllerForMarket(controller, market);
      },
      height: 200,
    );
  }

  void _registerControllerForMarket(WebViewController controller, String market) {
    widget.chartControllers.putIfAbsent(market, () => []);
    if (!widget.chartControllers[market]!.contains(controller)) {
      widget.chartControllers[market]!.add(controller);
      
      final allPoints = widget.marketPrices[market] ?? [];
      final lastPoints = allPoints.length > widget.chartPointsCount
          ? allPoints.sublist(allPoints.length - widget.chartPointsCount)
          : allPoints;
      
      if (lastPoints.isNotEmpty) {
        final jsArray = lastPoints.map((p) => p.toString()).join(',');
        final script = "try{ updateData([${jsArray}]); }catch(e){};";
        try {
          controller.runJavaScript(script);
        } catch (_) {}
      }
    }
  }

  Widget _buildWinRateChart(List<TradeRecord> history) {
    final windowSize = 10;
    final winRates = <double>[];

    for (int i = windowSize; i <= history.length; i++) {
      final window = history.sublist(i - windowSize, i);
      final wins = window.where((t) => t.won).length;
      winRates.add(wins / windowSize * 100);
    }

    return DerivAreaChart(
      points: winRates,
      autoScale: false,
      showGradient: false,
      market: widget.bot.config.market,
      onControllerCreated: (controller, market) {
        if (market == null) return;
        _registerControllerForMarket(controller, market);
      },
      height: 200,
    );
  }

  Widget _buildStakeChart(List<TradeRecord> history) {
    final stakes = history.map((t) => t.stake).toList();

    return DerivAreaChart(
      points: stakes,
      autoScale: true,
      showGradient: false,
      market: widget.bot.config.market,
      onControllerCreated: (controller, market) {
        if (market == null) return;
        _registerControllerForMarket(controller, market);
      },
      height: 200,
    );
  }

  Widget _buildStatisticsGrid(BotStatus status) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard('Total Profit', '\$${status.totalProfit.toStringAsFixed(2)}', 
            status.totalProfit >= 0 ? const Color(0xFF00C896) : const Color(0xFFFF4444)),
        _buildStatCard('Avg Win', '\$${status.avgWin.toStringAsFixed(2)}', const Color(0xFF00C896)),
        _buildStatCard('Avg Loss', '\$${status.avgLoss.toStringAsFixed(2)}', const Color(0xFFFF4444)),
        _buildStatCard('Max Drawdown', '${(status.maxDrawdown * 100).toStringAsFixed(1)}%', Colors.orange),
        _buildStatCard('Current RSI', status.currentRSI.toStringAsFixed(0), const Color(0xFF0066FF)),
        _buildStatCard('Current Stake', '\$${status.currentStake.toStringAsFixed(2)}', Colors.white70),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            value,
            style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTradeHistory(BotStatus status) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Trades',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: status.tradeHistory.take(20).length,
          itemBuilder: (context, index) {
            final trade = status.tradeHistory[status.tradeHistory.length - 1 - index];
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: trade.won ? const Color(0xFF00C896).withOpacity(0.3) : const Color(0xFFFF4444).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: trade.won ? const Color(0xFF00C896).withOpacity(0.2) : const Color(0xFFFF4444).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      trade.won ? Icons.trending_up : Icons.trending_down,
                      color: trade.won ? const Color(0xFF00C896) : const Color(0xFFFF4444),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trade.won ? 'WIN' : 'LOSS',
                          style: TextStyle(
                            color: trade.won ? const Color(0xFF00C896) : const Color(0xFFFF4444),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${trade.timestamp.hour}:${trade.timestamp.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(color: Colors.white54, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${trade.profit >= 0 ? '+' : ''}\$${trade.profit.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: trade.won ? const Color(0xFF00C896) : const Color(0xFFFF4444),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Stake: \$${trade.stake.toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.white54, fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Bot Settings',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            const Text('Settings coming soon...', style: TextStyle(color: Colors.white54)),
          ],
        ),
      ),
    );
  }
}

// ========== CREATE BOT SCREEN ==========

class CreateBotScreen extends StatefulWidget {
  final WebSocketChannel channel;
  final Function(TradingBot) onBotCreated;

  const CreateBotScreen({
    Key? key,
    required this.channel,
    required this.onBotCreated,
  }) : super(key: key);

  @override
  State<CreateBotScreen> createState() => _CreateBotScreenState();
}

class _CreateBotScreenState extends State<CreateBotScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  double _initialStake = 10.0;
  BotStrategy _selectedStrategy = BotStrategy.martingale;
  String _selectedMarket = 'R_100';
  String _contractType = 'CALL';
  RecoveryMode _recoveryMode = RecoveryMode.moderate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Create Custom Bot'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Bot Name',
                labelStyle: TextStyle(color: Colors.white54),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Description',
                labelStyle: TextStyle(color: Colors.white54),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            const Text('Initial Stake', style: TextStyle(color: Colors.white, fontSize: 16)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Text(
                      '\$${_initialStake.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _openStakeModal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0066FF),
                    minimumSize: const Size(120, 48),
                  ),
                  child: const Text('Alterar Stake'),
                ),
              ],
            ),

            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _createBot,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0066FF),
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('Create Bot'),
            ),
          ],
        ),
      ),
    );
  }

  void _openStakeModal() {
    final controller = TextEditingController(text: _initialStake.toStringAsFixed(2));
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Definir Initial Stake', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                prefixText: '\$ ',
                prefixStyle: const TextStyle(color: Colors.white70, fontSize: 20),
                hintText: '0.00',
                hintStyle: const TextStyle(color: Colors.white24),
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Colors.white24),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: Color(0xFF0066FF), width: 2),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFF2A2A2A),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      final value = double.tryParse(controller.text.replaceAll(',', '.'));
                      if (value != null && value >= 0.01) {
                        setState(() {
                          _initialStake = value;
                        });
                        Navigator.pop(context);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Insira um valor válido (>= 0.01)'), backgroundColor: Colors.orange),
                        );
                      }
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: const Color(0xFF0066FF),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('OK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _createBot() {
    final bot = TradingBot(
      config: BotConfiguration(
        name: _nameController.text.isEmpty ? 'Custom Bot' : _nameController.text,
        description: _descriptionController.text.isEmpty ? 'Custom strategy' : _descriptionController.text,
        strategy: _selectedStrategy,
        initialStake: _initialStake,
        market: _selectedMarket,
        contractType: _contractType,
        recoveryMode: _recoveryMode,
      ),
      channel: widget.channel,
      onStatusUpdate: (_) {},
    );

    widget.onBotCreated(bot);
    Navigator.pop(context);
  }
}

// =====================
// DerivAreaChart widget
// =====================

class DerivAreaChart extends StatefulWidget {
  final List<double> points;
  final bool autoScale;
  final bool showGradient;
  final double? height;
  final String? market;
  final void Function(WebViewController controller, String? market)? onControllerCreated;

  const DerivAreaChart({
    Key? key,
    required this.points,
    this.autoScale = true,
    this.showGradient = false,
    this.height,
    this.market,
    this.onControllerCreated,
  }) : super(key: key);

  @override
  State<DerivAreaChart> createState() => _DerivAreaChartState();
}

class _DerivAreaChartState extends State<DerivAreaChart> {
  late final WebViewController _controller;
  String get _initialHtml => _buildHtml(widget.points, widget.autoScale, widget.showGradient);

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF1A1A1A))
      ..addJavaScriptChannel('FlutterChannel', onMessageReceived: (message) {})
      ..loadHtmlString(_initialHtml);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.onControllerCreated != null) {
        widget.onControllerCreated!(_controller, widget.market);
      }
    });
  }

  @override
  void didUpdateWidget(covariant DerivAreaChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    final jsArray = widget.points.map((p) => p.toString()).join(',');
    final script = "try{ updateData([${jsArray}]); }catch(e){};";
    _controller.runJavaScript(script);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height ?? 180,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: WebViewWidget(controller: _controller),
      ),
    );
  }

  String _buildHtml(List<double> points, bool autoScale, bool showGradient) {
    final initialData = points.map((p) => p.toString()).join(',');
    return '''
<!doctype html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <style>
    html, body { margin:0; padding:0; background:#0F0F0F; }
    #chart { width:100%; height:100%; }
    canvas { display:block; }
  </style>
</head>
<body>
  <canvas id="chart"></canvas>
  <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
  <script>
    const ctx = document.getElementById('chart').getContext('2d');
    Chart.defaults.font.family = 'Arial';
    Chart.defaults.color = '#FFFFFF';
    const dataPoints = [${initialData}];
    const labels = dataPoints.map((_, i) => i.toString());

    const config = {
      type: 'line',
      data: {
        labels: labels,
        datasets: [{
          label: '',
          data: dataPoints,
          fill: ${showGradient ? 'true' : 'false'},
          backgroundColor: '${showGradient ? 'rgba(0,200,150,0.12)' : 'rgba(0,0,0,0)'}',
          borderColor: dataPoints.length>1 && dataPoints[dataPoints.length-1] >= dataPoints[dataPoints.length-2] ? '#00C896' : '#FF4444',
          tension: 0.25,
          pointRadius: 0,
          borderWidth: 2,
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        animation: false,
        scales: {
          x: { display: false },
          y: {
            display: false,
            beginAtZero: ${autoScale ? 'false' : 'true'}
          }
        },
        plugins: {
          legend: { display: false },
          tooltip: { enabled: false }
        }
      }
    };

    const myChart = new Chart(ctx, config);

    function updateData(newPoints) {
      try {
        const labels = newPoints.map((_, i) => i.toString());
        myChart.data.labels = labels;
        myChart.data.datasets[0].data = newPoints;
        if (newPoints.length >= 2) {
          const last = newPoints[newPoints.length - 1];
          const prev = newPoints[newPoints.length - 2];
          myChart.data.datasets[0].borderColor = last >= prev ? '#00C896' : '#FF4444';
        }
        myChart.update();
      } catch (e) {
        console.log('updateData error', e);
      }
    }

    window.updateData = updateData;
  </script>
</body>
</html>
''';
  }
}