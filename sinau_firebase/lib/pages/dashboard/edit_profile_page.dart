import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sinau_firebase/utils/custom_notification_utils.dart';

class EditProfilePage extends StatefulWidget {
  final User currentUser;
  final Map<String, dynamic> userData; // Data pengguna dari Firestore

  const EditProfilePage({
    super.key,
    required this.currentUser,
    required this.userData,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _emailController;
  late TextEditingController _usernameController;
  bool _isLoading = false;

  String _initialEmail = '';
  String _initialUsername = '';

  @override
  void initState() {
    super.initState();
    _initialEmail = widget.userData['email'] as String? ?? widget.currentUser.email ?? '';
    _initialUsername = widget.userData['username'] as String? ?? '';

    _emailController = TextEditingController(text: _initialEmail);
    _usernameController = TextEditingController(text: _initialUsername);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _saveProfileChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (mounted) setState(() => _isLoading = true);

    String newEmail = _emailController.text.trim();
    String newUsername = _usernameController.text.trim();
    bool emailChanged = newEmail != _initialEmail;
    bool usernameChanged = newUsername != _initialUsername;

    try {
      // 1. Validasi dan Update Email (jika berubah)
      if (emailChanged) {
        // Cek apakah email baru sudah digunakan oleh pengguna lain
        try {
          // Firebase Auth check (lebih kuat)
          final List<UserInfo> providers = widget.currentUser.providerData;
          bool emailProviderExists = providers.any((p) => p.providerId == EmailAuthProvider.PROVIDER_ID);

          if(emailProviderExists) {
             final methods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(newEmail);
             if (methods.isNotEmpty) {
                if (mounted) showErrorSnackbar('Email ini sudah digunakan oleh akun lain.');
                if (mounted) setState(() => _isLoading = false);
                return;
             }
          } else {
            // Jika pengguna login dengan provider lain (Google, dll) dan mencoba mengubah email
            // yang tidak terkait dengan provider email, ini mungkin tidak diperlukan atau
            // memerlukan penanganan khusus. Untuk saat ini, kita fokus pada email/password.
            print("Pengguna tidak menggunakan EmailAuthProvider, pengecekan email Auth dilewati.");
          }


          // Update email di Firebase Auth
          // Ini adalah operasi sensitif dan mungkin memerlukan re-autentikasi
          await widget.currentUser.verifyBeforeUpdateEmail(newEmail);
          // Beri tahu pengguna untuk memeriksa email mereka untuk verifikasi email baru
          if (mounted) {
             showSuccessSnackbar('Email berhasil diajukan untuk diubah. Silakan verifikasi email baru Anda.');
          }
          // Email di Firestore akan diupdate bersama username atau setelah Auth update berhasil
        } on FirebaseAuthException catch (e) {
          if (mounted) {
            showErrorSnackbar('Gagal memperbarui email di Auth: ${e.message}');
            setState(() => _isLoading = false);
          }
          return;
        }
      }

      // 2. Validasi dan Update Username (jika berubah)
      WriteBatch? batch; // Gunakan batch untuk update username di users dan journals

      if (usernameChanged) {
        // Cek apakah username baru sudah digunakan oleh pengguna lain
        final usernameCheck = await FirebaseFirestore.instance
            .collection('users')
            .where('username', isEqualTo: newUsername)
            .limit(1)
            .get();

        if (usernameCheck.docs.isNotEmpty) {
          if (mounted) showErrorSnackbar('Username ini sudah digunakan. Silakan pilih username lain.');
          if (mounted) setState(() => _isLoading = false);
          return;
        }
        // Jika username tersedia, siapkan update untuk Firestore
        batch = FirebaseFirestore.instance.batch();
        batch.update(FirebaseFirestore.instance.collection('users').doc(widget.currentUser.uid), {
          'username': newUsername,
        });

        // Update username di semua jurnal yang ditulis oleh pengguna ini
        final journalsQuery = await FirebaseFirestore.instance
            .collection('journals')
            .where('userId', isEqualTo: widget.currentUser.uid)
            .get();

        for (var doc in journalsQuery.docs) {
          batch.update(doc.reference, {'username': newUsername});
        }
      }

      // 3. Update email di Firestore (jika email di Auth berhasil diajukan untuk diubah atau tidak berubah)
      // dan commit batch jika ada perubahan username
      DocumentReference userDocRef = FirebaseFirestore.instance.collection('users').doc(widget.currentUser.uid);

      if (emailChanged && !usernameChanged) { // Hanya email berubah
        await userDocRef.update({'email': newEmail});
      } else if (!emailChanged && usernameChanged && batch != null) { // Hanya username berubah
        await batch.commit();
      } else if (emailChanged && usernameChanged && batch != null) { // Keduanya berubah
        batch.update(userDocRef, {'email': newEmail});
        await batch.commit();
      } else if (!emailChanged && !usernameChanged) {
        // Tidak ada perubahan
        if (mounted) showSuccessSnackbar('Tidak ada perubahan untuk disimpan.');
        if (mounted) setState(() => _isLoading = false);
        if (mounted) Navigator.of(context).pop(true); // Pop dengan hasil true menandakan ada update
        return;
      }


      if (mounted) {
        showSuccessSnackbar('Profil berhasil diperbarui!');
        Navigator.of(context).pop(true); // Pop dengan hasil true menandakan ada update
      }

    } catch (e) {
      if (mounted) {
        showErrorSnackbar('Terjadi kesalahan saat menyimpan perubahan: $e');
        print("Error saving profile: $e");
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void showErrorSnackbar(String message) {
    if (mounted) {
      TopNotification.show(context, message, type: NotificationType.error);
    }
  }
  void showSuccessSnackbar(String message) {
    if (mounted) {
      TopNotification.show(context, message, type: NotificationType.success);
    }
  }


  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Edit Profil'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 1.0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Ubah Email',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    hintText: 'Masukkan email baru',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Email tidak boleh kosong.';
                    }
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'Format email tidak valid.';
                    }
                    return null;
                  },
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, left: 12.0),
                  child: Text(
                    'Perubahan email memerlukan verifikasi melalui email baru Anda.',
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Ubah Username',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    hintText: 'Masukkan username baru',
                    prefixIcon: const Icon(Icons.account_circle_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0)),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Username tidak boleh kosong.';
                    }
                    if (value.contains(' ') || value.contains('@')) {
                      return "Username tidak boleh mengandung spasi atau karakter '@'.";
                    }
                    if (value.length < 3) {
                        return "Username minimal 3 karakter.";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 40),
                ElevatedButton.icon(
                  icon: _isLoading
                      ? Container(
                          width: 20,
                          height: 20,
                          child: const CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                        )
                      : const Icon(Icons.save_alt_outlined),
                  label: Text(_isLoading ? 'Menyimpan...' : 'Simpan Perubahan', style: const TextStyle(fontSize: 16)),
                  onPressed: _isLoading ? null : _saveProfileChanges,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    elevation: 3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
