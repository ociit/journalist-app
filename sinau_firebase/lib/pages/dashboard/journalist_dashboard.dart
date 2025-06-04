import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sinau_firebase/pages/dashboard/profile_page.dart';
import 'package:sinau_firebase/pages/journals/journalist/my_journals_page.dart';
import 'package:sinau_firebase/pages/journals/published_journals_page.dart';
import 'package:sinau_firebase/utils/custom_notification_utils.dart';

class JournalistDashboard extends StatefulWidget {
  final DocumentSnapshot<Map<String, dynamic>> firestoreUserDocument;

  const JournalistDashboard({super.key, required this.firestoreUserDocument});

  @override
  State<JournalistDashboard> createState() => _JournalistDashboardState();
}

class _JournalistDashboardState extends State<JournalistDashboard> {
  int _selectedIndex = 0; // Default ke tab pertama (Jurnal Saya)

  late Map<String, dynamic> userData;
  late String displayName;
  late String username;
  late String role;

  final User? authUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    userData = widget.firestoreUserDocument.data()!;
    username = userData['username'] as String? ?? 'Pengguna Anonim';
    role = userData['role'] as String? ?? 'Journalist';
    displayName = username; // Prioritaskan username untuk AppBar title
  }

  // Mengubah urutan halaman: Jurnal Saya, Terpublish, Profil
  List<Widget> _journalistPages() {
    if (authUser == null) {
      return [const Center(child: Text("Error: Pengguna tidak ditemukan."))];
    }
    String currentRole = userData['role'] as String? ?? 'Tidak Diketahui';
    return [
      MyJournalsPage(
        currentUser: authUser!,
        currentUsername: username,
      ), // Indeks 0
      PublishedJournalsPage(currentUserRole: currentRole), // Indeks 1
      ProfilePage(initialUserData: userData), // Indeks 2 (Paling Kanan)
    ];
  }

  String getAppBarTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Jurnal Saya';
      case 1:
        return 'Jurnal Terpublish';
      case 2:
        return '$role Profile Page';
      default:
        return 'Dasbor Journalist';
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<Widget> pages = _journalistPages();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(getAppBarTitle()),
        backgroundColor: theme.colorScheme.primaryContainer,
      ),
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.article_outlined),
            activeIcon: Icon(Icons.article), // Ikon berbeda saat aktif
            label: 'Jurnal Saya',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.public_outlined),
            activeIcon: Icon(Icons.public),
            label: 'Terpublish',
          ),
          BottomNavigationBarItem(
            // Profil paling kanan
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // Label selalu terlihat
        backgroundColor: theme.colorScheme.surface, // Warna latar BottomNav
        selectedItemColor: theme.colorScheme.primary,
        unselectedItemColor: Colors.grey[600],
        showUnselectedLabels: true, // Bisa diatur true atau false
        elevation: 8.0, // Menambah sedikit shadow
      ),
    );
  }
}
