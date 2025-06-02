import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:sinau_firebase/wrapper.dart';
import 'firebase_options.dart'; // <-- PASTIKAN INI ADA DAN DIIMPOR, jangan lupa untuk jalankan perintah 'flutterfire configure' dlu

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // print("MAIN: Memulai inisialisasi Firebase..."); // DEBUG
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // print("MAIN: Firebase BERHASIL diinisialisasi!"); // DEBUG
  } catch (e) {
    // print("!!!!!!!! ERROR SAAT INISIALISASI FIREBASE: $e !!!!!!!!!!"); // DEBUG
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Journalist App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: Wrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}