// 5. trade_controls.dart
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
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        border: Border(top: BorderSide(color: Color(0xFF2A2A2A))),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            _buildTradeTypeSelector(context),
            const SizedBox(height: 12),
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
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: controller.tradeTypes.length + 1,
        itemBuilder: (context, index) {
          if (index == controller.tradeTypes.length) {
            return _buildSoundToggle();
          }

          final type = controller.tradeTypes[index];
          final isSelected = controller.selectedTradeType == type['id'];

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              minSize: 0,
              onPressed: () => controller.changeTradeType(type['id']),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF0066FF) : const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      type['icon'],
                      color: isSelected ? Colors.white : Colors.white70,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      type['label'],
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSoundToggle() {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        minSize: 0,
        onPressed: () => controller.toggleSound(),
        child: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: controller.soundEnabled ? const Color(0xFF00C896) : const Color(0xFF2A2A2A),
            shape: BoxShape.circle,
          ),
          child: Icon(
            controller.soundEnabled ? CupertinoIcons.speaker_2_fill : CupertinoIcons.speaker_slash_fill,
            size: 20,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildStakeAndDurationRow() {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: onStakeTap,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Row(
                children: [
                  const Icon(CupertinoIcons.money_dollar, color: Colors.white70, size: 18),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      controller.stake.toStringAsFixed(2),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (controller.selectedTradeType != 'accumulators' &&
            controller.selectedTradeType != 'turbos') ...[
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: onDurationTap,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(CupertinoIcons.clock, color: Colors.white70, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      '${controller.durationValue}${controller.durationLabel}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPredictionSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Row(
            children: [
              Icon(CupertinoIcons.number, color: Colors.white70, size: 18),
              SizedBox(width: 8),
              Text('Prediction', style: TextStyle(color: Colors.white70, fontSize: 15)),
            ],
          ),
          Row(
            children: [
              CupertinoButton(
                padding: EdgeInsets.zero,
                minSize: 0,
                child: const Icon(CupertinoIcons.minus_circle_fill, color: Colors.white, size: 28),
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
                  ),
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                minSize: 0,
                child: const Icon(CupertinoIcons.plus_circle_fill, color: Colors.white, size: 28),
                onPressed: () {
                  if (controller.tickPrediction < 9) {
                    controller.setTickPrediction(controller.tickPrediction + 1);
                  ),
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTradeButtons() {
    if (controller.selectedTradeType == 'accumulators') {
      return _buildAccumulatorButton();
    }

    return Row(
      children: [
        Expanded(
          child: _buildTradeButton(
            controller.getButtonLabel(true),
            const Color(0xFF00C896),
            'buy',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildTradeButton(
            controller.getButtonLabel(false),
            const Color(0xFFFF4444),
            'sell',
          ),
        ),
      ],
    );
  }

  Widget _buildAccumulatorButton() {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: controller.isTrading
          ? null
          : () => onPlaceTrade(controller.hasActiveAccumulator ? 'sell' : 'buy'),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: controller.hasActiveAccumulator ? const Color(0xFFFF4444) : const Color(0xFF0066FF),
          borderRadius: BorderRadius.circular(32),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              controller.hasActiveAccumulator ? CupertinoIcons.xmark : CupertinoIcons.plus,
              color: Colors.white,
              size: 22,
            ),
            const SizedBox(width: 10),
            Text(
              controller.hasActiveAccumulator ? 'CLOSE' : 'OPEN',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTradeButton(String label, Color color, String direction) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: controller.isTrading ? null : () => onPlaceTrade(direction),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: controller.isTrading ? color.withOpacity(0.5) : color,
          borderRadius: BorderRadius.circular(32),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }