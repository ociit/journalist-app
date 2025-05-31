import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sinau_firebase/models/journal_model.dart'; // Pastikan path ini benar

// Jika TimeUtils belum ada di file util terpisah, Anda bisa salin/definisikan lagi di sini
// atau pastikan bisa diakses.
class TimeUtils {
  static String formatTimestamp(Timestamp timestamp) {
    DateTime dateTime = timestamp.toDate();
    return "${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}";
  }
}

class JournalsInReviewPage extends StatefulWidget {
  final User currentUser; // Reviewer yang sedang login

  const JournalsInReviewPage({super.key, required this.currentUser});

  @override
  State<JournalsInReviewPage> createState() => _JournalsInReviewPageState();
}

class _JournalsInReviewPageState extends State<JournalsInReviewPage> {

  // Fungsi untuk update status jurnal di Firestore
  Future<void> _updateJournalStatus(String journalId, String newStatus) async {
    if (mounted) { // Menambahkan indikator loading sederhana
        ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Memperbarui status...'), duration: Duration(seconds: 1)),
      );
    }

    Map<String, dynamic> dataToUpdate = {
      'status': newStatus,
      'reviewedBy': widget.currentUser.uid, // Catat siapa yang mereview
      'updatedAt': Timestamp.now(),
    };

    if (newStatus == 'published') {
      dataToUpdate['publishedAt'] = Timestamp.now(); // Catat waktu publish
    }
    // Anda bisa menambahkan field 'rejectionReason' jika statusnya 'rejected'

    try {
      await FirebaseFirestore.instance.collection('journals').doc(journalId).update(dataToUpdate);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status jurnal berhasil diubah menjadi "$newStatus".'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengubah status jurnal: $e'), backgroundColor: Colors.red),
        );
        print("Error updating journal status: $e");
      }
    }
  }

  // Menampilkan dialog untuk aksi review
  void _showReviewActionDialog(JournalModel journal) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Review Jurnal: "${journal.title}"'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Ditulis oleh: ${journal.username}'),
                Text('Status saat ini: ${journal.status}'),
                const SizedBox(height: 16),
                Text('Isi Jurnal:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(4)
                  ),
                  child: Text(journal.content, maxLines: 10, overflow: TextOverflow.ellipsis)
                ),
              ],
            ),
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.grey),
              child: const Text('Tutup'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: Colors.orange),
                  child: const Text('Tolak'),
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    _updateJournalStatus(journal.id!, 'rejected');
                  },
                ),
                const SizedBox(width: 8),
                ElevatedButton( // Menggunakan ElevatedButton agar lebih menonjol
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text('Publish', style: TextStyle(color: Colors.white)),
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    _updateJournalStatus(journal.id!, 'published');
                  },
                ),
              ],
            )
          ],
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar biasanya dari Dasbor Induk
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('journals')
            .where('status', isEqualTo: 'in review') // Filter hanya status 'in review'
            .orderBy('createdAt', descending: false) // Tampilkan yang paling lama diajukan dulu
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            print("Error fetching journals for review: ${snapshot.error}");
            return Center(child: Text('Gagal memuat jurnal untuk direview: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Tidak ada jurnal yang menunggu untuk direview saat ini.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
              ),
            );
          }

          final journalsToReview = snapshot.data!.docs
              .map((doc) => JournalModel.fromFirestore(doc))
              .toList();
          // ...
          
          if (snapshot.hasData) {
            print("JOURNALS_IN_REVIEW_DEBUG: Jumlah dokumen 'in review' dari Firestore: ${snapshot.data!.docs.length}"); // DEBUG
            snapshot.data!.docs.forEach((doc) {
              print("JOURNALS_IN_REVIEW_DEBUG: Data Dokumen 'in review': ${doc.data()}"); // DEBUG
            });
          }
          // ...

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: journalsToReview.length,
            itemBuilder: (context, index) {
              final journal = journalsToReview[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                child: ListTile(
                  title: Text(journal.title, style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    'Oleh: ${journal.username}\nDiajukan: ${TimeUtils.formatTimestamp(journal.createdAt)}',
                  ),
                  isThreeLine: true, // Agar subtitle bisa 2 baris jika perlu
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.blueAccent),
                  onTap: () {
                    _showReviewActionDialog(journal); // Tampilkan dialog aksi saat item diklik
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}