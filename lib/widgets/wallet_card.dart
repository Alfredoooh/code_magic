import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'app_ui_components.dart';

class WalletCard extends StatelessWidget {
  final Map<String, dynamic>? userData;
  final String cardStyle;
  final Function(String)? onStyleChanged;
  final bool showCustomizeButton;

  const WalletCard({
    required this.userData,
    required this.cardStyle,
    this.onStyleChanged,
    this.showCustomizeButton = true,
    Key? key,
  }) : super(key: key);

  void _showCardStylePicker(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    AppBottomSheet.show(
      context,
      height: 500,
      child: Column(
        children: [
          const SizedBox(height: 16),
          AppSectionTitle(
            text: 'Escolha o Estilo do Cartão',
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.count(
              padding: const EdgeInsets.all(16),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.1,
              children: [
                _buildStyleOption(context, 'aurora', 'Aurora', Icons.auto_awesome, isDark),
                _buildStyleOption(context, 'ocean', 'Ocean', Icons.waves, isDark),
                _buildStyleOption(context, 'carbon', 'Carbon', Icons.layers, isDark),
                _buildStyleOption(context, 'sunset', 'Sunset', Icons.wb_sunny, isDark),
                _buildStyleOption(context, 'midnight', 'Midnight', Icons.nightlight, isDark),
                _buildStyleOption(context, 'emerald', 'Emerald', Icons.eco, isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStyleOption(BuildContext context, String style, String name, IconData icon, bool isDark) {
    final isSelected = cardStyle == style;

    return GestureDetector(
      onTap: () async {
        onStyleChanged?.call(style);
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({'cardStyle': style});
        }
        Navigator.pop(context);
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.primary.withOpacity(0.2)
              : (isDark ? AppColors.darkCard : AppColors.lightCard),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 36,
              color: isSelected ? AppColors.primary : Colors.grey,
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected 
                    ? AppColors.primary 
                    : (isDark ? Colors.white : Colors.black),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (cardStyle) {
      case 'aurora':
        return _buildAuroraCard(context);
      case 'ocean':
        return _buildOceanCard(context);
      case 'carbon':
        return _buildCarbonCard(context);
      case 'sunset':
        return _buildSunsetCard(context);
      case 'midnight':
        return _buildMidnightCard(context);
      case 'emerald':
        return _buildEmeraldCard(context);
      default:
        return _buildAuroraCard(context);
    }
  }

  // Aurora Card - Rosa/Vermelho suave
  Widget _buildAuroraCard(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.primary,
          ),
          child: _buildCardContent(context, Colors.white),
        ),
      ),
    );
  }

  // Ocean Card - Azul claro
  Widget _buildOceanCard(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF06B6D4).withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF06B6D4),
          ),
          child: _buildCardContent(context, Colors.white),
        ),
      ),
    );
  }

  // Carbon Card - Cinza escuro
  Widget _buildCarbonCard(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A1A),
          ),
          child: _buildCardContent(context, Colors.white),
        ),
      ),
    );
  }

  // Sunset Card - Laranja suave
  Widget _buildSunsetCard(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF97316).withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF97316),
          ),
          child: _buildCardContent(context, Colors.white),
        ),
      ),
    );
  }

  // Midnight Card - Azul marinho
  Widget _buildMidnightCard(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1E3A8A),
          ),
          child: _buildCardContent(context, Colors.white),
        ),
      ),
    );
  }

  // Emerald Card - Verde esmeralda
  Widget _buildEmeraldCard(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: const BoxDecoration(
            color: Color(0xFF10B981),
          ),
          child: _buildCardContent(context, Colors.white),
        ),
      ),
    );
  }

  Widget _buildCardContent(BuildContext context, Color textColor) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TOKENS',
                    style: TextStyle(
                      color: textColor.withOpacity(0.7),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .doc(FirebaseAuth.instance.currentUser?.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      final tokens = snapshot.data?.data() != null
                          ? (snapshot.data!.data() as Map<String, dynamic>)['tokens'] ?? 0
                          : 0;
                      return Text(
                        '$tokens',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 52,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                          height: 1,
                        ),
                      );
                    },
                  ),
                ],
              ),
              Visibility(
                visible: showCustomizeButton,
                child: GestureDetector(
                  onTap: () => _showCardStylePicker(context),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.tune,
                      color: textColor,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (userData?['pro'] == true)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, color: textColor, size: 12),
                      const SizedBox(width: 6),
                      Text(
                        'PRO MEMBER',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${_getExpirationDays()} DIAS',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              Text(
                (userData?['username'] ?? 'UTILIZADOR').toUpperCase(),
                style: TextStyle(
                  color: textColor.withOpacity(0.95),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getExpirationDays() {
    if (userData?['expiration_date'] == null) return '0';
    try {
      final date = DateTime.parse(userData!['expiration_date']);
      final diff = date.difference(DateTime.now()).inDays;
      return diff > 0 ? '$diff' : '0';
    } catch (e) {
      return '0';
    }
  }
}