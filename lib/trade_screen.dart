// trade_screen.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'trade_logic_controller.dart';
import 'trade_chart_view.dart';
import 'trade_controls.dart';
import 'custom_keyboard_screen.dart';
import 'market_selector_screen.dart';

class TradeScreen extends StatefulWidget {
  final String token;
  final String? initialMarket;

  const TradeScreen({
    Key? key,
    required this.token,
    this.initialMarket,
  }) : super(key: key);

  @override
  State<TradeScreen> createState() => _TradeScreenState();
}

class _TradeScreenState extends State<TradeScreen> with TickerProviderStateMixin {
  late TradeLogicController _controller;
  bool _chartExpanded = false;

  @override
  void initState() {
    super.initState();
    _controller = TradeLogicController(
      token: widget.token,
      initialMarket: widget.initialMarket,
      onStateChanged: () {
        if (mounted) setState(() {});
      },
    );
    _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: Colors.black,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: const Color(0xFF1A1A1A),
        border: const Border(bottom: BorderSide(color: Color(0xFF2A2A2A))),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Icon(CupertinoIcons.back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        middle: GestureDetector(
          onTap: () => _showMarketSelector(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _controller.selectedMarketName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(CupertinoIcons.chevron_down, size: 16, color: Colors.white),
            ],
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${_controller.balance.toStringAsFixed(2)} ${_controller.currency}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _controller.priceChange >= 0
                    ? const Color(0xFF00C896).withOpacity(0.2)
                    : const Color(0xFFFF4444).withOpacity(0.2),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                '${_controller.priceChange >= 0 ? '+' : ''}${_controller.priceChange.toStringAsFixed(2)}%',
                style: TextStyle(
                  color: _controller.priceChange >= 0 ? const Color(0xFF00C896) : const Color(0xFFFF4444),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            if (_controller.mlPrediction != null) _buildMLPredictionBar(),
            Expanded(
              flex: _chartExpanded ? 5 : 3,
              child: TradeChartView(
                controller: _controller,
                isExpanded: _chartExpanded,
                onExpandToggle: () {
                  setState(() => _chartExpanded = !_chartExpanded);
                },
              ),
            ),
            if (!_chartExpanded)
              TradeControls(
                controller: _controller,
                onStakeTap: () => _showStakeKeyboard(),
                onDurationTap: () => _showDurationSelector(),
                onPlaceTrade: (direction) => _controller.placeTrade(direction),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMLPredictionBar() {
    final prediction = _controller.mlPrediction!;
    final direction = prediction['direction'] as String? ?? 'N/A';
    final confidence = prediction['confidence'] as double? ?? 0.0;
    final stake = _controller.mlRecommendedStake;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0D47A1).withOpacity(0.3),
        border: Border(
          bottom: BorderSide(color: const Color(0xFF2196F3).withOpacity(0.3)),
        ),
      ),
      child: Row(
        children: [
          const Icon(CupertinoIcons.chart_bar_alt_fill, color: Color(0xFF2196F3), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'ML: ${direction.toUpperCase()} (${(confidence * 100).toStringAsFixed(0)}%) - Stake: \$${stake.toStringAsFixed(2)}',
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            minSize: 0,
            child: const Icon(CupertinoIcons.info_circle, color: Colors.white70, size: 18),
            onPressed: () => _showMLInfo(),
          ),
        ],
      ),
    );
  }

  void _showMarketSelector() {
    Navigator.of(context, rootNavigator: true).push(
      CupertinoPageRoute(
        fullscreenDialog: true,
        builder: (context) => MarketSelectorScreen(
          currentMarket: _controller.selectedMarket,
          allMarkets: _controller.allMarkets,
          onMarketSelected: (market) {
            _controller.changeMarket(market);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _showStakeKeyboard() {
    Navigator.of(context, rootNavigator: true).push(
      CupertinoPageRoute(
        fullscreenDialog: true,
        builder: (context) => CustomKeyboardScreen(
          title: 'Definir Stake',
          initialValue: _controller.stake,
          prefix: '\$ ',
          onConfirm: (value) {
            _controller.setStake(value);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _showDurationSelector() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Duração'),
        actions: [
          CupertinoActionSheetAction(
            child: const Text('Ticks'),
            onPressed: () {
              _controller.setDurationType('t');
              Navigator.pop(context);
              _showDurationValuePicker();
            },
          ),
          CupertinoActionSheetAction(
            child: const Text('Seconds'),
            onPressed: () {
              _controller.setDurationType('s');
              Navigator.pop(context);
              _showDurationValuePicker();
            },
          ),
          CupertinoActionSheetAction(
            child: const Text('Minutes'),
            onPressed: () {
              _controller.setDurationType('m');
              Navigator.pop(context);
              _showDurationValuePicker();
            },
          ),
          CupertinoActionSheetAction(
            child: const Text('Hours'),
            onPressed: () {
              _controller.setDurationType('h');
              Navigator.pop(context);
              _showDurationValuePicker();
            },
          ),
          CupertinoActionSheetAction(
            child: const Text('Days'),
            onPressed: () {
              _controller.setDurationType('d');
              Navigator.pop(context);
              _showDurationValuePicker();
            },
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          child: const Text('Cancelar'),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  void _showDurationValuePicker() {
    Navigator.of(context, rootNavigator: true).push(
      CupertinoPageRoute(
        fullscreenDialog: true,
        builder: (context) => CustomKeyboardScreen(
          title: 'Valor (${_controller.durationLabel})',
          initialValue: _controller.durationValue.toDouble(),
          isInteger: true,
          onConfirm: (value) {
            _controller.setDurationValue(value.toInt());
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  void _showMLInfo() {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.sparkles, color: Color(0xFF2196F3)),
            SizedBox(width: 8),
            Text('Machine Learning'),
          ],
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            const Text('O sistema de ML analisa:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('• Padrões do gráfico\n• Histórico de preços\n• Volatilidade\n• Tendências de mercado\n• Seu histórico de trades\n• Gestão de banca'),
            const SizedBox(height: 12),
            Text('Precisão atual: ${(_controller.mlAccuracy * 100).toStringAsFixed(1)}%', style: const TextStyle(color: Color(0xFF00C896), fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('Total de análises: ${_controller.mlTotalPredictions}', style: const TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}