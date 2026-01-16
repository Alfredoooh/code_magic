// news_card_widgets.dart - Widgets de cards de notícias
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:ui';
import 'models.dart';

class NewsCardWidgets {
  final bool isDarkTheme;
  final Function(String) onTapUrl;
  final String? Function(NewsArticle) getTranslatedTitle;
  final String? Function(NewsArticle) getTranslatedDescription;
  final Future<void> Function(NewsArticle) onTranslate;

  NewsCardWidgets({
    required this.isDarkTheme,
    required this.onTapUrl,
    required this.getTranslatedTitle,
    required this.getTranslatedDescription,
    required this.onTranslate,
  });

  Color get _surfaceColor => isDarkTheme ? const Color(0xFF1A1A1A) : Colors.white;
  Color get _textColor => isDarkTheme ? const Color(0xFFE4E6EB) : const Color(0xFF050505);
  Color get _subTextColor => isDarkTheme ? const Color(0xFFB0B3B8) : const Color(0xFF65676B);
  Color get _borderColor => isDarkTheme ? const Color(0xFF3A3B3C) : const Color(0xFFDDDFE2);

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Agora';
    if (diff.inMinutes < 60) return '${diff.inMinutes}min';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays == 1) return '1 dia';
    if (diff.inDays < 7) return '${diff.inDays} dias';
    return '${date.day}/${date.month}';
  }

  // CARD PRINCIPAL COM BACKGROUND BLUR - VERSÃO COMPACTA
  Widget buildNewsCard(NewsArticle article) {
    return GestureDetector(
      onTap: () => onTapUrl(article.link),
      child: Container(
        decoration: BoxDecoration(
          color: _surfaceColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background com imagem blur
            if (article.hasImage)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CachedNetworkImage(
                    imageUrl: article.imageUrl!,
                    fit: BoxFit.cover,
                    httpHeaders: {'User-Agent': 'Mozilla/5.0'},
                    errorWidget: (context, url, error) => Container(color: _borderColor),
                    imageBuilder: (context, imageProvider) {
                      return Container(
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: imageProvider,
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  _surfaceColor.withOpacity(0.88),
                                  _surfaceColor.withOpacity(0.94),
                                  _surfaceColor.withOpacity(0.97),
                                ],
                                stops: const [0.0, 0.5, 1.0],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

            // Conteúdo do card
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (article.hasImage)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: CachedNetworkImage(
                      imageUrl: article.imageUrl!,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      httpHeaders: {'User-Agent': 'Mozilla/5.0'},
                      placeholder: (context, url) => Container(
                        height: 160,
                        color: _borderColor,
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 160,
                        color: _borderColor,
                        child: Icon(Ionicons.image_outline, size: 40, color: _subTextColor),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _borderColor.withOpacity(0.5),
                            ),
                            child: ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: article.source.favicon,
                                width: 16,
                                height: 16,
                                fit: BoxFit.cover,
                                httpHeaders: {'User-Agent': 'Mozilla/5.0'},
                                errorWidget: (context, url, error) => Icon(
                                  Ionicons.globe_outline,
                                  size: 10,
                                  color: _subTextColor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              article.source.name,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _subTextColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (article.pubDate != null) ...[
                            Text(' · ', style: TextStyle(color: _subTextColor, fontSize: 11)),
                            Text(
                              _formatTime(article.pubDate!),
                              style: TextStyle(fontSize: 11, color: _subTextColor),
                            ),
                          ],
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => onTranslate(article),
                            child: Icon(Ionicons.language_outline, size: 16, color: _subTextColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        getTranslatedTitle(article) ?? article.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                          color: _textColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if ((article.description != null && article.description!.isNotEmpty) || 
                          getTranslatedDescription(article) != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          getTranslatedDescription(article) ?? (article.description ?? ''),
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: _subTextColor,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // CARD PEQUENO (GRID)
  Widget buildSmallNewsCard(NewsArticle article) {
    return GestureDetector(
      onTap: () => onTapUrl(article.link),
      child: Container(
        decoration: BoxDecoration(
          color: _surfaceColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (article.hasImage)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                child: CachedNetworkImage(
                  imageUrl: article.imageUrl!,
                  height: 90,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  httpHeaders: {'User-Agent': 'Mozilla/5.0'},
                  placeholder: (context, url) => Container(
                    height: 90,
                    color: _borderColor,
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 90,
                    color: _borderColor,
                    child: Icon(Ionicons.image_outline, size: 30, color: _subTextColor),
                  ),
                ),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _borderColor,
                          ),
                          child: ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: article.source.favicon,
                              width: 14,
                              height: 14,
                              fit: BoxFit.cover,
                              httpHeaders: {'User-Agent': 'Mozilla/5.0'},
                              errorWidget: (context, url, error) => Icon(
                                Ionicons.globe_outline,
                                size: 8,
                                color: _subTextColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            article.source.name,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: _subTextColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: Text(
                        getTranslatedTitle(article) ?? article.title,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                          color: _textColor,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
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

  // CARD COMPACTO (HORIZONTAL)
  Widget buildCompactNewsCard(NewsArticle article) {
    return GestureDetector(
      onTap: () => onTapUrl(article.link),
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: _surfaceColor,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ],
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _borderColor,
                  ),
                  child: ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: article.source.favicon,
                      width: 14,
                      height: 14,
                      fit: BoxFit.cover,
                      httpHeaders: {'User-Agent': 'Mozilla/5.0'},
                      errorWidget: (context, url, error) => Icon(
                        Ionicons.globe_outline,
                        size: 8,
                        color: _subTextColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    article.source.name,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _subTextColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Text(
                getTranslatedTitle(article) ?? article.title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                  color: _textColor,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (article.pubDate != null) ...[
              const SizedBox(height: 4),
              Text(
                _formatTime(article.pubDate!),
                style: TextStyle(fontSize: 10, color: _subTextColor),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // GRID DE NOTÍCIAS
  Widget buildLowQualityNewsGrid(List<NewsArticle> articles) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: articles.length > 4 ? 4 : articles.length,
      itemBuilder: (context, index) {
        return buildSmallNewsCard(articles[index]);
      },
    );
  }

  // LISTA HORIZONTAL
  Widget buildHorizontalNewsList(List<NewsArticle> articles) {
    return SizedBox(
      height: 130,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: articles.length,
        itemBuilder: (context, index) {
          return buildCompactNewsCard(articles[index]);
        },
      ),
    );
  }
}