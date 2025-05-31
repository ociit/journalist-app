import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sinau_firebase/models/journal_model.dart';
import 'package:sinau_firebase/pages/journal_detail_page.dart';
import 'package:sinau_firebase/utils/time_utils.dart'; // Pastikan path ini benar

class RejectedJournalsPage extends StatelessWidget {
  const RejectedJournalsPage({super.key});

  Future<void> _deleteRejectedJournal(BuildContext context, String journalId) async {
    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: const Text('Apakah Anda yakin ingin menghapus jurnal yang ditolak ini secara permanen?'),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Jurnal yang ditolak berhasil dihapus.'), backgroundColor: Colors.green),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus jurnal: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      // AppBar biasanya dari Dasbor Induk
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('journals')
            .where('status', isEqualTo: 'rejected')
            .orderBy('updatedAt', descending: true) // Jurnal yang baru ditolak muncul di atas
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            print("Error fetching rejected journals: ${snapshot.error}");
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Gagal memuat jurnal ditolak: ${snapshot.error}', textAlign: TextAlign.center),
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
                    Icon(Icons.mood_bad_outlined, size: 80, color: Colors.grey[400]),
                    const SizedBox(height: 20),
                    Text(
                      'Tidak ada jurnal yang ditolak.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(color: Colors.grey[600]),
                    ),
                     const SizedBox(height: 8),
                    Text(
                      'Semua jurnal yang diajukan telah diterima atau masih dalam proses review.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            );
          }

          final rejectedJournals = snapshot.data!.docs
              .map((doc) => JournalModel.fromFirestore(doc))
              .toList();

          return ListView.builder(
            padding: const EdgeInsets.all(12.0),
            itemCount: rejectedJournals.length,
            itemBuilder: (context, index) {
              final journal = rejectedJournals[index];
              return Card(
                elevation: 2.0,
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                shape: RoundedRectangleBorder(
                  side: BorderSide(color: theme.colorScheme.error.withOpacity(0.5), width: 1),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                color: theme.colorScheme.errorContainer.withOpacity(0.3), // Warna latar untuk item ditolak
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
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            // color: theme.colorScheme.onErrorContainer // Bisa disesuaikan
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.person_outline, size: 16, color: Colors.grey[700]),
                            const SizedBox(width: 6),
                            Expanded(
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
                        // Anda bisa menambahkan cuplikan konten jika dirasa perlu
                        // Text(
                        //   journal.content,
                        //   maxLines: 2,
                        //   overflow: TextOverflow.ellipsis,
                        //   style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black87.withOpacity(0.7)),
                        // ),
                        // const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Status: Ditolak',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.error,
                                    fontWeight: FontWeight.bold
                                  ),
                                ),
                                if (journal.updatedAt != null) // Jurnal ditolak saat diupdate statusnya
                                  Text(
                                    'Pada: ${TimeUtils.formatTimestamp(journal.updatedAt!)}',
                                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                                  ),
                                if (journal.reviewedBy != null)
                                  Text(
                                    'Oleh Reviewer: (...${journal.reviewedBy!.substring(journal.reviewedBy!.length - 6)})', // Tampilkan sebagian UID reviewer
                                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                                  ),
                              ],
                            ),
                            IconButton(
                              icon: Icon(Icons.delete_forever_outlined, color: theme.colorScheme.error),
                              tooltip: 'Hapus Jurnal Ditolak Ini',
                              onPressed: () => _deleteRejectedJournal(context, journal.id!),
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
