import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sinau_firebase/pages/register.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sinau_firebase/utils/custom_notification_utils.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => LoginState();
}

class LoginState extends State<Login> {
  TextEditingController loginIdentifierController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  bool isLoading = false;
  bool isPasswordVisible = false;

  void setLoading(bool loading) {
    if (mounted) setState(() => isLoading = loading);
  }

  @override
  void dispose() {
    loginIdentifierController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> signIn() async {
    String loginInput = loginIdentifierController.text.trim();
    String password = passwordController.text.trim();
    String? emailToUse;

    if (mounted) setState(() => isLoading = true);
    if (loginInput.isEmpty || password.isEmpty) {
      TopNotification.show(context, 'Email/Username dan Password tidak boleh kosong.', type: NotificationType.error);
      setLoading(false);
      return;
    }

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
          TopNotification.show(context, 'Username tidak ditemukan.', type: NotificationType.error);
          setLoading(false);
          return;
        }
      }

      if (emailToUse == null || emailToUse.isEmpty) {
        TopNotification.show(context, 'Gagal mendapatkan email untuk login.', type: NotificationType.error);
        setLoading(false);
        return;
      }

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailToUse,
        password: password,
      );

      print("Login Berhasil: ${FirebaseAuth.instance.currentUser?.email}");

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

      //? Menampilkan notif untuk error
      if (mounted) {
        TopNotification.show(context, errorMessage, type: NotificationType.error);
      }

    } catch (e) {
      print('Terjadi kesalahan lain: $e');
      if (mounted) {
        TopNotification.show(context, 'Terjadi kesalahan yang tidak terduga.', type: NotificationType.error);
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Image.asset(
                  'assets/images/logo.png',
                  width: 120,
                  height: 120,
                ),
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
                  obscureText: !isPasswordVisible,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        isPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: Colors.grey[600],
                      ),
                      onPressed: () {
                        setState(() {
                          isPasswordVisible = !isPasswordVisible;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: isLoading ? null : signIn,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    elevation: 3,
                  ),
                  child: isLoading
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
                    if(isLoading) {
                      return;
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RegisterPage()),
                      );
                    }
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