// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/app_state.dart';
import 'sports_tab.dart';
import 'ticket_tab.dart';
import 'history_tab.dart';
import 'help_tab.dart';
import '../widgets/betslip_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tab = 0;

  static const _tabs = [
    SportsTab(),
    TicketTab(),
    HistoryTab(),
    HelpTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppState>(context);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFF0D1B3E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF112F6C),
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset('assets/favicon.png', width: 28, height: 28),
            ),
            const SizedBox(width: 10),
            RichText(
              text: TextSpan(
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 16),
                children: [
                  TextSpan(
                      text: 'Elephant',
                      style: TextStyle(color: cs.secondary)),
                  const TextSpan(
                      text: 'Bet AO',
                      style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              (state.config?.defaultCurrency ?? 'KZ').toUpperCase(),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700),
            ),
          ),
          if (state.error != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(Icons.wifi_off_rounded,
                  color: Colors.red.shade300, size: 20),
            ),
        ],
      ),
      body: Stack(
        children: [
          _tabs[_tab],
          // FAB betslip
          if (state.betslip.isNotEmpty)
            Positioned(
              bottom: 16,
              right: 16,
              child: _BetFab(
                count: state.betslip.length,
                onTap: () => _openBetslip(context),
              ),
            ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        backgroundColor: const Color(0xFF112F6C),
        indicatorColor: const Color(0xFF268CD4).withOpacity(0.25),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.sports_soccer_outlined),
            selectedIcon: Icon(Icons.sports_soccer),
            label: 'Desportos',
          ),
          NavigationDestination(
            icon: Icon(Icons.confirmation_number_outlined),
            selectedIcon: Icon(Icons.confirmation_number),
            label: 'Bilhete',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Histórico',
          ),
          NavigationDestination(
            icon: Icon(Icons.help_outline_rounded),
            selectedIcon: Icon(Icons.help_rounded),
            label: 'Ajuda',
          ),
        ],
      ),
    );
  }

  void _openBetslip(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const BetslipSheet(),
    );
  }
}

class _BetFab extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const _BetFab({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.pink,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: Colors.pink.withOpacity(0.5),
                blurRadius: 16,
                spreadRadius: 2),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.shopping_bag_outlined,
                color: Colors.white, size: 26),
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFCE00),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$count',
                    style: const TextStyle(
                        color: Colors.black,
                        fontSize: 10,
                        fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}