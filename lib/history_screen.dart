import 'package:flutter/material.dart';
import 'styles.dart';

class HistoryScreen extends StatefulWidget {
  final String token;
  
  const HistoryScreen({Key? key, required this.token}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppStyles.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppStyles.bgSecondary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppStyles.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Histórico',
          style: TextStyle(
            color: AppStyles.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded, color: AppStyles.textPrimary),
            onPressed: () {
              AppStyles.showSnackBar(context, 'Filtros em desenvolvimento');
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppStyles.iosBlue,
          labelColor: AppStyles.iosBlue,
          unselectedLabelColor: AppStyles.textSecondary,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Trades'),
            Tab(text: 'Transações'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTradesHistory(),
          _buildTransactionsHistory(),
        ],
      ),
    );
  }

  Widget _buildTradesHistory() {
    // Dados mockados - substituir por dados reais da API
    final trades = List.generate(15, (index) {
      final isWin = index % 3 != 0;
      return {
        'type': index % 2 == 0 ? 'CALL' : 'PUT',
        'symbol': ['Volatility 100', 'Volatility 75', 'Boom 1000'][index % 3],
        'stake': (index + 1) * 5.0,
        'multiplier': [20, 40, 60, 100][index % 4],
        'profit': isWin ? (index + 1) * 8.5 : -(index + 1) * 5.0,
        'time': '${index + 1}h atrás',
        'isWin': isWin,
      };
    });

    if (trades.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_rounded,
              size: 80,
              color: AppStyles.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'Nenhum trade realizado',
              style: TextStyle(
                color: AppStyles.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Suas operações aparecerão aqui',
              style: TextStyle(
                color: AppStyles.textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: trades.length,
      itemBuilder: (context, index) {
        final trade = trades[index];
        final isWin = trade['isWin'] as bool;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppStyles.bgSecondary,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isWin 
                  ? AppStyles.iosGreen.withOpacity(0.3) 
                  : AppStyles.red.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _showTradeDetails(context, trade),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Ícone
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: isWin 
                            ? AppStyles.iosGreen.withOpacity(0.15)
                            : AppStyles.red.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isWin ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                        color: isWin ? AppStyles.iosGreen : AppStyles.red,
                        size: 28,
                      ),
                    ),
                    
                    const SizedBox(width: 16),
                    
                    // Informações
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: trade['type'] == 'CALL'
                                      ? AppStyles.iosGreen.withOpacity(0.2)
                                      : AppStyles.red.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  trade['type'] as String,
                                  style: TextStyle(
                                    color: trade['type'] == 'CALL'
                                        ? AppStyles.iosGreen
                                        : AppStyles.red,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                trade['symbol'] as String,
                                style: const TextStyle(
                                  color: AppStyles.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Stake: \$${(trade['stake'] as double).toStringAsFixed(2)} • x${trade['multiplier']}',
                            style: const TextStyle(
                              color: AppStyles.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            trade['time'] as String,
                            style: const TextStyle(
                              color: AppStyles.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Lucro/Perda
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${(trade['profit'] as double) >= 0 ? '+' : ''}\$${(trade['profit'] as double).toStringAsFixed(2)}',
                          style: TextStyle(
                            color: isWin ? AppStyles.iosGreen : AppStyles.red,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: isWin 
                                ? AppStyles.iosGreen.withOpacity(0.15)
                                : AppStyles.red.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isWin ? 'WIN' : 'LOSS',
                            style: TextStyle(
                              color: isWin ? AppStyles.iosGreen : AppStyles.red,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTransactionsHistory() {
    final transactions = List.generate(20, (index) {
      final isDeposit = index % 2 == 0;
      return {
        'type': isDeposit ? 'Depósito' : 'Retirada',
        'amount': (index + 1) * 50.0,
        'status': ['Concluído', 'Pendente', 'Concluído'][index % 3],
        'date': '${index + 1}/10/2024',
        'time': '${14 + (index % 10)}:${30 + (index % 30)}',
        'isDeposit': isDeposit,
      };
    });

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        final isDeposit = transaction['isDeposit'] as bool;
        final status = transaction['status'] as String;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppStyles.bgSecondary,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppStyles.border, width: 0.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Ícone
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isDeposit 
                        ? AppStyles.iosGreen.withOpacity(0.15)
                        : AppStyles.iosBlue.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isDeposit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                    color: isDeposit ? AppStyles.iosGreen : AppStyles.iosBlue,
                    size: 24,
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Informações
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction['type'] as String,
                        style: const TextStyle(
                          color: AppStyles.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${transaction['date']} às ${transaction['time']}',
                        style: const TextStyle(
                          color: AppStyles.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: status == 'Concluído'
                              ? AppStyles.iosGreen.withOpacity(0.15)
                              : AppStyles.iosBlue.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: status == 'Concluído'
                                ? AppStyles.iosGreen
                                : AppStyles.iosBlue,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Valor
                Text(
                  '${isDeposit ? '+' : '-'}\$${(transaction['amount'] as double).toStringAsFixed(2)}',
                  style: TextStyle(
                    color: isDeposit ? AppStyles.iosGreen : AppStyles.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showTradeDetails(BuildContext context, Map<String, dynamic> trade) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppStyles.bgSecondary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Detalhes do Trade',
                  style: TextStyle(
                    color: AppStyles.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppStyles.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildDetailRow('Tipo', trade['type'] as String),
            _buildDetailRow('Símbolo', trade['symbol'] as String),
            _buildDetailRow('Stake', '\$${(trade['stake'] as double).toStringAsFixed(2)}'),
            _buildDetailRow('Multiplicador', 'x${trade['multiplier']}'),
            _buildDetailRow('Resultado', '${(trade['profit'] as double) >= 0 ? '+' : ''}\$${(trade['profit'] as double).toStringAsFixed(2)}'),
            _buildDetailRow('Tempo', trade['time'] as String),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fechar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppStyles.textSecondary,
              fontSize: 15,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppStyles.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}