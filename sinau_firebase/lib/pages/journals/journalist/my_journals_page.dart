import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sinau_firebase/models/journal_model.dart';
import 'package:sinau_firebase/pages/journals/journalist/add_edit_journal_page.dart';
import 'package:sinau_firebase/pages/journals/journal_detail_page.dart';
import 'package:sinau_firebase/utils/time_utils.dart'; // Pastikan path ini benar
import 'package:sinau_firebase/utils/custom_notification_utils.dart';

class MyJournalsPage extends StatefulWidget {
  final User currentUser;
  final String currentUsername;

  const MyJournalsPage({
    super.key,
    required this.currentUser,
    required this.currentUsername,
  });

  @override
  State<MyJournalsPage> createState() => _MyJournalsPageState();
}

class _MyJournalsPageState extends State<MyJournalsPage> {
  Future<void> _deleteJournal(String journalId) async {
    bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: const Text(
              'Apakah Anda yakin ingin menghapus jurnal ini? Tindakan ini tidak dapat dibatalkan.'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
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
        await FirebaseFirestore.instance
            .collection('journals')
            .doc(journalId)
            .delete();
        if (mounted) {
          TopNotification.show(context, 'Jurnal berhasil dihapus.', type: NotificationType.success);
        }
      } catch (e) {
        if (mounted) {
          TopNotification.show(context, 'Gagal menghapus jurnal: $e', type: NotificationType.error);
        }
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'published':
        return Colors.green;
      case 'in review':
        return Colors.blue;
      case 'rejected':
        return Colors.red;
      case 'created':
        return Colors.grey;
      default:
        return Colors.black54;
    }
  }

  String _getFriendlyStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'published':
        return 'Terpublish';
      case 'in review':
        return 'Dalam Review';
      case 'rejected':
        return 'Ditolak';
      case 'created':
        return 'Draft';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      // AppBar biasanya sudah ada di dasbor induk, jadi di sini tidak perlu
      // appBar: AppBar(title: Text('Jurnal Saya')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('journals')
            .where('userId', isEqualTo: widget.currentUser.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            print("Error stream journals: ${snapshot.error}");
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Gagal memuat jurnal: ${snapshot.error}', textAlign: TextAlign.center),
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
                    Icon(Icons.article_outlined, size: 80, color: Colors.grey[400]),
                    const SizedBox(height: 20),
                    Text(
                      'Anda belum memiliki jurnal.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tekan tombol "+" di bawah untuk membuat jurnal baru.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            );
          }

          final journals = snapshot.data!.docs
              .map((doc) => JournalModel.fromFirestore(doc))
              .toList();

          return ListView.builder(
            padding: const EdgeInsets.all(12.0), // Padding untuk keseluruhan list
            itemCount: journals.length,
            itemBuilder: (context, index) {
              final journal = journals[index];
              final bool canEditOrDelete =
                  !(journal.status == 'published' || journal.status == 'rejected');

              List<Widget> trailingActions = [];
              if (canEditOrDelete) {
                trailingActions.add(
                  IconButton(
                    icon: Icon(Icons.edit_outlined, color: theme.colorScheme.primary),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddEditJournalPage(
                            currentUser: widget.currentUser,
                            currentUsername: widget.currentUsername,
                            journalToEdit: journal,
                          ),
                        ),
                      );
                    },
                    tooltip: 'Edit Jurnal',
                  ),
                );
                trailingActions.add(
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: theme.colorScheme.error),
                    onPressed: () => _deleteJournal(journal.id!),
                    tooltip: 'Hapus Jurnal',
                  ),
                );
              }

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
                          builder: (context) =>
                              JournalDetailPage(journal: journal)),
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
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Chip(
                              avatar: Icon(Icons.circle, size: 12, color: _getStatusColor(journal.status)),
                              label: Text(
                                _getFriendlyStatusText(journal.status),
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                              backgroundColor: _getStatusColor(journal.status).withOpacity(0.1),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            ),
                            if (trailingActions.isNotEmpty)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: trailingActions,
                              )
                            else
                              const SizedBox(width: 48), // Placeholder agar alignment tetap
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Dibuat: ${TimeUtils.formatTimestamp(journal.createdAt)}',
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                        ),
                         if (journal.updatedAt != null && journal.updatedAt != journal.createdAt)
                          Padding(
                            padding: const EdgeInsets.only(top: 4.0),
                            child: Text(
                              'Diperbarui: ${TimeUtils.formatTimestamp(journal.updatedAt!)}',
                              style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddEditJournalPage(
                currentUser: widget.currentUser,
                currentUsername: widget.currentUsername,
              ),
            ),
          );
        },
        tooltip: 'Buat Jurnal Baru',
        icon: const Icon(Icons.add),
        label: const Text("Buat Jurnal"),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
    );
  }
}
