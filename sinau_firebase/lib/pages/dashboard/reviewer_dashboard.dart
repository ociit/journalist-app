import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sinau_firebase/pages/dashboard/profile_page.dart';
import 'package:sinau_firebase/pages/journals/reviewer/journals_in_review_page.dart';
import 'package:sinau_firebase/pages/journals/published_journals_page.dart';
import 'package:sinau_firebase/pages/journals/reviewer/rejected_journals_page.dart';
import 'package:sinau_firebase/utils/custom_notification_utils.dart';

class ReviewerDashboard extends StatefulWidget {
  final DocumentSnapshot<Map<String, dynamic>> firestoreUserDocument;

  const ReviewerDashboard({super.key, required this.firestoreUserDocument});

  @override
  State<ReviewerDashboard> createState() => _ReviewerDashboardState();
}

class _ReviewerDashboardState extends State<ReviewerDashboard> {
  int _selectedIndex = 0; // Default ke tab pertama (Review Jurnal)

  late Map<String, dynamic> userData;
  late String username;
  late String email;
  late String role;
  late String displayName;

  final User? authUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    userData = widget.firestoreUserDocument.data()!;
    username = userData['username'] as String? ?? "Anonim";
    email = userData['email'] as String? ?? authUser?.email ?? 'Pengguna';
    role = userData['role'] as String? ?? 'Reviewer';
    displayName = username;
  }

  // Mengubah urutan halaman: Review Jurnal, Terpublish, Ditolak, Profil
  List<Widget> _reviewerPages() {
    if (authUser == null) {
      return [
        const Center(child: Text("Error: Pengguna Reviewer tidak ditemukan.")),
      ];
    }
    String currentRole = userData['role'] as String? ?? 'Tidak Diketahui';
    return [
      JournalsInReviewPage(currentUser: authUser!), // Indeks 0
      PublishedJournalsPage(currentUserRole: currentRole), // Indeks 1
      const RejectedJournalsPage(), // Indeks 2
      ProfilePage(initialUserData: userData), // Indeks 3 (Paling Kanan)
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  String getAppBarTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Review Jurnal';
      case 1:
        return 'Jurnal Terpublish';
      case 2:
        return 'Jurnal Ditolak';
      case 3:
        return '$role Profile Page';
      default:
        return 'Dasbor Journalist';
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<Widget> pages = _reviewerPages();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          getAppBarTitle(),
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor:
            theme.colorScheme.secondaryContainer, // Contoh warna tema berbeda
      ),
      body: IndexedStack(index: _selectedIndex, children: pages),
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
          BottomNavigationBarItem(
            // Profil paling kanan
            icon: Icon(Icons.account_circle_outlined),
            activeIcon: Icon(Icons.account_circle),
            label: 'Profil',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: theme.colorScheme.surface,
        selectedItemColor: theme
            .colorScheme
            .secondary, // Mungkin ingin warna berbeda untuk Reviewer
        unselectedItemColor: Colors.grey[600],
        showUnselectedLabels: true,
        elevation: 8.0,
      ),
    );
  }
}
