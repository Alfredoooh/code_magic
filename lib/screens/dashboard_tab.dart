import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:memory_info/memory_info.dart';

import '../../models/user_model.dart';
import '../../models/app_model.dart';
import '../../services/app_service.dart';
import '../app_detail_screen.dart';
import 'dashboard_widgets/favorites_screen.dart';

class DashboardTab extends StatefulWidget {
  final User user;
  const DashboardTab({Key? key, required this.user}) : super(key: key);

  @override
  State createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  final AppService _appService = AppService();

  Map<String, AppUsageStats> _usageStats = {};
  List<AppModel> _allApps = [];
  List<AppModel> _favoriteApps = [];
  List<AppModel> _recentApps = [];
  List<AppModel> _mostUsedApps = [];
  bool _isLoading = true;

  // memória em tempo real (valores em GB)
  final List<FlSpot> _memorySpots = [];
  Timer? _memoryTimer;
  double _timeTick = 0.0;
  final int _maxSpots = 60;
  double _lastMemoryValue = 0.0;

  String? _currentUserId;
  bool _sessionSaving = false;

  @override
  void initState() {
    super.initState();
    _currentUserId = widget.user.id;
    _loadDashboardData();
    _startMemoryStream();
  }

  @override
  void didUpdateWidget(covariant DashboardTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.user.id != widget.user.id) {
      _handleUserSwitch(oldWidget.user.id, widget.user.id);
    }
  }

  @override
  void dispose() {
    _memoryTimer?.cancel();
    _saveSessionForUser(_currentUserId);
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _appService.fetchAllApps(),
        _appService.getUsageStats(),
        _appService.getFavorites(),
      ]);

      final apps = results[0] as List<AppModel>;
      final stats = results[1] as Map<String, AppUsageStats>;
      final favoriteIds = results[2] as List<String>;

      final userStats = <String, AppUsageStats>{};
      stats.forEach((key, value) {
        userStats[value.appId] = value;
      });

      final favorites = apps.where((app) => favoriteIds.contains(app.id)).toList();

      final mostUsed = apps.where((app) => userStats.containsKey(app.id)).toList();
      mostUsed.sort((a, b) {
        final statsA = userStats[a.id]!;
        final statsB = userStats[b.id]!;
        return statsB.openCount.compareTo(statsA.openCount);
      });

      final recent = apps.where((app) => userStats.containsKey(app.id)).toList();
      recent.sort((a, b) {
        final statsA = userStats[a.id]!;
        final statsB = userStats[b.id]!;
        return statsB.lastUsed.compareTo(statsA.lastUsed);
      });

      await _loadSessionForUser(widget.user.id, userStats, favorites);

      if (mounted) {
        setState(() {
          _allApps = apps;
          _usageStats = userStats;
          _favoriteApps = favorites;
          _mostUsedApps = mostUsed.take(10).toList();
          _recentApps = recent.take(10).toList();
          _isLoading = false;
          _currentUserId = widget.user.id;
        });
      }
    } catch (e, st) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSessionForUser(String? userId) async {
    if (userId == null || _sessionSaving) return;
    _sessionSaving = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final Map<String, int> openCounts = {};
      _usageStats.forEach((k, v) {
        openCounts[k] = v.openCount;
      });
      final session = {
        'openCounts': openCounts,
        'favorites': _favoriteApps.map((a) => a.id).toList(),
        'savedAt': DateTime.now().toIso8601String(),
      };
      await prefs.setString('session_$userId', jsonEncode(session));
    } catch (e) {
      // ignore
    } finally {
      _sessionSaving = false;
    }
  }

  Future<void> _loadSessionForUser(String userId, Map<String, AppUsageStats> userStats, List<AppModel> favoritesList) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('session_$userId');
      if (raw == null) return;
      final Map<String, dynamic> data = jsonDecode(raw);
      final Map<String, dynamic>? openCounts = (data['openCounts'] as Map?)?.cast<String, dynamic>();
      final List<dynamic>? favorites = data['favorites'] as List<dynamic>?;

      if (openCounts != null) {
        openCounts.forEach((appId, countDyn) {
          final count = (countDyn is int) ? countDyn : int.tryParse('$countDyn') ?? 0;
          if (userStats.containsKey(appId)) {
            // Create a new AppUsageStats with updated openCount
            final oldStats = userStats[appId]!;
            userStats[appId] = AppUsageStats(
              appId: appId,
              openCount: count,
              totalUsageTime: oldStats.totalUsageTime,
              lastUsed: oldStats.lastUsed,
            );
          } else {
            // Create new stats entry
            try {
              userStats[appId] = AppUsageStats(
                appId: appId,
                openCount: count,
                totalUsageTime: const Duration(seconds: 0),
                lastUsed: DateTime.now(),
              );
            } catch (_) {}
          }
        });
      }

      if (favorites != null && favorites.isNotEmpty) {
        final favIds = favorites.map((e) => '$e').toList();
        _favoriteApps = _allApps.where((a) => favIds.contains(a.id)).toList();
      }
    } catch (e) {
      // ignore
    }
  }

  Future<void> _handleUserSwitch(String oldUserId, String newUserId) async {
    await _saveSessionForUser(oldUserId);
    if (mounted) {
      setState(() {
        _usageStats = {};
        _allApps = [];
        _favoriteApps = [];
        _recentApps = [];
        _mostUsedApps = [];
        _isLoading = true;
      });
    }
    await _loadDashboardData();
  }

  void _startMemoryStream() {
    _timeTick = 0.0;
    _memorySpots.clear();
    final baseline = 3.0;
    for (int i = 0; i < 8; i++) {
      _memorySpots.add(FlSpot(i.toDouble(), baseline));
      _timeTick = i.toDouble();
    }
    _lastMemoryValue = baseline;

    _memoryTimer?.cancel();
    _memoryTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      final memGb = await _getMemoryInfoGB();
      _addMemoryPoint(memGb);
    });
  }

  Future<double> _getMemoryInfoGB() async {
    try {
      final memoryInfo = await MemoryInfoPlugin().memoryInfo;
      
      if (memoryInfo != null) {
        // Tenta obter memória total e livre
        final totalMem = memoryInfo.totalMem ?? 0;
        final freeMem = memoryInfo.freeMem ?? 0;
        
        if (totalMem > 0) {
          final usedBytes = (totalMem - freeMem).clamp(0, totalMem);
          final usedGb = usedBytes / (1024 * 1024 * 1024);
          
          if (usedGb.isFinite && usedGb > 0) {
            return double.parse(usedGb.toStringAsFixed(2));
          }
        }
      }
    } catch (e) {
      // Se falhar, tenta método alternativo
      try {
        final info = await MemoryInfoPlugin().memoryInfo;
        final totalBytes = info.totalMem ?? 0;
        final freeBytes = info.freeMem ?? 0;
        
        if (totalBytes > 0) {
          final usedBytes = (totalBytes - freeBytes).clamp(0, totalBytes);
          final usedGb = usedBytes / (1024 * 1024 * 1024);
          
          if (usedGb.isFinite && usedGb > 0) {
            return double.parse(usedGb.toStringAsFixed(2));
          }
        }
      } catch (e2) {
        // Ignora e usa fallback abaixo
      }
    }

    // Fallback: simulação suave quando não consegue obter dados reais
    final noise = (0.15 * (0.5 - (DateTime.now().millisecondsSinceEpoch % 1000) / 1000));
    final next = (_lastMemoryValue + noise).clamp(0.5, 12.0);
    return double.parse(next.toStringAsFixed(2));
  }

  void _addMemoryPoint(double rawGb) {
    final smoothed = (_lastMemoryValue * 0.6) + (rawGb * 0.4);
    _lastMemoryValue = smoothed;

    _timeTick += 1.0;
    final spot = FlSpot(_timeTick, smoothed);
    _memorySpots.add(spot);

    if (_memorySpots.length > _maxSpots) {
      _memorySpots.removeRange(0, _memorySpots.length - _maxSpots);
    }

    if (mounted) setState(() {});
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Olá, ${widget.user.name}',
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFFFFFF),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Sua atividade de hoje',
            style: TextStyle(
              fontSize: 17,
              color: Color(0xFF8E8E93),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralStats() {
    final totalApps = _allApps.length;
    final totalUsed = _usageStats.length;
    final totalOpens = _usageStats.values.fold<int>(0, (sum, stat) => sum + stat.openCount);
    final favoriteCount = _favoriteApps.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: CupertinoIcons.square_grid_2x2,
                  value: '$totalApps',
                  label: 'Apps',
                  color: const Color(0xFF007AFF),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: CupertinoIcons.app_badge,
                  value: '$totalUsed',
                  label: 'Usados',
                  color: const Color(0xFF34C759),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: CupertinoIcons.arrow_up_right,
                  value: '$totalOpens',
                  label: 'Aberturas',
                  color: const Color(0xFFFF9500),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: CupertinoIcons.heart_fill,
                  value: '$favoriteCount',
                  label: 'Favoritos',
                  color: const Color(0xFFFF3B30),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFFFFFF),
              letterSpacing: -0.5,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF8E8E93),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getBarColorForValue(int value, int maxValue) {
    final percentage = (value / (maxValue == 0 ? 1 : maxValue) * 100);
    if (percentage >= 70) return const Color(0xFF34C759);
    if (percentage >= 40) return const Color(0xFFFF9500);
    if (percentage >= 15) return const Color(0xFFFFCC00);
    return const Color(0xFF8E8E93);
  }

  Widget _buildUsageChart() {
    if (_usageStats.isEmpty) return const SizedBox.shrink();

    final now = DateTime.now();
    final last7Days = List.generate(7, (i) {
      return DateTime(now.year, now.month, now.day - (6 - i));
    });

    final dailyUsage = <int>[];
    for (var day in last7Days) {
      var count = 0;
      for (var stat in _usageStats.values) {
        if (stat.lastUsed.year == day.year &&
            stat.lastUsed.month == day.month &&
            stat.lastUsed.day == day.day) {
          count += stat.openCount;
        }
      }
      dailyUsage.add(count);
    }

    final maxY = dailyUsage.isEmpty ? 10.0 : (dailyUsage.reduce((a, b) => a > b ? a : b) + 5).toDouble();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Atividade Semanal',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFFFFFF),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 180,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const days = ['D', 'S', 'T', 'Q', 'Q', 'S', 'S'];
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            days[value.toInt() % 7],
                            style: const TextStyle(
                              color: Color(0xFF8E8E93),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 4,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: const Color(0xFF2C2C2E),
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: dailyUsage.asMap().entries.map((entry) {
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.toDouble(),
                        color: _getBarColorForValue(entry.value, maxY.toInt()),
                        width: 16,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMemoryUsageChart() {
    if (_memorySpots.isEmpty) return const SizedBox.shrink();

    final minX = _memorySpots.first.x;
    final maxX = _memorySpots.last.x;
    final values = _memorySpots.map((s) => s.y).toList();
    final maxYValue = (values.isEmpty ? 8.0 : (values.reduce((a, b) => a > b ? a : b) + 1.5)).clamp(1.0, 64.0);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Uso de Memória',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFFFFFF),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 180,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: (maxYValue / 4).clamp(1.0, maxYValue),
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: const Color(0xFF2C2C2E),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: ((maxX - minX) / 4).clamp(1.0, double.infinity),
                      getTitlesWidget: (value, meta) {
                        final intIndex = value.toInt();
                        final label = '${intIndex % 24}h';
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            label,
                            style: const TextStyle(
                              color: Color(0xFF8E8E93),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minX: minX,
                maxX: maxX,
                minY: 0,
                maxY: (maxYValue < 1) ? 1 : maxYValue,
                lineBarsData: [
                  LineChartBarData(
                    spots: _memorySpots,
                    isCurved: true,
                    color: const Color(0xFF007AFF),
                    barWidth: 1.6,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: const Color(0xFF007AFF).withOpacity(0.08),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Uso Atual',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_lastMemoryValue.toStringAsFixed(2)} GB',
                      style: const TextStyle(
                        color: Color(0xFF007AFF),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Disponível',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '—',
                      style: TextStyle(
                        color: Color(0xFF34C759),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
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

  Widget _buildMostUsedApps() {
    if (_mostUsedApps.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Mais Usados',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFFFFF),
                  letterSpacing: -0.3,
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () {},
                child: const Text(
                  'Ver tudo',
                  style: TextStyle(
                    color: Color(0xFF007AFF),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: _mostUsedApps.take(5).toList().asMap().entries.map((entry) {
                final index = entry.key;
                final app = entry.value;
                final stats = _usageStats[app.id]!;
                final isLast = index == _mostUsedApps.take(5).length - 1;
                return _buildAppUsageTile(app, stats, isLast);
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppUsageTile(AppModel app, AppUsageStats stats, bool isLast) {
    return GestureDetector(
      onTap: () => _openAppDetail(app),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: isLast
              ? null
              : const Border(
                  bottom: BorderSide(
                    color: Color(0xFF2C2C2E),
                    width: 1,
                  ),
                ),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                app.iconUrl,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 48,
                  height: 48,
                  color: const Color(0xFF2C2C2E),
                  child: const Icon(CupertinoIcons.app, color: Color(0xFF8E8E93)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    app.name,
                    style: const TextStyle(
                      color: Color(0xFFFFFFFF),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${stats.openCount} aberturas',
                    style: const TextStyle(
                      color: Color(0xFF8E8E93),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${stats.openCount}x',
                  style: const TextStyle(
                    color: Color(0xFF007AFF),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatLastUsed(stats.lastUsed),
                  style: const TextStyle(
                    color: Color(0xFF8E8E93),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentApps() {
    if (_recentApps.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(right: 20),
            child: Text(
              'Recentes',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFFFFFF),
                letterSpacing: -0.3,
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 110,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(right: 20),
              itemCount: _recentApps.length,
              itemBuilder: (context, index) {
                final app = _recentApps[index];
                return GestureDetector(
                  onTap: () => _openAppDetail(app),
                  child: Container(
                    width: 80,
                    margin: EdgeInsets.only(left: index == 0 ? 0 : 12),
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.06),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              app.iconUrl,
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 64,
                                height: 64,
                                color: const Color(0xFF1C1C1E),
                                child: const Icon(
                                  CupertinoIcons.app,
                                  color: Color(0xFF8E8E93),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          app.name,
                          style: const TextStyle(
                            color: Color(0xFFFFFFFF),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 2,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteApps() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Favoritos',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFFFFF),
                  letterSpacing: -0.3,
                ),
              ),
              if (_favoriteApps.isNotEmpty)
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (context) => FavoritesScreen(
                          favoriteApps: _favoriteApps,
                          onAppTap: _openAppDetail,
                        ),
                      ),
                    ).then((_) => _loadDashboardData());
                  },
                  child: const Text(
                    'Ver todos',
                    style: TextStyle(
                      color: Color(0xFF007AFF),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: _favoriteApps.isEmpty
                ? const Row(
                    children: [
                      Icon(CupertinoIcons.heart, color: Color(0xFF8E8E93)),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Nenhum favorito — toque em um app para adicionar aos favoritos',
                          style: TextStyle(
                            color: Color(0xFF8E8E93),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      ..._favoriteApps.take(4).map((app) {
                        final index = _favoriteApps.indexOf(app);
                        return GestureDetector(
                          onTap: () => _openAppDetail(app),
                          child: Container(
                            margin: EdgeInsets.only(right: index == 3 ? 0 : 12),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    app.iconUrl,
                                    width: 56,
                                    height: 56,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 56,
                                      height: 56,
                                      color: const Color(0xFF2C2C2E),
                                      child: const Icon(
                                        CupertinoIcons.app,
                                        color: Color(0xFF8E8E93),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                SizedBox(
                                  width: 64,
                                  child: Text(
                                    app.name,
                                    style: const TextStyle(
                                      color: Color(0xFFFFFFFF),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    maxLines: 2,
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                      if (_favoriteApps.length > 4)
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              CupertinoPageRoute(
                                builder: (context) => FavoritesScreen(
                                  favoriteApps: _favoriteApps,
                                  onAppTap: _openAppDetail,
                                ),
                              ),
                            ).then((_) => _loadDashboardData());
                          },
                          child: Container(
                            margin: const EdgeInsets.only(left: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2C2C2E),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '+${_favoriteApps.length - 4}',
                              style: const TextStyle(
                                color: Color(0xFF8E8E93),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      const Spacer(),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          Navigator.push(
                            context,
                            CupertinoPageRoute(
                              builder: (context) => FavoritesScreen(
                                favoriteApps: _favoriteApps,
                                onAppTap: _openAppDetail,
                              ),
                            ),
                          ).then((_) => _loadDashboardData());
                        },
                        child: const Text(
                          'Abrir',
                          style: TextStyle(
                            color: Color(0xFF007AFF),
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown() {
    if (_usageStats.isEmpty) return const SizedBox.shrink();

    final categoryCount = <String, int>{};
    for (var app in _allApps) {
      if (_usageStats.containsKey(app.id)) {
        categoryCount[app.category] = (categoryCount[app.category] ?? 0) + 1;
      }
    }

    final sortedCategories = categoryCount.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    final colors = [
      const Color(0xFF007AFF),
      const Color(0xFF34C759),
      const Color(0xFFFF9500),
      const Color(0xFFFF3B30),
      const Color(0xFF5856D6),
      const Color(0xFFAF52DE),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Por Categoria',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFFFFFF),
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: sortedCategories.take(6).toList().asMap().entries.map((entry) {
                final index = entry.key;
                final category = entry.value;
                final percentage = (_usageStats.isEmpty) ? 0.0 : (category.value / _usageStats.length * 100);

                return Padding(
                  padding: EdgeInsets.only(bottom: index == 5 ? 0 : 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            category.key,
                            style: const TextStyle(
                              color: Color(0xFFFFFFFF),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${category.value}',
                            style: const TextStyle(
                              color: Color(0xFF8E8E93),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: percentage / 100,
                          minHeight: 6,
                          backgroundColor: const Color(0xFF2C2C2E),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            colors[index % colors.length],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _formatLastUsed(DateTime lastUsed) {
    final now = DateTime.now();
    final difference = now.difference(lastUsed);

    if (difference.inMinutes < 1) {
      return 'Agora';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${(difference.inDays / 7).floor()}sem';
    }
  }

  void _openAppDetail(AppModel app) {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => AppDetailScreen(app: app),
      ),
    ).then((_) => _loadDashboardData());
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFF000000),
      child: _isLoading
          ? const Center(
              child: CupertinoActivityIndicator(
                radius: 20,
                color: Color(0xFF007AFF),
              ),
            )
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeader()),
                SliverToBoxAdapter(child: _buildGeneralStats()),
                SliverToBoxAdapter(child: _buildUsageChart()),
                SliverToBoxAdapter(child: _buildMemoryUsageChart()),
                SliverToBoxAdapter(child: _buildMostUsedApps()),
                SliverToBoxAdapter(child: _buildRecentApps()),
                SliverToBoxAdapter(child: _buildFavoriteApps()),
                SliverToBoxAdapter(child: _buildCategoryBreakdown()),
                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
    );
  }
}