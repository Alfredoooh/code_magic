import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'admin_panel_widgets.dart';
import 'admin_panel_utils.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({Key? key}) : super(key: key);

  @override
  _AdminPanelScreenState createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  String _selectedPeriod = '7d';
  String _searchQuery = '';
  String _userFilter = 'all';

  List<Map<String, dynamic>> _realtimeActivities = [];

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _activitySubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _usersSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _postsSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _messagesSubscription;

  Map<String, dynamic> _stats = {
    'totalUsers': 0,
    'activeUsers': 0,
    'proUsers': 0,
    'totalPosts': 0,
    'totalTokens': 0,
    'newUsersToday': 0,
    'totalMessages': 0,
    'bannedUsers': 0,
    'totalLikes': 0,
    'totalComments': 0,
  };

  List<FlSpot> _userGrowthData = [];
  List<FlSpot> _activityData = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _setupRealtimeListeners();
    _loadStatistics();
    _updateChartsFromFirestore();
  }

  void _setupRealtimeListeners() {
    _activitySubscription = FirebaseFirestore.instance
        .collection('activities')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          _realtimeActivities = snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .toList()
              .cast<Map<String, dynamic>>();
        });
      }
      _updateChartsFromFirestore();
    });

    _usersSubscription =
        FirebaseFirestore.instance.collection('users').snapshots().listen((snapshot) {
      _loadStatistics();
      _updateChartsFromFirestore();
    });

    _postsSubscription =
        FirebaseFirestore.instance.collection('posts').snapshots().listen((snapshot) {
      _loadStatistics();
    });

    _messagesSubscription =
        FirebaseFirestore.instance.collection('messages').snapshots().listen((snapshot) {
      if (mounted) {
        setState(() {
          _stats['totalMessages'] = snapshot.docs.length;
        });
      }
    });
  }

  Future<void> _updateChartsFromFirestore() async {
    try {
      final now = DateTime.now();
      final days = _selectedPeriod == '7d' ? 7 : (_selectedPeriod == '30d' ? 30 : 90);
      final start = DateTime(now.year, now.month, now.day).subtract(Duration(days: days - 1));

      final usersSnap = await FirebaseFirestore.instance.collection('users').get();
      final activitiesSnap = await FirebaseFirestore.instance.collection('activities').get();

      Map<int, int> userCounts = {};
      Map<int, int> activityCounts = {};
      for (int i = 0; i < days; i++) {
        userCounts[i] = 0;
        activityCounts[i] = 0;
      }

      for (var doc in usersSnap.docs) {
        final created = AdminPanelUtils.extractTimestamp(doc.data());
        if (created != null) {
          final diff = created.difference(start).inDays;
          if (diff >= 0 && diff < days) userCounts[diff] = (userCounts[diff] ?? 0) + 1;
        }
      }

      for (var doc in activitiesSnap.docs) {
        final created = AdminPanelUtils.extractTimestamp(doc.data());
        if (created != null) {
          final diff = created.difference(start).inDays;
          if (diff >= 0 && diff < days) activityCounts[diff] = (activityCounts[diff] ?? 0) + 1;
        }
      }

      List<FlSpot> userSpots = [];
      List<FlSpot> activitySpots = [];
      int cumulative = 0;
      for (int i = 0; i < days; i++) {
        cumulative += userCounts[i] ?? 0;
        userSpots.add(FlSpot(i.toDouble(), cumulative.toDouble()));
        activitySpots.add(FlSpot(i.toDouble(), (activityCounts[i] ?? 0).toDouble()));
      }

      if (mounted) {
        setState(() {
          _userGrowthData = userSpots.isEmpty ? [FlSpot(0, 0)] : userSpots;
          _activityData = activitySpots.isEmpty ? [FlSpot(0, 0)] : activitySpots;
        });
      }
    } catch (e) {
      debugPrint('Erro ao atualizar gráficos: $e');
    }
  }

  Future<void> _loadStatistics() async {
    try {
      final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
      final postsSnapshot = await FirebaseFirestore.instance.collection('posts').get();
      final messagesSnapshot = await FirebaseFirestore.instance.collection('messages').get();

      final users = usersSnapshot.docs.map((d) => d.data()).toList();
      final totalUsers = usersSnapshot.docs.length;
      final activeUsers = users.where((u) => (u['isOnline'] == true)).length;
      final proUsers = users.where((u) => (u['pro'] == true)).length;
      final bannedUsers = users.where((u) => (u['banned'] == true)).length;
      final totalPosts = postsSnapshot.docs.length;
      final totalMessages = messagesSnapshot.docs.length;

      final totalTokens = users.fold<int>(0, (sum, u) {
        final raw = u['tokens'] ?? 0;
        if (raw is int) return sum + raw;
        final parsed = int.tryParse(raw.toString()) ?? 0;
        return sum + parsed;
      });

      final totalLikes = postsSnapshot.docs.fold<int>(0, (sum, doc) {
        final likes = doc.data()['likes'] ?? 0;
        if (likes is int) return sum + likes;
        return sum + (int.tryParse(likes.toString()) ?? 0);
      });

      final totalComments = postsSnapshot.docs.fold<int>(0, (sum, doc) {
        final comments = doc.data()['comments'] ?? 0;
        if (comments is int) return sum + comments;
        return sum + (int.tryParse(comments.toString()) ?? 0);
      });

      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final newUsersToday = usersSnapshot.docs.where((doc) {
        final data = doc.data();
        final created = AdminPanelUtils.extractTimestamp(data);
        return created != null && created.isAfter(startOfDay);
      }).length;

      if (mounted) {
        setState(() {
          _stats = {
            'totalUsers': totalUsers,
            'activeUsers': activeUsers,
            'proUsers': proUsers,
            'totalPosts': totalPosts,
            'totalTokens': totalTokens,
            'newUsersToday': newUsersToday,
            'totalMessages': totalMessages,
            'bannedUsers': bannedUsers,
            'totalLikes': totalLikes,
            'totalComments': totalComments,
          };
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar estatísticas: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final isDark = theme.brightness == Brightness.dark;
    final scaffoldBg = isDark ? Colors.black : Colors.grey[50];

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onBackground),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Painel Admin', style: theme.textTheme.titleLarge?.copyWith(
          color: theme.colorScheme.onBackground, 
          fontWeight: FontWeight.bold
        )),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: theme.colorScheme.onBackground),
            onPressed: () {
              _loadStatistics();
              _updateChartsFromFirestore();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              border: Border(
                bottom: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: theme.primaryColor,
              indicatorWeight: 3,
              labelColor: theme.primaryColor,
              unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              tabs: const [
                Tab(text: 'Dashboard'),
                Tab(text: 'Usuários'),
                Tab(text: 'Posts'),
                Tab(text: 'Atividades'),
                Tab(text: 'Analytics'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                AdminPanelWidgets.buildDashboardTab(
                  context,
                  theme, 
                  _stats, 
                  _userGrowthData, 
                  _activityData, 
                  _loadStatistics, 
                  _updateChartsFromFirestore
                ),
                AdminPanelWidgets.buildUsersTab(
                  context,
                  theme, 
                  _searchQuery, 
                  _userFilter,
                  (value) => setState(() => _searchQuery = value),
                  (value) => setState(() => _userFilter = value),
                  _loadStatistics,
                ),
                AdminPanelWidgets.buildPostsTab(context, theme),
                AdminPanelWidgets.buildActivitiesTab(context, theme, _realtimeActivities),
                AdminPanelWidgets.buildAnalyticsTab(
                  context,
                  theme, 
                  _selectedPeriod, 
                  _stats,
                  (value) {
                    setState(() => _selectedPeriod = value);
                    _updateChartsFromFirestore();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _activitySubscription?.cancel();
    _usersSubscription?.cancel();
    _postsSubscription?.cancel();
    _messagesSubscription?.cancel();
    super.dispose();
  }
}