import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dashboard_screen.dart';
import '../activities/activities_screen.dart';
import '../community/community_screen.dart';
import '../profile/profile_screen.dart';
import '../../widgets/design_system.dart';
import '../../localization/app_localizations.dart';
import '../charts/chart_screen.dart';
import '../screener_screen.dart';
import '../calculators_screen.dart';
import '../journal_screen.dart';
import '../strategies_screen.dart';
import '../backtesting_screen.dart';
import '../paper_trading_screen.dart';
import '../reminders_screen.dart';
import '../researcher_screen.dart';
import '../dictionary_screen.dart';
import '../converter_screen.dart';
import '../heatmap_screen.dart';
import '../correlation_screen.dart';
import '../football_screen.dart';
import '../entertainment_hub_screen.dart';
import '../learning_hub_screen.dart';
import '../webinars_screen.dart';
import '../notifications_screen.dart';
import '../../services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    DashboardScreen(),
    ActivitiesScreen(),
    CommunityScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('K_paga', style: Theme.of(context).textTheme.headlineMedium),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_rounded),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => NotificationsScreen()));
            },
          ),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: accentGradient),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(gradient: accentGradient),
              child: Text(
                AppLocalizations.of(context)!.translate('menu')!,
                style: Theme.of(context).textTheme.headlineMedium!.copyWith(color: Colors.white),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart_rounded),
              title: Text(AppLocalizations.of(context)!.translate('charts')!),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => ChartScreen()));
              },
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
              leading: const Icon(Icons.code_rounded),
              title: Text(AppLocalizations.of(context)!.translate('strategies')!),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => StrategiesScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.timeline_rounded),
              title: Text(AppLocalizations.of(context)!.translate('backtesting')!),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => BacktestingScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.sim_card_rounded),
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
              leading: const Icon(Icons.search_rounded),
              title: Text(AppLocalizations.of(context)!.translate('researcher')!),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => ResearcherScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.book_online_rounded),
              title: Text(AppLocalizations.of(context)!.translate('dictionary')!),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => DictionaryScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.swap_horiz_rounded),
              title: Text(AppLocalizations.of(context)!.translate('converter')!),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => ConverterScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.grid_on_rounded),
              title: Text(AppLocalizations.of(context)!.translate('heatmaps')!),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => HeatmapScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.show_chart_rounded),
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
              leading: const Icon(Icons.games_rounded),
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
              leading: const Icon(Icons.videocam_rounded),
              title: Text(AppLocalizations.of(context)!.translate('webinars')!),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => WebinarsScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout_rounded),
              title: Text(AppLocalizations.of(context)!.translate('logout')!),
              onTap: () async {
                await AuthService().signOut();
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_rounded),
            label: AppLocalizations.of(context)!.translate('hub')!,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.history_rounded),
            label: AppLocalizations.of(context)!.translate('activities')!,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.group_rounded),
            label: AppLocalizations.of(context)!.translate('hub')!,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_rounded),
            label: AppLocalizations.of(context)!.translate('profile')!,
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: accentPrimary,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
      ),
    );
  }
}