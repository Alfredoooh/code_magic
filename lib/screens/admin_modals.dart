import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

// Statistics Modal
class StatisticsModal extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1C1C1E) : Color(0xFFF2F2F7),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.only(top: 8),
            width: 36,
            height: 5,
            decoration: BoxDecoration(
              color: isDark ? Color(0xFF48484A) : Color(0xFFD1D1D6),
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
          SizedBox(height: 20),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(CupertinoIcons.chart_bar_alt_fill, color: primaryColor, size: 28),
                SizedBox(width: 12),
                Text(
                  'Estatísticas',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CupertinoActivityIndicator());
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
                      color: CupertinoColors.systemBlue,
                      isDark: isDark,
                    ),
                    SizedBox(height: 12),
                    
                    // Gráfico de Usuários Ativos
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? Color(0xFF2C2C2E) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Usuários Ativos',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
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
                                    tooltipBgColor: isDark ? Color(0xFF3C3C3E) : Colors.grey[800],
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
                                      color: isDark ? Color(0xFF48484A) : Color(0xFFE5E5EA),
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
                                        color: CupertinoColors.systemGreen,
                                        width: 40,
                                        borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
                                      ),
                                    ],
                                  ),
                                  BarChartGroupData(
                                    x: 1,
                                    barRods: [
                                      BarChartRodData(
                                        toY: weeklyActive.toDouble(),
                                        color: CupertinoColors.systemBlue,
                                        width: 40,
                                        borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
                                      ),
                                    ],
                                  ),
                                  BarChartGroupData(
                                    x: 2,
                                    barRods: [
                                      BarChartRodData(
                                        toY: monthlyActive.toDouble(),
                                        color: CupertinoColors.systemOrange,
                                        width: 40,
                                        borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
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
                              _buildLegendItem('Diário', dailyActive, CupertinoColors.systemGreen, isDark),
                              _buildLegendItem('Semanal', weeklyActive, CupertinoColors.systemBlue, isDark),
                              _buildLegendItem('Mensal', monthlyActive, CupertinoColors.systemOrange, isDark),
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
                      color: CupertinoColors.systemGreen,
                      isDark: isDark,
                    ),
                    SizedBox(height: 12),
                    _buildStatCard(
                      title: 'Ativos Esta Semana',
                      value: weeklyActive.toString(),
                      subtitle: '${((weeklyActive / (totalUsers > 0 ? totalUsers : 1)) * 100).toStringAsFixed(1)}% do total',
                      color: CupertinoColors.systemBlue,
                      isDark: isDark,
                    ),
                    SizedBox(height: 12),
                    _buildStatCard(
                      title: 'Ativos Este Mês',
                      value: monthlyActive.toString(),
                      subtitle: '${((monthlyActive / (totalUsers > 0 ? totalUsers : 1)) * 100).toStringAsFixed(1)}% do total',
                      color: CupertinoColors.systemOrange,
                      isDark: isDark,
                    ),
                    SizedBox(height: 12),
                    _buildStatCard(
                      title: 'Usuários PRO',
                      value: proUsers.toString(),
                      subtitle: '${((proUsers / (totalUsers > 0 ? totalUsers : 1)) * 100).toStringAsFixed(1)}% do total',
                      color: Color(0xFFFF444F),
                      isDark: isDark,
                    ),
                    SizedBox(height: 12),
                    _buildStatCard(
                      title: 'Usuários Bloqueados',
                      value: blockedUsers.toString(),
                      subtitle: '${((blockedUsers / (totalUsers > 0 ? totalUsers : 1)) * 100).toStringAsFixed(1)}% do total',
                      color: CupertinoColors.systemRed,
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
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF2C2C2E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
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
    final primaryColor = Theme.of(context).primaryColor;
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1C1C1E) : Color(0xFFF2F2F7),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.only(top: 8),
            width: 36,
            height: 5,
            decoration: BoxDecoration(
              color: isDark ? Color(0xFF48484A) : Color(0xFFD1D1D6),
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
          SizedBox(height: 20),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(CupertinoIcons.settings_solid, color: primaryColor, size: 28),
                SizedBox(width: 12),
                Text(
                  'Configurações',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
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
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? Color(0xFF2C2C2E) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    children: [
                      _buildIOSSettingTile(
                        title: 'Permitir Novos Registros',
                        value: enableUserRegistration,
                        onChanged: (val) => setState(() => enableUserRegistration = val),
                        isDark: isDark,
                        primaryColor: primaryColor,
                        isFirst: true,
                      ),
                      Divider(height: 1, thickness: 0.5, indent: 16, color: isDark ? Color(0xFF48484A) : Color(0xFFE5E5EA)),
                      _buildIOSSettingTile(
                        title: 'Excluir Usuários Inativos',
                        value: autoDeleteInactiveUsers,
                        onChanged: (val) => setState(() => autoDeleteInactiveUsers = val),
                        isDark: isDark,
                        primaryColor: primaryColor,
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
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? Color(0xFF2C2C2E) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
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
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      SliderTheme(
                        data: SliderThemeData(
                          activeTrackColor: primaryColor,
                          inactiveTrackColor: isDark ? Color(0xFF48484A) : Color(0xFFE5E5EA),
                          thumbColor: primaryColor,
                          overlayColor: primaryColor.withOpacity(0.2),
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
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? Color(0xFF2C2C2E) : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
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
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      SliderTheme(
                        data: SliderThemeData(
                          activeTrackColor: primaryColor,
                          inactiveTrackColor: isDark ? Color(0xFF48484A) : Color(0xFFE5E5EA),
                          thumbColor: primaryColor,
                          overlayColor: primaryColor.withOpacity(0.2),
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
                CupertinoButton(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(10),
                  padding: EdgeInsets.symmetric(vertical: 14),
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Configurações salvas com sucesso!'),
                        backgroundColor: CupertinoColors.systemGreen,
                      ),
                    );
                  },
                  child: Text(
                    'Salvar Configurações',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIOSSettingTile({
    required String title,
    required bool value,
    required Function(bool) onChanged,
    required bool isDark,
    required Color primaryColor,
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
          CupertinoSwitch(
            value: value,
            activeColor: primaryColor,
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
    final primaryColor = Theme.of(context).primaryColor;
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: isDark ? Color(0xFF1C1C1E) : Color(0xFFF2F2F7),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Container(
            margin: EdgeInsets.only(top: 8),
            width: 36,
            height: 5,
            decoration: BoxDecoration(
              color: isDark ? Color(0xFF48484A) : Color(0xFFD1D1D6),
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),
          SizedBox(height: 20),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(CupertinoIcons.doc_text_fill, color: primaryColor, size: 28),
                SizedBox(width: 12),
                Text(
                  'Relatórios',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
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
                  color: CupertinoColors.systemBlue,
                  isDark: isDark,
                ),
                SizedBox(height: 12),
                _buildReportCard(
                  context: context,
                  title: 'Relatório de Atividade',
                  description: 'Análise de atividade dos usuários por período',
                  color: CupertinoColors.systemGreen,
                  isDark: isDark,
                ),
                SizedBox(height: 12),
                _buildReportCard(
                  context: context,
                  title: 'Relatório de Tokens',
                  description: 'Uso e distribuição de tokens no sistema',
                  color: CupertinoColors.systemOrange,
                  isDark: isDark,
                ),
                SizedBox(height: 12),
                _buildReportCard(
                  context: context,
                  title: 'Relatório de Segurança',
                  description: 'Tentativas de acesso e usuários bloqueados',
                  color: CupertinoColors.systemRed,
                  isDark: isDark,
                ),
                SizedBox(height: 12),
                _buildReportCard(
                  context: context,
                  title: 'Relatório PRO',
                  description: 'Assinaturas PRO ativas e expiradas',
                  color: Color(0xFFFF444F),
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
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Color(0xFF2C2C2E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
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
            Icon(CupertinoIcons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}