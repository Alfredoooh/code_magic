// all_transactions_screen.dart
import 'package:flutter/material.dart';
import 'styles.dart';

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
  String _filter = 'all';

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

  int get _creditCount {
    return widget.transactions.where((tx) {
      return double.parse(tx['amount'].toString()) > 0;
    }).length;
  }

  int get _debitCount {
    return widget.transactions.where((tx) {
      return double.parse(tx['amount'].toString()) < 0;
    }).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            AppHaptics.light();
            Navigator.pop(context);
          },
        ),
        title: const Text('Todas as Transações'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Filter Tabs
          FadeInWidget(
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: _buildFilterChip('all', 'Todas', Icons.list_rounded),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _buildFilterChip('credit', 'Entradas', Icons.arrow_downward_rounded),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _buildFilterChip('debit', 'Saídas', Icons.arrow_upward_rounded),
                  ),
                ],
              ),
            ),
          ),

          // Summary Cards
          FadeInWidget(
            delay: const Duration(milliseconds: 100),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      'Total',
                      _filteredTransactions.length.toString(),
                      AppColors.primary,
                      Icons.receipt_long_rounded,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _buildSummaryCard(
                      'Volume',
                      '${_calculateTotal().toStringAsFixed(2)} ${widget.currency}',
                      AppColors.success,
                      Icons.account_balance_wallet_rounded,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Statistics Bar
          if (_filter == 'all')
            FadeInWidget(
              delay: const Duration(milliseconds: 200),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: context.colors.surfaceContainer,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  border: Border.all(
                    color: context.colors.outlineVariant,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      'Entradas',
                      _creditCount.toString(),
                      AppColors.success,
                    ),
                    Container(
                      width: 1,
                      height: 30,
                      color: context.colors.outlineVariant,
                    ),
                    _buildStatItem(
                      'Saídas',
                      _debitCount.toString(),
                      AppColors.error,
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: AppSpacing.lg),

          // Transactions List
          Expanded(
            child: _filteredTransactions.isEmpty
                ? FadeInWidget(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.xl),
                            decoration: BoxDecoration(
                              color: context.colors.surfaceContainer,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.filter_list_off_rounded,
                              color: context.colors.onSurfaceVariant,
                              size: 48,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          Text(
                            'Nenhuma transação encontrada',
                            style: context.textStyles.bodyLarge?.copyWith(
                              color: context.colors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.sm,
                    ),
                    itemCount: _filteredTransactions.length,
                    itemBuilder: (context, index) {
                      final tx = _filteredTransactions[index];
                      
                      return StaggeredListItem(
                        index: index,
                        child: _buildTransactionCard(tx),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, IconData icon) {
    final isSelected = _filter == value;
    
    return GestureDetector(
      onTap: () {
        AppHaptics.selection();
        setState(() => _filter = value);
      },
      child: AnimatedContainer(
        duration: AppMotion.fast,
        padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.md,
          horizontal: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? context.colors.primary
              : context.colors.surfaceContainer,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isSelected
                ? context.colors.primary
                : context.colors.outlineVariant,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? context.colors.onPrimary
                  : context.colors.onSurface,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: context.textStyles.labelMedium?.copyWith(
                color: isSelected
                    ? context.colors.onPrimary
                    : context.colors.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: context.colors.outlineVariant,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: AppSpacing.sm),
          Text(
            label,
            style: context.textStyles.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: context.textStyles.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: context.textStyles.titleLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          label,
          style: context.textStyles.bodySmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> tx) {
    final amount = double.parse(tx['amount'].toString());
    final isCredit = amount > 0;
    final color = isCredit ? AppColors.success : AppColors.error;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Icon(
            isCredit
                ? Icons.arrow_downward_rounded
                : Icons.arrow_upward_rounded,
            color: color,
            size: 24,
          ),
        ),
        title: Text(
          tx['action_type'] ?? 'Trade',
          style: context.textStyles.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xs),
          child: Text(
            _formatDate(tx['transaction_time']),
            style: context.textStyles.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isCredit ? '+' : ''}${amount.toStringAsFixed(2)}',
              style: context.textStyles.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              widget.currency,
              style: context.textStyles.bodySmall?.copyWith(
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
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