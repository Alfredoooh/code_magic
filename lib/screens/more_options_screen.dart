import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'web_platform.dart';

class MoreOptionsScreen extends StatefulWidget {
  @override
  _MoreOptionsScreenState createState() => _MoreOptionsScreenState();
}

class _MoreOptionsScreenState extends State<MoreOptionsScreen> {
  @override
  void initState() {
    super.initState();
    _checkFirstTime();
  }

  Future<void> _checkFirstTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenIntro = prefs.getBool('hasSeenMoreOptionsIntro') ?? false;
    
    if (!hasSeenIntro) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).push(
          CupertinoPageRoute(
            fullscreenDialog: true,
            builder: (context) => MoreOptionsIntroScreen(),
          ),
        );
      });
    }
  }

  void _showPlatformsSheet(BuildContext context, bool isDark) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: isDark ? Color(0xFF1C1C1E) : CupertinoColors.white,
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
                color: CupertinoColors.systemGrey3,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Plataformas de Trading',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? CupertinoColors.white : CupertinoColors.black,
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
                    iconColor: Color(0xFFF3BA2F),
                  ),
                  SizedBox(height: 12),
                  _buildPlatformItem(
                    context: context,
                    name: 'Coinbase',
                    url: 'https://www.coinbase.com',
                    isDark: isDark,
                    iconColor: Color(0xFF0052FF),
                  ),
                  SizedBox(height: 12),
                  _buildPlatformItem(
                    context: context,
                    name: 'Kraken',
                    url: 'https://www.kraken.com',
                    isDark: isDark,
                    iconColor: Color(0xFF5741D9),
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
    required Color iconColor,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (context) => PlatformDetailScreen(
              name: name,
              url: url,
              iconColor: iconColor,
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
                color: iconColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  name[0],
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: iconColor,
                  ),
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
                  color: isDark ? CupertinoColors.white : CupertinoColors.black,
                ),
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              color: CupertinoColors.systemGrey,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  void _openFeature(BuildContext context, String title, IconData icon, bool isDark) {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => FeatureDetailScreen(
          title: title,
          icon: icon,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return CupertinoPageScaffold(
      backgroundColor: isDark ? Color(0xFF000000) : Color(0xFFF2F2F7),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: isDark ? Color(0xFF000000) : CupertinoColors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Color(0xFF1C1C1E) : Color(0xFFE5E5EA),
            width: 0.5,
          ),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CupertinoIcons.back,
                color: Color(0xFFFF444F),
                size: 24,
              ),
              SizedBox(width: 4),
              Text(
                'Voltar',
                style: TextStyle(
                  color: Color(0xFFFF444F),
                  fontSize: 17,
                ),
              ),
            ],
          ),
          onPressed: () => Navigator.pop(context),
        ),
        middle: Text(
          'Mais Opções',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: isDark ? CupertinoColors.white : CupertinoColors.black,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.all(16),
                children: [
                  // Features List
                  Text(
                    'FUNCIONALIDADES',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: CupertinoColors.systemGrey,
                      letterSpacing: 0.5,
                    ),
                  ),
                  SizedBox(height: 12),
                  _buildFeatureCard(
                    context: context,
                    icon: CupertinoIcons.chart_bar_alt_fill,
                    title: 'Análise de Mercado',
                    subtitle: 'Ferramentas avançadas',
                    onTap: () => _openFeature(context, 'Análise de Mercado', CupertinoIcons.chart_bar_alt_fill, isDark),
                    isDark: isDark,
                  ),
                  SizedBox(height: 12),
                  _buildFeatureCard(
                    context: context,
                    icon: CupertinoIcons.bell_fill,
                    title: 'Alertas de Preço',
                    subtitle: 'Notificações personalizadas',
                    onTap: () => _openFeature(context, 'Alertas de Preço', CupertinoIcons.bell_fill, isDark),
                    isDark: isDark,
                  ),
                  SizedBox(height: 12),
                  _buildFeatureCard(
                    context: context,
                    icon: CupertinoIcons.briefcase_fill,
                    title: 'Gestão de Portfolio',
                    subtitle: 'Acompanhe seus investimentos',
                    onTap: () => _openFeature(context, 'Gestão de Portfolio', CupertinoIcons.briefcase_fill, isDark),
                    isDark: isDark,
                  ),
                ],
              ),
            ),
            
            // Bottom Button
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Color(0xFF1C1C1E) : CupertinoColors.white,
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
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    borderRadius: BorderRadius.circular(14),
                    color: Color(0xFFFF444F),
                    onPressed: () => _showPlatformsSheet(context, isDark),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          CupertinoIcons.globe,
                          color: CupertinoColors.white,
                          size: 24,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Abrir Plataforma',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: CupertinoColors.white,
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

  Widget _buildFeatureCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Color(0xFF1C1C1E) : CupertinoColors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
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
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? CupertinoColors.white : CupertinoColors.black,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: CupertinoColors.systemGrey,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              color: CupertinoColors.systemGrey,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// Intro Screen
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
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

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
                    CupertinoIcons.globe,
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
                    'Explore funcionalidades avançadas e acesse plataformas de trading diretamente do app.',
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
                            icon: CupertinoIcons.chart_bar_alt_fill,
                            title: 'Análise Avançada',
                            description: 'Ferramentas profissionais para análise técnica e fundamental do mercado.',
                            isDark: isDark,
                          ),
                          
                          SizedBox(height: 28),
                          
                          _buildInfoSection(
                            icon: CupertinoIcons.globe,
                            title: 'Plataformas Integradas',
                            description: 'Acesse diversas corretoras e plataformas de trading sem sair do app.',
                            isDark: isDark,
                          ),
                          
                          SizedBox(height: 28),
                          
                          _buildInfoSection(
                            icon: CupertinoIcons.bell_fill,
                            title: 'Alertas Personalizados',
                            description: 'Configure notificações para acompanhar movimentos de preços importantes.',
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
                        onPressed: _handleDismiss,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFFF444F),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
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

// Feature Detail Screen
class FeatureDetailScreen extends StatelessWidget {
  final String title;
  final IconData icon;

  const FeatureDetailScreen({
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return CupertinoPageScaffold(
      backgroundColor: isDark ? Color(0xFF000000) : Color(0xFFF2F2F7),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Color(0xFFFF444F).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        icon,
                        size: 50,
                        color: Color(0xFFFF444F),
                      ),
                    ),
                    SizedBox(height: 24),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: isDark ? CupertinoColors.white : CupertinoColors.black,
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        'Em breve disponível',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 17,
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
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
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    borderRadius: BorderRadius.circular(14),
                    color: Color(0xFFFF444F),
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Voltar',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.white,
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
}

// Platform Detail Screen
class PlatformDetailScreen extends StatelessWidget {
  final String name;
  final String url;
  final Color iconColor;

  const PlatformDetailScreen({
    required this.name,
    required this.url,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;

    return CupertinoPageScaffold(
      backgroundColor: isDark ? Color(0xFF000000) : Color(0xFFF2F2F7),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: isDark ? Color(0xFF000000) : CupertinoColors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Color(0xFF1C1C1E) : Color(0xFFE5E5EA),
            width: 0.5,
          ),
        ),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CupertinoIcons.back,
                color: Color(0xFFFF444F),
                size: 24,
              ),
              SizedBox(width: 4),
              Text(
                'Voltar',
                style: TextStyle(
                  color: Color(0xFFFF444F),
                  fontSize: 17,
                ),
              ),
            ],
          ),
          onPressed: () => Navigator.pop(context),
        ),
        middle: Text(
          name,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: isDark ? CupertinoColors.white : CupertinoColors.black,
          ),
        ),
      ),
      child: SafeArea(
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
                        color: iconColor.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          name[0],
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.w700,
                            color: iconColor,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 32),
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: isDark ? CupertinoColors.white : CupertinoColors.black,
                      ),
                    ),
                    SizedBox(height: 40),
                    _buildSection(
                      icon: CupertinoIcons.checkmark_shield_fill,
                      title: 'Vantagens',
                      description: 'Plataforma confiável com alta liquidez e diversas opções de trading.',
                      isDark: isDark,
                    ),
                    SizedBox(height: 24),
                    _buildSection(
                      icon: CupertinoIcons.info_circle_fill,
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
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    borderRadius: BorderRadius.circular(14),
                    color: Color(0xFFFF444F),
                    onPressed: () {
                      Navigator.push(
                        context,
                        CupertinoPageRoute(
                          builder: (context) => WebPlatformScreen(url: url),
                        ),
                      );
                    },
                    child: Text(
                      'Continuar',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: CupertinoColors.white,
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