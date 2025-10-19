// lib/screens/home_screen_helper.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import '../widgets/app_colors.dart';
import '../widgets/app_ui_components.dart';
import '../models/news_article.dart';
import 'home_crypto_section.dart' as crypto_section;

class HomeScreenHelper {
  static Future<void> loadNews(Function(List<NewsArticle>, bool) callback) async {
    callback([], true);

    try {
      final response = await http.get(
        Uri.parse(
            'https://newsdata.io/api/1/news?apikey=pub_7d7d1ac2f86b4bc6b4662fd5d6dad47c&language=pt&country=br'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final results = data['results'] as List? ?? [];

        List<NewsArticle> articles = [];
        for (var article in results.take(10)) {
          articles.add(NewsArticle.fromNewsdata(article));
        }

        callback(articles, false);
      } else {
        callback([], false);
      }
    } catch (e) {
      callback([], false);
    }
  }

  static Future<void> loadStats(Function(int, int) callback) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final convSnapshot = await FirebaseFirestore.instance
          .collection('conversations')
          .where('participants', arrayContains: user.uid)
          .get();

      int totalMessages = 0;
      for (var conv in convSnapshot.docs) {
        final messagesSnapshot = await FirebaseFirestore.instance
            .collection('conversations')
            .doc(conv.id)
            .collection('messages')
            .where('senderId', isEqualTo: user.uid)
            .get();
        totalMessages += messagesSnapshot.docs.length;
      }

      final groupSnapshot = await FirebaseFirestore.instance
          .collection('groups')
          .where('members', arrayContains: user.uid)
          .get();

      callback(totalMessages, groupSnapshot.docs.length);
    } catch (e) {
      callback(0, 0);
    }
  }

  static Future<void> loadCryptoData(Function(List<crypto_section.CryptoData>, bool) callback) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.binance.com/api/v3/ticker/24hr'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final usdtPairs = data.where((coin) =>
            coin['symbol'].toString().endsWith('USDT') &&
            !coin['symbol'].toString().contains('DOWN') &&
            !coin['symbol'].toString().contains('UP') &&
            !coin['symbol'].toString().contains('BEAR') &&
            !coin['symbol'].toString().contains('BULL')).toList();

        usdtPairs.sort((a, b) => double.parse(b['quoteVolume'].toString()).compareTo(double.parse(a['quoteVolume'].toString())));

        final cryptoData = usdtPairs.take(3).map((coin) => crypto_section.CryptoData.fromBinance(coin)).toList();
        callback(cryptoData, false);
      } else {
        callback([], false);
      }
    } catch (e) {
      callback([], false);
    }
  }

  static Widget buildNewsCard({
    required NewsArticle article,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          if (article.imageUrl != null)
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  article.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: isDark ? AppColors.darkBorder : Color(0xFFF2F2F7),
                    child: Icon(
                      Icons.photo,
                      color: Colors.grey,
                      size: 40,
                    ),
                  ),
                ),
              ),
            ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 12,
            left: 12,
            right: 12,
            child: Text(
              article.title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}