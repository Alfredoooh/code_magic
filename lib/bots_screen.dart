// bots_screen.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class BotsScreen extends StatefulWidget {
  final String token;

  const BotsScreen({Key? key, required this.token}) : super(key: key);

  @override
  State<BotsScreen> createState() => _BotsScreenState();
}

class _BotsScreenState extends State<BotsScreen> with AutomaticKeepAliveClientMixin {
  WebSocketChannel? _channel;
  bool _isConnected = false;
  List<TradingBot> _bots = [];
  double _balance = 0.0;
  String _currency = 'USD';

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
    _loadDefaultBots();
  }

  @override
  void dispose() {
    for (var bot in _bots) {
      bot.stop();
    }
    _channel?.sink.close();
    super.dispose();
  }

  void _loadDefaultBots() {
    _bots = [
      TradingBot(
        name: 'Martingale Bot',
        description: 'Dobra o stake após perda',
        strategy: BotStrategy.martingale,
        initialStake: 10.0,
        market: 'R_100',
        contractType: 'CALL',
      ),
      TradingBot(
        name: 'Anti-Martingale Bot',
        description: 'Dobra o stake após vitória',
        strategy: BotStrategy.antiMartingale,
        initialStake: 10.0,
        market: 'R_50',
        contractType: 'PUT',
      ),
      TradingBot(
        name: 'Fixed Stake Bot',
        description: 'Stake fixo em todas as operações',
        strategy: BotStrategy.fixedStake,
        initialStake: 15.0,
        market: 'BOOM1000',
        contractType: 'CALL',
      ),
      TradingBot(
        name: 'RSI Bot',
        description: 'Opera baseado no RSI',
        strategy: BotStrategy.rsi,
        initialStake: 20.0,
        market: 'R_100',
        contractType: 'CALL',
      ),
    ];
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
            });
          } else if (data['msg_type'] == 'buy') {
            _handleBotTrade(data['buy']);
          } else if (data['msg_type'] == 'proposal_open_contract') {
            _handleContractUpdate(data['proposal_open_contract']);
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

  void _handleBotTrade(Map<String, dynamic> contract) {
    for (var bot in _bots) {
      if (bot.isRunning && bot.currentContractId == null) {
        setState(() {
          bot.currentContractId = contract['contract_id'];
          bot.totalTrades++;
        });
        
        _channel!.sink.add(json.encode({
          'proposal_open_contract': 1,
          'contract_id': contract['contract_id'],
          'subscribe': 1,
        }));
        break;
      }
    }
  }

  void _handleContractUpdate(Map<String, dynamic> contract) {
    for (var bot in _bots) {
      if (bot.currentContractId == contract['contract_id']) {
        final profit = double.parse(contract['profit'].toString());
        
        if (contract['status'] == 'won' || contract['status'] == 'lost') {
          setState(() {
            bot.totalProfit += profit;
            bot.currentContractId = null;
            
            if (contract['status'] == 'won') {
              bot.wins++;
              bot.consecutiveLosses = 0;
              bot.consecutiveWins++;
            } else {
              bot.losses++;
              bot.consecutiveWins = 0;
              bot.consecutiveLosses++;
            }
            
            // Atualizar stake baseado na estratégia
            _updateBotStake(bot);
          });
          
          // Fazer próximo trade se bot ainda está ativo
          if (bot.isRunning) {
            Future.delayed(const Duration(seconds: 2), () {
              _placeBotTrade(bot);
            });
          }
        }
        break;
      }
    }
  }

  void _updateBotStake(TradingBot bot) {
    switch (bot.strategy) {
      case BotStrategy.martingale:
        if (bot.consecutiveLosses > 0) {
          bot.currentStake = bot.initialStake * (2 << (bot.consecutiveLosses - 1));
        } else {
          bot.currentStake = bot.initialStake;
        }
        break;
      
      case BotStrategy.antiMartingale:
        if (bot.consecutiveWins > 0) {
          bot.currentStake = bot.initialStake * (2 << (bot.consecutiveWins - 1));
        } else {
          bot.currentStake = bot.initialStake;
        }
        break;
      
      case BotStrategy.fixedStake:
        bot.currentStake = bot.initialStake;
        break;
      
      case BotStrategy.rsi:
        bot.currentStake = bot.initialStake;
        break;
    }
    
    // Limitar stake máximo
    if (bot.currentStake > bot.initialStake * 100) {
      bot.currentStake = bot.initialStake;
      bot.consecutiveLosses = 0;
      bot.consecutiveWins = 0;
    }
  }

  void _placeBotTrade(TradingBot bot) {
    if (!_isConnected || !bot.isRunning) return;

    _channel!.sink.add(json.encode({
      'buy': 1,
      'price': bot.currentStake,
      'parameters': {
        'contract_type': bot.contractType,
        'currency': _currency,
        'duration': 5,
        'duration_unit': 't',
        'symbol': bot.market,
        'amount': bot.currentStake,
        'basis': 'stake',
      },
    }));
  }

  void _toggleBot(TradingBot bot) {
    setState(() {
      if (bot.isRunning) {
        bot.stop();
      } else {
        bot.start();
        _placeBotTrade(bot);
      }
    });
  }

  void _showBotSettings(TradingBot bot) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                bot.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                bot.description,
                style: const TextStyle(color: Colors.white54, fontSize: 14),
              ),
              const SizedBox(height: 24),
              _buildSettingItem('Stake Inicial', '\$${bot.initialStake.toStringAsFixed(2)}'),
              _buildSettingItem('Mercado', bot.market),
              _buildSettingItem('Tipo de Contrato', bot.contractType),
              _buildSettingItem('Estratégia', bot.strategy.toString().split('.').last),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0066FF),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Fechar',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Bots de Trading'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '${_balance.toStringAsFixed(2)} $_currency',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _isConnected
          ? ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _bots.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final bot = _bots[index];
                return _buildBotCard(bot);
              },
            )
          : const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF0066FF)),
                  SizedBox(height: 16),
                  Text(
                    'Conectando...',
                    style: TextStyle(color: Colors.white54),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildBotCard(TradingBot bot) {
    final winRate = bot.totalTrades > 0 
        ? (bot.wins / bot.totalTrades * 100) 
        : 0.0;
    final isProfit = bot.totalProfit >= 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: bot.isRunning 
              ? const Color(0xFF0066FF) 
              : Colors.white.withOpacity(0.05),
          width: bot.isRunning ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: bot.isRunning 
                      ? const Color(0xFF0066FF).withOpacity(0.2)
                      : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.smart_toy,
                  color: bot.isRunning ? const Color(0xFF0066FF) : Colors.white54,
                  size: 28,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bot.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      bot.description,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.settings, color: Colors.white54),
                onPressed: () => _showBotSettings(bot),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Trades', bot.totalTrades.toString()),
                Container(width: 1, height: 30, color: Colors.white12),
                _buildStatItem('Win Rate', '${winRate.toStringAsFixed(1)}%'),
                Container(width: 1, height: 30, color: Colors.white12),
                _buildStatItem(
                  'Lucro',
                  '${isProfit ? '+' : ''}\$${bot.totalProfit.toStringAsFixed(2)}',
                  color: isProfit ? const Color(0xFF00C896) : const Color(0xFFFF4444),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _toggleBot(bot),
                  icon: Icon(bot.isRunning ? Icons.stop : Icons.play_arrow),
                  label: Text(bot.isRunning ? 'Parar' : 'Iniciar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: bot.isRunning 
                        ? const Color(0xFFFF4444)
                        : const Color(0xFF00C896),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              if (bot.isRunning) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0066FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, {Color? color}) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color ?? Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

enum BotStrategy {
  martingale,
  antiMartingale,
  fixedStake,
  rsi,
}

class TradingBot {
  final String name;
  final String description;
  final BotStrategy strategy;
  final double initialStake;
  final String market;
  final String contractType;
  
  bool isRunning = false;
  double currentStake;
  int totalTrades = 0;
  int wins = 0;
  int losses = 0;
  double totalProfit = 0.0;
  String? currentContractId;
  int consecutiveWins = 0;
  int consecutiveLosses = 0;

  TradingBot({
    required this.name,
    required this.description,
    required this.strategy,
    required this.initialStake,
    required this.market,
    required this.contractType,
  }) : currentStake = initialStake;

  void start() {
    isRunning = true;
    currentStake = initialStake;
  }

  void stop() {
    isRunning = false;
    currentContractId = null;
  }

  void reset() {
    totalTrades = 0;
    wins = 0;
    losses = 0;
    totalProfit = 0.0;
    currentStake = initialStake;
    consecutiveWins = 0;
    consecutiveLosses = 0;
  }
}