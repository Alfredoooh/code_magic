// lib/screens/home_news_section.dart
import 'package:flutter/material.dart';
import '../widgets/app_ui_components.dart';
import '../models/news_article.dart';
import 'home_widgets.dart';
import 'home_screen_helper.dart';
import 'news_detail_screen.dart';

class HomeNewsSection extends StatelessWidget {
  final List<NewsArticle> newsArticles;
  final bool loadingNews;
  final bool isDark;
  final PageController pageController;
  final int currentPage;
  final Future<bool> Function(String) onNewsClick;

  const HomeNewsSection({
    required this.newsArticles,
    required this.loadingNews,
    required this.isDark,
    required this.pageController,
    required this.currentPage,
    required this.onNewsClick,
    Key? key,
  }) : super(key: key);

  Future<void> _handleNewsClick(BuildContext context, NewsArticle article, int index) async {
    final canProceed = await onNewsClick('view_news');
    if (!canProceed) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => NewsDetailScreen(
          article: article,
          allArticles: newsArticles,
          currentIndex: index,
        ),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSectionTitle(
          text: 'Últimas Notícias',
          fontSize: 24,
        ),
        SizedBox(height: 16),
        loadingNews
            ? Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              )
            : newsArticles.isEmpty
                ? _buildEmptyState()
                : Column(
                    children: [
                      Container(
                        height: 140,
                        child: PageView.builder(
                          controller: pageController,
                          physics: BouncingScrollPhysics(),
                          itemCount: newsArticles.length,
                          itemBuilder: (context, index) {
                            final article = newsArticles[index];
                            return Padding(
                              padding: EdgeInsets.only(right: 12),
                              child: GestureDetector(
                                onTap: () => _handleNewsClick(context, article, index),
                                child: HomeScreenHelper.buildNewsCard(
                                  article: article,
                                  isDark: isDark,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(height: 12),
Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          newsArticles.length,
                          (index) => Container(
                            margin: EdgeInsets.symmetric(horizontal: 4),
                            width: index == currentPage ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: index == currentPage
                                  ? AppColors.primary
                                  : (isDark ? Colors.grey[700] : Colors.grey[400]),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            }

  Widget _buildEmptyState() {
    return Container(
      height: 140,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.article_outlined,
              size: 40,
              color: Colors.grey,
            ),
            SizedBox(height: 8),
            Text(
              'Nenhuma notícia disponível',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}