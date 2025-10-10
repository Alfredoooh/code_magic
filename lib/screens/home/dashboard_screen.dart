import 'package:flutter/material.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:madeeasy/widgets/design_system.dart';
import 'package:madeeasy/localization/app_localizations.dart';
import 'package:madeeasy/services/market_service.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final MarketService _marketService = MarketService();
  double portfolioValue = 0.0;
  List<double> portfolioSparkline = [100, 105, 103, 110, 108, 115]; // Placeholder

  @override
  void initState() {
    super.initState();
    _loadPortfolio();
  }

  Future<void> _loadPortfolio() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final doc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (doc.exists) {
      setState(() {
        portfolioValue = (doc.data()!['portfolio_value'] as num?)?.toDouble() ?? 0.0;
      });
    }
    // Fetch real data from market service if needed
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final user = FirebaseAuth.instance.currentUser;
    return RefreshIndicator(
      onRefresh: _loadPortfolio,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${loc.translate('hello')!}, ${user?.displayName ?? 'User'} 👋',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            GlassCard(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${loc.translate('portfolio')!}: \$${portfolioValue.toStringAsFixed(2)} (+2.3%)',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 100,
                      child: SparklineChart(data: portfolioSparkline),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(loc.translate('quick_actions')!, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                QuickActionButton(icon: Icons.send_rounded, label: loc.translate('send')!, onPressed: () => Navigator.pushNamed(context, '/send_receive')),
                QuickActionButton(icon: Icons.qr_code_rounded, label: loc.translate('receive')!, onPressed: () => Navigator.pushNamed(context, '/send_receive')),
                QuickActionButton(icon: Icons.add_card_rounded, label: loc.translate('deposit')!, onPressed: () => Navigator.pushNamed(context, '/deposit')),
                QuickActionButton(icon: Icons.swap_horiz_rounded, label: loc.translate('convert')!, onPressed: () => Navigator.pushNamed(context, '/converter')),
              ],
            ),
            const SizedBox(height: 24),
            Text(loc.translate('watchlist')!, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('watchlists').where('userId', isEqualTo: user!.uid).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final watchlists = snapshot.data?.docs ?? [];
                if (watchlists.isEmpty) {
                  return Text(loc.translate('no_watchlists')!);
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: watchlists.length,
                  itemBuilder: (context, index) {
                    final item = watchlists[index].data() as Map<String, dynamic>;
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.trending_up_rounded, color: success),
                        title: Text(item['asset']),
                        subtitle: Text(item['price'].toString()),
                        trailing: SizedBox(
                          width: 80,
                          height: 40,
                          child: SparklineChart(data: [10, 12, 11, 13, 15]), // Placeholder
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 24),
            Text(loc.translate('recent_alerts')!, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('alerts').where('userId', isEqualTo: user.uid).orderBy('lastTriggered', descending: true).limit(5).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final alerts = snapshot.data?.docs ?? [];
                if (alerts.isEmpty) {
                  return Text(loc.translate('no_alerts')!);
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: alerts.length,
                  itemBuilder: (context, index) {
                    final alert = alerts[index].data() as Map<String, dynamic>;
                    return ListTile(
                      title: Text(alert['asset']),
                      subtitle: Text(alert['condition']),
                      trailing: Text(alert['lastTriggered'].toDate().toString()),
                    );
                  },
                );
              },
            ),
            // Add more widgets as per spec: top movers, calendar events, signals
          ],
        ),
      ),
    );
  }
}

class SendReceiveScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.translate('send_receive')!)),
      body: Center(child: Text('Send/Receive Interface')),
      // Implement form for send/receive
    );
  }
}

class DepositScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.translate('deposit')!)),
      body: Center(child: Text('Deposit Interface')),
      // Implement payment methods
    );
  }
}

class NotificationsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.translate('notifications')!)),
      body: Center(child: Text('Notifications Center')),
      // Implement list of notifications
    );
  }
}