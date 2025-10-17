// lib/screens/trading_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:async';
import '../services/deriv_service.dart';

class TradingScreen extends StatefulWidget {
  final DerivService derivService;

  TradingScreen({required this.derivService});

  @override
  _TradingScreenState createState() => _TradingScreenState();
}

class _TradingScreenState extends State<TradingScreen> {
  StreamSubscription? _tickSub;
  String _selectedSymbol = 'R_10';
  double _currentPrice = 0.0;
  List<double> _priceHistory = [];
  String _contractType = 'CALL';
  double _stake = 10.0;
  int _duration = 5;

  final Map<String, String> _symbols = {
    'R_10': 'Volatility 10 Index',
    'R_25': 'Volatility 25 Index',
    'R_50': 'Volatility 50 Index',
    'R_75': 'Volatility 75 Index',
    'R_100': 'Volatility 100 Index',
  };

  @override
  void initState() {
    super.initState();
    _subscribeToPrices();
  }

  void _subscribeToPrices() {
    widget.derivService.subscribeTicks(_selectedSymbol);
    
    _tickSub = widget.derivService.tickStream.listen((tickData) {
      if (mounted && tickData['symbol'] == _selectedSymbol) {
        final quote = tickData['quote'];
        if (quote != null) {
          setState(() {
            _currentPrice = _parsePrice(quote);
            _priceHistory.add(_currentPrice);
            if (_priceHistory.length > 50) {
              _priceHistory.removeAt(0);
            }
          });
        }
      }
    });
  }

  double _parsePrice(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  void _changeSymbol(String symbol) {
    widget.derivService.unsubscribeTicks(_selectedSymbol);
    setState(() {
      _selectedSymbol = symbol;
      _priceHistory.clear();
      _currentPrice = 0.0;
    });
    widget.derivService.subscribeTicks(_selectedSymbol);
  }

  void _showSymbolPicker(bool isDark) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 250,
        color: isDark ? Color(0xFF1C1C1E) : Colors.white,
        child: Column(
          children: [
            Container(
              height: 50,
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: Text('Cancelar'),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    'Selecionar Símbolo',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(width: 80),
                ],
              ),
            ),
            Expanded(
              child: CupertinoPicker(
                itemExtent: 40,
                onSelectedItemChanged: (index) {
                  _changeSymbol(_symbols.keys.elementAt(index));
                },
                children: _symbols.entries.map((entry) {
                  return Center(child: Text(entry.value));
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _executeTrade() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Confirmar Trade'),
        content: Text(
          'Tipo: $_contractType\nValor: \$${_stake.toStringAsFixed(2)}\nDuração: $_duration ticks',
        ),
        actions: [
          CupertinoDialogAction(
            child: Text('Cancelar'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: Text('Confirmar'),
            onPressed: () {
              Navigator.pop(context);
              widget.derivService.buyContract(
                contractType: _contractType,
                symbol: _selectedSymbol,
                stake: _stake,
                duration: _duration,
                durationType: 't',
              );
              _showSuccessDialog();
            },
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('✅ Trade Executado'),
        content: Text('Sua ordem foi enviada com sucesso!'),
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
  void dispose() {
    _tickSub?.cancel();
    widget.derivService.unsubscribeTicks(_selectedSymbol);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return CupertinoPageScaffold(
      backgroundColor: isDark ? Color(0xFF000000) : Color(0xFFF2F2F7),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: isDark ? Color(0xFF1C1C1E) : CupertinoColors.white,
        middle: Text('Trading em Tempo Real'),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(CupertinoIcons.back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(20),
          children: [
            // Seletor de símbolo
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Color(0xFF1C1C1E) : Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Símbolo',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                  SizedBox(height: 8),
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => _showSymbolPicker(isDark),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _symbols[_selectedSymbol] ?? _selectedSymbol,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        Icon(CupertinoIcons.chevron_down, size: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),

            // Preço atual
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFF444F), Color(0xFFFF6B6B)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    'Preço Atual',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    _currentPrice > 0 ? _currentPrice.toStringAsFixed(4) : '--',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),

            // Mini gráfico
            if (_priceHistory.length > 1)
              Container(
                height: 120,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Color(0xFF1C1C1E) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: CustomPaint(
                  painter: MiniChartPainter(_priceHistory, Color(0xFFFF444F)),
                  child: Container(),
                ),
              ),

            SizedBox(height: 24),

            // Tipo de contrato
            Text(
              'Tipo de Contrato',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildContractButton(isDark, 'CALL', CupertinoColors.systemGreen),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildContractButton(isDark, 'PUT', Color(0xFFFF444F)),
                ),
              ],
            ),

            SizedBox(height: 24),

            // Valor da aposta
            _buildInputField(
              isDark,
              'Valor da Aposta (\$)',
              _stake.toString(),
              (value) => setState(() => _stake = double.tryParse(value) ?? 10.0),
            ),

            SizedBox(height: 16),

            // Duração
            _buildInputField(
              isDark,
              'Duração (ticks)',
              _duration.toString(),
              (value) => setState(() => _duration = int.tryParse(value) ?? 5),
            ),

            SizedBox(height: 32),

            // Botão de executar
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _currentPrice > 0 ? _executeTrade : null,
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 18),
                decoration: BoxDecoration(
                  color: _currentPrice > 0 ? Color(0xFFFF444F) : CupertinoColors.systemGrey,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Executar Trade',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContractButton(bool isDark, String type, Color color) {
    final isSelected = _contractType == type;
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () => setState(() => _contractType = type),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(isSelected ? 1 : 0.3),
            width: 1.5,
          ),
        ),
        child: Text(
          type,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : color,
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(bool isDark, String label, String value, Function(String) onChanged) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.systemGrey,
            ),
          ),
          SizedBox(height: 8),
          CupertinoTextField(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Color(0xFF2C2C2E) : Color(0xFFF2F2F7),
              borderRadius: BorderRadius.circular(12),
            ),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
            ),
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            onChanged: onChanged,
            controller: TextEditingController(text: value)..selection = TextSelection.collapsed(offset: value.length),
          ),
        ],
      ),
    );
  }
}

// Painter para o mini gráfico de linha
class MiniChartPainter extends CustomPainter {
  final List<double> prices;
  final Color color;

  MiniChartPainter(this.prices, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    if (prices.length < 2) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final minPrice = prices.reduce((a, b) => a < b ? a : b);
    final maxPrice = prices.reduce((a, b) => a > b ? a : b);
    final priceRange = maxPrice - minPrice;

    if (priceRange == 0) return;

    final path = Path();
    final xStep = size.width / (prices.length - 1);

    for (int i = 0; i < prices.length; i++) {
      final x = i * xStep;
      final y = size.height - ((prices[i] - minPrice) / priceRange * size.height);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}