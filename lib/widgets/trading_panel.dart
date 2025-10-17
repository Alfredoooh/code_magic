// lib/widgets/trading_panel.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../services/deriv_service.dart';

class TradingPanel extends StatefulWidget {
  final DerivService derivService;

  const TradingPanel({Key? key, required this.derivService}) : super(key: key);

  @override
  _TradingPanelState createState() => _TradingPanelState();
}

class _TradingPanelState extends State<TradingPanel> {
  String? _selectedSymbol;
  String _selectedMarket = 'forex';
  String _contractType = 'CALL';
  double _amount = 10.0;
  String _duration = '5';
  String _durationType = 't';
  double? _currentPrice;
  double? _payout;
  String? _proposalId;
  bool _isLoadingProposal = false;
  List<Map<String, dynamic>> _openContracts = [];

  final Map<String, String> _marketNames = {
    'forex': 'Forex',
    'synthetic_index': 'Synthetic Indices',
    'commodities': 'Commodities',
    'stock_index': 'Stock Indices',
    'stocks': 'Stocks',
    'cryptocurrency': 'Cryptocurrencies',
  };

  final Map<String, List<String>> _marketSymbols = {
    'forex': ['frxEURUSD', 'frxGBPUSD', 'frxUSDJPY', 'frxAUDUSD', 'frxUSDCAD'],
    'synthetic_index': ['R_10', 'R_25', 'R_50', 'R_75', 'R_100', '1HZ10V', '1HZ25V', '1HZ50V', '1HZ75V', '1HZ100V', 'BOOM500', 'BOOM1000', 'CRASH500', 'CRASH1000'],
    'commodities': ['frxXAUUSD', 'frxXAGUSD', 'frxBROUSD'],
    'stock_index': ['OTC_AS51', 'OTC_DJI', 'OTC_FCHI', 'OTC_FTSE', 'OTC_GDAXI', 'OTC_HSI', 'OTC_N225', 'OTC_NDX', 'OTC_SPC'],
    'cryptocurrency': ['cryBTCUSD', 'cryETHUSD', 'cryLTCUSD', 'cryBCHUSD'],
  };

  @override
  void initState() {
    super.initState();
    _loadSymbols();
    _setupListeners();
  }

  void _loadSymbols() {
    if (widget.derivService.activeSymbols.isNotEmpty) {
      final symbols = widget.derivService.activeSymbols;
      if (symbols.isNotEmpty) {
        setState(() {
          _selectedSymbol = _getDefaultSymbol();
        });
        _subscribeTicks();
      }
    } else {
      widget.derivService.getActiveSymbols();
      Future.delayed(Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _selectedSymbol = _getDefaultSymbol();
          });
          _subscribeTicks();
        }
      });
    }
  }

  String _getDefaultSymbol() {
    final marketSymbols = _marketSymbols[_selectedMarket] ?? [];
    return marketSymbols.isNotEmpty ? marketSymbols[0] : 'R_10';
  }

  void _setupListeners() {
    widget.derivService.tickStream.listen((tick) {
      if (mounted && tick['symbol'] == _selectedSymbol) {
        setState(() {
          _currentPrice = tick['quote']?.toDouble();
        });
      }
    });

    widget.derivService.proposalStream.listen((proposal) {
      if (mounted) {
        setState(() {
          _payout = proposal['payout']?.toDouble();
          _proposalId = proposal['id'];
          _isLoadingProposal = false;
        });
      }
    });

    widget.derivService.contractStream.listen((contract) {
      if (mounted) {
        _showContractDialog(contract);
        _getProposal();
      }
    });
  }

  void _subscribeTicks() {
    if (_selectedSymbol != null) {
      widget.derivService.subscribeTicks(_selectedSymbol!);
    }
  }

  void _getProposal() {
    if (_selectedSymbol == null) return;

    setState(() {
      _isLoadingProposal = true;
      _proposalId = null;
      _payout = null;
    });

    widget.derivService.getProposal(
      contractType: _contractType,
      symbol: _selectedSymbol!,
      currency: 'USD',
      amount: _amount,
      duration: _duration,
      durationType: _durationType,
    );
  }

  void _buyContract() {
    if (_proposalId != null && _payout != null) {
      widget.derivService.buyContract(_proposalId!, _payout!);
    }
  }

  void _showContractDialog(Map<String, dynamic> contract) {
    final brightness = MediaQuery.of(context).platformBrightness;
    final isDark = brightness == Brightness.dark;

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Contrato Comprado'),
        content: Padding(
          padding: EdgeInsets.only(top: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('ID: ${contract['contract_id'] ?? 'N/A'}'),
              SizedBox(height: 8),
              Text('Preço: \$${contract['buy_price']?.toStringAsFixed(2) ?? '0.00'}'),
              SizedBox(height: 8),
              Text('Payout: \$${contract['payout']?.toStringAsFixed(2) ?? '0.00'}'),
            ],
          ),
        ),
        actions: [
          CupertinoDialogAction(
            child: Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.of(context).platformBrightness;
    final isDark = brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(isDark, 'Mercados'),
        SizedBox(height: 16),
        _buildMarketSelector(isDark),
        SizedBox(height: 24),
        _buildSectionTitle(isDark, 'Símbolo'),
        SizedBox(height: 16),
        _buildSymbolSelector(isDark),
        SizedBox(height: 24),
        if (_currentPrice != null) _buildPriceCard(isDark),
        if (_currentPrice != null) SizedBox(height: 24),
        _buildSectionTitle(isDark, 'Tipo de Contrato'),
        SizedBox(height: 16),
        _buildContractTypeSelector(isDark),
        SizedBox(height: 24),
        _buildSectionTitle(isDark, 'Valor da Aposta'),
        SizedBox(height: 16),
        _buildAmountInput(isDark),
        SizedBox(height: 24),
        _buildSectionTitle(isDark, 'Duração'),
        SizedBox(height: 16),
        _buildDurationInput(isDark),
        SizedBox(height: 24),
        _buildProposalCard(isDark),
        SizedBox(height: 24),
        _buildTradeButton(isDark),
        SizedBox(height: 40),
      ],
    );
  }

  Widget _buildSectionTitle(bool isDark, String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: Color(0xFFFF444F),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: isDark ? CupertinoColors.white : CupertinoColors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildMarketSelector(bool isDark) {
    return Container(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: BouncingScrollPhysics(),
        itemCount: _marketNames.length,
        itemBuilder: (context, index) {
          final marketKey = _marketNames.keys.elementAt(index);
          final marketName = _marketNames[marketKey]!;
          final isSelected = _selectedMarket == marketKey;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedMarket = marketKey;
                _selectedSymbol = _getDefaultSymbol();
              });
              _subscribeTicks();
              _getProposal();
            },
            child: Container(
              width: 140,
              margin: EdgeInsets.only(right: 12),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [Color(0xFFFF444F), Color(0xFFFF6B6B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isSelected ? null : (isDark ? Color(0xFF1C1C1E) : CupertinoColors.white),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? Colors.transparent
                      : (isDark ? Color(0xFF2C2C2E) : CupertinoColors.systemGrey6),
                  width: 1.5,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Color(0xFFFF444F).withOpacity(0.3),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getMarketIcon(marketKey),
                    color: isSelected
                        ? CupertinoColors.white
                        : Color(0xFFFF444F),
                    size: 32,
                  ),
                  SizedBox(height: 12),
                  Text(
                    marketName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? CupertinoColors.white
                          : (isDark ? CupertinoColors.white : CupertinoColors.black),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  IconData _getMarketIcon(String market) {
    switch (market) {
      case 'forex':
        return CupertinoIcons.money_dollar_circle_fill;
      case 'synthetic_index':
        return CupertinoIcons.chart_bar_alt_fill;
      case 'commodities':
        return CupertinoIcons.cube_fill;
      case 'stock_index':
        return CupertinoIcons.graph_square_fill;
      case 'stocks':
        return CupertinoIcons.building_2_fill;
      case 'cryptocurrency':
        return CupertinoIcons.bitcoin_circle_fill;
      default:
        return CupertinoIcons.chart_bar_fill;
    }
  }

  Widget _buildSymbolSelector(bool isDark) {
    final symbols = _marketSymbols[_selectedMarket] ?? [];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1C1C1E) : CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Color(0xFF2C2C2E) : CupertinoColors.systemGrey6,
          width: 1.5,
        ),
      ),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed: () {
          showCupertinoModalPopup(
            context: context,
            builder: (context) => Container(
              height: 250,
              child: CupertinoPicker(
                backgroundColor: isDark ? Color(0xFF1C1C1E) : CupertinoColors.white,
                itemExtent: 40,
                onSelectedItemChanged: (index) {
                  setState(() {
                    _selectedSymbol = symbols[index];
                  });
                  _subscribeTicks();
                  _getProposal();
                },
                children: symbols
                    .map((symbol) => Center(
                          child: Text(
                            symbol,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: isDark ? CupertinoColors.white : CupertinoColors.black,
                            ),
                          ),
                        ))
                    .toList(),
              ),
            ),
          );
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _selectedSymbol ?? 'Selecione',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: isDark ? CupertinoColors.white : CupertinoColors.black,
              ),
            ),
            Icon(
              CupertinoIcons.chevron_down,
              color: CupertinoColors.systemGrey,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceCard(bool isDark) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1C1C1E) : CupertinoColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Color(0xFF2C2C2E) : CupertinoColors.systemGrey6,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Preço Atual',
                style: TextStyle(
                  fontSize: 14,
                  color: CupertinoColors.systemGrey,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8),
              Text(
                _currentPrice?.toStringAsFixed(5) ?? '0.00000',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: isDark ? CupertinoColors.white : CupertinoColors.black,
                ),
              ),
            ],
          ),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Color(0xFFFF444F).withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              CupertinoIcons.arrow_up_arrow_down,
              color: Color(0xFFFF444F),
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContractTypeSelector(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _buildContractTypeButton(isDark, 'CALL', 'Rise', CupertinoIcons.arrow_up_circle_fill, CupertinoColors.systemGreen),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _buildContractTypeButton(isDark, 'PUT', 'Fall', CupertinoIcons.arrow_down_circle_fill, Color(0xFFFF444F)),
        ),
      ],
    );
  }

  Widget _buildContractTypeButton(bool isDark, String type, String label, IconData icon, Color color) {
    final isSelected = _contractType == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          _contractType = type;
        });
        _getProposal();
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [color, color.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isSelected ? null : (isDark ? Color(0xFF1C1C1E) : CupertinoColors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.transparent : color.withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? CupertinoColors.white : color,
              size: 36,
            ),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isSelected ? CupertinoColors.white : color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountInput(bool isDark) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1C1C1E) : CupertinoColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Color(0xFF2C2C2E) : CupertinoColors.systemGrey6,
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'USD',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: CupertinoColors.systemGrey,
                ),
              ),
              Text(
                '\$${_amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: isDark ? CupertinoColors.white : CupertinoColors.black,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              _buildQuickAmountButton(isDark, 5),
              SizedBox(width: 8),
              _buildQuickAmountButton(isDark, 10),
              SizedBox(width: 8),
              _buildQuickAmountButton(isDark, 25),
              SizedBox(width: 8),
              _buildQuickAmountButton(isDark, 50),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAmountButton(bool isDark, double amount) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _amount = amount;
          });
          _getProposal();
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: _amount == amount
                ? Color(0xFFFF444F).withOpacity(0.15)
                : (isDark ? Color(0xFF2C2C2E) : Color(0xFFF2F2F7)),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _amount == amount ? Color(0xFFFF444F) : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Text(
            '\$$amount',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: _amount == amount
                  ? Color(0xFFFF444F)
                  : CupertinoColors.systemGrey,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDurationInput(bool isDark) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1C1C1E) : CupertinoColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Color(0xFF2C2C2E) : CupertinoColors.systemGrey6,
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 2,
                child: CupertinoTextField(
                  controller: TextEditingController(text: _duration),
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isDark ? CupertinoColors.white : CupertinoColors.black,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? Color(0xFF2C2C2E) : Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onChanged: (value) {
                    _duration = value;
                    _getProposal();
                  },
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: isDark ? Color(0xFF2C2C2E) : Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      showCupertinoModalPopup(
                        context: context,
                        builder: (context) => Container(
                          height: 200,
                          child: CupertinoPicker(
                            backgroundColor: isDark ? Color(0xFF1C1C1E) : CupertinoColors.white,
                            itemExtent: 40,
                            onSelectedItemChanged: (index) {
                              final types = ['t', 'm', 'h', 'd'];
                              setState(() {
                                _durationType = types[index];
                              });
                              _getProposal();
                            },
                            children: [
                              Center(child: Text('Ticks', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600))),
                              Center(child: Text('Minutos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600))),
                              Center(child: Text('Horas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600))),
                              Center(child: Text('Dias', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600))),
                            ],
                          ),
                        ),
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _getDurationTypeLabel(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark ? CupertinoColors.white : CupertinoColors.black,
                          ),
                        ),
                        Icon(
                          CupertinoIcons.chevron_down,
                          color: CupertinoColors.systemGrey,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getDurationTypeLabel() {
    switch (_durationType) {
      case 't':
        return 'Ticks';
      case 'm':
        return 'Minutos';
      case 'h':
        return 'Horas';
      case 'd':
        return 'Dias';
      default:
        return 'Ticks';
    }
  }

  Widget _buildProposalCard(bool isDark) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFFF444F).withOpacity(0.15),
            Color(0xFFFF6B6B).withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Color(0xFFFF444F).withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Payout Potencial',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark ? CupertinoColors.white : CupertinoColors.black,
                ),
              ),
              if (_isLoadingProposal)
                CupertinoActivityIndicator()
              else
                Text(
                  '\$${_payout?.toStringAsFixed(2) ?? '0.00'}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFFFF444F),
                  ),
                ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Lucro',
                style: TextStyle(
                  fontSize: 14,
                  color: CupertinoColors.systemGrey,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '\$${((_payout ?? 0) - _amount).toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: CupertinoColors.systemGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTradeButton(bool isDark) {
    final canTrade = _proposalId != null && !_isLoadingProposal;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: canTrade ? _buyContract : null,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: canTrade
              ? LinearGradient(
                  colors: [Color(0xFFFF444F), Color(0xFFFF6B6B)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: canTrade ? null : CupertinoColors.systemGrey,
          borderRadius: BorderRadius.circular(16),
          boxShadow: canTrade
              ? [
                  BoxShadow(
                    color: Color(0xFFFF444F).withOpacity(0.4),
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              CupertinoIcons.checkmark_circle_fill,
              color: CupertinoColors.white,
              size: 24,
            ),
            SizedBox(width: 12),
            Text(
              _contractType == 'CALL' ? 'Comprar Rise' : 'Comprar Fall',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: CupertinoColors.white,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}