// lib/screens/news_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/post_model.dart';
import '../providers/theme_provider.dart';
import '../widgets/custom_icons.dart';

class NewsDetailScreen extends StatefulWidget {
  final Post post;

  const NewsDetailScreen({super.key, required this.post});

  @override
  State<NewsDetailScreen> createState() => _NewsDetailScreenState();
}

class _NewsDetailScreenState extends State<NewsDetailScreen> {
  // Simular notícias relacionadas (na prática, buscar do backend)
  List<Post> _relatedNews = [];

  @override
  void initState() {
    super.initState();
    _loadRelatedNews();
  }

  void _loadRelatedNews() {
    // TODO: Implementar busca real de notícias relacionadas
    // Por enquanto, criar exemplos mockados
    setState(() {
      _relatedNews = [
        // Aqui você buscaria notícias com tags/categorias similares
      ];
    });
  }

  Future<void> _openUrl(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _shareNews() async {
    // TODO: Implementar compartilhamento
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidade de compartilhamento em breve'),
        backgroundColor: Color(0xFF1877F2),
      ),
    );
  }

  Future<void> _bookmarkNews() async {
    // TODO: Implementar favoritos
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notícia salva nos favoritos'),
        backgroundColor: Color(0xFF31A24C),
      ),
    );
  }

  // Formatação de texto estilo WhatsApp
  List<TextSpan> _parseFormattedText(String text, Color textColor) {
    final spans = <TextSpan>[];
    final regex = RegExp(r'\*([^\*]+)\*|_([^_]+)_|~([^~]+)~|```([^`]+)```');
    int lastIndex = 0;

    for (final match in regex.allMatches(text)) {
      // Adiciona texto normal antes do match
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, match.start),
          style: TextStyle(color: textColor),
        ));
      }

      // Texto em negrito *texto*
      if (match.group(1) != null) {
        spans.add(TextSpan(
          text: match.group(1),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ));
      }
      // Texto em itálico _texto_
      else if (match.group(2) != null) {
        spans.add(TextSpan(
          text: match.group(2),
          style: TextStyle(
            fontStyle: FontStyle.italic,
            color: textColor,
          ),
        ));
      }
      // Texto riscado ~texto~
      else if (match.group(3) != null) {
        spans.add(TextSpan(
          text: match.group(3),
          style: TextStyle(
            decoration: TextDecoration.lineThrough,
            color: textColor,
          ),
        ));
      }
      // Texto monoespaçado ```texto```
      else if (match.group(4) != null) {
        spans.add(TextSpan(
          text: match.group(4),
          style: TextStyle(
            fontFamily: 'monospace',
            backgroundColor: textColor.withOpacity(0.1),
            color: textColor,
          ),
        ));
      }

      lastIndex = match.end;
    }

    // Adiciona texto restante
    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: TextStyle(color: textColor),
      ));
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final bgColor = isDark ? const Color(0xFF18191A) : const Color(0xFFF0F2F5);
    final cardColor = isDark ? const Color(0xFF242526) : Colors.white;
    final textColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);
    final secondaryColor = isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B);

    final domain = widget.post.newsUrl != null 
        ? Uri.parse(widget.post.newsUrl!).host.replaceAll('www.', '') 
        : '';

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        slivers: [
          // AppBar com imagem de fundo
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: cardColor,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: SvgPicture.string(
                  CustomIcons.arrowBack,
                  width: 24,
                  height: 24,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: SvgPicture.string(
                    CustomIcons.bookmark,
                    width: 24,
                    height: 24,
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                  onPressed: _bookmarkNews,
                ),
              ),
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: SvgPicture.string(
                    CustomIcons.share,
                    width: 24,
                    height: 24,
                    colorFilter: const ColorFilter.mode(
                      Colors.white,
                      BlendMode.srcIn,
                    ),
                  ),
                  onPressed: _shareNews,
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: widget.post.imageUrls != null && widget.post.imageUrls!.isNotEmpty
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: widget.post.imageUrls!.first,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF0F2F5),
                            child: const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1877F2)),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF0F2F5),
                            child: Center(
                              child: SvgPicture.string(
                                CustomIcons.brokenImage,
                                width: 64,
                                height: 64,
                                colorFilter: ColorFilter.mode(
                                  secondaryColor,
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // Overlay escuro
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.7),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : Container(
                      color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF0F2F5),
                    ),
            ),
          ),

          // Conteúdo
          SliverToBoxAdapter(
            child: Container(
              color: cardColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Badge e fonte
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF9800),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SvgPicture.string(
                                    CustomIcons.newspaper,
                                    width: 14,
                                    height: 14,
                                    colorFilter: const ColorFilter.mode(
                                      Colors.white,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'NOTÍCIA',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (domain.isNotEmpty) ...[
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFF0F2F5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Image.network(
                                      'https://www.google.com/s2/favicons?domain=$domain&sz=32',
                                      width: 14,
                                      height: 14,
                                      errorBuilder: (context, error, stackTrace) => 
                                          SvgPicture.string(
                                            CustomIcons.language,
                                            width: 14,
                                            height: 14,
                                            colorFilter: ColorFilter.mode(
                                              secondaryColor,
                                              BlendMode.srcIn,
                                            ),
                                          ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      domain,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: secondaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const Spacer(),
                            // Tempo de leitura estimado
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFF0F2F5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SvgPicture.string(
                                    CustomIcons.schedule,
                                    width: 14,
                                    height: 14,
                                    colorFilter: ColorFilter.mode(
                                      secondaryColor,
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${(widget.post.content.length / 200).ceil()} min',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: secondaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Summary destacado
                        if (widget.post.summary != null && widget.post.summary!.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1877F2).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF1877F2).withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1877F2).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: SvgPicture.string(
                                    CustomIcons.lightbulb,
                                    width: 20,
                                    height: 20,
                                    colorFilter: const ColorFilter.mode(
                                      Color(0xFF1877F2),
                                      BlendMode.srcIn,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: RichText(
                                    text: TextSpan(
                                      children: _parseFormattedText(
                                        widget.post.summary!,
                                        textColor,
                                      ),
                                      style: TextStyle(
                                        fontSize: 15,
                                        height: 1.6,
                                        color: textColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 24),

                        // Divider
                        Container(
                          height: 1,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.transparent,
                                (isDark ? const Color(0xFF3E4042) : const Color(0xFFDADADA)),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Conteúdo formatado
                        if (widget.post.content.isNotEmpty)
                          SelectableText.rich(
                            TextSpan(
                              children: _parseFormattedText(
                                widget.post.content,
                                textColor,
                              ),
                              style: TextStyle(
                                fontSize: 16,
                                height: 1.7,
                                color: textColor,
                              ),
                            ),
                          ),

                        const SizedBox(height: 32),

                        // Botão para fonte original
                        if (widget.post.newsUrl?.isNotEmpty == true)
                          Container(
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFF0F2F5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _openUrl(widget.post.newsUrl),
                                borderRadius: BorderRadius.circular(12),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1877F2).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: SvgPicture.string(
                                          CustomIcons.openInNew,
                                          width: 20,
                                          height: 20,
                                          colorFilter: const ColorFilter.mode(
                                            Color(0xFF1877F2),
                                            BlendMode.srcIn,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Ler matéria completa',
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                                color: textColor,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Acessar fonte original',
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: secondaryColor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      SvgPicture.string(
                                        CustomIcons.arrowForward,
                                        width: 20,
                                        height: 20,
                                        colorFilter: ColorFilter.mode(
                                          secondaryColor,
                                          BlendMode.srcIn,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                        const SizedBox(height: 32),

                        // Seção de notícias relacionadas
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF9800).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: SvgPicture.string(
                                CustomIcons.explore,
                                width: 20,
                                height: 20,
                                colorFilter: const ColorFilter.mode(
                                  Color(0xFFFF9800),
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Notícias Relacionadas',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: textColor,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Lista de notícias relacionadas
                        _relatedNews.isEmpty
                            ? Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFF0F2F5),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Column(
                                    children: [
                                      SvgPicture.string(
                                        CustomIcons.newspaper,
                                        width: 48,
                                        height: 48,
                                        colorFilter: ColorFilter.mode(
                                          secondaryColor.withOpacity(0.5),
                                          BlendMode.srcIn,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Nenhuma notícia relacionada no momento',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: secondaryColor,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : Column(
                                children: _relatedNews.map((news) {
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF3A3B3C) : const Color(0xFFF0F2F5),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => NewsDetailScreen(post: news),
                                            ),
                                          );
                                        },
                                        borderRadius: BorderRadius.circular(12),
                                        child: Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Row(
                                            children: [
                                              if (news.imageUrls != null && news.imageUrls!.isNotEmpty)
                                                ClipRRect(
                                                  borderRadius: BorderRadius.circular(8),
                                                  child: CachedNetworkImage(
                                                    imageUrl: news.imageUrls!.first,
                                                    width: 80,
                                                    height: 80,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      news.content,
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.w600,
                                                        color: textColor,
                                                      ),
                                                      maxLines: 2,
                                                      overflow: TextOverflow.ellipsis,
                                                    ),
                                                    if (news.summary != null) ...[
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        news.summary!,
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: secondaryColor,
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
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),

                        const SizedBox(height: 40),
                      ],
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