import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';
import 'dart:math';

class AdminPanelScreen extends StatefulWidget {
  @override
  _AdminPanelScreenState createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = '7d';
  String _searchQuery = '';
  String _userFilter = 'all';
  List<Map<String, dynamic>> _realtimeActivities = [];
  StreamSubscription? _activitySubscription;
  StreamSubscription? _usersSubscription;
  StreamSubscription? _postsSubscription;
  StreamSubscription? _messagesSubscription;
  
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
    _setupRealtimeListeners();
    _loadStatistics();
    _generateChartData();
  }

  void _setupRealtimeListeners() {
    // Monitor de atividades em tempo real
    _activitySubscription = FirebaseFirestore.instance
        .collection('activities')
        .orderBy('timestamp', descending: true)
        .limit(50)
        .snapshots()
        .listen((snapshot) {
      setState(() {
        _realtimeActivities = snapshot.docs.map((doc) {
          return {
            'id': doc.id,
            ...doc.data(),
          };
        }).toList();
      });
      
      // Mostrar notificação para cada nova atividade
      if (snapshot.docChanges.isNotEmpty) {
        for (var change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added) {
            final data = change.doc.data() as Map<String, dynamic>;
            _showActivityNotification(data);
          }
        }
      }
    });

    // Monitor de usuários em tempo real
    _usersSubscription = FirebaseFirestore.instance
        .collection('users')
        .snapshots()
        .listen((snapshot) {
      _loadStatistics();
      
      for (var change in snapshot.docChanges) {
        final userData = change.doc.data() as Map<String, dynamic>?;
        if (userData != null) {
          if (change.type == DocumentChangeType.added) {
            _logActivity('Novo usuário', '${userData['username'] ?? 'Usuário'} se cadastrou', 'user_add');
          } else if (change.type == DocumentChangeType.modified) {
            if (userData['isOnline'] == true) {
              _logActivity('Login', '${userData['username'] ?? 'Usuário'} entrou online', 'login');
            }
          }
        }
      }
    });

    // Monitor de posts em tempo real
    _postsSubscription = FirebaseFirestore.instance
        .collection('posts')
        .snapshots()
        .listen((snapshot) {
      _loadStatistics();
      
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final postData = change.doc.data() as Map<String, dynamic>?;
          if (postData != null) {
            _logActivity('Novo Post', '${postData['userName'] ?? 'Usuário'} criou um post', 'post');
          }
        }
      }
    });

    // Monitor de mensagens em tempo real
    _messagesSubscription = FirebaseFirestore.instance
        .collection('messages')
        .snapshots()
        .listen((snapshot) {
      setState(() {
        _stats['totalMessages'] = snapshot.docs.length;
      });
    });
  }

  void _logActivity(String type, String description, String icon) async {
    await FirebaseFirestore.instance.collection('activities').add({
      'type': type,
      'description': description,
      'icon': icon,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  void _showActivityNotification(Map<String, dynamic> activity) {
    if (!mounted) return;
    
    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => CupertinoAlertDialog(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _getActivityIcon(activity['icon'] ?? 'info'),
            SizedBox(width: 8),
            Text(activity['type'] ?? 'Atividade'),
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

    Future.delayed(Duration(seconds: 3), () {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
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

  void _generateChartData() {
    // Dados simulados para crescimento (em produção viriam do Firebase)
    _userGrowthData = List.generate(7, (i) {
      return FlSpot(i.toDouble(), (Random().nextInt(20) + 10).toDouble());
    });

    _activityData = List.generate(7, (i) {
      return FlSpot(i.toDouble(), (Random().nextInt(30) + 15).toDouble());
    });
  }

  Future<void> _loadStatistics() async {
    try {
      final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
      final postsSnapshot = await FirebaseFirestore.instance.collection('posts').get();
      final messagesSnapshot = await FirebaseFirestore.instance.collection('messages').get();
      
      int totalUsers = usersSnapshot.docs.length;
      int activeUsers = usersSnapshot.docs.where((doc) => doc.data()['isOnline'] == true).length;
      int proUsers = usersSnapshot.docs.where((doc) => doc.data()['pro'] == true).length;
      int bannedUsers = usersSnapshot.docs.where((doc) => doc.data()['banned'] == true).length;
      int totalPosts = postsSnapshot.docs.length;
      int totalMessages = messagesSnapshot.docs.length;
      int totalTokens = usersSnapshot.docs.fold(0, (sum, doc) => sum + (doc.data()['tokens'] ?? 0) as int);
      
      int totalLikes = postsSnapshot.docs.fold(0, (sum, doc) => sum + (doc.data()['likes'] ?? 0) as int);
      int totalComments = postsSnapshot.docs.fold(0, (sum, doc) => sum + (doc.data()['comments'] ?? 0) as int);
      
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      int newUsersToday = usersSnapshot.docs.where((doc) {
        final createdAt = (doc.data()['created_at'] as Timestamp?)?.toDate();
        return createdAt != null && createdAt.isAfter(startOfDay);
      }).length;

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
    } catch (e) {
      print('Erro ao carregar estatísticas: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.systemBackground.withOpacity(0.9),
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
          onPressed: _loadStatistics,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            CupertinoSegmentedControl<int>(
              padding: EdgeInsets.all(16),
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
                0: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text('Dashboard', style: TextStyle(fontSize: 12)),
                ),
                1: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text('Usuários', style: TextStyle(fontSize: 12)),
                ),
                2: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text('Posts', style: TextStyle(fontSize: 12)),
                ),
                3: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text('Atividades', style: TextStyle(fontSize: 12)),
                ),
                4: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text('Analytics', style: TextStyle(fontSize: 12)),
                ),
              },
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildDashboardTab(),
                  _buildUsersTab(),
                  _buildPostsTab(),
                  _buildActivitiesTab(),
                  _buildAnalyticsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardTab() {
    return CupertinoScrollbar(
      child: CustomScrollView(
        slivers: [
          CupertinoSliverRefreshControl(
            onRefresh: _loadStatistics,
          ),
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
                _buildStatsGrid(),
                SizedBox(height: 24),
                _buildOnlineUsersSection(),
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

  Widget _buildStatsGrid() {
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
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
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
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemGreen.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemGreen,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'LIVE',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: CupertinoColors.systemGreen,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: CupertinoColors.label,
                ),
              ),
              SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  color: CupertinoColors.systemGrey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOnlineUsersSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('isOnline', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SizedBox.shrink();
        }

        final onlineUsers = snapshot.data!.docs;

        if (onlineUsers.isEmpty) {
          return SizedBox.shrink();
        }

        return Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CupertinoColors.systemBackground,
            borderRadius: BorderRadius.circular(16),
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
                height: 60,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: onlineUsers.length,
                  itemBuilder: (context, index) {
                    final userData = onlineUsers[index].data() as Map<String, dynamic>;
                    return Padding(
                      padding: EdgeInsets.only(right: 12),
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  image: userData['profile_image'] != null
                                      ? DecorationImage(
                                          image: NetworkImage(userData['profile_image']),
                                          fit: BoxFit.cover,
                                        )
                                      : null,
                                  color: CupertinoColors.systemGrey5,
                                ),
                                child: userData['profile_image'] == null
                                    ? Center(
                                        child: Text(
                                          (userData['username'] ?? 'U')[0].toUpperCase(),
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
                                  width: 12,
                                  height: 12,
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

  Widget _buildChartCard({
    required String title,
    required List<FlSpot> data,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: CupertinoColors.label,
            ),
          ),
          SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 10,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: CupertinoColors.systemGrey5,
                      strokeWidth: 0.5,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 35,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            color: CupertinoColors.systemGrey,
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final days = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
                        if (value.toInt() >= 0 && value.toInt() < days.length) {
                          return Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text(
                              days[value.toInt()],
                              style: TextStyle(
                                color: CupertinoColors.systemGrey,
                                fontSize: 10,
                              ),
                            ),
                          );
                        }
                        return Text('');
                      },
                    ),
                  ),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: data,
                    isCurved: true,
                    color: color,
                    barWidth: 2,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 3,
                          color: color,
                          strokeWidth: 1.5,
                          strokeColor: CupertinoColors.systemBackground,
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          color.withOpacity(0.3),
                          color.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
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

  Widget _buildUsersTab() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(16),
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
              SizedBox(height: 12),
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
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(child: CupertinoActivityIndicator());
              }

              var users = snapshot.data!.docs.where((doc) {
                final userData = doc.data() as Map<String, dynamic>;
                final username = (userData['username'] ?? '').toString().toLowerCase();
                final email = (userData['email'] ?? '').toString().toLowerCase();
                
                bool matchesSearch = _searchQuery.isEmpty ||
                    username.contains(_searchQuery) ||
                    email.contains(_searchQuery);

                bool matchesFilter = true;
                if (_userFilter == 'online') {
                  matchesFilter = userData['isOnline'] == true;
                } else if (_userFilter == 'pro') {
                  matchesFilter = userData['pro'] == true;
                } else if (_userFilter == 'banned') {
                  matchesFilter = userData['banned'] == true;
                }

                return matchesSearch && matchesFilter;
              }).toList();

              if (users.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.person_2,
                        size: 64,
                        color: CupertinoColors.systemGrey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Nenhum usuário encontrado',
                        style: TextStyle(
                          fontSize: 16,
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return CupertinoScrollbar(
                child: ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final userData = users[index].data() as Map<String, dynamic>;
                    final userId = users[index].id;
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
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: CupertinoListTile(
        padding: EdgeInsets.all(12),
        leading: Stack(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: userData['profile_image'] != null && userData['profile_image'].isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(userData['profile_image']),
                        fit: BoxFit.cover,
                      )
                    : null,
                color: CupertinoColors.systemGrey5,
              ),
              child: userData['profile_image'] == null || userData['profile_image'].isEmpty
                  ? Center(
                      child: Text(
                        (userData['username'] ?? 'U')[0].toUpperCase(),
                        style: TextStyle(
                          fontSize: 20,
                          color: CupertinoColors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
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
                    border: Border.all(
                      color: CupertinoColors.systemBackground,
                      width: 2,
                    ),
                  ),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Text(
              userData['username'] ?? 'Usuário',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: CupertinoColors.label,
              ),
            ),
            SizedBox(width: 8),
            if (userData['pro'] == true)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemYellow,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'PRO',
                  style: TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (userData['admin'] == true)
              Container(
                margin: EdgeInsets.only(left: 4),
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: CupertinoColors.systemRed,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'ADMIN',
                  style: TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text(
              userData['email'] ?? '',
              style: TextStyle(
                color: CupertinoColors.systemGrey,
                fontSize: 13,
              ),
            ),
            SizedBox(height: 4),
            Text(
              '${userData['tokens'] ?? 0} tokens',
              style: TextStyle(
                color: CupertinoColors.systemGrey2,
                fontSize: 12,
              ),
            ),
          ],
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(CupertinoIcons.ellipsis_circle, color: CupertinoColors.systemGrey),
          onPressed: () => _showUserOptions(userId, userData),
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
            SizedBox(height: 16),
            CupertinoTextField(
              controller: usernameController,
              placeholder: 'Nome de usuário',
              prefix: Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(CupertinoIcons.person, size: 20),
              ),
            ),
            SizedBox(height: 12),
            CupertinoTextField(
              controller: tokensController,
              placeholder: 'Tokens',
              keyboardType: TextInputType.number,
              prefix: Padding(
                padding: EdgeInsets.only(left: 8),
                child: Icon(CupertinoIcons.money_dollar_circle, size: 20),
              ),
            ),
          ],
        ),
        actions: [
          CupertinoDialogAction(
            child: Text('Cancelar'),
            onPressed: () => Navigator.pop(context),
          ),
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

  void _togglePro(String userId, bool isPro) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'pro': !isPro,
    });
    _logActivity(
      isPro ? 'PRO Removido' : 'PRO Ativado',
      'Status PRO foi ${isPro ? 'removido' : 'ativado'}',
      'star',
    );
  }

  void _toggleAdmin(String userId, bool isAdmin) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).update({
      'admin': !isAdmin,
    });
    _logActivity(
      isAdmin ? 'Admin Removido' : 'Admin Ativado',
      'Privilégios de admin foram ${isAdmin ? 'removidos' : 'concedidos'}',
      'info',
    );
  }

  void _banUser(String userId, String username) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Confirmar Banimento'),
        content: Text('Tem certeza que deseja banir $username?'),
        actions: [
          CupertinoDialogAction(
            child: Text('Cancelar'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              await FirebaseFirestore.instance.collection('users').doc(userId).update({
                'banned': true,
                'isOnline': false,
              });
              _logActivity('Banimento', '$username foi banido', 'info');
              Navigator.pop(context);
            },
            child: Text('Banir'),
          ),
        ],
      ),
    );
  }

  Widget _buildPostsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CupertinoActivityIndicator());
        }

        final posts = snapshot.data!.docs;

        if (posts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.doc_text,
                  size: 64,
                  color: CupertinoColors.systemGrey,
                ),
                SizedBox(height: 16),
                Text(
                  'Nenhuma publicação encontrada',
                  style: TextStyle(
                    fontSize: 16,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
              ],
            ),
          );
        }

        return CupertinoScrollbar(
          child: ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final postData = posts[index].data() as Map<String, dynamic>;
              final postId = posts[index].id;
              return _buildPostCard(postData, postId);
            },
          ),
        );
      },
    );
  }

  Widget _buildPostCard(Map<String, dynamic> postData, String postId) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (postData['image'] != null && postData['image'].isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                postData['image'],
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => Container(
                  height: 200,
                  color: CupertinoColors.systemGrey5,
                  child: Icon(
                    CupertinoIcons.photo,
                    size: 50,
                    color: CupertinoColors.systemGrey,
                  ),
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
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemGrey5,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          (postData['userName'] ?? 'U')[0].toUpperCase(),
                          style: TextStyle(
                            fontSize: 14,
                            color: CupertinoColors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        postData['userName'] ?? 'Usuário',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: CupertinoColors.label,
                        ),
                      ),
                    ),
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: Icon(
                        CupertinoIcons.trash,
                        color: CupertinoColors.systemRed,
                        size: 20,
                      ),
                      onPressed: () => _deletePost(postId),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Text(
                  postData['content'] ?? '',
                  style: TextStyle(
                    fontSize: 15,
                    color: CupertinoColors.label,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Icon(CupertinoIcons.heart_fill, size: 16, color: CupertinoColors.systemRed),
                    SizedBox(width: 4),
                    Text('${postData['likes'] ?? 0}', style: TextStyle(color: CupertinoColors.systemGrey)),
                    SizedBox(width: 16),
                    Icon(CupertinoIcons.chat_bubble_fill, size: 16, color: CupertinoColors.systemBlue),
                    SizedBox(width: 4),
                    Text('${postData['comments'] ?? 0}', style: TextStyle(color: CupertinoColors.systemGrey)),
                    SizedBox(width: 16),
                    Icon(CupertinoIcons.time, size: 16, color: CupertinoColors.systemGrey),
                    SizedBox(width: 4),
                    Text(
                      _formatTimestamp(postData['timestamp']),
                      style: TextStyle(color: CupertinoColors.systemGrey, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _deletePost(String postId) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Confirmar Exclusão'),
        content: Text('Tem certeza que deseja excluir esta publicação?'),
        actions: [
          CupertinoDialogAction(
            child: Text('Cancelar'),
            onPressed: () => Navigator.pop(context),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () async {
              await FirebaseFirestore.instance.collection('posts').doc(postId).delete();
              _logActivity('Post Deletado', 'Admin deletou uma publicação', 'post');
              Navigator.pop(context);
            },
            child: Text('Excluir'),
          ),
        ],
      ),
    );
  }

  Widget _buildActivitiesTab() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(16),
          color: CupertinoColors.systemBackground,
          child: Row(
            children: [
              Icon(CupertinoIcons.dot_radiowaves_left_right, color: CupertinoColors.systemGreen),
              SizedBox(width: 8),
              Text(
                'Atividades em Tempo Real',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: CupertinoColors.label,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _realtimeActivities.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.clock,
                        size: 64,
                        color: CupertinoColors.systemGrey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Nenhuma atividade recente',
                        style: TextStyle(
                          fontSize: 16,
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                    ],
                  ),
                )
              : CupertinoScrollbar(
                  child: ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: _realtimeActivities.length,
                    itemBuilder: (context, index) {
                      final activity = _realtimeActivities[index];
                      return Container(
                        margin: EdgeInsets.only(bottom: 12),
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: CupertinoColors.systemBackground,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            _getActivityIcon(activity['icon'] ?? 'info'),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    activity['type'] ?? 'Atividade',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: CupertinoColors.label,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    activity['description'] ?? '',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: CupertinoColors.systemGrey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              _formatTimestamp(activity['timestamp']),
                              style: TextStyle(
                                fontSize: 11,
                                color: CupertinoColors.systemGrey2,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsTab() {
    return CupertinoScrollbar(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Text(
                  'Analytics Avançado',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: CupertinoColors.label,
                  ),
                ),
                SizedBox(height: 16),
                CupertinoSegmentedControl<String>(
                  groupValue: _selectedPeriod,
                  onValueChanged: (value) {
                    setState(() {
                      _selectedPeriod = value;
                    });
                  },
                  children: {
                    '7d': Text('7 Dias', style: TextStyle(fontSize: 12)),
                    '30d': Text('30 Dias', style: TextStyle(fontSize: 12)),
                    '90d': Text('90 Dias', style: TextStyle(fontSize: 12)),
                  },
                ),
                SizedBox(height: 24),
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemBackground,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Taxa de Conversão PRO',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: CupertinoColors.label,
                        ),
                      ),
                      SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Conversão',
                            style: TextStyle(
                              fontSize: 14,
                              color: CupertinoColors.systemGrey,
                            ),
                          ),
                          Text(
                            '${_calculateConversionRate()}%',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: CupertinoColors.systemBlue,
                            ),
                          ),
                        ],
                      ),
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
                    ],
                  ),
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: CupertinoColors.systemBackground,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Engajamento',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: CupertinoColors.label,
                        ),
                      ),
                      SizedBox(height: 20),
                      _buildEngagementRow('Likes Totais', _stats['totalLikes'], CupertinoIcons.heart_fill, CupertinoColors.systemRed),
                      SizedBox(height: 12),
                      _buildEngagementRow('Comentários', _stats['totalComments'], CupertinoIcons.chat_bubble_fill, CupertinoColors.systemBlue),
                      SizedBox(height: 12),
                      _buildEngagementRow('Mensagens', _stats['totalMessages'], CupertinoIcons.mail_solid, CupertinoColors.systemOrange),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementRow(String label, int value, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              color: CupertinoColors.label,
            ),
          ),
        ),
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: CupertinoColors.label,
          ),
        ),
      ],
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Agora';
    try {
      final date = (timestamp as Timestamp).toDate();
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays > 0) return '${difference.inDays}d';
      if (difference.inHours > 0) return '${difference.inHours}h';
      if (difference.inMinutes > 0) return '${difference.inMinutes}min';
      return 'Agora';
    } catch (e) {
      return 'Agora';
    }
  }

  double _calculateConversionRate() {
    if (_stats['totalUsers'] == 0) return 0;
    return ((_stats['proUsers'] as int) / (_stats['totalUsers'] as int) * 100).roundToDouble();
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