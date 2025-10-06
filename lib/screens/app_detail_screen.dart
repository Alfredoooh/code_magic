import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../models/app_model.dart';
import '../services/app_service.dart';
import 'webview_screen.dart';

class AppDetailScreen extends StatefulWidget {
  final AppModel app;

  const AppDetailScreen({Key? key, required this.app}) : super(key: key);

  @override
  State<AppDetailScreen> createState() => _AppDetailScreenState();
}

class _AppDetailScreenState extends State<AppDetailScreen> with TickerProviderStateMixin {
  final AppService _appService = AppService();
  bool _isFavorite = false;
  late AnimationController _favoriteAnimationController;
  late AnimationController _shareAnimationController;
  late Animation<double> _favoriteScaleAnimation;
  late Animation<double> _shareScaleAnimation;

  @override
  void initState() {
    super.initState();
    _loadFavoriteStatus();
    _setupAnimations();
  }

  void _setupAnimations() {
    _favoriteAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _shareAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _favoriteScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeInBack)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.2).chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 10,
      ),
    ]).animate(_favoriteAnimationController);

    _shareScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.8),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.8, end: 1.0),
        weight: 50,
      ),
    ]).animate(_shareAnimationController);
  }

  @override
  void dispose() {
    _favoriteAnimationController.dispose();
    _shareAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadFavoriteStatus() async {
    final isFav = await _appService.isFavorite(widget.app.id);
    setState(() => _isFavorite = isFav);
  }

  Future<void> _toggleFavorite() async {
    HapticFeedback.mediumImpact();
    _favoriteAnimationController.forward(from: 0.0);
    await _appService.toggleFavorite(widget.app.id);
    setState(() => _isFavorite = !_isFavorite);
  }

  void _handleShare() {
    HapticFeedback.lightImpact();
    _shareAnimationController.forward(from: 0.0);
  }

  void _openWebView() {
    HapticFeedback.lightImpact();
    _appService.recordAppUsage(widget.app.id);
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => WebViewScreen(
          url: widget.app.webviewUrl,
          title: widget.app.name,
        ),
      ),
    );
  }

  void _openScreenshotFullscreen(int index) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (context, animation, secondaryAnimation) {
          return ScreenshotFullscreenViewer(
            screenshots: widget.app.screenshots,
            initialIndex: index,
          );
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 0,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFF000000),
            elevation: 0,
            leading: IconButton(
              icon: const Icon(CupertinoIcons.back, color: Color(0xFF007AFF), size: 24),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              AnimatedBuilder(
                animation: _favoriteScaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _favoriteScaleAnimation.value,
                    child: IconButton(
                      icon: Icon(
                        _isFavorite ? CupertinoIcons.heart_fill : CupertinoIcons.heart,
                        color: _isFavorite ? const Color(0xFFFF3B30) : Colors.white,
                        size: 24,
                      ),
                      onPressed: _toggleFavorite,
                    ),
                  );
                },
              ),
              AnimatedBuilder(
                animation: _shareScaleAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _shareScaleAnimation.value,
                    child: IconButton(
                      icon: const Icon(CupertinoIcons.share, color: Colors.white, size: 24),
                      onPressed: _handleShare,
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                _buildHeader(),
                const SizedBox(height: 32),
                _buildActionButton(),
                const SizedBox(height: 32),
                _buildQuickInfo(),
                const SizedBox(height: 32),
                _buildScreenshots(),
                const SizedBox(height: 32),
                _buildDescription(),
                const SizedBox(height: 32),
                _buildFeatures(),
                const SizedBox(height: 32),
                _buildInformation(),
                const SizedBox(height: 32),
                _buildRatingsReviews(),
                const SizedBox(height: 32),
                _buildDeveloperSection(),
                const SizedBox(height: 32),
                _buildPrivacySection(),
                const SizedBox(height: 32),
                _buildSupportSection(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Center(
            child: Hero(
              tag: 'app_icon_${widget.app.id}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Image.network(
                  widget.app.iconUrl,
                  width: 130,
                  height: 130,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 130,
                    height: 130,
                    color: const Color(0xFF1C1C1E),
                    child: const Icon(CupertinoIcons.app, color: Colors.white, size: 24),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            widget.app.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.app.developer,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF8E8E93),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.app.category,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF8E8E93),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: CupertinoButton(
          padding: EdgeInsets.zero,
          color: const Color(0xFF007AFF),
          borderRadius: BorderRadius.circular(14),
          onPressed: _openWebView,
          child: const Text(
            'ABRIR',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickInfo() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildQuickInfoItem(
            '${widget.app.reviewCount}',
            'Avaliações',
            CupertinoIcons.chart_bar_alt_fill,
          ),
          Container(
            width: 1,
            height: 40,
            color: const Color(0xFF2C2C2E),
          ),
          _buildQuickInfoItem(
            widget.app.rating.toStringAsFixed(1),
            'Nota',
            CupertinoIcons.star_fill,
          ),
          Container(
            width: 1,
            height: 40,
            color: const Color(0xFF2C2C2E),
          ),
          _buildQuickInfoItem(
            widget.app.ageRating,
            'Idade',
            CupertinoIcons.person_fill,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickInfoItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF8E8E93), size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF8E8E93),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildScreenshots() {
    if (widget.app.screenshots.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Capturas de Tela',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 420,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: widget.app.screenshots.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _openScreenshotFullscreen(index),
                child: Hero(
                  tag: 'screenshot_${widget.app.id}_$index',
                  child: Container(
                    width: 230,
                    margin: const EdgeInsets.only(right: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        widget.app.screenshots[index],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: const Color(0xFF1C1C1E),
                          child: const Icon(
                            CupertinoIcons.photo,
                            color: Color(0xFF8E8E93),
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDescription() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sobre este app',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.app.longDescription,
            style: const TextStyle(
              color: Color(0xFFAAAAAA),
              fontSize: 16,
              height: 1.6,
              letterSpacing: 0.2,
            ),
          ),
          if (widget.app.whatsNew != null) ...[
            const SizedBox(height: 28),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(
                        CupertinoIcons.sparkles,
                        color: Color(0xFF8E8E93),
                        size: 24,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Novidades',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.app.whatsNew!,
                    style: const TextStyle(
                      color: Color(0xFFAAAAAA),
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFeatures() {
    if (widget.app.features.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recursos',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: widget.app.features.asMap().entries.map((entry) {
                final isLast = entry.key == widget.app.features.length - 1;
                return Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2C2C2E),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            CupertinoIcons.checkmark,
                            color: Color(0xFF8E8E93),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              entry.value,
                              style: const TextStyle(
                                color: Color(0xFFAAAAAA),
                                fontSize: 16,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (!isLast) const SizedBox(height: 16),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInformation() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informações',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildInfoRow('Desenvolvedor', widget.app.developer, CupertinoIcons.person_crop_circle),
                _buildInfoDivider(),
                _buildInfoRow('Versão', widget.app.version, CupertinoIcons.cube_box),
                _buildInfoDivider(),
                _buildInfoRow('Tamanho', widget.app.size, CupertinoIcons.arrow_down_circle),
                _buildInfoDivider(),
                _buildInfoRow('Categoria', widget.app.category, CupertinoIcons.square_grid_2x2),
                _buildInfoDivider(),
                _buildInfoRow('Idiomas', widget.app.languages.join(', '), CupertinoIcons.globe),
                _buildInfoDivider(),
                _buildInfoRow('Classificação', widget.app.ageRating, CupertinoIcons.shield),
                _buildInfoDivider(),
                _buildInfoRow('Atualização', _formatDate(widget.app.lastUpdate), CupertinoIcons.clock),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF8E8E93), size: 24),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF8E8E93),
                fontSize: 15,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoDivider() {
    return const Divider(
      color: Color(0xFF2C2C2E),
      thickness: 1,
      height: 1,
    );
  }

  Widget _buildRatingsReviews() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Avaliações',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
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
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Text(
                      widget.app.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 56,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text(
                      'de 5',
                      style: TextStyle(
                        color: Color(0xFF8E8E93),
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildStarRating(widget.app.rating),
                    const SizedBox(height: 8),
                    Text(
                      '${widget.app.reviewCount} avaliações',
                      style: const TextStyle(
                        color: Color(0xFF8E8E93),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 40),
                Expanded(
                  child: Column(
                    children: [
                      _buildRatingBar(5, 0.75),
                      const SizedBox(height: 6),
                      _buildRatingBar(4, 0.15),
                      const SizedBox(height: 6),
                      _buildRatingBar(3, 0.06),
                      const SizedBox(height: 6),
                      _buildRatingBar(2, 0.03),
                      const SizedBox(height: 6),
                      _buildRatingBar(1, 0.01),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarRating(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        return Icon(
          index < rating.floor() ? CupertinoIcons.star_fill : CupertinoIcons.star,
          color: const Color(0xFFFFCC00),
          size: 24,
        );
      }),
    );
  }

  Widget _buildRatingBar(int stars, double percentage) {
    return Row(
      children: [
        SizedBox(
          width: 35,
          child: Row(
            children: [
              const Icon(CupertinoIcons.star_fill, color: Color(0xFF8E8E93), size: 24),
              const SizedBox(width: 4),
              Text(
                '$stars',
                style: const TextStyle(
                  color: Color(0xFF8E8E93),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2E),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: percentage,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF8E8E93),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeveloperSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Desenvolvedor',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2C2E),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      widget.app.developer[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.app.developer,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Desenvolvedor',
                        style: TextStyle(
                          color: Color(0xFF8E8E93),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  CupertinoIcons.chevron_right,
                  color: Color(0xFF8E8E93),
                  size: 24,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacySection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Privacidade',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildPrivacyItem(
                  'Política de Privacidade',
                  'Ver detalhes sobre como seus dados são tratados',
                  CupertinoIcons.doc_text,
                ),
                const SizedBox(height: 12),
                const Divider(color: Color(0xFF2C2C2E), thickness: 1),
                const SizedBox(height: 12),
                _buildPrivacyItem(
                  'Práticas de Privacidade',
                  'Este app pode coletar dados conforme descrito',
                  CupertinoIcons.hand_raised,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyItem(String title, String subtitle, IconData icon) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: const Color(0xFF2C2C2E),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: const Color(0xFF8E8E93), size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF8E8E93),
                  fontSize: 13,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        const Icon(
          CupertinoIcons.chevron_right,
          color: Color(0xFF8E8E93),
          size: 24,
        ),
      ],
    );
  }

  Widget _buildSupportSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Suporte',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C1E),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                _buildSupportItem(
                  'Site do Desenvolvedor',
                  CupertinoIcons.globe,
                ),
                const SizedBox(height: 12),
                const Divider(color: Color(0xFF2C2C2E), thickness: 1),
                const SizedBox(height: 12),
                _buildSupportItem(
                  'Política de Privacidade',
                  CupertinoIcons.doc_text_fill,
                ),
                const SizedBox(height: 12),
                const Divider(color: Color(0xFF2C2C2E), thickness: 1),
                const SizedBox(height: 12),
                _buildSupportItem(
                  'Reportar um Problema',
                  CupertinoIcons.exclamationmark_triangle,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportItem(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF8E8E93), size: 24),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Icon(
          CupertinoIcons.chevron_right,
          color: Color(0xFF8E8E93),
          size: 24,
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
      'jul', 'ago', 'set', 'out', 'nov', 'dez'
    ];
    return '${date.day} de ${months[date.month - 1]} de ${date.year}';
  }
}

class ScreenshotFullscreenViewer extends StatefulWidget {
  final List<String> screenshots;
  final int initialIndex;

  const ScreenshotFullscreenViewer({
    Key? key,
    required this.screenshots,
    required this.initialIndex,
  }) : super(key: key);

  @override
  State<ScreenshotFullscreenViewer> createState() => _ScreenshotFullscreenViewerState();
}

class _ScreenshotFullscreenViewerState extends State<ScreenshotFullscreenViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
              HapticFeedback.selectionClick();
            },
            itemCount: widget.screenshots.length,
            itemBuilder: (context, index) {
              return Center(
                child: Hero(
                  tag: 'screenshot_${widget.screenshots[index]}_$index',
                  child: InteractiveViewer(
                    minScale: 1.0,
                    maxScale: 4.0,
                    child: Image.network(
                      widget.screenshots[index],
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFF1C1C1E),
                        child: const Icon(
                          CupertinoIcons.photo,
                          color: Color(0xFF8E8E93),
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: IconButton(
                          icon: const Icon(
                            CupertinoIcons.xmark,
                            color: Colors.white,
                            size: 24,
                          ),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            Navigator.pop(context);
                          },
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_currentIndex + 1} de ${widget.screenshots.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (widget.screenshots.length > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          widget.screenshots.length,
                          (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: _currentIndex == index ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: _currentIndex == index
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}