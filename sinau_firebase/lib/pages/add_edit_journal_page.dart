import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sinau_firebase/models/journal_model.dart'; // Pastikan path ini benar

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
    // Jika mengedit jurnal yang sudah ada dan statusnya bukan salah satu dari opsi Journalist,
    // maka jangan set _selectedStatus agar dropdown menampilkan hintText.
    // Namun, Journalist hanya bisa mengubah ke 'created' atau 'in review'.
    if (widget.journalToEdit != null && _journalistStatusOptions.contains(widget.journalToEdit!.status)) {
      _selectedStatus = widget.journalToEdit!.status;
    } else {
      _selectedStatus = _journalistStatusOptions.first; // Default ke 'created' untuk jurnal baru
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
    if (_selectedStatus == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih status jurnal.'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    setState(() => _isLoading = true);

    String title = _titleController.text.trim();
    String content = _contentController.text.trim();

    try {
      if (widget.journalToEdit == null) {
        // Membuat jurnal baru
        await FirebaseFirestore.instance.collection('journals').add({
          'title': title,
          'content': content,
          'userId': widget.currentUser.uid,
          'username': widget.currentUsername,
          'status': _selectedStatus!,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
          'publishedAt': null, // Default null
          'reviewedBy': null,  // Default null
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Jurnal berhasil dibuat!'), backgroundColor: Colors.green),
          );
        }
      } else {
        // Mengedit jurnal yang sudah ada
        Map<String, dynamic> dataToUpdate = {
          'title': title,
          'content': content,
          'status': _selectedStatus!,
          'updatedAt': Timestamp.now(),
        };
        // Hanya update field yang relevan, jangan timpa publishedAt atau reviewedBy jika sudah ada
        // kecuali ada logika khusus.
        await FirebaseFirestore.instance.collection('journals').doc(widget.journalToEdit!.id).update(dataToUpdate);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Jurnal berhasil diperbarui!'), backgroundColor: Colors.green),
          );
        }
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan jurnal: $e'), backgroundColor: Colors.redAccent),
        );
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
        title: Text(widget.journalToEdit == null ? 'Tulis Jurnal Baru' : 'Edit Jurnal'),
        backgroundColor: theme.colorScheme.surface, // Atau primaryContainer
        elevation: 1.0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 10.0),
            child: IconButton(
              icon: const Icon(Icons.save_alt_outlined),
              onPressed: _isLoading ? null : _saveJournal,
              tooltip: 'Simpan Jurnal',
            ),
          )
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  'Judul Jurnal',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    hintText: 'Masukkan judul jurnal Anda...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Judul tidak boleh kosong.';
                    }
                    return null;
                  },
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 24),
                Text(
                  'Isi Jurnal',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _contentController,
                  decoration: InputDecoration(
                    hintText: 'Tuliskan isi jurnal Anda di sini...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                    alignLabelWithHint: true,
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                  maxLines: 12, // Lebih banyak baris untuk konten
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Isi jurnal tidak boleh kosong.';
                    }
                    return null;
                  },
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 24),
                Text(
                  'Status Pengajuan',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    // labelText: 'Status Jurnal', // Label sudah ada di atas
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                    filled: true,
                    fillColor: Colors.grey[50],
                    prefixIcon: Icon(Icons.flag_outlined, color: theme.colorScheme.primary),
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
                            width: 24,
                            height: 24,
                            padding: const EdgeInsets.all(2.0),
                            child: const CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                          )
                        : const Icon(Icons.save_outlined),
                  label: Text(_isLoading ? 'Menyimpan...' : 'Simpan Jurnal', style: TextStyle(fontSize: 16)),
                  onPressed: _isLoading ? null : _saveJournal,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    padding: const EdgeInsets.symmetric(vertical: 15),
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
