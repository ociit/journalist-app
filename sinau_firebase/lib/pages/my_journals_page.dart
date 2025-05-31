import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sinau_firebase/models/journal_model.dart';
import 'package:sinau_firebase/pages/my_journals_page.dart'; // Pastikan Anda sudah membuat model ini
import 'package:sinau_firebase/pages/add_edit_journal_page.dart'; // Halaman ini akan kita buat selanjutnya

class MyJournalsPage extends StatefulWidget {
  final User currentUser; // Pengguna Auth saat ini
  final String currentUsername; // Username pengguna saat ini (dari Firestore user document)

  const MyJournalsPage({
    super.key,
    required this.currentUser,
    required this.currentUsername,
  });

  @override
  State<MyJournalsPage> createState() => _MyJournalsPageState();
}

class _MyJournalsPageState extends State<MyJournalsPage> {
  // Fungsi untuk menghapus jurnal dengan konfirmasi
  Future<void> _deleteJournal(String journalId) async {
    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: const Text('Apakah Anda yakin ingin menghapus jurnal ini? Tindakan ini tidak dapat dibatalkan.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Hapus'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      try {
        await FirebaseFirestore.instance.collection('journals').doc(journalId).delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Jurnal berhasil dihapus.'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menghapus jurnal: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar bisa jadi bagian dari JournalistDashboard, jadi opsional di sini
      // appBar: AppBar(title: const Text('Jurnal Saya')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('journals')
            .where('userId', isEqualTo: widget.currentUser.uid) // Filter jurnal milik pengguna saat ini
            .orderBy('createdAt', descending: true) // Urutkan berdasarkan terbaru
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            print("Error stream journals: ${snapshot.error}");
            return const Center(child: Text('Gagal memuat jurnal.'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Anda belum memiliki jurnal. Tekan tombol "+" untuk membuat jurnal baru.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            );
          }

          if (snapshot.hasData) {
            print("MY_JOURNALS_DEBUG: Jumlah dokumen dari Firestore: ${snapshot.data!.docs.length}"); // DEBUG
            snapshot.data!.docs.forEach((doc) {
              print("MY_JOURNALS_DEBUG: Data Dokumen: ${doc.data()}"); // DEBUG
              try {
                JournalModel.fromFirestore(doc); // Coba parsing
                print("MY_JOURNALS_DEBUG: Parsing dokumen ${doc.id} BERHASIL."); // DEBUG
              } catch (e, s) {
                print("!!!!!!!! MY_JOURNALS_DEBUG: GAGAL parsing dokumen ${doc.id}: $e"); // DEBUG
                print("!!!!!!!! StackTrace: $s"); // DEBUG
              }
            });
          }

          // Jika ada data jurnal
          final journals = snapshot.data!.docs
              .map((doc) => JournalModel.fromFirestore(doc))
              .toList();

          return ListView.builder(
            itemCount: journals.length,
            itemBuilder: (context, index) {
              final journal = journals[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  title: Text(journal.title, style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    'Status: ${journal.status} - Dibuat: ${TimeUtils.formatTimestamp(journal.createdAt)}', // Kita perlu helper untuk format tanggal
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Theme.of(context).primaryColor),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AddEditJournalPage(
                                currentUser: widget.currentUser,
                                currentUsername: widget.currentUsername,
                                journalToEdit: journal, // Kirim jurnal untuk diedit
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () => _deleteJournal(journal.id!),
                      ),
                    ],
                  ),
                  onTap: () {
                     // Opsional: Navigasi ke halaman detail jurnal jika ada
                     // Navigator.push(context, MaterialPageRoute(builder: (context) => JournalDetailPage(journal: journal)));
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Detail untuk '${journal.title}' belum diimplementasikan.")));
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddEditJournalPage(
                currentUser: widget.currentUser,
                currentUsername: widget.currentUsername,
              ), // Tidak ada journalToEdit, berarti membuat baru
            ),
          );
        },
        tooltip: 'Buat Jurnal Baru',
        child: const Icon(Icons.add),
      ),
    );
  }
}

// Helper class untuk format Timestamp (bisa ditaruh di file util terpisah)
class TimeUtils {
  static String formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    // Format sederhana, Anda bisa menggunakan package 'intl' untuk format yang lebih kompleks
    return "${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}";
  }
}