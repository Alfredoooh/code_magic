import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';

class AdminPanelScreen extends StatefulWidget {
  @override
  _AdminPanelScreenState createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedPeriod = '7d';
  Map<String, dynamic> _stats = {
    'totalUsers': 0,
    'activeUsers': 0,
    'proUsers': 0,
    'totalPosts': 0,
    'totalTokens': 0,
    'newUsersToday': 0,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    try {
      final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
      final postsSnapshot = await FirebaseFirestore.instance.collection('posts').get();
      
      int totalUsers = usersSnapshot.docs.length;
      int activeUsers = usersSnapshot.docs.where((doc) => doc.data()['isOnline'] == true).length;
      int proUsers = usersSnapshot.docs.where((doc) => doc.data()['pro'] == true).length;
      int totalPosts = postsSnapshot.docs.length;
      int totalTokens = usersSnapshot.docs.fold(0, (sum, doc) => sum + (doc.data()['tokens'] ?? 0) as int);
      
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
        };
      });
    } catch (e) {
      print('Erro ao carregar estatísticas: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Color(0xFF0E0E0E) : Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: isDark ? Color(0xFF1A1A1A) : Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: isDark ? Colors.white : Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Painel Administrativo',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: isDark ? Colors.white : Colors.black87),
            onPressed: _loadStatistics,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Color(0xFFFF444F),
          labelColor: Color(0xFFFF444F),
          unselectedLabelColor: Colors.grey,
          labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            Tab(text: 'Dashboard'),
            Tab(text: 'Usuários'),
            Tab(text: 'Posts'),
            Tab(text: 'Analytics'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDashboardTab(isDark),
          _buildUsersTab(isDark),
          _buildPostsTab(isDark),
          _buildAnalyticsTab(isDark),
        ],
      ),
    );
  }

  Widget _buildDashboardTab(bool isDark) {
    return RefreshIndicator(
      color: Color(0xFFFF444F),
      onRefresh: _loadStatistics,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Visão Geral',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _buildStatCard(
                  icon: Icons.people_rounded,
                  title: 'Total Usuários',
                  value: '${_stats['totalUsers']}',
                  color: Colors.blue,
                  isDark: isDark,
                ),
                _buildStatCard(
                  icon: Icons.online_prediction_rounded,
                  title: 'Usuários Ativos',
                  value: '${_stats['activeUsers']}',
                  color: Colors.green,
                  isDark: isDark,
                ),
                _buildStatCard(
                  icon: Icons.star_rounded,
                  title: 'Contas PRO',
                  value: '${_stats['proUsers']}',
                  color: Colors.amber,
                  isDark: isDark,
                ),
                _buildStatCard(
                  icon: Icons.article_rounded,
                  title: 'Total Posts',
                  value: '${_stats['totalPosts']}',
                  color: Colors.purple,
                  isDark: isDark,
                ),
                _buildStatCard(
                  icon: Icons.toll_rounded,
                  title: 'Total Tokens',
                  value: '${_stats['totalTokens']}',
                  color: Colors.orange,
                  isDark: isDark,
                ),
                _buildStatCard(
                  icon: Icons.person_add_rounded,
                  title: 'Novos Hoje',
                  value: '${_stats['newUsersToday']}',
                  color: Colors.cyan,
                  isDark: isDark,
                ),
              ],
            ),
            SizedBox(height: 24),
            Text(
              'Distribuição de Usuários',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            SizedBox(height: 16),
            Container(
              height: 280,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? Color(0xFF1A1A1A) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 60,
                  sections: [
                    PieChartSectionData(
                      value: (_stats['proUsers'] as int).toDouble(),
                      title: 'PRO',
                      color: Colors.amber,
                      radius: 80,
                      titleStyle: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    PieChartSectionData(
                      value: (_stats['activeUsers'] as int).toDouble(),
                      title: 'Ativos',
                      color: Colors.green,
                      radius: 80,
                      titleStyle: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    PieChartSectionData(
                      value: ((_stats['totalUsers'] as int) - (_stats['activeUsers'] as int)).toDouble(),
                      title: 'Inativos',
                      color: Colors.grey,
                      radius: 80,
                      titleStyle: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Crescimento de Usuários',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            SizedBox(height: 16),
            Container(
              height: 280,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? Color(0xFF1A1A1A) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true, drawVerticalLine: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: TextStyle(color: Colors.grey, fontSize: 12),
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
                            return Text(
                              days[value.toInt()],
                              style: TextStyle(color: Colors.grey, fontSize: 12),
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
                      spots: [
                        FlSpot(0, 3),
                        FlSpot(1, 5),
                        FlSpot(2, 4),
                        FlSpot(3, 8),
                        FlSpot(4, 6),
                        FlSpot(5, 10),
                        FlSpot(6, 12),
                      ],
                      isCurved: true,
                      color: Color(0xFFFF444F),
                      barWidth: 4,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Color(0xFFFF444F).withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersTab(bool isDark) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(16),
          color: isDark ? Color(0xFF1A1A1A) : Colors.white,
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    hintText: 'Buscar usuários...',
                    hintStyle: TextStyle(color: Colors.grey),
                    prefixIcon: Icon(Icons.search_rounded, color: Color(0xFFFF444F)),
                    filled: true,
                    fillColor: isDark ? Color(0xFF0E0E0E) : Color(0xFFF5F5F5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: Color(0xFFFF444F),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(Icons.filter_list_rounded, color: Colors.white),
                  onPressed: () => _showFilterDialog(isDark),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('users').snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(child: CircularProgressIndicator(color: Color(0xFFFF444F)));
              }

              final users = snapshot.data!.docs;

              if (users.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline_rounded, size: 80, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Nenhum usuário encontrado',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final userData = users[index].data() as Map<String, dynamic>;
                  final userId = users[index].id;
                  return _buildUserCard(userData, userId, isDark);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPostsTab(bool isDark) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('posts').orderBy('timestamp', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator(color: Color(0xFFFF444F)));
        }

        final posts = snapshot.data!.docs;

        if (posts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.article_outlined, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Nenhuma publicação encontrada',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final postData = posts[index].data() as Map<String, dynamic>;
            final postId = posts[index].id;
            return _buildPostCard(postData, postId, isDark);
          },
        );
      },
    );
  }

  Widget _buildAnalyticsTab(bool isDark) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildPeriodChip('7d', '7 Dias', isDark),
              SizedBox(width: 8),
              _buildPeriodChip('30d', '30 Dias', isDark),
              SizedBox(width: 8),
              _buildPeriodChip('90d', '90 Dias', isDark),
            ],
          ),
          SizedBox(height: 24),
          Text(
            'Atividade por Categoria',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          SizedBox(height: 16),
          Container(
            height: 300,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? Color(0xFF1A1A1A) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 100,
                barTouchData: BarTouchData(enabled: true),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final categories = ['Posts', 'Usuários', 'Tokens', 'PRO'];
                        if (value.toInt() >= 0 && value.toInt() < categories.length) {
                          return Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text(
                              categories[value.toInt()],
                              style: TextStyle(color: Colors.grey, fontSize: 12),
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
                gridData: FlGridData(show: true, drawVerticalLine: false),
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: (_stats['totalPosts'] as int).toDouble(),
                        color: Colors.purple,
                        width: 20,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: (_stats['totalUsers'] as int).toDouble(),
                        color: Colors.blue,
                        width: 20,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 2,
                    barRods: [
                      BarChartRodData(
                        toY: min((_stats['totalTokens'] as int).toDouble(), 100),
                        color: Colors.orange,
                        width: 20,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 3,
                    barRods: [
                      BarChartRodData(
                        toY: (_stats['proUsers'] as int).toDouble(),
                        color: Colors.amber,
                        width: 20,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Taxa de Conversão PRO',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? Color(0xFF1A1A1A) : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Conversão',
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    Text(
                      '${_calculateConversionRate()}%',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF444F),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                LinearProgressIndicator(
                  value: _calculateConversionRate() / 100,
                  backgroundColor: Colors.grey.withOpacity(0.2),
                  color: Color(0xFFFF444F),
                  minHeight: 12,
                  borderRadius: BorderRadius.circular(6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 32),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> userData, String userId, bool isDark) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(12),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Color(0xFFFF444F),
              backgroundImage: userData['profile_image'] != null && userData['profile_image'].isNotEmpty
                  ? NetworkImage(userData['profile_image'])
                  : null,
              child: userData['profile_image'] == null || userData['profile_image'].isEmpty
                  ? Text(
                      (userData['username'] ?? 'U')[0].toUpperCase(),
                      style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
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
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: isDark ? Color(0xFF1A1A1A) : Colors.white, width: 2),
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
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            SizedBox(width: 8),
            if (userData['pro'] == true)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'PRO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (userData['admin'] == true)
              Container(
                margin: EdgeInsets.only(left: 4),
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Color(0xFFFF444F),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'ADMIN',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
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
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.toll_rounded, size: 14, color: Colors.orange),
                SizedBox(width: 4),
                Text(
                  '${userData['tokens'] ?? 0} tokens',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton(
          icon: Icon(Icons.more_vert_rounded, color: isDark ? Colors.white : Colors.black87),
          itemBuilder: (context) => [
            PopupMenuItem(
              child: Row(
                children: [
                  Icon(Icons.edit_rounded, size: 20, color: Colors.blue),
                  SizedBox(width: 8),
                  Text('Editar'),
                ],
              ),
              onTap: () => _editUser(userId, userData, isDark),
            ),
            PopupMenuItem(
              child: Row(
                children: [
                  Icon(Icons.star_rounded, size: 20, color: Colors.amber),
                  SizedBox(width: 8),
                  Text(userData['pro'] == true ? 'Remover PRO' : 'Tornar PRO'),
                ],
              ),
              onTap: () => _togglePro(userId, userData['pro'] == true),
            ),
            PopupMenuItem(
              child: Row(
                children: [
                  Icon(Icons.block_rounded, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Banir'),
                ],
              ),
              onTap: () => _banUser(userId),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> postData, String postId, bool isDark) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (postData['image'] != null && postData['image'].isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              child: Image.network(
                postData['image'],
                width: double.infinity,
                height: 180,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stack) => Container(
                  height: 180,
                  color: Colors.grey[300],
                  child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
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
                      radius: 16,
                      backgroundColor: Color(0xFFFF444F),
                      child: Text(
                        (postData['userName'] ?? 'U')[0].toUpperCase(),
                        style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      postData['userName'] ?? 'Usuário',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Spacer(),
                    IconButton(
                      icon: Icon(Icons.delete_rounded, color: Colors.red, size: 20),
                      onPressed: () => _deletePost(postId),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Text(
                  postData['content'] ?? '',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.favorite_rounded, size: 16, color: Colors.red),
                    SizedBox(width: 4),
                    Text('${postData['likes'] ?? 0}', style: TextStyle(color: Colors.grey)),
                    SizedBox(width: 16),
                    Icon(Icons.comment_rounded, size: 16, color: Colors.blue),
                    SizedBox(width: 4),
                    Text('${postData['comments'] ?? 0}', style: TextStyle(color: Colors.grey)),
                    SizedBox(width: 16),
                    Icon(Icons.access_time_rounded, size: 16, color: Colors.grey),
                    SizedBox(width: 4),
                    Text(
                      _formatTimestamp(postData['timestamp']),
                      style: TextStyle(color: Colors.grey, fontSize: 12),
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

  Widget _buildPeriodChip(String period, String label, bool isDark) {
    final isSelected = _selectedPeriod == period;
    return GestureDetector(
      onTap: () => setState(() => _selectedPeriod = period),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFFFF444F) : (isDark ? Color(0xFF1A1A1A) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Color(0xFFFF444F) : Colors.grey.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black87),
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  void _showFilterDialog(bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? Color(0xFF1A1A1A) : Colors.white,
        title: Text(
          'Filtrar Usuários',
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('Todos', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              title: Text('Apenas PRO', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              title: Text('Ativos', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              title: Text('Inativos', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _editUser(String userId, Map<String, dynamic> userData, bool isDark) {
    Future.delayed(Duration(milliseconds: 100), () {
      final tokensController = TextEditingController(text: '${userData['tokens'] ?? 0}');
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: isDark ? Color(0xFF1A1A1A) : Colors.white,
          title: Text(
            'Editar Usuário',
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: tokensController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  labelText: 'Tokens',
                  labelStyle: TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Color(0xFFFF444F)),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance.collection('users').doc(userId).update({
                  'tokens': int.tryParse(tokensController.text) ?? 0,
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Usuário atualizado com sucesso!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFFF444F)),
              child: Text('Salvar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    });
  }

  void _togglePro(String userId, bool isPro) {
    Future.delayed(Duration(milliseconds: 100), () async {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'pro': !isPro,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isPro ? 'PRO removido!' : 'Usuário promovido a PRO!'),
          backgroundColor: Colors.green,
        ),
      );
    });
  }

  void _banUser(String userId) {
    Future.delayed(Duration(milliseconds: 100), () {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Confirmar Banimento'),
          content: Text('Tem certeza que deseja banir este usuário?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance.collection('users').doc(userId).update({
                  'banned': true,
                  'isOnline': false,
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Usuário banido com sucesso!'),
                    backgroundColor: Colors.red,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Banir', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    });
  }

  void _deletePost(String postId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmar Exclusão'),
        content: Text('Tem certeza que deseja excluir esta publicação?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('posts').doc(postId).delete();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Publicação excluída com sucesso!'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Excluir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Agora';
    try {
      final date = (timestamp as Timestamp).toDate();
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays > 0) return '${difference.inDays}d atrás';
      if (difference.inHours > 0) return '${difference.inHours}h atrás';
      if (difference.inMinutes > 0) return '${difference.inMinutes}min atrás';
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
    super.dispose();
  }
}