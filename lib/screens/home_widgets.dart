// lib/screens/home_widgets.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import '../widgets/app_ui_components.dart';
import '../models/news_article.dart';
import 'news_detail_screen.dart';

class HomeWidgets {
  // ==================== CRYPTO ICONS ====================
  
  static const Map<String, String> _cryptoNames = {
    'btc': 'bitcoin',
    'eth': 'ethereum',
    'bnb': 'bnb',
    'sol': 'solana',
    'xrp': 'xrp',
    'ada': 'cardano',
    'doge': 'dogecoin',
    'dot': 'polkadot',
    'matic': 'polygon',
    'ltc': 'litecoin',
    'trx': 'tron',
    'avax': 'avalanche',
    'link': 'chainlink',
    'uni': 'uniswap',
    'atom': 'cosmos',
  };

  static String getCryptoIcon(String symbol) {
    final clean = symbol.replaceAll('USDT', '').toLowerCase();
    final name = _cryptoNames[clean] ?? clean;
    return 'https://cryptologos.cc/logos/$name-$clean-logo.png';
  }

  static Widget buildCryptoIcon(String symbol, {double size = 32}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 2),
      child: Image.network(
        getCryptoIcon(symbol),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.currency_bitcoin,
            color: AppColors.primary,
            size: size * 0.6,
          ),
        ),
      ),
    );
  }

  // ==================== PROFILE AVATAR ====================
  
  static Widget buildProfileAvatar({
    required String? profileImage,
    required String username,
    required VoidCallback onTap,
    double radius = 18,
  }) {
    final imageProvider = _getProfileImage(profileImage);

    return Padding(
      padding: EdgeInsets.only(right: 16),
      child: GestureDetector(
        onTap: onTap,
        child: CircleAvatar(
          radius: radius,
          backgroundColor: AppColors.primary,
          backgroundImage: imageProvider,
          child: imageProvider == null
              ? Text(
                  username.isNotEmpty ? username[0].toUpperCase() : 'U',
                  style: TextStyle(
                    fontSize: radius * 0.8,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                )
              : null,
        ),
      ),
    );
  }

  static ImageProvider? _getProfileImage(String? profileImage) {
    if (profileImage == null || profileImage.isEmpty) return null;

    if (profileImage.startsWith('data:image')) {
      try {
        final bytes = base64Decode(profileImage.split(',')[1]);
        return MemoryImage(bytes);
      } catch (_) {
        return null;
      }
    }

    return NetworkImage(profileImage);
  }

  // ==================== PAGE INDICATOR ====================
  
  static Widget buildPageIndicator({
    required int count,
    required int currentPage,
    required bool isDark,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final isActive = currentPage == i;
        return AnimatedContainer(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          width: isActive ? 24 : 8,
          height: 8,
          margin: EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : Colors.grey.withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
            boxShadow: isActive ? [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ] : null,
          ),
        );
      }),
    );
  }

  // ==================== STATS CARD ====================
  
  static Widget buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return AppCard(
      padding: EdgeInsets.all(20),
      borderRadius: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primary, size: 28),
          ),
          SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black,
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== NEWS CARD ====================
  
  static Widget buildNewsCard({
    required NewsArticle article,
    required int index,
    required bool isDark,
    required BuildContext context,
    required List<NewsArticle> allArticles,
  }) {
    return GestureDetector(
      onTap: () => _navigateToNewsDetail(context, article, allArticles, index),
      child: AppCard(
        padding: EdgeInsets.zero,
        borderRadius: 24,
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: _buildNewsContent(article, isDark),
              ),
            ),
            if (article.imageUrl.isNotEmpty)
              _buildNewsImage(article, isDark),
          ],
        ),
      ),
    );
  }

  static Widget _buildNewsContent(NewsArticle article, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Notícia',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
        SizedBox(height: 12),
        Text(
          article.title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black,
            height: 1.3,
            letterSpacing: -0.2,
          ),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 8),
        Text(
          article.description,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
            height: 1.3,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.access_time, size: 12, color: Colors.grey),
            SizedBox(width: 4),
            Text(
              'Há 2 horas',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ],
    );
  }

  static Widget _buildNewsImage(NewsArticle article, bool isDark) {
    return Container(
      width: 120,
      height: 160,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
            child: Image.network(
              article.imageUrl,
              width: 120,
              height: 160,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: isDark ? Color(0xFF0E0E0E) : Color(0xFFF2F2F7),
                child: Icon(Icons.photo, color: Colors.grey, size: 40),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Colors.black.withOpacity(0.3)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.only(
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Icon(
                Icons.arrow_forward_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static void _navigateToNewsDetail(
    BuildContext context,
    NewsArticle article,
    List<NewsArticle> allArticles,
    int index,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NewsDetailScreen(
          article: article,
          allArticles: allArticles,
          currentIndex: index,
        ),
        fullscreenDialog: true,
      ),
    );
  }

  // ==================== CRYPTO CARD ====================
  
  static Widget buildCryptoCard({
    required String symbol,
    required String name,
    required double price,
    required double change,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final isPositive = change >= 0;

    return GestureDetector(
      onTap: onTap,
      child: AppCard(
        padding: EdgeInsets.all(16),
        borderRadius: 20,
        child: Row(
          children: [
            buildCryptoIcon(symbol, size: 40),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    symbol.replaceAll('USDT', ''),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  Text(
                    name,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${price.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                _buildChangeIndicator(change, isPositive),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildChangeIndicator(double change, bool isPositive) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (isPositive ? Colors.green : Colors.red).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isPositive ? Icons.arrow_upward : Icons.arrow_downward,
            size: 12,
            color: isPositive ? Colors.green : Colors.red,
          ),
          SizedBox(width: 4),
          Text(
            '${change.abs().toStringAsFixed(2)}%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isPositive ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== QUICK ACTION BUTTON ====================
  
  static Widget buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AppCard(
        padding: EdgeInsets.all(16),
        borderRadius: 20,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: AppColors.primary, size: 28),
            ),
            SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ==================== PROMO CARD ====================
  
  static Widget buildPromoCard({
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 16,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                      height: 1.3,
                    ),
                  ),
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Explorar',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward, color: Colors.white, size: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 16),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, color: Colors.white, size: 40),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== EMPTY STATE ====================
  
  static Widget buildEmptyState({
    required String message,
    IconData icon = Icons.inbox_outlined,
    VoidCallback? onAction,
    String? actionText,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey.withOpacity(0.5)),
          SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
          if (onAction != null && actionText != null) ...[
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(actionText),
            ),
          ],
        ],
      ),
    );
  }

  // ==================== NOTIFICATION BADGE ====================
  
  static Widget buildNotificationBadge({
    required int count,
  }) {
    if (count == 0) return SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.red,
        borderRadius: BorderRadius.circular(10),
      ),
      constraints: BoxConstraints(minWidth: 18, minHeight: 18),
      child: Center(
        child: Text(
          count > 99 ? '99+' : count.toString(),
          style: TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}