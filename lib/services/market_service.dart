import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class MarketService {
  static const String alphaVantageKey = 'demo';
  static const String finnhubKey = 'demo';
  static const String coinGeckoBase = 'https://api.coingecko.com/api/v3';
  static const String alphaVantageBase = 'https://www.alphavantage.co/query';
  static const String apiFootballKey = 'demo';
  static const String apiFootballBase = 'https://api-football-v1.p.rapidapi.com/v3';

  Future<Map<String, dynamic>> getStockQuote(String symbol) async {
    final response = await http.get(Uri.parse('$alphaVantageBase?function=GLOBAL_QUOTE&symbol=$symbol&apikey=$alphaVantageKey'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load stock quote');
  }

  Future<Map<String, dynamic>> getCryptoQuote(String id) async {
    final response = await http.get(Uri.parse('$coinGeckoBase/coins/$id'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load crypto quote');
  }

  Future<List<dynamic>> getEconomicCalendar() async {
    final response = await http.get(Uri.parse('https://finnhub.io/api/v1/calendar/economic?token=$finnhubKey'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['economicCalendar'];
    }
    throw Exception('Failed to load economic calendar');
  }

  Future<List<dynamic>> getFootballFixtures() async {
    final response = await http.get(
      Uri.parse('$apiFootballBase/fixtures?next=10'),
      headers: {'X-RapidAPI-Key': apiFootballKey},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['response'];
    }
    throw Exception('Failed to load football fixtures');
  }

  Future<List<dynamic>> getNews(String category) async {
    final response = await http.get(Uri.parse('https://finnhub.io/api/v1/news?category=$category&token=$finnhubKey'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load news');
  }

  WebSocketChannel getRealTimeChannel(String symbol) {
    final channel = WebSocketChannel.connect(Uri.parse('wss://ws.finnhub.io?token=$finnhubKey'));
    channel.sink.add(jsonEncode({'type': 'subscribe', 'symbol': symbol}));
    return channel;
  }
}