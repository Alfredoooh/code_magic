import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../models/news_article.dart';

class RelatedArticleCard extends StatelessWidget {
  final NewsArticle article;
  final bool isDark;
  final Color primaryColor;
  final VoidCallback onTap;

  const RelatedArticleCard({
    required this.article,
    required this.isDark,
    required this.primaryColor,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  String _getFaviconUrl(String source) {
    final domain = source.toLowerCase().replaceAll(' ', '');
    return 'https://www.google.com/s2/favicons?domain=$domain.com&sz=64';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Color(0xFF1C1C1E) : CupertinoColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: CupertinoColors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: Offset(0, 4),
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
                        color: isDark 
                          ? Color(0xFF2C2C2E) 
                          : CupertinoColors.systemGrey6,
                        child: Icon(CupertinoIcons.photo, size: 32, 
                             color: CupertinoColors.systemGrey),
                      ),
                    )
                  : Container(
                      height: 100,
                      color: isDark 
                        ? Color(0xFF2C2C2E) 
                        : CupertinoColors.systemGrey6,
                      child: Icon(CupertinoIcons.news, size: 32, 
                           color: CupertinoColors.systemGrey),
                    ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        article.category.toUpperCase(),
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
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
                          fontWeight: FontWeight.w700,
                          color: isDark 
                            ? CupertinoColors.white 
                            : CupertinoColors.black,
                          height: 1.3,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(height: 6),
                    Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: Image.network(
                            _getFaviconUrl(article.source),
                            width: 14,
                            height: 14,
                            errorBuilder: (context, error, stack) => Icon(
                              CupertinoIcons.news,
                              size: 14,
                              color: primaryColor,
                            ),
                          ),
                        ),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            article.timeAgo,
                            style: TextStyle(
                              fontSize: 11,
                              color: CupertinoColors.systemGrey,
                              fontWeight: FontWeight.w600,
                            ),
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