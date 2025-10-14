// lib/screens/admin_panel_screen.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

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
        final created = _extractTimestamp(doc.data());
        if (created != null) {
          final diff = created.difference(start).inDays;
          if (diff >= 0 && diff < days) userCounts[diff] = (userCounts[diff] ?? 0) + 1;
        }
      }

      for (var doc in activitiesSnap.docs) {
        final created = _extractTimestamp(doc.data());
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

  DateTime? _extractTimestamp(Map<String, dynamic>? data) {
    if (data == null) return null;
    final candidates = ['created_at', 'createdAt', 'timestamp', 'time', 'created'];
    for (final key in candidates) {
      if (!data.containsKey(key)) continue;
      final value = data[key];
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      if (value is int) {
        try {
          if (value.toString().length == 10) {
            return DateTime.fromMillisecondsSinceEpoch(value * 1000);
          }
          return DateTime.fromMillisecondsSinceEpoch(value);
        } catch (_) {}
      }
    }
    return null;
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
        final created = _extractTimestamp(data);
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
        backgroundColor: primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.appBarTheme.iconTheme?.color ?? Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Painel Admin', style: theme.textTheme.headline6?.copyWith(color: theme.appBarTheme.titleTextStyle?.color ?? Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: theme.appBarTheme.iconTheme?.color ?? Colors.white),
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
            color: primaryColor,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
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
                _buildDashboardTab(theme),
                _buildUsersTab(theme),
                _buildPostsTab(theme),
                _buildActivitiesTab(theme),
                _buildAnalyticsTab(theme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardTab(ThemeData theme) {
    return RefreshIndicator(
      onRefresh: () async {
        await _loadStatistics();
        await _updateChartsFromFirestore();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Visão Geral em Tempo Real', style: theme.textTheme.headline6?.copyWith(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _buildStatsGrid(theme),
          const SizedBox(height: 24),
          _buildOnlineUsersSection(theme.primaryColor),
          const SizedBox(height: 24),
          _buildChartCard(title: 'Crescimento de Usuários', data: _userGrowthData, color: theme.primaryColor, theme: theme),
          const SizedBox(height: 16),
          _buildChartCard(title: 'Atividade da Plataforma', data: _activityData, color: Colors.purple, theme: theme),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(ThemeData theme) {
    final primaryColor = theme.primaryColor;
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          icon: Icons.people,
          title: 'Total Usuários',
          value: '${_stats['totalUsers']}',
          color: primaryColor,
          trendData: _userGrowthData,
          theme: theme,
        ),
        _buildStatCard(
          icon: Icons.circle,
          title: 'Online Agora',
          value: '${_stats['activeUsers']}',
          color: Colors.green,
          isLive: true,
          showBar: true,
          trendData: _activityData,
          theme: theme,
        ),
        _buildStatCard(icon: Icons.star, title: 'Contas PRO', value: '${_stats['proUsers']}', color: Colors.amber, theme: theme),
        _buildStatCard(icon: Icons.article, title: 'Posts Totais', value: '${_stats['totalPosts']}', color: Colors.purple, theme: theme),
        _buildStatCard(icon: Icons.chat, title: 'Mensagens', value: '${_stats['totalMessages']}', color: Colors.orange, theme: theme),
        _buildStatCard(icon: Icons.person_add, title: 'Novos Hoje', value: '${_stats['newUsersToday']}', color: Colors.teal, theme: theme),
        _buildStatCard(icon: Icons.favorite, title: 'Total Likes', value: '${_stats['totalLikes']}', color: Colors.red, theme: theme),
        _buildStatCard(icon: Icons.block, title: 'Banidos', value: '${_stats['bannedUsers']}', color: Colors.grey, theme: theme),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    bool isLive = false,
    bool showBar = false,
    List<FlSpot>? trendData,
    required ThemeData theme,
  }) {
    Widget chart = const SizedBox.shrink();
    final data = trendData ?? [];
    if (data.length >= 2 && !showBar) {
      chart = SizedBox(
        height: 36,
        width: 80,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(show: false),
            titlesData: FlTitlesData(show: false),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: data,
                isCurved: true,
                color: color,
                barWidth: 2,
                dotData: FlDotData(show: false),
              ),
            ],
          ),
        ),
      );
    } else if (data.isNotEmpty && showBar) {
      final bars = <BarChartGroupData>[];
      for (var s in data) {
        bars.add(BarChartGroupData(
          x: s.x.toInt(),
          barRods: [BarChartRodData(toY: s.y, width: 6, color: color)],
        ));
      }
      chart = SizedBox(
        height: 40,
        width: 80,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceBetween,
            titlesData: FlTitlesData(show: false),
            borderData: FlBorderData(show: false),
            barGroups: bars,
            gridData: FlGridData(show: false),
          ),
        ),
      );
    }

    final cardBg = theme.cardColor;
    final textColor = theme.textTheme.bodyText1?.color ?? Colors.black;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: theme.brightness == Brightness.dark ? Colors.black54 : Colors.black12, blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 28),
              if (isLive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: const [
                      CircleAvatar(radius: 4, backgroundColor: Colors.green),
                      SizedBox(width: 6),
                      Text('LIVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(value, style: theme.textTheme.headline6?.copyWith(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
                    const SizedBox(height: 4),
                    Text(title, style: TextStyle(fontSize: 12, color: theme.textTheme.caption?.color ?? Colors.grey[600])),
                  ],
                ),
              ),
              chart,
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOnlineUsersSection(Color primaryColor) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').where('isOnline', isEqualTo: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox.shrink();
        final onlineUsers = snapshot.data!.docs;
        final theme = Theme.of(context);
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: theme.brightness == Brightness.dark ? Colors.black54 : Colors.black12, blurRadius: 4, offset: const Offset(0, 2))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(width: 10, height: 10, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Text('Usuários Online (${onlineUsers.length})', style: theme.textTheme.subtitle1?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: onlineUsers.map((doc) {
                  final userData = doc.data();
                  final username = (userData['username'] ?? 'Usuário').toString();
                  final profile = (userData['profile_image'] ?? '').toString();
                  return Column(
                    children: [
                      Stack(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundImage: profile.isNotEmpty ? NetworkImage(profile) : null,
                            backgroundColor: primaryColor.withOpacity(0.3),
                            child: profile.isEmpty ? Text(username[0].toUpperCase(), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor)) : null,
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      SizedBox(width: 56, child: Text(username, style: const TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis, textAlign: TextAlign.center)),
                    ],
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChartCard({required String title, required List<FlSpot> data, required Color color, required ThemeData theme}) {
    final spots = data.isEmpty ? [FlSpot(0, 0)] : data;
    final cardBg = theme.cardColor;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: theme.brightness == Brightness.dark ? Colors.black54 : Colors.black12, blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.subtitle1?.copyWith(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: color,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(show: true, color: color.withOpacity(0.2)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersTab(ThemeData theme) {
    final primaryColor = theme.primaryColor;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: theme.cardColor,
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: 'Buscar usuários...',
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                  filled: true,
                  fillColor: theme.canvasColor,
                ),
                onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('Todos', 'all', primaryColor),
                    _buildFilterChip('Online', 'online', primaryColor),
                    _buildFilterChip('PRO', 'pro', primaryColor),
                    _buildFilterChip('Banidos', 'banned', primaryColor),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

              var users = snapshot.data!.docs.where((doc) {
                final data = doc.data();
                final username = (data['username'] ?? '').toString().toLowerCase();
                final email = (data['email'] ?? '').toString().toLowerCase();
                bool matchesSearch = _searchQuery.isEmpty || username.contains(_searchQuery) || email.contains(_searchQuery);
                bool matchesFilter = true;
                if (_userFilter == 'online') matchesFilter = data['isOnline'] == true;
                if (_userFilter == 'pro') matchesFilter = data['pro'] == true;
                if (_userFilter == 'banned') matchesFilter = data['banned'] == true;
                return matchesSearch && matchesFilter;
              }).toList();

              if (users.isEmpty) {
                return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.people_outline, size: 64, color: Colors.grey), SizedBox(height: 12), Text('Nenhum usuário encontrado')]));
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final userDoc = users[index];
                  final userData = userDoc.data();
                  final userId = userDoc.id;
                  return _buildUserCard(userData, userId, primaryColor);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value, Color primaryColor) {
    final isSelected = _userFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) => setState(() => _userFilter = value),
        selectedColor: primaryColor.withOpacity(0.3),
        checkmarkColor: primaryColor,
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> userData, String userId, Color primaryColor) {
    final profile = (userData['profile_image'] ?? '').toString();
    final username = (userData['username'] ?? 'Usuário').toString();
    final email = (userData['email'] ?? '').toString();
    final tokens = userData['tokens'] ?? 0;
    final isOnline = userData['isOnline'] == true;
    final isPro = userData['pro'] == true;
    final isAdmin = userData['admin'] == true;
    final isBanned = userData['banned'] == true;
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      color: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundImage: profile.isNotEmpty ? NetworkImage(profile) : null,
              backgroundColor: primaryColor.withOpacity(0.3),
              child: profile.isEmpty ? Text(username[0].toUpperCase(), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryColor)) : null,
            ),
            if (isOnline)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(width: 14, height: 14, decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle, border: Border.all(color: theme.cardColor == Colors.white ? Colors.white : Colors.black, width: 2))),
              ),
          ],
        ),
        title: Row(
          children: [
            Flexible(child: Text(username, style: TextStyle(fontWeight: FontWeight.bold, color: theme.textTheme.bodyText1?.color))),
            if (isPro) ...[
              const SizedBox(width: 8),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(12)), child: const Text('PRO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white))),
            ],
            if (isAdmin) ...[
              const SizedBox(width: 8),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)), child: const Text('ADMIN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white))),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(email, style: TextStyle(fontSize: 12, color: theme.textTheme.caption?.color)),
            const SizedBox(height: 4),
            Text('$tokens tokens', style: TextStyle(fontSize: 12, color: theme.textTheme.caption?.color)),
            if (isBanned) const SizedBox(height: 4),
            if (isBanned) const Text('Usuário banido', style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        trailing: PopupMenuButton(
          icon: Icon(Icons.more_vert, color: theme.iconTheme.color),
          itemBuilder: (context) => [
            const PopupMenuItem(child: Text('Editar Dados'), value: 'edit'),
            PopupMenuItem(child: Text(isPro ? 'Remover PRO' : 'Promover a PRO'), value: 'pro'),
            PopupMenuItem(child: Text(isAdmin ? 'Remover Admin' : 'Tornar Admin'), value: 'admin'),
            PopupMenuItem(child: Text(isBanned ? 'Desbanir Usuário' : 'Banir Usuário'), value: 'ban'),
            const PopupMenuItem(child: Text('Excluir Usuário (Firestore)'), value: 'delete'),
          ],
          onSelected: (value) {
            if (value == 'edit') _editUser(userId, userData, primaryColor);
            if (value == 'pro') _togglePro(userId, isPro);
            if (value == 'admin') _toggleAdmin(userId, isAdmin);
            if (value == 'ban') _banOrUnbanUser(userId, username, isBanned);
            if (value == 'delete') _confirmDeleteUser(userId, username);
          },
        ),
      ),
    );
  }

  void _editUser(String userId, Map<String, dynamic> userData, Color primaryColor) {
    final tokensController = TextEditingController(text: '${userData['tokens'] ?? 0}');
    final usernameController = TextEditingController(text: userData['username'] ?? '');
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.dialogBackgroundColor,
        title: const Text('Editar Usuário'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: usernameController, decoration: const InputDecoration(labelText: 'Nome de usuário', prefixIcon: Icon(Icons.person))),
            const SizedBox(height: 16),
            TextField(controller: tokensController, decoration: const InputDecoration(labelText: 'Tokens', prefixIcon: Icon(Icons.monetization_on)), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(child: const Text('Cancelar'), onPressed: () => Navigator.pop(context)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            onPressed: () async {
              await FirebaseFirestore.instance.collection('users').doc(userId).update({
                'username': usernameController.text,
                'tokens': int.tryParse(tokensController.text) ?? 0,
              });
              Navigator.pop(context);
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usuário atualizado com sucesso')));
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  Future<void> _togglePro(String userId, bool isPro) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).update({'pro': !isPro});
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isPro ? 'PRO removido' : 'PRO ativado')));
  }

  Future<void> _toggleAdmin(String userId, bool isAdmin) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).update({'admin': !isAdmin});
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isAdmin ? 'Admin removido' : 'Admin ativado')));
  }

  Future<void> _banOrUnbanUser(String userId, String username, bool isCurrentlyBanned) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).update({'banned': !isCurrentlyBanned, 'isOnline': false});
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isCurrentlyBanned ? '$username desbanido' : '$username foi banido')));
  }

  void _confirmDeleteUser(String userId, String username) {
    bool alsoDeleteContent = true;
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return StatefulBuilder(builder: (context, setStateSB) {
          return AlertDialog(
            backgroundColor: theme.dialogBackgroundColor,
            title: const Text('Excluir Usuário'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Irás apagar o documento do utilizador em Firestore para "$username". Isto NÃO remove a conta do Firebase Auth. Deseja continuar?'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Checkbox(value: alsoDeleteContent, onChanged: (v) => setStateSB(() => alsoDeleteContent = v ?? true)),
                    const SizedBox(width: 8),
                    const Expanded(child: Text('Remover também posts e mensagens deste usuário')),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(child: const Text('Cancelar'), onPressed: () => Navigator.pop(context)),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Excluir'),
                onPressed: () async {
                  Navigator.pop(context);
                  await _deleteUser(userId, alsoDeleteContent);
                },
              ),
            ],
          );
        });
      },
    );
  }

  Future<void> _deleteUser(String userId, bool removeContent) async {
    try {
      // Delete user document
      await FirebaseFirestore.instance.collection('users').doc(userId).delete();

      // Optionally delete posts and messages
      if (removeContent) {
        await _deleteUserPostsAndMessages(userId);
      }

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Usuário excluído do Firestore')));
      _loadStatistics();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erro ao excluir usuário: $e')));
    }
  }

  Future<void> _deleteUserPostsAndMessages(String userId) async {
    try {
      // Delete posts by user
      final postsSnap = await FirebaseFirestore.instance.collection('posts').where('userId', isEqualTo: userId).get();
      for (var p in postsSnap.docs) {
        try {
          await FirebaseFirestore.instance.collection('posts').doc(p.id).delete();
        } catch (_) {}
      }
      // Delete messages by user
      final messagesSnap = await FirebaseFirestore.instance.collection('messages').where('senderId', isEqualTo: userId).get();
      for (var m in messagesSnap.docs) {
        try {
          await FirebaseFirestore.instance.collection('messages').doc(m.id).delete();
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('Erro ao apagar conteúdo do usuário: $e');
    }
  }

  Widget _buildPostsTab(ThemeData theme) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('posts').orderBy('timestamp', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final posts = snapshot.data!.docs;
        if (posts.isEmpty) return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.article, size: 64, color: Colors.grey), SizedBox(height: 12), Text('Nenhuma publicação encontrada')]));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index].data();
            final postId = posts[index].id;
            return _buildPostCard(post, postId, theme.primaryColor);
          },
        );
      },
    );
  }

  Widget _buildPostCard(Map<String, dynamic> postData, String postId, Color primaryColor) {
    final image = (postData['image'] ?? '').toString();
    final userName = (postData['userName'] ?? 'Usuário').toString();
    final content = (postData['content'] ?? '').toString();
    final likes = postData['likes'] ?? 0;
    final comments = postData['comments'] ?? 0;
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      color: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (image.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                image,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (c, e, st) => Container(height: 200, color: Colors.grey[200], child: const Icon(Icons.image, size: 50, color: Colors.grey)),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(radius: 20, backgroundColor: primaryColor.withOpacity(0.3), child: Text(userName[0].toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor))),
                    const SizedBox(width: 12),
                    Expanded(child: Text(userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                    IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deletePost(postId)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(content, maxLines: 3, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyText2),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.favorite, size: 18, color: Colors.red),
                    const SizedBox(width: 4),
                    Text('$likes', style: TextStyle(color: theme.textTheme.caption?.color)),
                    const SizedBox(width: 16),
                    const Icon(Icons.comment, size: 18, color: Colors.blue),
                    const SizedBox(width: 4),
                    Text('$comments', style: TextStyle(color: theme.textTheme.caption?.color)),
                    const SizedBox(width: 16),
                    const Icon(Icons.access_time, size: 18, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(_formatTimestamp(postData['timestamp']), style: TextStyle(color: theme.textTheme.caption?.color, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deletePost(String postId) async {
    final confirmed = await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: const Text('Tem certeza que deseja excluir esta publicação?'),
        actions: [
          TextButton(child: const Text('Cancelar'), onPressed: () => Navigator.pop(c, false)),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Excluir'), onPressed: () => Navigator.pop(c, true)),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseFirestore.instance.collection('posts').doc(postId).delete();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post deletado com sucesso')));
    }
  }

  Widget _buildActivitiesTab(ThemeData theme) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: theme.cardColor,
          child: Row(
            children: [
              Icon(Icons.access_time, color: theme.primaryColor),
              const SizedBox(width: 10),
              Text('Atividades em Tempo Real', style: theme.textTheme.subtitle1?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Expanded(
          child: _realtimeActivities.isEmpty
              ? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.history, size: 64, color: Colors.grey), SizedBox(height: 12), Text('Nenhuma atividade recente')]))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _realtimeActivities.length,
                  itemBuilder: (context, index) {
                    final activity = _realtimeActivities[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: _getActivityIcon(activity['icon'] ?? 'info', theme.primaryColor),
                        title: Text(activity['type'] ?? 'Atividade', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(activity['description'] ?? ''),
                        trailing: Text(_formatTimestamp(activity['timestamp']), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _getActivityIcon(String type, Color primaryColor) {
    IconData iconData;
    Color color;
    switch (type) {
      case 'user_add':
        iconData = Icons.person_add;
        color = primaryColor;
        break;
      case 'login':
        iconData = Icons.check_circle;
        color = Colors.green;
        break;
      case 'post':
        iconData = Icons.article;
        color = Colors.purple;
        break;
      case 'message':
        iconData = Icons.message;
        color = Colors.orange;
        break;
      default:
        iconData = Icons.info;
        color = Colors.grey;
    }
    return CircleAvatar(backgroundColor: color.withOpacity(0.2), child: Icon(iconData, color: color, size: 20));
  }

  Widget _buildAnalyticsTab(ThemeData theme) {
    final primaryColor = theme.primaryColor;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Analytics Avançado', style: theme.textTheme.headline6?.copyWith(fontSize: 24, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildPeriodButton('7 Dias', '7d', primaryColor)),
            const SizedBox(width: 8),
            Expanded(child: _buildPeriodButton('30 Dias', '30d', primaryColor)),
            const SizedBox(width: 8),
            Expanded(child: _buildPeriodButton('90 Dias', '90d', primaryColor)),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: theme.brightness == Brightness.dark ? Colors.black54 : Colors.black12, blurRadius: 4, offset: const Offset(0, 2))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Taxa de Conversão PRO', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Conversão', style: TextStyle(color: Colors.grey)), Text('${_calculateConversionRate()}%', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryColor))]),
              const SizedBox(height: 12),
              ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: _calculateConversionRate() / 100, backgroundColor: Colors.grey[200], color: primaryColor, minHeight: 8)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: theme.brightness == Brightness.dark ? Colors.black54 : Colors.black12, blurRadius: 4, offset: const Offset(0, 2))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Engajamento', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildEngagementRow('Likes Totais', _stats['totalLikes'] ?? 0, Icons.favorite, Colors.red),
              const SizedBox(height: 12),
              _buildEngagementRow('Comentários', _stats['totalComments'] ?? 0, Icons.comment, Colors.blue),
              const SizedBox(height: 12),
              _buildEngagementRow('Mensagens', _stats['totalMessages'] ?? 0, Icons.message, Colors.orange),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPeriodButton(String label, String value, Color primaryColor) {
    final isSelected = _selectedPeriod == value;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? primaryColor : Colors.grey[200],
        foregroundColor: isSelected ? Colors.white : Colors.black87,
        elevation: isSelected ? 4 : 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: () {
        setState(() => _selectedPeriod = value);
        _updateChartsFromFirestore();
      },
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  Widget _buildEngagementRow(String label, int value, IconData icon, Color color) {
    return Row(
      children: [
        Container(width: 48, height: 48, decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 24)),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 15))),
        Text(value.toString(), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      ],
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Agora';
    try {
      DateTime date;
      if (timestamp is Timestamp) {
        date = timestamp.toDate();
      } else if (timestamp is DateTime) {
        date = timestamp;
      } else if (timestamp is int) {
        date = DateTime.fromMillisecondsSinceEpoch(timestamp);
      } else {
        return 'Agora';
      }
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inDays > 0) return '${diff.inDays}d';
      if (diff.inHours > 0) return '${diff.inHours}h';
      if (diff.inMinutes > 0) return '${diff.inMinutes}min';
      return 'Agora';
    } catch (e) {
      return 'Agora';
    }
  }

  double _calculateConversionRate() {
    if ((_stats['totalUsers'] ?? 0) == 0) return 0;
    final totalUsers = (_stats['totalUsers'] ?? 0) as int;
    final pro = (_stats['proUsers'] ?? 0) as int;
    return double.parse(((pro / totalUsers) * 100).toStringAsFixed(0));
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