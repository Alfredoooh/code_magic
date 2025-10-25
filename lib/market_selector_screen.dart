// 3. market_selector_screen.dart
// ========================================
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class MarketSelectorScreen extends StatelessWidget {
  final String currentMarket;
  final Map<String, String> allMarkets;
  final Function(String) onMarketSelected;

  const MarketSelectorScreen({
    Key? key,
    required this.currentMarket,
    required this.allMarkets,
    required this.onMarketSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: Colors.black,
      navigationBar: const CupertinoNavigationBar(
        backgroundColor: Color(0xFF1A1A1A),
        middle: Text(
          'Selecionar Mercado',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      child: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: allMarkets.length,
          itemBuilder: (context, index) {
            final entry = allMarkets.entries.elementAt(index);
            final isSelected = entry.key == currentMarket;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => onMarketSelected(entry.key),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF0066FF).withOpacity(0.2) : const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF0066FF) : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        CupertinoIcons.chart_bar_square,
                        color: isSelected ? const Color(0xFF0066FF) : Colors.white70,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontSize: 16,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (isSelected)
                        const Icon(
                          CupertinoIcons.check_mark_circled_solid,
                          color: Color(0xFF0066FF),
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}