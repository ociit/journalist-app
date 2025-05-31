import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart'; // Tidak digunakan langsung di UI ini, data via props

class ProfilePage extends StatefulWidget {
  final Map<String, dynamic> userData;

  const ProfilePage({super.key, required this.userData});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late String username;
  late String email;
  late String role;
  bool _isPasswordResetLoading = false;

  @override
  void initState() {
    super.initState();
    username = widget.userData['username'] as String? ?? 'Belum diatur';
    email = widget.userData['email'] as String? ?? 'Tidak tersedia';
    role = widget.userData['role'] as String? ?? 'Tidak diketahui';
  }

  Future<void> _changePassword() async {
    if (email.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Email pengguna tidak ditemukan untuk reset password.'),
              backgroundColor: Colors.redAccent),
        );
      }
      return;
    }

    if (mounted) setState(() => _isPasswordResetLoading = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Email reset password telah dikirim ke $email'),
              backgroundColor: Colors.green),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Gagal mengirim email reset password: $error'),
              backgroundColor: Colors.redAccent),
        );
      }
      print("Error sending password reset email: $error");
    } finally {
      if (mounted) setState(() => _isPasswordResetLoading = false);
    }
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
    Color? iconColor,
  }) {
    return Card(
      elevation: 2.0,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: ListTile(
        leading: Icon(icon, color: iconColor ?? Theme.of(context).colorScheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle),
        trailing: onTap != null ? const Icon(Icons.arrow_forward_ios, size: 16) : null,
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      // AppBar biasanya sudah ada di dasbor, jadi di sini tidak perlu jika terintegrasi
      // appBar: AppBar(title: const Text('Profil Saya')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch, // Membuat tombol selebar mungkin
            children: <Widget>[
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Icon(
                        Icons.person,
                        size: 60,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                      // TODO: Implement image picker and display profile image
                    ),
                    const SizedBox(height: 16),
                    Text(
                      username,
                      style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      role,
                      style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.secondary),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              _buildInfoCard(
                icon: Icons.email_outlined,
                title: 'Email',
                subtitle: email,
              ),
              _buildInfoCard(
                icon: Icons.badge_outlined,
                title: 'Peran',
                subtitle: role,
              ),
              const Divider(height: 30, thickness: 1),
              ElevatedButton.icon(
                icon: _isPasswordResetLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.lock_reset_outlined),
                label: Text(_isPasswordResetLoading ? 'Mengirim...' : 'Ubah Password'),
                onPressed: _isPasswordResetLoading ? null : _changePassword,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  elevation: 3,
                ),
              ),
              const SizedBox(height: 12),
              // Placeholder untuk Tombol Edit Profil
              OutlinedButton.icon(
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit Profil'),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Fitur Edit Profil belum diimplementasikan.')),
                  );
                  // TODO: Navigasi ke halaman edit profil
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  side: BorderSide(color: theme.colorScheme.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
