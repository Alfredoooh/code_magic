import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'admin_panel_utils.dart';

class AdminPanelWidgets {
  static Widget buildDashboardTab(
    BuildContext context,
    ThemeData theme,
    Map<String, dynamic> stats,
    List<FlSpot> userGrowthData,
    List<FlSpot> activityData,
    Future<void> Function() loadStatistics,
    Future<void> Function() updateChartsFromFirestore,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        await loadStatistics();
        await updateChartsFromFirestore();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Visão Geral em Tempo Real', 
            style: theme.textTheme.titleLarge?.copyWith(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _buildStatsGrid(theme, stats, userGrowthData, activityData),
          const SizedBox(height: 24),
          _buildOnlineUsersSection(context, theme.primaryColor, theme),
          const SizedBox(height: 24),
          _buildChartCard(
            title: 'Crescimento de Usuários', 
            data: userGrowthData, 
            color: theme.primaryColor, 
            theme: theme
          ),
          const SizedBox(height: 16),
          _buildChartCard(
            title: 'Atividade da Plataforma', 
            data: activityData, 
            color: Colors.purple, 
            theme: theme
          ),
        ],
      ),
    );
  }

  static Widget _buildStatsGrid(
    ThemeData theme, 
    Map<String, dynamic> stats, 
    List<FlSpot> userGrowthData, 
    List<FlSpot> activityData
  ) {
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
          value: '${stats['totalUsers']}',
          color: primaryColor,
          trendData: userGrowthData,
          theme: theme,
        ),
        _buildStatCard(
          icon: Icons.circle,
          title: 'Online Agora',
          value: '${stats['activeUsers']}',
          color: Colors.green,
          isLive: true,
          showBar: true,
          trendData: activityData,
          theme: theme,
        ),
        _buildStatCard(
          icon: Icons.star, 
          title: 'Contas PRO', 
          value: '${stats['proUsers']}', 
          color: Colors.amber, 
          theme: theme
        ),
        _buildStatCard(
          icon: Icons.article, 
          title: 'Posts Totais', 
          value: '${stats['totalPosts']}', 
          color: Colors.purple, 
          theme: theme
        ),
        _buildStatCard(
          icon: Icons.chat, 
          title: 'Mensagens', 
          value: '${stats['totalMessages']}', 
          color: Colors.orange, 
          theme: theme
        ),
        _buildStatCard(
          icon: Icons.person_add, 
          title: 'Novos Hoje', 
          value: '${stats['newUsersToday']}', 
          color: Colors.teal, 
          theme: theme
        ),
        _buildStatCard(
          icon: Icons.favorite, 
          title: 'Total Likes', 
          value: '${stats['totalLikes']}', 
          color: Colors.red, 
          theme: theme
        ),
        _buildStatCard(
          icon: Icons.block, 
          title: 'Banidos', 
          value: '${stats['bannedUsers']}', 
          color: Colors.grey, 
          theme: theme
        ),
      ],
    );
  }

  static Widget _buildStatCard({
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
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.brightness == Brightness.dark 
              ? Colors.black54 
              : Colors.black12, 
            blurRadius: 4, 
            offset: const Offset(0, 2)
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: const [
                      CircleAvatar(radius: 4, backgroundColor: Colors.green),
                      SizedBox(width: 6),
                      Text('LIVE', style: TextStyle(
                        fontSize: 10, 
                        fontWeight: FontWeight.bold, 
                        color: Colors.green
                      )),
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
                    Text(value, style: theme.textTheme.titleLarge?.copyWith(
                      fontSize: 22, 
                      fontWeight: FontWeight.bold, 
                      color: textColor
                    )),
                    const SizedBox(height: 4),
                    Text(title, style: TextStyle(
                      fontSize: 12, 
                      color: theme.textTheme.bodySmall?.color ?? Colors.grey[600]
                    )),
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

  static Widget _buildOnlineUsersSection(BuildContext context, Color primaryColor, ThemeData theme) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('isOnline', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }
        final onlineUsers = snapshot.data!.docs;
        
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: theme.brightness == Brightness.dark 
                  ? Colors.black54 
                  : Colors.black12, 
                blurRadius: 4, 
                offset: const Offset(0, 2)
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 10, 
                    height: 10, 
                    decoration: const BoxDecoration(
                      color: Colors.green, 
                      shape: BoxShape.circle
                    )
                  ),
                  const SizedBox(width: 8),
                  Text('Usuários Online (${onlineUsers.length})', 
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold
                    )
                  ),
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
                            backgroundImage: profile.isNotEmpty 
                              ? NetworkImage(profile) 
                              : null,
                            backgroundColor: primaryColor.withOpacity(0.3),
                            child: profile.isEmpty 
                              ? Text(username[0].toUpperCase(), 
                                  style: TextStyle(
                                    fontSize: 20, 
                                    fontWeight: FontWeight.bold, 
                                    color: primaryColor
                                  )
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
                                color: Colors.green,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      SizedBox(
                        width: 56, 
                        child: Text(
                          username, 
                          style: const TextStyle(fontSize: 11), 
                          overflow: TextOverflow.ellipsis, 
                          textAlign: TextAlign.center
                        )
                      ),
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

  static Widget _buildChartCard({
    required String title,
    required List<FlSpot> data,
    required Color color,
    required ThemeData theme,
  }) {
    final spots = data.isEmpty ? [FlSpot(0, 0)] : data;
    final cardBg = theme.cardColor;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: theme.brightness == Brightness.dark 
              ? Colors.black54 
              : Colors.black12, 
            blurRadius: 4, 
            offset: const Offset(0, 2)
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleMedium?.copyWith(
            fontSize: 18, 
            fontWeight: FontWeight.bold
          )),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, drawVerticalLine: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: true, reservedSize: 40)
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false)
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false)
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false)
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: color,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true, 
                      color: color.withOpacity(0.2)
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

  static Widget buildUsersTab(
    BuildContext context,
    ThemeData theme,
    String searchQuery,
    String userFilter,
    Function(String) onSearchChanged,
    Function(String) onFilterChanged,
    Function() onUserDeleted,
  ) {
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
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12))
                  ),
                  filled: true,
                  fillColor: theme.canvasColor,
                ),
                onChanged: onSearchChanged,
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('Todos', 'all', primaryColor, userFilter, onFilterChanged),
                    _buildFilterChip('Online', 'online', primaryColor, userFilter, onFilterChanged),
                    _buildFilterChip('PRO', 'pro', primaryColor, userFilter, onFilterChanged),
                    _buildFilterChip('Banidos', 'banned', primaryColor, userFilter, onFilterChanged),
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
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              var users = snapshot.data!.docs.where((doc) {
                final data = doc.data();
                final username = (data['username'] ?? '').toString().toLowerCase();
                final email = (data['email'] ?? '').toString().toLowerCase();
                bool matchesSearch = searchQuery.isEmpty || 
                  username.contains(searchQuery) || 
                  email.contains(searchQuery);
                bool matchesFilter = true;
                if (userFilter == 'online') matchesFilter = data['isOnline'] == true;
                if (userFilter == 'pro') matchesFilter = data['pro'] == true;
                if (userFilter == 'banned') matchesFilter = data['banned'] == true;
                return matchesSearch && matchesFilter;
              }).toList();

              if (users.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 64, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('Nenhum usuário encontrado')
                    ],
                  )
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final userDoc = users[index];
                  final userData = userDoc.data();
                  final userId = userDoc.id;
                  return _buildUserCard(
                    context,
                    userData, 
                    userId, 
                    primaryColor, 
                    theme,
                    onUserDeleted,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  static Widget _buildFilterChip(
    String label,
    String value,
    Color primaryColor,
    String currentFilter,
    Function(String) onFilterChanged,
  ) {
    final isSelected = currentFilter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) => onFilterChanged(value),
        selectedColor: primaryColor.withOpacity(0.3),
        checkmarkColor: primaryColor,
      ),
    );
  }

  static Widget _buildUserCard(
    BuildContext context,
    Map<String, dynamic> userData,
    String userId,
    Color primaryColor,
    ThemeData theme,
    Function() onUserDeleted,
  ) {
    final profile = (userData['profile_image'] ?? '').toString();
    final username = (userData['username'] ?? 'Usuário').toString();
    final email = (userData['email'] ?? '').toString();
    final tokens = userData['tokens'] ?? 0;
    final isOnline = userData['isOnline'] == true;
    final isPro = userData['pro'] == true;
    final isAdmin = userData['admin'] == true;
    final isBanned = userData['banned'] == true;

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
              child: profile.isEmpty 
                ? Text(
                    username[0].toUpperCase(), 
                    style: TextStyle(
                      fontSize: 20, 
                      fontWeight: FontWeight.bold, 
                      color: primaryColor
                    )
                  ) 
                : null,
            ),
            if (isOnline)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 14, 
                  height: 14, 
                  decoration: BoxDecoration(
                    color: Colors.green, 
                    shape: BoxShape.circle, 
                    border: Border.all(
                      color: theme.cardColor == Colors.white 
                        ? Colors.white 
                        : Colors.black, 
                      width: 2
                    )
                  )
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                username, 
                style: TextStyle(
                  fontWeight: FontWeight.bold, 
                  color: theme.textTheme.bodyLarge?.color
                )
              )
            ),
            if (isPro) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber, 
                  borderRadius: BorderRadius.circular(12)
                ),
                child: const Text(
                  'PRO', 
                  style: TextStyle(
                    fontSize: 10, 
                    fontWeight: FontWeight.bold, 
                    color: Colors.white
                  )
                )
              ),
            ],
            if (isAdmin) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.red, 
                  borderRadius: BorderRadius.circular(12)
                ),
                child: const Text(
                  'ADMIN', 
                  style: TextStyle(
                    fontSize: 10, 
                    fontWeight: FontWeight.bold, 
                    color: Colors.white
                  )
                )
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              email, 
              style: TextStyle(
                fontSize: 12, 
                color: theme.textTheme.bodySmall?.color
              )
            ),
            const SizedBox(height: 4),
            Text(
              '$tokens tokens', 
              style: TextStyle(
                fontSize: 12, 
                color: theme.textTheme.bodySmall?.color
              )
            ),
            if (isBanned) const SizedBox(height: 4),
            if (isBanned) const Text(
              'Usuário banido', 
              style: TextStyle(
                color: Colors.red, 
                fontSize: 12, 
                fontWeight: FontWeight.bold
              )
            ),
          ],
        ),
        trailing: PopupMenuButton(
          icon: Icon(Icons.more_vert, color: theme.iconTheme.color),
          itemBuilder: (context) => [
            const PopupMenuItem(child: Text('Editar Dados'), value: 'edit'),
            PopupMenuItem(
              child: Text(isPro ? 'Remover PRO' : 'Promover a PRO'), 
              value: 'pro'
            ),
            PopupMenuItem(
              child: Text(isAdmin ? 'Remover Admin' : 'Tornar Admin'), 
              value: 'admin'
            ),
            PopupMenuItem(
              child: Text(isBanned ? 'Desbanir Usuário' : 'Banir Usuário'), 
              value: 'ban'
            ),
            const PopupMenuItem(
              child: Text('Excluir Usuário (Firestore)'), 
              value: 'delete'
            ),
          ],
          onSelected: (value) async {
            if (value == 'edit') {
              await AdminPanelUtils.editUser(context, userId, userData);
              onUserDeleted();
            }
            if (value == 'pro') {
              await AdminPanelUtils.togglePro(context, userId, isPro);
              onUserDeleted();
            }
            if (value == 'admin') {
              await AdminPanelUtils.toggleAdmin(context, userId, isAdmin);
              onUserDeleted();
            }
            if (value == 'ban') {
              await AdminPanelUtils.banOrUnbanUser(context, userId, username, isBanned);
              onUserDeleted();
            }
            if (value == 'delete') {
              AdminPanelUtils.confirmDeleteUser(context, userId, username, onUserDeleted);
            }
          },
        ),
      ),
    );
  }

  static Widget buildPostsTab(BuildContext context, ThemeData theme) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('posts')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final posts = snapshot.data!.docs;
        if (posts.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.article, size: 64, color: Colors.grey),
                SizedBox(height: 12),
                Text('Nenhuma publicação encontrada')
              ],
            )
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index].data();
            final postId = posts[index].id;
            return _buildPostCard(
              context,
              post, 
              postId, 
              theme.primaryColor, 
              theme,
            );
          },
        );
      },
    );
  }

  static Widget _buildPostCard(
    BuildContext context,
    Map<String, dynamic> postData,
    String postId,
    Color primaryColor,
    ThemeData theme,
  ) {
    final image = (postData['image'] ?? '').toString();
    final userName = (postData['userName'] ?? 'Usuário').toString();
    final content = (postData['content'] ?? '').toString();
    final likes = postData['likes'] ?? 0;
    final comments = postData['comments'] ?? 0;

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
                errorBuilder: (c, e, st) => Container(
                  height: 200, 
                  color: Colors.grey[200], 
                  child: const Icon(Icons.image, size: 50, color: Colors.grey)
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: primaryColor.withOpacity(0.3),
                      child: Text(
                        userName[0].toUpperCase(), 
                        style: TextStyle(
                          fontWeight: FontWeight.bold, 
                          color: primaryColor
                        )
                      )
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        userName, 
                        style: const TextStyle(
                          fontWeight: FontWeight.bold, 
                          fontSize: 16
                        )
                      )
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red), 
                      onPressed: () => AdminPanelUtils.deletePost(context, postId)
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  content, 
                  maxLines: 3, 
                  overflow: TextOverflow.ellipsis, 
                  style: theme.textTheme.bodyMedium
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.favorite, size: 18, color: Colors.red),
                    const SizedBox(width: 4),
                    Text('$likes', 
                      style: TextStyle(color: theme.textTheme.bodySmall?.color)
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.comment, size: 18, color: Colors.blue),
                    const SizedBox(width: 4),
                    Text('$comments', 
                      style: TextStyle(color: theme.textTheme.bodySmall?.color)
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.access_time, size: 18, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      AdminPanelUtils.formatTimestamp(postData['timestamp']), 
                      style: TextStyle(
                        color: theme.textTheme.bodySmall?.color, 
                        fontSize: 12
                      )
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

  static Widget buildActivitiesTab(
    BuildContext context,
    ThemeData theme, 
    List<Map<String, dynamic>> realtimeActivities
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          color: theme.cardColor,
          child: Row(
            children: [
              Icon(Icons.access_time, color: theme.primaryColor),
              const SizedBox(width: 10),
              Text(
                'Atividades em Tempo Real', 
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold
                )
              ),
            ],
          ),
        ),
        Expanded(
          child: realtimeActivities.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 64, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('Nenhuma atividade recente')
                    ],
                  )
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: realtimeActivities.length,
                  itemBuilder: (context, index) {
                    final activity = realtimeActivities[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: _getActivityIcon(
                          activity['icon'] ?? 'info', 
                          theme.primaryColor
                        ),
                        title: Text(
                          activity['type'] ?? 'Atividade', 
                          style: const TextStyle(fontWeight: FontWeight.bold)
                        ),
                        subtitle: Text(activity['description'] ?? ''),
                        trailing: Text(
                          AdminPanelUtils.formatTimestamp(activity['timestamp']), 
                          style: const TextStyle(fontSize: 11, color: Colors.grey)
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  static Widget _getActivityIcon(String type, Color primaryColor) {
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
    return CircleAvatar(
      backgroundColor: color.withOpacity(0.2),
      child: Icon(iconData, color: color, size: 20),
    );
  }

  static Widget buildAnalyticsTab(
    BuildContext context,
    ThemeData theme,
    String selectedPeriod,
    Map<String, dynamic> stats,
    Function(String) onPeriodChanged,
  ) {
    final primaryColor = theme.primaryColor;
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Analytics Avançado', 
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: 24, 
            fontWeight: FontWeight.bold
          )
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildPeriodButton('7 Dias', '7d', primaryColor, selectedPeriod, onPeriodChanged)
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildPeriodButton('30 Dias', '30d', primaryColor, selectedPeriod, onPeriodChanged)
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildPeriodButton('90 Dias', '90d', primaryColor, selectedPeriod, onPeriodChanged)
            ),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: theme.brightness == Brightness.dark 
                  ? Colors.black54 
                  : Colors.black12, 
                blurRadius: 4, 
                offset: const Offset(0, 2)
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Taxa de Conversão PRO', 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Conversão', style: TextStyle(color: Colors.grey)),
                  Text(
                    '${AdminPanelUtils.calculateConversionRate(stats['totalUsers'] ?? 0, stats['proUsers'] ?? 0)}%', 
                    style: TextStyle(
                      fontSize: 24, 
                      fontWeight: FontWeight.bold, 
                      color: primaryColor
                    )
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: AdminPanelUtils.calculateConversionRate(
                    stats['totalUsers'] ?? 0, 
                    stats['proUsers'] ?? 0
                  ) / 100,
                  backgroundColor: Colors.grey[200],
                  color: primaryColor,
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: theme.brightness == Brightness.dark 
                  ? Colors.black54 
                  : Colors.black12, 
                blurRadius: 4, 
                offset: const Offset(0, 2)
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Engajamento', 
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
              ),
              const SizedBox(height: 16),
              _buildEngagementRow(
                'Likes Totais', 
                stats['totalLikes'] ?? 0, 
                Icons.favorite, 
                Colors.red
              ),
              const SizedBox(height: 12),
              _buildEngagementRow(
                'Comentários', 
                stats['totalComments'] ?? 0, 
                Icons.comment, 
                Colors.blue
              ),
              const SizedBox(height: 12),
              _buildEngagementRow(
                'Mensagens', 
                stats['totalMessages'] ?? 0, 
                Icons.message, 
                Colors.orange
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _buildPeriodButton(
    String label,
    String value,
    Color primaryColor,
    String selectedPeriod,
    Function(String) onPeriodChanged,
  ) {
    final isSelected = selectedPeriod == value;
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? primaryColor : Colors.grey[200],
        foregroundColor: isSelected ? Colors.white : Colors.black87,
        elevation: isSelected ? 4 : 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: () => onPeriodChanged(value),
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }

  static Widget _buildEngagementRow(
    String label, 
    int value, 
    IconData icon, 
    Color color
  ) {
    return Row(
      children: [
        Container(
          width: 48, 
          height: 48, 
          decoration: BoxDecoration(
            color: color.withOpacity(0.2), 
            borderRadius: BorderRadius.circular(12)
          ), 
          child: Icon(icon, color: color, size: 24)
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 15))),
        Text(
          value.toString(), 
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
        ),
      ],
    );
  }
}