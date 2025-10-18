// lib/widgets/trading_panel.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../services/deriv_service.dart';
import 'app_ui_components.dart';

class TradingPanel extends StatefulWidget {
  final DerivService derivService;
  final Function(String)? onSymbolChanged;

  const TradingPanel({
    Key? key,
    required this.derivService,
    this.onSymbolChanged,
  }) : super(key: key);

  @override
  _TradingPanelState createState() => _TradingPanelState();
}

class _TradingPanelState extends State<TradingPanel> {
  String? _selectedSymbol;
  String _selectedMarket = 'forex';
  String _contractType = 'CALL';
  double _amount = 0.35; // Valor mínimo
  String _duration = '5';
  String _durationType = 't';
  double? _currentPrice;
  double? _payout;
  String? _proposalId;
  bool _isLoadingProposal = false;

  final Map<String, String> _marketNames = {
    'forex': 'Forex',
    'synthetic_index': 'Synthetic Indices',
    'commodities': 'Commodities',
    'stock_index': 'Stock Indices',
    'cryptocurrency': 'Cryptocurrencies',
  };

  final Map<String, List<String>> _marketSymbols = {
    'forex': ['frxEURUSD', 'frxGBPUSD', 'frxUSDJPY', 'frxAUDUSD', 'frxUSDCAD'],
    'synthetic_index': ['R_10', 'R_25', 'R_50', 'R_75', 'R_100'],
    'commodities': ['frxXAUUSD', 'frxXAGUSD', 'frxBROUSD'],
    'stock_index': ['OTC_AS51', 'OTC_DJI', 'OTC_FTSE'],
    'cryptocurrency': ['cryBTCUSD', 'cryETHUSD', 'cryLTCUSD'],
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
        widget.onSymbolChanged?.call(_selectedSymbol!);
      }
    } else {
      widget.derivService.getActiveSymbols();
      Future.delayed(Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _selectedSymbol = _getDefaultSymbol();
          });
          _subscribeTicks();
          widget.onSymbolChanged?.call(_selectedSymbol!);
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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

  void _showTradingOptions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    AppBottomSheet.show(
      context,
      height: MediaQuery.of(context).size.height * 0.75,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSectionTitle(
              text: 'Opções de Trading',
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
            SizedBox(height: 24),
            _buildMarketSelector(isDark),
            SizedBox(height: 24),
            AppFieldLabel(text: 'Símbolo'),
            SizedBox(height: 8),
            _buildSymbolSelector(isDark),
            SizedBox(height: 24),
            AppFieldLabel(text: 'Valor da Aposta (Mínimo: \$0.35)'),
            SizedBox(height: 8),
            _buildAmountInput(isDark),
            SizedBox(height: 24),
            AppFieldLabel(text: 'Duração'),
            SizedBox(height: 8),
            _buildDurationInput(isDark),
            SizedBox(height: 24),
            AppPrimaryButton(
              text: 'Aplicar',
              onPressed: () {
                Navigator.pop(context);
                _getProposal();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_currentPrice != null) _buildPriceCard(isDark),
        if (_currentPrice != null) SizedBox(height: 16),
        _buildProposalCard(isDark),
        SizedBox(height: 24),
        _buildTradeButtons(isDark),
        SizedBox(height: 16),
        _buildOptionsButton(isDark),
      ],
    );
  }

  Widget _buildPriceCard(bool isDark) {
    return AppCard(
      padding: EdgeInsets.all(20),
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
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8),
              Text(
                _currentPrice?.toStringAsFixed(5) ?? '0.00000',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.show_chart,
              color: AppColors.primary,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProposalCard(bool isDark) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.15),
            Color(0xFFFF6B6B).withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.3),
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
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              if (_isLoadingProposal)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                )
              else
                Text(
                  '\$${_payout?.toStringAsFixed(2) ?? '0.00'}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
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
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '\$${((_payout ?? 0) - _amount).toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTradeButtons(bool isDark) {
    final canTrade = _proposalId != null && !_isLoadingProposal;

    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              if (canTrade) {
                setState(() => _contractType = 'CALL');
                _buyContract();
              }
            },
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                gradient: canTrade
                    ? LinearGradient(
                        colors: [Colors.green, Colors.green.shade600],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: canTrade ? null : Colors.grey,
                borderRadius: BorderRadius.circular(16),
                boxShadow: canTrade
                    ? [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.3),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.arrow_upward_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'COMPRAR',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: GestureDetector(
            onTap: () {
              if (canTrade) {
                setState(() => _contractType = 'PUT');
                _buyContract();
              }
            },
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                gradient: canTrade
                    ? LinearGradient(
                        colors: [AppColors.primary, Color(0xFFFF6B6B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: canTrade ? null : Colors.grey,
                borderRadius: BorderRadius.circular(16),
                boxShadow: canTrade
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.arrow_downward_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'VENDER',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionsButton(bool isDark) {
    return AppSecondaryButton(
      text: 'Configurar Opções',
      onPressed: _showTradingOptions,
    );
  }

  Widget _buildMarketSelector(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppFieldLabel(text: 'Mercado'),
        SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _marketNames.entries.map((entry) {
            final isSelected = _selectedMarket == entry.key;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedMarket = entry.key;
                  _selectedSymbol = _getDefaultSymbol();
                });
                _subscribeTicks();
                widget.onSymbolChanged?.call(_selectedSymbol!);
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : (isDark ? AppColors.darkCard : AppColors.lightCard),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                ),
                child: Text(
                  entry.value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.white : Colors.black),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSymbolSelector(bool isDark) {
    final symbols = _marketSymbols[_selectedMarket] ?? [];

    return AppTextField(
      hintText: _selectedSymbol ?? 'Selecione',
      suffixIcon: Icon(Icons.arrow_drop_down),
      onTap: () {
        showCupertinoModalPopup(
          context: context,
          builder: (context) => Container(
            height: 250,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : AppColors.lightCard,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: CupertinoPicker(
              backgroundColor: Colors.transparent,
              itemExtent: 40,
              onSelectedItemChanged: (index) {
                setState(() {
                  _selectedSymbol = symbols[index];
                });
                _subscribeTicks();
                widget.onSymbolChanged?.call(_selectedSymbol!);
              },
              children: symbols
                  .map((symbol) => Center(
                        child: Text(
                          symbol,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAmountInput(bool isDark) {
    return Column(
      children: [
        AppTextField(
          hintText: '\$${_amount.toStringAsFixed(2)}',
          keyboardType: TextInputType.number,
          onChanged: (value) {
            final parsed = double.tryParse(value);
            if (parsed != null && parsed >= 0.35) {
              setState(() => _amount = parsed);
            }
          },
        ),
        SizedBox(height: 12),
        Row(
          children: [
            _buildQuickAmountButton(isDark, 0.35),
            SizedBox(width: 8),
            _buildQuickAmountButton(isDark, 1.0),
            SizedBox(width: 8),
            _buildQuickAmountButton(isDark, 5.0),
            SizedBox(width: 8),
            _buildQuickAmountButton(isDark, 10.0),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickAmountButton(bool isDark, double amount) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _amount = amount);
          _getProposal();
        },
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: _amount == amount
                ? AppColors.primary.withOpacity(0.15)
                : (isDark ? AppColors.darkCard : Color(0xFFF2F2F7)),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _amount == amount ? AppColors.primary : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Text(
            '\$${amount.toStringAsFixed(2)}',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _amount == amount ? AppColors.primary : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDurationInput(bool isDark) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: AppTextField(
            hintText: _duration,
            keyboardType: TextInputType.number,
            onChanged: (value) {
              setState(() => _duration = value);
              _getProposal();
            },
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: AppTextField(
            hintText: _getDurationTypeLabel(),
            suffixIcon: Icon(Icons.arrow_drop_down),
            onTap: () {
              showCupertinoModalPopup(
                context: context,
                builder: (context) => Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: CupertinoPicker(
                    backgroundColor: Colors.transparent,
                    itemExtent: 40,
                    onSelectedItemChanged: (index) {
                      final types = ['t', 'm', 'h', 'd'];
                      setState(() => _durationType = types[index]);
                      _getProposal();
                    },
                    children: [
                      Center(child: Text('Ticks', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black))),
                      Center(child: Text('Minutos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black))),
                      Center(child: Text('Horas', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black))),
                      Center(child: Text('Dias', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black))),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
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
}