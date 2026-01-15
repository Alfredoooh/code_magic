// rss_service.dart - Serviço para buscar RSS
import 'dart:async';
import 'dart:io'; // IMPORTANTE: Para usar HttpDate.parse()
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart' as xml;
import 'models.dart';

class RssService {
  Future<List<NewsArticle>> fetchArticles(NewsSource source) async {
    try {
      final response = await http.get(
        Uri.parse(source.rss),
        headers: {'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final document = xml.XmlDocument.parse(response.body);
        final items = document.findAllElements('item');

        List<NewsArticle> articles = [];

        for (var item in items) {
          try {
            final title = item.findElements('title').first.innerText.trim();
            final link = item.findElements('link').first.innerText.trim();
            var description = item.findElements('description').isNotEmpty
                ? item.findElements('description').first.innerText.trim()
                : null;

            if (description != null) {
              description = _cleanHtml(description);
            }

            String? imageUrl;
            if (item.findElements('media:content').isNotEmpty) {
              imageUrl = item.findElements('media:content').first.getAttribute('url');
            } else if (item.findElements('enclosure').isNotEmpty) {
              final enclosure = item.findElements('enclosure').first;
              final type = enclosure.getAttribute('type');
              if (type != null && type.startsWith('image/')) {
                imageUrl = enclosure.getAttribute('url');
              }
            } else if (item.findElements('media:thumbnail').isNotEmpty) {
              imageUrl = item.findElements('media:thumbnail').first.getAttribute('url');
            }

            if (imageUrl != null) {
              imageUrl = imageUrl.trim();
              if (!imageUrl.startsWith('http')) {
                imageUrl = null;
              }
            }

            DateTime? pubDate;
            if (item.findElements('pubDate').isNotEmpty) {
              try {
                final dateStr = item.findElements('pubDate').first.innerText;
                pubDate = _parseRssDate(dateStr);
              } catch (e) {
                pubDate = DateTime.now();
              }
            } else {
              pubDate = DateTime.now();
            }

            final article = NewsArticle(
              title: title,
              description: description,
              imageUrl: imageUrl,
              link: link,
              pubDate: pubDate,
              source: source,
            );

            articles.add(article);
          } catch (e) {
            continue;
          }
        }

        return articles;
      }
    } catch (e) {
      print('Error fetching ${source.name}: $e');
    }
    return [];
  }

  String _cleanHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&#x27;', "'")
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  DateTime _parseRssDate(String dateStr) {
    try {
      return DateTime.parse(dateStr);
    } catch (e) {
      try {
        return HttpDate.parse(dateStr); // CORRIGIDO: Agora funciona com import 'dart:io'
      } catch (e) {
        return DateTime.now();
      }
    }
  }

  Future<List<NewsArticle>> fetchAllArticles() async {
    List<NewsArticle> allArticles = [];

    final batches = _createBatches(RssSources.sources, 3);

    for (var batch in batches) {
      final results = await Future.wait(
        batch.map((source) => fetchArticles(source)),
      );

      for (var articles in results) {
        allArticles.addAll(articles);
      }

      await Future.delayed(const Duration(milliseconds: 350));
    }

    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    allArticles = allArticles.where((article) {
      if (article.pubDate == null) return false;
      return article.pubDate!.isAfter(sevenDaysAgo);
    }).toList();

    allArticles.sort((a, b) {
      if (a.pubDate == null) return 1;
      if (b.pubDate == null) return -1;
      return b.pubDate!.compareTo(a.pubDate!);
    });

    return allArticles;
  }

  List<List<NewsSource>> _createBatches(List<NewsSource> sources, int batchSize) {
    List<List<NewsSource>> batches = [];
    for (var i = 0; i < sources.length; i += batchSize) {
      batches.add(sources.sublist(
        i,
        i + batchSize > sources.length ? sources.length : i + batchSize,
      ));
    }
    return batches;
  }
}