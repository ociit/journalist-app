import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'package:sinau_firebase/pages/profile_page.dart'; // Bisa digunakan ulang
import 'package:sinau_firebase/pages/journals_in_review_page.dart'; // Akan kita buat
import 'package:sinau_firebase/pages/published_journals_page.dart'; // Sudah ada, bisa digunakan ulang

class ReviewerDashboard extends StatefulWidget {
  final DocumentSnapshot<Map<String, dynamic>> firestoreUserDocument;

  const ReviewerDashboard({super.key, required this.firestoreUserDocument});

  @override
  State<ReviewerDashboard> createState() => _ReviewerDashboardState();
}

class _ReviewerDashboardState extends State<ReviewerDashboard> {
  int _selectedIndex = 0;

  late Map<String, dynamic> userData;
  late String displayName;

  final User? authUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    userData = widget.firestoreUserDocument.data()!;
    String? username = userData['username'] as String?;
    String email = userData['email'] as String? ?? authUser?.email ?? 'Pengguna';
    displayName = username ?? email; // Prioritaskan username untuk tampilan nama
  }

  // Daftar halaman untuk Reviewer
  List<Widget> _reviewerPages() {
    if (authUser == null) {
      // Kondisi darurat, seharusnya tidak terjadi jika Wrapper bekerja
      return [const Center(child: Text("Error: Pengguna Reviewer tidak ditemukan."))];
    }
    return [
      ProfilePage(userData: userData), // Menggunakan ulang ProfilePage
      JournalsInReviewPage(currentUser: authUser!), // Halaman baru untuk Reviewer
      const PublishedJournalsPage(), // Menggunakan ulang PublishedJournalsPage
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // --- Fungsi Logout (Salin dari JournalistDashboard atau Homepage) ---
  Future<void> _performSignOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      // Wrapper akan menangani navigasi
    } catch (e) {
      print("Error signing out from ReviewerDashboard: $e");
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal logout: $e")));
    }
  }

  Future<void> _showLogoutConfirmationDialog() async {
     return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Konfirmasi Logout'),
          content: const Text('Apakah Anda yakin ingin keluar?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Logout'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _performSignOut();
              },
            ),
          ],
        );
      },
    );
  }
  // ------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dasbor Reviewer: $displayName'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _showLogoutConfirmationDialog,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: IndexedStack( // Gunakan IndexedStack agar state halaman tetap terjaga
        index: _selectedIndex,
        children: _reviewerPages(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle), // Ikon bisa disesuaikan
            label: 'Profil',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.rate_review_outlined), // Ikon untuk review
            label: 'Review Jurnal',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.public),
            label: 'Terpublish',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // Agar label selalu terlihat
      ),
    );
  }
}