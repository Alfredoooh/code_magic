// trade_screen.dart - MATERIAL DESIGN 3 EXPRESSIVE
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

// trade_controls.dart - MATERIAL DESIGN 3 EXPRESSIVE
// ========================================
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'trade_logic_controller.dart';

class TradeControls extends StatelessWidget {
  final TradeLogicController controller;
  final VoidCallback onStakeTap;
  final VoidCallback onDurationTap;
  final Function(String) onPlaceTrade;

  const TradeControls({
    Key? key,
    required this.controller,
    required this.onStakeTap,
    required this.onDurationTap,
    required this.onPlaceTrade,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        border: Border(top: BorderSide(color: Color(0xFF2A2A2A), width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildTradeTypeSelector(context),
            const SizedBox(height: 16),
            _buildStakeAndDurationRow(),
            if (controller.selectedTradeType == 'match_differ' ||
                controller.selectedTradeType == 'over_under') ...[
              const SizedBox(height: 12),
              _buildPredictionSelector(),
            ],
            const SizedBox(height: 16),
            _buildTradeButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildTradeTypeSelector(BuildContext context) {
    // Apenas os tipos de trade solicitados
    final tradeTypes = [
      {'id': 'rise_fall', 'label': 'Rise/Fall', 'icon': Icons.trending_up},
      {'id': 'higher_lower', 'label': 'Higher/Lower', 'icon': Icons.compare_arrows},
      {'id': 'even_odd', 'label': 'Even/Odd', 'icon': Icons.filter_1},
      {'id': 'match_differ', 'label': 'Match/Differ', 'icon': Icons.casino},
      {'id': 'over_under', 'label': 'Over/Under', 'icon': Icons.unfold_more},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...tradeTypes.map((type) {
            final isSelected = controller.selectedTradeType == type['id'];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => controller.changeTradeType(type['id'] as String),
                  borderRadius: BorderRadius.circular(12),
                  child: Ink(
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? const Color(0xFF0066FF)
                          : const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected 
                            ? const Color(0xFF0066FF)
                            : Colors.white.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            type['icon'] as IconData,
                            color: isSelected ? Colors.white : Colors.white60,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            type['label'] as String,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white60,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              fontSize: 13,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
          // Botão de som
          const SizedBox(width: 4),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => controller.toggleSound(),
              customBorder: const CircleBorder(),
              child: Ink(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: controller.soundEnabled 
                      ? const Color(0xFF00C896)
                      : const Color(0xFF2A2A2A),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: controller.soundEnabled
                        ? const Color(0xFF00C896)
                        : Colors.white.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Icon(
                  controller.soundEnabled 
                      ? Icons.volume_up_rounded 
                      : Icons.volume_off_rounded,
                  size: 20,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStakeAndDurationRow() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onStakeTap,
              borderRadius: BorderRadius.circular(16),
              child: Ink(
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.attach_money_rounded, color: Colors.white60, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          controller.stake.toStringAsFixed(2),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      const Icon(Icons.edit_rounded, color: Colors.white38, size: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onDurationTap,
              borderRadius: BorderRadius.circular(16),
              child: Ink(
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.schedule_rounded, color: Colors.white60, size: 20),
                      const SizedBox(width: 6),
                      Text(
                        '${controller.durationValue}${controller.durationLabel}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPredictionSelector() {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.psychology_rounded, color: Colors.white60, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Prediction',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_rounded, color: Colors.white),
                    iconSize: 28,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      if (controller.tickPrediction > 0) {
                        controller.setTickPrediction(controller.tickPrediction - 1);
                      }
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      controller.tickPrediction.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_rounded, color: Colors.white),
                    iconSize: 28,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      if (controller.tickPrediction < 9) {
                        controller.setTickPrediction(controller.tickPrediction + 1);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTradeButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildTradeButton(
            controller.getButtonLabel(true),
            const Color(0xFF00C896),
            'buy',
            Icons.arrow_upward_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildTradeButton(
            controller.getButtonLabel(false),
            const Color(0xFFFF4444),
            'sell',
            Icons.arrow_downward_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildTradeButton(String label, Color color, String direction, IconData icon) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: controller.isTrading ? null : () => onPlaceTrade(direction),
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: controller.isTrading ? color.withOpacity(0.5) : color,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}