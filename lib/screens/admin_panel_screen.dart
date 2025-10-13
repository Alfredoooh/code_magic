// admin_panel_screen.dart
import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AdminPanelScreen extends StatefulWidget {
  @override
  _AdminPanelScreenState createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // filtros e estado
  String _selectedPeriod = '7d';
  String _searchQuery = '';
  String _userFilter = 'all';

  // realtime lists
  List<Map<String, dynamic>> _realtimeActivities = [];

  // subscrições
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _activitySubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _usersSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _postsSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _messagesSubscription;

  // estatísticas
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

  // dados para charts (FlSpot)
  List<FlSpot> _userGrowthData = [];
  List<FlSpot> _activityData = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(() {
      // garante que o segmented control atualize ao trocar tab por swipe
      if (mounted) setState(() {});
    });
    _setupRealtimeListeners();
    _loadStatistics();
    _updateChartsFromFirestore(); // inicializa gráficos reais
  }

  void _setupRealtimeListeners() {
    // Atividades em tempo real (mantém lista curta)
    _activitySubscription = FirebaseFirestore.instance
        .collection('activities')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .listen((snapshot) {
      final list = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();

      if (mounted) {
        setState(() {
          _realtimeActivities = list.cast<Map<String, dynamic>>();
        });
      }

      // Notificar sobre novas atividades (apenas ex.: adicione lógica se quiser)
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final data = change.doc.data();
          if (data != null) _showActivityNotification(data);
        }
      }

      // atualizar charts quando chega nova atividade
      _updateChartsFromFirestore();
    });

    // Usuários - atualizar estatísticas e reagir a mudanças
    _usersSubscription = FirebaseFirestore.instance
        .collection('users')
        .snapshots()
        .listen((snapshot) {
      _loadStatistics(); // recalc stats
      for (var change in snapshot.docChanges) {
        final userData = change.doc.data();
        if (userData == null) continue;
        if (change.type == DocumentChangeType.added) {
          _logActivity('Novo usuário',
              '${userData['username'] ?? 'Usuário'} se cadastrou', 'user_add');
        } else if (change.type == DocumentChangeType.modified) {
          if (userData['isOnline'] == true) {
            _logActivity('Login',
                '${userData['username'] ?? 'Usuário'} entrou online', 'login');
          }
        }
      }

      // atualizar charts com base em novos usuários
      _updateChartsFromFirestore();
    });

    // Posts
    _postsSubscription = FirebaseFirestore.instance
        .collection('posts')
        .snapshots()
        .listen((snapshot) {
      _loadStatistics();
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final postData = change.doc.data();
          if (postData != null) {
            _logActivity('Novo Post',
                '${postData['userName'] ?? 'Usuário'} criou um post', 'post');
          }
        }
      }
    });

    // Mensagens
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

  Future<void> _logActivity(
      String type, String description, String icon) async {
    try {
      await FirebaseFirestore.instance.collection('activities').add({
        'type': type,
        'description': description,
        'icon': icon,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // ignore errors silently (pode logar)
    }
  }

  void _showActivityNotification(Map<String, dynamic> activity) {
    if (!mounted) return;
    // breve alerta baseado em Cupertino
    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => CupertinoAlertDialog(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _getActivityIcon(activity['icon'] ?? 'info'),
            SizedBox(width: 8),
            Flexible(child: Text(activity['type'] ?? 'Atividade')),
          ],
        ),
        content: Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text(activity['description'] ?? ''),
        ),
        actions: [
          CupertinoDialogAction(
            child: Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );

    // auto dismiss em 3s se ainda aberto
    Future.delayed(Duration(seconds: 3), () {
      if (mounted && Navigator.canPop(context)) {
        try {
          Navigator.pop(context);
        } catch (_) {}
      }
    });
  }

  Widget _getActivityIcon(String type) {
    IconData iconData;
    Color color;

    switch (type) {
      case 'user_add':
        iconData = CupertinoIcons.person_add;
        color = CupertinoColors.systemBlue;
        break;
      case 'login':
        iconData = CupertinoIcons.checkmark_circle_fill;
        color = CupertinoColors.systemGreen;
        break;
      case 'post':
        iconData = CupertinoIcons.square_pencil;
        color = CupertinoColors.systemPurple;
        break;
      case 'message':
        iconData = CupertinoIcons.chat_bubble_fill;
        color = CupertinoColors.systemOrange;
        break;
      default:
        iconData = CupertinoIcons.info_circle_fill;
        color = CupertinoColors.systemGrey;
    }

    return Icon(iconData, color: color, size: 20);
  }

  /// Atualiza os dados do gráfico com base em contagens reais do Firestore
  Future<void> _updateChartsFromFirestore() async {
    try {
      final now = DateTime.now();
      int days = 7;
      if (_selectedPeriod == '7d') days = 7;
      if (_selectedPeriod == '30d') days = 30;
      if (_selectedPeriod == '90d') days = 90;

      final start = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: days - 1));

      // Busca usuários criados desde start (tenta fazer query por campo 'created_at' ou 'createdAt')
      final usersSnap = await FirebaseFirestore.instance
          .collection('users')
          .where('created_at', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .get()
          .catchError((_) async {
        // fallback: buscar sem filtro (client-side)
        return await FirebaseFirestore.instance.collection('users').get();
      });

      // Buscar atividades com timestamp >= start
      final activitiesSnap = await FirebaseFirestore.instance
          .collection('activities')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
          .get()
          .catchError((_) async {
        return await FirebaseFirestore.instance.collection('activities').get();
      });

      // Converte snapshots em listas de DateTime (tentando vários campos)
      List<DateTime> userDates = usersSnap.docs.map((d) {
        final data = d.data();
        return _extractTimestamp(data) ?? DateTime.now();
      }).toList();

      List<DateTime> activityDates = activitiesSnap.docs.map((d) {
        final data = d.data();
        return _extractTimestamp(data) ?? DateTime.now();
      }).toList();

      // Conta por dia
      Map<int, int> userCounts = {};
      Map<int, int> activityCounts = {};
      for (int i = 0; i < days; i++) {
        userCounts[i] = 0;
        activityCounts[i] = 0;
      }

      for (var dt in userDates) {
        final diff = dt.toLocal().difference(start).inDays;
        if (diff >= 0 && diff < days) userCounts[diff] = (userCounts[diff] ?? 0) + 1;
      }

      for (var dt in activityDates) {
        final diff = dt.toLocal().difference(start).inDays;
        if (diff >= 0 && diff < days) activityCounts[diff] = (activityCounts[diff] ?? 0) + 1;
      }

      // Monta FlSpot arrays (x = dia index, y = count aggregated cumulative or raw — aqui usamos cumulativo para crescimento)
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
          _userGrowthData = userSpots;
          _activityData = activitySpots;
        });
      }
    } catch (e) {
      // falha silenciosa: mantemos dados anteriores
      // se quiser, logue aqui
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
        // epoch millis?
        try {
          return DateTime.fromMillisecondsSinceEpoch(value);
        } catch (_) {}
      }
    }
    return null;
  }

  Future<void> _loadStatistics() async {
    try {
      final usersSnapshot =
          await FirebaseFirestore.instance.collection('users').get();
      final postsSnapshot =
          await FirebaseFirestore.instance.collection('posts').get();
      final messagesSnapshot =
          await FirebaseFirestore.instance.collection('messages').get();

      final users = usersSnapshot.docs.map((d) => d.data()).toList();
      final totalUsers = usersSnapshot.docs.length;
      final activeUsers =
          users.where((u) => (u['isOnline'] == true)).length;
      final proUsers = users.where((u) => (u['pro'] == true)).length;
      final bannedUsers = users.where((u) => (u['banned'] == true)).length;
      final totalPosts = postsSnapshot.docs.length;
      final totalMessages = messagesSnapshot.docs.length;
      final totalTokens = users.fold<int>(
          0, (sum, u) => sum + ((u['tokens'] ?? 0) is int ? (u['tokens'] ?? 0) : int.tryParse((u['tokens'] ?? 0).toString()) ?? 0));
      final totalLikes = postsSnapshot.docs.fold<int>(
          0,
          (sum, doc) =>
              sum + ((doc.data()['likes'] ?? 0) is int ? (doc.data()['likes'] ?? 0) : int.tryParse((doc.data()['likes'] ?? 0).toString()) ?? 0));
      final totalComments = postsSnapshot.docs.fold<int>(
          0,
          (sum, doc) =>
              sum + ((doc.data()['comments'] ?? 0) is int ? (doc.data()['comments'] ?? 0) : int.tryParse((doc.data()['comments'] ?? 0).toString()) ?? 0));

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
      // ignore erro, opcional: print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = CupertinoColors.systemGroupedBackground.resolveFrom(context);
    final cardBg = CupertinoColors.systemBackground.resolveFrom(context);

    return CupertinoPageScaffold(
      backgroundColor: bg,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.systemBackground.withOpacity(0.95),
        border: null,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(CupertinoIcons.back, color: CupertinoColors.systemBlue),
          onPressed: () => Navigator.pop(context),
        ),
        middle: Text(
          'Painel Admin',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(CupertinoIcons.refresh, color: CupertinoColors.systemBlue),
          onPressed: () {
            _loadStatistics();
            _updateChartsFromFirestore();
          },
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Segmented control sincronizado com TabController.index
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: CupertinoSegmentedControl<int>(
                padding: EdgeInsets.all(6),
                borderColor: CupertinoColors.systemGrey4,
                selectedColor: CupertinoColors.systemBlue,
                unselectedColor: CupertinoColors.systemBackground,
                groupValue: _tabController.index,
                onValueChanged: (value) {
                  setState(() {
                    _tabController.animateTo(value);
                  });
                },
                children: {
                  0: _segmentedLabel('Dashboard'),
                  1: _segmentedLabel('Usuários'),
                  2: _segmentedLabel('Posts'),
                  3: _segmentedLabel('Atividades'),
                  4: _segmentedLabel('Analytics'),
                },
              ),
            ),

            // Conteúdo
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildDashboardTab(cardBg),
                  _buildUsersTab(cardBg),
                  _buildPostsTab(cardBg),
                  _buildActivitiesTab(cardBg),
                  _buildAnalyticsTab(cardBg),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _segmentedLabel(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Text(text, style: TextStyle(fontSize: 13)),
    );
  }

  // --------------------------- DASHBOARD ---------------------------
  Widget _buildDashboardTab(Color cardBg) {
    return CupertinoScrollbar(
      child: CustomScrollView(
        slivers: [
          CupertinoSliverRefreshControl(onRefresh: () async {
            await _loadStatistics();
            await _updateChartsFromFirestore();
          }),
          SliverPadding(
            padding: EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(
                  'Visão Geral em Tempo Real',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: CupertinoColors.label,
                  ),
                ),
                SizedBox(height: 20),
                _buildStatsGrid(cardBg),
                SizedBox(height: 24),
                _buildOnlineUsersSection(cardBg),
                SizedBox(height: 24),
                _buildChartCard(
                  title: 'Crescimento de Usuários',
                  data: _userGrowthData,
                  color: CupertinoColors.systemBlue,
                ),
                SizedBox(height: 16),
                _buildChartCard(
                  title: 'Atividade da Plataforma',
                  data: _activityData,
                  color: CupertinoColors.systemPurple,
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(Color cardBg) {
    return GridView.count(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _buildStatCard(
          icon: CupertinoIcons.person_2_fill,
          title: 'Total Usuários',
          value: '${_stats['totalUsers']}',
          color: CupertinoColors.systemBlue,
        ),
        _buildStatCard(
          icon: CupertinoIcons.circle_fill,
          title: 'Online Agora',
          value: '${_stats['activeUsers']}',
          color: CupertinoColors.systemGreen,
          isLive: true,
        ),
        _buildStatCard(
          icon: CupertinoIcons.star_fill,
          title: 'Contas PRO',
          value: '${_stats['proUsers']}',
          color: CupertinoColors.systemYellow,
        ),
        _buildStatCard(
          icon: CupertinoIcons.doc_text_fill,
          title: 'Posts Totais',
          value: '${_stats['totalPosts']}',
          color: CupertinoColors.systemPurple,
        ),
        _buildStatCard(
          icon: CupertinoIcons.chat_bubble_2_fill,
          title: 'Mensagens',
          value: '${_stats['totalMessages']}',
          color: CupertinoColors.systemOrange,
        ),
        _buildStatCard(
          icon: CupertinoIcons.person_badge_plus_fill,
          title: 'Novos Hoje',
          value: '${_stats['newUsersToday']}',
          color: CupertinoColors.systemTeal,
        ),
        _buildStatCard(
          icon: CupertinoIcons.heart_fill,
          title: 'Total Likes',
          value: '${_stats['totalLikes']}',
          color: CupertinoColors.systemRed,
        ),
        _buildStatCard(
          icon: CupertinoIcons.xmark_shield_fill,
          title: 'Banidos',
          value: '${_stats['bannedUsers']}',
          color: CupertinoColors.systemGrey,
        ),
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
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withOpacity(0.06),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 26),
              if (isLive)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGreen.withOpacity(0.13),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 6),
                      Text(
                        'LIVE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: CupertinoColors.systemGreen,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: CupertinoColors.label,
            ),
          ),
          SizedBox(height: 6),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: CupertinoColors.systemGrey),
          ),
        ],
      ),
    );
  }

  Widget _buildOnlineUsersSection(Color cardBg) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('isOnline', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SizedBox.shrink();
        }
        final onlineUsers = snapshot.data!.docs;
        if (onlineUsers.isEmpty) return SizedBox.shrink();

        return Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CupertinoColors.systemBackground,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Usuários Online (${onlineUsers.length})',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: CupertinoColors.label,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              SizedBox(
                height: 70,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: onlineUsers.length,
                  itemBuilder: (context, index) {
                    final userData = onlineUsers[index].data();
                    final username = (userData['username'] ?? 'U').toString();
                    final profile = userData['profile_image'] ?? '';
                    return Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: profile == '' ? CupertinoColors.systemGrey5 : null,
                                  image: profile != '' ? DecorationImage(
                                    image: NetworkImage(profile),
                                    fit: BoxFit.cover,
                                  ) : null,
                                ),
                                child: profile == ''
                                    ? Center(
                                        child: Text(
                                          username[0].toUpperCase(),
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: CupertinoColors.white,
                                          ),
                                        ),
                                      )
                                    : null,
                              ),
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  width: 14,
                                  height: 14,
                                  decoration: BoxDecoration(
                                    color: CupertinoColors.systemGreen,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: CupertinoColors.systemBackground,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 6),
                          SizedBox(
                            width: 52,
                            child: Text(
                              username,
                              style: TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                            ),
                          )
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --------------------------- CHART CARD ---------------------------
  Widget _buildChartCard({
    required String title,
    required List<FlSpot> data,
    required Color color,
  }) {
    final spots = data.isNotEmpty
        ? data
        : List.generate(7, (i) => FlSpot(i.toDouble(), Random().nextInt(10).toDouble()));

    return Container(
      padding: EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: CupertinoColors.label)),
          SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 10,
                    getDrawingHorizontalLine: (value) {
                  return FlLine(color: CupertinoColors.systemGrey5, strokeWidth: 0.5);
                }),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40, getTitlesWidget: (value, meta) {
                    return Text(value.toInt().toString(), style: TextStyle(color: CupertinoColors.systemGrey, fontSize: 10));
                  })),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, getTitlesWidget: (value, meta) {
                    // gera labels relativas (ex: -6 .. 0). Você pode personalizar
                    final daysCount = spots.length;
                    final idx = value.toInt();
                    final labels = daysCount <= 7 ? ['Seg','Ter','Qua','Qui','Sex','Sáb','Dom'] : List.generate(daysCount, (i) => '');
                    if (idx >= 0 && idx < labels.length) {
                      return Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: Text(labels[idx], style: TextStyle(color: CupertinoColors.systemGrey, fontSize: 10)),
                      );
                    }
                    return Text('');
                  }))),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: color,
                    barWidth: 2.4,
                    dotData: FlDotData(show: true, getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(radius: 3, color: color, strokeWidth: 1.4, strokeColor: CupertinoColors.systemBackground);
                    }),
                    belowBarData: BarAreaData(show: true, gradient: LinearGradient(colors: [color.withOpacity(0.28), color.withOpacity(0.0)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------- USERS TAB ---------------------------
  Widget _buildUsersTab(Color cardBg) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          color: CupertinoColors.systemBackground,
          child: Column(
            children: [
              CupertinoSearchTextField(
                placeholder: 'Buscar usuários...',
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
              ),
              SizedBox(height: 10),
              CupertinoSegmentedControl<String>(
                groupValue: _userFilter,
                onValueChanged: (value) {
                  setState(() {
                    _userFilter = value;
                  });
                },
                children: {
                  'all': Text('Todos', style: TextStyle(fontSize: 12)),
                  'online': Text('Online', style: TextStyle(fontSize: 12)),
                  'pro': Text('PRO', style: TextStyle(fontSize: 12)),
                  'banned': Text('Banidos', style: TextStyle(fontSize: 12)),
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return Center(child: CupertinoActivityIndicator());
              final docs = snapshot.data!.docs;
              final users = docs.where((doc) {
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
                return Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(CupertinoIcons.person_2, size: 64, color: CupertinoColors.systemGrey),
                    SizedBox(height: 12),
                    Text('Nenhum usuário encontrado', style: TextStyle(fontSize: 16, color: CupertinoColors.systemGrey))
                  ]),
                );
              }

              return CupertinoScrollbar(
                child: ListView.builder(
                  padding: EdgeInsets.all(12),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final userDoc = users[index];
                    final userData = userDoc.data();
                    final userId = userDoc.id;
                    return _buildUserCard(userData, userId);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildUserCard(Map<String, dynamic> userData, String userId) {
    final profile = userData['profile_image'] ?? '';
    final username = userData['username'] ?? 'Usuário';
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(10),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: profile == '' ? CupertinoColors.systemGrey5 : null,
                    image: profile != '' ? DecorationImage(image: NetworkImage(profile), fit: BoxFit.cover) : null,
                  ),
                  child: profile == ''
                      ? Center(child: Text((username[0] ?? 'U').toUpperCase(), style: TextStyle(fontSize: 20, color: CupertinoColors.white, fontWeight: FontWeight.bold)))
                      : null,
                ),
                if (userData['isOnline'] == true)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemGreen,
                        shape: BoxShape.circle,
                        border: Border.all(color: CupertinoColors.systemBackground, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Text(username, style: TextStyle(fontWeight: FontWeight.w600, color: CupertinoColors.label)),
                  SizedBox(width: 8),
                  if (userData['pro'] == true)
                    Container(padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: CupertinoColors.systemYellow, borderRadius: BorderRadius.circular(6)), child: Text('PRO', style: TextStyle(color: CupertinoColors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                  if (userData['admin'] == true)
                    Container(margin: EdgeInsets.only(left: 6), padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: CupertinoColors.systemRed, borderRadius: BorderRadius.circular(6)), child: Text('ADMIN', style: TextStyle(color: CupertinoColors.white, fontSize: 10, fontWeight: FontWeight.bold))),
                ]),
                SizedBox(height: 6),
                Text(userData['email'] ?? '', style: TextStyle(color: CupertinoColors.systemGrey, fontSize: 13)),
                SizedBox(height: 4),
                Text('${userData['tokens'] ?? 0} tokens', style: TextStyle(color: CupertinoColors.systemGrey2, fontSize: 12)),
              ]),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: Icon(CupertinoIcons.ellipsis_circle, color: CupertinoColors.systemGrey, size: 26),
              onPressed: () => _showUserOptions(userId, userData),
            )
          ],
        ),
      ),
    );
  }

  void _showUserOptions(String userId, Map<String, dynamic> userData) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text('Gerenciar Usuário'),
        message: Text(userData['username'] ?? 'Usuário'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _editUser(userId, userData);
            },
            child: Text('Editar Dados'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _togglePro(userId, userData['pro'] == true);
            },
            child: Text(userData['pro'] == true ? 'Remover PRO' : 'Promover a PRO'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _toggleAdmin(userId, userData['admin'] == true);
            },
            child: Text(userData['admin'] == true ? 'Remover Admin' : 'Tornar Admin'),
          ),
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              _banUser(userId, userData['username'] ?? 'Usuário');
            },
            child: Text('Banir Usuário'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(context),
          child: Text('Cancelar'),
        ),
      ),
    );
  }

  void _editUser(String userId, Map<String, dynamic> userData) {
    final tokensController = TextEditingController(text: '${userData['tokens'] ?? 0}');
    final usernameController = TextEditingController(text: userData['username'] ?? '');

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Editar Usuário'),
        content: Column(
          children: [
            SizedBox(height: 12),
            CupertinoTextField(controller: usernameController, placeholder: 'Nome de usuário', prefix: Padding(padding: EdgeInsets.only(left: 8), child: Icon(CupertinoIcons.person, size: 20))),
            SizedBox(height: 12),
            CupertinoTextField(controller: tokensController, placeholder: 'Tokens', keyboardType: TextInputType.number, prefix: Padding(padding: EdgeInsets.only(left: 8), child: Icon(CupertinoIcons.money_dollar_circle, size: 20))),
          ],
        ),
        actions: [
          CupertinoDialogAction(child: Text('Cancelar'), onPressed: () => Navigator.pop(context)),
          CupertinoDialogAction(
            isDefaultAction: true,
            onPressed: () async {
              await FirebaseFirestore.instance.collection('users').doc(userId).update({
                'username': usernameController.text,
                'tokens': int.tryParse(tokensController.text) ?? 0,
              });
              _logActivity('Edição', 'Admin editou dados de ${usernameController.text}', 'info');
              Navigator.pop(context);
            },
            child: Text('Salvar'),
          ),
        ],
      ),
    );
  }

  Future<void> _togglePro(String userId, bool isPro) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).update({'pro': !isPro});
    _logActivity(isPro ? 'PRO Removido' : 'PRO Ativado', 'Status PRO foi ${isPro ? 'removido' : 'ativado'}', 'star');
  }

  Future<void> _toggleAdmin(String userId, bool isAdmin) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).update({'admin': !isAdmin});
    _logActivity(isAdmin ? 'Admin Removido' : 'Admin Ativado', 'Privilégios de admin foram ${isAdmin ? 'removidos' : 'concedidos'}', 'info');
  }

  void _banUser(String userId, String username) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Confirmar Banimento'),
        content: Text('Tem certeza que deseja banir $username?'),
        actions: [
          CupertinoDialogAction(child: Text('Cancelar'), onPressed: () => Navigator.pop(context)),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              await FirebaseFirestore.instance.collection('users').doc(userId).update({'banned': true, 'isOnline': false});
              _logActivity('Banimento', '$username foi banido', 'info');
              Navigator.pop(context);
            },
            child: Text('Banir'),
          ),
        ],
      ),
    );
  }

  // --------------------------- POSTS TAB ---------------------------
  Widget _buildPostsTab(Color cardBg) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('posts').orderBy('timestamp', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return Center(child: CupertinoActivityIndicator());
        final posts = snapshot.data!.docs;
        if (posts.isEmpty) {
          return Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(CupertinoIcons.doc_text, size: 64, color: CupertinoColors.systemGrey),
              SizedBox(height: 12),
              Text('Nenhuma publicação encontrada', style: TextStyle(fontSize: 16, color: CupertinoColors.systemGrey)),
            ]),
          );
        }
        return CupertinoScrollbar(
          child: ListView.builder(
            padding: EdgeInsets.all(12),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index].data();
              final postId = posts[index].id;
              return _buildPostCard(post, postId);
            },
          ),
        );
      },
    );
  }

  Widget _buildPostCard(Map<String, dynamic> postData, String postId) {
    final image = postData['image'] ?? '';
    final userName = postData['userName'] ?? 'Usuário';
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: CupertinoColors.systemBackground, borderRadius: BorderRadius.circular(12)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (image != '')
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            child: Image.network(image, width: double.infinity, height: 200, fit: BoxFit.cover, errorBuilder: (c, e, st) {
              return Container(height: 200, color: CupertinoColors.systemGrey5, child: Icon(CupertinoIcons.photo, size: 50, color: CupertinoColors.systemGrey));
            }),
          ),
        Padding(
          padding: EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 36, height: 36, decoration: BoxDecoration(color: CupertinoColors.systemGrey5, shape: BoxShape.circle), child: Center(child: Text((userName[0] ?? 'U').toUpperCase(), style: TextStyle(fontSize: 14, color: CupertinoColors.white, fontWeight: FontWeight.bold)))),
              SizedBox(width: 10),
              Expanded(child: Text(userName, style: TextStyle(fontWeight: FontWeight.w600))),
              CupertinoButton(padding: EdgeInsets.zero, child: Icon(CupertinoIcons.trash, color: CupertinoColors.systemRed, size: 20), onPressed: () => _deletePost(postId)),
            ]),
            SizedBox(height: 12),
            Text(postData['content'] ?? '', maxLines: 3, overflow: TextOverflow.ellipsis),
            SizedBox(height: 12),
            Row(children: [
              Icon(CupertinoIcons.heart_fill, size: 16, color: CupertinoColors.systemRed),
              SizedBox(width: 6),
              Text('${postData['likes'] ?? 0}', style: TextStyle(color: CupertinoColors.systemGrey)),
              SizedBox(width: 16),
              Icon(CupertinoIcons.chat_bubble_fill, size: 16, color: CupertinoColors.systemBlue),
              SizedBox(width: 6),
              Text('${postData['comments'] ?? 0}', style: TextStyle(color: CupertinoColors.systemGrey)),
              SizedBox(width: 16),
              Icon(CupertinoIcons.time, size: 16, color: CupertinoColors.systemGrey),
              SizedBox(width: 6),
              Text(_formatTimestamp(postData['timestamp']), style: TextStyle(color: CupertinoColors.systemGrey, fontSize: 12)),
            ]),
          ]),
        )
      ]),
    );
  }

  Future<void> _deletePost(String postId) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (c) => CupertinoAlertDialog(
        title: Text('Confirmar Exclusão'),
        content: Text('Tem certeza que deseja excluir esta publicação?'),
        actions: [
          CupertinoDialogAction(child: Text('Cancelar'), onPressed: () => Navigator.pop(c, false)),
          CupertinoDialogAction(isDestructiveAction: true, child: Text('Excluir'), onPressed: () => Navigator.pop(c, true)),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseFirestore.instance.collection('posts').doc(postId).delete();
      _logActivity('Post Deletado', 'Admin deletou uma publicação', 'post');
    }
  }

  // --------------------------- ACTIVITIES TAB ---------------------------
  Widget _buildActivitiesTab(Color cardBg) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(14),
          color: CupertinoColors.systemBackground,
          child: Row(children: [
            Icon(CupertinoIcons.dot_radiowaves_left_right, color: CupertinoColors.systemGreen),
            SizedBox(width: 10),
            Text('Atividades em Tempo Real', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
          ]),
        ),
        Expanded(
          child: _realtimeActivities.isEmpty
              ? Center(
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(CupertinoIcons.clock, size: 64, color: CupertinoColors.systemGrey),
                    SizedBox(height: 12),
                    Text('Nenhuma atividade recente', style: TextStyle(fontSize: 16, color: CupertinoColors.systemGrey)),
                  ]),
                )
              : CupertinoScrollbar(
                  child: ListView.builder(
                    padding: EdgeInsets.all(12),
                    itemCount: _realtimeActivities.length,
                    itemBuilder: (context, index) {
                      final activity = _realtimeActivities[index];
                      return Container(
                        margin: EdgeInsets.only(bottom: 10),
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(color: CupertinoColors.systemBackground, borderRadius: BorderRadius.circular(12)),
                        child: Row(children: [
                          _getActivityIcon(activity['icon'] ?? 'info'),
                          SizedBox(width: 12),
                          Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(activity['type'] ?? 'Atividade', style: TextStyle(fontWeight: FontWeight.w600)),
                            SizedBox(height: 6),
                            Text(activity['description'] ?? '', style: TextStyle(color: CupertinoColors.systemGrey, fontSize: 13)),
                          ])),
                          SizedBox(width: 10),
                          Text(_formatTimestamp(activity['timestamp']), style: TextStyle(fontSize: 11, color: CupertinoColors.systemGrey2)),
                        ]),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  // --------------------------- ANALYTICS TAB ---------------------------
  Widget _buildAnalyticsTab(Color cardBg) {
    return CupertinoScrollbar(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text('Analytics Avançado', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                SizedBox(height: 16),
                CupertinoSegmentedControl<String>(
                  groupValue: _selectedPeriod,
                  onValueChanged: (value) {
                    setState(() {
                      _selectedPeriod = value;
                    });
                    _updateChartsFromFirestore();
                  },
                  children: {
                    '7d': Text('7 Dias', style: TextStyle(fontSize: 12)),
                    '30d': Text('30 Dias', style: TextStyle(fontSize: 12)),
                    '90d': Text('90 Dias', style: TextStyle(fontSize: 12)),
                  },
                ),
                SizedBox(height: 24),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(color: CupertinoColors.systemBackground, borderRadius: BorderRadius.circular(12)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Taxa de Conversão PRO', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    SizedBox(height: 12),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('Conversão', style: TextStyle(color: CupertinoColors.systemGrey)),
                      Text('${_calculateConversionRate()}%', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: CupertinoColors.systemBlue)),
                    ]),
                    SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _calculateConversionRate() / 100,
                        backgroundColor: CupertinoColors.systemGrey5,
                        color: CupertinoColors.systemBlue,
                        minHeight: 8,
                      ),
                    ),
                  ]),
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(color: CupertinoColors.systemBackground, borderRadius: BorderRadius.circular(12)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Engajamento', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    SizedBox(height: 16),
                    _buildEngagementRow('Likes Totais', _stats['totalLikes'] ?? 0, CupertinoIcons.heart_fill, CupertinoColors.systemRed),
                    SizedBox(height: 12),
                    _buildEngagementRow('Comentários', _stats['totalComments'] ?? 0, CupertinoIcons.chat_bubble_fill, CupertinoColors.systemBlue),
                    SizedBox(height: 12),
                    _buildEngagementRow('Mensagens', _stats['totalMessages'] ?? 0, CupertinoIcons.mail_solid, CupertinoColors.systemOrange),
                  ]),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementRow(String label, int value, IconData icon, Color color) {
    return Row(children: [
      Container(width: 42, height: 42, decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: color, size: 20)),
      SizedBox(width: 12),
      Expanded(child: Text(label, style: TextStyle(fontSize: 15))),
      Text(value.toString(), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    ]);
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Agora';
    try {
      DateTime date;
      if (timestamp is Timestamp) date = timestamp.toDate();
      else if (timestamp is DateTime) date = timestamp;
      else if (timestamp is int) date = DateTime.fromMillisecondsSinceEpoch(timestamp);
      else return 'Agora';

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