import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'dashboard_screen.dart';
import 'package:madeeasy/screens/activities/activity_screen.dart';
import 'package:madeeasy/screens/community/community_screen.dart';
import 'package:madeeasy/screens/profile/profile_screen.dart';
import 'package:madeeasy/widgets/design_system.dart';
import 'package:madeeasy/localization/app_localizations.dart';
import 'package:madeeasy/screens/chart_screen.dart';
import 'package:madeeasy/screens/screener_screen.dart';
import 'package:madeeasy/screens/calculators_screen.dart';
import 'package:madeeasy/screens/journal_screen.dart';
import 'package:madeeasy/screens/strategies_screen.dart';
import 'package:madeeasy/screens/backtesting_screen.dart';
import 'package:madeeasy/screens/paper_trading_screen.dart';
import 'package:madeeasy/screens/reminders_screen.dart';
import 'package:madeeasy/screens/researcher_screen.dart';
import 'package:madeeasy/screens/dictionary_screen.dart';
import 'package:madeeasy/screens/converter/converter_screen.dart';
import 'package:madeeasy/screens/heatmap_screen.dart';
import 'package:madeeasy/screens/correlation_screen.dart';
import 'package:madeeasy/screens/football_screen.dart';
import 'package:madeeasy/screens/entertainment_hub_screen.dart';
import 'package:madeeasy/screens/learning_hub_screen.dart';
import 'package:madeeasy/screens/webinars_screen.dart';
import 'package:madeeasy/screens/notifications_screen.dart';
import 'package:madeeasy/services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    DashboardScreen(),
    ActivitiesScreen(),
    CommunityScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('K_paga'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_rounded),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => NotificationsScreen()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.show_chart_rounded),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => ChartScreen()));
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: accentPrimary),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person_rounded, size: 40, color: accentPrimary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    FirebaseAuth.instance.currentUser?.email ?? '',
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.search_rounded),
              title: Text(AppLocalizations.of(context)!.translate('screener')!),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => ScreenerScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.calculate_rounded),
              title: Text(AppLocalizations.of(context)!.translate('calculators')!),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => CalculatorsScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.book_rounded),
              title: Text(AppLocalizations.of(context)!.translate('journal')!),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => JournalScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.strategy_rounded),
              title: Text(AppLocalizations.of(context)!.translate('strategies')!),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => StrategiesScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.history_rounded),
              title: Text(AppLocalizations.of(context)!.translate('backtesting')!),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => BacktestingScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.description_rounded),
              title: Text(AppLocalizations.of(context)!.translate('paper_trading')!),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => PaperTradingScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.alarm_rounded),
              title: Text(AppLocalizations.of(context)!.translate('reminders')!),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => RemindersScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.science_rounded),
              title: Text(AppLocalizations.of(context)!.translate('researcher')!),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => ResearcherScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.menu_book_rounded),
              title: Text(AppLocalizations.of(context)!.translate('dictionary')!),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => DictionaryScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.swap_horiz_rounded),
              title: Text(AppLocalizations.of(context)!.translate('converter')!),
              onTap: () {
                Navigator.pushNamed(context, '/converter');
              },
            ),
            ListTile(
              leading: const Icon(Icons.grid_on_rounded),
              title: Text(AppLocalizations.of(context)!.translate('heatmap')!),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => HeatmapScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.scatter_plot_rounded),
              title: Text(AppLocalizations.of(context)!.translate('correlation')!),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => CorrelationScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.sports_soccer_rounded),
              title: Text(AppLocalizations.of(context)!.translate('football')!),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => FootballScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.movie_rounded),
              title: Text(AppLocalizations.of(context)!.translate('entertainment')!),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => EntertainmentHubScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.school_rounded),
              title: Text(AppLocalizations.of(context)!.translate('learning')!),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => LearningHubScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.video_call_rounded),
              title: Text(AppLocalizations.of(context)!.translate('webinars')!),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => WebinarsScreen()));
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout_rounded),
              title: Text(AppLocalizations.of(context)!.translate('logout')!),
              onTap: () async {
                await AuthService().signOut();
                Navigator.pushReplacementNamed(context, '/');
              },
            ),
          ],
        ),
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.dashboard_rounded),
            label: AppLocalizations.of(context)!.translate('dashboard')!,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.list_rounded),
            label: AppLocalizations.of(context)!.translate('activities')!,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.people_rounded),
            label: AppLocalizations.of(context)!.translate('community')!,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_rounded),
            label: AppLocalizations.of(context)!.translate('profile')!,
          ),
        ],
      ),
    );
  }
}