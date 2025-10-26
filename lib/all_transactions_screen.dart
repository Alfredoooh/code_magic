// lib/all_transactions_screen.dart
import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'theme/app_colors.dart';
import 'theme/app_widgets.dart';

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
  String _sortBy = 'date'; // date, amount
  bool _sortAscending = false;

  List<Map<String, dynamic>> get _filteredTransactions {
    var filtered = widget.transactions;

    // Apply filter
    if (_filter != 'all') {
      filtered = filtered.where((tx) {
        final amount = double.parse(tx['amount'].toString());
        if (_filter == 'credit') return amount > 0;
        if (_filter == 'debit') return amount < 0;
        return true;
      }).toList();
    }

    // Apply sorting
    filtered = List.from(filtered);
    filtered.sort((a, b) {
      int comparison;
      if (_sortBy == 'amount') {
        final amountA = double.parse(a['amount'].toString()).abs();
        final amountB = double.parse(b['amount'].toString()).abs();
        comparison = amountA.compareTo(amountB);
      } else {
        comparison = a['transaction_time'].compareTo(b['transaction_time']);
      }
      return _sortAscending ? comparison : -comparison;
    });

    return filtered;
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

  double get _creditTotal {
    return widget.transactions.where((tx) {
      return double.parse(tx['amount'].toString()) > 0;
    }).fold(0.0, (sum, tx) => sum + double.parse(tx['amount'].toString()));
  }

  double get _debitTotal {
    return widget.transactions.where((tx) {
      return double.parse(tx['amount'].toString()) < 0;
    }).fold(0.0, (sum, tx) => sum + double.parse(tx['amount'].toString()).abs());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.surface,
      appBar: SecondaryAppBar(
        title: 'Transações',
        onBack: () {
          AppHaptics.light();
          Navigator.pop(context);
        },
        actions: [
          IconButton(
            icon: Icon(Icons.sort_rounded),
            tooltip: 'Ordenar',
            onPressed: _showSortOptions,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          FadeInWidget(
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip(
                      'all',
                      'Todas',
                      Icons.list_rounded,
                      widget.transactions.length,
                    ),
                    SizedBox(width: AppSpacing.sm),
                    _buildFilterChip(
                      'credit',
                      'Entradas',
                      Icons.arrow_downward_rounded,
                      _creditCount,
                    ),
                    SizedBox(width: AppSpacing.sm),
                    _buildFilterChip(
                      'debit',
                      'Saídas',
                      Icons.arrow_upward_rounded,
                      _debitCount,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Summary Section
          FadeInWidget(
            delay: Duration(milliseconds: 100),
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              padding: EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    context.colors.primaryContainer,
                    context.colors.primaryContainer.withOpacity(0.5),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryItem(
                          'Total de Transações',
                          _filteredTransactions.length.toString(),
                          Icons.receipt_long_rounded,
                        ),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: context.colors.outline.withOpacity(0.3),
                      ),
                      Expanded(
                        child: _buildSummaryItem(
                          'Volume Total',
                          '${_calculateTotal().toStringAsFixed(2)}',
                          Icons.account_balance_wallet_rounded,
                        ),
                      ),
                    ],
                  ),
                  if (_filter == 'all') ...[
                    SizedBox(height: AppSpacing.lg),
                    Divider(color: context.colors.outline.withOpacity(0.3)),
                    SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        Expanded(
                          child: _buildBalanceItem(
                            'Entradas',
                            _creditTotal,
                            AppColors.success,
                            Icons.trending_up_rounded,
                          ),
                        ),
                        SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: _buildBalanceItem(
                            'Saídas',
                            _debitTotal,
                            AppColors.error,
                            Icons.trending_down_rounded,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),

          SizedBox(height: AppSpacing.lg),

          // Section Header
          FadeInWidget(
            delay: Duration(milliseconds: 200),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  Text(
                    '${_filteredTransactions.length} ${_filteredTransactions.length == 1 ? 'transação' : 'transações'}',
                    style: context.textStyles.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Spacer(),
                  AppBadge(
                    text: _sortBy == 'date' ? 'Por Data' : 'Por Valor',
                    color: context.colors.primary,
                    outlined: true,
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: AppSpacing.md),

          // Transactions List
          Expanded(
            child: _filteredTransactions.isEmpty
                ? FadeInWidget(
                    child: EmptyState(
                      icon: Icons.filter_list_off_rounded,
                      title: 'Nenhuma transação',
                      subtitle: _filter == 'all'
                          ? 'Você ainda não tem transações'
                          : 'Nenhuma transação encontrada com este filtro',
                      actionText: _filter != 'all' ? 'Limpar Filtro' : null,
                      onAction: _filter != 'all'
                          ? () {
                              AppHaptics.light();
                              setState(() => _filter = 'all');
                            }
                          : null,
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                      vertical: AppSpacing.sm,
                    ),
                    itemCount: _filteredTransactions.length,
                    itemBuilder: (context, index) {
                      final tx = _filteredTransactions[index];
                      return StaggeredListItem(
                        index: index,
                        delay: Duration(milliseconds: 30),
                        child: _buildTransactionCard(tx, index),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String value,
    String label,
    IconData icon,
    int count,
  ) {
    final isSelected = _filter == value;

    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          SizedBox(width: AppSpacing.xs),
          Text(label),
          if (count > 0) ...[
            SizedBox(width: AppSpacing.xs),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.xs,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? context.colors.onPrimaryContainer.withOpacity(0.2)
                    : context.colors.onSurface.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Text(
                count.toString(),
                style: context.textStyles.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
      onSelected: (selected) {
        if (selected) {
          AppHaptics.selection();
          setState(() => _filter = value);
        }
      },
      selectedColor: context.colors.primaryContainer,
      checkmarkColor: context.colors.onPrimaryContainer,
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          color: context.colors.onPrimaryContainer,
          size: 24,
        ),
        SizedBox(height: AppSpacing.sm),
        Text(
          value,
          style: context.textStyles.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: context.colors.onPrimaryContainer,
          ),
        ),
        SizedBox(height: AppSpacing.xxs),
        Text(
          label,
          style: context.textStyles.bodySmall?.copyWith(
            color: context.colors.onPrimaryContainer.withOpacity(0.8),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildBalanceItem(
    String label,
    double value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 16),
              SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: context.textStyles.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.xs),
          Text(
            '${value.toStringAsFixed(2)} ${widget.currency}',
            style: context.textStyles.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionCard(Map<String, dynamic> tx, int index) {
    final amount = double.parse(tx['amount'].toString());
    final isCredit = amount > 0;
    final color = isCredit ? AppColors.success : AppColors.error;
    final date = DateTime.fromMillisecondsSinceEpoch(
      tx['transaction_time'] * 1000,
    );

    return AnimatedCard(
      onTap: () => _showTransactionDetails(tx),
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            // Icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
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

            SizedBox(width: AppSpacing.md),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx['action_type'] ?? 'Trade',
                    style: context.textStyles.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: AppSpacing.xxs),
                  Text(
                    _formatDate(tx['transaction_time']),
                    style: context.textStyles.bodySmall?.copyWith(
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // Amount
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${isCredit ? '+' : ''}${amount.toStringAsFixed(2)}',
                  style: context.textStyles.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: AppSpacing.xxs),
                Text(
                  widget.currency,
                  style: context.textStyles.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showSortOptions() {
    AppModalBottomSheet.show(
      context: context,
      title: 'Ordenar Transações',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppListTile(
            title: 'Por Data',
            subtitle: 'Mais recentes primeiro',
            leading: Icon(Icons.calendar_today_rounded),
            trailing: _sortBy == 'date'
                ? Icon(Icons.check_circle_rounded, color: AppColors.success)
                : null,
            onTap: () {
              AppHaptics.selection();
              setState(() {
                _sortBy = 'date';
                _sortAscending = false;
              });
              Navigator.pop(context);
            },
          ),
          AppListTile(
            title: 'Por Valor',
            subtitle: 'Maior para menor',
            leading: Icon(Icons.attach_money_rounded),
            trailing: _sortBy == 'amount'
                ? Icon(Icons.check_circle_rounded, color: AppColors.success)
                : null,
            onTap: () {
              AppHaptics.selection();
              setState(() {
                _sortBy = 'amount';
                _sortAscending = false;
              });
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _showTransactionDetails(Map<String, dynamic> tx) {
    final amount = double.parse(tx['amount'].toString());
    final isCredit = amount > 0;
    final color = isCredit ? AppColors.success : AppColors.error;

    AppModalBottomSheet.show(
      context: context,
      title: 'Detalhes da Transação',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Amount Display
          Container(
            padding: EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(
                color: color.withOpacity(0.3),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  isCredit
                      ? Icons.arrow_downward_rounded
                      : Icons.arrow_upward_rounded,
                  color: color,
                  size: 48,
                ),
                SizedBox(height: AppSpacing.md),
                Text(
                  '${isCredit ? '+' : ''}${amount.toStringAsFixed(2)} ${widget.currency}',
                  style: context.textStyles.displaySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: AppSpacing.xs),
                AppBadge(
                  text: isCredit ? 'Entrada' : 'Saída',
                  color: color,
                ),
              ],
            ),
          ),

          SizedBox(height: AppSpacing.xl),

          // Transaction Info
          _buildDetailRow('Tipo', tx['action_type'] ?? 'Trade'),
          LabeledDivider(label: ''),
          _buildDetailRow('Data', _formatDate(tx['transaction_time'])),
          LabeledDivider(label: ''),
          _buildDetailRow(
            'ID',
            tx['transaction_id']?.toString() ?? 'N/A',
          ),

          SizedBox(height: AppSpacing.xl),

          PrimaryButton(
            text: 'Fechar',
            onPressed: () => Navigator.pop(context),
            expanded: true,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: context.textStyles.bodyMedium?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: context.textStyles.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
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
      return 'Hoje às ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Ontem às ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays < 7) {
      final weekday = ['Dom', 'Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb'][date.weekday % 7];
      return '$weekday às ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else {
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }
  }
}