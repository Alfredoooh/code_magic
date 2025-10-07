import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/theme_service.dart';

class HomeTab extends StatefulWidget {
  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  Map<String, dynamic>? _cryptoData;
  bool _isLoadingCrypto = true;
  int _messageCount = 0;
  int _channelCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadCryptoData(),
      _loadChatStats(),
    ]);
  }

  Future<void> _loadCryptoData() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.coingecko.com/api/v3/simple/price?ids=bitcoin,ethereum,tether&vs_currencies=eur,usd&include_24hr_change=true'),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          setState(() {
            _cryptoData = json.decode(response.body);
            _isLoadingCrypto = false;
          });
        }
      }
    } catch (e) {
      print('Erro ao carregar dados crypto: $e');
      if (mounted) {
        setState(() => _isLoadingCrypto = false);
      }
    }
  }

  Future<void> _loadChatStats() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final chatsSnapshot = await FirebaseFirestore.instance
          .collection('chats')
          .where('participants', arrayContains: user.uid)
          .get();

      int messages = 0;
      int channels = 0;

      for (var chat in chatsSnapshot.docs) {
        final data = chat.data();
        if (data['type'] == 'channel') {
          channels++;
        } else {
          messages++;
        }
      }

      if (mounted) {
        setState(() {
          _messageCount = messages;
          _channelCount = channels;
        });
      }
    } catch (e) {
      print('Erro ao carregar estatísticas: $e');
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bom dia';
    if (hour < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.displayName?.split(' ').first ?? 'Usuário';

    return Scaffold(
      backgroundColor: ThemeService.backgroundColor,
      appBar: AppBar(
        backgroundColor: ThemeService.backgroundColor,
        elevation: 0,
        title: Text(
          'Início',
          style: TextStyle(
            color: ThemeService.textColor,
            fontSize: 28,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(CupertinoIcons.refresh, color: ThemeService.textColor),
            onPressed: _loadData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildWelcomeCard(userName),
            const SizedBox(height: 20),
            _buildStatsCard(),
            const SizedBox(height: 20),
            _buildCryptoMarkets(),
            const SizedBox(height: 20),
            _buildTopCryptos(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(String userName) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1877F2), Color(0xFF0D47A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_getGreeting()}, $userName',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Vista geral do mercado',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              CupertinoIcons.chart_bar_fill,
              color: Colors.white,
              size: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ThemeService.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ThemeService.isDarkMode
              ? Colors.white.withOpacity(0.1)
              : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(CupertinoIcons.chat_bubble_2_fill, _messageCount.toString(), 'Conversas'),
          _buildStatItem(CupertinoIcons.group_solid, _channelCount.toString(), 'Canais'),
          _buildStatItem(CupertinoIcons.bell_fill, '0', 'Alertas'),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF1877F2), size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: ThemeService.textColor,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: ThemeService.textColor.withOpacity(0.6),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildCryptoMarkets() {
    if (_isLoadingCrypto) {
      return Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: ThemeService.cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_cryptoData == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: ThemeService.cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Text(
            'Erro ao carregar dados',
            style: TextStyle(color: ThemeService.textColor.withOpacity(0.6)),
          ),
        ),
      );
    }

    final btcEur = _cryptoData!['bitcoin']['eur'];
    final btcChange = _cryptoData!['bitcoin']['eur_24h_change'];
    final ethEur = _cryptoData!['ethereum']['eur'];
    final ethChange = _cryptoData!['ethereum']['eur_24h_change'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Mercados',
              style: TextStyle(
                color: ThemeService.textColor,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                'Ver Mercados',
                style: TextStyle(
                  color: Color(0xFF1877F2),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMarketCard(
                'BTC/EUR',
                '€${btcEur.toStringAsFixed(0)}',
                btcChange,
                const Color(0xFFF7931A),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMarketCard(
                'ETH/EUR',
                '€${ethEur.toStringAsFixed(0)}',
                ethChange,
                const Color(0xFF627EEA),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMarketCard(String pair, String price, double change, Color color) {
    final isPositive = change >= 0;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThemeService.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ThemeService.isDarkMode
              ? Colors.white.withOpacity(0.1)
              : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  CupertinoIcons.graph_square_fill,
                  color: color,
                  size: 20,
                ),
              ),
              const Spacer(),
              Icon(
                isPositive ? CupertinoIcons.arrow_up : CupertinoIcons.arrow_down,
                color: isPositive ? Colors.green : Colors.red,
                size: 16,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            pair,
            style: TextStyle(
              color: ThemeService.textColor.withOpacity(0.6),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            price,
            style: TextStyle(
              color: ThemeService.textColor,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${isPositive ? '+' : ''}${change.toStringAsFixed(2)}%',
            style: TextStyle(
              color: isPositive ? Colors.green : Colors.red,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopCryptos() {
    if (_isLoadingCrypto || _cryptoData == null) {
      return const SizedBox.shrink();
    }

    final btcEur = _cryptoData!['bitcoin']['eur'];
    final btcChange = _cryptoData!['bitcoin']['eur_24h_change'];
    final ethEur = _cryptoData!['ethereum']['eur'];
    final ethChange = _cryptoData!['ethereum']['eur_24h_change'];
    final usdtUsd = _cryptoData!['tether']['usd'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Ativos Principais',
              style: TextStyle(
                color: ThemeService.textColor,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text(
                'Ver Todos',
                style: TextStyle(
                  color: Color(0xFF1877F2),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: ThemeService.cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: ThemeService.isDarkMode
                  ? Colors.white.withOpacity(0.1)
                  : Colors.grey.withOpacity(0.2),
            ),
          ),
          child: Column(
            children: [
              _buildCryptoItem(
                'BTC',
                'Bitcoin',
                '€${btcEur.toStringAsFixed(2)}',
                btcChange,
                const Color(0xFFF7931A),
                CupertinoIcons.bitcoin_circle_fill,
              ),
              Divider(
                color: ThemeService.isDarkMode
                    ? Colors.white.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.2),
                height: 1,
              ),
              _buildCryptoItem(
                'ETH',
                'Ethereum',
                '€${ethEur.toStringAsFixed(2)}',
                ethChange,
                const Color(0xFF627EEA),
                CupertinoIcons.square_stack_3d_up_fill,
              ),
              Divider(
                color: ThemeService.isDarkMode
                    ? Colors.white.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.2),
                height: 1,
              ),
              _buildCryptoItem(
                'USDT',
                'Tether',
                '\$${usdtUsd.toStringAsFixed(2)}',
                0.0,
                const Color(0xFF26A17B),
                CupertinoIcons.money_dollar_circle_fill,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCryptoItem(String symbol, String name, String price, double change, Color color, IconData icon) {
    final isPositive = change >= 0;
    
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      title: Text(
        symbol,
        style: TextStyle(
          color: ThemeService.textColor,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        name,
        style: TextStyle(
          color: ThemeService.textColor.withOpacity(0.6),
          fontSize: 14,
        ),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            price,
            style: TextStyle(
              color: ThemeService.textColor,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (change != 0.0)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isPositive ? CupertinoIcons.arrow_up : CupertinoIcons.arrow_down,
                  color: isPositive ? Colors.green : Colors.red,
                  size: 12,
                ),
                const SizedBox(width: 2),
                Text(
                  '${change.toStringAsFixed(2)}%',
                  style: TextStyle(
                    color: isPositive ? Colors.green : Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
