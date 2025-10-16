import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/news_article.dart';

class NewsService {
  Future<List<NewsArticle>> loadAdditionalNews() async {
    List<NewsArticle> newsFromSources = [];
    newsFromSources.addAll(await fetchFromCryptoCompare());
    newsFromSources.addAll(await fetchFromCoinDesk());
    return newsFromSources;
  }

  Future<List<NewsArticle>> loadCustomNews() async {
    try {
      final response = await http.get(
        Uri.parse('https://alfredoooh.github.io/database/data/News/news.json'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['articles'] as List)
            .map((article) => NewsArticle.fromCustomJson(article))
            .toList();
      }
    } catch (e) {}
    return [];
  }

  Future<List<NewsArticle>> fetchNewsFromNewsdata() async {
    try {
      final response = await http.get(
        Uri.parse('https://newsdata.io/api/1/news?apikey=pub_7d7d1ac2f86b4bc6b4662fd5d6dad47c&language=pt&country=br'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List? ?? [];
        return results.map((article) => NewsArticle.fromNewsdata(article)).toList();
      }
    } catch (e) {}
    return [];
  }

  Future<List<NewsArticle>> fetchNewsFromNewsApi() async {
    try {
      final response = await http.get(
        Uri.parse('https://newsapi.org/v2/top-headlines?apiKey=b2e4d59068e545abbdffaf947c371bcd&country=br'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['articles'] as List? ?? [];
        return results.map((article) => NewsArticle.fromNewsApi(article)).toList();
      }
    } catch (e) {}
    return [];
  }

  Future<List<NewsArticle>> fetchNewsFromGNews() async {
    try {
      final response = await http.get(
        Uri.parse('https://gnews.io/api/v4/top-headlines?token=5a3e9cdd12d67717cfb6643d25ebaeb5&lang=pt&country=br'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['articles'] as List? ?? [];
        return results.map((article) => NewsArticle.fromGNews(article)).toList();
      }
    } catch (e) {}
    return [];
  }

  Future<List<NewsArticle>> fetchFromCryptoCompare() async {
    try {
      final response = await http.get(
        Uri.parse('https://min-api.cryptocompare.com/data/v2/news/?lang=PT'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['Data'] as List? ?? [];
        return results.take(20).map((article) {
          return NewsArticle(
            title: article['title'] ?? '',
            description: article['body'] ?? '',
            imageUrl: article['imageurl'] ?? '',
            url: article['url'] ?? '',
            source: article['source'] ?? 'CryptoCompare',
            publishedAt: DateTime.fromMillisecondsSinceEpoch((article['published_on'] ?? 0) * 1000),
            category: 'crypto',
          );
        }).toList();
      }
    } catch (e) {}
    return [];
  }

  Future<List<NewsArticle>> fetchFromCoinDesk() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.coindesk.com/v1/bpi/currentprice.json'),
      );
      if (response.statusCode == 200) {
        return [
          NewsArticle(
            title: 'Bitcoin Price Update',
            description: 'Latest Bitcoin market data',
            imageUrl: 'https://cryptologos.cc/logos/bitcoin-btc-logo.png',
            url: 'https://www.coindesk.com',
            source: 'CoinDesk',
            publishedAt: DateTime.now(),
            category: 'crypto',
          )
        ];
      }
    } catch (e) {}
    return [];
  }

  Future<List<NewsArticle>> fetchFromTechCrunch() async {
    try {
      final response = await http.get(
        Uri.parse('https://newsapi.org/v2/top-headlines?sources=techcrunch&apiKey=b2e4d59068e545abbdffaf947c371bcd'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['articles'] as List? ?? [];
        return results.map((article) => NewsArticle.fromNewsApi(article)).toList();
      }
    } catch (e) {}
    return [];
  }

  Future<List<NewsArticle>> fetchFromTheVerge() async {
    try {
      final response = await http.get(
        Uri.parse('https://newsapi.org/v2/everything?domains=theverge.com&apiKey=b2e4d59068e545abbdffaf947c371bcd'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['articles'] as List? ?? [];
        return results.take(10).map((article) => NewsArticle.fromNewsApi(article)).toList();
      }
    } catch (e) {}
    return [];
  }

  Future<List<NewsArticle>> fetchFromBloomberg() async {
    try {
      final response = await http.get(
        Uri.parse('https://newsapi.org/v2/everything?domains=bloomberg.com&apiKey=b2e4d59068e545abbdffaf947c371bcd'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['articles'] as List? ?? [];
        return results.take(10).map((article) => NewsArticle.fromNewsApi(article)).toList();
      }
    } catch (e) {}
    return [];
  }

  Future<List<NewsArticle>> fetchFromCNBC() async {
    try {
      final response = await http.get(
        Uri.parse('https://newsapi.org/v2/top-headlines?sources=cnbc&apiKey=b2e4d59068e545abbdffaf947c371bcd'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['articles'] as List? ?? [];
        return results.map((article) => NewsArticle.fromNewsApi(article)).toList();
      }
    } catch (e) {}
    return [];
  }

  Future<List<NewsArticle>> fetchFromGoogleNews() async {
    try {
      final response = await http.get(
        Uri.parse('https://newsapi.org/v2/top-headlines?apiKey=b2e4d59068e545abbdffaf947c371bcd&language=pt&country=br&pageSize=20'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['articles'] as List? ?? [];
        return results.map((article) {
          return NewsArticle(
            title: article['title'] ?? '',
            description: article['description'] ?? '',
            imageUrl: article['urlToImage'] ?? '',
            url: article['url'] ?? '',
            source: 'Google News',
            publishedAt: article['publishedAt'] != null 
                ? DateTime.parse(article['publishedAt'])
                : DateTime.now(),
            category: 'general',
          );
        }).toList();
      }
    } catch (e) {}
    return [];
  }

  Future<List<NewsArticle>> fetchFromDuckDuckGo() async {
    try {
      // DuckDuckGo não possui API pública oficial de notícias
      // Usando NewsAPI como alternativa com query DuckDuckGo
      final response = await http.get(
        Uri.parse('https://newsapi.org/v2/everything?q=tecnologia OR economia OR mundo&apiKey=b2e4d59068e545abbdffaf947c371bcd&language=pt&sortBy=publishedAt&pageSize=15'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['articles'] as List? ?? [];
        return results.map((article) {
          return NewsArticle(
            title: article['title'] ?? '',
            description: article['description'] ?? '',
            imageUrl: article['urlToImage'] ?? '',
            url: article['url'] ?? '',
            source: 'DuckDuckGo News',
            publishedAt: article['publishedAt'] != null 
                ? DateTime.parse(article['publishedAt'])
                : DateTime.now(),
            category: 'general',
          );
        }).toList();
      }
    } catch (e) {}
    return [];
  }
}