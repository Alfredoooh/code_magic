// all_transactions_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class AllTransactionsScreen extends StatefulWidget {
  final List<Map<String, dynamic>> transactions;
  final String currency;

  const AllTransactionsScreen({
    Key? key,
    required this.transactions,
    required this.currency,
  }) : super(key: key);

  @override
  State<AllTransactionsScreen> createState() => _AllTransactionsScreenState();
}

class _AllTransactionsScreenState extends State<AllTransactionsScreen> {
  String _filter = 'all'; // all, credit, debit

  List<Map<String, dynamic>> get _filteredTransactions {
    if (_filter == 'all') return widget.transactions;
    
    return widget.transactions.where((tx) {
      final amount = double.parse(tx['amount'].toString());
      if (_filter == 'credit') return amount > 0;
      if (_filter == 'debit') return amount < 0;
      return true;
    }).toList();
  }

  double _calculateTotal() {
    return _filteredTransactions.fold(0.0, (sum, tx) {
      return sum + double.parse(tx['amount'].toString()).abs();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C1C1E),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Todas as Transações',
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.4,
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withOpacity(0.1),
                  width: 0.5,
                ),
              ),
            ),
            child: CupertinoSlidingSegmentedControl<String>(
              backgroundColor: const Color(0xFF1C1C1E),
              thumbColor: const Color(0xFF0066FF),
              groupValue: _filter,
              onValueChanged: (value) {
                if (value != null) {
                  setState(() {
                    _filter = value;
                  });
                }
              },
              children: const {
                'all': Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Text('Todas', style: TextStyle(fontSize: 13)),
                ),
                'credit': Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Text('Entradas', style: TextStyle(fontSize: 13)),
                ),
                'debit': Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Text('Saídas', style: TextStyle(fontSize: 13)),
                ),
              },
            ),
          ),

          // Summary
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Total',
                    _filteredTransactions.length.toString(),
                    const Color(0xFF0066FF),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    'Volume',
                    _calculateTotal().toStringAsFixed(2),
                    const Color(0xFF00C896),
                  ),
                ),
              ],
            ),
          ),

          // Transactions List
          Expanded(
            child: _filteredTransactions.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.filter_list_off,
                          color: Colors.white.withOpacity(0.3),
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhuma transação encontrada',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredTransactions.length,
                    itemBuilder: (context, index) {
                      final tx = _filteredTransactions[index];
                      final amount = double.parse(tx['amount'].toString());
                      final isCredit = amount > 0;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1C1C1E),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          leading: Icon(
                            isCredit
                                ? Icons.arrow_downward
                                : Icons.arrow_upward,
                            color: isCredit
                                ? const Color(0xFF00C896)
                                : const Color(0xFFFF4444),
                            size: 20,
                          ),
                          title: Text(
                            tx['action_type'] ?? 'Trade',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            _formatDate(tx['transaction_time']),
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 12,
                            ),
                          ),
                          trailing: Text(
                            '${isCredit ? '+' : ''}${amount.toStringAsFixed(2)} ${widget.currency}',
                            style: TextStyle(
                              color: isCredit
                                  ? const Color(0xFF00C896)
                                  : const Color(0xFFFF4444),
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Hoje ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Ontem ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }
  }
}