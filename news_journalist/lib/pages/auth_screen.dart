// lib/pages/auth_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthScreen extends StatefulWidget {
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();
  String email = '';
  String password = '';
  String error = '';
  bool _isLoading = false;
  bool _isLoginMode = true; // true for login, false for register
  String _selectedRole = 'journalist'; // Default role for registration

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isLoginMode ? 'Login Aplikasi' : 'Daftar Akun', // Judul lebih umum
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 30.0), // Padding lebih besar
              child: Form(
                key: _formKey,
                child: Column(
                  children: <Widget>[
                    SizedBox(height: 20.0),
                    Text(
                      _isLoginMode ? 'Selamat Datang Kembali!' : 'Buat Akun Baru',
                      style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 10.0),
                    Text(
                      _isLoginMode ? 'Silakan login untuk melanjutkan.' : 'Daftar untuk mengakses fitur.',
                      style: GoogleFonts.openSans(fontSize: 16, color: Colors.grey[700]),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 30.0),
                    TextFormField(
                      decoration: InputDecoration(
                        hintText: 'Email',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      keyboardType: TextInputType.emailAddress,
                      validator: (val) => val!.isEmpty ? 'Masukkan email' : null,
                      onChanged: (val) {
                        setState(() => email = val);
                      },
                    ),
                    SizedBox(height: 20.0),
                    TextFormField(
                      decoration: InputDecoration(
                        hintText: 'Password',
                        prefixIcon: Icon(Icons.lock),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                      obscureText: true,
                      validator: (val) => val!.length < 6 ? 'Password minimal 6 karakter' : null,
                      onChanged: (val) {
                        setState(() => password = val);
                      },
                    ),
                    SizedBox(height: 20.0),
                    if (!_isLoginMode) // Tampilkan pilihan role saat mendaftar
                      Column(
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Pilih Role:',
                              style: GoogleFonts.poppins(fontSize: 16, color: Colors.black87),
                            ),
                          ),
                          DropdownButtonFormField<String>(
                            value: _selectedRole,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: Colors.grey[100],
                            ),
                            items: ['journalist', 'reviewer'].map((String role) {
                              return DropdownMenuItem<String>(
                                value: role,
                                child: Text(role.toUpperCase(), style: GoogleFonts.openSans()),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedRole = newValue!;
                              });
                            },
                          ),
                          SizedBox(height: 20.0),
                        ],
                      ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 5,
                      ),
                      child: Text(
                        _isLoginMode ? 'LOGIN' : 'DAFTAR',
                        style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          setState(() {
                            _isLoading = true;
                            error = '';
                          });
                          try {
                            User? result;
                            if (_isLoginMode) {
                              result = await _auth.signInWithEmailAndPassword(email, password);
                            } else {
                              result = await _auth.registerWithEmailAndPassword(email, password, _selectedRole);
                            }

                            if (result != null) {
                              // Autentikasi berhasil, biarkan StreamBuilder di MyApp yang menangani navigasi
                              // Cukup pop AuthScreen jika sedang di-push
                              if (Navigator.of(context).canPop()) {
                                Navigator.of(context).pop();
                              }
                            } else {
                              // Ini seharusnya ditangkap oleh try-catch di atas, tapi sebagai fallback
                              setState(() {
                                _isLoading = false;
                                error = 'Autentikasi gagal. Coba lagi.';
                              });
                            }
                          } catch (e) {
                            setState(() {
                              _isLoading = false;
                              error = e.toString().replaceFirst('Exception: ', '');
                            });
                          }
                        }
                      },
                    ),
                    SizedBox(height: 15.0),
                    Text(
                      error,
                      style: GoogleFonts.openSans(color: Colors.red, fontSize: 14.0),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20.0),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isLoginMode = !_isLoginMode;
                          error = ''; // Clear error message
                          email = ''; // Clear fields on mode switch
                          password = '';
                          _formKey.currentState?.reset(); // Reset form validation
                        });
                      },
                      child: Text(
                        _isLoginMode ? 'Belum punya akun? Daftar Sekarang' : 'Sudah punya akun? Login di Sini',
                        style: GoogleFonts.openSans(color: Theme.of(context).colorScheme.primary, fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}