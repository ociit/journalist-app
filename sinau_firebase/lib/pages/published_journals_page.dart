import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sinau_firebase/models/journal_model.dart'; // Pastikan path ini benar
// Anda mungkin perlu helper TimeUtils lagi di sini, atau buat file util terpisah
// import 'package:sinau_firebase/utils/time_utils.dart'; // Contoh jika Anda memindahkannya

// Jika TimeUtils belum ada di file util terpisah, Anda bisa salin/definisikan lagi di sini
// atau pastikan bisa diakses. Untuk contoh ini, saya sertakan lagi.
class TimeUtils {
  static String formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return "${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}";
  }
}

class PublishedJournalsPage extends StatelessWidget {
  const PublishedJournalsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar biasanya sudah disediakan oleh Dasbor Induk (JournalistDashboard/ReviewerDashboard)
      // Jika halaman ini berdiri sendiri, Anda bisa tambahkan AppBar di sini:
      // appBar: AppBar(
      //   title: const Text('Jurnal Terpublish'),
      // ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('journals')
            .where('status', isEqualTo: 'published') // Filter hanya status 'published'
            .orderBy('publishedAt', descending: true) // Urutkan berdasarkan tanggal publish terbaru
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            print("Error fetching published journals: ${snapshot.error}");
            return Center(child: Text('Gagal memuat jurnal terpublish: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Belum ada jurnal yang terpublish saat ini.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            );
          }

          // Jika ada data jurnal terpublish
          final publishedJournals = snapshot.data!.docs
              .map((doc) => JournalModel.fromFirestore(doc))
              .toList();

          if (snapshot.hasData) {
            print("JOURNALS_IN_REVIEW_DEBUG: Jumlah dokumen 'in review' dari Firestore: ${snapshot.data!.docs.length}"); // DEBUG
            snapshot.data!.docs.forEach((doc) {
              print("JOURNALS_IN_REVIEW_DEBUG: Data Dokumen 'in review': ${doc.data()}"); // DEBUG
            });
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8.0), // Tambahkan padding keseluruhan
            itemCount: publishedJournals.length,
            itemBuilder: (context, index) {
              final journal = publishedJournals[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        journal.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Ditulis oleh: ${journal.username}', // Menampilkan username penulis
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontStyle: FontStyle.italic,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        journal.content,
                        maxLines: 4, // Tampilkan beberapa baris konten
                        overflow: TextOverflow.ellipsis, // Tambahkan ellipsis jika konten terlalu panjang
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          journal.publishedAt != null
                              ? 'Dipublish: ${TimeUtils.formatTimestamp(journal.publishedAt!)}'
                              // Jika karena suatu hal publishedAt null tapi status published, tampilkan status
                              : 'Status: ${journal.status[0].toUpperCase() + journal.status.substring(1)}',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                      // Opsional: Tombol "Baca Selengkapnya" jika konten panjang
                      // TextButton(
                      //   onPressed: () {
                      //     // Navigasi ke halaman detail jurnal (read-only)
                      //   },
                      //   child: Text("Baca Selengkapnya"),
                      // )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}