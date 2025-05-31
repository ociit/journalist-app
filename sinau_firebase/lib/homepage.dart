import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:sinau_firebase/pages/dashboard/journalist_dashboard.dart';
import 'package:sinau_firebase/pages/dashboard/reviewer_dashboard.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final User? authUser = FirebaseAuth.instance.currentUser; // authUser dari Firebase Auth

  // Fungsi logout dan dialog konfirmasi (tetap sama seperti sebelumnya)
  Future<void> _performSignOut() async { /* ... kode Anda ... */ }
  Future<void> _showLogoutConfirmationDialog() async { /* ... kode Anda ... */ }
  // Pastikan kode _performSignOut dan _showLogoutConfirmationDialog Anda ada di sini

  // Widget untuk membangun UI berdasarkan data pengguna dari Firestore
  Widget _buildRoleSpecificUI(DocumentSnapshot<Map<String, dynamic>> userDocument) {
    if (!userDocument.exists || userDocument.data() == null) {
      return const Center(child: Text("Data pengguna tidak ditemukan di Firestore."));
    }

    Map<String, dynamic> userData = userDocument.data()!;
    String userRole = userData['role'] ?? 'Tidak Diketahui';
    // User authUser sudah ada di state, kita bisa teruskan jika perlu
    // String? userUsername = userData['username'] as String?;
    // String userEmail = authUser?.email ?? 'Email tidak tersedia';
    // String displayName = userUsername ?? userEmail;

    // Navigasi ke dasbor yang sesuai berdasarkan peran
    if (userRole == 'Journalist') {
      return JournalistDashboard(firestoreUserDocument: userDocument);
    } else if (userRole == 'Reviewer') {
      return ReviewerDashboard(firestoreUserDocument: userDocument);
    } else {
      // Tampilan default jika peran tidak dikenali
      return Scaffold(
        appBar: AppBar(
          title: const Text("Homepage"),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: _showLogoutConfirmationDialog,
              tooltip: 'Logout',
            ),
          ],
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Selamat datang, ${authUser?.email ?? 'Pengguna'}!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Peran Anda: $userRole', style: TextStyle(fontSize: 16)),
                const SizedBox(height: 20),
                const Icon(Icons.person, size: 50, color: Colors.grey),
                const SizedBox(height: 10),
                const Text("Tampilan spesifik untuk peran Anda belum diatur.", textAlign: TextAlign.center),
              ],
            ),
          )
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return authUser == null
        ? const Scaffold(body: Center(child: Text("Pengguna tidak login."))) // Seharusnya tidak terjadi jika Wrapper benar
        : FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            future: FirebaseFirestore.instance.collection('users').doc(authUser!.uid).get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }
              if (snapshot.hasError) {
                print("Error fetching user data: ${snapshot.error}");
                return const Scaffold(body: Center(child: Text("Gagal memuat data pengguna.")));
              }
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return Scaffold(
                  backgroundColor: Colors.white,
                  appBar: AppBar(title: const Text("Profil Tidak Lengkap")),
                  body: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Data profil Anda tidak ditemukan di database Firestore."),
                          Text("Email: ${authUser?.email ?? 'N/A'}"),
                          Text("UID: ${authUser?.uid ?? 'N/A'}"),
                          const SizedBox(height: 10),
                          const Text("Ini mungkin karena proses registrasi sebelumnya tidak menyimpan data profil sepenuhnya. Mohon coba logout dan registrasi ulang."),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            icon: Icon(Icons.logout),
                            label: Text("Logout"),
                            onPressed: _showLogoutConfirmationDialog,
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                          )
                        ],
                      ),
                    ),
                  )
                );
              }
              // Jika data ada, bangun UI kontennya
              return _buildRoleSpecificUI(snapshot.data!);
            },
          );
  }
}