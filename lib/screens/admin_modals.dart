import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import '../widgets/app_ui_components.dart';
import '../widgets/app_colors.dart';

// Statistics Modal
class StatisticsModal extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightBackground,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: Column(
        children: [
          SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: 20),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(Icons.bar_chart_rounded, color: AppColors.primary, size: 28),
                SizedBox(width: 12),
                AppSectionTitle(text: 'Estatísticas', fontSize: 28),
              ],
            ),
          ),
          SizedBox(height: 24),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator(color: AppColors.primary));
                }

                final users = snapshot.data!.docs;
                final totalUsers = users.length;

                final now = DateTime.now();
                final dailyActive = users.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final lastSeen = data['last_seen'] as Timestamp?;
                  if (lastSeen == null) return false;
                  return now.difference(lastSeen.toDate()).inHours < 24;
                }).length;

                final weeklyActive = users.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final lastSeen = data['last_seen'] as Timestamp?;
                  if (lastSeen == null) return false;
                  return now.difference(lastSeen.toDate()).inDays < 7;
                }).length;

                final monthlyActive = users.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final lastSeen = data['last_seen'] as Timestamp?;
                  if (lastSeen == null) return false;
                  return now.difference(lastSeen.toDate()).inDays < 30;
                }).length;

                final proUsers = users.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['pro'] == true;
                }).length;

                final blockedUsers = users.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['access'] == false;
                }).length;

                return ListView(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _buildStatCard(
                      title: 'Total de Usuários',
                      value: totalUsers.toString(),
                      color: Colors.blue,
                      isDark: isDark,
                    ),
                    SizedBox(height: 12),

                    // Gráfico de Usuários Ativos
                    AppCard(
                      padding: EdgeInsets.all(20),
                      borderRadius: 20,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppSectionTitle(text: 'Usuários Ativos', fontSize: 20),
                          SizedBox(height: 20),
                          Container(
                            height: 250,
                            child: BarChart(
                              BarChartData(
                                alignment: BarChartAlignment.spaceAround,
                                maxY: totalUsers.toDouble() * 1.2,
                                barTouchData: BarTouchData(
                                  enabled: true,
                                  touchTooltipData: BarTouchTooltipData(
                                    tooltipBorder: BorderSide(color: Colors.transparent),
                                    tooltipPadding: EdgeInsets.all(8),
                                    tooltipMargin: 8,
                                    getTooltipColor: (group) => isDark ? Color(0xFF3C3C3E) : Colors.grey[800]!,
                                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                      String label;
                                      switch (group.x.toInt()) {
                                        case 0:
                                          label = 'Diário';
                                          break;
                                        case 1:
                                          label = 'Semanal';
                                          break;
                                        case 2:
                                          label = 'Mensal';
                                          break;
                                        default:
                                          label = '';
                                      }
                                      return BarTooltipItem(
                                        '$label\n${rod.toY.toInt()}',
                                        TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                titlesData: FlTitlesData(
                                  show: true,
                                  bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      getTitlesWidget: (value, meta) {
                                        String text;
                                        switch (value.toInt()) {
                                          case 0:
                                            text = 'Diário';
                                            break;
                                          case 1:
                                            text = 'Semanal';
                                            break;
                                          case 2:
                                            text = 'Mensal';
                                            break;
                                          default:
                                            text = '';
                                        }
                                        return Padding(
                                          padding: EdgeInsets.only(top: 8),
                                          child: Text(
                                            text,
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  leftTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                      showTitles: true,
                                      reservedSize: 40,
                                      getTitlesWidget: (value, meta) {
                                        return Text(
                                          value.toInt().toString(),
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  topTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                  rightTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: false),
                                  ),
                                ),
                                gridData: FlGridData(
                                  show: true,
                                  drawVerticalLine: false,
                                  horizontalInterval: (totalUsers / 4).ceilToDouble(),
                                  getDrawingHorizontalLine: (value) {
                                    return FlLine(
                                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                                      strokeWidth: 1,
                                    );
                                  },
                                ),
                                borderData: FlBorderData(show: false),
                                barGroups: [
                                  BarChartGroupData(
                                    x: 0,
                                    barRods: [
                                      BarChartRodData(
                                        toY: dailyActive.toDouble(),
                                        color: Colors.green,
                                        width: 40,
                                        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                                      ),
                                    ],
                                  ),
                                  BarChartGroupData(
                                    x: 1,
                                    barRods: [
                                      BarChartRodData(
                                        toY: weeklyActive.toDouble(),
                                        color: Colors.blue,
                                        width: 40,
                                        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                                      ),
                                    ],
                                  ),
                                  BarChartGroupData(
                                    x: 2,
                                    barRods: [
                                      BarChartRodData(
                                        toY: monthlyActive.toDouble(),
                                        color: Colors.orange,
                                        width: 40,
                                        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildLegendItem('Diário', dailyActive, Colors.green, isDark),
                              _buildLegendItem('Semanal', weeklyActive, Colors.blue, isDark),
                              _buildLegendItem('Mensal', monthlyActive, Colors.orange, isDark),
                            ],
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 12),
                    _buildStatCard(
                      title: 'Ativos Hoje',
                      value: dailyActive.toString(),
                      subtitle: '${((dailyActive / (totalUsers > 0 ? totalUsers : 1)) * 100).toStringAsFixed(1)}% do total',
                      color: Colors.green,
                      isDark: isDark,
                    ),
                    SizedBox(height: 12),
                    _buildStatCard(
                      title: 'Ativos Esta Semana',
                      value: weeklyActive.toString(),
                      subtitle: '${((weeklyActive / (totalUsers > 0 ? totalUsers : 1)) * 100).toStringAsFixed(1)}% do total',
                      color: Colors.blue,
                      isDark: isDark,
                    ),
                    SizedBox(height: 12),
                    _buildStatCard(
                      title: 'Ativos Este Mês',
                      value: monthlyActive.toString(),
                      subtitle: '${((monthlyActive / (totalUsers > 0 ? totalUsers : 1)) * 100).toStringAsFixed(1)}% do total',
                      color: Colors.orange,
                      isDark: isDark,
                    ),
                    SizedBox(height: 12),
                    _buildStatCard(
                      title: 'Usuários PRO',
                      value: proUsers.toString(),
                      subtitle: '${((proUsers / (totalUsers > 0 ? totalUsers : 1)) * 100).toStringAsFixed(1)}% do total',
                      color: AppColors.primary,
                      isDark: isDark,
                    ),
                    SizedBox(height: 12),
                    _buildStatCard(
                      title: 'Usuários Bloqueados',
                      value: blockedUsers.toString(),
                      subtitle: '${((blockedUsers / (totalUsers > 0 ? totalUsers : 1)) * 100).toStringAsFixed(1)}% do total',
                      color: Colors.red,
                      isDark: isDark,
                    ),
                    SizedBox(height: 24),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildLegendItem(String label, int value, Color color, bool isDark) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        SizedBox(height: 4),
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }

  static Widget _buildStatCard({
    required String title,
    required String value,
    String? subtitle,
    required Color color,
    required bool isDark,
  }) {
    return AppCard(
      padding: EdgeInsets.all(16),
      borderRadius: 16,
      child: Row(
        children: [
          Container(
            width: 4,
            height: 50,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                if (subtitle != null) ...[
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Settings Modal
class SettingsModal extends StatefulWidget {
  @override
  _SettingsModalState createState() => _SettingsModalState();
}

class _SettingsModalState extends State<SettingsModal> {
  bool autoDeleteInactiveUsers = false;
  bool enableUserRegistration = true;
  int maxTokensPerUser = 1000;
  int inactivityDays = 90;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return KeyboardAvoiding(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightBackground,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        child: Column(
          children: [
            SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 20),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(Icons.settings, color: AppColors.primary, size: 28),
                  SizedBox(width: 12),
                  AppSectionTitle(text: 'Configurações', fontSize: 28),
                ],
              ),
            ),
            SizedBox(height: 24),
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 20),
                children: [
                  Text(
                    'GERENCIAMENTO DE USUÁRIOS',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                      letterSpacing: -0.08,
                    ),
                  ),
                  SizedBox(height: 8),
                  AppCard(
                    padding: EdgeInsets.zero,
                    borderRadius: 16,
                    child: Column(
                      children: [
                        _buildSettingTile(
                          title: 'Permitir Novos Registros',
                          value: enableUserRegistration,
                          onChanged: (val) => setState(() => enableUserRegistration = val),
                          isDark: isDark,
                          isFirst: true,
                        ),
                        Divider(height: 1, thickness: 0.5, indent: 16),
                        _buildSettingTile(
                          title: 'Excluir Usuários Inativos',
                          value: autoDeleteInactiveUsers,
                          onChanged: (val) => setState(() => autoDeleteInactiveUsers = val),
                          isDark: isDark,
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 32),
                  Text(
                    'TOKENS',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                      letterSpacing: -0.08,
                    ),
                  ),
                  SizedBox(height: 8),
                  AppCard(
                    padding: EdgeInsets.all(16),
                    borderRadius: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Tokens Máximos',
                              style: TextStyle(
                                fontSize: 17,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            Text(
                              maxTokensPerUser.toString(),
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        SliderTheme(
                          data: SliderThemeData(
                            activeTrackColor: AppColors.primary,
                            inactiveTrackColor: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                            thumbColor: AppColors.primary,
                            overlayColor: AppColors.primary.withOpacity(0.2),
                            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8),
                          ),
                          child: Slider(
                            value: maxTokensPerUser.toDouble(),
                            min: 100,
                            max: 10000,
                            divisions: 99,
                            onChanged: (val) => setState(() => maxTokensPerUser = val.toInt()),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12),
                  AppCard(
                    padding: EdgeInsets.all(16),
                    borderRadius: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Dias de Inatividade',
                              style: TextStyle(
                                fontSize: 17,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            Text(
                              '$inactivityDays dias',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        SliderTheme(
                          data: SliderThemeData(
                            activeTrackColor: AppColors.primary,
                            inactiveTrackColor: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                            thumbColor: AppColors.primary,
                            overlayColor: AppColors.primary.withOpacity(0.2),
                            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8),
                          ),
                          child: Slider(
                            value: inactivityDays.toDouble(),
                            min: 30,
                            max: 365,
                            divisions: 67,
                            onChanged: (val) => setState(() => inactivityDays = val.toInt()),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 32),
                  AppPrimaryButton(
                    text: 'Salvar Configurações',
                    onPressed: () {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Configurações salvas com sucesso!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required String title,
    required bool value,
    required Function(bool) onChanged,
    required bool isDark,
    bool isFirst = false,
    bool isLast = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 17,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          Switch(
            value: value,
            activeColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

// Reports Modal
class ReportsModal extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightBackground,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(25),
          topRight: Radius.circular(25),
        ),
      ),
      child: Column(
        children: [
          SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: 20),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(Icons.description, color: AppColors.primary, size: 28),
                SizedBox(width: 12),
                AppSectionTitle(text: 'Relatórios', fontSize: 28),
              ],
            ),
          ),
          SizedBox(height: 24),
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: 20),
              children: [
                _buildReportCard(
                  context: context,
                  title: 'Relatório de Usuários',
                  description: 'Lista completa de todos os usuários cadastrados',
                  color: Colors.blue,
                  isDark: isDark,
                ),
                SizedBox(height: 12),
                _buildReportCard(
                  context: context,
                  title: 'Relatório de Atividade',
                  description: 'Análise de atividade dos usuários por período',
                  color: Colors.green,
                  isDark: isDark,
                ),
                SizedBox(height: 12),
                _buildReportCard(
                  context: context,
                  title: 'Relatório de Tokens',
                  description: 'Uso e distribuição de tokens no sistema',
                  color: Colors.orange,
                  isDark: isDark,
                ),
                SizedBox(height: 12),
                _buildReportCard(
                  context: context,
                  title: 'Relatório de Segurança',
                  description: 'Tentativas de acesso e usuários bloqueados',
                  color: Colors.red,
                  isDark: isDark,
                ),
                SizedBox(height: 12),
                _buildReportCard(
                  context: context,
                  title: 'Relatório PRO',
                  description: 'Assinaturas PRO ativas e expiradas',
                  color: AppColors.primary,
                  isDark: isDark,
                ),
                SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildReportCard({
    required BuildContext context,
    required String title,
    required String description,
    required Color color,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: () {
        // Implementar ação do relatório
      },
      child: AppCard(
        padding: EdgeInsets.all(16),
        borderRadius: 16,
        child: Row(
          children: [
            Container(
              width: 4,
              height: 50,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}

// Keyboard Avoiding Widget
class KeyboardAvoiding extends StatelessWidget {
  final Widget child;

  const KeyboardAvoiding({required this.child, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 200),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: child,
    );
  }
}