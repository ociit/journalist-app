import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sinau_firebase/models/journal_model.dart';
import 'package:sinau_firebase/pages/journals/journal_detail_page.dart';
import 'package:sinau_firebase/utils/time_utils.dart'; // Pastikan path ini benar
import 'package:sinau_firebase/utils/custom_notification_utils.dart';

// Widget Card terpisah (bisa juga ditaruh di file sendiri dan diimpor)
class RejectedJournalCard extends StatefulWidget {
  final JournalModel journal;
  final ThemeData theme;
  final Future<void> Function(BuildContext, String)
  onDelete; // Fungsi hapus harus future

  const RejectedJournalCard({
    super.key,
    required this.journal,
    required this.theme,
    required this.onDelete,
  });

  @override
  State<RejectedJournalCard> createState() => _RejectedJournalCardState();
}

class _RejectedJournalCardState extends State<RejectedJournalCard> {
  String? _reviewerUsername;
  bool _isLoadingReviewer = false;

  @override
  void initState() {
    super.initState();
    if (widget.journal.reviewedBy != null &&
        widget.journal.reviewedBy!.isNotEmpty) {
      _fetchReviewerUsername(widget.journal.reviewedBy!);
    } else {
      _reviewerUsername = 'N/A';
    }
  }

  //? Fungsi untuk mencocokan username reviewer
  Future<void> _fetchReviewerUsername(String reviewerUid) async {
    if (!mounted) return;
    setState(() => _isLoadingReviewer = true);
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(reviewerUid)
          .get();
      if (userDoc.exists && userDoc.data() != null) {
        final userData = userDoc.data() as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _reviewerUsername = userData['username'] as String? ?? reviewerUid;
          });
        }
      } else {
        if (mounted)
          setState(
            () => _reviewerUsername =
                'Reviewer (ID: ...${reviewerUid.substring(reviewerUid.length - 6)})',
          );
      }
    } catch (e) {
      print("Error fetching reviewer username for rejected list: $e");
      if (mounted) setState(() => _reviewerUsername = 'Error memuat nama');
    } finally {
      if (mounted) setState(() => _isLoadingReviewer = false);
    }
  }

  //? Fungsi untuk mengembalikan jurnal yang telah terpublish ke status in-review
  Future<void> revertToInReview(BuildContext context, String journalId) async {
    bool? confirmRevert = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Konfirmasi Kembalikan Status'),
          content: const Text(
            'Apakah Anda yakin ingin mengembalikan status jurnal ini menjadi "Dalam Review"? Jurnal ini akan hilang dari daftar terpublish.',
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.orange,
              ), // Warna berbeda untuk aksi ini
              child: const Text('Kembalikan ke Review'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmRevert == true) {
      try {
        Map<String, dynamic> dataToUpdate = {
          'status': 'in review',
          'updatedAt': Timestamp.now(),
          'publishedAt': null, //!untuk Hapus tanggal publish
          // 'revertedBy': currentUser?.uid,
        };
        await FirebaseFirestore.instance
            .collection('journals')
            .doc(journalId)
            .update(dataToUpdate);
        TopNotification.show(
          context,
          'Status jurnal berhasil dikembalikan ke "Dalam Review".',
          type: NotificationType.info,
        );
      } catch (e) {
        TopNotification.show(
          context,
          'Gagal mengembalikan status jurnal: $e',
          type: NotificationType.error,
        );
        print("Error reverting journal status: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        side: BorderSide(
          color: widget.theme.colorScheme.error.withOpacity(0.6),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(12.0),
      ),
      // color: widget.theme.colorScheme.errorContainer.withOpacity(0.4),
      child: InkWell(
        borderRadius: BorderRadius.circular(11.0),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => JournalDetailPage(journal: widget.journal),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.journal.title,
                style: widget.theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: widget.theme.colorScheme.onErrorContainer.withOpacity(
                    0.9,
                  ),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 16,
                    color: widget.theme.colorScheme.onErrorContainer
                        .withOpacity(0.7),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      widget.journal.username, // Penulis jurnal
                      style: widget.theme.textTheme.bodyMedium?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: widget.theme.colorScheme.onErrorContainer
                            .withOpacity(0.7),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Status: Ditolak',
                          style: widget.theme.textTheme.bodySmall?.copyWith(
                            color: widget.theme.colorScheme.error,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (widget.journal.updatedAt != null)
                          Text(
                            'Pada: ${TimeUtils.formatTimestamp(widget.journal.updatedAt!)}',
                            style: widget.theme.textTheme.bodySmall?.copyWith(
                              color: widget.theme.colorScheme.onErrorContainer
                                  .withOpacity(0.6),
                            ),
                          ),
                        if (widget.journal.reviewedBy != null &&
                            widget.journal.reviewedBy!.isNotEmpty)
                          _isLoadingReviewer
                              ? Row(
                                  children: [
                                    Text(
                                      'Oleh: ',
                                      style: widget.theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: widget
                                                .theme
                                                .colorScheme
                                                .onErrorContainer
                                                .withOpacity(0.6),
                                          ),
                                    ),
                                    SizedBox(
                                      height: 10,
                                      width: 10,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 1.5,
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  'Oleh: ${_reviewerUsername ?? 'Memuat...'}', // Tampilkan username reviewer
                                  style: widget.theme.textTheme.bodySmall
                                      ?.copyWith(
                                        color: widget
                                            .theme
                                            .colorScheme
                                            .onErrorContainer
                                            .withOpacity(0.6),
                                      ),
                                ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () =>
                            revertToInReview(context, widget.journal.id!),
                        icon: Icon(Icons.undo_outlined),
                        color: Colors.orange.shade700,
                        tooltip: 'Kembalikan ke in-review',
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.delete_forever_outlined,
                          color: widget.theme.colorScheme.error,
                        ),
                        tooltip: 'Hapus Jurnal Ditolak Ini',
                        onPressed: () =>
                            widget.onDelete(context, widget.journal.id!),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RejectedJournalsPage extends StatelessWidget {
  const RejectedJournalsPage({super.key});

  // Fungsi _deleteRejectedJournal sekarang menjadi bagian dari RejectedJournalsPage
  // karena RejectedJournalCard akan memanggilnya via callback.
  Future<void> _deleteJournalFromList(
    BuildContext context,
    String journalId,
  ) async {
    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: const Text(
            'Apakah Anda yakin ingin menghapus jurnal yang ditolak ini secara permanen?',
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
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
        await FirebaseFirestore.instance
            .collection('journals')
            .doc(journalId)
            .delete();
        // context di sini adalah BuildContext dari RejectedJournalsPage
        TopNotification.show(
          context,
          'Jurnal yang ditolak berhasil dihapus.',
          type: NotificationType.success,
        );
      } catch (e) {
        TopNotification.show(
          context,
          'Gagal menghapus jurnal: $e',
          type: NotificationType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('journals')
            .where('status', isEqualTo: 'rejected')
            .orderBy('updatedAt', descending: true)
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
                child: Text(
                  'Gagal memuat jurnal ditolak: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              // Tampilan jika tidak ada jurnal ditolak
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.thumb_down_off_alt_outlined,
                      size: 80,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Tidak Ada Jurnal Ditolak',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tidak ada jurnal dengan status ditolak saat ini.',
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

          final rejectedJournals = snapshot.data!.docs
              .map((doc) => JournalModel.fromFirestore(doc))
              .toList();

          return ListView.builder(
            padding: const EdgeInsets.all(12.0),
            itemCount: rejectedJournals.length,
            itemBuilder: (context, index) {
              final journal = rejectedJournals[index];
              // Gunakan RejectedJournalCard
              return RejectedJournalCard(
                journal: journal,
                theme: theme,
                onDelete: _deleteJournalFromList, // Teruskan fungsi delete
              );
            },
          );
        },
      ),
    );
  }
}
