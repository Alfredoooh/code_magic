// lib/screens/history_tab.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../services/app_state.dart';

class HistoryTab extends StatefulWidget {
  const HistoryTab({super.key});
  @override
  State<HistoryTab> createState() => _HistoryTabState();
}

class _HistoryTabState extends State<HistoryTab> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final filtered = _filter == 'all'
        ? state.history
        : state.history.where((h) => h.status == _filter).toList();

    return Column(
      children: [
        // ── Filters ──
        SizedBox(
          height: 52,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            scrollDirection: Axis.horizontal,
            children: [
              for (final f in [
                ('all', 'Todos'),
                ('pending', 'Pendentes'),
                ('won', 'Ganhos'),
                ('lost', 'Perdidos'),
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: _filter == f.$1,
                    label: Text(f.$2),
                    onSelected: (_) => setState(() => _filter = f.$1),
                    selectedColor: const Color(0xFF268CD4),
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(
                      color: _filter == f.$1
                          ? Colors.white
                          : Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    side: BorderSide(
                      color: _filter == f.$1
                          ? const Color(0xFF268CD4)
                          : Colors.white.withOpacity(0.15),
                    ),
                    backgroundColor: Colors.white.withOpacity(0.06),
                    showCheckmark: false,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                  ),
                ),
            ],
          ),
        ),

        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history_outlined,
                          color: Colors.white.withOpacity(0.2), size: 64),
                      const SizedBox(height: 12),
                      Text('Sem bilhetes',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 15)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 100),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _HistoryCard(ticket: filtered[i]),
                ),
        ),
      ],
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final HistoryTicket ticket;
  const _HistoryCard({required this.ticket});

  @override
  Widget build(BuildContext context) {
    final Color statusColor;
    final String gainLabel;

    switch (ticket.status) {
      case 'won':
        statusColor = const Color(0xFF29D300);
        gainLabel = '+${ticket.net.toStringAsFixed(0)} Kz';
        break;
      case 'lost':
        statusColor = const Color(0xFFD60000);
        gainLabel = 'Perdido';
        break;
      default:
        statusColor = const Color(0xFFFFCE00);
        gainLabel = 'Pendente';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.sports_soccer_outlined,
                  color: Colors.white54, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ticket.events.split('+').first.trim(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${ticket.date.day.toString().padLeft(2, '0')}/'
                    '${ticket.date.month.toString().padLeft(2, '0')}/'
                    '${ticket.date.year}',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 11),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${ticket.stake.toStringAsFixed(0)} Kz',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 11)),
                const SizedBox(height: 2),
                Text(gainLabel,
                    style: TextStyle(
                        color: statusColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}