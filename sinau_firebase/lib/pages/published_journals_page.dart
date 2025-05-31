import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sinau_firebase/models/journal_model.dart';
import 'package:sinau_firebase/pages/journal_detail_page.dart';
import 'package:sinau_firebase/utils/time_utils.dart'; // Pastikan path ini benar
import 'package:sinau_firebase/utils/custom_notification_utils.dart';

class PublishedJournalsPage extends StatelessWidget {
  final String currentUserRole;

  const PublishedJournalsPage({super.key, required this.currentUserRole});

  Future<void> _deletePublishedJournal(BuildContext context, String journalId) async {
    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: const Text('Apakah Anda yakin ingin menghapus jurnal terpublish ini secara permanen?'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Hapus Permanen'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      try {
        await FirebaseFirestore.instance.collection('journals').doc(journalId).delete();
        TopNotification.show(context, 'Jurnal berhasil dihapus permanen.', type: NotificationType.success);
      } catch (e) {
        TopNotification.show(context, 'Gagal menghapus jurnal: $e', type: NotificationType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      // AppBar biasanya sudah ada di dasbor induk
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('journals')
            .where('status', isEqualTo: 'published')
            .orderBy('publishedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            print("Error fetching published journals: ${snapshot.error}");
            return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text('Gagal memuat jurnal terpublish: ${snapshot.error}', textAlign: TextAlign.center),
                )
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.public_off_outlined, size: 80, color: Colors.grey[400]),
                    const SizedBox(height: 20),
                    Text(
                      'Belum ada jurnal yang terpublish.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Jurnal yang telah direview dan disetujui akan muncul di sini.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            );
          }

          final publishedJournals = snapshot.data!.docs
              .map((doc) => JournalModel.fromFirestore(doc))
              .toList();

          return ListView.builder(
            padding: const EdgeInsets.all(12.0),
            itemCount: publishedJournals.length,
            itemBuilder: (context, index) {
              final journal = publishedJournals[index];
              return Card(
                elevation: 3.0,
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12.0),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => JournalDetailPage(journal: journal),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          journal.title,
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.person_outline, size: 16, color: Colors.grey[700]),
                            const SizedBox(width: 6),
                            Expanded( // Expanded agar nama penulis tidak overflow
                              child: Text(
                                journal.username,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey[700]
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          journal.content,
                          maxLines: 3, // Sedikit lebih banyak cuplikan
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black87),
                        ),
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Status: Terpublish',
                                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.green[700], fontWeight: FontWeight.bold),
                                ),
                                if (journal.publishedAt != null)
                                  Text(
                                    'Pada: ${TimeUtils.formatTimestamp(journal.publishedAt!)}',
                                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                                  ),
                              ],
                            ),
                            if (currentUserRole == 'Reviewer')
                              IconButton(
                                icon: Icon(Icons.delete_forever_outlined, color: theme.colorScheme.error),
                                tooltip: 'Hapus Jurnal Ini (Reviewer)',
                                onPressed: () => _deletePublishedJournal(context, journal.id!),
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
        },
      ),
    );
  }
}
