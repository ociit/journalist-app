// lib/pages/news_page.dart

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart'; // Untuk format tanggal
import '../models/news_article.dart';
import '../services/news_service.dart';
import 'news_detail_page.dart'; // Import halaman detail berita yang baru

class NewsPage extends StatefulWidget {
  @override
  _NewsPageState createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  late Future<List<NewsArticle>> _newsArticlesFuture;

  @override
  void initState() {
    super.initState();
    _newsArticlesFuture = NewsService().fetchTopHeadlines();
  }

  // Fungsi _launchURL sekarang hanya untuk fallback jika artikel tidak punya URL detail
  Future<void> launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tidak dapat membuka link: $url')),
      );
      throw 'Could not launch $url';
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Tanggal tidak diketahui';
    try {
      final dateTime = DateTime.parse(dateString);
      return DateFormat('dd MMMM yyyy, HH:mm', 'id_ID').format(dateTime); // Format tanggal
    } catch (e) {
      return dateString; // Kembali ke string asli jika parsing gagal
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Berita Terkini',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: FutureBuilder<List<NewsArticle>>(
        future: _newsArticlesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
                child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 60, color: Colors.redAccent),
                  SizedBox(height: 10),
                  Text(
                    'Gagal memuat berita: ${snapshot.error}',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.openSans(fontSize: 16, color: Colors.redAccent),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        _newsArticlesFuture = NewsService().fetchTopHeadlines(); // Coba lagi
                      });
                    },
                    icon: Icon(Icons.refresh),
                    label: Text('Coba Lagi', style: GoogleFonts.poppins()),
                  )
                ],
              ),
            ));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
                child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.newspaper, size: 80, color: Colors.grey[400]),
                SizedBox(height: 10),
                Text(
                  'Tidak ada berita yang ditemukan.',
                  style: GoogleFonts.openSans(fontSize: 18, color: Colors.grey[600]),
                ),
                Text(
                  'Coba ganti negara di NewsService.',
                  style: GoogleFonts.openSans(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final article = snapshot.data![index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                  child: InkWell(
                    // === MODIFIKASI DISINI ===
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NewsDetailPage(article: article),
                        ),
                      );
                    },
                    // === AKHIR MODIFIKASI ===
                    borderRadius: BorderRadius.circular(15),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (article.urlToImage != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10.0),
                              child: Image.network(
                                article.urlToImage!,
                                height: 200, // Tinggi gambar lebih besar
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                  height: 200,
                                  width: double.infinity,
                                  color: Colors.grey[200],
                                  child: Icon(Icons.broken_image, size: 50, color: Colors.grey[400]),
                                  alignment: Alignment.center,
                                  ),
                              ),
                            ),
                          SizedBox(height: 15),
                          Text(
                            article.title,
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            article.description,
                            maxLines: 4, // Tampilkan lebih banyak baris deskripsi
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.openSans(
                              fontSize: 15,
                              color: Colors.grey[700],
                            ),
                          ),
                          SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                article.sourceName != null
                                    ? 'Sumber: ${article.sourceName}'
                                    : 'Sumber tidak diketahui',
                                style: GoogleFonts.openSans(
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey[600],
                                ),
                              ),
                              Text(
                                _formatDate(article.publishedAt),
                                style: GoogleFonts.openSans(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}