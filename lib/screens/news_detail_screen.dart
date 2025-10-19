// lib/screens/news_detail_screen.dart - Redesenhado com UI Components
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/news_article.dart';
import '../widgets/app_ui_components.dart';
import 'bookmarks_screen.dart';
import '../widgets/related_article_card.dart';
import '../widgets/app_colors.dart';

class NewsDetailScreen extends StatefulWidget {
  final NewsArticle article;
  final List<NewsArticle>? allArticles;
  final int? currentIndex;

  const NewsDetailScreen({
    required this.article,
    this.allArticles,
    this.currentIndex,
    Key? key,
  }) : super(key: key);

  @override
  _NewsDetailScreenState createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  late PageController _pageController;
  late int currentIndex;
  late List<NewsArticle> articles;
  bool _isBookmarked = false;
  bool _showNavigationButtons = true;
  bool _isLoadingBookmark = false;

  @override
  void initState() {
    super.initState();
    articles = (widget.allArticles ?? [widget.article]).cast<NewsArticle>();
    currentIndex = (widget.currentIndex != null &&
            widget.currentIndex! >= 0 &&
            widget.currentIndex! < articles.length)
        ? widget.currentIndex!
        : 0;
    _pageController = PageController(initialPage: currentIndex);
    _checkIfBookmarked();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _checkIfBookmarked() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('bookmarks')
          .doc(_generateArticleId(articles[currentIndex]))
          .get();

      if (mounted) {
        setState(() {
          _isBookmarked = doc.exists;
        });
      }
    } catch (e) {
      print('Erro ao verificar bookmark: $e');
    }
  }

  String _generateArticleId(NewsArticle article) {
    return article.title.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
  }

  Future<void> _toggleBookmark() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      AppDialogs.showError(
        context,
        'Login Necessário',
        'Você precisa estar logado para adicionar aos favoritos',
      );
      return;
    }

    setState(() => _isLoadingBookmark = true);

    try {
      final article = articles[currentIndex];
      final articleId = _generateArticleId(article);
      final bookmarkRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('bookmarks')
          .doc(articleId);

      if (_isBookmarked) {
        await bookmarkRef.delete();
        if (mounted) {
          setState(() => _isBookmarked = false);
          AppDialogs.showSuccess(
            context,
            'Sucesso',
            'Removido dos favoritos',
          );
        }
      } else {
        await bookmarkRef.set({
          'title': article.title,
          'description': article.description,
          'imageUrl': article.imageUrl,
          'url': article.url,
          'source': article.source,
          'category': article.category,
          'publishedAt': article.publishedAt.toIso8601String(),
          'savedAt': FieldValue.serverTimestamp(),
        });
        if (mounted) {
          setState(() => _isBookmarked = true);
          AppDialogs.showSuccess(
            context,
            'Sucesso',
            'Adicionado aos favoritos',
          );
        }
      }
    } catch (e) {
      AppDialogs.showError(context, 'Erro', 'Erro ao salvar favorito: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingBookmark = false);
      }
    }
  }

  void _goToPrevious() {
    if (currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _goToNext() {
    if (currentIndex < articles.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _shareArticle(NewsArticle article) {
    final text = '${article.title}\n\n${article.description}\n\n${article.source}';
    Share.share(text, subject: article.title);
  }

  void _showBookmarksScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const BookmarksScreen()),
    );
  }

  void _showImageFullScreen(String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => _FullScreenImageViewer(imageUrl: imageUrl),
      ),
    );
  }

  void _showActionSheet(BuildContext context, NewsArticle article) {
    AppBottomSheet.show(
      context,
      height: 240,
      child: Column(
        children: [
          const SizedBox(height: 8),
          const AppSectionTitle(text: 'Ações', fontSize: 18),
          const SizedBox(height: 20),
          _buildActionOption(
            icon: Icons.share_outlined,
            title: 'Compartilhar',
            onTap: () {
              Navigator.pop(context);
              _shareArticle(article);
            },
          ),
          const Divider(height: 1),
          _buildActionOption(
            icon: Icons.bookmark_outline,
            title: 'Ver Favoritos',
            onTap: () {
              Navigator.pop(context);
              _showBookmarksScreen();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getFaviconUrl(String source) {
    final domain = source.toLowerCase().replaceAll(' ', '');
    return 'https://www.google.com/s2/favicons?domain=$domain.com&sz=64';
  }

  List<NewsArticle> _getRelatedArticles(NewsArticle currentArticle) {
    return articles
        .where((article) =>
            article != currentArticle && article.category == currentArticle.category)
        .take(6)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasMultipleArticles = articles.length > 1;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppSecondaryAppBar(
        title: 'Detalhes',
        actions: [
          if (_isLoadingBookmark)
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
                ),
              ),
            )
          else
            IconButton(
              icon: Icon(
                _isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                color: _isBookmarked ? AppColors.primary : null,
              ),
              onPressed: _toggleBookmark,
            ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showActionSheet(context, articles[currentIndex]),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  currentIndex = index;
                  _showNavigationButtons = true;
                  _checkIfBookmarked();
                });
                Future.delayed(const Duration(seconds: 2), () {
                  if (mounted) setState(() => _showNavigationButtons = false);
                });
              },
              itemCount: articles.length,
              itemBuilder: (context, index) {
                return _buildArticleContent(articles[index], isDark);
              },
            ),

            if (hasMultipleArticles && currentIndex > 0)
              Positioned(
                left: 16,
                top: 0,
                bottom: 0,
                child: Center(
                  child: AnimatedOpacity(
                    opacity: _showNavigationButtons ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: GestureDetector(
                      onTap: _goToPrevious,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.chevron_left,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            if (hasMultipleArticles && currentIndex < articles.length - 1)
              Positioned(
                right: 16,
                top: 0,
                bottom: 0,
                child: Center(
                  child: AnimatedOpacity(
                    opacity: _showNavigationButtons ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 300),
                    child: GestureDetector(
                      onTap: _goToNext,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.chevron_right,
                          color: Colors.white,
                          size: 24,
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

  Widget _buildArticleContent(NewsArticle article, bool isDark) {
    final relatedArticles = _getRelatedArticles(article);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (article.imageUrl.isNotEmpty)
            GestureDetector(
              onTap: () => _showImageFullScreen(article.imageUrl),
              child: Hero(
                tag: 'article_${article.title}',
                child: Container(
                  width: double.infinity,
                  height: 280,
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Image.network(
                    article.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) => Container(
                      color: isDark ? AppColors.darkCard : AppColors.lightCard,
                      child: const Icon(
                        Icons.image_outlined,
                        size: 80,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        article.category.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const Spacer(),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(
                        _getFaviconUrl(article.source),
                        width: 20,
                        height: 20,
                        errorBuilder: (context, error, stack) => Icon(
                          Icons.language,
                          size: 20,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      article.source,
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                AppSectionTitle(
                  text: article.title,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      article.timeAgo,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.visibility_outlined, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Text(
                      '${(article.title.length * 10)} leituras',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                Container(
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withOpacity(0.3),
                        Colors.transparent,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  article.description,
                  style: TextStyle(
                    fontSize: 17,
                    color: isDark
                        ? Colors.white.withOpacity(0.9)
                        : Colors.black.withOpacity(0.85),
                    height: 1.6,
                    letterSpacing: 0.1,
                  ),
                ),

                const SizedBox(height: 32),

                AppCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.info_outline,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const AppSectionTitle(
                            text: 'Sobre esta notícia',
                            fontSize: 16,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow(
                        icon: Icons.business_outlined,
                        label: 'Fonte',
                        value: article.source,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        icon: Icons.label_outline,
                        label: 'Categoria',
                        value: article.category,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 12),
                      _buildInfoRow(
                        icon: Icons.schedule,
                        label: 'Publicado',
                        value: article.timeAgo,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                AppPrimaryButton(
                  text: 'Compartilhar Notícia',
                  onPressed: () => _shareArticle(article),
                ),

                if (relatedArticles.isNotEmpty) ...[
                  const SizedBox(height: 40),
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const AppSectionTitle(
                        text: 'Notícias Relacionadas',
                        fontSize: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.75,
                    ),
                    itemCount: relatedArticles.length,
                    itemBuilder: (context, index) => RelatedArticleCard(
                      article: relatedArticles[index],
                      isDark: isDark,
                      primaryColor: AppColors.primary,
                      onTap: () {
                        final idx = articles.indexOf(relatedArticles[index]);
                        if (idx != -1) {
                          _pageController.animateToPage(
                            idx,
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOutCubic,
                          );
                        }
                      },
                    ),
                  ),
                ],

                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white.withOpacity(0.9) : Colors.black.withOpacity(0.8),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.6),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _FullScreenImageViewer extends StatelessWidget {
  final String imageUrl;

  const _FullScreenImageViewer({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.8),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Visualizar Imagem',
          style: TextStyle(color: Colors.white, fontSize: 17),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stack) => const Icon(
              Icons.broken_image_outlined,
              size: 100,
              color: Colors.grey,
            ),
          ),
        ),
      ),
    );
  }
}