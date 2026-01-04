import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'uygulama_ici.dart'; // Ana ekranı çağırmak için gerekli

// --- 1. KAPICI (AUTH GATE) ---
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Kullanıcı giriş yapmışsa Ana Ekrana (uygulama_ici.dart'tan gelir) git
        if (snapshot.hasData) return const MagazaListesiEkrani();
        // Yapmamışsa Giriş Ekranında kal
        return const GirisKayitEkrani();
      },
    );
  }
}

// --- 2. GİRİŞ VE KAYIT EKRANI ---
class GirisKayitEkrani extends StatefulWidget {
  const GirisKayitEkrani({super.key});
  @override
  State<GirisKayitEkrani> createState() => _GirisKayitEkraniState();
}

class _GirisKayitEkraniState extends State<GirisKayitEkrani> {
  bool girisModu = true;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool isLoading = false;

  Future<void> _islemYap() async {
    setState(() => isLoading = true);
    try {
      if (girisModu) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
          'email': _emailController.text.trim(),
          'rol': 'musteri',
          'adSoyad': '',
          'telefon': '',
          'favoriler': [],
        });
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? "Hata"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    Color iconColor = isDark ? Colors.white : Colors.blueGrey.shade800;
    Color textColor = isDark ? Colors.white : Colors.blueGrey.shade900;
    Color bgColor = isDark ? Colors.black : Colors.blueGrey.shade100;

    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(Icons.car_repair, size: 80, color: iconColor),
              const SizedBox(height: 10),
              Text(girisModu ? 'Giriş Yap' : 'Hesap Oluştur', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textColor)),
              const SizedBox(height: 30),
              TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'E-Posta', prefixIcon: Icon(Icons.email)), keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 15),
              TextField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Şifre', prefixIcon: Icon(Icons.lock)), obscureText: true),
              const SizedBox(height: 25),
              SizedBox(width: double.infinity, height: 50, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey.shade800, foregroundColor: Colors.white), onPressed: isLoading ? null : _islemYap, child: isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(girisModu ? 'GİRİŞ YAP' : 'KAYIT OL', style: const TextStyle(fontWeight: FontWeight.bold)))),
              const SizedBox(height: 10),
              TextButton(onPressed: () => setState(() => girisModu = !girisModu), child: Text(girisModu ? 'Hesabın yok mu? Kayıt Ol' : 'Zaten hesabın var mı? Giriş Yap'))
            ],
          ),
        ),
      ),
    );
  }
}