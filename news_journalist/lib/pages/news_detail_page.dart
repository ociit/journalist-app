// lib/pages/news_detail_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/news_article.dart';

class NewsDetailPage extends StatelessWidget {
  final NewsArticle article;

  const NewsDetailPage({Key? key, required this.article}) : super(key: key);

  Future<void> _launchURL(String url, BuildContext context) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tidak dapat membuka link: $url')),
      );
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Tanggal tidak diketahui';
    try {
      final dateTime = DateTime.parse(dateString);
      return DateFormat('dd MMMM, HH:mm', 'id_ID').format(dateTime);
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tentukan teks yang akan ditampilkan: gunakan content jika ada, jika tidak, description.
    // Hapus '[...]' jika ada di akhir content
    String articleText = article.content != null && article.content!.isNotEmpty
        ? article.content!.replaceAll(
            RegExp(r'\s*\[\+\d+ chars\]$'), '') // Hapus "[+N chars]"
        : article.description;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Detail Berita',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar Artikel
            if (article.urlToImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(15.0),
                child: Image.network(
                  article.urlToImage!,
                  height: 250,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 250,
                    width: double.infinity,
                    color: Colors.grey[200],
                    child: Icon(Icons.broken_image,
                        size: 70, color: Colors.grey[400]),
                    alignment: Alignment.center,
                  ),
                ),
              ),
            const SizedBox(height: 20),

            // Judul Artikel
            Text(
              article.title,
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 10),

            // Info Sumber dan Tanggal
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    article.sourceName != null
                        ? 'Sumber: ${article.sourceName}'
                        : 'Sumber tidak diketahui',
                    style: GoogleFonts.openSans(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDate(article.publishedAt),
                  style: GoogleFonts.openSans(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),

            // Author (jika ada)
            if (article.author != null && article.author!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 15.0),
                child: Text(
                  'Penulis: ${article.author}',
                  style: GoogleFonts.openSans(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
              ),

            // Teks Artikel (description atau content)
            Text(
              articleText, // Menggunakan teks yang sudah ditentukan
              style: GoogleFonts.openSans(
                fontSize: 16,
                height: 1.5,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),

            // Tombol "Baca Selengkapnya"
            ElevatedButton.icon(
              onPressed: () => _launchURL(article.url, context),
              icon: const Icon(Icons.link),
              label: Text('Baca Selengkapnya di Web',
                  style: GoogleFonts.poppins()),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.secondary,
                foregroundColor: Theme.of(context).colorScheme.onSecondary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
