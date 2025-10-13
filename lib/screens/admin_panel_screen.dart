// admin_panel_screen.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class AdminPanelScreen extends StatefulWidget {
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

    _usersSubscription = FirebaseFirestore.instance
        .collection('users')
        .snapshots()
        .listen((snapshot) {
      _loadStatistics();
      _updateChartsFromFirestore();
    });

    _postsSubscription = FirebaseFirestore.instance
        .collection('posts')
        .snapshots()
        .listen((snapshot) {
      _loadStatistics();
    });

    _messagesSubscription = FirebaseFirestore.instance
        .collection('messages')
        .snapshots()
        .listen((snapshot) {
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
      int days = _selectedPeriod == '7d' ? 7 : (_selectedPeriod == '30d' ? 30 : 90);

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
      print('Erro ao atualizar gráficos: $e');
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
      final totalTokens = users.fold<int>(0, (sum, u) => sum + (((u['tokens'] ?? 0) is int ? (u['tokens'] ?? 0) : int.tryParse((u['tokens'] ?? 0).toString()) ?? 0) as int));
      final totalLikes = postsSnapshot.docs.fold<int>(0, (sum, doc) => sum + (((doc.data()['likes'] ?? 0) is int ? (doc.data()['likes'] ?? 0) : int.tryParse((doc.data()['likes'] ?? 0).toString()) ?? 0) as int));
      final totalComments = postsSnapshot.docs.fold<int>(0, (sum, doc) => sum + (((doc.data()['comments'] ?? 0) is int ? (doc.data()['comments'] ?? 0) : int.tryParse((doc.data()['comments'] ?? 0).toString()) ?? 0) as int));

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
      print('Erro ao carregar estatísticas: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Painel Admin', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
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
              labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              tabs: [
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
                _buildDashboardTab(primaryColor),
                _buildUsersTab(primaryColor),
                _buildPostsTab(primaryColor),
                _buildActivitiesTab(primaryColor),
                _buildAnalyticsTab(primaryColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardTab(Color primaryColor) {
    return RefreshIndicator(
      onRefresh: () async {
        await _loadStatistics();
        await _updateChartsFromFirestore();
      },
      child: ListView(
        padding: EdgeInsets.all(16),
        children: [
          Text('Visão Geral em Tempo Real', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          SizedBox(height: 20),
          _buildStatsGrid(primaryColor),
          SizedBox(height: 24),
          _buildOnlineUsersSection(primaryColor),
          SizedBox(height: 24),
          _buildChartCard(title: 'Crescimento de Usuários', data: _userGrowthData, color: primaryColor),
          SizedBox(height: 16),
          _buildChartCard(title: 'Atividade da Plataforma', data: _activityData, color: Colors.purple),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(Color primaryColor) {
    return GridView.count(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(icon: Icons.people, title: 'Total Usuários', value: '${_stats['totalUsers']}', color: primaryColor),
        _buildStatCard(icon: Icons.circle, title: 'Online Agora', value: '${_stats['activeUsers']}', color: Colors.green, isLive: true),
        _buildStatCard(icon: Icons.star, title: 'Contas PRO', value: '${_stats['proUsers']}', color: Colors.amber),
        _buildStatCard(icon: Icons.article, title: 'Posts Totais', value: '${_stats['totalPosts']}', color: Colors.purple),
        _buildStatCard(icon: Icons.chat, title: 'Mensagens', value: '${_stats['totalMessages']}', color: Colors.orange),
        _buildStatCard(icon: Icons.person_add, title: 'Novos Hoje', value: '${_stats['newUsersToday']}', color: Colors.teal),
        _buildStatCard(icon: Icons.favorite, title: 'Total Likes', value: '${_stats['totalLikes']}', color: Colors.red),
        _buildStatCard(icon: Icons.block, title: 'Banidos', value: '${_stats['bannedUsers']}', color: Colors.grey),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    bool isLive = false,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
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
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(width: 8, height: 8, decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                      SizedBox(width: 4),
                      Text('LIVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
                    ],
                  ),
                ),
            ],
          ),
          SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildOnlineUsersSection(Color primaryColor) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').where('isOnline', isEqualTo: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return SizedBox.shrink();

        final onlineUsers = snapshot.data!.docs;

        return Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(width: 10, height: 10, decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                  SizedBox(width: 8),
                  Text('Usuários Online (${onlineUsers.length})', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: onlineUsers.map((doc) {
                  final userData = doc.data();
                  final username = userData['username'] ?? 'Usuário';
                  final profile = userData['profile_image'] ?? '';
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
                      SizedBox(height: 4),
                      SizedBox(width: 56, child: Text(username, style: TextStyle(fontSize: 11), overflow: TextOverflow.ellipsis, textAlign: TextAlign.center)),
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

  Widget _buildChartCard({required String title, required List<FlSpot> data, required Color color}) {
    final spots = data.isEmpty ? [FlSpot(0, 0)] : data;

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 16),
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

  Widget _buildUsersTab(Color primaryColor) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(16),
          color: Colors.white,
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: 'Buscar usuários...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
              ),
              SizedBox(height: 12),
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
              if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

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
                return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.people_outline, size: 64, color: Colors.grey), SizedBox(height: 12), Text('Nenhum usuário encontrado')]));
              }

              return ListView.builder(
                padding: EdgeInsets.all(16),
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
      padding: EdgeInsets.only(right: 8),
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
    final profile = userData['profile_image'] ?? '';
    final username = userData['username'] ?? 'Usuário';
    final email = userData['email'] ?? '';
    final tokens = userData['tokens'] ?? 0;
    final isOnline = userData['isOnline'] == true;
    final isPro = userData['pro'] == true;
    final isAdmin = userData['admin'] == true;

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: EdgeInsets.all(12),
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
                child: Container(width: 14, height: 14, decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2))),
              ),
          ],
        ),
        title: Row(
          children: [
            Flexible(child: Text(username, style: TextStyle(fontWeight: FontWeight.bold))),
            if (isPro) ...[
              SizedBox(width: 8),
              Container(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(12)), child: Text('PRO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white))),
            ],
            if (isAdmin) ...[
              SizedBox(width: 8),
              Container(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)), child: Text('ADMIN', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white))),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(email, style: TextStyle(fontSize: 12)),
            SizedBox(height: 4),
            Text('$tokens tokens', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        trailing: PopupMenuButton(
          icon: Icon(Icons.more_vert),
          itemBuilder: (context) => [
            PopupMenuItem(child: Text('Editar Dados'), value: 'edit'),
            PopupMenuItem(child: Text(isPro ? 'Remover PRO' : 'Promover a PRO'), value: 'pro'),
            PopupMenuItem(child: Text(isAdmin ? 'Remover Admin' : 'Tornar Admin'), value: 'admin'),
            PopupMenuItem(child: Text('Banir Usuário'), value: 'ban'),
          ],
          onSelected: (value) {
            if (value == 'edit') _editUser(userId, userData, primaryColor);
            if (value == 'pro') _togglePro(userId, isPro);
            if (value == 'admin') _toggleAdmin(userId, isAdmin);
            if (value == 'ban') _banUser(userId, username);
          },
        ),
      ),
    );
  }

  void _editUser(String userId, Map<String, dynamic> userData, Color primaryColor) {
    final tokensController = TextEditingController(text: '${userData['tokens'] ?? 0}');
    final usernameController = TextEditingController(text: userData['username'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Editar Usuário'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: usernameController, decoration: InputDecoration(labelText: 'Nome de usuário', prefixIcon: Icon(Icons.person))),
            SizedBox(height: 16),
            TextField(controller: tokensController, decoration: InputDecoration(labelText: 'Tokens', prefixIcon: Icon(Icons.monetization_on)), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(child: Text('Cancelar'), onPressed: () => Navigator.pop(context)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
            onPressed: () async {
              await FirebaseFirestore.instance.collection('users').doc(userId).update({
                'username': usernameController.text,
                'tokens': int.tryParse(tokensController.text) ?? 0,
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Usuário atualizado com sucesso')));
            },
            child: Text('Salvar'),
          ),
        ],
      ),
    );
  }

  Future<void> _togglePro(String userId, bool isPro) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).update({'pro': !isPro});
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isPro ? 'PRO removido' : 'PRO ativado')));
  }

  Future<void> _toggleAdmin(String userId, bool isAdmin) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).update({'admin': !isAdmin});
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isAdmin ? 'Admin removido' : 'Admin ativado')));
  }

  void _banUser(String userId, String username) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmar Banimento'),
        content: Text('Tem certeza que deseja banir $username?'),
        actions: [
          TextButton(child: Text('Cancelar'), onPressed: () => Navigator.pop(context)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await FirebaseFirestore.instance.collection('users').doc(userId).update({'banned': true, 'isOnline': false});
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$username foi banido')));
            },
            child: Text('Banir'),
          ),
        ],
      ),
    );
  }

  Widget _buildPostsTab(Color primaryColor) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('posts').orderBy('timestamp', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
        final posts = snapshot.data!.docs;
        if (posts.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.article, size: 64, color: Colors.grey), SizedBox(height: 12), Text('Nenhuma publicação encontrada')]));
        
        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index].data();
            final postId = posts[index].id;
            return _buildPostCard(post, postId, primaryColor);
          },
        );
      },
    );
  }

  Widget _buildPostCard(Map<String, dynamic> postData, String postId, Color primaryColor) {
    final image = postData['image'] ?? '';
    final userName = postData['userName'] ?? 'Usuário';
    final content = postData['content'] ?? '';
    final likes = postData['likes'] ?? 0;
    final comments = postData['comments'] ?? 0;

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (image.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                image,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (c, e, st) => Container(
                  height: 200,
                  color: Colors.grey[200],
                  child: Icon(Icons.image, size: 50, color: Colors.grey),
                ),
              ),
            ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: primaryColor.withOpacity(0.3),
                      child: Text(userName[0].toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor)),
                    ),
                    SizedBox(width: 12),
                    Expanded(child: Text(userName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deletePost(postId),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Text(content, maxLines: 3, overflow: TextOverflow.ellipsis),
                SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.favorite, size: 18, color: Colors.red),
                    SizedBox(width: 4),
                    Text('$likes', style: TextStyle(color: Colors.grey)),
                    SizedBox(width: 16),
                    Icon(Icons.comment, size: 18, color: Colors.blue),
                    SizedBox(width: 4),
                    Text('$comments', style: TextStyle(color: Colors.grey)),
                    SizedBox(width: 16),
                    Icon(Icons.access_time, size: 18, color: Colors.grey),
                    SizedBox(width: 4),
                    Text(_formatTimestamp(postData['timestamp']), style: TextStyle(color: Colors.grey, fontSize: 12)),
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Confirmar Exclusão'),
        content: Text('Tem certeza que deseja excluir esta publicação?'),
        actions: [
          TextButton(child: Text('Cancelar'), onPressed: () => Navigator.pop(c, false)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Excluir'),
            onPressed: () => Navigator.pop(c, true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseFirestore.instance.collection('posts').doc(postId).delete();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Post deletado com sucesso')));
    }
  }

  Widget _buildActivitiesTab(Color primaryColor) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(16),
          color: Colors.white,
          child: Row(
            children: [
              Icon(Icons.access_time, color: primaryColor),
              SizedBox(width: 10),
              Text('Atividades em Tempo Real', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Expanded(
          child: _realtimeActivities.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.history, size: 64, color: Colors.grey), SizedBox(height: 12), Text('Nenhuma atividade recente')]))
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: _realtimeActivities.length,
                  itemBuilder: (context, index) {
                    final activity = _realtimeActivities[index];
                    return Card(
                      margin: EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: _getActivityIcon(activity['icon'] ?? 'info', primaryColor),
                        title: Text(activity['type'] ?? 'Atividade', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(activity['description'] ?? ''),
                        trailing: Text(_formatTimestamp(activity['timestamp']), style: TextStyle(fontSize: 11, color: Colors.grey)),
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

  Widget _buildAnalyticsTab(Color primaryColor) {
    return ListView(
      padding: EdgeInsets.all(16),
      children: [
        Text('Analytics Avançado', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildPeriodButton('7 Dias', '7d', primaryColor)),
            SizedBox(width: 8),
            Expanded(child: _buildPeriodButton('30 Dias', '30d', primaryColor)),
            SizedBox(width: 8),
            Expanded(child: _buildPeriodButton('90 Dias', '90d', primaryColor)),
          ],
        ),
        SizedBox(height: 24),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Taxa de Conversão PRO', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Conversão', style: TextStyle(color: Colors.grey)),
                  Text('${_calculateConversionRate()}%', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: primaryColor)),
                ],
              ),
              SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: _calculateConversionRate() / 100,
                  backgroundColor: Colors.grey[200],
                  color: primaryColor,
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Engajamento', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              _buildEngagementRow('Likes Totais', _stats['totalLikes'] ?? 0, Icons.favorite, Colors.red),
              SizedBox(height: 12),
              _buildEngagementRow('Comentários', _stats['totalComments'] ?? 0, Icons.comment, Colors.blue),
              SizedBox(height: 12),
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
      child: Text(label, style: TextStyle(fontSize: 12)),
    );
  }

  Widget _buildEngagementRow(String label, int value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 24),
        ),
        SizedBox(width: 12),
        Expanded(child: Text(label, style: TextStyle(fontSize: 15))),
        Text(value.toString(), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
    return ((pro / totalUsers) * 100).roundToDouble();
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