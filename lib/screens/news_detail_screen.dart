import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../models/news_article.dart';

class NewsDetailScreen extends StatefulWidget {
  final NewsArticle article;
  final List<NewsArticle>? allArticles;
  final int? currentIndex;

  const NewsDetailScreen({
    required this.article,
    this.allArticles,
    this.currentIndex,
  });

  @override
  _NewsDetailScreenState createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  late PageController _pageController;
  late int currentIndex;
  late List<NewsArticle> articles;
  bool _isBookmarked = false;
  bool _showNavigationButtons = true;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.currentIndex ?? 0;
    articles = widget.allArticles ?? [widget.article];
    _pageController = PageController(initialPage: currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
    Share.share(
      '${article.title}\n\n${article.description}\n\nLeia mais: ${article.url}',
      subject: article.title,
    );
  }

  void _showActionSheet(BuildContext context, NewsArticle article) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: Text('Ações'),
        message: Text(article.title),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _shareArticle(article);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.share, size: 20),
                SizedBox(width: 8),
                Text('Compartilhar'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _isBookmarked = !_isBookmarked);
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_isBookmarked ? CupertinoIcons.bookmark_fill : CupertinoIcons.bookmark, size: 20),
                SizedBox(width: 8),
                Text(_isBookmarked ? 'Remover dos Favoritos' : 'Adicionar aos Favoritos'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () async {
              Navigator.pop(context);
              final uri = Uri.parse(article.url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.arrow_up_right_square, size: 20),
                SizedBox(width: 8),
                Text('Abrir no Navegador'),
              ],
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(context),
          child: Text('Cancelar'),
        ),
      ),
    );
  }

  List<NewsArticle> _getRelatedArticles(NewsArticle currentArticle) {
    return articles
        .where((article) => 
          article != currentArticle && 
          article.category == currentArticle.category)
        .take(6)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasMultipleArticles = articles.length > 1;

    return CupertinoPageScaffold(
      backgroundColor: isDark ? Color(0xFF0E0E0E) : Color(0xFFF5F5F5),
      child: Stack(
        children: [
          CustomScrollView(
            slivers: [
              CupertinoSliverNavigationBar(
                backgroundColor: isDark ? Color(0xFF1A1A1A).withOpacity(0.95) : CupertinoColors.white.withOpacity(0.95),
                border: null,
                largeTitle: Text('Notícia'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() => _isBookmarked = !_isBookmarked);
                      },
                      child: Icon(
                        _isBookmarked ? CupertinoIcons.bookmark_fill : CupertinoIcons.bookmark,
                        color: _isBookmarked ? Color(0xFFFF444F) : (isDark ? CupertinoColors.white : CupertinoColors.black),
                        size: 22,
                      ),
                    ),
                    SizedBox(width: 16),
                    GestureDetector(
                      onTap: () => _showActionSheet(context, articles[currentIndex]),
                      child: Icon(
                        CupertinoIcons.ellipsis_circle,
                        color: isDark ? CupertinoColors.white : CupertinoColors.black,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
              SliverToBoxAdapter(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      currentIndex = index;
                      _showNavigationButtons = true;
                    });
                    Future.delayed(Duration(seconds: 2), () {
                      if (mounted) {
                        setState(() => _showNavigationButtons = false);
                      }
                    });
                  },
                  itemCount: articles.length,
                  physics: BouncingScrollPhysics(),
                  itemBuilder: (context, index) {
                    return _buildArticleContent(articles[index], isDark);
                  },
                ),
              ),
            ],
          ),
          
          // Botões de navegação transparentes
          if (hasMultipleArticles) ...[
            AnimatedOpacity(
              opacity: _showNavigationButtons ? 1.0 : 0.0,
              duration: Duration(milliseconds: 300),
              child: Positioned(
                left: 16,
                top: 0,
                bottom: 0,
                child: Center(
                  child: currentIndex > 0
                      ? GestureDetector(
                          onTap: _goToPrevious,
                          child: Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: CupertinoColors.black.withOpacity(0.3),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: CupertinoColors.white.withOpacity(0.3),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: CupertinoColors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              CupertinoIcons.chevron_left,
                              color: CupertinoColors.white,
                              size: 22,
                            ),
                          ),
                        )
                      : SizedBox.shrink(),
                ),
              ),
            ),
            
            AnimatedOpacity(
              opacity: _showNavigationButtons ? 1.0 : 0.0,
              duration: Duration(milliseconds: 300),
              child: Positioned(
                right: 16,
                top: 0,
                bottom: 0,
                child: Center(
                  child: currentIndex < articles.length - 1
                      ? GestureDetector(
                          onTap: _goToNext,
                          child: Container(
                            padding: EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: CupertinoColors.black.withOpacity(0.3),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: CupertinoColors.white.withOpacity(0.3),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: CupertinoColors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              CupertinoIcons.chevron_right,
                              color: CupertinoColors.white,
                              size: 22,
                            ),
                          ),
                        )
                      : SizedBox.shrink(),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildArticleContent(NewsArticle article, bool isDark) {
    final relatedArticles = _getRelatedArticles(article);
    
    return SingleChildScrollView(
      physics: BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero Image
          if (article.imageUrl.isNotEmpty)
            Hero(
              tag: 'article_${article.title}',
              child: Container(
                width: double.infinity,
                height: 300,
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: CupertinoColors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Image.network(
                  article.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => Container(
                    color: isDark ? Color(0xFF1A1A1A) : CupertinoColors.systemGrey5,
                    child: Icon(CupertinoIcons.photo, size: 80, color: CupertinoColors.systemGrey),
                  ),
                ),
              ),
            ),
          
          // Conteúdo Principal
          Container(
            color: isDark ? Color(0xFF0E0E0E) : Color(0xFFF5F5F5),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Categoria Badge
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFFF444F), Color(0xFFFF6B6B)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFFFF444F).withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      article.category.toUpperCase(),
                      style: TextStyle(
                        color: CupertinoColors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  
                  // Título
                  Text(
                    article.title,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isDark ? CupertinoColors.white : CupertinoColors.black,
                      height: 1.3,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  // Metadados
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isDark ? Color(0xFF1A1A1A) : CupertinoColors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(CupertinoIcons.doc_text, size: 16, color: Color(0xFFFF444F)),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          article.source,
                          style: TextStyle(
                            color: isDark ? CupertinoColors.white.withOpacity(0.7) : CupertinoColors.systemGrey,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 12),
                      Icon(CupertinoIcons.time, size: 16, color: CupertinoColors.systemGrey),
                      SizedBox(width: 6),
                      Text(
                        article.timeAgo,
                        style: TextStyle(color: CupertinoColors.systemGrey, fontSize: 14),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                  
                  // Divider
                  Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          CupertinoColors.systemGrey.withOpacity(0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  
                  // Descrição
                  Text(
                    article.description,
                    style: TextStyle(
                      fontSize: 18,
                      color: isDark ? CupertinoColors.white.withOpacity(0.9) : CupertinoColors.black.withOpacity(0.85),
                      height: 1.7,
                      letterSpacing: 0.2,
                    ),
                  ),
                  
                  // Botões de Ação
                  SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: CupertinoButton(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          color: Color(0xFFFF444F),
                          borderRadius: BorderRadius.circular(14),
                          onPressed: () async {
                            final uri = Uri.parse(article.url);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri, mode: LaunchMode.externalApplication);
                            }
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(CupertinoIcons.arrow_up_right_square, size: 18),
                              SizedBox(width: 8),
                              Text(
                                'Ler Completo',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? Color(0xFF1A1A1A) : CupertinoColors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Color(0xFFFF444F).withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: CupertinoButton(
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          onPressed: () => _shareArticle(article),
                          child: Icon(
                            CupertinoIcons.share,
                            color: Color(0xFFFF444F),
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // Artigos Relacionados
                  if (relatedArticles.isNotEmpty) ...[
                    SizedBox(height: 48),
                    Text(
                      'Relacionados',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDark ? CupertinoColors.white : CupertinoColors.black,
                      ),
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
                      itemBuilder: (context, index) {
                        return _buildRelatedCard(relatedArticles[index], isDark);
                      },
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

  Widget _buildRelatedCard(NewsArticle article, bool isDark) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context, rootNavigator: true).push(
          CupertinoPageRoute(
            builder: (context) => NewsDetailScreen(
              article: article,
              allArticles: articles,
              currentIndex: articles.indexOf(article),
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Color(0xFF1A1A1A) : CupertinoColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              child: article.imageUrl.isNotEmpty
                  ? Image.network(
                      article.imageUrl,
                      height: 100,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stack) => Container(
                        height: 100,
                        color: isDark ? Color(0xFF0E0E0E) : CupertinoColors.systemGrey6,
                        child: Icon(CupertinoIcons.photo, size: 30, color: CupertinoColors.systemGrey),
                      ),
                    )
                  : Container(
                      height: 100,
                      color: isDark ? Color(0xFF0E0E0E) : CupertinoColors.systemGrey6,
                      child: Icon(CupertinoIcons.news, size: 30, color: CupertinoColors.systemGrey),
                    ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: Color(0xFFFF444F).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        article.category.toUpperCase(),
                        style: TextStyle(
                          color: Color(0xFFFF444F),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                      ),
                    ),
                    SizedBox(height: 8),
                    Expanded(
                      child: Text(
                        article.title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? CupertinoColors.white : CupertinoColors.black,
                          height: 1.3,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(CupertinoIcons.time, size: 10, color: CupertinoColors.systemGrey),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            article.timeAgo,
                            style: TextStyle(fontSize: 10, color: CupertinoColors.systemGrey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}