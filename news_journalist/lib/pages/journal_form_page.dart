// lib/pages/journal_form_page.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Tambahkan ini
import '../db/journal_db.dart';
import '../models/journal.dart';

class JournalFormPage extends StatefulWidget {
  final Journal? journal;

  JournalFormPage({this.journal});

  @override
  _JournalFormPageState createState() => _JournalFormPageState();
}

class _JournalFormPageState extends State<JournalFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.journal?.title ?? '');
    _contentController = TextEditingController(text: widget.journal?.content ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _saveJournal() async {
    if (_formKey.currentState!.validate()) {
      if (widget.journal == null) {
        await JournalDatabase.instance.create(
          Journal(
            title: _titleController.text,
            content: _contentController.text,
            date: DateTime.now(), // Gunakan DateTime.now() langsung
          ),
        );
      } else {
        await JournalDatabase.instance.update(
          Journal(
            id: widget.journal!.id,
            title: _titleController.text,
            content: _contentController.text,
            date: widget.journal!.date, // Pertahankan tanggal asli saat edit
          ),
        );
      }
      Navigator.pop(context, true); // Kirim true untuk menandakan perubahan
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.journal != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Jurnal' : 'Tambah Jurnal',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold), // Contoh font
        ),
        backgroundColor: Theme.of(context).colorScheme.primary, // Warna AppBar
        foregroundColor: Theme.of(context).colorScheme.onPrimary, // Warna teks AppBar
      ),
      body: SingleChildScrollView( // Tambahkan SingleChildScrollView agar tidak overflow
        padding: EdgeInsets.all(20), // Padding yang lebih besar
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, // Agar elemen mengisi lebar
            children: [
              TextFormField(
                controller: _titleController,
                style: GoogleFonts.openSans(), // Contoh font input
                decoration: InputDecoration(
                  labelText: 'Judul Jurnal',
                  hintText: 'Tulis judul jurnal Anda...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12), // Sudut lebih membulat
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2), // Warna saat fokus
                  ),
                  prefixIcon: Icon(Icons.title), // Ikon
                  filled: true, // Latar belakang terisi
                  fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.2), // Warna latar
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Judul tidak boleh kosong' : null,
              ),
              SizedBox(height: 20), // Spasi yang lebih besar
              TextFormField(
                controller: _contentController,
                style: GoogleFonts.openSans(),
                maxLines: 10, // Maksimal baris lebih banyak
                minLines: 5, // Minimal baris
                keyboardType: TextInputType.multiline,
                decoration: InputDecoration(
                  labelText: 'Isi Jurnal',
                  hintText: 'Ceritakan apa yang ada di pikiran Anda...',
                  alignLabelWithHint: true, // Label sejajar dengan hint
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2),
                  ),
                  prefixIcon: Padding( // Ikon di atas kiri
                    padding: const EdgeInsets.only(bottom: 80.0), // Agar ikon di awal baris pertama
                    child: Icon(Icons.edit_note),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.2),
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Isi jurnal tidak boleh kosong' : null,
              ),
              SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _saveJournal,
                icon: Icon(isEditing ? Icons.save : Icons.add_box), // Ikon dinamis
                label: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0), // Padding vertikal untuk tombol
                  child: Text(
                    isEditing ? 'Simpan Perubahan' : 'Tambah Jurnal',
                    style: GoogleFonts.poppins(fontSize: 18),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5, // Tambahkan bayangan
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}