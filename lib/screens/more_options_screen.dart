import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'web_platform.dart';

class MoreOptionsScreen extends StatefulWidget {
  @override
  _MoreOptionsScreenState createState() => _MoreOptionsScreenState();
}

class _MoreOptionsScreenState extends State<MoreOptionsScreen> {
  bool _hasShownIntro = false;
  List<Map<String, dynamic>> _recentPlatforms = [];
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
    _checkFirstTime();
  }

  void _getCurrentUser() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() => _currentUserId = user.uid);
      _loadRecentPlatforms();
    }
  }

  Future<void> _loadRecentPlatforms() async {
    if (_currentUserId == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('user_platforms')
        .doc(_currentUserId)
        .get();

    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      final platforms = List<Map<String, dynamic>>.from(data['recent'] ?? []);
      
      platforms.sort((a, b) {
        final aTime = (a['lastUsed'] as Timestamp?)?.toDate() ?? DateTime(2000);
        final bTime = (b['lastUsed'] as Timestamp?)?.toDate() ?? DateTime(2000);
        return bTime.compareTo(aTime);
      });

      if (mounted) {
        setState(() => _recentPlatforms = platforms.take(3).toList());
      }
    }
  }

  Future<void> _savePlatformUsage(String name, String url, String faviconUrl) async {
    if (_currentUserId == null) return;

    final docRef = FirebaseFirestore.instance
        .collection('user_platforms')
        .doc(_currentUserId);

    final doc = await docRef.get();
    List<Map<String, dynamic>> platforms = [];

    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      platforms = List<Map<String, dynamic>>.from(data['recent'] ?? []);
    }

    platforms.removeWhere((p) => p['name'] == name);

    platforms.insert(0, {
      'name': name,
      'url': url,
      'faviconUrl': faviconUrl,
      'lastUsed': FieldValue.serverTimestamp(),
    });

    if (platforms.length > 10) {
      platforms = platforms.sublist(0, 10);
    }

    await docRef.set({
      'recent': platforms,
      'userId': _currentUserId,
    }, SetOptions(merge: true));

    _loadRecentPlatforms();
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Agora mesmo';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m atrás';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h atrás';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d atrás';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks sem atrás';
    } else {
      final months = (difference.inDays / 30).floor();
      return '$months mês${months > 1 ? 'es' : ''} atrás';
    }
  }

  Future<void> _checkFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenIntro = prefs.getBool('hasSeenMoreOptionsIntro') ?? false;

    if (!hasSeenIntro && !_hasShownIntro && mounted) {
      _hasShownIntro = true;
      Future.delayed(Duration(milliseconds: 300), () {
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              fullscreenDialog: true,
              builder: (context) => MoreOptionsIntroScreen(),
            ),
          );
        }
      });
    }
  }

  void _showPlatformsSheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: isDark ? Color(0xFF1C1C1E) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            SizedBox(height: 12),
            Container(
              width: 36,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Plataformas de Trading',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildPlatformItem(
                    context: context,
                    name: 'Binance',
                    url: 'https://www.binance.com',
                    isDark: isDark,
                    faviconUrl: 'https://bin.bnbstatic.com/static/images/common/favicon.ico',
                  ),
                  SizedBox(height: 12),
                  _buildPlatformItem(
                    context: context,
                    name: 'Coinbase',
                    url: 'https://www.coinbase.com',
                    isDark: isDark,
                    faviconUrl: 'https://www.coinbase.com/favicon.ico',
                  ),
                  SizedBox(height: 12),
                  _buildPlatformItem(
                    context: context,
                    name: 'Kraken',
                    url: 'https://www.kraken.com',
                    isDark: isDark,
                    faviconUrl: 'https://www.kraken.com/favicon.ico',
                  ),
                  SizedBox(height: 12),
                  _buildPlatformItem(
                    context: context,
                    name: 'Bybit',
                    url: 'https://www.bybit.com',
                    isDark: isDark,
                    faviconUrl: 'https://www.bybit.com/favicon.ico',
                  ),
                  SizedBox(height: 12),
                  _buildPlatformItem(
                    context: context,
                    name: 'KuCoin',
                    url: 'https://www.kucoin.com',
                    isDark: isDark,
                    faviconUrl: 'https://www.kucoin.com/favicon.ico',
                  ),
                  SizedBox(height: 12),
                  _buildPlatformItem(
                    context: context,
                    name: 'OKX',
                    url: 'https://www.okx.com',
                    isDark: isDark,
                    faviconUrl: 'https://www.okx.com/favicon.ico',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformItem({
    required BuildContext context,
    required String name,
    required String url,
    required bool isDark,
    required String faviconUrl,
  }) {
    return InkWell(
      onTap: () async {
        Navigator.pop(context);
        await _savePlatformUsage(name, url, faviconUrl);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlatformDetailScreen(
              name: name,
              url: url,
              faviconUrl: faviconUrl,
              onContinue: () => _savePlatformUsage(name, url, faviconUrl),
            ),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Color(0xFF2C2C2E) : Color(0xFFF2F2F7),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isDark ? Color(0xFF1C1C1E) : Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  faviconUrl,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Color(0xFFFF444F).withOpacity(0.2),
                      child: Icon(
                        Icons.language,
                        color: Color(0xFFFF444F),
                        size: 24,
                      ),
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Color(0xFFFF444F)),
                      ),
                    );
                  },
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Color(0xFF000000) : Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: isDark ? Color(0xFF000000) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: Color(0xFFFF444F),
            size: 24,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Mais Opções',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Container(
            color: isDark ? Color(0xFF1C1C1E) : Color(0xFFE5E5EA),
            height: 0.5,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.all(16),
                children: [
                  if (_recentPlatforms.isNotEmpty) ...[
                    Text(
                      'RECENTEMENTE USADOS',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 12),
                    ..._recentPlatforms.map((platform) {
                      final lastUsed = (platform['lastUsed'] as Timestamp?)?.toDate();
                      return Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          onTap: () async {
                            await _savePlatformUsage(
                              platform['name'],
                              platform['url'],
                              platform['faviconUrl'],
                            );
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => WebPlatformScreen(
                                  url: platform['url'],
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? Color(0xFF1C1C1E) : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: isDark ? Color(0xFF2C2C2E) : Color(0xFFF2F2F7),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      platform['faviconUrl'],
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return Icon(
                                          Icons.language,
                                          color: Color(0xFFFF444F),
                                          size: 24,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        platform['name'],
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? Colors.white : Colors.black,
                                        ),
                                      ),
                                      if (lastUsed != null)
                                        Text(
                                          _getTimeAgo(lastUsed),
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  color: Colors.grey,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                    SizedBox(height: 24),
                  ],
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Color(0xFF1C1C1E) : Colors.white,
                border: Border(
                  top: BorderSide(
                    color: isDark ? Color(0xFF2C2C2E) : Color(0xFFE5E5EA),
                    width: 0.5,
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFFF444F),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    onPressed: () => _showPlatformsSheet(context, isDark),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.language, size: 24),
                        SizedBox(width: 12),
                        Text(
                          'Abrir Plataforma',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MoreOptionsIntroScreen extends StatefulWidget {
  @override
  _MoreOptionsIntroScreenState createState() => _MoreOptionsIntroScreenState();
}

class _MoreOptionsIntroScreenState extends State<MoreOptionsIntroScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Interval(0.0, 0.5, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleDismiss() async {
    await _controller.reverse();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenMoreOptionsIntro', true);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Color(0xFF000000) : Colors.white,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 50),
                  Icon(
                    Icons.language,
                    color: Color(0xFFFF444F),
                    size: 64,
                  ),
                  SizedBox(height: 40),
                  Text(
                    'Bem-vindo às\nMais Opções',
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                      letterSpacing: -1,
                      height: 1.1,
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Acesse plataformas de trading diretamente do app com segurança e privacidade.',
                    style: TextStyle(
                      fontSize: 18,
                      height: 1.6,
                      color: isDark ? Colors.white.withOpacity(0.85) : Colors.black.withOpacity(0.8),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(height: 44),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          _buildInfoSection(
                            icon: Icons.lock_outline,
                            title: 'Dados Seguros',
                            description: 'Suas atividades são armazenadas com segurança e isoladas por usuário.',
                            isDark: isDark,
                          ),
                          SizedBox(height: 28),
                          _buildInfoSection(
                            icon: Icons.history,
                            title: 'Histórico Pessoal',
                            description: 'Acompanhe suas plataformas recentemente usadas e tempo de uso.',
                            isDark: isDark,
                          ),
                          SizedBox(height: 28),
                          _buildInfoSection(
                            icon: Icons.language,
                            title: 'Acesso Rápido',
                            description: 'Navegue entre múltiplas plataformas sem sair do app.',
                            isDark: isDark,
                          ),
                          SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(bottom: 20, top: 16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFFF444F),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _handleDismiss,
                        child: Text(
                          'Começar',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection({
    required IconData icon,
    required String title,
    required String description,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: Color(0xFFFF444F),
          size: 28,
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
                  color: isDark ? Colors.white : Colors.black,
                  letterSpacing: -0.2,
                ),
              ),
              SizedBox(height: 6),
              Text(
                description,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: isDark ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.65),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class PlatformDetailScreen extends StatelessWidget {
  final String name;
  final String url;
  final String faviconUrl;
  final VoidCallback onContinue;

  const PlatformDetailScreen({
    required this.name,
    required this.url,
    required this.faviconUrl,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Color(0xFF000000) : Color(0xFFF2F2F7),
      appBar: AppBar(
        backgroundColor: isDark ? Color(0xFF000000) : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: Color(0xFFFF444F),
            size: 24,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          name,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Container(
            color: isDark ? Color(0xFF1C1C1E) : Color(0xFFE5E5EA),
            height: 0.5,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(28),
                child: Column(
                  children: [
                    SizedBox(height: 20),
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: isDark ? Color(0xFF1C1C1E) : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Image.network(
                          faviconUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Color(0xFFFF444F).withOpacity(0.2),
                              child: Icon(
                                Icons.language,
                                color: Color(0xFFFF444F),
                                size: 48,
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(Color(0xFFFF444F)),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    SizedBox(height: 32),
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    SizedBox(height: 40),
                    _buildSection(
                      icon: Icons.check_circle_outline,
                      title: 'Vantagens',
                      description: 'Plataforma confiável com alta liquidez e diversas opções de trading.',
                      isDark: isDark,
                    ),
                    SizedBox(height: 24),
                    _buildSection(
                      icon: Icons.info_outline,
                      title: 'Considerações',
                      description: 'Verifique as taxas e regulamentações aplicáveis na sua região.',
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.all(16),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFFF444F),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    onPressed: () {
                      onContinue();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => WebPlatformScreen(url: url),
                        ),
                      );
                    },
                    child: Text(
                      'Continuar',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required String description,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: Color(0xFFFF444F),
          size: 28,
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
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              SizedBox(height: 6),
              Text(
                description,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: isDark ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.65),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}