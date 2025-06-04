import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sinau_firebase/models/journal_model.dart'; // Pastikan path ini benar
import 'package:sinau_firebase/pages/journals/journal_detail_page.dart'; // Untuk navigasi ke detail
import 'package:sinau_firebase/utils/time_utils.dart'; // Pastikan path ini benar
import 'package:sinau_firebase/utils/custom_notification_utils.dart';

class JournalsInReviewPage extends StatefulWidget {
  final User currentUser; // Reviewer yang sedang login

  const JournalsInReviewPage({super.key, required this.currentUser});

  @override
  State<JournalsInReviewPage> createState() => _JournalsInReviewPageState();
}

class _JournalsInReviewPageState extends State<JournalsInReviewPage> {
  bool _isUpdatingStatus = false; // State untuk loading saat update status

  Future<void> _updateJournalStatus(String journalId, String newStatus) async {
    if (mounted) {
      setState(() => _isUpdatingStatus = true);
      // Menampilkan SnackBar loading yang lebih persisten jika diperlukan, atau cukup loading di dialog
    }

    Map<String, dynamic> dataToUpdate = {
      'status': newStatus,
      'reviewedBy': widget.currentUser.uid,
      'updatedAt': Timestamp.now(),
    };

    if (newStatus == 'published') {
      dataToUpdate['publishedAt'] = Timestamp.now();
    }

    try {
      await FirebaseFirestore.instance
          .collection('journals')
          .doc(journalId)
          .update(dataToUpdate);
      if (mounted) {
        TopNotification.show(
          context,
          'Status jurnal berhasil diubah menjadi "$newStatus".',
          type: NotificationType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        TopNotification.show(
          context,
          'Gagal mengubah status jurnal: $e',
          type: NotificationType.error,
        );
        print("Error updating journal status: $e");
      }
    } finally {
      if (mounted) setState(() => _isUpdatingStatus = false);
    }
  }

  void _showReviewActionDialog(BuildContext pageContext, JournalModel journal) {
    // Menggunakan pageContext
    showDialog(
      context: pageContext, // Menggunakan pageContext untuk dialog
      barrierDismissible: !_isUpdatingStatus, // Tidak bisa dismiss saat loading
      builder: (BuildContext dialogContext) {
        // Gunakan StatefulWidget untuk dialog jika ingin state loading di dalam dialog
        // Untuk kesederhanaan, loading diatur di _JournalsInReviewPageState
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          title: Text(
            'Review: ${journal.title}',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                _buildDialogInfoRow(
                  Icons.person_outline,
                  'Penulis:',
                  journal.username,
                ),
                _buildDialogInfoRow(
                  Icons.info_outline,
                  'Status Saat Ini:',
                  journal.status,
                ),
                const SizedBox(height: 12),
                Text(
                  'Ringkasan Konten:',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(pageContext).textTheme.bodySmall?.color,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    journal.content,
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop(); // Tutup dialog dulu
                    Navigator.push(
                      pageContext, // Gunakan context dari halaman
                      MaterialPageRoute(
                        builder: (context) =>
                            JournalDetailPage(journal: journal),
                      ),
                    );
                  },
                  child: const Text('Lihat Detail Jurnal Lengkap'),
                ),
              ],
            ),
          ),
          actionsAlignment: MainAxisAlignment.center,
          actionsPadding: const EdgeInsets.symmetric(
            horizontal: 16.0,
            vertical: 12.0,
          ),
          actions: <Widget>[
            if (_isUpdatingStatus)
              const Center(child: CircularProgressIndicator(strokeWidth: 2.5))
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.close),
                    label: const Text('Tolak'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange.shade700,
                      side: BorderSide(color: Colors.orange.shade700),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      _updateJournalStatus(journal.id!, 'rejected');
                    },
                  ),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text('Publish'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      _updateJournalStatus(journal.id!, 'published');
                    },
                  ),
                ],
              ),
              SizedBox(height: 10),
              TextButton(
                onPressed: _isUpdatingStatus
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.deepPurple[100],
                ),
                child: Text("Tutup", style: TextStyle(
                  color: Colors.black87
                ),
              )
            ),
          ],
        );
      },
    );
  }

  Widget _buildDialogInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey[700]),
          const SizedBox(width: 8),
          Text(
            '$label ',
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey[800],
            ),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: Colors.grey[800])),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('journals')
            .where('status', isEqualTo: 'in review')
            .orderBy('createdAt', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            print("Error fetching journals for review: ${snapshot.error}");
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Gagal memuat jurnal untuk direview: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.playlist_add_check_circle_outlined,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Tidak ada jurnal yang menunggu review.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Semua jurnal yang diajukan telah direview atau belum ada yang mengajukan.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final journalsToReview = snapshot.data!.docs
              .map((doc) => JournalModel.fromFirestore(doc))
              .toList();

          return ListView.builder(
            padding: const EdgeInsets.all(12.0),
            itemCount: journalsToReview.length,
            itemBuilder: (context, index) {
              final journal = journalsToReview[index];
              return Card(
                elevation: 3.0,
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12.0),
                  onTap: () {
                    _showReviewActionDialog(context, journal);
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
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.person_pin_outlined,
                              size: 16,
                              color: Colors.grey[700],
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                journal.username,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[700],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time_outlined,
                              size: 16,
                              color: Colors.grey[700],
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Diajukan: ${TimeUtils.formatTimestamp(journal.createdAt)}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Chip(
                            label: Text(
                              'Review Sekarang',
                              style: TextStyle(
                                color: theme.colorScheme.onSecondaryContainer,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            backgroundColor:
                                theme.colorScheme.secondaryContainer,
                            avatar: Icon(
                              Icons.arrow_forward,
                              size: 16,
                              color: theme.colorScheme.onSecondaryContainer,
                            ),
                          ),
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
