import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'admin_panel_utils.dart';
import '../widgets/app_colors.dart';
import 'app_ui_components.dart';

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
      color: AppColors.primary,
      onRefresh: () async {
        await loadStatistics();
        await updateChartsFromFirestore();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const AppSectionTitle(text: 'Visão Geral', fontSize: 20),
          const SizedBox(height: 16),
          _buildStatsGrid(stats, userGrowthData, activityData),
          const SizedBox(height: 20),
          _buildOnlineUsersSection(context),
          const SizedBox(height: 20),
          _buildChartCard(
            title: 'Crescimento de Usuários',
            data: userGrowthData,
            color: AppColors.primary,
          ),
          const SizedBox(height: 16),
          _buildChartCard(
            title: 'Atividade da Plataforma',
            data: activityData,
            color: Colors.purple,
          ),
        ],
      ),
    );
  }

  static Widget _buildStatsGrid(
    Map<String, dynamic> stats,
    List<FlSpot> userGrowthData,
    List<FlSpot> activityData,
  ) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _buildStatCard(
          icon: Icons.people_outline,
          title: 'Total Usuários',
          value: '${stats['totalUsers']}',
          color: AppColors.primary,
        ),
        _buildStatCard(
          icon: Icons.circle,
          title: 'Online Agora',
          value: '${stats['activeUsers']}',
          color: Colors.green,
          isLive: true,
        ),
        _buildStatCard(
          icon: Icons.star_outline,
          title: 'Contas PRO',
          value: '${stats['proUsers']}',
          color: Colors.amber,
        ),
        _buildStatCard(
          icon: Icons.article_outlined,
          title: 'Posts Totais',
          value: '${stats['totalPosts']}',
          color: Colors.purple,
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
  }) {
    return Builder(
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        
        return AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  if (isLive)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: const [
                          CircleAvatar(radius: 3, backgroundColor: Colors.green),
                          SizedBox(width: 4),
                          Text(
                            'LIVE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.green,
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
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget _buildOnlineUsersSection(BuildContext context) {
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

        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const AppSectionTitle(text: 'Usuários Online', fontSize: 16),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${onlineUsers.length}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
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
                            radius: 24,
                            backgroundImage: profile.isNotEmpty ? NetworkImage(profile) : null,
                            backgroundColor: AppColors.primary.withOpacity(0.2),
                            child: profile.isEmpty
                                ? Text(
                                    username[0].toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
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
                        width: 48,
                        child: Text(
                          username,
                          style: const TextStyle(fontSize: 10),
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
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
  }) {
    final spots = data.isEmpty ? [FlSpot(0, 0)] : data;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSectionTitle(text: title, fontSize: 16),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 1,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey.withOpacity(0.1),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      getTitlesWidget: (value, meta) => Text(
                        value.toInt().toString(),
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      ),
                    ),
                  ),
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
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: color.withOpacity(0.1),
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
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              AppTextField(
                hintText: 'Buscar usuários...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                onChanged: onSearchChanged,
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('Todos', 'all', userFilter, onFilterChanged),
                    const SizedBox(width: 8),
                    _buildFilterChip('Online', 'online', userFilter, onFilterChanged),
                    const SizedBox(width: 8),
                    _buildFilterChip('PRO', 'pro', userFilter, onFilterChanged),
                    const SizedBox(width: 8),
                    _buildFilterChip('Banidos', 'banned', userFilter, onFilterChanged),
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
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
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
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppIconCircle(
                        icon: Icons.people_outline,
                        size: 40,
                        iconColor: Colors.grey,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Nenhum usuário encontrado',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
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
    String currentFilter,
    Function(String) onFilterChanged,
  ) {
    final isSelected = currentFilter == value;
    return GestureDetector(
      onTap: () => onFilterChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  static Widget _buildUserCard(
    BuildContext context,
    Map<String, dynamic> userData,
    String userId,
    Function() onUserDeleted,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final profile = (userData['profile_image'] ?? '').toString();
    final username = (userData['username'] ?? 'Usuário').toString();
    final email = (userData['email'] ?? '').toString();
    final tokens = userData['tokens'] ?? 0;
    final isOnline = userData['isOnline'] == true;
    final isPro = userData['pro'] == true;
    final isAdmin = userData['admin'] == true;
    final isBanned = userData['banned'] == true;

    return AppCard(
      padding: const EdgeInsets.all(12),
      elevated: false,
      child: Row(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage: profile.isNotEmpty ? NetworkImage(profile) : null,
                backgroundColor: AppColors.primary.withOpacity(0.2),
                child: profile.isEmpty
                    ? Text(
                        username[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      )
                    : null,
              ),
              if (isOnline)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? AppColors.darkCard : Colors.white,
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        username,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    if (isPro) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'PRO',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                    if (isAdmin) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'ADMIN',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.monetization_on, size: 12, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      '$tokens tokens',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
                if (isBanned) ...[
                  const SizedBox(height: 4),
                  const Text(
                    'Usuário banido',
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          PopupMenuButton(
            icon: Icon(Icons.more_vert, color: Colors.grey[600]),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            itemBuilder: (context) => [
              const PopupMenuItem(
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('Editar Dados'),
                  ],
                ),
                value: 'edit',
              ),
              PopupMenuItem(
                child: Row(
                  children: [
                    Icon(isPro ? Icons.star_outline : Icons.star, size: 20),
                    const SizedBox(width: 8),
                    Text(isPro ? 'Remover PRO' : 'Promover a PRO'),
                  ],
                ),
                value: 'pro',
              ),
              PopupMenuItem(
                child: Row(
                  children: [
                    Icon(isAdmin ? Icons.admin_panel_settings_outlined : Icons.admin_panel_settings, size: 20),
                    const SizedBox(width: 8),
                    Text(isAdmin ? 'Remover Admin' : 'Tornar Admin'),
                  ],
                ),
                value: 'admin',
              ),
              PopupMenuItem(
                child: Row(
                  children: [
                    Icon(isBanned ? Icons.lock_open : Icons.block, size: 20, color: Colors.red),
                    const SizedBox(width: 8),
                    Text(isBanned ? 'Desbanir' : 'Banir', style: const TextStyle(color: Colors.red)),
                  ],
                ),
                value: 'ban',
              ),
              const PopupMenuItem(
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Excluir', style: TextStyle(color: Colors.red)),
                  ],
                ),
                value: 'delete',
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
        ],
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
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }
        final posts = snapshot.data!.docs;
        if (posts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppIconCircle(
                  icon: Icons.article_outlined,
                  size: 40,
                  iconColor: Colors.grey,
                ),
                const SizedBox(height: 12),
                Text(
                  'Nenhuma publicação encontrada',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            final post = posts[index].data();
            final postId = posts[index].id;
            return _buildPostCard(context, post, postId);
          },
        );
      },
    );
  }

  static Widget _buildPostCard(
    BuildContext context,
    Map<String, dynamic> postData,
    String postId,
  ) {
    final image = (postData['image'] ?? '').toString();
    final userName = (postData['userName'] ?? 'Usuário').toString();
    final content = (postData['content'] ?? '').toString();
    final likes = postData['likes'] ?? 0;
    final comments = postData['comments'] ?? 0;

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primary.withOpacity(0.2),
                  child: Text(
                    userName[0].toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    userName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  onPressed: () => AdminPanelUtils.deletePost(context, postId),
                ),
              ],
            ),
          ),
          if (image.isNotEmpty)
            Image.network(
              image,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
              errorBuilder: (c, e, st) => Container(
                height: 200,
                color: Colors.grey[200],
                child: const Icon(Icons.image, size: 40, color: Colors.grey),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  content,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.favorite_border, size: 16, color: Colors.red),
                    const SizedBox(width: 4),
                    Text('$likes', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    const SizedBox(width: 16),
                    const Icon(Icons.chat_bubble_outline, size: 16, color: Colors.blue),
                    const SizedBox(width: 4),
                    Text('$comments', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    const Spacer(),
                    Text(
                      AdminPanelUtils.formatTimestamp(postData['timestamp']),
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
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
    List<Map<String, dynamic>> realtimeActivities,
  ) {
    return realtimeActivities.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppIconCircle(
                  icon: Icons.history,
                  size: 40,
                  iconColor: Colors.grey,
                ),
                const SizedBox(height: 12),
                Text(
                  'Nenhuma atividade recente',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: realtimeActivities.length,
            itemBuilder: (context, index) {
              final activity = realtimeActivities[index];
              return AppCard(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    _getActivityIcon(activity['icon'] ?? 'info'),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activity['type'] ?? 'Atividade',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            activity['description'] ?? '',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      AdminPanelUtils.formatTimestamp(activity['timestamp']),
                      style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                    ),
                  ],
                ),
              );
            },
          );
  }

  static Widget _getActivityIcon(String type) {
    IconData iconData;
    Color color;
    switch (type) {
      case 'user_add':
        iconData = Icons.person_add_outlined;
        color = AppColors.primary;
        break;
      case 'login':
        iconData = Icons.login;
        color = Colors.green;
        break;
      case 'post':
        iconData = Icons.article_outlined;
        color = Colors.purple;
        break;
      case 'message':
        iconData = Icons.message_outlined;
        color = Colors.orange;
        break;
      default:
        iconData = Icons.info_outline;
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const AppSectionTitle(text: 'Analytics Avançado', fontSize: 20),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildPeriodButton('7 Dias', '7d', selectedPeriod, onPeriodChanged),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildPeriodButton('30 Dias', '30d', selectedPeriod, onPeriodChanged),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildPeriodButton('90 Dias', '90d', selectedPeriod, onPeriodChanged),
            ),
          ],
        ),
        const SizedBox(height: 20),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppSectionTitle(text: 'Taxa de Conversão PRO', fontSize: 16),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Conversão',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                  Text(
                    '${AdminPanelUtils.calculateConversionRate(stats['totalUsers'] ?? 0, stats['proUsers'] ?? 0)}%',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: AdminPanelUtils.calculateConversionRate(
                            stats['totalUsers'] ?? 0,
                            stats['proUsers'] ?? 0) /
                      100,
                  backgroundColor: Colors.grey[200],
                  color: AppColors.primary,
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppSectionTitle(text: 'Engajamento', fontSize: 16),
              const SizedBox(height: 16),
              _buildEngagementRow(
                'Likes Totais',
                stats['totalLikes'] ?? 0,
                Icons.favorite_outline,
                Colors.red,
              ),
              const SizedBox(height: 12),
              _buildEngagementRow(
                'Comentários',
                stats['totalComments'] ?? 0,
                Icons.chat_bubble_outline,
                Colors.blue,
              ),
              const SizedBox(height: 12),
              _buildEngagementRow(
                'Mensagens',
                stats['totalMessages'] ?? 0,
                Icons.message_outlined,
                Colors.orange,
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
    String selectedPeriod,
    Function(String) onPeriodChanged,
  ) {
    final isSelected = selectedPeriod == value;
    return GestureDetector(
      onTap: () => onPeriodChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? Colors.white : Colors.grey[700],
          ),
        ),
      ),
    );
  }

  static Widget _buildEngagementRow(
    String label,
    int value,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
        Text(
          value.toString(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}