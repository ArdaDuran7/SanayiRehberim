import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- 1. UYGULAMA BAŞLANGICI ---
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
      home: const AuthGate(),
    );
  }
}

// --- 2. KAPICI (GİRİŞ KONTROLÜ) ---
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return const MagazaListesiEkrani();
        }
        return const GirisKayitEkrani();
      },
    );
  }
}

// --- 3. GİRİŞ VE KAYIT EKRANI ---
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
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? "Hata"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => isLoading = false);
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
              Text(girisModu ? 'Giriş Yap' : 'Hesap Oluştur', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade900)),
              const SizedBox(height: 30),
              TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'E-Posta', prefixIcon: Icon(Icons.email)), keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 15),
              TextField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Şifre', prefixIcon: Icon(Icons.lock)), obscureText: true),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey.shade800, foregroundColor: Colors.white),
                  onPressed: isLoading ? null : _islemYap,
                  child: isLoading ? const CircularProgressIndicator(color: Colors.white) : Text(girisModu ? 'GİRİŞ YAP' : 'KAYIT OL', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () => setState(() => girisModu = !girisModu),
                child: Text(girisModu ? 'Hesabın yok mu? Kayıt Ol' : 'Zaten hesabın var mı? Giriş Yap'),
              )
            ],
          ),
        ),
      ),
    );
  }
}

// --- 4. ANA EKRAN (LİSTELEME) ---
class MagazaListesiEkrani extends StatefulWidget {
  const MagazaListesiEkrani({super.key});

  @override
  State<MagazaListesiEkrani> createState() => _MagazaListesiEkraniState();
}

class _MagazaListesiEkraniState extends State<MagazaListesiEkrani> {
  String secilenKategori = "Tümü";
  String aramaMetni = "";
  final TextEditingController _searchController = TextEditingController();
  final List<String> kategoriler = ["Tümü", "Kaporta", "Motor", "Elektrik", "Lastik & Jant", "Yedek Parça", "Boya", "Döşeme"];

  Future<void> _demoVeriEkle() async {
    final firestore = FirebaseFirestore.instance;
    List<Map<String, dynamic>> ornekDukkanlar = [
      {'isim': 'Yılmaz Oto Elektrik', 'kategori': 'Elektrik', 'adres': 'A Blok No:12', 'puan': 4.5},
      {'isim': 'Şahin Motor Yenileme', 'kategori': 'Motor', 'adres': 'C Blok No:45', 'puan': 4.8},
      {'isim': 'Demir Kaporta Boya', 'kategori': 'Kaporta', 'adres': 'B Blok No:22', 'puan': 3.9},
      {'isim': 'Can Oto Boya', 'kategori': 'Boya', 'adres': 'F Blok No:5', 'puan': 4.7},
    ];
    for (var dukkan in ornekDukkanlar) {
      await firestore.collection('magazalar').add(dukkan);
    }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Demo Veriler Eklendi!'), backgroundColor: Colors.green));
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Sanayi Rehberim'), centerTitle: true, backgroundColor: Colors.blueGrey.shade800, foregroundColor: Colors.white),

      // --- YAN MENÜ (GÜNCELLENDİ) ---
      drawer: Drawer(
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: Colors.blueGrey.shade700),
              accountName: const Text("Hoşgeldiniz", style: TextStyle(fontWeight: FontWeight.bold)),
              accountEmail: Text(user?.email ?? "Misafir"),
              currentAccountPicture: const CircleAvatar(backgroundColor: Colors.white, child: Icon(Icons.person, size: 40, color: Colors.blueGrey)),
            ),
            ListTile(leading: const Icon(Icons.home), title: const Text('Ana Sayfa'), onTap: () => Navigator.pop(context)),

            // --- RANDEVULARIM BUTONU (YENİ EKRANA GİDER) ---
            ListTile(
              leading: const Icon(Icons.calendar_month),
              title: const Text('Randevularım'),
              onTap: () {
                Navigator.pop(context); // Menüyü kapat
                Navigator.push(context, MaterialPageRoute(builder: (context) => const RandevularimEkrani())); // Yeni sayfaya git
              },
            ),

            const Divider(),
            ListTile(leading: const Icon(Icons.logout, color: Colors.red), title: const Text('Çıkış Yap', style: TextStyle(color: Colors.red)), onTap: () => FirebaseAuth.instance.signOut()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.small(onPressed: _demoVeriEkle, backgroundColor: Colors.orange, child: const Icon(Icons.add)),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.blueGrey.shade800,
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => aramaMetni = value.toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Ara...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: aramaMetni.isNotEmpty ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchController.clear(); setState(() => aramaMetni = ""); }) : null,
                filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          Container(
            height: 60, padding: const EdgeInsets.symmetric(vertical: 10), color: Colors.grey[100],
            child: ListView.builder(
              scrollDirection: Axis.horizontal, itemCount: kategoriler.length, itemBuilder: (context, index) {
              final k = kategoriler[index];
              return Padding(padding: const EdgeInsets.symmetric(horizontal: 5), child: ChoiceChip(label: Text(k), selected: secilenKategori == k, onSelected: (s) => setState(() => secilenKategori = k)));
            },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: secilenKategori == "Tümü"
                  ? FirebaseFirestore.instance.collection('magazalar').snapshots()
                  : FirebaseFirestore.instance.collection('magazalar').where('kategori', isEqualTo: secilenKategori).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text('Hata: ${snapshot.error}'));
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                var docs = snapshot.data!.docs;
                var filtered = docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  return (data['isim'] ?? '').toString().toLowerCase().contains(aramaMetni);
                }).toList();

                if (filtered.isEmpty) return const Center(child: Text('Bulunamadı.'));

                return ListView.builder(
                  itemCount: filtered.length, padding: const EdgeInsets.all(10),
                  itemBuilder: (context, index) {
                    var data = filtered[index].data() as Map<String, dynamic>;
                    return Card(
                      elevation: 3, margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(child: Text(data['isim'][0])),
                        title: Text(data['isim']), subtitle: Text(data['kategori']),
                        trailing: Text("★ ${data['puan']}"),
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => DukkanDetayEkrani(docId: filtered[index].id, isim: data['isim'], kategori: data['kategori'], adres: data['adres'], puan: (data['puan'] ?? 0).toDouble()))),
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

// --- 5. DETAY EKRANI ---
class DukkanDetayEkrani extends StatefulWidget {
  final String docId, isim, kategori, adres;
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tarih/Saat seçiniz!'), backgroundColor: Colors.red));
      return;
    }
    setState(() => isSaving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('randevular').add({
        'dukkanId': widget.docId, 'dukkanIsim': widget.isim, 'userId': user?.uid, 'userEmail': user?.email,
        'tarih': secilenTarih.toString().split(' ')[0], 'saat': secilenSaat!.format(context), 'olusturulmaZamani': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Randevu alındı!'), backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
    } finally {
      if(mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.isim)),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Icon(Icons.store, size: 80, color: Colors.blueGrey), const SizedBox(height: 20),
              Text(widget.isim, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              Text(widget.adres), const Divider(height: 30),
              Row(children: [
                Expanded(child: OutlinedButton(onPressed: () async {
                  final t = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 30)));
                  if(t!=null) setState(()=>secilenTarih=t);
                }, child: Text(secilenTarih?.toString().split(' ')[0] ?? "Tarih Seç"))),
                const SizedBox(width: 10),
                Expanded(child: OutlinedButton(onPressed: () async {
                  final s = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                  if(s!=null) setState(()=>secilenSaat=s);
                }, child: Text(secilenSaat?.format(context) ?? "Saat Seç"))),
              ]),
              const SizedBox(height: 20),
              SizedBox(width: double.infinity, height: 50, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey.shade900, foregroundColor: Colors.white), onPressed: isSaving ? null : _randevuOlustur, child: isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text("RANDEVUYU ONAYLA"))),
            ],
          ),
        ),
      ),
    );
  }
}

// --- 6. YENİ EKLENEN: RANDEVULARIM EKRANI ---
class RandevularimEkrani extends StatelessWidget {
  const RandevularimEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Randevularım"),
        backgroundColor: Colors.blueGrey.shade800,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // SADECE GİRİŞ YAPAN KULLANICININ RANDEVULARINI GETİR
        stream: FirebaseFirestore.instance
            .collection('randevular')
            .where('userId', isEqualTo: user?.uid) // <-- Filtre burada!
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Text("Bir hata oluştu"));
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

          final randevular = snapshot.data!.docs;

          if (randevular.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today_outlined, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 20),
                  const Text("Henüz randevunuz yok.", style: TextStyle(color: Colors.grey, fontSize: 16)),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: randevular.length,
            padding: const EdgeInsets.all(12),
            itemBuilder: (context, index) {
              var veri = randevular[index].data() as Map<String, dynamic>;
              var docId = randevular[index].id;

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: CircleAvatar(
                    backgroundColor: Colors.orange.shade100,
                    child: const Icon(Icons.access_time, color: Colors.orange),
                  ),
                  title: Text(veri['dukkanIsim'] ?? 'Bilinmeyen Dükkan', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 5),
                      Row(children: [const Icon(Icons.calendar_today, size: 14), const SizedBox(width: 5), Text(veri['tarih'] ?? '?')]),
                      Row(children: [const Icon(Icons.schedule, size: 14), const SizedBox(width: 5), Text(veri['saat'] ?? '?')]),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () {
                      // Randevuyu Silme İşlemi
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text("İptal Et"),
                          content: const Text("Bu randevuyu iptal etmek istediğine emin misin?"),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Hayır")),
                            TextButton(
                              onPressed: () {
                                FirebaseFirestore.instance.collection('randevular').doc(docId).delete();
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Randevu iptal edildi.")));
                              },
                              child: const Text("Evet, İptal Et", style: TextStyle(color: Colors.red)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}