import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';
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
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToNext() {
    if (currentIndex < articles.length - 1) {
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = MediaQuery.of(context).platformBrightness == Brightness.dark;
    final hasMultipleArticles = articles.length > 1;

    return CupertinoPageScaffold(
      backgroundColor: isDark ? Color(0xFF0E0E0E) : Color(0xFFF5F5F5),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: isDark ? Color(0xFF1A1A1A) : CupertinoColors.white,
        middle: Text('Detalhes'),
        border: null,
      ),
      child: Stack(
        children: [
          SafeArea(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() => currentIndex = index);
              },
              itemCount: articles.length,
              itemBuilder: (context, index) {
                return _buildArticleContent(articles[index], isDark);
              },
            ),
          ),
          
          // Botões de navegação
          if (hasMultipleArticles) ...[
            Positioned(
              left: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: currentIndex > 0
                    ? GestureDetector(
                        onTap: _goToPrevious,
                        child: Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Color(0xFFFF444F),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: CupertinoColors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            CupertinoIcons.chevron_left,
                            color: CupertinoColors.white,
                            size: 24,
                          ),
                        ),
                      )
                    : SizedBox.shrink(),
              ),
            ),
            
            Positioned(
              right: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: currentIndex < articles.length - 1
                    ? GestureDetector(
                        onTap: _goToNext,
                        child: Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Color(0xFFFF444F),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: CupertinoColors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            CupertinoIcons.chevron_right,
                            color: CupertinoColors.white,
                            size: 24,
                          ),
                        ),
                      )
                    : SizedBox.shrink(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildArticleContent(NewsArticle article, bool isDark) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (article.imageUrl.isNotEmpty)
            Image.network(
              article.imageUrl,
              width: double.infinity,
              height: 250,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => Container(
                height: 250,
                color: isDark ? Color(0xFF1A1A1A) : CupertinoColors.systemGrey5,
                child: Icon(CupertinoIcons.photo, size: 60, color: CupertinoColors.systemGrey),
              ),
            ),
          Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Color(0xFFFF444F).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    article.category.toUpperCase(),
                    style: TextStyle(
                      color: Color(0xFFFF444F),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  article.title,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: isDark ? CupertinoColors.white : CupertinoColors.black,
                    height: 1.3,
                  ),
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Icon(CupertinoIcons.doc_text, size: 16, color: CupertinoColors.systemGrey),
                    SizedBox(width: 6),
                    Text(
                      article.source,
                      style: TextStyle(color: CupertinoColors.systemGrey, fontSize: 14),
                    ),
                    SizedBox(width: 16),
                    Icon(CupertinoIcons.time, size: 16, color: CupertinoColors.systemGrey),
                    SizedBox(width: 6),
                    Text(
                      article.timeAgo,
                      style: TextStyle(color: CupertinoColors.systemGrey, fontSize: 14),
                    ),
                  ],
                ),
                SizedBox(height: 24),
                Text(
                  article.description,
                  style: TextStyle(
                    fontSize: 17,
                    color: isDark ? CupertinoColors.white.withOpacity(0.85) : CupertinoColors.black,
                    height: 1.6,
                  ),
                ),
                if (article.url.isNotEmpty) ...[
                  SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: CupertinoButton(
                      color: Color(0xFFFF444F),
                      borderRadius: BorderRadius.circular(12),
                      onPressed: () async {
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
                          Text(
                            'Ler Notícia Completa',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}