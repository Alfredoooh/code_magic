// lib/screens/news_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/post_model.dart';
import '../providers/theme_provider.dart';

class NewsDetailScreen extends StatelessWidget {
  final Post post;

  const NewsDetailScreen({super.key, required this.post});

  Future<void> _openUrl(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeProvider>().isDarkMode;
    final bgColor = isDark ? const Color(0xFF18191A) : const Color(0xFFF0F2F5);
    final cardColor = isDark ? const Color(0xFF242526) : Colors.white;
    final textColor = isDark ? const Color(0xFFE4E6EB) : const Color(0xFF050505);
    final secondaryColor = isDark ? const Color(0xFFB0B3B8) : const Color(0xFF65676B);

    final domain = post.newsUrl != null 
        ? Uri.parse(post.newsUrl!).host.replaceAll('www.', '') 
        : '';

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (post.newsUrl?.isNotEmpty == true)
            IconButton(
              icon: Icon(Icons.open_in_new, color: textColor),
              onPressed: () => _openUrl(post.newsUrl),
              tooltip: 'Abrir no navegador',
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Container(
          color: cardColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Imagem principal
              if (post.imageUrls != null && post.imageUrls!.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: post.imageUrls!.first,
                  width: double.infinity,
                  height: 300,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    height: 300,
                    color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF0F2F5),
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1877F2)),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 300,
                    color: isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF0F2F5),
                    child: const Icon(Icons.broken_image, size: 64),
                  ),
                ),

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge NEWS + Fonte
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF9800),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'NEWS',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        if (domain.isNotEmpty) ...[
                          const SizedBox(width: 12),
                          Image.network(
                            'https://www.google.com/s2/favicons?domain=$domain&sz=32',
                            width: 16,
                            height: 16,
                            errorBuilder: (context, error, stackTrace) => 
                                const Icon(Icons.language, size: 16),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              domain,
                              style: TextStyle(
                                fontSize: 13,
                                color: secondaryColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Summary (descrição resumida)
                    if (post.summary != null && post.summary!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark 
                              ? const Color(0xFF3A3B3C) 
                              : const Color(0xFFF0F2F5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          post.summary!,
                          style: TextStyle(
                            fontSize: 15,
                            color: textColor,
                            height: 1.5,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),

                    const SizedBox(height: 20),

                    // Divider
                    Container(
                      height: 1,
                      color: isDark ? const Color(0xFF3E4042) : const Color(0xFFDADADA),
                    ),

                    const SizedBox(height: 20),

                    // Content completo (expandido e scrollável)
                    if (post.content.isNotEmpty)
                      SelectableText(
                        post.content,
                        style: TextStyle(
                          fontSize: 16,
                          color: textColor,
                          height: 1.6,
                        ),
                      ),

                    const SizedBox(height: 24),

                    // Botão flutuante para abrir URL original
                    if (post.newsUrl?.isNotEmpty == true)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark 
                              ? const Color(0xFF3A3B3C) 
                              : const Color(0xFFF0F2F5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF1877F2).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: Color(0xFF1877F2),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Leia a notícia completa na fonte original',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: secondaryColor,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.open_in_new,
                                color: Color(0xFF1877F2),
                                size: 20,
                              ),
                              onPressed: () => _openUrl(post.newsUrl),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}