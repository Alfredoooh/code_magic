// home_screen.dart - COPIE ESTE ARQUIVO COMPLETO
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

// IMPORTS DAS OUTRAS TELAS - NÃO REMOVA
import 'markets_screen.dart';
import 'posts_screen.dart';
import 'trade_screen.dart';
import 'bots_screen.dart';
import 'portfolio_screen.dart';

class HomeScreen extends StatefulWidget {
  final String token;

  const HomeScreen({Key? key, required this.token}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTabIndex = 0;
  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = [
      MarketsScreen(token: widget.token),
      PostsScreen(token: widget.token),
    ];
  }

  void _showTradeOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.show_chart, color: Color(0xFF00C896)),
              title: const Text('Negociar', style: TextStyle(color: Colors.white)),
              subtitle: const Text(
                'Abrir tela de negociação',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TradeScreen(token: widget.token),
                  ),
                );
              },
            ),
            const Divider(color: Colors.white12, height: 1),
            ListTile(
              leading: const Icon(Icons.smart_toy_outlined, color: Color(0xFF0066FF)),
              title: const Text('Automatizar Trade', style: TextStyle(color: Colors.white)),
              subtitle: const Text(
                'Gerenciar bots de trading',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BotsScreen(token: widget.token),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: _showTradeOptions,
        ),
        title: CupertinoSlidingSegmentedControl<int>(
          backgroundColor: const Color(0xFF2A2A2A),
          thumbColor: const Color(0xFF0066FF),
          groupValue: _currentTabIndex,
          onValueChanged: (value) {
            if (value != null) {
              setState(() => _currentTabIndex = value);
            }
          },
          children: const {
            0: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text('Mercados', style: TextStyle(fontSize: 14)),
            ),
            1: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text('Publicações', style: TextStyle(fontSize: 14)),
            ),
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_wallet_outlined, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PortfolioScreen(token: widget.token),
                ),
              );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentTabIndex,
        children: _tabs,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TradeScreen(token: widget.token),
            ),
          );
        },
        backgroundColor: const Color(0xFF00C896),
        icon: const Icon(Icons.add_chart, color: Colors.white),
        label: const Text(
          'Negociar',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}