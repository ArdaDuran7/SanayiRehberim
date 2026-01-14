import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart'; // Font paketi
import 'global.dart';
import 'giris_islemleri.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const SanayiRehberimApp());
}

class SanayiRehberimApp extends StatelessWidget {
  const SanayiRehberimApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: temaModu,
      builder: (context, mode, child) {
        return MaterialApp(
          title: 'Sanayi Rehberim',
          debugShowCheckedModeBanner: false,

          // --- MODERN AYDINLIK TEMA ---
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF0F172A), // Slate 900
              primary: const Color(0xFF0F172A),
              secondary: const Color(0xFFF59E0B), // Amber 500
            ),
            scaffoldBackgroundColor: const Color(0xFFF1F5F9), // Slate 100
            appBarTheme: AppBarTheme(
              backgroundColor: const Color(0xFF0F172A),
              foregroundColor: Colors.white,
              elevation: 0,
              centerTitle: true,
              titleTextStyle: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            textTheme: GoogleFonts.poppinsTextTheme(),
            // cardTheme kısmını sildik, hata düzeldi.
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0F172A), width: 2)),
            ),
          ),

          // --- MODERN KARANLIK TEMA ---
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF0F172A),
              brightness: Brightness.dark,
              primary: const Color(0xFF94A3B8),
              secondary: const Color(0xFFF59E0B),
            ),
            scaffoldBackgroundColor: const Color(0xFF0B1120), // Çok koyu lacivert
            appBarTheme: AppBarTheme(
              backgroundColor: const Color(0xFF0B1120),
              foregroundColor: Colors.white,
              elevation: 0,
              titleTextStyle: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
            // cardTheme kısmını sildik, hata düzeldi.
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFF1E293B),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            ),
          ),

          themeMode: mode,
          home: const AuthGate(),
        );
      },
    );
  }
}