import 'package:flutter/material.dart';
import 'bot_strategies.dart';
import 'styles.dart';

class TradeHistoryScreen extends StatelessWidget {
  final List<TradeResult> trades;
  final Map<String, dynamic> stats;

  const TradeHistoryScreen({
    Key? key,
    required this.trades,
    required this.stats,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF141414),
        title: const Text('Histórico de Trades'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics_rounded),
            onPressed: () => _showStatsDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Cards de Estatísticas
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF141414),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Total Trades',
                        stats['total_trades'].toString(),
                        Icons.swap_horiz_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Win Rate',
                        '${stats['win_rate']}%',
                        Icons.trending_up_rounded,
                        color: stats['win_rate'] >= 50 ? AppStyles.green : AppStyles.red,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Lucro Total',
                        '\$${stats['profit'].toStringAsFixed(2)}',
                        Icons.attach_money_rounded,
                        color: stats['profit'] >= 0 ? AppStyles.green : AppStyles.red,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Média/Trade',
                        '\$${stats['avg_profit'].toStringAsFixed(2)}',
                        Icons.analytics_rounded,
                        color: stats['avg_profit'] >= 0 ? AppStyles.green : AppStyles.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Lista de Trades
          Expanded(
            child: trades.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history_rounded,
                        size: 64,
                        color: Colors.white24,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Nenhum trade registrado',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: trades.length,
                  itemBuilder: (context, index) {
                    final trade = trades[trades.length - 1 - index];
                    return _buildTradeCard(trade, index);
                  },
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, {Color? color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1a1a1a),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color ?? Colors.white54),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color ?? Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTradeCard(TradeResult trade, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: trade.won 
            ? AppStyles.green.withOpacity(0.3) 
            : AppStyles.red.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (trade.won ? AppStyles.green : AppStyles.red).withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: trade.won ? AppStyles.green : AppStyles.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    trade.won ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trade #${trades.length - index}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${trade.timestamp.day}/${trade.timestamp.month}/${trade.timestamp.year} ${trade.timestamp.hour}:${trade.timestamp.minute.toString().padLeft(2, '0')}',
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
                      trade.won ? 'WIN' : 'LOSS',
                      style: TextStyle(
                        color: trade.won ? AppStyles.green : AppStyles.red,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${trade.profit >= 0 ? "+" : ""}\$${trade.profit.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: trade.won ? AppStyles.green : AppStyles.red,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Detalhes
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildDetailRow('Mercado', trade.market, Icons.show_chart_rounded),
                const SizedBox(height: 8),
                _buildDetailRow('Direção', trade.direction, Icons.arrow_forward_rounded),
                const SizedBox(height: 8),
                _buildDetailRow('Stake', '\$${trade.stake.toStringAsFixed(2)}', Icons.attach_money_rounded),
                const SizedBox(height: 8),
                _buildDetailRow('Payout', '\$${trade.payout.toStringAsFixed(2)}', Icons.payments_rounded),
                const SizedBox(height: 8),
                _buildDetailRow('Estratégia', trade.strategy, Icons.psychology_rounded),
                
                if (trade.accumulationLevel > 0) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF007AFF).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF007AFF)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.layers_rounded, size: 14, color: Color(0xFF007AFF)),
                        const SizedBox(width: 6),
                        Text(
                          'Acumulação Nível ${trade.accumulationLevel}',
                          style: const TextStyle(
                            color: Color(0xFF007AFF),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                if (trade.wasRecovery) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD60A).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFFFD60A)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.restore_rounded, size: 14, color: Color(0xFFFFD60A)),
                        const SizedBox(width: 6),
                        const Text(
                          'Trade de Recuperação',
                          style: TextStyle(
                            color: Color(0xFFFFD60A),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.white54),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  void _showStatsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF141414),
        title: const Text(
          'Estatísticas Detalhadas',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildStatRow('Total de Trades', stats['total_trades'].toString()),
              _buildStatRow('Vitórias', stats['wins'].toString()),
              _buildStatRow('Derrotas', stats['losses'].toString()),
              _buildStatRow('Win Rate', '${stats['win_rate']}%'),
              _buildStatRow('Lucro Total', '\$${stats['profit'].toStringAsFixed(2)}'),
              _buildStatRow('Melhor Trade', '\$${stats['best_trade'].toStringAsFixed(2)}'),
              _buildStatRow('Pior Trade', '\$${stats['worst_trade'].toStringAsFixed(2)}'),
              _buildStatRow('Média por Trade', '\$${stats['avg_profit'].toStringAsFixed(2)}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
