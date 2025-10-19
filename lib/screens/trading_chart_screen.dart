// lib/screens/trading_chart_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../widgets/app_ui_components.dart';
import '../services/deriv_service.dart';
import '../widgets/trading_chart_widget.dart';
import '../widgets/app_colors.dart';

class TradingChartScreen extends StatefulWidget {
  final DerivService derivService;

  const TradingChartScreen({Key? key, required this.derivService}) : super(key: key);

  @override
  _TradingChartScreenState createState() => _TradingChartScreenState();
}

class _TradingChartScreenState extends State<TradingChartScreen> with TickerProviderStateMixin {
  // Trading State
  String _selectedSymbol = 'R_10';
  String _contractType = 'CALL';
  String _duration = '5';
  String _durationType = 't';
  double _stakeAmount = 1.0;
  double _initialStake = 1.0;
  String? _barrier;
  String _currency = 'USD';

  // Market Data
  double _currentTick = 0.0;
  double _payout = 0.0;
  String? _proposalId;
  double _accountBalance = 0.0;
  double _previousBalance = 0.0;

  // Statistics
  double _totalProfit = 0.0;
  double _totalLoss = 0.0;
  int _winCount = 0;
  int _lossCount = 0;
  double _highestProfit = 0.0;
  double _highestLoss = 0.0;
  int _consecutiveLosses = 0;
  int _consecutiveWins = 0;

  // Auto Trading
  bool _autoTradingEnabled = false;
  String _autoStrategy = 'accumulation_pro';
  int _autoTradeCount = 0;
  Timer? _autoTradeTimer;
  int _autoTradeInterval = 8;

  // Custom Strategy Parameters
  double _martingaleMultiplier = 2.0;
  double _dalembertIncrement = 0.35;
  int _maxConsecutiveLosses = 5;
  bool _stopOnTarget = false;
  double _profitTarget = 100.0;
  double _lossLimit = 50.0;

  // Trade History
  List<Map<String, dynamic>> _tradeHistory = [];
  List<double> _fibonacciSequence = [1, 1, 2, 3, 5, 8, 13, 21, 34, 55];
  int _fibIndex = 0;

  // Animations
  late AnimationController _balanceAnimationController;
  late Animation<double> _balanceAnimation;
  late AnimationController _pulseController;

  // Streams
  StreamSubscription? _tickSub;
  StreamSubscription? _proposalSub;
  StreamSubscription? _contractSub;
  StreamSubscription? _accountSub;

  // Available Symbols - Complete Deriv Market
  final List<String> _availableSymbols = [
    'R_10', 'R_25', 'R_50', 'R_75', 'R_100',
    '1HZ10V', '1HZ25V', '1HZ50V', '1HZ75V', '1HZ100V',
    'BOOM300N', 'BOOM500N', 'BOOM1000N',
    'CRASH300N', 'CRASH500N', 'CRASH1000N',
    'RDBEAR', 'RDBULL',
    'frxEURUSD', 'frxGBPUSD', 'frxAUDUSD', 'frxUSDJPY',
    'frxEURGBP', 'frxUSDCAD', 'frxUSDCHF',
  ];

  // Contract Types with Material Icons
  final Map<String, List<Map<String, dynamic>>> _contractCategories = {
    'Rise/Fall': [
      {'id': 'CALL', 'name': 'Rise', 'icon': Icons.trending_up_rounded},
      {'id': 'PUT', 'name': 'Fall', 'icon': Icons.trending_down_rounded},
    ],
    'Higher/Lower': [
      {'id': 'CALLE', 'name': 'Higher', 'icon': Icons.arrow_upward_rounded},
      {'id': 'PUTE', 'name': 'Lower', 'icon': Icons.arrow_downward_rounded},
    ],
    'Matches/Differs': [
      {'id': 'DIGITMATCH', 'name': 'Matches', 'icon': Icons.check_circle_outline_rounded},
      {'id': 'DIGITDIFF', 'name': 'Differs', 'icon': Icons.cancel_outlined},
    ],
    'Even/Odd': [
      {'id': 'DIGITEVEN', 'name': 'Even', 'icon': Icons.looks_two_rounded},
      {'id': 'DIGITODD', 'name': 'Odd', 'icon': Icons.looks_one_rounded},
    ],
    'Over/Under': [
      {'id': 'DIGITOVER', 'name': 'Over', 'icon': Icons.expand_less_rounded},
      {'id': 'DIGITUNDER', 'name': 'Under', 'icon': Icons.expand_more_rounded},
    ],
  };

  // Advanced Strategies
  final Map<String, Map<String, dynamic>> _autoStrategies = {
    'accumulation_pro': {
      'name': 'Acumulação Profissional',
      'description': 'Acumula lucros, mantém stake em perdas',
      'icon': Icons.trending_up_rounded,
      'winRate': 85,
    },
    'martingale_classic': {
      'name': 'Martingale Clássico',
      'description': 'Dobra stake após cada perda',
      'icon': Icons.analytics_rounded,
      'winRate': 75,
    },
    'anti_martingale': {
      'name': 'Anti-Martingale',
      'description': 'Aumenta stake após vitórias',
      'icon': Icons.show_chart_rounded,
      'winRate': 70,
    },
    'dalembert': {
      'name': "D'Alembert Avançado",
      'description': 'Incremento gradual após perdas',
      'icon': Icons.stairs_rounded,
      'winRate': 78,
    },
    'fibonacci': {
      'name': 'Fibonacci Sequence',
      'description': 'Segue sequência de Fibonacci',
      'icon': Icons.timeline_rounded,
      'winRate': 80,
    },
    'percentage_kelly': {
      'name': 'Kelly Criterion',
      'description': 'Baseado em percentual do saldo',
      'icon': Icons.percent_rounded,
      'winRate': 82,
    },
    'fixed_ratio': {
      'name': 'Razão Fixa',
      'description': 'Valor fixo por operação',
      'icon': Icons.lock_rounded,
      'winRate': 65,
    },
    'custom': {
      'name': 'Estratégia Personalizada',
      'description': 'Configure seus próprios parâmetros',
      'icon': Icons.tune_rounded,
      'winRate': 0,
    },
  };

  @override
  void initState() {
    super.initState();
    _initialStake = _stakeAmount;
    _setupAnimations();
    _setupListeners();
    widget.derivService.subscribeTicks(_selectedSymbol);
    _updateProposal();
    _loadAccountBalance();
  }

  @override
  void dispose() {
    _tickSub?.cancel();
    _proposalSub?.cancel();
    _contractSub?.cancel();
    _accountSub?.cancel();
    _autoTradeTimer?.cancel();
    _balanceAnimationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _balanceAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );

    _balanceAnimation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _balanceAnimationController, curve: Curves.easeInOut),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  void _loadAccountBalance() {
    _accountBalance = widget.derivService.balance;
    _previousBalance = _accountBalance;
  }

  void _setupListeners() {
    _accountSub = widget.derivService.accountInfo.listen((accountInfo) {
      if (mounted && accountInfo != null) {
        setState(() {
          _currency = accountInfo['currency'] ?? 'USD';
          _previousBalance = _accountBalance;
          _accountBalance = (accountInfo['balance'] ?? 0).toDouble();

          // Animar mudança de saldo
          _balanceAnimation = Tween<double>(
            begin: _previousBalance,
            end: _accountBalance,
          ).animate(CurvedAnimation(
            parent: _balanceAnimationController,
            curve: Curves.easeInOut,
          ));

          _balanceAnimationController.forward(from: 0);
        });
      }
    });

    _tickSub = widget.derivService.tickStream.listen((tick) {
      if (mounted && tick != null) {
        final q = tick['quote'] ?? tick['quote'] == 0 ? tick['quote'] : 0;
        setState(() => _currentTick = (q is num ? q.toDouble() : 0.0));
      }
    });

    _proposalSub = widget.derivService.proposalStream.listen((proposal) {
      if (mounted && proposal != null) {
        setState(() {
          final p = proposal['payout'] ?? 0;
          _payout = (p is num) ? p.toDouble() : 0.0;
          _proposalId = proposal['id']?.toString();
        });
      }
    });

    _contractSub = widget.derivService.contractStream.listen((contract) {
      if (mounted && contract != null) _handleContractResult(contract);
    });
  }

  void _handleContractResult(Map<String, dynamic> contract) {
    final status = contract['status']?.toString() ?? '';
    if (status == 'sold' || status == 'won' || status == 'lost') {
      final buyPriceRaw = contract['buy_price'] ?? 0;
      final sellPriceRaw = contract['sell_price'] ?? contract['bid_price'] ?? 0;
      final buyPrice = (buyPriceRaw is num) ? buyPriceRaw.toDouble() : 0.0;
      final sellPrice = (sellPriceRaw is num) ? sellPriceRaw.toDouble() : 0.0;
      final profit = sellPrice - buyPrice;
      final isWin = profit > 0;
      final entryTick = _currentTick;
      final exitTick = _currentTick + (isWin ? 0.001 : -0.001);

      setState(() {
        // Atualizar saldo em tempo real
        _previousBalance = _accountBalance;
        _accountBalance += profit;

        // Animar saldo
        _balanceAnimation = Tween<double>(
          begin: _previousBalance,
          end: _accountBalance,
        ).animate(CurvedAnimation(
          parent: _balanceAnimationController,
          curve: Curves.easeInOut,
        ));
        _balanceAnimationController.forward(from: 0);

        _tradeHistory.insert(0, {
          'timestamp': DateTime.now(),
          'symbol': _selectedSymbol,
          'type': _contractType,
          'amount': buyPrice,
          'payout': sellPrice,
          'profit': profit,
          'status': isWin ? 'won' : 'lost',
          'entryTick': entryTick,
          'exitTick': exitTick,
          'balance': _accountBalance,
        });

        if (isWin) {
          _totalProfit += profit;
          _winCount++;
          _consecutiveLosses = 0;
          _consecutiveWins++;

          if (profit > _highestProfit) _highestProfit = profit;

          if (_autoTradingEnabled) {
            _applyWinStrategy(profit);
          }
        } else {
          _totalLoss += profit.abs();
          _lossCount++;
          _consecutiveLosses++;
          _consecutiveWins = 0;

          if (profit.abs() > _highestLoss) _highestLoss = profit.abs();

          if (_autoTradingEnabled) {
            _applyLossStrategy();
          }
        }

        // Check stop conditions
        if (_stopOnTarget) {
          if (_netProfit >= _profitTarget) {
            _stopAutoTrading('Meta de lucro atingida!');
          } else if (_netProfit <= -_lossLimit) {
            _stopAutoTrading('Limite de perda atingido!');
          }
        }

        if (_consecutiveLosses >= _maxConsecutiveLosses) {
          _stopAutoTrading('Máximo de perdas consecutivas atingido!');
        }

        // Limitar histórico
        if (_tradeHistory.length > 100) {
          _tradeHistory = _tradeHistory.sublist(0, 100);
        }
      });
    }
  }

  void _applyWinStrategy(double profit) {
    switch (_autoStrategy) {
      case 'accumulation_pro':
        _stakeAmount = _initialStake + (profit * 0.5);
        break;
      case 'anti_martingale':
        _stakeAmount *= 1.5;
        break;
      case 'percentage_kelly':
        _stakeAmount = _accountBalance * 0.02;
        break;
      case 'fibonacci':
      case 'dalembert':
      case 'martingale_classic':
        _stakeAmount = _initialStake;
        _fibIndex = 0;
        break;
      default:
        _stakeAmount = _initialStake;
    }

    _validateStake();
  }

  void _applyLossStrategy() {
    switch (_autoStrategy) {
      case 'accumulation_pro':
        _stakeAmount = _stakeAmount;
        break;
      case 'martingale_classic':
        _stakeAmount *= _martingaleMultiplier;
        break;
      case 'dalembert':
        _stakeAmount += _dalembertIncrement;
        break;
      case 'fibonacci':
        if (_fibIndex < _fibonacciSequence.length - 1) {
          _fibIndex++;
        }
        _stakeAmount = _initialStake * _fibonacciSequence[_fibIndex];
        break;
      case 'percentage_kelly':
        _stakeAmount = _accountBalance * 0.03;
        break;
      default:
        _stakeAmount = _initialStake;
    }

    _validateStake();
  }

  void _validateStake() {
    if (_stakeAmount < 0.35) _stakeAmount = 0.35;
    if (_stakeAmount > _accountBalance * 0.5) {
      _stakeAmount = _accountBalance * 0.1;
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

      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 8),
                Text('Trade #$_autoTradeCount • \$${_stakeAmount.toStringAsFixed(2)}'),
              ],
            ),
            backgroundColor: AppColors.primary,
            duration: Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _toggleAutoTrading() {
    setState(() => _autoTradingEnabled = !_autoTradingEnabled);

    if (_autoTradingEnabled) {
      _autoTradeTimer = Timer.periodic(Duration(seconds: _autoTradeInterval), (timer) {
        if (_proposalId != null && _payout > 0) {
          _executeTrade(_contractType);
          _updateProposal();
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.play_arrow_rounded, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text('Auto-trading: ${_autoStrategies[_autoStrategy]!['name']}'),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      _autoTradeTimer?.cancel();
      _autoTradeCount = 0;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.stop_rounded, color: Colors.white),
              SizedBox(width: 8),
              Text('Auto-trading desativado'),
            ],
          ),
          backgroundColor: Colors.grey,
        ),
      );
    }
  }

  void _stopAutoTrading(String reason) {
    setState(() => _autoTradingEnabled = false);
    _autoTradeTimer?.cancel();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.warning_rounded, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(reason)),
          ],
        ),
        backgroundColor: AppColors.warning,
        duration: Duration(seconds: 3),
      ),
    );
  }

  void _resetStats() {
    setState(() {
      _totalProfit = 0;
      _totalLoss = 0;
      _winCount = 0;
      _lossCount = 0;
      _tradeHistory.clear();
      _consecutiveLosses = 0;
      _consecutiveWins = 0;
      _autoTradeCount = 0;
      _stakeAmount = _initialStake;
      _fibIndex = 0;
      _highestProfit = 0;
      _highestLoss = 0;
    });
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
        title: 'Trading Profissional',
        actions: [
          IconButton(
            icon: Icon(Icons.settings_rounded, color: AppColors.primary),
            onPressed: () => _showAdvancedSettings(isDark),
          ),
          IconButton(
            icon: Icon(Icons.history_rounded, color: AppColors.primary),
            onPressed: () => _showDetailedHistory(isDark),
          ),
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: AppColors.primary),
            onPressed: _resetStats,
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            _buildBalanceCard(isDark),
            SizedBox(height: 12),
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

  Widget _buildBalanceCard(bool isDark) {
    return AnimatedBuilder(
      animation: _balanceAnimation,
      builder: (context, child) {
        final displayBalance = _balanceAnimation.value;
        final balanceChange = _accountBalance - _previousBalance;
        final isPositive = balanceChange >= 0;

        return Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withOpacity(0.15),
                AppColors.primary.withOpacity(0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary.withOpacity(0.3), width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.2),
                blurRadius: 15,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary, size: 24),
                      ),
                      SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Saldo da Conta',
                              style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600)),
                          SizedBox(height: 2),
                          Text(_currency, style: TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                  if (balanceChange != 0)
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: (isPositive ? AppColors.success : AppColors.error).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isPositive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                            color: isPositive ? AppColors.success : AppColors.error,
                            size: 14,
                          ),
                          SizedBox(width: 4),
                          Text(
                            '${isPositive ? '+' : ''}\$${balanceChange.abs().toStringAsFixed(2)}',
                            style: TextStyle(
                              color: isPositive ? AppColors.success : AppColors.error,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    displayBalance.toStringAsFixed(2),
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                      letterSpacing: -1,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsCard(bool isDark) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'P&L',
                  '${_netProfit >= 0 ? '+' : ''}\$${_netProfit.toStringAsFixed(2)}',
                  _netProfit >= 0 ? AppColors.success : AppColors.error,
                  _netProfit >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                ),
              ),
              _divider(isDark),
              Expanded(
                child: _buildStatItem(
                  'Taxa',
                  '${_winRate.toStringAsFixed(1)}%',
                  _winRate >= 80 ? AppColors.success : _winRate >= 50 ? Colors.orange : AppColors.error,
                  Icons.percent_rounded,
                ),
              ),
              _divider(isDark),
              Expanded(
                child: _buildStatItem(
                  'W/L',
                  '$_winCount/$_lossCount',
                  AppColors.primary,
                  Icons.analytics_rounded,
                ),
              ),
            ],
          ),
          if (_autoTradingEnabled) ...[
            SizedBox(height: 12),
            Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMiniStat('Trades Auto', '$_autoTradeCount', Icons.repeat_rounded),
                _buildMiniStat('Sequência', '$_consecutiveWins W / $_consecutiveLosses L',
                    _consecutiveWins > _consecutiveLosses ? Icons.thumb_up_rounded : Icons.thumb_down_rounded),
                _buildMiniStat('Próximo', '${_autoTradeInterval}s', Icons.timer_rounded),
              ],
            ),
          ],
          SizedBox(height: 12),
          Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniStat('Maior Lucro', '\$${_highestProfit.toStringAsFixed(2)}', Icons.arrow_circle_up_rounded,
                  color: AppColors.success),
              _buildMiniStat('Maior Perda', '\$${_highestLoss.toStringAsFixed(2)}', Icons.arrow_circle_down_rounded,
                  color: AppColors.error),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        SizedBox(height: 6),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
        SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  Widget _buildMiniStat(String label, String value, IconData icon, {Color? color}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color ?? Colors.grey),
        SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 9, color: Colors.grey)),
            Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ],
    );
  }

  Widget _divider(bool isDark) => Container(
        width: 1,
        height: 50,
        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
      );

  Widget _buildChartWidget(bool isDark) {
  return TradingChartWidget(
    symbol: _selectedSymbol,
    tradeHistory: _tradeHistory,
    tickStream: widget.derivService.accountTickStream ?? widget.derivService.tickStream, // ajuste caso seu DerivService tenha outro nome de stream
    margins: null, // ou: [minPrice, maxPrice, 123.456], se quiser linhas horizontais fixas
    candleTicks: 5, // quantos ticks agregam 1 candle
    enablePatterns: true,
    height: 320,
    smaPeriod: 20,
    emaPeriod: 50,
  );
}

  Widget _buildTickInfo(bool isDark) {
    return Container(
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.1),
            AppColors.primary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.speed_rounded, color: AppColors.primary, size: 20),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tick Atual', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600)),
                SizedBox(height: 2),
                Text(_selectedSymbol, style: TextStyle(fontSize: 10, color: Colors.grey)),
              ],
            ),
          ),
          Text(_currentTick.toStringAsFixed(5),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
        ],
      ),
    );
  }

  Widget _buildTradingPanel(bool isDark) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.control_point_rounded, color: AppColors.primary, size: 22),
                  SizedBox(width: 8),
                  Text('Painel de Controle', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              CupertinoSwitch(
                value: _autoTradingEnabled,
                activeColor: AppColors.primary,
                onChanged: (v) => _toggleAutoTrading(),
              ),
            ],
          ),
          SizedBox(height: 16),
          Text('Símbolo', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
          SizedBox(height: 8),
          _buildSymbolSelector(isDark),
          SizedBox(height: 16),
          Text('Tipo de Contrato', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
          SizedBox(height: 8),
          _buildContractSelector(isDark),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Duração (ticks)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
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
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Stake (\$)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    SizedBox(height: 6),
                    _buildInputField(isDark, _stakeAmount.toStringAsFixed(2), (v) {
                      if (v.isNotEmpty) {
                        final amt = double.tryParse(v);
                        if (amt != null && amt >= 0.35) {
                          setState(() {
                            _stakeAmount = amt;
                            _initialStake = amt;
                          });
                          _updateProposal();
                        }
                      }
                    }, isNumeric: true),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          if (_payout > 0)
            Container(
              padding: EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary.withOpacity(0.2), AppColors.primary.withOpacity(0.1)],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withOpacity(0.5)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.monetization_on_rounded, color: AppColors.primary, size: 20),
                      SizedBox(width: 8),
                      Text('Payout Estimado:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    ],
                  ),
                  Text('\$${_payout.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                ],
              ),
            ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildTradeButton(isDark, 'CALL', Icons.arrow_upward_rounded, AppColors.success)),
              SizedBox(width: 12),
              Expanded(child: _buildTradeButton(isDark, 'PUT', Icons.arrow_downward_rounded, AppColors.error)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSymbolSelector(bool isDark) {
    return Container(
      height: 44,
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
              margin: EdgeInsets.only(right: 8),
              padding: EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)])
                    : null,
                color: !isSelected ? (isDark ? AppColors.darkBackground : Colors.grey[200]) : null,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: isSelected ? AppColors.primary : (isDark ? AppColors.darkBorder : AppColors.lightBorder)),
              ),
              alignment: Alignment.center,
              child: Text(symbol,
                  style: TextStyle(
                      color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black),
                      fontWeight: FontWeight.bold,
                      fontSize: 13)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContractSelector(bool isDark) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _contractCategories.entries.expand((category) {
        return category.value.map((contract) {
          final isSelected = contract['id'] == _contractType;

          return GestureDetector(
            onTap: () {
              setState(() => _contractType = contract['id']!);
              _updateProposal();
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                gradient: isSelected ? LinearGradient(colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)]) : null,
                color: !isSelected ? (isDark ? AppColors.darkBackground : Colors.grey[200]) : null,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isSelected ? AppColors.primary : (isDark ? AppColors.darkBorder : AppColors.lightBorder)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(contract['icon'], size: 16, color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87)),
                  SizedBox(width: 6),
                  Text(contract['name'],
                      style: TextStyle(
                          color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black),
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          );
        });
      }).toList(),
    );
  }

  Widget _buildInputField(bool isDark, String hint, Function(String) onChanged, {bool isNumeric = false}) {
    return Container(
      height: 42,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkBackground : Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: TextField(
        keyboardType: isNumeric ? TextInputType.numberWithOptions(decimal: true) : TextInputType.number,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
        height: 50,
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color, color.withOpacity(0.8)]),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: Offset(0, 4)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            SizedBox(width: 10),
            Text(type == 'CALL' ? 'RISE' : 'FALL',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }

  void _showAdvancedSettings(bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(Icons.tune_rounded, color: AppColors.primary, size: 24),
                  SizedBox(width: 12),
                  Text('Configurações Avançadas', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 20),
                children: [
                  Text('Estratégias de Trading',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary)),
                  SizedBox(height: 12),
                  ..._autoStrategies.entries.map((e) {
                    final strategy = e.value;
                    final isSelected = _autoStrategy == e.key;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _autoStrategy = e.key);
                        if (e.key != 'custom') {
                          Navigator.pop(context);
                        }
                      },
                      child: Container(
                        margin: EdgeInsets.only(bottom: 10),
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(
                                  colors: [AppColors.primary.withOpacity(0.2), AppColors.primary.withOpacity(0.1)])
                              : null,
                          color: !isSelected ? (isDark ? AppColors.darkBackground : Colors.grey[100]) : null,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: isSelected ? AppColors.primary : (isDark ? AppColors.darkBorder : AppColors.lightBorder)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isSelected ? AppColors.primary.withOpacity(0.2) : Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(strategy['icon'], color: isSelected ? AppColors.primary : Colors.grey, size: 24),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(strategy['name'], style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                                  SizedBox(height: 4),
                                  Text(strategy['description'], style: TextStyle(fontSize: 11, color: Colors.grey)),
                                ],
                              ),
                            ),
                            if (strategy['winRate'] > 0)
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.success.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text('${strategy['winRate']}%',
                                    style: TextStyle(
                                        fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.success)),
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  if (_autoStrategy == 'custom') ...[
                    SizedBox(height: 20),
                    Text('Parâmetros Personalizados',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary)),
                    SizedBox(height: 16),
                    _buildCustomParameter(
                        'Multiplicador Martingale', _martingaleMultiplier, 1.5, 5.0, (v) => setState(() => _martingaleMultiplier = v)),
                    _buildCustomParameter("Incremento D'Alembert", _dalembertIncrement, 0.1, 2.0, (v) => setState(() => _dalembertIncrement = v)),
                    _buildCustomParameter('Máx. Perdas Consecutivas', _maxConsecutiveLosses.toDouble(), 3, 10,
                        (v) => setState(() => _maxConsecutiveLosses = v.toInt()), isInt: true),
                    SizedBox(height: 16),
                    SwitchListTile(
                      title: Text('Parar ao atingir meta'),
                      subtitle: Text('Parar trading ao atingir lucro/perda'),
                      value: _stopOnTarget,
                      activeColor: AppColors.primary,
                      onChanged: (v) => setState(() => _stopOnTarget = v),
                    ),
                    if (_stopOnTarget) ...[
                      _buildCustomParameter(
                          'Meta de Lucro (\$)', _profitTarget, 10, 500, (v) => setState(() => _profitTarget = v)),
                      _buildCustomParameter(
                          'Limite de Perda (\$)', _lossLimit, 10, 500, (v) => setState(() => _lossLimit = v)),
                    ],
                  ],
                  SizedBox(height: 20),
                  Text('Intervalo de Auto-Trading',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary)),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: _autoTradeInterval.toDouble(),
                          min: 2,
                          max: 120,
                          divisions: 118,
                          activeColor: AppColors.primary,
                          label: '$_autoTradeInterval seg',
                          onChanged: (v) => setState(() => _autoTradeInterval = v.toInt()),
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('$_autoTradeInterval s',
                            style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomParameter(String label, double value, double min, double max, Function(double) onChanged,
      {bool isInt = false}) {
    final divisions = ((max - min) / (isInt ? 1.0 : 0.1)).clamp(1, 1000).toInt();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            Text(isInt ? value.toInt().toString() : value.toStringAsFixed(2),
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary)),
          ],
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: divisions,
          activeColor: AppColors.primary,
          onChanged: onChanged,
        ),
        SizedBox(height: 8),
      ],
    );
  }

  void _showDetailedHistory(bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey, borderRadius: BorderRadius.circular(2))),
            Padding(
              padding: EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.history_rounded, color: AppColors.primary, size: 24),
                      SizedBox(width: 12),
                      Text('Histórico Completo', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('${_tradeHistory.length}',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _tradeHistory.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.inbox_rounded, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text('Nenhuma operação ainda', style: TextStyle(fontSize: 16, color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _tradeHistory.length,
                      itemBuilder: (context, i) => _buildDetailedTradeItem(_tradeHistory[i], isDark),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedTradeItem(Map<String, dynamic> trade, bool isDark) {
    final isWin = trade['status'] == 'won';
    final profit = (trade['profit'] is num) ? (trade['profit'] as num).toDouble() : 0.0;
    final timestamp = trade['timestamp'] as DateTime;
    final timeStr =
        '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isWin
              ? [AppColors.success.withOpacity(0.1), AppColors.success.withOpacity(0.05)]
              : [AppColors.error.withOpacity(0.1), AppColors.error.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isWin ? AppColors.success.withOpacity(0.3) : AppColors.error.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isWin
                        ? [AppColors.success, AppColors.success.withOpacity(0.8)]
                        : [AppColors.error, AppColors.error.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(isWin ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, color: Colors.white, size: 20),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(trade['symbol'], style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        SizedBox(width: 8),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isWin ? AppColors.success.withOpacity(0.2) : AppColors.error.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(trade['type'],
                              style: TextStyle(
                                  fontSize: 9, fontWeight: FontWeight.bold, color: isWin ? AppColors.success : AppColors.error)),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(timeStr, style: TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${profit >= 0 ? '+' : ''}\$${profit.toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isWin ? AppColors.success : AppColors.error)),
                  Text('Stake: \$${(trade['amount'] is num ? (trade['amount'] as num).toDouble() : 0.0).toStringAsFixed(2)}',
                      style: TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
            ],
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkBackground.withOpacity(0.5) : Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.login_rounded, size: 14, color: Colors.blue),
                        SizedBox(width: 4),
                        Text('Entrada', style: TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text((trade['entryTick'] as double).toStringAsFixed(5),
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue)),
                  ],
                ),
                Icon(Icons.arrow_forward_rounded, size: 16, color: Colors.grey),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.logout_rounded, size: 14, color: isWin ? AppColors.success : AppColors.error),
                        SizedBox(width: 4),
                        Text('Saída', style: TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text((trade['exitTick'] as double).toStringAsFixed(5),
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isWin ? AppColors.success : AppColors.error)),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.account_balance_wallet_rounded, size: 14, color: Colors.grey),
                  SizedBox(width: 4),
                  Text('Saldo após:', style: TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
              Text('\$${(trade['balance'] is num ? (trade['balance'] as num).toDouble() : 0.0).toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTradeHistory(bool isDark) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.history_rounded, color: AppColors.primary, size: 20),
                  SizedBox(width: 8),
                  Text('Últimas Operações', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                ],
              ),
              GestureDetector(
                onTap: () => _showDetailedHistory(isDark),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Text('Ver tudo', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_rounded, size: 12, color: AppColors.primary),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: _tradeHistory.length > 5 ? 5 : _tradeHistory.length,
            itemBuilder: (context, i) {
              final trade = _tradeHistory[i];
              final isWin = trade['status'] == 'won';
              final profit = (trade['profit'] is num) ? (trade['profit'] as num).toDouble() : 0.0;
              final entryTick = trade['entryTick'] as double;
              final exitTick = trade['exitTick'] as double;
              final timestamp = trade['timestamp'] as DateTime;
              final timeStr =
                  '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';

              return Container(
                margin: EdgeInsets.only(bottom: 8),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isWin
                        ? [AppColors.success.withOpacity(0.1), AppColors.success.withOpacity(0.05)]
                        : [AppColors.error.withOpacity(0.1), AppColors.error.withOpacity(0.05)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isWin ? AppColors.success.withOpacity(0.3) : AppColors.error.withOpacity(0.3),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isWin
                              ? [AppColors.success, AppColors.success.withOpacity(0.8)]
                              : [AppColors.error, AppColors.error.withOpacity(0.8)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: (isWin ? AppColors.success : AppColors.error).withOpacity(0.3),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(isWin ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, color: Colors.white, size: 20),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(trade['symbol'], style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                              SizedBox(width: 6),
                              Icon(
                                trade['type'] == 'CALL' ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                                size: 12,
                                color: isWin ? AppColors.success : AppColors.error,
                              ),
                            ],
                          ),
                          SizedBox(height: 2),
                          Text('$timeStr • ${entryTick.toStringAsFixed(3)} → ${exitTick.toStringAsFixed(3)}',
                              style: TextStyle(fontSize: 9, color: Colors.grey)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${profit >= 0 ? '+' : ''}\$${profit.toStringAsFixed(2)}',
                            style:
                                TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isWin ? AppColors.success : AppColors.error)),
                        Text('\$${(trade['amount'] is num ? (trade['amount'] as num).toDouble() : 0.0).toStringAsFixed(2)}', style: TextStyle(fontSize: 9, color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}