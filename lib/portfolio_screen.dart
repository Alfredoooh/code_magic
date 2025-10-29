// lib/portfolio_screen.dart - Material Design 3
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme/app_theme.dart';
import 'theme/app_colors.dart';
import 'theme/app_widgets.dart';
import 'all_transactions_screen.dart';

class PortfolioScreen extends StatefulWidget {
  final String token;

  const PortfolioScreen({Key? key, required this.token}) : super(key: key);

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  WebSocketChannel? _channel;
  bool _isConnected = false;
  double _balance = 0.0;
  String _currency = 'USD';
  String _accountId = '';
  String _loginId = '';
  String _userName = '';
  List<Map<String, dynamic>> _transactions = [];
  Map<String, dynamic>? _profitTable;
  Timer? _refreshTimer;

  double _todayProfit = 0.0;
  double _weekProfit = 0.0;
  double _monthProfit = 0.0;
  int _totalTrades = 0;
  int _winningTrades = 0;
  int _losingTrades = 0;

  List<double> _weeklyData = [0, 0, 0, 0, 0, 0, 0];
  
  String _selectedPeriod = '7D'; // 5D, 7D, 15D, 30D

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _channel?.sink.close();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_isConnected) {
        _fetchTransactions();
        _fetchProfitTable();
      }
    });
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
              _accountId = data['authorize']['account_list'][0]['loginid'];
              _loginId = data['authorize']['loginid'];
              _userName = data['authorize']['fullname'] ?? data['authorize']['email']?.split('@')[0] ?? 'Usuário';
            });

            _fetchTransactions();
            _fetchProfitTable();
          } else if (data['msg_type'] == 'statement') {
            setState(() {
              _transactions = List<Map<String, dynamic>>.from(
                data['statement']['transactions'] ?? []
              );
            });
          } else if (data['msg_type'] == 'profit_table') {
            setState(() {
              _profitTable = data['profit_table'];
              _calculateStats();
            });
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

  void _fetchTransactions() {
    _channel?.sink.add(json.encode({
      'statement': 1,
      'description': 1,
      'limit': 50,
    }));
  }

  void _fetchProfitTable() {
    _channel?.sink.add(json.encode({
      'profit_table': 1,
      'description': 1,
      'limit': 100,
    }));
  }

  void _calculateStats() {
    if (_profitTable == null) return;

    final transactions = _profitTable!['transactions'] as List?;
    if (transactions == null || transactions.isEmpty) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekAgo = now.subtract(const Duration(days: 7));
    final monthAgo = now.subtract(const Duration(days: 30));

    double todayProfit = 0;
    double weekProfit = 0;
    double monthProfit = 0;
    int totalTrades = 0;
    int wins = 0;
    int losses = 0;

    int daysToShow = _selectedPeriod == '5D' ? 5 : _selectedPeriod == '15D' ? 15 : _selectedPeriod == '30D' ? 30 : 7;
    List<double> periodData = List.filled(daysToShow, 0.0);

    for (var tx in transactions) {
      final sellTime = tx['sell_time'];
      if (sellTime == null) continue;

      final buyTime = DateTime.fromMillisecondsSinceEpoch(tx['buy_time'] * 1000);
      final profit = double.parse(tx['sell_price'].toString()) - 
                     double.parse(tx['buy_price'].toString());

      totalTrades++;
      if (profit > 0) {
        wins++;
      } else if (profit < 0) {
        losses++;
      }

      if (buyTime.isAfter(today)) {
        todayProfit += profit;
      }
      if (buyTime.isAfter(weekAgo)) {
        weekProfit += profit;
      }
      if (buyTime.isAfter(monthAgo)) {
        monthProfit += profit;
      }

      // Calculate period data
      final daysDiff = now.difference(buyTime).inDays;
      if (daysDiff >= 0 && daysDiff < daysToShow) {
        periodData[daysToShow - 1 - daysDiff] += profit;
      }
    }

    setState(() {
      _todayProfit = todayProfit;
      _weekProfit = weekProfit;
      _monthProfit = monthProfit;
      _totalTrades = totalTrades;
      _winningTrades = wins;
      _losingTrades = losses;
      _weeklyData = periodData;
    });
  }

  void _showAllTransactions() {
    AppHaptics.light();
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => AllTransactionsScreen(
          transactions: _transactions,
          currency: _currency,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(position: animation.drive(tween), child: child);
        },
      ),
    );
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair da Conta'),
        content: const Text('Tem certeza que deseja sair?'),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () {
              AppHaptics.light();
              Navigator.pop(context, false);
            },
          ),
          FilledButton(
            child: const Text('Sair'),
            onPressed: () {
              AppHaptics.medium();
              Navigator.pop(context, true);
            },
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('deriv_token');
      await prefs.remove('app_lock_pin');

      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  void _showSettingsMenu() {
    AppHaptics.light();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusLg)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: AppSpacing.md),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: context.colors.onSurfaceVariant.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppListTile(
              title: 'Sair da Conta',
              leading: Icon(Icons.logout_rounded, color: AppColors.error),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () {
                Navigator.pop(context);
                _logout();
              },
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ),
      ),
    );
  }

  void _changePeriod(String period) {
    setState(() {
      _selectedPeriod = period;
    });
    _calculateStats();
  }

  @override
  Widget build(BuildContext context) {
    final winRate = _totalTrades > 0 
        ? (_winningTrades / _totalTrades * 100) 
        : 0.0;

    return Scaffold(
      backgroundColor: context.surface,
      appBar: SecondaryAppBar(
        title: 'Portfólio',
        onBack: () => Navigator.pop(context),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz_rounded),
            onPressed: _showSettingsMenu,
          ),
        ],
      ),
      body: _isConnected
          ? RefreshIndicator(
              onRefresh: () async {
                AppHaptics.light();
                _fetchTransactions();
                _fetchProfitTable();
                await Future.delayed(const Duration(milliseconds: 500));
              },
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Balance Card
                          AnimatedContainer(
                            duration: AppMotion.medium,
                            height: 200,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  context.colors.surfaceContainer,
                                  context.colors.surfaceContainerHighest,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _userName,
                                        style: context.textStyles.bodyLarge?.copyWith(
                                          color: context.colors.onSurface,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.xxs),
                                      Text(
                                        _loginId,
                                        style: context.textStyles.bodySmall?.copyWith(
                                          color: context.colors.onSurfaceVariant,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Saldo Disponível',
                                        style: context.textStyles.bodySmall?.copyWith(
                                          color: context.colors.onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.xs),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.baseline,
                                        textBaseline: TextBaseline.alphabetic,
                                        children: [
                                          Text(
                                            _balance.toStringAsFixed(2),
                                            style: context.textStyles.displaySmall?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(width: AppSpacing.sm),
                                          Text(
                                            _currency,
                                            style: context.textStyles.titleLarge?.copyWith(
                                              color: context.colors.onSurfaceVariant,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: AppSpacing.lg),

                          // Profit Summary - Only show profits, no +0.00
                          Row(
                            children: [
                              if (_todayProfit != 0) Expanded(child: _buildCompactProfitCard('Hoje', _todayProfit)),
                              if (_todayProfit != 0 && _weekProfit != 0) const SizedBox(width: AppSpacing.md),
                              if (_weekProfit != 0) Expanded(child: _buildCompactProfitCard('7D', _weekProfit)),
                              if (_weekProfit != 0 && _monthProfit != 0) const SizedBox(width: AppSpacing.md),
                              if (_monthProfit != 0) Expanded(child: _buildCompactProfitCard('30D', _monthProfit)),
                            ],
                          ),

                          if (_todayProfit == 0 && _weekProfit == 0 && _monthProfit == 0)
                            Container(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              decoration: BoxDecoration(
                                color: context.colors.surfaceContainer,
                                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                              ),
                              child: Center(
                                child: Text(
                                  'Nenhuma atividade registrada',
                                  style: context.textStyles.bodyMedium?.copyWith(
                                    color: context.colors.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ),

                          const SizedBox(height: AppSpacing.lg),

                          // Period Selector
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: context.colors.surfaceContainer,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            ),
                            child: Row(
                              children: ['5D', '7D', '15D', '30D'].map((period) {
                                final isSelected = _selectedPeriod == period;
                                return Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      AppHaptics.selection();
                                      _changePeriod(period);
                                    },
                                    child: AnimatedContainer(
                                      duration: AppMotion.short,
                                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                                      decoration: BoxDecoration(
                                        color: isSelected ? context.colors.primary : Colors.transparent,
                                        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                      ),
                                      child: Center(
                                        child: Text(
                                          period,
                                          style: context.textStyles.labelLarge?.copyWith(
                                            color: isSelected ? context.colors.onPrimary : context.colors.onSurfaceVariant,
                                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),

                          const SizedBox(height: AppSpacing.md),

                          // Weekly Chart
                          AnimatedContainer(
                            duration: AppMotion.medium,
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            decoration: BoxDecoration(
                              color: context.colors.surfaceContainer,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Últimos $_selectedPeriod',
                                  style: context.textStyles.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                _buildBarChart(),
                              ],
                            ),
                          ),

                          const SizedBox(height: AppSpacing.lg),

                          // Stats Card - Now responsive
                          AnimatedContainer(
                            duration: AppMotion.medium,
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            decoration: BoxDecoration(
                              color: context.colors.surfaceContainer,
                              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Estatísticas',
                                  style: context.textStyles.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                Row(
                                  children: [
                                    Expanded(child: _buildStatItem('Total', _totalTrades.toString(), context.colors.primary)),
                                    Expanded(child: _buildStatItem('Vitórias', _winningTrades.toString(), AppColors.success)),
                                    Expanded(child: _buildStatItem('Derrotas', _losingTrades.toString(), AppColors.error)),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                                  child: TweenAnimationBuilder<double>(
                                    tween: Tween(begin: 0.0, end: winRate / 100),
                                    duration: AppMotion.long,
                                    curve: AppMotion.emphasizedDecelerate,
                                    builder: (context, value, child) {
                                      return LinearProgressIndicator(
                                        value: value,
                                        backgroundColor: context.colors.surfaceContainerHighest,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          winRate >= 50 ? AppColors.success : AppColors.error,
                                        ),
                                        minHeight: 6,
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  'Taxa de Vitória: ${winRate.toStringAsFixed(1)}%',
                                  style: context.textStyles.bodySmall?.copyWith(
                                    color: context.colors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: AppSpacing.lg),

                          // Recent Transactions Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Transações Recentes',
                                style: context.textStyles.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (_transactions.length > 5)
                                GestureDetector(
                                  onTap: _showAllTransactions,
                                  child: Row(
                                    children: [
                                      Text(
                                        'Ver Todas',
                                        style: context.textStyles.bodyMedium?.copyWith(
                                          color: context.colors.primary,
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.xxs),
                                      Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        color: context.colors.primary,
                                        size: 14,
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(height: AppSpacing.md),

                          // Transactions List - Grouped in single container
                          if (_transactions.isEmpty)
                            EmptyState(
                              icon: Icons.inbox_rounded,
                              title: 'Nenhuma transação',
                              subtitle: 'Suas transações aparecerão aqui',
                            )
                          else
                            _buildGroupedTransactionsList(),

                          const SizedBox(height: AppSpacing.lg),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )
          : LoadingOverlay(
              isLoading: true,
              message: 'Carregando portfólio...',
              child: const SizedBox.expand(),
            ),
    );
  }

  Widget _buildCompactProfitCard(String label, double profit) {
    final isProfit = profit > 0;

    return AnimatedContainer(
      duration: AppMotion.medium,
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.md, 
        horizontal: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: context.colors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: context.textStyles.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${isProfit ? '+' : ''}${profit.toStringAsFixed(2)}',
            style: context.textStyles.titleMedium?.copyWith(
              color: isProfit ? AppColors.success : AppColors.error,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        TweenAnimationBuilder<int>(
          tween: IntTween(begin: 0, end: int.tryParse(value) ?? 0),
          duration: AppMotion.long,
          curve: AppMotion.emphasizedDecelerate,
          builder: (context, value, child) {
            return Text(
              value.toString(),
              style: context.textStyles.headlineSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            );
          },
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

  Widget _buildGroupedTransactionsList() {
    final displayTransactions = _transactions.take(5).toList();

    return Container(
      decoration: BoxDecoration(
        color: context.colors.surfaceContainer,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Column(
        children: displayTransactions.asMap().entries.map((entry) {
          final index = entry.key;
          final tx = entry.value;
          final amount = double.parse(tx['amount'].toString());
          final isCredit = amount > 0;
          final isFirst = index == 0;
          final isLast = index == displayTransactions.length - 1;

          return Container(
            decoration: BoxDecoration(
              border: isLast ? null : Border(
                bottom: BorderSide(
                  color: context.colors.outlineVariant.withOpacity(0.5),
                  width: 1,
                ),
              ),
              borderRadius: BorderRadius.vertical(
                top: isFirst ? const Radius.circular(AppSpacing.radiusMd) : Radius.zero,
                bottom: isLast ? const Radius.circular(AppSpacing.radiusMd) : Radius.zero,
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, 
                vertical: AppSpacing.sm,
              ),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: (isCredit ? AppColors.success : AppColors.error).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(
                  isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                  color: isCredit ? AppColors.success : AppColors.error,
                  size: 20,
                ),
              ),
              title: Text(
                tx['action_type'] ?? 'Trade',
                style: context.textStyles.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xxs),
                child: Text(
                  _formatDate(tx['transaction_time']),
                  style: context.textStyles.bodySmall?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ),
              trailing: Text(
                '${isCredit ? '+' : ''}${amount.toStringAsFixed(2)}',
                style: context.textStyles.titleSmall?.copyWith(
                  color: isCredit ? AppColors.success : AppColors.error,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildBarChart() {
    final maxValue = _weeklyData.reduce((a, b) => a.abs() > b.abs() ? a : b).abs();
    
    return SizedBox(
      height: 140,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(_weeklyData.length, (index) {
          final value = _weeklyData[index];
          final isPositive = value >= 0;
          final heightPercent = maxValue != 0 ? (value.abs() / maxValue) : 0.0;
          final barHeight = 100 * heightPercent;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: barHeight.clamp(3.0, 100.0)),
                duration: AppMotion.long,
                curve: AppMotion.emphasizedDecelerate,
                builder: (context, animatedHeight, child) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (value != 0)
                        Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
                          child: Text(
                            value.abs().toStringAsFixed(0),
                            style: context.textStyles.labelSmall?.copyWith(
                              color: isPositive ? AppColors.success : AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      Container(
                        width: double.infinity,
                        height: animatedHeight,
                        decoration: BoxDecoration(
                          color: isPositive ? AppColors.success : AppColors.error,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '${index + 1}',
                        style: context.textStyles.labelSmall?.copyWith(
                          color: context.colors.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          );
        }),
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
      return 'Ontem';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}