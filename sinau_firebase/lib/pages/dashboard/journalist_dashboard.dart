import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sinau_firebase/pages/profile_page.dart';
import 'package:sinau_firebase/pages/my_journals_page.dart';
import 'package:sinau_firebase/pages/my_journals_page.dart';
import 'package:sinau_firebase/pages/published_journals_page.dart';

// Nanti kita akan buat halaman-halaman ini:
// import 'profile_page.dart';
// import 'my_journals_page.dart';
// import 'published_journals_page.dart';

class JournalistDashboard extends StatefulWidget {
  final DocumentSnapshot<Map<String, dynamic>> firestoreUserDocument;

  const JournalistDashboard({super.key, required this.firestoreUserDocument});

  @override
  State<JournalistDashboard> createState() => _JournalistDashboardState();
}

class _JournalistDashboardState extends State<JournalistDashboard> {
  int _selectedIndex = 0; // Untuk BottomNavigationBar

  // User data dari Firestore
  late Map<String, dynamic> userData;
  late String displayName;
  late String username;

  // User dari Firebase Auth (untuk logout misalnya)
  final User? authUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    userData = widget.firestoreUserDocument.data()!;
    userData = widget.firestoreUserDocument.data()!;
    username = userData['username'] as String? ?? 'Pengguna Anonim'; // Ambil username
    String email = userData['email'] as String? ?? authUser?.email ?? 'Pengguna';
    displayName = username; // Atau kombinasi, sesuai preferensi
  }

  // Daftar halaman untuk Journalist
  List<Widget> _journalistPages() {
    if (authUser == null) {
      return [Center(child: Text("Error: Pengguna tidak ditemukan."))];
    }

    return [
      ProfilePage(userData: userData), // <-- Gunakan ProfilePage di sini
      MyJournalsPage(currentUser: authUser!, currentUsername: username), // Kirim user dan username
      const PublishedJournalsPage(),
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _performSignOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      // Wrapper akan menangani navigasi
    } catch (e) {
      print("Error signing out from dashboard: $e");
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Gagal logout: $e")));
    }
  }

  Future<void> _showLogoutConfirmationDialog() async {return showDialog<void>(
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
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dasbor Journalist: $displayName'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _showLogoutConfirmationDialog,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _journalistPages(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
          BottomNavigationBarItem(icon: Icon(Icons.article), label: 'Jurnal Saya'),
          BottomNavigationBarItem(icon: Icon(Icons.public), label: 'Terpublish'), // Label sudah sesuai
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}