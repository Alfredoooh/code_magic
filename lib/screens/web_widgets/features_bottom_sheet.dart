import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class FeaturesBottomSheet extends StatelessWidget {
  final VoidCallback onPatternAnalysis;

  const FeaturesBottomSheet({
    Key? key,
    required this.onPatternAnalysis,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;

    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Funcionalidades',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.pop(context),
                  child: Icon(
                    CupertinoIcons.xmark_circle_fill,
                    color: Colors.grey,
                    size: 28,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildFeatureCard(
                  context,
                  icon: CupertinoIcons.chart_bar_alt_fill,
                  title: 'Analisar Padrão',
                  description: 'Analise padrões gráficos com ferramentas de desenho',
                  color: primaryColor,
                  onTap: onPatternAnalysis,
                ),
                SizedBox(height: 12),
                _buildFeatureCard(
                  context,
                  icon: CupertinoIcons.bookmark_fill,
                  title: 'Favoritos',
                  description: 'Salve seus sites favoritos para acesso rápido',
                  color: CupertinoColors.systemOrange,
                  onTap: () {
                    Navigator.pop(context);
                    // Implementar favoritos
                  },
                ),
                SizedBox(height: 12),
                _buildFeatureCard(
                  context,
                  icon: CupertinoIcons.clock_fill,
                  title: 'Histórico',
                  description: 'Veja o histórico de navegação',
                  color: CupertinoColors.systemPurple,
                  onTap: () {
                    Navigator.pop(context);
                    // Implementar histórico
                  },
                ),
                SizedBox(height: 12),
                _buildFeatureCard(
                  context,
                  icon: CupertinoIcons.gear_alt_fill,
                  title: 'Configurações',
                  description: 'Personalize sua experiência de navegação',
                  color: CupertinoColors.systemGrey,
                  onTap: () {
                    Navigator.pop(context);
                    // Implementar configurações
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Color(0xFF2C2C2E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: color,
                size: 26,
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
                  SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              color: Colors.grey,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}