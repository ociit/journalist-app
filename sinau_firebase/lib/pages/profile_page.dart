import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Jika perlu query ulang atau update
import 'package:firebase_auth/firebase_auth.dart';   // Jika perlu info authUser

class ProfilePage extends StatefulWidget {
  final Map<String, dynamic> userData; // Data dari Firestore yang sudah di-passing

  const ProfilePage({super.key, required this.userData});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late String username;
  late String email;
  late String role;
  // Untuk password, kita TIDAK akan menampilkannya. Kita akan buat tombol "Ubah Password".

  @override
  void initState() {
    super.initState();
    username = widget.userData['username'] as String? ?? 'Belum diatur';
    email = widget.userData['email'] as String? ?? 'Tidak tersedia';
    role = widget.userData['role'] as String? ?? 'Tidak diketahui';
  }

  // --- PENTING: Jangan Tampilkan Password! ---
  // Menampilkan password adalah praktik keamanan yang buruk.
  // Sebagai gantinya, kita akan buat fungsi untuk "Ubah Password".
  void _changePassword() {
    if (email.isNotEmpty) {
      FirebaseAuth.instance.sendPasswordResetEmail(email: email)
        .then((value) => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Email reset password telah dikirim ke $email')),
            ))
        .catchError((error) => ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Gagal mengirim email reset password: $error')),
            ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email pengguna tidak ditemukan untuk reset password.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar bisa dihilangkan jika halaman ini bagian dari BottomNav di dasbor
      // appBar: AppBar(title: const Text('Profil Saya')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView( // Gunakan ListView agar bisa di-scroll jika konten banyak
          children: <Widget>[
            Center(
              child: Column(
                children: [
                  // Placeholder untuk Foto Profil
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[300],
                    child: Icon(Icons.person, size: 50, color: Colors.grey[700]),
                    // Nanti kita akan tambahkan image picker di sini
                  ),
                  const SizedBox(height: 16),
                  Text(username, style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 8),
                ],
              )
            ),
            ListTile(
              leading: Icon(Icons.email),
              title: Text('Email'),
              subtitle: Text(email),
            ),
            ListTile(
              leading: Icon(Icons.badge),
              title: Text('Peran'),
              subtitle: Text(role),
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.lock_reset),
              title: Text('Ubah Password'),
              onTap: _changePassword,
            ),
            // Nanti di sini bisa ditambahkan tombol untuk edit profil, dll.
          ],
        ),
      ),
    );
  }
}