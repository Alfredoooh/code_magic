import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../widgets/design_system.dart';
import '../../localization/app_localizations.dart';

class ActivitiesScreen extends StatefulWidget {
  @override
  _ActivitiesScreenState createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          bottom: TabBar(
            tabs: [
              Tab(text: AppLocalizations.of(context)!.translate('transactions')!),
              Tab(text: AppLocalizations.of(context)!.translate('orders')!),
              Tab(text: AppLocalizations.of(context)!.translate('alerts')!),
              Tab(text: AppLocalizations.of(context)!.translate('reports')!),
            ],
          ),
          title: Text(AppLocalizations.of(context)!.translate('activities')!),
        ),
        body: TabBarView(
          children: [
            TransactionsList(),
            OrdersList(),
            AlertsList(),
            ReportsScreen(),
          ],
        ),
      ),
    );
  }
}

class TransactionsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('transactions').where('userId', isEqualTo: userId).orderBy('timestamp', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text(AppLocalizations.of(context)!.translate('error_loading')!));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final transactions = snapshot.data!.docs;
        if (transactions.isEmpty) {
          return Center(child: Text(AppLocalizations.of(context)!.translate('no_transactions')!));
        }
        return ListView.builder(
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final tx = transactions[index].data() as Map<String, dynamic>;
            return ListTile(
              leading: Icon(tx['type'] == 'deposit' ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, color: tx['type'] == 'deposit' ? success : danger),
              title: Text(tx['type']),
              subtitle: Text('${tx['amount']} - ${tx['timestamp'].toDate().toLocal().toString()}'),
              trailing: Text(tx['status']),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(tx['type']),
                    content: Text('Amount: ${tx['amount']}\nDescription: ${tx['description']}'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: Text(AppLocalizations.of(context)!.translate('close')!)),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class OrdersList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('orders').where('userId', isEqualTo: userId).orderBy('timestamp', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text(AppLocalizations.of(context)!.translate('error_loading')!));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final orders = snapshot.data!.docs;
        if (orders.isEmpty) {
          return Center(child: Text(AppLocalizations.of(context)!.translate('no_orders')!));
        }
        return ListView.builder(
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index].data() as Map<String, dynamic>;
            return ListTile(
              leading: Icon(Icons.shopping_cart_rounded, color: accentPrimary),
              title: Text(order['type']),
              subtitle: Text('${order['amount']} at ${order['price']} - ${order['timestamp'].toDate().toLocal().toString()}'),
              trailing: Text(order['status']),
              onTap: () {},
            );
          },
        );
      },
    );
  }
}

class AlertsList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('alerts').where('userId', isEqualTo: userId).orderBy('lastTriggered', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text(AppLocalizations.of(context)!.translate('error_loading')!));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final alerts = snapshot.data!.docs;
        if (alerts.isEmpty) {
          return Center(child: Text(AppLocalizations.of(context)!.translate('no_alerts')!));
        }
        return ListView.builder(
          itemCount: alerts.length,
          itemBuilder: (context, index) {
            final alert = alerts[index].data() as Map<String, dynamic>;
            return ListTile(
              leading: Icon(Icons.notifications_rounded, color: warning),
              title: Text(alert['asset']),
              subtitle: Text(alert['condition']),
              trailing: Switch(
                value: alert['active'],
                onChanged: (value) {
                  FirebaseFirestore.instance.collection('alerts').doc(alerts[index].id).update({'active': value});
                },
              ),
            );
          },
        );
      },
    );
  }
}

class ReportsScreen extends StatelessWidget {
  Future<void> _generatePdf() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Text('Performance Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.Text('P&L: \$1234.56'),
              pw.Text('Win Rate: 65%'),
            ],
          );
        },
      ),
    );
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/report.pdf');
    await file.writeAsBytes(await pdf.save());
    OpenFile.open(file.path);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppLocalizations.of(context)!.translate('reports')!, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
          CustomButton(
            text: AppLocalizations.of(context)!.translate('generate_report')!,
            onPressed: _generatePdf,
          ),
          const SizedBox(height: 24),
          Text(AppLocalizations.of(context)!.translate('performance_chart')!, style: Theme.of(context).textTheme.headlineSmall),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true),
                titlesData: FlTitlesData(show: true),
                borderData: FlBorderData(show: true),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      FlSpot(0, 100),
                      FlSpot(1, 120),
                      FlSpot(2, 110),
                      FlSpot(3, 130),
                      FlSpot(4, 125),
                      FlSpot(5, 140),
                    ],
                    isCurved: true,
                    color: success,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
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