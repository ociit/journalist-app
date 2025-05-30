// lib/services/auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Import Firestore
import 'package:flutter/foundation.dart';
import 'package:rxdart/rxdart.dart';


class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Inisialisasi Firestore

  // Mendapatkan stream perubahan status autentikasi pengguna
  Stream<User?> get user {
    return _firebaseAuth.authStateChanges();
  }

  // --- Fungsi untuk mendapatkan data pengguna dari Firestore ---
  // Ini akan mengembalikan Stream<Map<String, dynamic>?>
  // agar kita bisa mendengarkan perubahan data profil pengguna (termasuk role)
  Stream<Map<String, dynamic>?> get userProfile {
    return _firebaseAuth.authStateChanges().switchMap((user) {
      if (user == null) {
        return Stream.value(null);
      } else {
        return _firestore.collection('users').doc(user.uid).snapshots().map((snapshot) {
          if (snapshot.exists) {
            return snapshot.data();
          }
          return null;
        });
      }
    });
  }

  // Fungsi untuk login anonim (opsional, jika masih ingin ada)
  Future<User?> signInAnonymously() async {
    try {
      UserCredential result = await _firebaseAuth.signInAnonymously();
      // Tambahkan data profil ke Firestore jika baru login anonim
      if (result.user != null && result.additionalUserInfo!.isNewUser) {
        await _firestore.collection('users').doc(result.user!.uid).set({
          'email': null, // Anonim tidak punya email
          'role': 'journalist', // Default role untuk anonim
          'createdAt': FieldValue.serverTimestamp(),
          'lastSignInTime': FieldValue.serverTimestamp(),
        });
      } else if (result.user != null) {
        // Update last sign in time for existing users
        await _firestore.collection('users').doc(result.user!.uid).update({
          'lastSignInTime': FieldValue.serverTimestamp(),
        });
      }
      debugPrint('Anonymous user signed in: ${result.user?.uid}');
      return result.user;
    } catch (e) {
      debugPrint('Error signing in anonymously: $e');
      return null;
    }
  }

  // Fungsi untuk login dengan email dan password
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      UserCredential result = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      // Update last sign in time for existing users
      if (result.user != null) {
        await _firestore.collection('users').doc(result.user!.uid).update({
          'lastSignInTime': FieldValue.serverTimestamp(),
        });
      }
      debugPrint('User signed in with email: ${result.user?.uid}');
      return result.user;
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      if (e.code == 'user-not-found') {
        errorMessage = 'Tidak ada pengguna ditemukan dengan email tersebut.';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Password salah untuk pengguna tersebut.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Format email tidak valid.';
      } else {
        errorMessage = 'Autentikasi gagal: ${e.message}';
      }
      debugPrint('Error signing in with email: $errorMessage');
      throw Exception(errorMessage);
    } catch (e) {
      debugPrint('General error signing in with email: $e');
      throw Exception('Terjadi kesalahan saat login: $e');
    }
  }

  // Fungsi untuk mendaftar pengguna dengan email dan password
  // Anda bisa menentukan role di sini saat pendaftaran
  Future<User?> registerWithEmailAndPassword(String email, String password, String role) async {
    try {
      UserCredential result = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      if (result.user != null) {
        // Simpan data pengguna dan role di Firestore
        await _firestore.collection('users').doc(result.user!.uid).set({
          'email': email,
          'role': role, // Role ditentukan saat pendaftaran (misal: 'journalist' atau 'reviewer')
          'createdAt': FieldValue.serverTimestamp(),
          'lastSignInTime': FieldValue.serverTimestamp(),
        });
      }
      debugPrint('New user registered: ${result.user?.uid} with role: $role');
      return result.user;
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      if (e.code == 'weak-password') {
        errorMessage = 'Password terlalu lemah.';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'Email sudah digunakan.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Format email tidak valid.';
      } else {
        errorMessage = 'Registrasi gagal: ${e.message}';
      }
      debugPrint('Error registering with email: $errorMessage');
      throw Exception(errorMessage);
    } catch (e) {
      debugPrint('General error registering: $e');
      throw Exception('Terjadi kesalahan saat registrasi: $e');
    }
  }

  // Fungsi untuk logout
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
      debugPrint('User signed out.');
    } catch (e) {
      debugPrint('Error signing out: $e');
    }
  }
}