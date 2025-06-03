import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:sinau_firebase/wrapper.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print("!!!!!!!! ERROR SAAT INISIALISASI FIREBASE: $e !!!!!!!!!!"); // DEBUG
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Journalist App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true
      ),
      home: Wrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}