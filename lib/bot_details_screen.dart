// lib/bot_details_screen.dart
// Tela de detalhes e controle do bot com chart em tempo real
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'bot_engine.dart';
import 'deriv_chart_widget.dart';

class BotDetailsScreen extends StatefulWidget {
  final TradingBot bot;
  final Function() onUpdate;
  final Map<String, List<double>> marketPrices;

  const BotDetailsScreen({
    Key? key,
    required this.bot,
    required this.onUpdate,
    required this.marketPrices,
  }) : super(key: key);

  @override
  State<BotDetailsScreen> createState() => _BotDetailsScreenState();
}

class _BotDetailsScreenState extends State<BotDetailsScreen> {
  Timer? _updateTimer;
  WebViewController? _chartController;

  @override
  void initState() {
    super.initState();
    // Atualização em tempo real a cada 500ms para ser mais responsivo
    _updateTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) {
        setState(() {});
        _updateChart();
      }
    });
  }

  void _updateChart() {
    if (_chartController != null) {
      final marketData = widget.marketPrices[widget.bot.config.market] ?? [];
      if (marketData.isNotEmpty) {
        final jsArray = marketData.map((p) => p.toString()).join(',');
        final script = "try{ updateData([${jsArray}]); }catch(e){};";
        try {
          _chartController!.runJavaScript(script);
        } catch (_) {}
      }
    }
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  void _showConfigDialog() {
    final stakeController = TextEditingController(text: widget.bot.config.initialStake.toStringAsFixed(2));
    final maxStakeController = TextEditingController(text: widget.bot.config.maxStake.toStringAsFixed(2));
    final targetProfitController = TextEditingController(text: widget.bot.config.targetProfit.toStringAsFixed(2));

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Configurar Bot', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: stakeController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Stake Inicial (\$)',
                  labelStyle: const TextStyle(color: Colors.white54),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white24),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFFFF8C00)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: maxStakeController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Stake Máximo (\$)',
                  labelStyle: const TextStyle(color: Colors.white54),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white24),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFFFF8C00)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: targetProfitController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Target Profit (\$)',
                  labelStyle: const TextStyle(color: Colors.white54),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white24),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFFFF8C00)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              final newStake = double.tryParse(stakeController.text.replaceAll(',', '.'));
              final newMaxStake = double.tryParse(maxStakeController.text.replaceAll(',', '.'));
              final newTargetProfit = double.tryParse(targetProfitController.text.replaceAll(',', '.'));

              if (newStake != null && newStake >= 0.35 && 
                  newMaxStake != null && newMaxStake >= newStake &&
                  newTargetProfit != null && newTargetProfit > 0) {
                setState(() {
                  widget.bot.config.initialStake = newStake;
                  widget.bot.currentStake = newStake;
                  widget.bot.config.maxStake = newMaxStake;
                  widget.bot.config.targetProfit = newTargetProfit;
                });
                widget.onUpdate();
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF8C00),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.bot.getStatus();
    final winRate = status.winRate * 100;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF1A1A1A),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.bot.config.name),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.settings_rounded, color: Colors.white, size: 20),
              ),
              onPressed: _showConfigDialog,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gráfico Deriv em tempo real
            _buildDerivChart(),
            const SizedBox(height: 16),
            
            // Status e controles
            _buildStatusCard(status),
            const SizedBox(height: 16),
            
            // Botões de controle
            _buildControlButtons(),
            const SizedBox(height: 16),
            
            // Estatísticas
            _buildStatisticsGrid(status, winRate),
            const SizedBox(height: 16),
            
            // Histórico de trades
            _buildTradeHistory(status),
          ],
        ),
      ),
    );
  }

  Widget _buildDerivChart() {
    // Pega os preços reais do mercado do bot
    final marketData = widget.marketPrices[widget.bot.config.market] ?? [];
    final chartData = marketData.isEmpty ? [100.0] : marketData;

    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(24),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: DerivAreaChart(
          points: chartData,
          autoScale: true,
          showGradient: false,
          market: widget.bot.config.market,
          height: 300,
          onControllerCreated: (controller, market) {
            _chartController = controller;
          },
        ),
      ),
    );
  }

  Widget _buildStatusCard(BotStatus status) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Session Profit', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(
                    '${status.sessionProfit >= 0 ? '+' : ''}\$${status.sessionProfit.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: status.sessionProfit >= 0 ? const Color(0xFFFF8C00) : const Color(0xFFFF4444),
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: status.isRunning ? const Color(0xFFFF8C00).withOpacity(0.2) : const Color(0xFF2A2A2A),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  status.isRunning ? Icons.play_arrow_rounded : Icons.pause_rounded,
                  color: status.isRunning ? const Color(0xFFFF8C00) : Colors.white54,
                  size: 32,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildQuickStat('Win Rate', '${(status.winRate * 100).toStringAsFixed(1)}%')),
              Expanded(child: _buildQuickStat('Trades', status.totalTrades.toString())),
              Expanded(child: _buildQuickStat('Streak', '${status.consecutiveWins - status.consecutiveLosses}')),
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

  Widget _buildControlButtons() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: ElevatedButton.icon(
            onPressed: () {
              if (widget.bot.isRunning) {
                widget.bot.isPaused ? widget.bot.resume() : widget.bot.pause();
              } else {
                widget.bot.start();
              }
              widget.onUpdate();
              setState(() {});
            },
            icon: Icon(
              widget.bot.isRunning 
                  ? (widget.bot.isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded)
                  : Icons.play_arrow_rounded,
              size: 20,
            ),
            label: Text(
              widget.bot.isRunning 
                  ? (widget.bot.isPaused ? 'Continuar' : 'Pausar')
                  : 'Iniciar Trade',
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.bot.isRunning 
                  ? (widget.bot.isPaused ? const Color(0xFFFF8C00) : Colors.orange)
                  : const Color(0xFFFF8C00),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
        if (widget.bot.isRunning) ...[
          const SizedBox(width: 12),
          Expanded(
            flex: 1,
            child: ElevatedButton(
              onPressed: () {
                widget.bot.stop();
                widget.onUpdate();
                setState(() {});
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF4444),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Icon(Icons.stop_rounded, size: 24),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatisticsGrid(BotStatus status, double winRate) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard('Total Profit', '\$${status.totalProfit.toStringAsFixed(2)}', 
            status.totalProfit >= 0 ? const Color(0xFFFF8C00) : const Color(0xFFFF4444)),
        _buildStatCard('Win Rate', '${winRate.toStringAsFixed(1)}%', 
            winRate >= 50 ? const Color(0xFFFF8C00) : const Color(0xFFFF4444)),
        _buildStatCard('Avg Win', '\$${status.avgWin.toStringAsFixed(2)}', const Color(0xFFFF8C00)),
        _buildStatCard('Avg Loss', '\$${status.avgLoss.toStringAsFixed(2)}', const Color(0xFFFF4444)),
        _buildStatCard('Current RSI', status.currentRSI.toStringAsFixed(0), Colors.white70),
        _buildStatCard('Stake', '\$${status.currentStake.toStringAsFixed(2)}', Colors.white70),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildTradeHistory(BotStatus status) {
    if (status.tradeHistory.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(
          child: Text('Nenhum trade ainda', style: TextStyle(color: Colors.white54)),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Recent Trades', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: trade.won ? const Color(0xFFFF8C00).withOpacity(0.2) : const Color(0xFFFF4444).withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      trade.won ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                      color: trade.won ? const Color(0xFFFF8C00) : const Color(0xFFFF4444),
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
                            color: trade.won ? const Color(0xFFFF8C00) : const Color(0xFFFF4444),
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
                          color: trade.won ? const Color(0xFFFF8C00) : const Color(0xFFFF4444),
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
}