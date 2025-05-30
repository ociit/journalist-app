// lib/pages/profile_page.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart'; // Import AuthService

class ProfilePage extends StatelessWidget {
  final AuthService _auth = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profil Saya',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await _auth.signOut();
              // Setelah logout, StreamBuilder di MyApp akan mendeteksi perubahan
              // dan mengarahkan kembali ke AuthScreen.
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Anda telah logout.')),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: _auth.userProfile, // Menggunakan stream profil pengguna
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error memuat profil: ${snapshot.error}'));
          } else if (!snapshot.hasData || FirebaseAuth.instance.currentUser == null) {
            // Ini bisa terjadi jika dokumen pengguna belum dibuat atau pengguna logout
            return Center(
                child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.person_off, size: 80, color: Colors.grey),
                SizedBox(height: 10),
                Text('Data profil tidak ditemukan. Silakan login kembali.', style: GoogleFonts.poppins(fontSize: 16)),
              ],
            ));
          } else {
            final user = FirebaseAuth.instance.currentUser;
            final userProfileData = snapshot.data!;
            final String userEmail = user?.email ?? 'N/A';
            final String userUid = user?.uid ?? 'N/A';
            final String userRole = userProfileData['role'] ?? 'Tidak Diketahui';

            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      child: Icon(Icons.person, size: 60, color: Theme.of(context).colorScheme.onPrimary),
                    ),
                  ),
                  SizedBox(height: 20),
                  _buildProfileInfoRow('Email', userEmail),
                  _buildProfileInfoRow('User ID', userUid),
                  _buildProfileInfoRow('Role', userRole.toUpperCase()),
                  SizedBox(height: 20),
                  if (userRole == 'reviewer') // Contoh: Tampilkan tombol khusus untuk reviewer
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Navigasi ke halaman admin/reviewer panel
                          // Contoh: Navigator.push(context, MaterialPageRoute(builder: (context) => ReviewerPanelPage()));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Anda adalah Reviewer! Fitur Admin segera hadir.')),
                          );
                        },
                        icon: Icon(Icons.dashboard),
                        label: Text('Buka Panel Reviewer', style: GoogleFonts.poppins()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.secondary,
                          foregroundColor: Theme.of(context).colorScheme.onSecondary,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildProfileInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label + ':',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: GoogleFonts.openSans(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}