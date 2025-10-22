// portfolio_screen.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
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
  
  double _todayProfit = 0.0;
  double _weekProfit = 0.0;
  double _monthProfit = 0.0;
  int _totalTrades = 0;
  int _winningTrades = 0;
  int _losingTrades = 0;

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
  }

  @override
  void dispose() {
    _channel?.sink.close();
    super.dispose();
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
    _channel!.sink.add(json.encode({
      'statement': 1,
      'description': 1,
      'limit': 50,
    }));
  }

  void _fetchProfitTable() {
    _channel!.sink.add(json.encode({
      'profit_table': 1,
      'description': 1,
      'limit': 100,
    }));
  }

  void _calculateStats() {
    if (_profitTable == null) return;

    final transactions = _profitTable!['transactions'] as List?;
    if (transactions == null) return;

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

    for (var tx in transactions) {
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
    }

    setState(() {
      _todayProfit = todayProfit;
      _weekProfit = weekProfit;
      _monthProfit = monthProfit;
      _totalTrades = totalTrades;
      _winningTrades = wins;
      _losingTrades = losses;
    });
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Portfólio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              _fetchTransactions();
              _fetchProfitTable();
            },
          ),
        ],
      ),
      body: _isConnected
          ? RefreshIndicator(
              onRefresh: () async {
                _fetchTransactions();
                _fetchProfitTable();
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
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Saldo Total',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_balance.toStringAsFixed(2)} $_currency',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ID: $_loginId',
                          style: const TextStyle(
                            color: Colors.white54,
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
                          Icons.today,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildProfitCard(
                          '7 Dias',
                          _weekProfit,
                          Icons.date_range,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  _buildProfitCard(
                    '30 Dias',
                    _monthProfit,
                    Icons.calendar_month,
                    fullWidth: true,
                  ),

                  const SizedBox(height: 24),

                  // Stats Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Estatísticas',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
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
                        LinearProgressIndicator(
                          value: winRate / 100,
                          backgroundColor: const Color(0xFF2A2A2A),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            winRate >= 50 
                                ? const Color(0xFF00C896)
                                : const Color(0xFFFF4444),
                          ),
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Taxa de Vitória: ${winRate.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Recent Transactions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Transações Recentes',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: const Text(
                          'Ver Todas',
                          style: TextStyle(color: Color(0xFF0066FF)),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  if (_transactions.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      child: const Center(
                        child: Text(
                          'Nenhuma transação recente',
                          style: TextStyle(color: Colors.white54),
                        ),
                      ),
                    )
                  else
                    ..._transactions.take(10).map((tx) {
                      final amount = double.parse(tx['amount'].toString());
                      final isCredit = amount > 0;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isCredit 
                                    ? const Color(0xFF00C896).withOpacity(0.2)
                                    : const Color(0xFFFF4444).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                                color: isCredit ? const Color(0xFF00C896) : const Color(0xFFFF4444),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tx['action_type'] ?? 'Trade',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _formatDate(tx['transaction_time']),
                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${isCredit ? '+' : ''}\$${amount.abs().toStringAsFixed(2)}',
                              style: TextStyle(
                                color: isCredit ? const Color(0xFF00C896) : const Color(0xFFFF4444),
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                ],
              ),
            )
          : const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF0066FF)),
                  SizedBox(height: 16),
                  Text('Carregando...', style: TextStyle(color: Colors.white54)),
                ],
              ),
            ),
    );
  }

  Widget _buildProfitCard(String label, double profit, IconData icon, {bool fullWidth = false}) {
    final isProfit = profit >= 0;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: fullWidth ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: fullWidth ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              Icon(icon, color: Colors.white54, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${isProfit ? '+' : ''}\$${profit.toStringAsFixed(2)}',
            style: TextStyle(
              color: isProfit ? const Color(0xFF00C896) : const Color(0xFFFF4444),
              fontSize: fullWidth ? 24 : 20,
              fontWeight: FontWeight.bold,
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
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 13,
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