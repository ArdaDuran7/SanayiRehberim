import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

// --- 1. KAPICI ---
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasData) return const MagazaListesiEkrani();
        return const GirisKayitEkrani();
      },
    );
  }
}

// --- 2. GİRİŞ VE KAYIT ---
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
    return Scaffold(
      backgroundColor: Colors.blueGrey.shade100,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(Icons.car_repair, size: 80, color: Colors.blueGrey.shade800),
              const SizedBox(height: 10),
              Text(girisModu ? 'Giriş Yap' : 'Hesap Oluştur', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade900)),
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

// --- 3. ANA EKRAN (BUTONSUZ) ---
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

  // --- SİLME FONKSİYONU ---
  void _dukkanSil(String docId, String dukkanIsmi) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Dükkanı Sil"),
        content: Text("$dukkanIsmi kalıcı olarak silinsin mi?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("İptal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              await FirebaseFirestore.instance.collection('magazalar').doc(docId).delete();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Dükkan silindi!"), backgroundColor: Colors.red));
            },
            child: const Text("SİL"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Sanayi Rehberim'), centerTitle: true, backgroundColor: Colors.blueGrey.shade800, foregroundColor: Colors.white),
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
            ListTile(leading: const Icon(Icons.calendar_month), title: const Text('Randevularım'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => const RandevularimEkrani())); }),
            ListTile(leading: const Icon(Icons.settings), title: const Text('Profil Ayarları'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfilAyarlariEkrani())); }),
            const Divider(),
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || !snapshot.data!.exists) return const SizedBox();
                var userData = snapshot.data!.data() as Map<String, dynamic>;
                if (userData['rol'] == 'yonetici') {
                  return ListTile(
                    leading: const Icon(Icons.admin_panel_settings, color: Colors.indigo),
                    title: const Text('Dükkan Sahibi Paneli', style: TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
                    onTap: () {
                      Navigator.pop(context);
                      if (userData['dukkanId'] != null) {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => DukkanYonetimPaneli(dukkanId: userData['dukkanId'])));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Dükkan atanmamış!")));
                      }
                    },
                  );
                }
                return const SizedBox();
              },
            ),
            ListTile(leading: const Icon(Icons.logout, color: Colors.red), title: const Text('Çıkış Yap', style: TextStyle(color: Colors.red)), onTap: () => FirebaseAuth.instance.signOut()),
          ],
        ),
      ),
      // FLOATING ACTION BUTTON BURADAN KALDIRILDI
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.blueGrey.shade800,
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => aramaMetni = value.toLowerCase()),
              decoration: InputDecoration(hintText: 'Ara...', prefixIcon: const Icon(Icons.search), suffixIcon: aramaMetni.isNotEmpty ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchController.clear(); setState(() => aramaMetni = ""); }) : null, filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(vertical: 0)),
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
              stream: secilenKategori == "Tümü" ? FirebaseFirestore.instance.collection('magazalar').snapshots() : FirebaseFirestore.instance.collection('magazalar').where('kategori', isEqualTo: secilenKategori).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text('Hata: ${snapshot.error}'));
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                var filtered = snapshot.data!.docs.where((doc) {
                  return (doc.data() as Map<String, dynamic>)['isim'].toString().toLowerCase().contains(aramaMetni);
                }).toList();

                if (filtered.isEmpty) return const Center(child: Text('Bulunamadı.'));

                return ListView.builder(
                  itemCount: filtered.length,
                  padding: const EdgeInsets.all(10),
                  itemBuilder: (context, index) {
                    var data = filtered[index].data() as Map<String, dynamic>;
                    double puan = (data['puan'] ?? 0).toDouble();
                    String puanYazisi = puan == 0 ? "Yeni" : puan.toStringAsFixed(1);
                    String resimUrl = data['resimUrl'] ?? '';

                    return Card(
                      elevation: 3, margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: Container(
                          width: 60, height: 60,
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.grey.shade200,
                              image: resimUrl.isNotEmpty
                                  ? DecorationImage(image: NetworkImage(resimUrl), fit: BoxFit.cover)
                                  : null
                          ),
                          child: resimUrl.isEmpty ? const Icon(Icons.store, color: Colors.grey) : null,
                        ),
                        title: Text(data['isim'], style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(data['kategori']),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(10)),
                          child: Text("★ $puanYazisi", style: TextStyle(color: Colors.green.shade800, fontWeight: FontWeight.bold)),
                        ),
                        // --- TEK TIKLAMA: DETAY GİT ---
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => DukkanDetayEkrani(docId: filtered[index].id, isim: data['isim'], kategori: data['kategori'], adres: data['adres'], puan: puan, resimUrl: resimUrl))),
                        // --- UZUN BASMA: SİLME İŞLEMİ ---
                        onLongPress: () => _dukkanSil(filtered[index].id, data['isim']),
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

// --- 4. PROFİL AYARLARI ---
class ProfilAyarlariEkrani extends StatefulWidget {
  const ProfilAyarlariEkrani({super.key});
  @override
  State<ProfilAyarlariEkrani> createState() => _ProfilAyarlariEkraniState();
}

class _ProfilAyarlariEkraniState extends State<ProfilAyarlariEkrani> {
  final _adController = TextEditingController();
  final _telController = TextEditingController();
  bool isLoading = false;
  @override
  void initState() { super.initState(); _verileriGetir(); }
  Future<void> _verileriGetir() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) { setState(() { _adController.text = doc.data()?['adSoyad'] ?? ''; _telController.text = doc.data()?['telefon'] ?? ''; }); }
    }
  }
  Future<void> _kaydet() async {
    setState(() => isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({ 'adSoyad': _adController.text.trim(), 'telefon': _telController.text.trim(), 'email': user.email, }, SetOptions(merge: true));
        if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil Güncellendi!'), backgroundColor: Colors.green)); Navigator.pop(context); }
      }
    } catch (e) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e'))); } finally { if (mounted) setState(() => isLoading = false); }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text("Profil Ayarları")),
        body: Padding(padding: const EdgeInsets.all(20), child: Column(children: [ const Icon(Icons.account_circle, size: 100, color: Colors.blueGrey), const SizedBox(height: 20), TextField(controller: _adController, decoration: const InputDecoration(labelText: "Ad Soyad", prefixIcon: Icon(Icons.person))), const SizedBox(height: 15), TextField(controller: _telController, decoration: const InputDecoration(labelText: "Telefon Numarası", prefixIcon: Icon(Icons.phone))), const SizedBox(height: 25), SizedBox(width: double.infinity, height: 50, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey.shade800, foregroundColor: Colors.white), onPressed: isLoading ? null : _kaydet, child: isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("KAYDET"))) ])));
  }
}

// --- 5. DETAY EKRANI ---
class DukkanDetayEkrani extends StatefulWidget {
  final String docId, isim, kategori, adres;
  final String resimUrl;
  final double puan;
  const DukkanDetayEkrani({super.key, required this.docId, required this.isim, required this.kategori, required this.adres, required this.puan, required this.resimUrl});
  @override
  State<DukkanDetayEkrani> createState() => _DukkanDetayEkraniState();
}

class _DukkanDetayEkraniState extends State<DukkanDetayEkrani> {
  DateTime? secilenTarih; TimeOfDay? secilenSaat; bool isSaving = false;
  Future<void> _randevuOlustur() async {
    if (secilenTarih == null || secilenSaat == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tarih/Saat seçiniz!'), backgroundColor: Colors.red)); return; }
    setState(() => isSaving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      String musteriAd = "Belirtilmemiş", musteriTel = "Belirtilmemiş";
      if (user != null) { final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get(); if (userDoc.exists) { musteriAd = userDoc.data()?['adSoyad'] ?? "Belirtilmemiş"; musteriTel = userDoc.data()?['telefon'] ?? "Belirtilmemiş"; } }
      await FirebaseFirestore.instance.collection('randevular').add({ 'dukkanId': widget.docId, 'dukkanIsim': widget.isim, 'userId': user?.uid, 'userEmail': user?.email, 'userAdSoyad': musteriAd, 'userTelefon': musteriTel, 'tarih': secilenTarih.toString().split(' ')[0], 'saat': secilenSaat!.format(context), 'olusturulmaZamani': FieldValue.serverTimestamp(), 'durum': 'bekliyor' });
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Randevu alındı!'), backgroundColor: Colors.green)); Navigator.pop(context); }
    } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e'))); } finally { if (mounted) setState(() => isSaving = false); }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(title: Text(widget.isim), bottom: const TabBar(tabs: [Tab(text: "Bilgiler & Randevu"), Tab(text: "Yorumlar")])),
        body: TabBarView(
          children: [
            SingleChildScrollView(child: Column(children: [
              Container(
                height: 200, width: double.infinity,
                decoration: BoxDecoration(color: Colors.blueGrey.shade200, image: widget.resimUrl.isNotEmpty ? DecorationImage(image: NetworkImage(widget.resimUrl), fit: BoxFit.cover) : null),
                child: widget.resimUrl.isEmpty ? const Icon(Icons.store, size: 80, color: Colors.white) : null,
              ),
              Padding(padding: const EdgeInsets.all(16), child: Column(children: [
                Text(widget.isim, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), Text(widget.adres), const Divider(height: 30),
                const Text("Randevu Al", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), const SizedBox(height: 10),
                Row(children: [ Expanded(child: OutlinedButton(onPressed: () async { final t = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 30))); if(t!=null) setState(()=>secilenTarih=t); }, child: Text(secilenTarih?.toString().split(' ')[0] ?? "Tarih Seç"))), const SizedBox(width: 10), Expanded(child: OutlinedButton(onPressed: () async { final s = await showTimePicker(context: context, initialTime: TimeOfDay.now()); if(s!=null) setState(()=>secilenSaat=s); }, child: Text(secilenSaat?.format(context) ?? "Saat Seç"))) ]),
                const SizedBox(height: 20), SizedBox(width: double.infinity, height: 50, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey.shade900, foregroundColor: Colors.white), onPressed: isSaving ? null : _randevuOlustur, child: isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text("RANDEVUYU ONAYLA")))
              ])),
            ])),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('yorumlar').where('dukkanId', isEqualTo: widget.docId).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("Henüz yorum yapılmamış."));
                return ListView.builder(
                  padding: const EdgeInsets.all(10), itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var yorum = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                    return Card(child: ListTile(leading: CircleAvatar(backgroundColor: Colors.orange.shade100, child: Text(yorum['puan'].toString())), title: Text(yorum['userAdSoyad'] ?? 'Anonim'), subtitle: Text(yorum['yorum'] ?? ''), trailing: const Icon(Icons.star, color: Colors.amber, size: 16)));
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// --- 6. RANDEVULARIM EKRANI ---
class RandevularimEkrani extends StatelessWidget {
  const RandevularimEkrani({super.key});

  void _yorumYapDialog(BuildContext context, String dukkanId, String dukkanIsmi) {
    final yorumController = TextEditingController();
    double puan = 5;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("$dukkanIsmi Değerlendir"),
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text("Hizmetten memnun kaldınız mı?"),
                TextField(controller: yorumController, decoration: const InputDecoration(labelText: "Yorumunuz")),
                const SizedBox(height: 10),
                const Text("Puanınız (1-5):"),
                DropdownButton<double>(value: puan, items: [1,2,3,4,5].map((e) => DropdownMenuItem(value: e.toDouble(), child: Text(e.toString()))).toList(), onChanged: (v) { setState(() { puan = v!; }); })
              ]),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("İptal")),
                ElevatedButton(onPressed: () async {
                  final user = FirebaseAuth.instance.currentUser;
                  if (dukkanId.isEmpty) return;
                  await FirebaseFirestore.instance.collection('yorumlar').add({ 'dukkanId': dukkanId, 'userId': user!.uid, 'userAdSoyad': user.email, 'yorum': yorumController.text, 'puan': puan, 'tarih': FieldValue.serverTimestamp() });
                  try {
                    var yorumlarSnapshot = await FirebaseFirestore.instance.collection('yorumlar').where('dukkanId', isEqualTo: dukkanId).get();
                    if (yorumlarSnapshot.docs.isNotEmpty) {
                      double toplamPuan = 0;
                      for (var doc in yorumlarSnapshot.docs) { toplamPuan += (doc.data()['puan'] as num).toDouble(); }
                      double yeniOrtalama = toplamPuan / yorumlarSnapshot.docs.length;
                      await FirebaseFirestore.instance.collection('magazalar').doc(dukkanId).update({'puan': yeniOrtalama});
                    }
                  } catch (e) { debugPrint("Hata: $e"); }
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Yorumunuz eklendi!")));
                }, child: const Text("GÖNDER"))
              ],
            );
          }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text("Randevularım"), backgroundColor: Colors.blueGrey.shade800, foregroundColor: Colors.white),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('randevular').where('userId', isEqualTo: user?.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return Center(child: Text("Hata: ${snapshot.error}"));
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("Randevu yok."));

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            padding: const EdgeInsets.all(12),
            itemBuilder: (context, index) {
              var belge = snapshot.data!.docs[index];
              var veri = belge.data() as Map<String, dynamic>;
              String dukkanIsmi = veri['dukkanIsim'] ?? 'Bilinmeyen Dükkan'; String tarih = veri['tarih'] ?? '?'; String saat = veri['saat'] ?? '?'; String durum = veri['durum'] ?? 'bekliyor'; String dukkanId = veri['dukkanId'] ?? '';
              Color durumRenk = Colors.orange; if (durum == 'onaylandi') durumRenk = Colors.green; if (durum == 'reddedildi') durumRenk = Colors.red; if (durum == 'tamamlandi') durumRenk = Colors.blueGrey;

              return Card(
                elevation: 3, margin: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    ListTile(leading: Icon(Icons.circle, color: durumRenk), title: Text(dukkanIsmi), subtitle: Text("$tarih - $saat\nDurum: ${durum.toUpperCase()}"), trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => FirebaseFirestore.instance.collection('randevular').doc(belge.id).delete())),
                    if (durum == 'tamamlandi' && dukkanId.isNotEmpty)
                      Padding(padding: const EdgeInsets.only(bottom: 8.0, right: 8.0), child: Align(alignment: Alignment.centerRight, child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black), icon: const Icon(Icons.star), label: const Text("YORUM YAP"), onPressed: () => _yorumYapDialog(context, dukkanId, dukkanIsmi))))
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// --- 7. DÜKKAN YÖNETİM PANELİ ---
class DukkanYonetimPaneli extends StatelessWidget {
  final String dukkanId;

  const DukkanYonetimPaneli({super.key, required this.dukkanId});

  void _durumGuncelle(String docId, String yeniDurum) {
    FirebaseFirestore.instance.collection('randevular').doc(docId).update({'durum': yeniDurum});
  }

  void _dukkanDuzenleDialog(BuildContext context, String mevcutIsim, String mevcutAdres, String mevcutKategori, String mevcutResimUrl) {
    final isimController = TextEditingController(text: mevcutIsim);
    final adresController = TextEditingController(text: mevcutAdres);
    final resimController = TextEditingController(text: mevcutResimUrl);
    String kategori = mevcutKategori;
    final List<String> kategoriler = ["Kaporta", "Motor", "Elektrik", "Lastik & Jant", "Yedek Parça", "Boya", "Döşeme"];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Dükkan Bilgilerini Düzenle"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: isimController, decoration: const InputDecoration(labelText: "Dükkan İsmi")),
                    const SizedBox(height: 10),
                    TextField(controller: adresController, decoration: const InputDecoration(labelText: "Adres")),
                    const SizedBox(height: 10),
                    TextField(controller: resimController, decoration: const InputDecoration(labelText: "Resim Linki (URL)", hintText: "https://...")),
                    const SizedBox(height: 10),
                    const Text("Kategori:"),
                    DropdownButton<String>(
                        value: kategoriler.contains(kategori) ? kategori : kategoriler[0],
                        isExpanded: true,
                        items: kategoriler.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        onChanged: (v) { setState(() { kategori = v!; }); }
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("İptal")),
                ElevatedButton(onPressed: () async {
                  await FirebaseFirestore.instance.collection('magazalar').doc(dukkanId).update({
                    'isim': isimController.text.trim(),
                    'adres': adresController.text.trim(),
                    'resimUrl': resimController.text.trim(),
                    'kategori': kategori
                  });
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bilgiler güncellendi!")));
                }, child: const Text("KAYDET"))
              ],
            );
          }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('magazalar').doc(dukkanId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator()));

          var dukkanVerisi = snapshot.data!.data() as Map<String, dynamic>;
          String dukkanIsmi = dukkanVerisi['isim'] ?? 'Dükkanım';
          String dukkanAdres = dukkanVerisi['adres'] ?? '';
          String dukkanKategori = dukkanVerisi['kategori'] ?? 'Genel';
          String resimUrl = dukkanVerisi['resimUrl'] ?? '';

          return Scaffold(
            appBar: AppBar(
              title: Text("$dukkanIsmi Paneli"),
              backgroundColor: Colors.indigo,
              foregroundColor: Colors.white,
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: "Dükkanı Düzenle",
                  onPressed: () => _dukkanDuzenleDialog(context, dukkanIsmi, dukkanAdres, dukkanKategori, resimUrl),
                )
              ],
            ),
            body: Column(
              children: [
                Container(padding: const EdgeInsets.all(15), color: Colors.indigo.shade50, width: double.infinity, child: const Text("Randevu İşlemleri", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo), textAlign: TextAlign.center)),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('randevular').where('dukkanId', isEqualTo: dukkanId).snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("Randevu yok."));
                      return ListView.builder(
                        padding: const EdgeInsets.all(10), itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          var doc = snapshot.data!.docs[index];
                          var veri = doc.data() as Map<String, dynamic>;
                          String durum = veri['durum'] ?? 'bekliyor';
                          return Card(
                            child: Padding(padding: const EdgeInsets.all(12.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text("${veri['userAdSoyad']} - ${veri['userTelefon']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Text("${veri['tarih']} Saat: ${veri['saat']}"),
                              Text("Şu anki durum: $durum", style: const TextStyle(color: Colors.grey)), const Divider(),
                              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                                if (durum == 'bekliyor') ...[ ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.green), onPressed: () => _durumGuncelle(doc.id, 'onaylandi'), child: const Text("ONAYLA", style: TextStyle(color: Colors.white))), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () => _durumGuncelle(doc.id, 'reddedildi'), child: const Text("REDDET", style: TextStyle(color: Colors.white))), ],
                                if (durum == 'onaylandi') ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey), onPressed: () => _durumGuncelle(doc.id, 'tamamlandi'), icon: const Icon(Icons.check_circle, color: Colors.white), label: const Text("İŞİ TAMAMLA", style: TextStyle(color: Colors.white))),
                                if (durum == 'tamamlandi') const Text("✅ İŞLEM BİTTİ", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                if (durum == 'reddedildi') const Text("❌ REDDEDİLDİ", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                              ],
                              )
                            ],
                            ),
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
    );
  }
}