// lib/models/news_article.dart

class NewsArticle {
  final String title;
  final String description;
  final String url;
  final String? urlToImage;
  final String? publishedAt;
  final String? author;
  final String? sourceName;
  final String? content; // Tambahkan ini

  NewsArticle({
    required this.title,
    required this.description,
    required this.url,
    this.urlToImage,
    this.publishedAt,
    this.author,
    this.sourceName,
    this.content, // Tambahkan ini
  });

  factory NewsArticle.fromJson(Map<String, dynamic> json) {
    return NewsArticle(
      title: json['title'] ?? 'No Title',
      description: json['description'] ?? 'No Description',
      url: json['url'] ?? 'https://example.com', // Fallback URL
      urlToImage: json['urlToImage'],
      publishedAt: json['publishedAt'],
      author: json['author'],
      sourceName: json['source'] != null ? json['source']['name'] : null,
      content: json['content'], // Tambahkan ini
    );
  }
}