import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Diperlukan untuk query username reviewer
import 'package:sinau_firebase/models/journal_model.dart'; // Sesuaikan path jika perlu
import 'package:sinau_firebase/utils/time_utils.dart';   // Sesuaikan path jika perlu
import 'package:flutter/services.dart'; // Untuk Clipboard
import 'package:sinau_firebase/utils/custom_notification_utils.dart';

class JournalDetailPage extends StatefulWidget { // Diubah menjadi StatefulWidget
  final JournalModel journal;

  const JournalDetailPage({super.key, required this.journal});

  @override
  State<JournalDetailPage> createState() => _JournalDetailPageState();
}

class _JournalDetailPageState extends State<JournalDetailPage> { // State class baru
  String? _reviewerUsername; // State untuk menyimpan username reviewer
  bool _isLoadingReviewerUsername = false;

  @override
  void initState() {
    super.initState();
    if (widget.journal.reviewedBy != null && widget.journal.reviewedBy!.isNotEmpty) {
      _fetchReviewerUsername(widget.journal.reviewedBy!);
    }
  }

  Future<void> _fetchReviewerUsername(String reviewerUid) async {
    if (mounted) {
      setState(() {
        _isLoadingReviewerUsername = true;
      });
    }
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(reviewerUid)
          .get();
      if (userDoc.exists && userDoc.data() != null) {
        final userData = userDoc.data() as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _reviewerUsername = userData['username'] as String? ?? 'ID: $reviewerUid';
            _isLoadingReviewerUsername = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _reviewerUsername = 'Reviewer tidak ditemukan (ID: $reviewerUid)';
            _isLoadingReviewerUsername = false;
          });
        }
      }
    } catch (e) {
      print("Error fetching reviewer username: $e");
      if (mounted) {
        setState(() {
          _reviewerUsername = 'Gagal memuat nama reviewer';
          _isLoadingReviewerUsername = false;
        });
      }
    }
  }

  Color _getStatusColor(BuildContext context, String status) {
    final ThemeData theme = Theme.of(context);
    switch (status.toLowerCase()) {
      case 'published':
        return Colors.green.shade700;
      case 'in review':
        return theme.colorScheme.secondary;
      case 'rejected':
        return theme.colorScheme.error;
      case 'created':
        return Colors.grey.shade600;
      default:
        return theme.textTheme.bodySmall?.color ?? Colors.black54;
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
        return status.isNotEmpty ? status[0].toUpperCase() + status.substring(1) : 'N/A';
    }
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String label, String value, {bool isSelectable = false}) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary.withOpacity(0.8)),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          Expanded(
            child: isSelectable
                ? SelectableText(value, style: theme.textTheme.bodyMedium)
                : Text(value, style: theme.textTheme.bodyMedium),
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
      appBar: AppBar(
        title: Text(widget.journal.title, overflow: TextOverflow.ellipsis),
        backgroundColor: theme.colorScheme.surface,
        elevation: 1.0,
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_all_outlined),
            tooltip: 'Salin Judul & Penulis',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: "Judul: ${widget.journal.title}\nPenulis: ${widget.journal.username}"));
              TopNotification.show(context, 'Judul & Penulis disalin ke clipboard!', type: NotificationType.info);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              widget.journal.title,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 2.0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow(context, Icons.person_outline, 'Penulis', widget.journal.username),
                    _buildInfoRow(context, Icons.calendar_today_outlined, 'Dibuat', TimeUtils.formatTimestamp(widget.journal.createdAt)),
                    if (widget.journal.updatedAt != null && widget.journal.updatedAt != widget.journal.createdAt)
                      _buildInfoRow(context, Icons.edit_calendar_outlined, 'Diperbarui', TimeUtils.formatTimestamp(widget.journal.updatedAt!)),
                    
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0),
                      child: Row(
                        children: [
                          Icon(Icons.flag_outlined, size: 20, color: theme.colorScheme.primary.withOpacity(0.8)),
                          const SizedBox(width: 12),
                          Text(
                            'Status: ',
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          Chip(
                            label: Text(
                              _getFriendlyStatusText(widget.journal.status),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            backgroundColor: _getStatusColor(context, widget.journal.status),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            labelPadding: EdgeInsets.zero,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ],
                      ),
                    ),

                    if (widget.journal.status.toLowerCase() == 'published' && widget.journal.publishedAt != null)
                      _buildInfoRow(context, Icons.publish_outlined, 'Dipublish', TimeUtils.formatTimestamp(widget.journal.publishedAt!)),
                    
                    // Menampilkan username reviewer
                    if (widget.journal.reviewedBy != null && widget.journal.reviewedBy!.isNotEmpty)
                      _isLoadingReviewerUsername
                        ? Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6.0),
                            child: Row(
                              children: [
                                Icon(Icons.rate_review_outlined, size: 20, color: theme.colorScheme.primary.withOpacity(0.8)),
                                const SizedBox(width: 12),
                                Text(
                                  'Direview oleh: ',
                                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(width: 4),
                                const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                              ],
                            ),
                          )
                        : _buildInfoRow(context, Icons.rate_review_outlined, 'Direview oleh', _reviewerUsername ?? 'Tidak diketahui'),
                  ],
                ),
              ),
            ),
            
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20.0),
              child: Divider(thickness: 1),
            ),

            Text(
              'Isi Jurnal Lengkap',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.grey.shade300)
              ),
              child: SelectableText(
                widget.journal.content,
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.7, fontSize: 16),
                textAlign: TextAlign.justify,
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
