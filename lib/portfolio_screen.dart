// portfolio_screen.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

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
  List<Map<String, dynamic>> _transactions = [];
  Map<String, dynamic>? _profitTable;
  Timer? _refreshTimer;
  
  double _todayProfit = 0.0;
  double _weekProfit = 0.0;
  double _monthProfit = 0.0;
  int _totalTrades = 0;
  int _winningTrades = 0;
  int _losingTrades = 0;

  // Dados para o gráfico semanal
  List<double> _weeklyData = [0, 0, 0, 0, 0, 0, 0];

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
            });
            
            _fetchTransactions();
            _fetchProfitTable();
          } else if (data['msg_type'] == 'statement') {
            setState(() {
              _transactions = List<Map<String, dynamic>>.from(
                data['statement']['transactions']
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

    // Dados semanais por dia
    List<double> weeklyData = List.filled(7, 0.0);

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
        // Adicionar ao gráfico semanal
        final daysDiff = now.difference(buyTime).inDays;
        if (daysDiff >= 0 && daysDiff < 7) {
          weeklyData[6 - daysDiff] += profit;
        }
      }
      if (buyTime.isAfter(monthAgo)) {
        monthProfit += profit;
      }
    }

    setState(() {
      _todayProfit = todayProfit;
      _weekProfit = weekProfit;
      _monthProfit = monthProfit;
      _totalTrades = totalTrades;
      _winningTrades = wins;
      _losingTrades = losses;
      _weeklyData = weeklyData;
    });
  }

  void _showAllTransactions() {
    Navigator.of(context).push(
      IOSSlideUpRoute(
        builder: (context) => AllTransactionsScreen(
          transactions: _transactions,
          currency: _currency,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final winRate = _totalTrades > 0 
        ? (_winningTrades / _totalTrades * 100) 
        : 0.0;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Portfólio',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _isConnected
          ? RefreshIndicator(
              onRefresh: () async {
                _fetchTransactions();
                _fetchProfitTable();
                await Future.delayed(const Duration(milliseconds: 500));
              },
              color: const Color(0xFF0066FF),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Balance Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0066FF), Color(0xFF0044CC)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0066FF).withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.account_balance_wallet_rounded,
                              color: Colors.white.withOpacity(0.7),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Saldo Total',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${_balance.toStringAsFixed(2)} $_currency',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ID: $_loginId',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Profit Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildProfitCard(
                          'Hoje',
                          _todayProfit,
                          Icons.today_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildProfitCard(
                          '7 Dias',
                          _weekProfit,
                          Icons.date_range_rounded,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  _buildProfitCard(
                    '30 Dias',
                    _monthProfit,
                    Icons.calendar_month_rounded,
                    fullWidth: true,
                  ),

                  const SizedBox(height: 24),

                  // Weekly Chart
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.bar_chart_rounded,
                              color: Colors.white.withOpacity(0.7),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Últimos 7 dias',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        _buildIOSBarChart(),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Stats Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.analytics_rounded,
                              color: Colors.white.withOpacity(0.7),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Estatísticas',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatColumn(
                              'Total',
                              _totalTrades.toString(),
                              const Color(0xFF0066FF),
                            ),
                            _buildStatColumn(
                              'Vitórias',
                              _winningTrades.toString(),
                              const Color(0xFF00C896),
                            ),
                            _buildStatColumn(
                              'Derrotas',
                              _losingTrades.toString(),
                              const Color(0xFFFF4444),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: winRate / 100,
                            backgroundColor: const Color(0xFF2A2A2A),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              winRate >= 50 
                                  ? const Color(0xFF00C896)
                                  : const Color(0xFFFF4444),
                            ),
                            minHeight: 8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Taxa de Vitória: ${winRate.toStringAsFixed(1)}%',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Recent Transactions Header
                  Row(
                    children: [
                      Icon(
                        Icons.receipt_long_rounded,
                        color: Colors.white.withOpacity(0.7),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Transações Recentes',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Recent Transactions List
                  if (_transactions.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(48),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.inbox_rounded,
                              color: Colors.white.withOpacity(0.3),
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Nenhuma transação recente',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._buildTransactionsList(),
                ],
              ),
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CupertinoActivityIndicator(
                    color: Color(0xFF0066FF),
                    radius: 16,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Carregando portfólio...',
                    style: TextStyle(color: Colors.white.withOpacity(0.5)),
                  ),
                ],
              ),
            ),
    );
  }

  List<Widget> _buildTransactionsList() {
    final displayTransactions = _transactions.take(7).toList();
    final hasMore = _transactions.length > 7;

    final widgets = displayTransactions.map((tx) {
      final amount = double.parse(tx['amount'].toString());
      final isCredit = amount > 0;
      
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {},
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isCredit 
                          ? const Color(0xFF00C896).withOpacity(0.15)
                          : const Color(0xFFFF4444).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCredit 
                            ? const Color(0xFF00C896).withOpacity(0.3)
                            : const Color(0xFFFF4444).withOpacity(0.3),
                      ),
                    ),
                    child: Icon(
                      isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                      color: isCredit ? const Color(0xFF00C896) : const Color(0xFFFF4444),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tx['action_type'] ?? 'Trade',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(tx['transaction_time']),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${isCredit ? '+' : ''}${amount.toStringAsFixed(2)} $_currency',
                    style: TextStyle(
                      color: isCredit ? const Color(0xFF00C896) : const Color(0xFFFF4444),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }).toList();

    if (hasMore) {
      widgets.add(
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _showAllTransactions,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF0066FF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF0066FF).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.expand_more_rounded,
                      color: Color(0xFF0066FF),
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Ver Todas as Transações (${_transactions.length})',
                      style: const TextStyle(
                        color: Color(0xFF0066FF),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return widgets;
  }

  Widget _buildIOSBarChart() {
    final maxValue = _weeklyData.reduce((a, b) => a.abs() > b.abs() ? a : b).abs();
    final days = ['D', 'S', 'T', 'Q', 'Q', 'S', 'S'];

    return SizedBox(
      height: 180,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (index) {
          final value = _weeklyData[index];
          final isPositive = value >= 0;
          final heightPercent = maxValue != 0 ? (value.abs() / maxValue) : 0.0;
          final barHeight = 120 * heightPercent;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Valor
                  if (value != 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        value.abs() < 1 
                            ? value.toStringAsFixed(2)
                            : value.abs().toStringAsFixed(0),
                        style: TextStyle(
                          color: isPositive 
                              ? const Color(0xFF00C896) 
                              : const Color(0xFFFF4444),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  // Barra
                  Container(
                    width: double.infinity,
                    height: barHeight.clamp(4.0, 120.0),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: isPositive
                            ? [
                                const Color(0xFF00C896),
                                const Color(0xFF00C896).withOpacity(0.6),
                              ]
                            : [
                                const Color(0xFFFF4444),
                                const Color(0xFFFF4444).withOpacity(0.6),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Dia da semana
                  Text(
                    days[index],
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildProfitCard(String label, double profit, IconData icon, {bool fullWidth = false}) {
    final isProfit = profit >= 0;
    
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: fullWidth ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: fullWidth ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Icon(icon, color: Colors.white.withOpacity(0.5), size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${isProfit ? '+' : ''}${profit.toStringAsFixed(2)} $_currency',
            style: TextStyle(
              color: isProfit ? const Color(0xFF00C896) : const Color(0xFFFF4444),
              fontSize: fullWidth ? 26 : 22,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
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
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

// Tela de Todas as Transações
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
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      setState(() {
        _scrollOffset = _scrollController.offset;
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final opacity = (_scrollOffset / 100).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Color.lerp(
          const Color(0xFF1A1A1A),
          const Color(0xFF2A2A2A),
          opacity,
        ),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Opacity(
          opacity: opacity,
          child: const Text(
            'Todas as Transações',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: Text(
                'Todas as Transações',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final tx = widget.transactions[index];
                  final amount = double.parse(tx['amount'].toString());
                  final isCredit = amount > 0;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {},
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.08)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: isCredit 
                                      ? const Color(0xFF00C896).withOpacity(0.15)
                                      : const Color(0xFFFF4444).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isCredit 
                                        ? const Color(0xFF00C896).withOpacity(0.3)
                                        : const Color(0xFFFF4444).withOpacity(0.3),
                                  ),
                                ),
                                child: Icon(
                                  isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                                  color: isCredit ? const Color(0xFF00C896) : const Color(0xFFFF4444),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tx['action_type'] ?? 'Trade',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatDate(tx['transaction_time']),
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.5),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${isCredit ? '+' : ''}${amount.toStringAsFixed(2)} ${widget.currency}',
                                style: TextStyle(
                                  color: isCredit ? const Color(0xFF00C896) : const Color(0xFFFF4444),
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
                childCount: widget.transactions.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 32),
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
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

// Animação iOS Slide Up
class IOSSlideUpRoute extends PageRouteBuilder {
  final WidgetBuilder builder;

  IOSSlideUpRoute({required this.builder})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => builder(context),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const curve = Curves.easeOutCubic;
            var curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: curve,
            );

            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 1.0),
                end: Offset.zero,
              ).animate(curvedAnimation),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 350),
          reverseTransitionDuration: const Duration(milliseconds: 300),
        );
}