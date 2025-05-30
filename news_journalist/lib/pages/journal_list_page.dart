// lib/pages/journal_list_page.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart'; // Tambahkan ini
import '../db/journal_db.dart';
import '../models/journal.dart';
import 'journal_form_page.dart';

class JournalListPage extends StatefulWidget {
  @override
  _JournalListPageState createState() => _JournalListPageState();
}

class _JournalListPageState extends State<JournalListPage> {
  List<Journal> journals = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    refreshJournals();
  }

  Future<void> refreshJournals() async {
    setState(() {
      _isLoading = true; // Set loading state
    });
    final data = await JournalDatabase.instance.readAll();
    setState(() {
      journals = data;
      _isLoading = false; // Hentikan loading
    });
  }

  void deleteJournal(int id) async {
    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Hapus Jurnal?'),
          content: Text('Anda yakin ingin menghapus jurnal ini?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Hapus', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmDelete == true) {
      await JournalDatabase.instance.delete(id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Jurnal berhasil dihapus!')),
      );
      refreshJournals();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Jurnal Pribadi',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator()) // Tampilkan loading
          : journals.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.book_outlined, size: 80, color: Colors.grey[400]),
                      SizedBox(height: 10),
                      Text(
                        'Belum ada jurnal.',
                        style: GoogleFonts.openSans(
                            fontSize: 18, color: Colors.grey[600]),
                      ),
                      Text(
                        'Ayo buat jurnal pertamamu!',
                        style: GoogleFonts.openSans(
                            fontSize: 14, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: journals.length,
                  itemBuilder: (context, index) {
                    final journal = journals[index];
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: 6, // Bayangan lebih menonjol
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15)), // Sudut membulat
                      child: InkWell(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => JournalFormPage(journal: journal),
                            ),
                          );
                          refreshJournals();
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      journal.title,
                                      style: GoogleFonts.poppins(
                                          fontSize: 20, fontWeight: FontWeight.bold),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  // Tombol PopUp Menu untuk Edit/Delete
                                  PopupMenuButton<String>(
                                    onSelected: (value) async {
                                      if (value == 'edit') {
                                        await Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => JournalFormPage(journal: journal),
                                          ),
                                        );
                                        refreshJournals();
                                      } else if (value == 'delete') {
                                        deleteJournal(journal.id!);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      PopupMenuItem(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit, size: 20),
                                            SizedBox(width: 8),
                                            Text('Edit'),
                                          ],
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete, size: 20, color: Colors.red),
                                            SizedBox(width: 8),
                                            Text('Hapus', style: TextStyle(color: Colors.red)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Text(
                                DateFormat('EEEE, dd MMMM yyyy HH:mm', 'id_ID').format(journal.date), // Format tanggal lebih detail
                                style: GoogleFonts.openSans(
                                    fontSize: 12, fontStyle: FontStyle.italic, color: Colors.grey[600]),
                              ),
                              SizedBox(height: 12),
                              Text(
                                journal.content,
                                style: GoogleFonts.openSans(fontSize: 15, color: Colors.grey[800]),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => JournalFormPage()),
          );
          refreshJournals();
        },
        icon: Icon(Icons.add, size: 28),
        label: Text('Tambah Jurnal', style: GoogleFonts.poppins(fontSize: 16)),
        backgroundColor: Theme.of(context).colorScheme.secondary, // Warna FAB yang menarik
        foregroundColor: Theme.of(context).colorScheme.onSecondary, // Warna teks FAB
        elevation: 8, // Bayangan lebih menonjol
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), // Bentuk membulat
      ),
    );
  }
}