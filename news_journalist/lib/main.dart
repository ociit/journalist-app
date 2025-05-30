// lib/main.dart

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth

import 'firebase_options.dart'; // Pastikan ini ada

import 'pages/journal_list_page.dart';
import 'pages/news_page.dart';
import 'pages/weather_page.dart';
import 'pages/auth_screen.dart'; // Import halaman autentikasi
import 'pages/profile_page.dart'; // Import halaman profil
import 'services/auth_service.dart'; // Import AuthService

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await initializeDateFormatting('id_ID', null);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final AuthService _auth = AuthService(); // Inisialisasi AuthService

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'News, Weather & Journals',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.deepPurple,
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          elevation: 4,
          titleTextStyle: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: Theme.of(context).colorScheme.secondary,
          foregroundColor: Theme.of(context).colorScheme.onSecondary,
          elevation: 6,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
          selectedLabelStyle:
              GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 13),
          unselectedLabelStyle: GoogleFonts.poppins(fontSize: 12),
          elevation: 8,
        ),
      ),
      // Gunakan StreamBuilder untuk mendengarkan status autentikasi
      home: StreamBuilder<User?>(
        stream: _auth.user, // Mendengarkan stream perubahan status autentikasi
        builder: (BuildContext context, AsyncSnapshot<User?> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // Tampilkan loading screen saat menunggu status autentikasi
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          } else if (snapshot.hasData && snapshot.data != null) {
            // Jika ada pengguna yang login (baik anonim, email, dll.)
            return MainAppScaffold(); // Tampilkan halaman utama aplikasi
          } else {
            // Jika tidak ada pengguna yang login, arahkan ke halaman autentikasi
            return AuthScreen();
          }
        },
      ),
    );
  }
}

// === Widget baru untuk Scaffold utama Anda dengan BottomNavigationBar ===
class MainAppScaffold extends StatefulWidget {
  @override
  _MainAppScaffoldState createState() => _MainAppScaffoldState();
}

class _MainAppScaffoldState extends State<MainAppScaffold> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    NewsPage(),
    WeatherPage(),
    JournalListPage(),
    ProfilePage(), // Tambahkan ProfilePage ke daftar halaman
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.article_outlined),
            activeIcon: Icon(Icons.article),
            label: 'Berita',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.cloud_outlined),
            activeIcon: Icon(Icons.cloud),
            label: 'Cuaca',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book_outlined),
            activeIcon: Icon(Icons.book),
            label: 'Jurnal',
          ),
          BottomNavigationBarItem( // Item baru untuk Profile
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
      // AppBar di MainAppScaffold sekarang akan lebih sederhana karena tidak ada tombol login/logout lagi di sini
      appBar: AppBar(
        title: Text(
          _selectedIndex == 0 ? 'Berita Terkini' :
          _selectedIndex == 1 ? 'Info Cuaca' :
          _selectedIndex == 2 ? 'Jurnal Saya' :
          'Profil Saya', // Sesuaikan judul AppBar
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
    );
  }
}