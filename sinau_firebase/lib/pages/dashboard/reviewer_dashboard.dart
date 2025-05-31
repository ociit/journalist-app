import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sinau_firebase/pages/profile_page.dart';
import 'package:sinau_firebase/pages/journals_in_review_page.dart';
import 'package:sinau_firebase/pages/published_journals_page.dart';
import 'package:sinau_firebase/pages/rejected_journals_page.dart';

class ReviewerDashboard extends StatefulWidget {
  final DocumentSnapshot<Map<String, dynamic>> firestoreUserDocument;

  const ReviewerDashboard({super.key, required this.firestoreUserDocument});

  @override
  State<ReviewerDashboard> createState() => _ReviewerDashboardState();
}

class _ReviewerDashboardState extends State<ReviewerDashboard> {
  int _selectedIndex = 0; // Default ke tab pertama (Review Jurnal)

  late Map<String, dynamic> userData;
  late String displayName;

  final User? authUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    userData = widget.firestoreUserDocument.data()!;
    String? username = userData['username'] as String?;
    String email = userData['email'] as String? ?? authUser?.email ?? 'Pengguna';
    displayName = username ?? email;
  }

  // Mengubah urutan halaman: Review Jurnal, Terpublish, Ditolak, Profil
  List<Widget> _reviewerPages() {
    if (authUser == null) {
      return [const Center(child: Text("Error: Pengguna Reviewer tidak ditemukan."))];
    }
    String currentRole = userData['role'] as String? ?? 'Tidak Diketahui';
    return [
      JournalsInReviewPage(currentUser: authUser!),           // Indeks 0
      PublishedJournalsPage(currentUserRole: currentRole), // Indeks 1
      const RejectedJournalsPage(),                          // Indeks 2
      ProfilePage(userData: userData),                       // Indeks 3 (Paling Kanan)
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
    } catch (e) {
      print("Error signing out from ReviewerDashboard: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Gagal logout: $e"), backgroundColor: Colors.redAccent));
      }
    }
  }

  Future<void> _showLogoutConfirmationDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Konfirmasi Logout'),
          content: const Text('Apakah Anda yakin ingin keluar dari akun ini?'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
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
    final ThemeData theme = Theme.of(context);
    final List<Widget> pages = _reviewerPages();

    return Scaffold(
      appBar: AppBar(
        title: Text('$displayName, Reviewer!'),
        backgroundColor: theme.colorScheme.secondaryContainer, // Contoh warna tema berbeda
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
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.rate_review_outlined),
            activeIcon: Icon(Icons.rate_review),
            label: 'Review',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.public_outlined),
            activeIcon: Icon(Icons.public),
            label: 'Terpublish',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.unpublished_outlined),
            activeIcon: Icon(Icons.unpublished),
            label: 'Ditolak',
          ),
          BottomNavigationBarItem( // Profil paling kanan
            icon: Icon(Icons.account_circle_outlined),
            activeIcon: Icon(Icons.account_circle),
            label: 'Profil',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: theme.colorScheme.surface,
        selectedItemColor: theme.colorScheme.secondary, // Mungkin ingin warna berbeda untuk Reviewer
        unselectedItemColor: Colors.grey[600],
        showUnselectedLabels: true,
        elevation: 8.0,
      ),
    );
  }
}
