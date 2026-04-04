// lib/screens/ticket_tab.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';

class TicketTab extends StatefulWidget {
  const TicketTab({super.key});
  @override
  State<TicketTab> createState() => _TicketTabState();
}

class _TicketTabState extends State<TicketTab> {
  final _ctrl = TextEditingController();
  bool _loading = false;
  Map<String, dynamic>? _result;
  String? _err;

  Future<void> _check() async {
    final ref = _ctrl.text.trim();
    if (ref.isEmpty) return;
    setState(() { _loading = true; _result = null; _err = null; });
    final state = Provider.of<AppState>(context, listen: false);
    final data = await state.lookupTicket(ref);
    setState(() {
      _loading = false;
      if (data != null) _result = data;
      else _err = 'Bilhete não encontrado';
    });
    _ctrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // ── Scan area ──
          GestureDetector(
            onTap: () {},
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32),
              decoration: BoxDecoration(
                border: Border.all(
                    color: const Color(0xFF268CD4).withOpacity(0.5),
                    width: 2,
                    strokeAlign: BorderSide.strokeAlignInside),
                borderRadius: BorderRadius.circular(16),
                color: const Color(0xFF268CD4).withOpacity(0.05),
              ),
              child: Column(
                children: [
                  Icon(Icons.qr_code_scanner_rounded,
                      color: Colors.white.withOpacity(0.5), size: 56),
                  const SizedBox(height: 12),
                  const Text('Digitalizar QR Code',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('Aponte a câmera para o QR code do bilhete',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.5),
                          fontSize: 12)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // ── Manual input ──
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Número do bilhete...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.08),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.15)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.15)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: Color(0xFF268CD4)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                  onSubmitted: (_) => _check(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _loading ? null : _check,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF268CD4),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Validar',
                        style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Error ──
          if (_err != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                border: Border.all(color: Colors.red.withOpacity(0.4)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(_err!,
                  style: const TextStyle(color: Colors.red, fontSize: 13)),
            ),

          // ── Result ──
          if (_result != null) _TicketCard(data: _result!),
        ],
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _TicketCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final status = data['status'] ?? data['ticketStatus'] ?? 'pending';
    final Color statusColor;
    final String statusLabel;
    final IconData statusIcon;

    switch (status.toString().toLowerCase()) {
      case 'won':
      case 'win':
        statusColor = const Color(0xFF29D300);
        statusLabel = 'Ganho';
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'lost':
      case 'lose':
        statusColor = const Color(0xFFD60000);
        statusLabel = 'Perdido';
        statusIcon = Icons.cancel_rounded;
        break;
      case 'canceled':
        statusColor = Colors.grey;
        statusLabel = 'Cancelado';
        statusIcon = Icons.block_rounded;
        break;
      default:
        statusColor = const Color(0xFFFFCE00);
        statusLabel = 'Pendente';
        statusIcon = Icons.hourglass_top_rounded;
    }

    return Card(
      margin: const EdgeInsets.only(top: 4),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF112F6C), const Color(0xFF1A4A9E)],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 22),
                const SizedBox(width: 8),
                Text(statusLabel,
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
                const Spacer(),
                Text(
                  data['reference']?.toString() ??
                      data['id']?.toString() ??
                      '—',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.4), fontSize: 11),
                ),
              ],
            ),
          ),
          _row('Aposta', '${data['amount'] ?? data['stake'] ?? '—'} Kz'),
          _row('Índice Total',
              data['totalOdds'] != null
                  ? double.tryParse(data['totalOdds'].toString())
                          ?.toStringAsFixed(2) ??
                      '—'
                  : '—'),
          _row('Ganho Líquido',
              '${data['netGains'] ?? data['net'] ?? '—'} Kz',
              valueColor: statusColor),
          _row('Data', data['date']?.toString() ?? '—'),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {Color? valueColor}) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Text(label,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.5), fontSize: 13)),
            const Spacer(),
            Text(value,
                style: TextStyle(
                    color: valueColor ?? Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      );
}