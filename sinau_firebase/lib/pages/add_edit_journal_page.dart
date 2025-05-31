import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sinau_firebase/models/journal_model.dart';

class AddEditJournalPage extends StatefulWidget {
  final User currentUser;
  final String currentUsername;
  final JournalModel? journalToEdit; // Nullable, jika null berarti membuat baru

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

  // Status yang bisa dipilih oleh Journalist saat membuat/mengedit
  final List<String> _journalistStatusOptions = ['created', 'in review'];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.journalToEdit?.title ?? '');
    _contentController = TextEditingController(text: widget.journalToEdit?.content ?? '');
    _selectedStatus = widget.journalToEdit?.status ?? _journalistStatusOptions.first; // Default ke 'created'
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveJournal() async {
    if (!_formKey.currentState!.validate()) {
      return; // Validasi gagal
    }
    if (_selectedStatus == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih status jurnal.'), backgroundColor: Colors.red),
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
          'username': widget.currentUsername, // Simpan username penulis
          'status': _selectedStatus!,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Jurnal berhasil dibuat!'), backgroundColor: Colors.green),
          );
        }
      } else {
        // Mengedit jurnal yang sudah ada
        await FirebaseFirestore.instance.collection('journals').doc(widget.journalToEdit!.id).update({
          'title': title,
          'content': content,
          'status': _selectedStatus!,
          'updatedAt': Timestamp.now(),
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Jurnal berhasil diperbarui!'), backgroundColor: Colors.green),
          );
        }
      }
      if (mounted) Navigator.of(context).pop(); // Kembali ke halaman sebelumnya setelah simpan
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan jurnal: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.journalToEdit == null ? 'Buat Jurnal Baru' : 'Edit Jurnal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveJournal,
            tooltip: 'Simpan Jurnal',
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView( // ListView agar bisa di-scroll
            children: <Widget>[
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Judul Jurnal',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Judul tidak boleh kosong.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Isi Jurnal',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 10, // Untuk konten yang lebih panjang
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Isi jurnal tidak boleh kosong.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Status Jurnal',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
                ),
                value: _selectedStatus,
                hint: const Text('Pilih Status'),
                items: _journalistStatusOptions.map((String status) {
                  return DropdownMenuItem<String>(
                    value: status,
                    child: Text(status[0].toUpperCase() + status.substring(1)), // Capitalize
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedStatus = newValue;
                  });
                },
                validator: (value) => value == null ? 'Status tidak boleh kosong' : null,
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                icon: _isLoading ? SizedBox.shrink() : Icon(Icons.save),
                label: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))
                    : const Text('Simpan Jurnal'),
                onPressed: _isLoading ? null : _saveJournal,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}