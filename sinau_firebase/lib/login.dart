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
  TextEditingController loginIdentifierController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool _isLoading = false;

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
    loginIdentifierController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> signIn() async {
    if (mounted) setState(() => _isLoading = true);

    String loginInput = loginIdentifierController.text.trim();
    String password = passwordController.text.trim();

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
          final userData = userQuery.docs.first.data() as Map<String, dynamic>?;
          emailToUse = userData?['email'] as String?;
        } else {
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

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailToUse,
        password: password,
      );

      print("Login Berhasil: ${FirebaseAuth.instance.currentUser?.email}");

      // TODO: Navigasi ke halaman berikutnya
      // if (mounted) {
      //   Navigator.pushReplacement(
      //     context,
      //     MaterialPageRoute(builder: (context) => const HomePage()),
      //   );
      // }

    } on FirebaseAuthException catch (e) {
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      print('Terjadi kesalahan lain: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Terjadi kesalahan yang tidak terduga.')),
        );
      }
    } finally {
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                // Logo atau Judul Aplikasi (opsional)
                const FlutterLogo(size: 100),
                const SizedBox(height: 40),
                Text(
                  'Selamat Datang',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: loginIdentifierController,
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    labelText: 'Email atau Username',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _isLoading ? null : signIn,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    elevation: 3,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text('Login', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const RegisterPage()),
                    );
                  },
                  child: const Text('Belum punya akun? Daftar di sini', style: TextStyle(fontSize: 14)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}