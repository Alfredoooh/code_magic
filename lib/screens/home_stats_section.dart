// lib/screens/home_stats_section.dart
import 'package:flutter/material.dart';
import '../widgets/app_ui_components.dart';

class HomeStatsSection extends StatelessWidget {
  final int messageCount;
  final int groupCount;
  final bool isDark;

  const HomeStatsSection({
    required this.messageCount,
    required this.groupCount,
    required this.isDark,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.chat_bubble,
            title: 'Mensagens',
            value: '$messageCount',
            color: Colors.blue,
            isLeft: true,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.group,
            title: 'Grupos',
            value: '$groupCount',
            color: Colors.green,
            isLeft: false,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required bool isLeft,
  }) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.only(
          topLeft: isLeft ? Radius.circular(25) : Radius.circular(1),
          bottomLeft: isLeft ? Radius.circular(25) : Radius.circular(1),
          topRight: !isLeft ? Radius.circular(25) : Radius.circular(1),
          bottomRight: !isLeft ? Radius.circular(25) : Radius.circular(1),
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(width: 8),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}