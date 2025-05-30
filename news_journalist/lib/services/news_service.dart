// lib/services/news_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import '../api/api_keys.dart';
import '../models/news_article.dart';
import 'package:flutter/foundation.dart';

class NewsService {
  final String _apiKey = ApiKeys.newsApiKey;
  final String _baseUrl = 'https://newsapi.org/v2/top-headlines';

  Future<List<NewsArticle>> fetchTopHeadlines({String country = 'us'}) async {
    final uri = Uri.parse('$_baseUrl?country=$country&apiKey=$_apiKey');
    debugPrint('Mengambil berita dari: $uri');

    try {
      final response = await http.get(uri);
      debugPrint('Status Code Berita: ${response.statusCode}');
      debugPrint('Response Body Berita: ${response.body}');
      print('News API URL: $uri'); // <-- Tambahkan ini
      print(
          'News API Status Code: ${response.statusCode}'); // <-- Tambahkan ini
      print('News API Response Body: ${response.body}'); // <-- Tambahkan ini

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        if (data['status'] == 'ok' && data['articles'] != null) {
          List<dynamic> articlesJson = data['articles'];
          print('Number of articles received: ${articlesJson.length}');
          debugPrint('Jumlah artikel yang diterima: ${articlesJson.length}');
          return articlesJson
              .where((article) =>
                  article['title'] != null && article['description'] != null)
              .map((json) => NewsArticle.fromJson(json))
              .toList();
        } else {
          debugPrint('News API Status not ok: ${data['message']}');
          throw Exception('Failed to load news: ${data['message']}');
        }
      } else {
        debugPrint('News HTTP Error: ${response.statusCode}, ${response.body}');
        throw Exception(
            'Failed to load news. Status code: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Caught error fetching news: $e');
      // Menangani error jaringan atau parsing JSON
      throw Exception('Error fetching news: $e');
    }
  }
}
