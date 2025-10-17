// lib/screens/marketplace_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'dart:async';
import '../services/deriv_service.dart';
import '../widgets/login_sheet.dart';
import 'trading_screen.dart';

class MarketplaceScreen extends StatefulWidget {
  @override
  _MarketplaceScreenState createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final DerivService _derivService = DerivService();
  StreamSubscription? _connectionSub;
  StreamSubscription? _balanceSub;

  bool _isConnected = false;
  String? _accountInfo;
  double _balance = 0.0;
  String _currency = 'USD';

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  void _initializeService() {
    _connectionSub = _derivService.connectionStream.listen((connected) {
      if (mounted) {
        setState(() => _isConnected = connected);
      }
    });

    _balanceSub = _derivService.balanceStream.listen((balanceData) {
      if (mounted && balanceData != null) {
        setState(() {
          _balance = balanceData['balance'] ?? 0.0;
          _currency = balanceData['currency'] ?? 'USD';
          _accountInfo = balanceData['loginid'];
        });
      }
    });

    _derivService.loadSavedToken();
  }

  @override
  void dispose() {
    _connectionSub?.cancel();
    _balanceSub?.cancel();
    super.dispose();
  }

  void _showLoginSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LoginSheet(derivService: _derivService),
    );
  }

  void _disconnect() {
    _derivService.disconnect();
    setState(() {
      _isConnected = false;
      _accountInfo = null;
      _balance = 0.0;
    });
  }

  void _navigateToTrading() {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => TradingScreen(derivService: _derivService),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return CupertinoPageScaffold(
      backgroundColor: isDark ? Color(0xFF000000) : Color(0xFFF2F2F7),
      child: CustomScrollView(
        physics: BouncingScrollPhysics(),
        slivers: [
          CupertinoSliverNavigationBar(
            backgroundColor: isDark ? Color(0xFF1C1C1E) : CupertinoColors.white,
            border: null,
            largeTitle: Text(
              'Trading',
              style: TextStyle(
                color: isDark ? CupertinoColors.white : CupertinoColors.black,
                fontWeight: FontWeight.w800,
              ),
            ),
            trailing: _isConnected
                ? CupertinoButton(
                    padding: EdgeInsets.zero,
                    minSize: 0,
                    onPressed: _disconnect,
                    child: Icon(CupertinoIcons.power, color: Color(0xFFFF444F), size: 24),
                  )
                : null,
          ),
          SliverToBoxAdapter(
            child: _isConnected ? _buildConnectedView(isDark) : _buildDisconnectedView(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildDisconnectedView(bool isDark) {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          SizedBox(height: 60),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFF444F), Color(0xFFFF6B6B)],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(CupertinoIcons.chart_bar_alt_fill, size: 50, color: Colors.white),
          ),
          SizedBox(height: 32),
          Text(
            'Bem-vindo ao Trading',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Conecte sua conta Deriv para começar',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: CupertinoColors.systemGrey),
          ),
          SizedBox(height: 48),
          _buildFeatureCard(isDark, CupertinoIcons.speedometer, 'Trading Rápido'),
          SizedBox(height: 16),
          _buildFeatureCard(isDark, CupertinoIcons.chart_bar_square_fill, 'Análise em Tempo Real'),
          SizedBox(height: 16),
          _buildFeatureCard(isDark, CupertinoIcons.lock_shield_fill, 'Seguro e Confiável'),
          SizedBox(height: 48),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _showLoginSheet,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: Color(0xFFFF444F),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.link, size: 22, color: Colors.white),
                  SizedBox(width: 10),
                  Text(
                    'Conectar Conta Deriv',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(bool isDark, IconData icon, String title) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Color(0xFFFF444F).withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Color(0xFFFF444F), size: 26),
          ),
          SizedBox(width: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectedView(bool isDark) {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFF444F), Color(0xFFFF6B6B)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Saldo Disponível',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  '${_currency} ${_balance.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 16),
                if (_accountInfo != null)
                  Row(
                    children: [
                      Icon(CupertinoIcons.checkmark_seal_fill, size: 16, color: Colors.white),
                      SizedBox(width: 6),
                      Text(
                        _accountInfo!,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          SizedBox(height: 32),
          Text(
            'Ações Rápidas',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          SizedBox(height: 16),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _navigateToTrading,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: Color(0xFFFF444F).withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Color(0xFFFF444F).withOpacity(0.3), width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.chart_bar_circle_fill, color: Color(0xFFFF444F), size: 28),
                  SizedBox(width: 12),
                  Text(
                    'Abrir Tela de Trading',
                    style: TextStyle(
                      color: Color(0xFFFF444F),
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}