import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart' as g_sign; // Hataları önleyen takma isim
import 'uygulama_ici.dart';

// --- 1. KAPICI (AUTH GATE & MODERN SPLASH) ---
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _splashGosteriliyor = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _splashGosteriliyor = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_splashGosteriliyor) {
      return Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0F172A), Color(0xFF334155)],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, spreadRadius: 5)],
                ),
                child: const Icon(Icons.car_repair, size: 80, color: Color(0xFF0F172A)),
              ),
              const SizedBox(height: 40),
              const Text(
                "SANAYİ REHBERİM",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2.5, shadows: [Shadow(blurRadius: 10, color: Colors.black45, offset: Offset(2, 2))]),
              ),
              const SizedBox(height: 10),
              Text("Aradığın Usta Cebinde", style: TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.7), fontStyle: FontStyle.italic)),
              const SizedBox(height: 60),
              const CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
            ],
          ),
        ),
      );
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasData) return const MagazaListesiEkrani();
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
  bool _sifreGozuksunMu = false;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _adController = TextEditingController();
  final _telController = TextEditingController();
  bool isLoading = false;

  // --- SOSYAL KULLANICIYI VERİTABANINA KAYDET ---
  Future<void> _sosyalKullaniciyiVeritabaninaKaydet(User user) async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (!userDoc.exists) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'email': user.email ?? "",
        'rol': 'musteri',
        'adSoyad': user.displayName ?? "İsimsiz Kullanıcı",
        'telefon': user.phoneNumber ?? "",
        'favoriler': [],
        'profilResmi': user.photoURL,
      });
    }
  }

  // --- GOOGLE İLE GİRİŞ YAP ---
  Future<void> _googleIleGirisYap() async {
    setState(() => isLoading = true);
    try {
      final g_sign.GoogleSignIn googleSignIn = g_sign.GoogleSignIn();
      final g_sign.GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        setState(() => isLoading = false);
        return;
      }

      final g_sign.GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

      if (userCredential.user != null) {
        await _sosyalKullaniciyiVeritabaninaKaydet(userCredential.user!);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Google Giriş Hatası: $e")));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  // --- NORMAL E-POSTA İŞLEMLERİ ---
  Future<void> _islemYap() async {
    FocusScope.of(context).unfocus();

    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen E-Posta ve Şifre giriniz."), backgroundColor: Colors.orange));
      return;
    }

    if (!girisModu) {
      if (_adController.text.isEmpty || _telController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen Ad Soyad ve Telefon bilgilerini giriniz."), backgroundColor: Colors.orange));
        return;
      }
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Şifreler uyuşmuyor! Lütfen kontrol edin."), backgroundColor: Colors.red));
        return;
      }
    }

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
          'adSoyad': _adController.text.trim(),
          'telefon': _telController.text.trim(),
          'favoriler': [],
          'profilResmi': null,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kayıt Başarılı!"), backgroundColor: Colors.green));
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? "Hata oluştu"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _sifreSifirla() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen önce E-Posta adresinizi yazın!")));
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: _emailController.text.trim());
      if (mounted) {
        showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text("Gönderildi"), content: const Text("Şifre sıfırlama linki e-postanıza gönderildi.")));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Hata oluştu")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                width: 120, height: 120,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
                child: Icon(Icons.car_repair, size: 80, color: primaryColor),
              ),
              const SizedBox(height: 30),
              Text(girisModu ? 'Giriş Yap' : 'Hesap Oluştur', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: primaryColor)),
              const SizedBox(height: 30),

              if (!girisModu) ...[
                TextField(controller: _adController, decoration: const InputDecoration(labelText: 'Ad Soyad', prefixIcon: Icon(Icons.person))),
                const SizedBox(height: 15),
              ],
              TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'E-Posta', prefixIcon: Icon(Icons.email))),
              const SizedBox(height: 15),
              if (!girisModu) ...[
                TextField(controller: _telController, decoration: const InputDecoration(labelText: 'Telefon Numarası', prefixIcon: Icon(Icons.phone))),
                const SizedBox(height: 15),
              ],
              TextField(
                  controller: _passwordController,
                  obscureText: !_sifreGozuksunMu,
                  decoration: InputDecoration(
                      labelText: 'Şifre',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(icon: Icon(_sifreGozuksunMu ? Icons.visibility : Icons.visibility_off), onPressed: () => setState(() => _sifreGozuksunMu = !_sifreGozuksunMu))
                  )
              ),
              if (!girisModu) ...[
                const SizedBox(height: 15),
                TextField(controller: _confirmPasswordController, obscureText: !_sifreGozuksunMu, decoration: const InputDecoration(labelText: 'Şifre Tekrar', prefixIcon: Icon(Icons.lock_outline))),
              ],
              if (girisModu) Align(alignment: Alignment.centerRight, child: TextButton(onPressed: _sifreSifirla, child: const Text("Şifremi Unuttum?"))),
              const SizedBox(height: 25),

              SizedBox(width: double.infinity, height: 55, child: ElevatedButton(onPressed: isLoading ? null : _islemYap, child: isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(girisModu ? 'GİRİŞ YAP' : 'KAYIT OL'))),

              const SizedBox(height: 20),

              // --- GOOGLE BUTONU VE AYIRICI ---
              if (girisModu) ...[
                const Row(children: [Expanded(child: Divider()), Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text("VEYA")), Expanded(child: Divider())]),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.g_mobiledata, color: Colors.red, size: 36),
                    label: const Text("Google ile Devam Et", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
                    onPressed: isLoading ? null : _googleIleGirisYap,
                  ),
                ),
                const SizedBox(height: 20),
              ],

              TextButton(onPressed: () => setState(() => girisModu = !girisModu), child: Text(girisModu ? 'Hesabın yok mu? Kayıt Ol' : 'Zaten hesabın var mı? Giriş Yap'))
            ],
          ),
        ),
      ),
    );
  }
}