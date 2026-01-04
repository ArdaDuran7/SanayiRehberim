import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'global.dart';          // Tema ayarı buradan geliyor
import 'giris_islemleri.dart'; // İlk açılış ekranı buradan geliyor

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

          // --- AYDINLIK TEMA ---
          theme: ThemeData(
            primarySwatch: Colors.blueGrey,
            brightness: Brightness.light,
            scaffoldBackgroundColor: Colors.grey[100],
            useMaterial3: true,
            appBarTheme: AppBarTheme(backgroundColor: Colors.blueGrey.shade800, foregroundColor: Colors.white),
            inputDecorationTheme: InputDecorationTheme(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              filled: true,
              fillColor: Colors.white,
            ),
          ),

          // --- KARANLIK TEMA ---
          darkTheme: ThemeData(
            primarySwatch: Colors.blueGrey,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF121212),
            useMaterial3: true,
            appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF1F1F1F), foregroundColor: Colors.white),
            canvasColor: const Color(0xFF2C2C2C),
            dialogBackgroundColor: const Color(0xFF2C2C2C),
            inputDecorationTheme: InputDecorationTheme(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              filled: true,
              fillColor: const Color(0xFF2C2C2C),
            ),
          ),

          themeMode: mode,

          // Başlangıç noktası artık giris_islemleri.dart dosyasında
          home: const AuthGate(),
        );
      },
    );
  }
}