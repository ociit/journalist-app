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
  final TextEditingController confirmPasswordController = TextEditingController();
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

    if (email.isEmpty || username.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      showErrorSnackbar("Semua Kolom tidak boleh kosong.");
      setLoading(false);
      return;
    }

    if (selectedRole == null) {
      showErrorSnackbar("Silahkan Pilih Peran Anda.");
      setLoading(false);
      return;
    }

    if (password != confirmPassword) {
      showErrorSnackbar("Password dan konfirmasi password tidak cocok.");
      setLoading(false);
      return;
    }

    if (username.contains(" ") || username.contains("@")) {
      showErrorSnackbar(
        "Username tidak boleh mengandung spasi atau karakter '@'.",
      );
      setLoading(false);
      return;
    }

    try {
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

      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      if (userCredential.user != null) {
        print("SIGN_UP_DEBUG: UID Pengguna Auth: ${userCredential.user!.uid}");
        print("SIGN_UP_DEBUG: Mencoba menyimpan data ke Firestore dengan detail:");
        print("SIGN_UP_DEBUG: UID: ${userCredential.user!.uid}, Email: $email, Username: $username, Role: $selectedRole");

        try {
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
          print("SIGN_UP_DEBUG: Data pengguna BERHASIL disimpan ke Firestore.");
        } catch (firestoreError, stackTrace) {
          print("!!!!!!!! SIGN_UP_DEBUG: GAGAL menyimpan data ke Firestore !!!!!!!!!!");
          print("!!!!!!!! Error Firestore: $firestoreError");
          print("!!!!!!!! Stack Trace Firestore: $stackTrace");
          showErrorSnackbar("Akun berhasil dibuat di Auth, tetapi gagal menyimpan detail profil ke database. Silakan hubungi support.");
        }
      } else {
        print("SIGN_UP_DEBUG: userCredential.user adalah null setelah pembuatan akun Auth. Seharusnya tidak terjadi.");
      }

      print("Registrasi Berhasil: ${userCredential.user?.email}");
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

  void showErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
      );
    }
  }

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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  'Buat Akun Baru',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 30),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: usernameController,
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    prefixIcon: const Icon(Icons.account_circle),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
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
                const SizedBox(height: 15),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Konfirmasi Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Pilih Peran Anda',
                    prefixIcon: const Icon(Icons.person_pin_circle),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                  ),
                  value: selectedRole,
                  hint: const Text('Pilih Peran'),
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
                  validator: (value) => value == null ? 'Peran tidak boleh kosong' : null,
                ),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: isLoading ? null : signUp,
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
                      : const Text('Register', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Sudah punya akun? Login disini', style: TextStyle(fontSize: 14)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}