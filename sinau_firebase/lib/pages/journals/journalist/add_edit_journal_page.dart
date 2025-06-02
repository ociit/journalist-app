import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sinau_firebase/models/journal_model.dart'; // Pastikan path ini benar
import 'package:sinau_firebase/utils/custom_notification_utils.dart';

class AddEditJournalPage extends StatefulWidget {
  final User currentUser;
  final String currentUsername;
  final JournalModel? journalToEdit;

  const AddEditJournalPage({
    super.key,
    required this.currentUser,
    required this.currentUsername,
    this.journalToEdit,
  });

  @override
  State<AddEditJournalPage> createState() => _AddEditJournalPageState();
}

class _AddEditJournalPageState extends State<AddEditJournalPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  String? _selectedStatus;
  bool _isLoading = false;

  final List<String> _journalistStatusOptions = ['created', 'in review'];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.journalToEdit?.title ?? '');
    _contentController = TextEditingController(text: widget.journalToEdit?.content ?? '');
    if (widget.journalToEdit != null) {
        // Jika edit, set status ke status jurnal yang ada jika valid, jika tidak, default
        _selectedStatus = _journalistStatusOptions.contains(widget.journalToEdit!.status)
            ? widget.journalToEdit!.status
            : _journalistStatusOptions.first; // atau biarkan null jika ingin validasi saat simpan
    } else {
      _selectedStatus = _journalistStatusOptions.first; // Default 'created' untuk jurnal baru
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveJournal() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_selectedStatus == null) { // Seharusnya tidak terjadi jika ada default, tapi jaga-jaga
      TopNotification.show(context, 'Silakan pilih status jurnal.', type: NotificationType.warning);
      return;
    }

    setState(() => _isLoading = true);

    String title = _titleController.text.trim();
    String content = _contentController.text.trim();

    try {
      if (widget.journalToEdit == null) {
        await FirebaseFirestore.instance.collection('journals').add({
          'title': title,
          'content': content,
          'userId': widget.currentUser.uid,
          'username': widget.currentUsername,
          'status': _selectedStatus!,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
          'publishedAt': null,
          'reviewedBy': null,
        });
        if (mounted) {
          TopNotification.show(context, 'Jurnal berhasil dibuat!', type: NotificationType.success);
        }
      } else {
        Map<String, dynamic> dataToUpdate = {
          'title': title,
          'content': content,
          'status': _selectedStatus!,
          'updatedAt': Timestamp.now(),
        };
        await FirebaseFirestore.instance.collection('journals').doc(widget.journalToEdit!.id).update(dataToUpdate);
        if (mounted) {
          TopNotification.show(context, 'Jurnal berhasil diperbarui!', type: NotificationType.success);
        }
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        TopNotification.show(context, 'Gagal menyimpan jurnal: $e', type: NotificationType.error);
        print("Error saving journal: $e");
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.journalToEdit == null ? 'Tulis Jurnal Baru' : 'Edit Jurnal "${widget.journalToEdit!.title}"', overflow: TextOverflow.ellipsis),
        backgroundColor: theme.colorScheme.surface,
        elevation: 2.0, // Sedikit shadow untuk appbar
        leading: IconButton( // Tombol kembali yang lebih eksplisit
          icon: Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Batal',
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: TextButton.icon( // Menggunakan TextButton agar lebih ringkas
              icon: const Icon(Icons.save_alt_outlined),
              label: const Text('Simpan'),
              onPressed: _isLoading ? null : _saveJournal,
              style: TextButton.styleFrom(
                foregroundColor: theme.colorScheme.primary,
              ),
            ),
          )
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20.0, 24.0, 20.0, 20.0), // Padding sedikit berbeda
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, // Label rata kiri
              children: <Widget>[
                Text(
                  'Judul',
                  style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w500, color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: 'Masukkan judul yang menarik...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Judul tidak boleh kosong.';
                    return null;
                  },
                  textCapitalization: TextCapitalization.words, // Setiap kata diawali huruf besar
                ),
                const SizedBox(height: 24),
                Text(
                  'Konten Jurnal',
                  style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w500, color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _contentController,
                  decoration: InputDecoration(
                    hintText: 'Tuliskan pemikiran atau cerita Anda di sini...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
                    alignLabelWithHint: true, // Untuk labelText, jika digunakan
                    filled: true,
                    fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  maxLines: 15, // Lebih banyak baris
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return 'Isi jurnal tidak boleh kosong.';
                    return null;
                  },
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 24),
                Text(
                  'Status Pengajuan',
                   style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w500, color: theme.colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                    prefixIcon: Icon(Icons.flag_circle_outlined, color: theme.colorScheme.primary),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4), // Sesuaikan padding
                  ),
                  value: _selectedStatus,
                  hint: const Text('Pilih Status'),
                  items: _journalistStatusOptions.map((String status) {
                    return DropdownMenuItem<String>(
                      value: status,
                      child: Text(status == 'created' ? 'Simpan sebagai Draft' : 'Ajukan untuk Review'),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedStatus = newValue;
                    });
                  },
                  validator: (value) => value == null ? 'Status tidak boleh kosong' : null,
                ),
                const SizedBox(height: 40),
                ElevatedButton.icon(
                  icon: _isLoading
                      ? Container(
                          width: 20, // Disesuaikan agar konsisten dengan tombol login/register
                          height: 20,
                          child: const CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                      : const Icon(Icons.save),
                  label: Text(_isLoading ? 'Menyimpan...' : 'Simpan Jurnal', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  onPressed: _isLoading ? null : _saveJournal,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52), // Sedikit lebih tinggi
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    elevation: 3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
