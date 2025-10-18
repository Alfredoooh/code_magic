// lib/screens/trading_chart_screen.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../widgets/app_ui_components.dart';
import '../services/deriv_service.dart';
import '../widgets/trading_panel.dart';
import '../widgets/trading_chart_widget.dart';

class TradingChartScreen extends StatefulWidget {
  final DerivService derivService;

  const TradingChartScreen({Key? key, required this.derivService}) : super(key: key);

  @override
  _TradingChartScreenState createState() => _TradingChartScreenState();
}

class _TradingChartScreenState extends State<TradingChartScreen> {
  String? _selectedSymbol = 'R_10';
  double _totalProfit = 0.0;
  double _totalLoss = 0.0;
  int _winCount = 0;
  int _lossCount = 0;
  bool _autoTradingEnabled = false;
  List<Map<String, dynamic>> _tradeHistory = [];

  @override
  void initState() {
    super.initState();
    _setupListeners();
  }

  void _setupListeners() {
    widget.derivService.contractStream.listen((contract) {
      if (mounted) {
        _handleContractResult(contract);
      }
    });
  }

  void _handleContractResult(Map<String, dynamic> contract) {
    final buyPrice = contract['buy_price']?.toDouble() ?? 0.0;
    final payout = contract['payout']?.toDouble() ?? 0.0;
    final profit = payout - buyPrice;

    setState(() {
      _tradeHistory.add({
        'timestamp': DateTime.now(),
        'symbol': _selectedSymbol,
        'type': contract['contract_type'] ?? 'CALL',
        'amount': buyPrice,
        'payout': payout,
        'profit': profit,
        'status': profit > 0 ? 'won' : 'lost',
      });

      if (profit > 0) {
        _totalProfit += profit;
        _winCount++;
      } else {
        _totalLoss += profit.abs();
        _lossCount++;
      }
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
      body: CustomScrollView(
        physics: BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 100,
            pinned: true,
            stretch: true,
            backgroundColor: Colors.transparent,
            leading: IconButton(
              icon: Icon(
                CupertinoIcons.back,
                color: isDark ? Colors.white : Colors.black,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: ClipRRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: (isDark ? AppColors.darkCard : AppColors.lightCard).withOpacity(0.8),
                    border: Border(
                      bottom: BorderSide(
                        color: (isDark ? AppColors.darkBorder : AppColors.lightBorder).withOpacity(0.2),
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: FlexibleSpaceBar(
                    titlePadding: EdgeInsets.only(left: 60, bottom: 16),
                    title: Text(
                      'Trading Chart',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildProfitLossCard(isDark),
                SizedBox(height: 16),
                _buildChartWidget(isDark),
                SizedBox(height: 16),
                _buildAutoTradingToggle(isDark),
                SizedBox(height: 24),
                TradingPanel(
                  derivService: widget.derivService,
                  onSymbolChanged: (symbol) {
                    setState(() => _selectedSymbol = symbol);
                  },
                ),
                SizedBox(height: 24),
                if (_tradeHistory.isNotEmpty) _buildTradeHistory(isDark),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfitLossCard(bool isDark) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildPLItem(
                isDark,
                'Lucro Total',
                '+\$${_totalProfit.toStringAsFixed(2)}',
                Colors.green,
              ),
              Container(
                width: 1,
                height: 40,
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              ),
              _buildPLItem(
                isDark,
                'Perda Total',
                '-\$${_totalLoss.toStringAsFixed(2)}',
                Colors.red,
              ),
            ],
          ),
          SizedBox(height: 16),
          Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'P&L Líquido',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${_netProfit >= 0 ? '+' : ''}\$${_netProfit.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: _netProfit >= 0 ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Taxa de Acerto',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${_winRate.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: _winRate >= 50 ? Colors.green : Colors.orange,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPLItem(bool isDark, String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // CORRIGIDO: Retorna o widget TradingChartWidget ao invés de chamar como método
  Widget _buildChartWidget(bool isDark) {
  return TradingChartWidget(
    symbol: _selectedSymbol ?? 'R_10',
    tradeHistory: _tradeHistory,
  );
}

  Widget _buildAutoTradingToggle(bool isDark) {
    return AppCard(
      padding: EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.auto_awesome,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trading Automático',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  _autoTradingEnabled ? 'Ativado' : 'Desativado',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          CupertinoSwitch(
            value: _autoTradingEnabled,
            activeColor: AppColors.primary,
            onChanged: (value) {
              setState(() => _autoTradingEnabled = value);
              if (value) {
                _showAutoTradingConfig(isDark);
              }
            },
          ),
        ],
      ),
    );
  }

  void _showAutoTradingConfig(bool isDark) {
    AppBottomSheet.show(
      context,
      height: MediaQuery.of(context).size.height * 0.6,
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSectionTitle(
              text: 'Configurar Trading Automático',
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
            SizedBox(height: 24),
            AppInfoCard(
              icon: Icons.info_outline,
              text: 'Configure os parâmetros para o trading automático. O sistema executará trades baseado nas suas configurações.',
            ),
            SizedBox(height: 24),
            AppFieldLabel(text: 'Valor por Trade'),
            SizedBox(height: 8),
            AppTextField(
              hintText: 'Mínimo: 0.35 USD',
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            AppFieldLabel(text: 'Estratégia'),
            SizedBox(height: 8),
            AppTextField(
              hintText: 'Martingale, Fixed, etc.',
            ),
            SizedBox(height: 24),
            AppPrimaryButton(
              text: 'Salvar Configuração',
              onPressed: () {
                Navigator.pop(context);
                AppDialogs.showSuccess(
                  context,
                  'Sucesso!',
                  'Trading automático configurado',
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTradeHistory(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionTitle(
          text: 'Histórico de Trades',
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        SizedBox(height: 16),
        ...(_tradeHistory.reversed.take(10).map((trade) {
          final isWin = trade['status'] == 'won';
          final profit = trade['profit'] as double;

          return Container(
            margin: EdgeInsets.only(bottom: 12),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isWin ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: (isWin ? Colors.green : Colors.red).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isWin ? Icons.trending_up : Icons.trending_down,
                    color: isWin ? Colors.green : Colors.red,
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${trade['symbol']} - ${trade['type']}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Stake: \$${(trade['amount'] as double).toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${profit >= 0 ? '+' : ''}\$${profit.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: isWin ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          );
        }).toList()),
      ],
    );
  }
}