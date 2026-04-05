// lib/widgets/betslip_sheet.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';

class BetslipSheet extends StatefulWidget {
  const BetslipSheet({super.key});

  @override
  State<BetslipSheet> createState() => _BetslipSheetState();
}

class _BetslipSheetState extends State<BetslipSheet> {
  final _stakeCtrl = TextEditingController(text: '500');
  double _stake = 500;

  @override
  void dispose() {
    _stakeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final gross = state.potentialGross(_stake);
    final tax = state.potentialTax(_stake);
    final net = state.potentialNet(_stake);

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, controller) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF112F6C),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 6),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  // Title
                  Row(
                    children: [
                      const Text('Meu Bilhete',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800)),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          state.clearBetslip();
                          Navigator.pop(context);
                        },
                        child: Text('Limpar',
                            style: TextStyle(
                                color: Colors.red.shade300, fontSize: 13)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Bet items
                  ...state.betslip.asMap().entries.map((e) {
                    final b = e.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.08)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${b.home} vs ${b.away}',
                                  style: TextStyle(
                                      color:
                                          Colors.white.withOpacity(0.5),
                                      fontSize: 11),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(b.label,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700)),
                              ],
                            ),
                          ),
                          Text(
                            b.oddValue.toStringAsFixed(2),
                            style: const TextStyle(
                                color: Color(0xFFFFCE00),
                                fontSize: 16,
                                fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () => state.removeBet(e.key),
                            icon: const Icon(Icons.close_rounded,
                                size: 18, color: Colors.white38),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 4),

                  // Summary
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        _sumRow('Índice Total',
                            state.totalOdds.toStringAsFixed(2)),
                        const SizedBox(height: 10),

                        // Stake input
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _stakeCtrl,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor:
                                      Colors.white.withOpacity(0.08),
                                  border: OutlineInputBorder(
                                    borderRadius:
                                        BorderRadius.circular(10),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 10),
                                ),
                                onChanged: (v) {
                                  setState(() {
                                    _stake = double.tryParse(v) ?? 0;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text('Kz',
                                style: TextStyle(
                                    color:
                                        Colors.white.withOpacity(0.5),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 10),

                        _sumRow('Ganho Bruto',
                            '${gross.toStringAsFixed(0)} Kz'),
                        const SizedBox(height: 4),
                        _sumRow(
                            'IVA (15%)', '-${tax.toStringAsFixed(0)} Kz',
                            valueColor: Colors.white38),
                        const Divider(
                            color: Colors.white12, height: 16),
                        _sumRow(
                          'Ganho Líquido',
                          '${net.toStringAsFixed(0)} Kz',
                          labelBold: true,
                          valueColor: const Color(0xFFFFCE00),
                          valueFontSize: 17,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Place bet button
                  FilledButton(
                    onPressed: _stake > 0 && state.betslip.isNotEmpty
                        ? () {
                            state.placeBet(_stake);
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context)
                                .showSnackBar(const SnackBar(
                              content: Text('✓ Bilhete submetido!'),
                              backgroundColor: Color(0xFF29D300),
                              duration: Duration(seconds: 3),
                            ));
                          }
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.pink,
                      disabledBackgroundColor:
                          Colors.white.withOpacity(0.1),
                      minimumSize: const Size(double.infinity, 54),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('✓  Apostar Agora',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sumRow(String label, String value,
      {Color? valueColor,
      bool labelBold = false,
      double valueFontSize = 13}) =>
      Row(
        children: [
          Text(label,
              style: TextStyle(
                  color: Colors.white.withOpacity(labelBold ? 1 : 0.5),
                  fontSize: 13,
                  fontWeight:
                      labelBold ? FontWeight.w700 : FontWeight.normal)),
          const Spacer(),
          Text(value,
              style: TextStyle(
                  color: valueColor ?? Colors.white,
                  fontSize: valueFontSize,
                  fontWeight: FontWeight.w700)),
        ],
      );
}