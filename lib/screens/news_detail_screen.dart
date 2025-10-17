import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/news_article.dart';
import 'bookmarks_screen.dart';
import '../widgets/related_article_card.dart';

class NewsDetailScreen extends StatefulWidget {
  final NewsArticle article;
  final List<NewsArticle>? allArticles;
  final int? currentIndex;
  final bool isDark;

  const NewsDetailScreen({
    required this.article,
    required this.isDark,
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
      _showErrorDialog('Você precisa estar logado para adicionar aos favoritos');
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
          _showSuccessMessage('Removido dos favoritos');
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
          _showSuccessMessage('Adicionado aos favoritos');
        }
      }
    } catch (e) {
      _showErrorDialog('Erro ao salvar favorito: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingBookmark = false);
      }
    }
  }

  void _showSuccessMessage(String message) {
    showCupertinoDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => CupertinoAlertDialog(
        content: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.check_mark_circled_solid,
                color: CupertinoColors.systemGreen, size: 24),
            SizedBox(width: 12),
            Flexible(
              child: Text(message, style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
    Future.delayed(Duration(seconds: 1), () {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
    });
  }

  void _showErrorDialog(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Erro'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  void _goToPrevious() {
    if (currentIndex > 0) {
      _pageController.previousPage(
        duration: Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _goToNext() {
    if (currentIndex < articles.length - 1) {
      _pageController.nextPage(
        duration: Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _shareArticle(NewsArticle article) {
    final text = '${article.title}\n\n${article.description}\n\n${article.source}';
    Share.share(text, subject: article.title);
  }

  // <-- ALTERAÇÃO MÍNIMA: não passar isDark para BookmarksScreen,
  // porque sua BookmarksScreen atual não tem esse parâmetro.
  void _showBookmarksScreen() {
    Navigator.push(
      context,
      CupertinoPageRoute(builder: (context) => BookmarksScreen()),
    );
  }

  void _showImageFullScreen(String imageUrl) {
    Navigator.push(
      context,
      CupertinoPageRoute(
        fullscreenDialog: true,
        builder: (context) => _FullScreenImageViewer(imageUrl: imageUrl),
      ),
    );
  }

  void _showActionSheet(BuildContext context, NewsArticle article) {
    final primaryColor = Color(0xFFFF444F);

    showCupertinoModalPopup(
      context: context,
      builder: (context) {
        return CupertinoActionSheet(
          title: Text('Ações', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          message: Text(
            article.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12),
          ),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _shareArticle(article);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.share, size: 20, color: primaryColor),
                  SizedBox(width: 8),
                  Text('Compartilhar'),
                ],
              ),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _showBookmarksScreen();
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.bookmark_fill, size: 20, color: primaryColor),
                  SizedBox(width: 8),
                  Text('Ver Favoritos'),
                ],
              ),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
        );
      },
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
    final isDark = widget.isDark;
    final hasMultipleArticles = articles.length > 1;
    final primaryColor = Color(0xFFFF444F);

    return CupertinoPageScaffold(
      backgroundColor: isDark ? Color(0xFF000000) : Color(0xFFF2F2F7),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: isDark ? Color(0xFF1C1C1E).withOpacity(0.95) : CupertinoColors.white.withOpacity(0.95),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(
            CupertinoIcons.back,
            color: isDark ? CupertinoColors.white : CupertinoColors.black,
            size: 24,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        middle: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.network(
                _getFaviconUrl(articles[currentIndex].source),
                width: 18,
                height: 18,
                errorBuilder: (context, error, stack) => Icon(
                  CupertinoIcons.news,
                  size: 18,
                  color: primaryColor,
                ),
              ),
            ),
            SizedBox(width: 6),
            Text(
              'Detalhes',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: isDark ? CupertinoColors.white : CupertinoColors.black,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isLoadingBookmark)
              CupertinoActivityIndicator(radius: 10)
            else
              CupertinoButton(
                padding: EdgeInsets.zero,
                minSize: 0,
                child: Icon(
                  _isBookmarked ? CupertinoIcons.bookmark_solid : CupertinoIcons.bookmark,
                  color: _isBookmarked ? primaryColor : (isDark ? CupertinoColors.white : CupertinoColors.black),
                  size: 22,
                ),
                onPressed: _toggleBookmark,
              ),
            SizedBox(width: 8),
            CupertinoButton(
              padding: EdgeInsets.zero,
              minSize: 0,
              child: Icon(
                CupertinoIcons.ellipsis_circle,
                color: isDark ? CupertinoColors.white : CupertinoColors.black,
                size: 22,
              ),
              onPressed: () => _showActionSheet(context, articles[currentIndex]),
            ),
          ],
        ),
        border: null,
      ),
      child: SafeArea(
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
                Future.delayed(Duration(seconds: 2), () {
                  if (mounted) setState(() => _showNavigationButtons = false);
                });
              },
              itemCount: articles.length,
              itemBuilder: (context, index) {
                return _buildArticleContent(articles[index], isDark, primaryColor);
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
                    duration: Duration(milliseconds: 300),
                    child: GestureDetector(
                      onTap: _goToPrevious,
                      child: Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.4),
                              blurRadius: 16,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(CupertinoIcons.chevron_left, color: CupertinoColors.white, size: 24),
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
                    duration: Duration(milliseconds: 300),
                    child: GestureDetector(
                      onTap: _goToNext,
                      child: Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.4),
                              blurRadius: 16,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(CupertinoIcons.chevron_right, color: CupertinoColors.white, size: 24),
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

  Widget _buildArticleContent(NewsArticle article, bool isDark, Color primaryColor) {
    final relatedArticles = _getRelatedArticles(article);

    return SingleChildScrollView(
      physics: BouncingScrollPhysics(),
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
                        color: CupertinoColors.black.withOpacity(0.25),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Image.network(
                    article.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) => Container(
                      color: isDark ? Color(0xFF1C1C1E) : CupertinoColors.systemGrey6,
                      child: Icon(CupertinoIcons.photo, size: 80, color: CupertinoColors.systemGrey),
                    ),
                  ),
                ),
              ),
            ),

          Container(
            color: isDark ? Color(0xFF000000) : Color(0xFFF2F2F7),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withOpacity(0.35),
                              blurRadius: 10,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          article.category.toUpperCase(),
                          style: TextStyle(
                            color: CupertinoColors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                      Spacer(),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: Image.network(
                          _getFaviconUrl(article.source),
                          width: 22,
                          height: 22,
                          errorBuilder: (context, error, stack) => Icon(
                            CupertinoIcons.news,
                            size: 22,
                            color: primaryColor,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        article.source,
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),

                  Text(
                    article.title,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: isDark ? CupertinoColors.white : CupertinoColors.black,
                      height: 1.25,
                      letterSpacing: -0.6,
                    ),
                  ),
                  SizedBox(height: 16),

                  Row(
                    children: [
                      Icon(CupertinoIcons.time, size: 16, color: CupertinoColors.systemGrey),
                      SizedBox(width: 6),
                      Text(
                        article.timeAgo,
                        style: TextStyle(
                          color: CupertinoColors.systemGrey,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(width: 16),
                      Icon(CupertinoIcons.eye, size: 16, color: CupertinoColors.systemGrey),
                      SizedBox(width: 6),
                      Text(
                        '${(article.title.length * 10)} leituras',
                        style: TextStyle(
                          color: CupertinoColors.systemGrey,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),

                  Container(
                    height: 3,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          primaryColor,
                          primaryColor.withOpacity(0.3),
                          Colors.transparent,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  SizedBox(height: 24),

                  Text(
                    article.description,
                    style: TextStyle(
                      fontSize: 18,
                      color: isDark ? CupertinoColors.white.withOpacity(0.95) : CupertinoColors.black.withOpacity(0.9),
                      height: 1.75,
                      letterSpacing: 0.2,
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  SizedBox(height: 32),

                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          primaryColor.withOpacity(0.12),
                          primaryColor.withOpacity(0.06),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: primaryColor.withOpacity(0.25),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                CupertinoIcons.info_circle_fill,
                                color: primaryColor,
                                size: 20,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Sobre esta notícia',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                color: isDark ? CupertinoColors.white : CupertinoColors.black,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        _buildInfoRow(
                          icon: CupertinoIcons.building_2_fill,
                          label: 'Fonte',
                          value: article.source,
                          isDark: isDark,
                          primaryColor: primaryColor,
                        ),
                        SizedBox(height: 10),
                        _buildInfoRow(
                          icon: CupertinoIcons.tag_fill,
                          label: 'Categoria',
                          value: article.category,
                          isDark: isDark,
                          primaryColor: primaryColor,
                        ),
                        SizedBox(height: 10),
                        _buildInfoRow(
                          icon: CupertinoIcons.clock_fill,
                          label: 'Publicado',
                          value: article.timeAgo,
                          isDark: isDark,
                          primaryColor: primaryColor,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 32),

                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: () => _shareArticle(article),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.4),
                            blurRadius: 16,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(CupertinoIcons.share, size: 20, color: Colors.white),
                          SizedBox(width: 12),
                          Text(
                            'Compartilhar Notícia',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (relatedArticles.isNotEmpty) ...[
                    SizedBox(height: 48),
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 24,
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Notícias Relacionadas',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: isDark ? CupertinoColors.white : CupertinoColors.black,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: relatedArticles.length,
                      itemBuilder: (context, index) => RelatedArticleCard(
                        article: relatedArticles[index],
                        isDark: isDark,
                        primaryColor: primaryColor,
                        onTap: () {
                          final idx = articles.indexOf(relatedArticles[index]);
                          if (idx != -1) {
                            _pageController.animateToPage(
                              idx,
                              duration: Duration(milliseconds: 400),
                              curve: Curves.easeInOutCubic,
                            );
                          }
                        },
                      ),
                    ),
                  ],

                  SizedBox(height: 40),
                ],
              ),
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
    required Color primaryColor,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: primaryColor),
        SizedBox(width: 8),
        Text(
          '$label:',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark ? CupertinoColors.white.withOpacity(0.9) : CupertinoColors.black.withOpacity(0.8),
          ),
        ),
        SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? CupertinoColors.white.withOpacity(0.7) : CupertinoColors.black.withOpacity(0.6),
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
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: CupertinoColors.black.withOpacity(0.8),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          child: Icon(
            CupertinoIcons.xmark,
            color: CupertinoColors.white,
            size: 24,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        border: null,
      ),
      child: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stack) => Icon(
              CupertinoIcons.photo,
              size: 100,
              color: CupertinoColors.systemGrey,
            ),
          ),
        ),
      ),
    );
  }
}