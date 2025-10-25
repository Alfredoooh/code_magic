// portfolio_screen.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import 'all_transactions_screen.dart';
import 'pin_setup_screen.dart';

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
      CupertinoPageRoute(
        builder: (context) => AllTransactionsScreen(
          transactions: _transactions,
          currency: _currency,
        ),
      ),
    );
  }

  Future<void> _logout() async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Sair da Conta'),
        content: const Text('Tem certeza que deseja sair?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancelar'),
            onPressed: () => Navigator.pop(context, false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('Sair'),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('deriv_token');
      await prefs.remove('app_lock_pin');

      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  Future<void> _setupAppLock() async {
    final prefs = await SharedPreferences.getInstance();
    final existingPin = prefs.getString('app_lock_pin');

    if (existingPin != null) {
      final remove = await showCupertinoDialog<bool>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Bloqueio Ativo'),
          content: const Text('Deseja remover o bloqueio?'),
          actions: [
            CupertinoDialogAction(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.pop(context, false),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: const Text('Remover'),
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        ),
      );

      if (remove == true) {
        await prefs.remove('app_lock_pin');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bloqueio removido'),
            backgroundColor: Color(0xFFFF9500),
          ),
        );
      }
    } else {
      final result = await Navigator.of(context).push(
        CupertinoPageRoute(
          fullscreenDialog: true,
          builder: (context) => const PinSetupScreen(),
        ),
      );

      if (result != null && result is String) {
        await prefs.setString('app_lock_pin', result);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bloqueio ativado'),
            backgroundColor: Color(0xFFFF9500),
          ),
        );
      }
    }
  }

  void _showSettingsMenu() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _setupAppLock();
            },
            child: const Text('Bloquear App'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              _logout();
            },
            child: const Text('Sair da Conta'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final winRate = _totalTrades > 0 
        ? (_winningTrades / _totalTrades * 100) 
        : 0.0;

    return CupertinoPageScaffold(
      backgroundColor: Colors.black,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: const Color(0xFF1C1C1E),
        border: null,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        middle: const Text(
          'Portfólio',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.4,
          ),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(Icons.more_horiz_rounded, size: 24),
          onPressed: _showSettingsMenu,
        ),
      ),
      child: _isConnected
          ? CustomScrollView(
              slivers: [
                CupertinoSliverRefreshControl(
                  onRefresh: () async {
                    _fetchTransactions();
                    _fetchProfitTable();
                    await Future.delayed(const Duration(milliseconds: 500));
                  },
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Balance Card
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1C1C1E), Color(0xFF2C2C2E)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _userName,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.8),
                                        fontSize: 15,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _loginId,
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.5),
                                        fontSize: 12,
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
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.6),
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.baseline,
                                      textBaseline: TextBaseline.alphabetic,
                                      children: [
                                        Text(
                                          _balance.toStringAsFixed(2),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 32,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: -1,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _currency,
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.7),
                                            fontSize: 18,
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

                        const SizedBox(height: 20),

                        // Profit Summary
                        Row(
                          children: [
                            Expanded(child: _buildCompactProfitCard('Hoje', _todayProfit)),
                            const SizedBox(width: 12),
                            Expanded(child: _buildCompactProfitCard('7D', _weekProfit)),
                            const SizedBox(width: 12),
                            Expanded(child: _buildCompactProfitCard('30D', _monthProfit)),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Weekly Chart
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1C1C1E),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Últimos 7 dias',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildIOSBarChart(),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Stats Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1C1C1E),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Estatísticas',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(child: _buildStatItem('Total', _totalTrades.toString(), const Color(0xFFFF9500))),
                                  Expanded(child: _buildStatItem('Vitórias', _winningTrades.toString(), const Color(0xFFFF9500))),
                                  Expanded(child: _buildStatItem('Derrotas', _losingTrades.toString(), const Color(0xFFFF3B30))),
                                ],
                              ),
                              const SizedBox(height: 16),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: winRate / 100,
                                  backgroundColor: const Color(0xFF2C2C2E),
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    winRate >= 50 ? const Color(0xFFFF9500) : const Color(0xFFFF3B30),
                                  ),
                                  minHeight: 6,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Taxa de Vitória: ${winRate.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.6),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Recent Transactions
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Transações Recentes',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (_transactions.length > 5)
                              GestureDetector(
                                onTap: _showAllTransactions,
                                child: Row(
                                  children: [
                                    const Text(
                                      'Ver Todas',
                                      style: TextStyle(
                                        color: Color(0xFF007AFF),
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      color: Color(0xFF007AFF),
                                      size: 14,
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        if (_transactions.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(40),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1C1C1E),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.inbox_outlined,
                                    color: Colors.white.withOpacity(0.3),
                                    size: 40,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Nenhuma transação',
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

                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CupertinoActivityIndicator(
                    color: Color(0xFFFF9500),
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

  Widget _buildCompactProfitCard(String label, double profit) {
    final isProfit = profit >= 0;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
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
            '${isProfit ? '+' : ''}${profit.toStringAsFixed(2)}',
            style: TextStyle(
              color: isProfit ? const Color(0xFFFF9500) : const Color(0xFFFF3B30),
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
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
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildTransactionsList() {
    final displayTransactions = _transactions.take(5).toList();

    return displayTransactions.map((tx) {
      final amount = double.parse(tx['amount'].toString());
      final isCredit = amount > 0;

      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (isCredit 
                  ? const Color(0xFFFF9500) 
                  : const Color(0xFFFF3B30)).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isCredit ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              color: isCredit ? const Color(0xFFFF9500) : const Color(0xFFFF3B30),
              size: 20,
            ),
          ),
          title: Text(
            tx['action_type'] ?? 'Trade',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _formatDate(tx['transaction_time']),
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 13,
              ),
            ),
          ),
          trailing: Text(
            '${isCredit ? '+' : ''}${amount.toStringAsFixed(2)}',
            style: TextStyle(
              color: isCredit ? const Color(0xFFFF9500) : const Color(0xFFFF3B30),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildIOSBarChart() {
    final maxValue = _weeklyData.reduce((a, b) => a.abs() > b.abs() ? a : b).abs();
    final days = ['D', 'S', 'T', 'Q', 'Q', 'S', 'S'];

    return SizedBox(
      height: 140,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(7, (index) {
          final value = _weeklyData[index];
          final isPositive = value >= 0;
          final heightPercent = maxValue != 0 ? (value.abs() / maxValue) : 0.0;
          final barHeight = 100 * heightPercent;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (value != 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        value.abs().toStringAsFixed(0),
                        style: TextStyle(
                          color: isPositive ? const Color(0xFFFF9500) : const Color(0xFFFF3B30),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  Container(
                    width: double.infinity,
                    height: barHeight.clamp(3.0, 100.0),
                    decoration: BoxDecoration(
                      color: isPositive ? const Color(0xFFFF9500) : const Color(0xFFFF3B30),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    days[index],
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 11,
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