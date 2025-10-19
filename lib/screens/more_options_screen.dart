import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/app_ui_components.dart';
import 'web_platform.dart';
import '../widgets/app_colors.dart';

class MoreOptionsScreen extends StatefulWidget {
  const MoreOptionsScreen({Key? key}) : super(key: key);

  @override
  State<MoreOptionsScreen> createState() => _MoreOptionsScreenState();
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
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              fullscreenDialog: true,
              builder: (context) => const MoreOptionsIntroScreen(),
            ),
          );
        }
      });
    }
  }

  void _showPlatformsSheet(BuildContext context, bool isDark) {
    AppBottomSheet.show(
      context,
      height: MediaQuery.of(context).size.height * 0.7,
      child: Column(
        children: [
          const SizedBox(height: 16),
          AppSectionTitle(
            text: 'Plataformas de Trading',
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildPlatformItem(
                  context: context,
                  name: 'Binance',
                  url: 'https://www.binance.com',
                  isDark: isDark,
                  faviconUrl: 'https://bin.bnbstatic.com/static/images/common/favicon.ico',
                ),
                const SizedBox(height: 12),
                _buildPlatformItem(
                  context: context,
                  name: 'Coinbase',
                  url: 'https://www.coinbase.com',
                  isDark: isDark,
                  faviconUrl: 'https://www.coinbase.com/favicon.ico',
                ),
                const SizedBox(height: 12),
                _buildPlatformItem(
                  context: context,
                  name: 'Kraken',
                  url: 'https://www.kraken.com',
                  isDark: isDark,
                  faviconUrl: 'https://www.kraken.com/favicon.ico',
                ),
                const SizedBox(height: 12),
                _buildPlatformItem(
                  context: context,
                  name: 'Bybit',
                  url: 'https://www.bybit.com',
                  isDark: isDark,
                  faviconUrl: 'https://www.bybit.com/favicon.ico',
                ),
                const SizedBox(height: 12),
                _buildPlatformItem(
                  context: context,
                  name: 'KuCoin',
                  url: 'https://www.kucoin.com',
                  isDark: isDark,
                  faviconUrl: 'https://www.kucoin.com/favicon.ico',
                ),
                const SizedBox(height: 12),
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
      borderRadius: BorderRadius.circular(16),
      child: AppCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : Colors.white,
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
                        color: AppColors.primary.withOpacity(0.2),
                        child: Icon(
                          Icons.language,
                          color: AppColors.primary,
                          size: 24,
                        ),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(AppColors.primary),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AppSectionTitle(
                  text: name,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Colors.grey,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppSecondaryAppBar(
        title: 'Mais Opções',
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  if (_recentPlatforms.isNotEmpty) ...[
                    const Text(
                      'RECENTEMENTE USADOS',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ..._recentPlatforms.map((platform) {
                      final lastUsed = (platform['lastUsed'] as Timestamp?)?.toDate();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
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
                          borderRadius: BorderRadius.circular(12),
                          child: AppCard(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: isDark ? AppColors.darkCard : AppColors.lightCard,
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
                                            color: AppColors.primary,
                                            size: 24,
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        AppSectionTitle(
                                          text: platform['name'],
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        if (lastUsed != null)
                                          Text(
                                            _getTimeAgo(lastUsed),
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.chevron_right,
                                    color: Colors.grey,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : Colors.white,
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    width: 0.5,
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: AppPrimaryButton(
                  text: 'Abrir Plataforma',
                  onPressed: () => _showPlatformsSheet(context, isDark),
                  height: 56,
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
  const MoreOptionsIntroScreen({Key? key}) : super(key: key);

  @override
  State<MoreOptionsIntroScreen> createState() => _MoreOptionsIntroScreenState();
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
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
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
      backgroundColor: isDark ? AppColors.darkBackground : Colors.white,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 50),
                  AppIconCircle(
                    icon: Icons.language,
                    size: 64,
                  ),
                  const SizedBox(height: 40),
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
                  const SizedBox(height: 20),
                  Text(
                    'Acesse plataformas de trading diretamente do app com segurança e privacidade.',
                    style: TextStyle(
                      fontSize: 18,
                      height: 1.6,
                      color: isDark ? Colors.white.withOpacity(0.85) : Colors.black.withOpacity(0.8),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 44),
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
                          const SizedBox(height: 28),
                          _buildInfoSection(
                            icon: Icons.history,
                            title: 'Histórico Pessoal',
                            description: 'Acompanhe suas plataformas recentemente usadas e tempo de uso.',
                            isDark: isDark,
                          ),
                          const SizedBox(height: 28),
                          _buildInfoSection(
                            icon: Icons.language,
                            title: 'Acesso Rápido',
                            description: 'Navegue entre múltiplas plataformas sem sair do app.',
                            isDark: isDark,
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20, top: 16),
                    child: AppPrimaryButton(
                      text: 'Começar',
                      onPressed: _handleDismiss,
                      height: 56,
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
          color: AppColors.primary,
          size: 28,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSectionTitle(
                text: title,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
              const SizedBox(height: 6),
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
    Key? key,
    required this.name,
    required this.url,
    required this.faviconUrl,
    required this.onContinue,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppSecondaryAppBar(
        title: name,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(28),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCard : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
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
                              color: AppColors.primary.withOpacity(0.2),
                              child: Icon(
                                Icons.language,
                                color: AppColors.primary,
                                size: 48,
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(AppColors.primary),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    AppSectionTitle(
                      text: name,
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                    ),
                    const SizedBox(height: 40),
                    _buildSection(
                      icon: Icons.check_circle_outline,
                      title: 'Vantagens',
                      description: 'Plataforma confiável com alta liquidez e diversas opções de trading.',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 24),
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
              padding: const EdgeInsets.all(16),
              child: SafeArea(
                top: false,
                child: AppPrimaryButton(
                  text: 'Continuar',
                  onPressed: () {
                    onContinue();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => WebPlatformScreen(url: url),
                      ),
                    );
                  },
                  height: 56,
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
          color: AppColors.primary,
          size: 28,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSectionTitle(
                text: title,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
              const SizedBox(height: 6),
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