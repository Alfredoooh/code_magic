// lib/screens/trading_chart_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../widgets/app_ui_components.dart';
import '../services/deriv_service.dart';
import '../widgets/trading_chart_widget.dart';

class TradingChartScreen extends StatefulWidget {
  final DerivService derivService;

  const TradingChartScreen({Key? key, required this.derivService}) : super(key: key);

  @override
  _TradingChartScreenState createState() => _TradingChartScreenState();
}

class _TradingChartScreenState extends State<TradingChartScreen> {
  String _selectedSymbol = 'R_10';
  String _contractType = 'CALL';
  String _duration = '5';
  String _durationType = 't';
  double _stakeAmount = 1.0;
  String? _barrier;
  String _currency = 'USD';
  
  double _currentTick = 0.0;
  double _payout = 0.0;
  String? _proposalId;
  
  double _totalProfit = 0.0;
  double _totalLoss = 0.0;
  int _winCount = 0;
  int _lossCount = 0;
  
  bool _autoTradingEnabled = false;
  String _autoStrategy = 'martingale';
  int _autoTradeCount = 0;
  int _consecutiveLosses = 0;
  Timer? _autoTradeTimer;
  
  List<Map<String, dynamic>> _tradeHistory = [];
  StreamSubscription? _tickSub;
  StreamSubscription? _proposalSub;
  StreamSubscription? _contractSub;
  StreamSubscription? _accountSub;

  final List<String> _availableSymbols = [
    'R_10', 'R_25', 'R_50', 'R_75', 'R_100',
    '1HZ10V', '1HZ25V', '1HZ50V', '1HZ75V', '1HZ100V',
    'frxEURUSD', 'frxGBPUSD', 'frxAUDUSD', 'frxUSDJPY',
  ];

  final Map<String, List<Map<String, String>>> _contractCategories = {
    'Rise/Fall': [
      {'id': 'CALL', 'name': 'Rise', 'icon': '📈'},
      {'id': 'PUT', 'name': 'Fall', 'icon': '📉'},
    ],
    'Higher/Lower': [
      {'id': 'CALLE', 'name': 'Higher', 'icon': '⬆️'},
      {'id': 'PUTE', 'name': 'Lower', 'icon': '⬇️'},
    ],
    'Matches/Differs': [
      {'id': 'DIGITMATCH', 'name': 'Matches', 'icon': '🎯'},
      {'id': 'DIGITDIFF', 'name': 'Differs', 'icon': '❌'},
    ],
    'Even/Odd': [
      {'id': 'DIGITEVEN', 'name': 'Even', 'icon': '2️⃣'},
      {'id': 'DIGITODD', 'name': 'Odd', 'icon': '1️⃣'},
    ],
    'Over/Under': [
      {'id': 'DIGITOVER', 'name': 'Over', 'icon': '🔼'},
      {'id': 'DIGITUNDER', 'name': 'Under', 'icon': '🔽'},
    ],
    'Touch/No Touch': [
      {'id': 'ONETOUCH', 'name': 'Touch', 'icon': '👆'},
      {'id': 'NOTOUCH', 'name': 'No Touch', 'icon': '🚫'},
    ],
    'Ends Between/Outside': [
      {'id': 'RANGE', 'name': 'Between', 'icon': '↔️'},
      {'id': 'UPORDOWN', 'name': 'Outside', 'icon': '↕️'},
    ],
    'Stays/Goes': [
      {'id': 'EXPIRYMISS', 'name': 'Stays', 'icon': '🎯'},
      {'id': 'EXPIRYRANGE', 'name': 'Goes', 'icon': '💥'},
    ],
  };

  final Map<String, String> _autoStrategies = {
    'martingale': 'Martingale (2x após perda)',
    'anti_martingale': 'Anti-Martingale (2x após ganho)',
    'dalembert': "D'Alembert (+\$0.35)",
    'fibonacci': 'Fibonacci (Sequência)',
    'fixed': 'Valor Fixo',
    'percentage': 'Percentual (5%)',
  };

  @override
  void initState() {
    super.initState();
    _setupListeners();
    widget.derivService.subscribeTicks(_selectedSymbol);
    _updateProposal();
  }

  @override
  void dispose() {
    _tickSub?.cancel();
    _proposalSub?.cancel();
    _contractSub?.cancel();
    _accountSub?.cancel();
    _autoTradeTimer?.cancel();
    super.dispose();
  }

  void _setupListeners() {
    // Escutar mudanças de conta para obter moeda
    _accountSub = widget.derivService.accountInfo.listen((accountInfo) {
      if (mounted && accountInfo != null) {
        setState(() {
          _currency = accountInfo['currency'] ?? 'USD';
        });
      }
    });

    _tickSub = widget.derivService.tickStream.listen((tick) {
      if (mounted) {
        setState(() => _currentTick = (tick['quote'] ?? 0).toDouble());
      }
    });

    _proposalSub = widget.derivService.proposalStream.listen((proposal) {
      if (mounted) {
        setState(() {
          _payout = (proposal['payout'] ?? 0).toDouble();
          _proposalId = proposal['id'];
        });
      }
    });

    _contractSub = widget.derivService.contractStream.listen((contract) {
      if (mounted) _handleContractResult(contract);
    });
  }

  void _handleContractResult(Map<String, dynamic> contract) {
    if (contract['status'] == 'sold' || contract['status'] == 'won' || contract['status'] == 'lost') {
      final buyPrice = (contract['buy_price'] ?? 0).toDouble();
      final sellPrice = (contract['sell_price'] ?? contract['bid_price'] ?? 0).toDouble();
      final profit = sellPrice - buyPrice;
      final isWin = profit > 0;

      setState(() {
        _tradeHistory.insert(0, {
          'timestamp': DateTime.now(),
          'symbol': _selectedSymbol,
          'type': _contractType,
          'amount': buyPrice,
          'payout': sellPrice,
          'profit': profit,
          'status': isWin ? 'won' : 'lost',
        });

        if (isWin) {
          _totalProfit += profit;
          _winCount++;
          _consecutiveLosses = 0;
          
          if (_autoTradingEnabled && _autoStrategy == 'anti_martingale') {
            _stakeAmount *= 2;
          } else if (_autoStrategy == 'fibonacci' || _autoStrategy == 'dalembert') {
            _stakeAmount = 1.0;
          }
        } else {
          _totalLoss += profit.abs();
          _lossCount++;
          _consecutiveLosses++;
          
          if (_autoTradingEnabled) {
            _applyLossStrategy();
          }
        }
      });
    }
  }

  void _applyLossStrategy() {
    switch (_autoStrategy) {
      case 'martingale':
        _stakeAmount *= 2;
        break;
      case 'dalembert':
        _stakeAmount += 0.35;
        break;
      case 'fibonacci':
        if (_consecutiveLosses <= 1) {
          _stakeAmount = 1.0;
        } else if (_consecutiveLosses == 2) {
          _stakeAmount = 1.0;
        } else if (_consecutiveLosses == 3) {
          _stakeAmount = 2.0;
        } else if (_consecutiveLosses == 4) {
          _stakeAmount = 3.0;
        } else if (_consecutiveLosses >= 5) {
          _stakeAmount = 5.0;
        }
        break;
      case 'percentage':
        _stakeAmount = widget.derivService.balance * 0.05;
        break;
    }
    
    if (_stakeAmount < 0.35) _stakeAmount = 0.35;
    if (_stakeAmount > widget.derivService.balance * 0.5) {
      _stakeAmount = widget.derivService.balance * 0.1;
    }
  }

  void _updateProposal() {
    widget.derivService.getProposal(
      contractType: _contractType,
      symbol: _selectedSymbol,
      currency: _currency,
      amount: _stakeAmount,
      duration: _duration,
      durationType: _durationType,
      barrier: _barrier,
    );
  }

  void _executeTrade(String type) {
    if (_proposalId != null && _payout > 0) {
      widget.derivService.buyContract(_proposalId!, _payout);
      _autoTradeCount++;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Trade #$_autoTradeCount executado'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  void _toggleAutoTrading() {
    setState(() => _autoTradingEnabled = !_autoTradingEnabled);

    if (_autoTradingEnabled) {
      _autoTradeTimer = Timer.periodic(Duration(seconds: 8), (timer) {
        if (_proposalId != null && _payout > 0) {
          _executeTrade(_contractType);
        }
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Auto: ${_autoStrategies[_autoStrategy]}'), 
          backgroundColor: AppColors.primary),
      );
    } else {
      _autoTradeTimer?.cancel();
      _autoTradeCount = 0;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Auto-trading OFF'), backgroundColor: Colors.grey),
      );
    }
  }

  double get _winRate {
    final total = _winCount + _lossCount;
    return total > 0 ? (_winCount / total) * 100 : 0.0;
  }

  double get _netProfit => _totalProfit - _totalLoss;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppSecondaryAppBar(
        title: 'Trading',
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined, color: AppColors.primary),
            onPressed: () => _showStrategySettings(isDark),
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: AppColors.primary),
            onPressed: () {
              setState(() {
                _totalProfit = 0;
                _totalLoss = 0;
                _winCount = 0;
                _lossCount = 0;
                _tradeHistory.clear();
                _consecutiveLosses = 0;
                _autoTradeCount = 0;
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _buildStatsCard(isDark),
            SizedBox(height: 12),
            _buildChartWidget(isDark),
            SizedBox(height: 12),
            _buildTickInfo(isDark),
            SizedBox(height: 12),
            _buildTradingPanel(isDark),
            SizedBox(height: 12),
            if (_tradeHistory.isNotEmpty) _buildTradeHistory(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(bool isDark) {
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Row(
        children: [
          Expanded(child: _buildStat('P&L', '${_netProfit >= 0 ? '+' : ''}\$${_netProfit.toStringAsFixed(2)}', 
            _netProfit >= 0 ? Colors.green : Colors.red)),
          _divider(isDark),
          Expanded(child: _buildStat('Taxa', '${_winRate.toStringAsFixed(1)}%', 
            _winRate >= 50 ? Colors.green : Colors.orange)),
          _divider(isDark),
          Expanded(child: _buildStat('W/L', '$_winCount/$_lossCount', Colors.blue)),
        ],
      ),
    );
  }

  Widget _divider(bool isDark) => Container(
    width: 1, height: 35, 
    color: isDark ? AppColors.darkBorder : AppColors.lightBorder
  );

  Widget _buildStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey)),
        SizedBox(height: 3),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildChartWidget(bool isDark) {
    return TradingChartWidget(symbol: _selectedSymbol, tradeHistory: _tradeHistory);
  }

  Widget _buildTickInfo(bool isDark) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Tick:', style: TextStyle(fontSize: 13, color: Colors.grey)),
          Text(_currentTick.toStringAsFixed(5),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTradingPanel(bool isDark) {
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Painel', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
              CupertinoSwitch(
                value: _autoTradingEnabled,
                activeColor: AppColors.primary,
                onChanged: (v) => _toggleAutoTrading(),
              ),
            ],
          ),
          SizedBox(height: 12),
          
          Text('Símbolo', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          SizedBox(height: 6),
          _buildSymbolSelector(isDark),
          SizedBox(height: 12),
          
          Text('Contratos', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          SizedBox(height: 6),
          _buildContractSelector(isDark),
          SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Duração', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    SizedBox(height: 6),
                    _buildInputField(isDark, _duration, (v) {
                      if (v.isNotEmpty) {
                        setState(() => _duration = v);
                        _updateProposal();
                      }
                    }),
                  ],
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Stake', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    SizedBox(height: 6),
                    _buildInputField(isDark, '\$${_stakeAmount.toStringAsFixed(2)}', (v) {
                      if (v.isNotEmpty) {
                        final amt = double.tryParse(v);
                        if (amt != null && amt >= 0.35) {
                          setState(() => _stakeAmount = amt);
                          _updateProposal();
                        }
                      }
                    }, isNumeric: true),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          
          if (_payout > 0)
            Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Payout:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  Text('\$${_payout.toStringAsFixed(2)}', 
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
                ],
              ),
            ),
          
          SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _buildTradeButton(isDark, 'CALL', Icons.arrow_upward, Colors.green),
              ),
              SizedBox(width: 10),
              Expanded(
                child: _buildTradeButton(isDark, 'PUT', Icons.arrow_downward, Colors.red),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSymbolSelector(bool isDark) {
    return Container(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _availableSymbols.length,
        itemBuilder: (context, i) {
          final symbol = _availableSymbols[i];
          final isSelected = symbol == _selectedSymbol;
          
          return GestureDetector(
            onTap: () {
              setState(() => _selectedSymbol = symbol);
              widget.derivService.subscribeTicks(symbol);
              _updateProposal();
            },
            child: Container(
              margin: EdgeInsets.only(right: 6),
              padding: EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : (isDark ? AppColors.darkBackground : Colors.grey[200]),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Text(symbol, style: TextStyle(
                color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black),
                fontWeight: FontWeight.w600, fontSize: 12)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContractSelector(bool isDark) {
    return Column(
      children: _contractCategories.entries.map((category) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(top: 8, bottom: 4),
              child: Text(category.key, 
                style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
            ),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: category.value.map((contract) {
                final isSelected = contract['id'] == _contractType;
                
                return GestureDetector(
                  onTap: () {
                    setState(() => _contractType = contract['id']!);
                    _updateProposal();
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : (isDark ? AppColors.darkBackground : Colors.grey[200]),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isSelected ? AppColors.primary : 
                        (isDark ? AppColors.darkBorder : AppColors.lightBorder)),
                    ),
                    child: Text('${contract['icon']} ${contract['name']}',
                      style: TextStyle(
                        color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black),
                        fontSize: 11, fontWeight: FontWeight.w600)),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildInputField(bool isDark, String hint, Function(String) onChanged, {bool isNumeric = false}) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: TextField(
        keyboardType: isNumeric ? TextInputType.numberWithOptions(decimal: true) : TextInputType.number,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 13),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey, fontSize: 13),
        ),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildTradeButton(bool isDark, String type, IconData icon, Color color) {
    return GestureDetector(
      onTap: () {
        setState(() => _contractType = type);
        _updateProposal();
        Future.delayed(Duration(milliseconds: 300), () {
          _executeTrade(type);
        });
      },
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text(
              type == 'CALL' ? 'Rise' : 'Fall',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showStrategySettings(bool isDark) {
    AppBottomSheet.show(context, height: 400, child: Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Estratégia', 
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
          ..._autoStrategies.entries.map((e) {
            return GestureDetector(
              onTap: () {
                setState(() => _autoStrategy = e.key);
                Navigator.pop(context);
              },
              child: Container(
                margin: EdgeInsets.only(bottom: 8),
                padding: EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _autoStrategy == e.key ? AppColors.primary.withOpacity(0.1) : 
                    (isDark ? AppColors.darkBackground : Colors.grey[100]),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _autoStrategy == e.key ? AppColors.primary : 
                      (isDark ? AppColors.darkBorder : AppColors.lightBorder)),
                ),
                child: Row(
                  children: [
                    if (_autoStrategy == e.key) 
                      Icon(Icons.check_circle, color: AppColors.primary, size: 20),
                    if (_autoStrategy == e.key) SizedBox(width: 10),
                    Expanded(child: Text(e.value, 
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    ));
  }

  Widget _buildTradeHistory(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Histórico', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        SizedBox(height: 10),
        ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: _tradeHistory.length > 15 ? 15 : _tradeHistory.length,
          itemBuilder: (context, i) {
            final trade = _tradeHistory[i];
            final isWin = trade['status'] == 'won';
            final profit = trade['profit'] as double;

            return Container(
              margin: EdgeInsets.only(bottom: 6),
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isWin ? 
                  Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 30, height: 30,
                    decoration: BoxDecoration(
                      color: (isWin ? Colors.green : Colors.red).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(isWin ? Icons.trending_up : Icons.trending_down,
                      color: isWin ? Colors.green : Colors.red, size: 16),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${trade['symbol']}',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        Text('\$${(trade['amount'] as double).toStringAsFixed(2)}',
                          style: TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Text('${profit >= 0 ? '+' : ''}\$${profit.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold,
                      color: isWin ? Colors.green : Colors.red)),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}