import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  bool isLoading = false;

  String? selectedRole;
  final List<String> roles = ['Journalist', 'Reviewer'];

  @override
  void dispose() {
    emailController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> signUp() async {
    if (mounted) {
      setState(() {
        isLoading = true;
      });
    }

    String email = emailController.text.trim();
    String username = usernameController.text.trim();
    String password = passwordController.text.trim();
    String confirmPassword = confirmPasswordController.text.trim();

    //? Validasi dasar
    if (email.isEmpty ||
        username.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      showErrorSnackbar("Semua Kolom tidak boleh kosong.");
      setLoading(false);
      return;
    }

    //* Validasi Role
    if (selectedRole == null) {
      showErrorSnackbar("Silahkan Pilih Peran Anda.");
      setLoading(false);
      return;
    }

    //* Validasi kecocokan konfirmasi password
    if (password != confirmPassword) {
      showErrorSnackbar("Password dan konfirmasi password tidak cocok.");
      setLoading(false);
      return;
    }

    //* Validasi username
    if (username.contains(" ") || username.contains("@")) {
      showErrorSnackbar(
        "Username tidak boleh mengandung spasi atau karakter '@'.",
      );
      setLoading(false);
      return;
    }

    try {
      //? Cek Ketersediaan username
      final usernameCheck = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (usernameCheck.docs.isNotEmpty) {
        showErrorSnackbar(
          "username ini sudah digunakan. Silahkan pilih username lain.",
        );
        setLoading(false);
        return;
      }

      //! Membuat pengguna baru dengan email dan passowrd
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

          if (userCredential.user != null) {
            // Tambahkan print statement sebelum dan sesudah operasi Firestore
            print("SIGN_UP_DEBUG: UID Pengguna Auth: ${userCredential.user!.uid}");
            print("SIGN_UP_DEBUG: Mencoba menyimpan data ke Firestore dengan detail:");
            print("SIGN_UP_DEBUG: UID: ${userCredential.user!.uid}, Email: $email, Username: $username, Role: $selectedRole");

            try { // <-- Tambahkan try spesifik untuk Firestore
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(userCredential.user!.uid)
                  .set({
                    'uid': userCredential.user!.uid,
                    'email': email,
                    'username': username, // Pastikan sudah diperbaiki dari 'usernamme'
                    'role': selectedRole,
                    'createdAt': Timestamp.now(),
                  });
              print("SIGN_UP_DEBUG: Data pengguna BERHASIL disimpan ke Firestore."); // <-- Apakah ini tercetak?
            } catch (firestoreError, stackTrace) { // <-- Tangkap error Firestore
              print("!!!!!!!! SIGN_UP_DEBUG: GAGAL menyimpan data ke Firestore !!!!!!!!!!");
              print("!!!!!!!! Error Firestore: $firestoreError");
              print("!!!!!!!! Stack Trace Firestore: $stackTrace");
              // Tampilkan pesan ke pengguna bahwa detail profil gagal disimpan
              showErrorSnackbar("Akun berhasil dibuat di Auth, tetapi gagal menyimpan detail profil ke database. Silakan hubungi support.");
              // Pertimbangkan: Apakah Anda ingin menghapus akun Auth jika penyimpanan Firestore gagal?
              // Ini adalah langkah yang lebih kompleks. Untuk sekarang, cukup log dan informasikan.
            }
          } else {
            print("SIGN_UP_DEBUG: userCredential.user adalah null setelah pembuatan akun Auth. Seharusnya tidak terjadi.");
          }

      print("Registrasi Berhasil: ${userCredential.user?.email}");
      if (userCredential.user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
              'uid': userCredential.user!.uid,
              'email': email,
              'username': username,
              'role': selectedRole,
              'createdAt': Timestamp.now(),
            });
        print("Data pengguna berhasil disimpan ke Firestore.");
      }
      // Setelah berhasil registrasi, Wrapper akan otomatis mengarahkan ke HomePage
      // karena authStateChanges akan mendeteksi pengguna baru.
      // Jadi, tidak perlu navigasi manual di sini jika Wrapper sudah benar.

      //* Opsional: Anda bisa pop halaman register agar kembali ke state Wrapper
      //* yang kemudian akan menampilkan HomePage.
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      if (e.code == 'weak-password') {
        errorMessage = 'Password yang dimasukkan terlalu lemah.';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'Email ini sudah digunakan oleh akun lain.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Format email tidak valid.';
      } else {
        errorMessage = 'Gagal mendaftar. Silakan coba lagi.';
        print('Firebase error: ${e.code} - ${e.message}');
      }

      showErrorSnackbar(errorMessage);
    } catch (e) {
      showErrorSnackbar('Terjadi kesalahan yang tidak terduga.');
      print('Generic error: $e');
    } finally {
      setLoading(false);
    }
  }

  //? Helper Method untuk snackbar error
  void showErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
      );
    }
  }

  //? Helper method untuk mengatur state loading
  void setLoading(bool loading) {
    if (mounted) {
      setState(() {
        isLoading = loading;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Register Akun Baru")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    hintText: 'Masukkan Email',
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: usernameController,
                  decoration: const InputDecoration(
                    hintText: 'Masukkan Username',
                    prefixIcon: Icon(Icons.account_circle),
                  ),
                  keyboardType: TextInputType.text,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(
                    hintText: 'Masukkan Password',
                    prefixIcon: Icon(Icons.lock),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: confirmPasswordController,
                  decoration: const InputDecoration(
                    hintText: 'Konfirmasi Password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  obscureText: true,
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Pilih Peran Anda',
                    prefixIcon: Icon(Icons.person_pin_circle),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  value: selectedRole,
                  hint: Text('Pilih Peran'),
                  items: roles.map((String role) {
                    return DropdownMenuItem<String>(
                      value: role,
                      child: Text(role),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedRole = newValue;
                    });
                  },
                  validator: (value) =>
                      value == null ? 'Peran tidak boleh kosong' : null,
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: isLoading ? null : signUp,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const ui.Size(double.infinity, 50),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.0,
                          ),
                        )
                      : const Text("Register"),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    // Kembali ke halaman login
                    // Jika Anda menggunakan Navigator.push untuk ke halaman register dari login,
                    // maka Navigator.pop(context) sudah cukup.
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  },
                  child: const Text("Sudah punya akun? Login disini"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
