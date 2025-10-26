// lib/news_detail_screen.dart - Material Design 3
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'markets_screen.dart';
import 'theme/app_theme.dart';
import 'theme/app_colors.dart';
import 'theme/app_widgets.dart';

class NewsDetailScreen extends StatefulWidget {
  final NewsItem news;

  const NewsDetailScreen({Key? key, required this.news}) : super(key: key);

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  bool _isBookmarked = false;
  final ScrollController _scrollController = ScrollController();
  double _scrollProgress = 0.0;
  bool _showTitle = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.position.pixels;
      
      setState(() {
        _scrollProgress = (maxScroll > 0) 
            ? (currentScroll / maxScroll).clamp(0.0, 1.0) 
            : 0.0;
        _showTitle = currentScroll > 200;
      });
    }
  }

  Future<void> _launchURL() async {
    AppHaptics.medium();
    final Uri url = Uri.parse(widget.news.url);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        AppSnackbar.error(context, 'Could not open link');
      }
    }
  }

  Future<void> _shareNews() async {
    AppHaptics.light();
    final text = '${widget.news.title}\n\n${widget.news.summary}\n\n${widget.news.url}';
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      AppSnackbar.success(
        context,
        'Link copied to clipboard! 📋',
      );
    }
  }

  void _toggleBookmark() {
    AppHaptics.light();
    setState(() {
      _isBookmarked = !_isBookmarked;
    });
    
    if (_isBookmarked) {
      AppSnackbar.success(context, 'Article saved! 📌');
    } else {
      AppSnackbar.info(context, 'Article removed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.surface,
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(),
          _buildHeroImage(),
          _buildContent(),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: context.surface,
      elevation: 0,
      pinned: true,
      expandedHeight: 0,
      leading: IconButtonWithBackground(
        icon: Icons.arrow_back_rounded,
        onPressed: () {
          AppHaptics.light();
          Navigator.pop(context);
        },
        backgroundColor: context.surface.withOpacity(0.9),
        size: 40,
      ),
      actions: [
        IconButtonWithBackground(
          icon: Icons.share_rounded,
          onPressed: _shareNews,
          backgroundColor: context.surface.withOpacity(0.9),
          size: 40,
        ),
        const SizedBox(width: AppSpacing.xs),
        IconButtonWithBackground(
          icon: _isBookmarked 
              ? Icons.bookmark_rounded 
              : Icons.bookmark_border_rounded,
          onPressed: _toggleBookmark,
          backgroundColor: context.surface.withOpacity(0.9),
          iconColor: _isBookmarked ? AppColors.warning : null,
          size: 40,
        ),
        const SizedBox(width: AppSpacing.sm),
      ],
      title: AnimatedOpacity(
        opacity: _showTitle ? 1.0 : 0.0,
        duration: AppMotion.short,
        child: Text(
          widget.news.title,
          style: context.textStyles.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(2),
        child: LinearProgressIndicator(
          value: _scrollProgress,
          backgroundColor: context.colors.surfaceContainerHighest,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          minHeight: 2,
        ),
      ),
    );
  }

  Widget _buildHeroImage() {
    return SliverToBoxAdapter(
      child: Stack(
        children: [
          // Hero Image
          Hero(
            tag: 'news_${widget.news.url}',
            child: Container(
              height: 280,
              width: double.infinity,
              decoration: BoxDecoration(
                color: context.colors.surfaceContainerHighest,
              ),
              child: widget.news.imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: widget.news.imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => _buildImagePlaceholder(),
                      errorWidget: (context, url, error) => _buildImageError(),
                    )
                  : _buildImagePlaceholder(),
            ),
          ),
          
          // Gradient overlay
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                  stops: const [0.5, 1.0],
                ),
              ),
            ),
          ),
          
          // Category badge
          Positioned(
            top: AppSpacing.lg,
            left: AppSpacing.lg,
            child: FadeInWidget(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: _getCategoryColor(widget.news.category),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getCategoryIcon(widget.news.category),
                      size: 14,
                      color: Colors.white,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      widget.news.category.toUpperCase(),
                      style: context.textStyles.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: context.colors.surfaceContainerHighest,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.article_rounded,
              size: 64,
              color: context.colors.onSurfaceVariant.withOpacity(0.3),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Loading image...',
              style: context.textStyles.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageError() {
    return Container(
      color: context.colors.surfaceContainerHighest,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.broken_image_rounded,
              size: 64,
              color: context.colors.onSurfaceVariant.withOpacity(0.3),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Image not available',
              style: context.textStyles.bodyMedium?.copyWith(
                color: context.colors.onSurfaceVariant.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            FadeInWidget(
              child: Text(
                widget.news.title,
                style: context.textStyles.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  height: 1.3,
                  letterSpacing: -0.5,
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Author and metadata
            FadeInWidget(
              delay: const Duration(milliseconds: 100),
              child: _buildMetadata(),
            ),

            const SizedBox(height: AppSpacing.xl),
            
            const LabeledDivider(label: 'Summary'),
            
            const SizedBox(height: AppSpacing.xl),

            // Summary
            FadeInWidget(
              delay: const Duration(milliseconds: 200),
              child: Text(
                widget.news.summary,
                style: context.textStyles.bodyLarge?.copyWith(
                  height: 1.8,
                  letterSpacing: 0.2,
                  color: context.colors.onSurface,
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xxxl),

            // Action buttons
            FadeInWidget(
              delay: const Duration(milliseconds: 300),
              child: Column(
                children: [
                  PrimaryButton(
                    text: 'Read Full Article',
                    icon: Icons.open_in_new_rounded,
                    onPressed: _launchURL,
                    expanded: true,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: SecondaryButton(
                          text: 'Share',
                          icon: Icons.share_rounded,
                          onPressed: _shareNews,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: SecondaryButton(
                          text: _isBookmarked ? 'Saved' : 'Save',
                          icon: _isBookmarked 
                              ? Icons.bookmark_rounded 
                              : Icons.bookmark_border_rounded,
                          onPressed: _toggleBookmark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xxxl),

            // Related info
            FadeInWidget(
              delay: const Duration(milliseconds: 400),
              child: _buildRelatedInfo(),
            ),

            const SizedBox(height: AppSpacing.massive),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadata() {
    return GlassCard(
      blur: 10,
      opacity: 0.05,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            // Favicon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: context.colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                child: CachedNetworkImage(
                  imageUrl: widget.news.favicon,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  errorWidget: (_, __, ___) => Icon(
                    Icons.article_rounded,
                    color: context.colors.onSurfaceVariant,
                    size: 24,
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: AppSpacing.md),
            
            // Source and time
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.news.source,
                    style: context.textStyles.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 14,
                        color: context.colors.onSurfaceVariant,
                      ),
                      const SizedBox(width: AppSpacing.xxs),
                      Text(
                        widget.news.time,
                        style: context.textStyles.bodySmall?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        width: 4,
                        height: 4,
                        decoration: BoxDecoration(
                          color: context.colors.onSurfaceVariant,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Icon(
                        Icons.visibility_rounded,
                        size: 14,
                        color: context.colors.onSurfaceVariant,
                      ),
                      const SizedBox(width: AppSpacing.xxs),
                      Text(
                        '${_getRandomViews()} reads',
                        style: context.textStyles.bodySmall?.copyWith(
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRelatedInfo() {
    return OutlinedCard(
      borderColor: AppColors.info.withOpacity(0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_rounded,
                color: AppColors.info,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'About This Article',
                style: context.textStyles.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _buildInfoRow(
            Icons.language_rounded,
            'Source',
            widget.news.source,
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildInfoRow(
            Icons.category_rounded,
            'Category',
            widget.news.category,
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildInfoRow(
            Icons.schedule_rounded,
            'Published',
            widget.news.time,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: context.colors.onSurfaceVariant,
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          '$label: ',
          style: context.textStyles.bodySmall?.copyWith(
            color: context.colors.onSurfaceVariant,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: context.textStyles.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'mercados':
      case 'markets':
        return AppColors.primary;
      case 'trading':
        return AppColors.success;
      case 'análise':
      case 'analysis':
        return AppColors.tertiary;
      case 'notícias':
      case 'news':
        return AppColors.info;
      default:
        return AppColors.secondary;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'mercados':
      case 'markets':
        return Icons.trending_up_rounded;
      case 'trading':
        return Icons.show_chart_rounded;
      case 'análise':
      case 'analysis':
        return Icons.analytics_rounded;
      case 'notícias':
      case 'news':
        return Icons.newspaper_rounded;
      default:
        return Icons.article_rounded;
    }
  }

  String _getRandomViews() {
    final views = [234, 567, 892, 1234, 2456, 3421, 5678, 8923];
    return views[DateTime.now().second % views.length].toString();
  }
}