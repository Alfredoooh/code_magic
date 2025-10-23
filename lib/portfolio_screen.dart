// portfolio_screen.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
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
      IOSSlideUpRoute(
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
        content: const Text('Tem certeza que deseja sair? Você precisará fazer login novamente.'),
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
      // Já tem PIN, perguntar se quer remover
      final remove = await showCupertinoDialog<bool>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Bloqueio Ativo'),
          content: const Text('O bloqueio do app já está ativo. Deseja removê-lo?'),
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
            content: Text('Bloqueio removido com sucesso'),
            backgroundColor: Color(0xFF00C896),
          ),
        );
      }
    } else {
      // Criar novo PIN
      final pin = await _showPinSetupDialog();
      if (pin != null && pin.length >= 6) {
        await prefs.setString('app_lock_pin', pin);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bloqueio ativado com sucesso'),
            backgroundColor: Color(0xFF00C896),
          ),
        );
      }
    }
  }

  Future<String?> _showPinSetupDialog() async {
    final pinController = TextEditingController();
    final confirmController = TextEditingController();

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Criar PIN',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: pinController,
              obscureText: true,
              maxLength: 20,
              keyboardType: TextInputType.text,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'PIN (mínimo 6 caracteres)',
                labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                counterStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmController,
              obscureText: true,
              maxLength: 20,
              keyboardType: TextInputType.text,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Confirmar PIN',
                labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                counterStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              final pin = pinController.text;
              final confirm = confirmController.text;

              if (pin.length < 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('PIN deve ter pelo menos 6 caracteres'),
                    backgroundColor: Color(0xFFFF4444),
                  ),
                );
                return;
              }

              if (pin != confirm) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('PINs não coincidem'),
                    backgroundColor: Color(0xFFFF4444),
                  ),
                );
                return;
              }

              Navigator.pop(context, pin);
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  void _showSettingsMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.lock_outline, color: Color(0xFF0066FF)),
              title: const Text('Bloquear App', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _setupAppLock();
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Color(0xFFFF4444)),
              title: const Text('Sair da Conta', style: TextStyle(color: Color(0xFFFF4444))),
              onTap: () {
                Navigator.pop(context);
                _logout();
              },
            ),
            const SizedBox(height: 12),
          ],
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
        backgroundColor: const Color(0xFF1C1C1E),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Portfólio',
          style: TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.4,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white, size: 22),
            onPressed: _showSettingsMenu,
          ),
        ],
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
                  // Visa-style Balance Card
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF1C1C1E), Color(0xFF2C2C2E)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Pattern overlay
                        Positioned(
                          right: -20,
                          top: -20,
                          child: Container(
                            width: 150,
                            height: 150,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF0066FF).withOpacity(0.1),
                            ),
                          ),
                        ),
                        Padding(
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
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _loginId,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.5),
                                      fontSize: 12,
                                      letterSpacing: 1,
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
                                      letterSpacing: 0.5,
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
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Profit Summary
                  Row(
                    children: [
                      Expanded(
                        child: _buildCompactProfitCard('Hoje', _todayProfit),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildCompactProfitCard('7D', _weekProfit),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildCompactProfitCard('30D', _monthProfit),
                      ),
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
                            letterSpacing: -0.3,
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
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: _buildStatItem('Total', _totalTrades.toString(), const Color(0xFF0066FF))),
                            Expanded(child: _buildStatItem('Vitórias', _winningTrades.toString(), const Color(0xFF00C896))),
                            Expanded(child: _buildStatItem('Derrotas', _losingTrades.toString(), const Color(0xFFFF4444))),
                          ],
                        ),
                        const SizedBox(height: 16),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: winRate / 100,
                            backgroundColor: const Color(0xFF2C2C2E),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              winRate >= 50 ? const Color(0xFF00C896) : const Color(0xFFFF4444),
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
                  const Text(
                    'Transações Recentes',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                    ),
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
              color: isProfit ? const Color(0xFF00C896) : const Color(0xFFFF4444),
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
    final hasMore = _transactions.length > 5;

    final widgets = displayTransactions.map((tx) {
      final amount = double.parse(tx['amount'].toString());
      final isCredit = amount > 0;
      
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          leading: Icon(
            isCredit ? Icons.arrow_downward : Icons.arrow_upward,
            color: isCredit ? const Color(0xFF00C896) : const Color(0xFFFF4444),
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
            '${isCredit ? '+' : ''}${amount.toStringAsFixed(2)}',
            style: TextStyle(
              color: isCredit ? const Color(0xFF00C896) : const Color(0xFFFF4444),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }).toList();

    if (hasMore) {
      widgets.add(
        Container(
          margin: const EdgeInsets.only(top: 4),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _showAllTransactions,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF0066FF).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF0066FF).withOpacity(0.3),
                  ),
                ),
                child: Center(
                  child: Text(
                    'Ver Todas (${_transactions.length})',
                    style: const TextStyle(
                      color: Color(0xFF0066FF),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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
                          color: isPositive ? const Color(0xFF00C896) : const Color(0xFFFF4444),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  Container(
                    width: double.infinity,
                    height: barHeight.clamp(3.0, 100.0),
                    decoration: BoxDecoration(
                      color: isPositive ? const Color(0xFF00C896) : const Color(0xFFFF4444),
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

// Animação iOS Slide Up
class IOSSlideUpRoute extends PageRouteBuilder {
  final WidgetBuilder builder;

  IOSSlideUpRoute({required this.builder})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => builder(context),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const curve = Cubic(0.42, 0.0, 0.58, 1.0);
            
            var curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: curve,
              reverseCurve: Curves.easeInOut,
            );

            return SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 1.0),
                end: Offset.zero,
              ).animate(curvedAnimation),
              child: FadeTransition(
                opacity: Tween<double>(
                  begin: 0.0,
                  end: 1.0,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
                )),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 500),
          reverseTransitionDuration: const Duration(milliseconds: 400),
        );
}