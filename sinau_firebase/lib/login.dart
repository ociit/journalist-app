import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sinau_firebase/register.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  TextEditingController loginIdentifierController = TextEditingController(); // Mengganti nama variabel agar lebih jelas
  TextEditingController passwordController = TextEditingController(); // Mengganti nama variabel agar lebih jelas
  bool _isLoading = false; // State untuk loading indicator

    void showErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
      );
    }
  }

  void setLoading(bool loading) {
    if (mounted) setState(() => _isLoading = loading);
  }

  @override
  void dispose() {
    // Selalu dispose controller ketika widget tidak lagi digunakan
    loginIdentifierController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> signIn() async { // Mengubah menjadi Future<void> agar lebih jelas
    // 0. Set loading state menjadi true
    if(mounted) setState(() => _isLoading = true);

    //! 1. Ambil dan trim input dari controller
    String loginInput = loginIdentifierController.text.trim();
    String password = passwordController.text.trim();

    // Validasi dasar apakah field kosong (opsional tapi baik)
      if (loginInput.isEmpty || password.isEmpty) {
        showErrorSnackbar('Email/Username dan Password tidak boleh kosong.');
        setLoading(false);
        return;
      }

    String? emailToUse;

    try {
      bool isEmail = loginInput.contains('@');

      if (isEmail) {
        emailToUse = loginInput;
      } else {
        final QuerySnapshot userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: loginInput)
          .limit(1)
          .get();

        if (userQuery.docs.isNotEmpty) {
          // Username ditemukan, ambil emailnya
          final userData = userQuery.docs.first.data() as Map<String, dynamic>?; // Casting
          emailToUse = userData?['email'] as String?; // Ambil email, pastikan casting aman
        } else {
          // Username tidak ditemukan
          showErrorSnackbar('Username tidak ditemukan.');
          setLoading(false);
          return;
        }
      }

      if (emailToUse == null || emailToUse.isEmpty) {
        showErrorSnackbar('Gagal mendapatkan email untuk login.');
        setLoading(false);
        return;
      }


      //! 2. Lakukan proses sign in
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailToUse,
        password: password,
      );

      // Jika login berhasil
      print("Login Berhasil: ${userCredential.user?.email}");

      // TODO: Navigasi ke halaman berikutnya (misalnya halaman beranda)
      // Pastikan Anda sudah membuat halaman ini dan mengimpornya
      // if (mounted) {
      //   Navigator.pushReplacement(
      //     context,
      //     MaterialPageRoute(builder: (context) => const HomePage()), // Ganti HomePage dengan halaman Anda
      //   );
      // }

    } on FirebaseAuthException catch (e) {
      //! 3. Tangani error spesifik dari Firebase Auth
      String errorMessage;
      if (e.code == 'user-not-found') {
        errorMessage = 'Pengguna dengan email tersebut tidak ditemukan.';
        print('No user found for that email.');
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Password yang dimasukkan salah.';
        print('Wrong password provided for that user.');
      } else if (e.code == 'invalid-credential') {
        errorMessage = 'Email atau password salah. Silakan coba lagi.';
        print('Invalid credential provided.');
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Format email tidak valid.';
        print('The email address is not valid.');
      } else if (e.code == 'user-disabled') {
        errorMessage = 'Akun pengguna ini telah dinonaktifkan.';
        print('User account has been disabled.');
      } else {
        errorMessage = 'Terjadi kesalahan: Silakan coba beberapa saat lagi.';
        print('An unknown Firebase error occurred: ${e.code} - ${e.message}');
      }

      // Tampilkan pesan error menggunakan SnackBar
      if (mounted) { // Pastikan widget masih terpasang (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      //! 4. Tangani error umum lainnya
      print('Terjadi kesalahan lain: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Terjadi kesalahan yang tidak terduga.')),
        );
      }
    } finally {
      //! 5. Set loading state kembali ke false setelah selesai (baik sukses maupun gagal)
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

@override
Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextField(
                  controller: loginIdentifierController, // Controller untuk email/username
                  decoration: const InputDecoration(
                    hintText: 'Masukkan Email atau Username', // Hint diubah
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  keyboardType: TextInputType.text, // Bisa text biasa
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
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _isLoading ? null : signIn,
                  style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.0))
                      : const Text("Login"),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RegisterPage()),
                    );
                  },
                  child: const Text("Belum punya akun? Daftar di sini"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}