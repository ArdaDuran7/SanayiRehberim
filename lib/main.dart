import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Yeni eklediğimiz paket

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const SanayiRehberimApp());
}

class SanayiRehberimApp extends StatelessWidget {
  const SanayiRehberimApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sanayi Rehberim',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        scaffoldBackgroundColor: Colors.grey[100],
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
      // AuthGate: Kullanıcı içeride mi değil mi kontrol eden kapı
      home: const AuthGate(),
    );
  }
}

// --- 1. KAPICI (AUTH GATE) ---
// Bu widget, kullanıcının durumuna göre sayfayı yönlendirir.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Eğer kullanıcı giriş yapmışsa (data varsa) -> Ana Sayfaya git
        if (snapshot.hasData) {
          return const MagazaListesiEkrani();
        }
        // Giriş yapmamışsa -> Giriş Ekranına git
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
  bool girisModu = true; // True ise Giriş, False ise Kayıt ekranı
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool isLoading = false;

  // Giriş veya Kayıt İşlemi
  Future<void> _islemYap() async {
    setState(() => isLoading = true);
    try {
      if (girisModu) {
        // GİRİŞ YAP
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      } else {
        // KAYIT OL
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        // İsteğe bağlı: Kayıt olan kullanıcıyı Firestore'a da ekleyebiliriz (şimdilik gerek yok)
      }
      // Hata yoksa AuthGate otomatik olarak ana sayfaya yönlendirecek
    } on FirebaseAuthException catch (e) {
      String mesaj = 'Bir hata oluştu';
      if (e.code == 'user-not-found') mesaj = 'Böyle bir kullanıcı bulunamadı.';
      if (e.code == 'wrong-password') mesaj = 'Şifre hatalı.';
      if (e.code == 'email-already-in-use') mesaj = 'Bu e-posta zaten kayıtlı.';
      if (e.code == 'weak-password') mesaj = 'Şifre çok zayıf (en az 6 karakter).';

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mesaj), backgroundColor: Colors.red));
    } finally {
      if(mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey.shade100,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.car_repair, size: 80, color: Colors.blueGrey.shade800),
              const SizedBox(height: 10),
              Text(
                girisModu ? 'Giriş Yap' : 'Hesap Oluştur',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade900),
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'E-Posta', prefixIcon: Icon(Icons.email)),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Şifre', prefixIcon: Icon(Icons.lock)),
                obscureText: true,
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey.shade800, foregroundColor: Colors.white),
                  onPressed: isLoading ? null : _islemYap,
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(girisModu ? 'GİRİŞ YAP' : 'KAYIT OL', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  setState(() {
                    girisModu = !girisModu; // Modu değiştir
                  });
                },
                child: Text(girisModu ? 'Hesabın yok mu? Kayıt Ol' : 'Zaten hesabın var mı? Giriş Yap'),
              )
            ],
          ),
        ),
      ),
    );
  }
}

// --- 3. ANA EKRAN (KATEGORİ FİLTRELİ) ---
class MagazaListesiEkrani extends StatefulWidget {
  const MagazaListesiEkrani({super.key});

  @override
  State<MagazaListesiEkrani> createState() => _MagazaListesiEkraniState();
}

class _MagazaListesiEkraniState extends State<MagazaListesiEkrani> {
  // Seçilen kategoriyi tutan değişken (Başlangıçta hepsi)
  String secilenKategori = "Tümü";

  // Sabit kategori listemiz (Bunları buton yapacağız)
  final List<String> kategoriler = [
    "Tümü",
    "Kaporta",
    "Motor",
    "Elektrik",
    "Lastik & Jant",
    "Yedek Parça",
    "Boya",
    "Döşeme"
  ];

  // Demo veri ekleme fonksiyonu (Kategorilere uygun veriler)
  Future<void> _demoVeriEkle() async {
    final firestore = FirebaseFirestore.instance;
    List<Map<String, dynamic>> ornekDukkanlar = [
      {'isim': 'Yılmaz Oto Elektrik', 'kategori': 'Elektrik', 'adres': 'A Blok No:12', 'puan': 4.5},
      {'isim': 'Şahin Motor Yenileme', 'kategori': 'Motor', 'adres': 'C Blok No:45', 'puan': 4.8},
      {'isim': 'Demir Kaporta Boya', 'kategori': 'Kaporta', 'adres': 'B Blok No:22', 'puan': 3.9},
      {'isim': 'Antalya Yedek Parça', 'kategori': 'Yedek Parça', 'adres': 'Giriş Kat No:1', 'puan': 5.0},
      {'isim': 'Usta Rot Balans', 'kategori': 'Lastik & Jant', 'adres': 'D Blok No:8', 'puan': 4.2},
      {'isim': 'Can Oto Boya', 'kategori': 'Boya', 'adres': 'F Blok No:5', 'puan': 4.7},
      {'isim': 'Lüks Döşeme', 'kategori': 'Döşeme', 'adres': 'A Blok No:3', 'puan': 4.1},
    ];

    for (var dukkan in ornekDukkanlar) {
      await firestore.collection('magazalar').add(dukkan);
    }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kategorili Demo Veriler Eklendi!'), backgroundColor: Colors.green));
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sanayi Rehberim'),
        centerTitle: true,
        backgroundColor: Colors.blueGrey.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          )
        ],
      ),
      // Sağ alttaki buton (Veri yüklemek için)
      floatingActionButton: FloatingActionButton.small(
        onPressed: _demoVeriEkle,
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // 1. KULLANICI BİLGİSİ
          Container(
            width: double.infinity,
            color: Colors.amber.shade100,
            padding: const EdgeInsets.all(8),
            child: Text("Hoşgeldin: ${user?.email ?? 'Misafir'}", textAlign: TextAlign.center, style: TextStyle(color: Colors.blueGrey.shade900)),
          ),

          // 2. YATAY KATEGORİ LİSTESİ
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: ListView.builder(
              scrollDirection: Axis.horizontal, // Yana doğru kaydırma
              itemCount: kategoriler.length,
              itemBuilder: (context, index) {
                final kategori = kategoriler[index];
                final seciliMi = secilenKategori == kategori;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  child: ChoiceChip(
                    label: Text(kategori),
                    selected: seciliMi,
                    selectedColor: Colors.blueGrey.shade800,
                    labelStyle: TextStyle(color: seciliMi ? Colors.white : Colors.black),
                    onSelected: (bool selected) {
                      setState(() {
                        secilenKategori = kategori; // Seçilen kategoriyi güncelle
                      });
                    },
                  ),
                );
              },
            ),
          ),

          // 3. FİLTRELENMİŞ DÜKKAN LİSTESİ
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              // SORGUSU: Eğer 'Tümü' ise hepsini getir, değilse sadece seçilen kategoriyi getir.
              stream: secilenKategori == "Tümü"
                  ? FirebaseFirestore.instance.collection('magazalar').snapshots()
                  : FirebaseFirestore.instance.collection('magazalar').where('kategori', isEqualTo: secilenKategori).snapshots(),

              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text('Hata: ${snapshot.error}'));
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 60, color: Colors.grey.shade400),
                        const SizedBox(height: 10),
                        Text('Bu kategoride dükkan bulunamadı.', style: TextStyle(color: Colors.grey.shade600)),
                      ],
                    ),
                  );
                }

                final dukkanlar = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: dukkanlar.length,
                  padding: const EdgeInsets.all(10),
                  itemBuilder: (context, index) {
                    var veri = dukkanlar[index].data() as Map<String, dynamic>;
                    String docId = dukkanlar[index].id;
                    String isim = veri['isim'] ?? 'İsimsiz';
                    String kategori = veri['kategori'] ?? 'Genel';
                    String adres = veri['adres'] ?? '-';
                    double puan = (veri['puan'] ?? 0).toDouble();

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blueGrey.shade100,
                          // Kategoriye göre farklı ikon göstermek istersen burayı geliştirebiliriz
                          child: const Icon(Icons.store, color: Colors.black54),
                        ),
                        title: Text(isim, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(kategori),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(10)),
                          child: Text("★ $puan", style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold)),
                        ),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => DukkanDetayEkrani(docId: docId, isim: isim, kategori: kategori, adres: adres, puan: puan)));
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// --- 4. DETAY EKRANI (RANDEVU KAYDEDERKEN USER ID EKLENDİ) ---
class DukkanDetayEkrani extends StatefulWidget {
  final String docId;
  final String isim, kategori, adres;
  final double puan;

  const DukkanDetayEkrani({super.key, required this.docId, required this.isim, required this.kategori, required this.adres, required this.puan});

  @override
  State<DukkanDetayEkrani> createState() => _DukkanDetayEkraniState();
}

class _DukkanDetayEkraniState extends State<DukkanDetayEkrani> {
  DateTime? secilenTarih;
  TimeOfDay? secilenSaat;
  bool isSaving = false;

  Future<void> _randevuOlustur() async {
    if (secilenTarih == null || secilenSaat == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen tarih ve saat seçiniz!'), backgroundColor: Colors.red));
      return;
    }

    setState(() => isSaving = true);

    try {
      // AKTİF KULLANICININ ID'SİNİ ALIYORUZ
      final user = FirebaseAuth.instance.currentUser;

      await FirebaseFirestore.instance.collection('randevular').add({
        'dukkanId': widget.docId,
        'dukkanIsim': widget.isim,
        'userId': user?.uid, // <-- ARTIK KİMİN RANDEVU ALDIĞINI BİLİYORUZ!
        'userEmail': user?.email, // <-- Dükkan sahibi iletişime geçebilsin diye
        'tarih': secilenTarih.toString().split(' ')[0],
        'saat': secilenSaat!.format(context),
        'olusturulmaZamani': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Randevunuz alındı!'), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
    } finally {
      if(mounted) setState(() => isSaving = false);
    }
  }

  // --- (Tarih ve Saat seçiciler burada aynı kalıyor, yer kaplamasın diye kısalttım, kodun çalışması için önceki tarihSec fonksiyonlarını buraya ekleyebilirsin veya UI aynı) ---
  // Not: Tam kopyala yapıştır yapman için aşağıya tarih seçicileri de ekliyorum.

  Future<void> _tarihSec(BuildContext context) async {
    final DateTime? picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 30)));
    if (picked != null) setState(() => secilenTarih = picked);
  }

  Future<void> _saatSec(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null) setState(() => secilenSaat = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.isim)),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Container(height: 150, color: Colors.blueGrey.shade200, child: const Center(child: Icon(Icons.store, size: 80, color: Colors.white))),
              const SizedBox(height: 20),
              Text(widget.isim, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              Text(widget.adres),
              const Divider(height: 30),
              Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: () => _tarihSec(context), child: Text(secilenTarih == null ? "Tarih" : secilenTarih.toString().split(' ')[0]))),
                  const SizedBox(width: 10),
                  Expanded(child: OutlinedButton(onPressed: () => _saatSec(context), child: Text(secilenSaat == null ? "Saat" : secilenSaat!.format(context)))),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey.shade900, foregroundColor: Colors.white),
                  onPressed: isSaving ? null : _randevuOlustur,
                  child: isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text("RANDEVUYU ONAYLA"),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}