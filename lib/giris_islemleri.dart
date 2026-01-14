import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
    // 3 Saniye bekleme süresi
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
    // --- MODERN AÇILIŞ EKRANI TASARIMI ---
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

    // Normal Akış
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

  Future<void> _islemYap() async {
    FocusScope.of(context).unfocus();

    // 1. Boş Alan Kontrolü
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen E-Posta ve Şifre giriniz."), backgroundColor: Colors.orange));
      return;
    }

    // 2. Kayıt Modu Kontrolleri
    if (!girisModu) {
      if (_adController.text.isEmpty || _telController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen Ad Soyad ve Telefon bilgilerini giriniz."), backgroundColor: Colors.orange));
        return;
      }
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Şifreler uyuşmuyor! Lütfen kontrol edin."), backgroundColor: Colors.red));
        return;
      }
      if (_passwordController.text.length < 6) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Şifre en az 6 karakter olmalıdır."), backgroundColor: Colors.orange));
        return;
      }
    }

    setState(() => isLoading = true);
    try {
      if (girisModu) {
        // --- GİRİŞ YAP ---
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        // --- KAYIT OL ---
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

        // --- İŞTE EKLENEN KISIM: KAYIT BAŞARILI MESAJI ---
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Hesabınız başarıyla oluşturuldu! Giriş yapılıyor..."),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
        // ------------------------------------------------
      }
    } on FirebaseAuthException catch (e) {
      // --- ÖZEL HATA MESAJLARI (TÜRKÇE) ---
      String mesaj = "Bir hata oluştu. Lütfen tekrar deneyin.";

      switch (e.code) {
        case 'user-not-found':
          mesaj = "Böyle bir kullanıcı bulunamadı! Lütfen kayıt olun.";
          break;
        case 'wrong-password':
          mesaj = "Girdiğiniz şifre hatalı! Lütfen tekrar deneyin.";
          break;
        case 'invalid-email':
          mesaj = "Lütfen geçerli bir e-posta adresi girin.";
          break;
        case 'user-disabled':
          mesaj = "Bu hesap erişime kapatılmış.";
          break;
        case 'email-already-in-use':
          mesaj = "Bu e-posta adresi zaten kullanımda. Giriş yapmayı deneyin.";
          break;
        case 'weak-password':
          mesaj = "Belirlediğiniz şifre çok zayıf.";
          break;
        case 'invalid-credential':
          mesaj = "E-posta veya şifre hatalı.";
          break;
        case 'network-request-failed':
          mesaj = "İnternet bağlantınızı kontrol edin.";
          break;
        default:
          mesaj = "Hata: ${e.message}";
      }

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mesaj), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _sifreSifirla() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen önce E-Posta adresinizi yazın!"), backgroundColor: Colors.orange));
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: _emailController.text.trim());
      if (mounted) {
        showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text("E-Posta Gönderildi"), content: const Text("Şifre sıfırlama bağlantısı e-posta adresinize gönderildi."), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("TAMAM"))]));
      }
    } on FirebaseAuthException catch (e) {
      String mesaj = "Hata oluştu.";
      if (e.code == 'user-not-found') mesaj = "Bu e-posta ile kayıtlı kullanıcı bulunamadı.";
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mesaj), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // LOGO
              Container(
                width: 120, height: 120,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))]
                ),
                child: Icon(Icons.car_repair, size: 80, color: primaryColor),
              ),

              const SizedBox(height: 30),
              Text(girisModu ? 'Giriş Yap' : 'Hesap Oluştur', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: primaryColor)),
              const SizedBox(height: 30),

              if (!girisModu) ...[
                TextField(controller: _adController, decoration: const InputDecoration(labelText: 'Ad Soyad', prefixIcon: Icon(Icons.person)), textCapitalization: TextCapitalization.words),
                const SizedBox(height: 15),
              ],

              TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'E-Posta', prefixIcon: Icon(Icons.email)), keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 15),

              if (!girisModu) ...[
                TextField(controller: _telController, decoration: const InputDecoration(labelText: 'Telefon Numarası', prefixIcon: Icon(Icons.phone)), keyboardType: TextInputType.phone),
                const SizedBox(height: 15),
              ],

              // --- ŞİFRE ALANI ---
              TextField(
                  controller: _passwordController,
                  obscureText: !_sifreGozuksunMu,
                  decoration: InputDecoration(
                      labelText: 'Şifre',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(icon: Icon(_sifreGozuksunMu ? Icons.visibility : Icons.visibility_off, color: Colors.grey), onPressed: () { setState(() { _sifreGozuksunMu = !_sifreGozuksunMu; }); })
                  )
              ),

              // --- ŞİFRE TEKRAR ALANI (SADECE KAYITTA) ---
              if (!girisModu) ...[
                const SizedBox(height: 15),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: !_sifreGozuksunMu,
                  decoration: const InputDecoration(
                    labelText: 'Şifre Tekrar',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
              ],

              if (girisModu) Align(alignment: Alignment.centerRight, child: TextButton(onPressed: _sifreSifirla, child: Text("Şifremi Unuttum?", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)))),

              if (!girisModu) const SizedBox(height: 25),

              SizedBox(width: double.infinity, height: 55, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: primaryColor, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 5), onPressed: isLoading ? null : _islemYap, child: isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(girisModu ? 'GİRİŞ YAP' : 'KAYIT OL', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)))),

              const SizedBox(height: 20),
              TextButton(onPressed: () { setState(() { girisModu = !girisModu; }); }, child: Text(girisModu ? 'Hesabın yok mu? Kayıt Ol' : 'Zaten hesabın var mı? Giriş Yap', style: TextStyle(color: primaryColor)))
            ],
          ),
        ),
      ),
    );
  }
}