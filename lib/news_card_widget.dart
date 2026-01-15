// news_card_widgets.dart - Widgets de cards de notícias
import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:palette_generator/palette_generator.dart';
import 'models.dart';

class NewsCardWidgets {
  final bool isDarkTheme;
  final Function(String) onTapUrl;
  final String? Function(NewsArticle) getTranslatedTitle;
  final String? Function(NewsArticle) getTranslatedDescription;
  final Future<void> Function(NewsArticle) onTranslate;
  final Map<String, Color> colorCache;

  NewsCardWidgets({
    required this.isDarkTheme,
    required this.onTapUrl,
    required this.getTranslatedTitle,
    required this.getTranslatedDescription,
    required this.onTranslate,
    required this.colorCache,
  });

  Color get _surfaceColor => isDarkTheme ? const Color(0xFF1A1A1A) : Colors.white;
  Color get _textColor => isDarkTheme ? const Color(0xFFE4E6EB) : const Color(0xFF050505);
  Color get _subTextColor => isDarkTheme ? const Color(0xFFB0B3B8) : const Color(0xFF65676B);
  Color get _borderColor => isDarkTheme ? const Color(0xFF3A3B3C) : const Color(0xFFDDDFE2);

  // OTIMIZADO: Extração de cor rápida e com cache
  Future<Color> _getImageColor(String? imageUrl) async {
    if (imageUrl == null || imageUrl.isEmpty) return const Color(0xFF2374E1);
    
    // Verificar cache primeiro
    if (colorCache.containsKey(imageUrl)) {
      return colorCache[imageUrl]!;
    }

    try {
      final provider = CachedNetworkImageProvider(imageUrl);
      
      // OTIMIZADO: Reduzir cores analisadas de 20 para 8 (muito mais rápido)
      final palette = await PaletteGenerator.fromImageProvider(
        provider,
        maximumColorCount: 8, // Reduzido para ganhar performance
        timeout: const Duration(seconds: 3), // Timeout para não travar
      );
      
      final color = palette.dominantColor?.color ?? 
                    palette.vibrantColor?.color ?? 
                    const Color(0xFF2374E1);
      
      colorCache[imageUrl] = color;
      return color;
    } catch (e) {
      colorCache[imageUrl] = const Color(0xFF2374E1);
      return const Color(0xFF2374E1);
    }
  }

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

  // CARD PRINCIPAL COM IMAGEM DE ALTA QUALIDADE
  Widget buildNewsCard(NewsArticle article) {
    return GestureDetector(
      onTap: () => onTapUrl(article.link),
      child: FutureBuilder<Color>(
        future: _getImageColor(article.imageUrl),
        initialData: colorCache[article.imageUrl] ?? const Color(0xFF2374E1), // Mostrar cor do cache imediatamente
        builder: (context, snap) {
          final primaryColor = snap.data ?? const Color(0xFF2374E1);
          return Container(
            decoration: BoxDecoration(
              color: _surfaceColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(color: primaryColor.withOpacity(0.12), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                ),
                if (article.hasImage)
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                        child: CachedNetworkImage(
                          imageUrl: article.imageUrl!,
                          height: 220,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          httpHeaders: {'User-Agent': 'Mozilla/5.0'},
                          placeholder: (context, url) => Container(
                            height: 220,
                            color: _borderColor,
                            child: Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) {
                            return Container(
                              height: 220,
                              color: _borderColor,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Ionicons.image_outline, size: 48, color: _subTextColor),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Imagem indisponivel',
                                    style: TextStyle(fontSize: 12, color: _subTextColor),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 36,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white.withOpacity(isDarkTheme ? 0.02 : 0.0),
                                Colors.black.withOpacity(isDarkTheme ? 0.55 : 0.10),
                              ],
                              stops: const [0.0, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _borderColor.withOpacity(0.5),
                            ),
                            child: ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: article.source.favicon,
                                width: 22,
                                height: 22,
                                fit: BoxFit.cover,
                                httpHeaders: {'User-Agent': 'Mozilla/5.0'},
                                errorWidget: (context, url, error) => Icon(
                                  Ionicons.globe_outline,
                                  size: 12,
                                  color: _subTextColor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            article.source.name,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _subTextColor,
                            ),
                          ),
                          if (article.pubDate != null) ...[
                            Text(' · ', style: TextStyle(color: _subTextColor)),
                            Text(
                              _formatTime(article.pubDate!),
                              style: TextStyle(fontSize: 12, color: _subTextColor),
                            ),
                          ],
                          const Spacer(),
                          GestureDetector(
                            onTap: () => onTranslate(article),
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Icon(Ionicons.language_outline, size: 18, color: _subTextColor),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        getTranslatedTitle(article) ?? article.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                          color: _textColor,
                        ),
                      ),
                      if ((article.description != null && article.description!.isNotEmpty) || 
                          getTranslatedDescription(article) != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          getTranslatedDescription(article) ?? (article.description ?? ''),
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.4,
                            color: _subTextColor,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
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
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (article.hasImage)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: CachedNetworkImage(
                      imageUrl: article.imageUrl!,
                      height: 100,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      httpHeaders: {'User-Agent': 'Mozilla/5.0'},
                      placeholder: (context, url) => Container(
                        height: 100,
                        color: _borderColor,
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 100,
                        color: _borderColor,
                        child: Icon(Ionicons.image_outline, color: _subTextColor),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 14,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(isDarkTheme ? 0.35 : 0.08),
                          ],
                          stops: const [0.0, 1.0],
                        ),
                      ),
                    ),
                  ),
                ],
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
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _borderColor,
                          ),
                          child: ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: article.source.favicon,
                              width: 20,
                              height: 20,
                              fit: BoxFit.cover,
                              httpHeaders: {'User-Agent': 'Mozilla/5.0'},
                              errorWidget: (context, url, error) => Icon(
                                Ionicons.globe_outline,
                                size: 12,
                                color: _subTextColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
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
                    const SizedBox(height: 4),
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
        width: 200,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: _surfaceColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _borderColor,
                  ),
                  child: ClipOval(
                    child: CachedNetworkImage(
                      imageUrl: article.source.favicon,
                      width: 18,
                      height: 18,
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
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Text(
                getTranslatedTitle(article) ?? article.title,
                style: TextStyle(
                  fontSize: 13,
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
                style: TextStyle(fontSize: 11, color: _subTextColor),
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
      height: 140,
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