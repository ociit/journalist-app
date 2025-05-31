import 'package:flutter/material.dart';
import 'package:sinau_firebase/models/journal_model.dart'; // Sesuaikan path jika perlu
import 'package:sinau_firebase/utils/time_utils.dart';   // Sesuaikan path jika perlu
import 'package:flutter/services.dart'; // Untuk Clipboard

class JournalDetailPage extends StatelessWidget {
  final JournalModel journal;

  const JournalDetailPage({super.key, required this.journal});

  Color _getStatusColor(BuildContext context, String status) {
    // Menggunakan warna dari tema untuk konsistensi
    final ThemeData theme = Theme.of(context);
    switch (status.toLowerCase()) {
      case 'published':
        return Colors.green.shade700; // Tetap hijau untuk published
      case 'in review':
        return theme.colorScheme.secondary; // Warna sekunder tema
      case 'rejected':
        return theme.colorScheme.error; // Warna error tema
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
      appBar: AppBar(
        title: Text(journal.title, overflow: TextOverflow.ellipsis),
        backgroundColor: theme.colorScheme.surface,
        elevation: 1.0,
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_all_outlined),
            tooltip: 'Salin Judul & Penulis',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: "Judul: ${journal.title}\nPenulis: ${journal.username}"));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Judul & Penulis disalin ke clipboard!')),
              );
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
              journal.title,
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
                    _buildInfoRow(context, Icons.person_outline, 'Penulis', journal.username),
                    _buildInfoRow(context, Icons.calendar_today_outlined, 'Dibuat', TimeUtils.formatTimestamp(journal.createdAt)),
                    if (journal.updatedAt != null && journal.updatedAt != journal.createdAt)
                      _buildInfoRow(context, Icons.edit_calendar_outlined, 'Diperbarui', TimeUtils.formatTimestamp(journal.updatedAt!)),
                    
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
                              _getFriendlyStatusText(journal.status),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            backgroundColor: _getStatusColor(context, journal.status),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            labelPadding: EdgeInsets.zero, // Hapus padding internal label
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, // Kurangi area tap
                          ),
                        ],
                      ),
                    ),

                    if (journal.status.toLowerCase() == 'published' && journal.publishedAt != null)
                      _buildInfoRow(context, Icons.publish_outlined, 'Dipublish', TimeUtils.formatTimestamp(journal.publishedAt!)),
                    
                    if (journal.reviewedBy != null && journal.reviewedBy!.isNotEmpty)
                       _buildInfoRow(context, Icons.rate_review_outlined, 'Direview oleh', '(...${journal.reviewedBy!.substring(journal.reviewedBy!.length - 6)})'),
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
                color: theme.scaffoldBackgroundColor, // Atau Colors.grey[50] jika ingin sedikit beda
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.grey.shade300)
              ),
              child: SelectableText(
                journal.content,
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.7, fontSize: 16), // Line height dan font size
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
