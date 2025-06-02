import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Diperlukan untuk StreamBuilder
import 'package:sinau_firebase/pages/dashboard/edit_profile_page.dart';
import 'package:sinau_firebase/utils/custom_notification_utils.dart';

class ProfilePage extends StatefulWidget {
  // widget.userData (Map<String, dynamic>) masih berguna untuk dikirim ke EditProfilePage
  // sebagai data awal sebelum diedit.
  final Map<String, dynamic> initialUserData;

  const ProfilePage({super.key, required this.initialUserData});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isPasswordResetLoading = false;
  final User? currentUser = FirebaseAuth.instance.currentUser;

  // Fungsi _changePassword tidak perlu banyak perubahan,
  // hanya pastikan email diambil dari sumber yang tepat (snapshot atau currentUser)
  Future<void> _changePassword(String currentEmail) async {
    if (currentEmail.isEmpty) {
      if (mounted) {
        TopNotification.show(context, 'Email pengguna tidak ditemukan untuk reset password.', type: NotificationType.error);
      }
      return;
    }
    if (mounted) setState(() => _isPasswordResetLoading = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: currentEmail);
      if (mounted) {
        TopNotification.show(context, 'Email reset password telah dikirim ke $currentEmail', type: NotificationType.success);
      }
    } catch (error) {
      if (mounted) {
        TopNotification.show(context, 'Gagal mengirim email reset password: $error', type: NotificationType.error);
      }
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

    if (currentUser == null) {
      // Seharusnya tidak terjadi jika Wrapper bekerja dengan benar
      return const Scaffold(body: Center(child: Text("Pengguna tidak login.")));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              print("Error fetching profile data: ${snapshot.error}");
              return Center(child: Text("Gagal memuat data profil: ${snapshot.error}"));
            }
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Data profil tidak ditemukan."),
                    Text("Email: ${currentUser?.email ?? 'N/A'}"),
                  ],
                )
              );
            }

            // Data pengguna terbaru dari Firestore
            final Map<String, dynamic> currentProfileData = snapshot.data!.data()!;
            final String username = currentProfileData['username'] as String? ?? 'Belum diatur';
            final String email = currentProfileData['email'] as String? ?? currentUser!.email ?? 'Tidak tersedia';
            final String role = currentProfileData['role'] as String? ?? 'Tidak diketahui';

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
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
                    onPressed: _isPasswordResetLoading ? null : () => _changePassword(email),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit Profil'),
                    onPressed: () async {
                      // Navigasi ke EditProfilePage
                      // widget.initialUserData bisa digunakan di sini jika EditProfilePage membutuhkannya
                      // untuk perbandingan nilai awal, atau EditProfilePage bisa mengambil datanya sendiri.
                      // Untuk konsistensi, kita teruskan data yang baru saja kita dapat dari stream.
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditProfilePage(
                            currentUser: currentUser!,
                            userData: currentProfileData, // Kirim data terbaru dari stream
                          ),
                        ),
                      );
                      // Karena ProfilePage sekarang menggunakan StreamBuilder,
                      // ia akan otomatis refresh jika data di Firestore berubah.
                      // Pesan Snackbar di sini menjadi kurang krusial untuk refresh,
                      // tapi bisa tetap ada untuk feedback.
                      if (result == true && mounted) {
                        TopNotification.show(context, 'Perubahan profil mungkin sedang diproses.', type: NotificationType.info);
                      }
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
            );
          },
        ),
      ),
    );
  }
}
