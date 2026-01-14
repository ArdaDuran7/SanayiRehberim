import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

// --- 1. FAVORİ BUTONU ---
class FavoriButonu extends StatelessWidget {
  final String dukkanId;
  const FavoriButonu({super.key, required this.dukkanId});
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) return const Icon(Icons.favorite_border, color: Colors.grey);
        var userData = snapshot.data!.data() as Map<String, dynamic>;
        List favoriler = userData['favoriler'] ?? [];
        bool isFav = favoriler.contains(dukkanId);
        return IconButton(
          icon: Icon(isFav ? Icons.favorite : Icons.favorite_border, color: isFav ? Colors.red : Colors.grey),
          onPressed: () async {
            if (isFav) {
              await FirebaseFirestore.instance.collection('users').doc(user?.uid).update({'favoriler': FieldValue.arrayRemove([dukkanId])});
              if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Favorilerden çıkarıldı.")));
            } else {
              await FirebaseFirestore.instance.collection('users').doc(user?.uid).update({'favoriler': FieldValue.arrayUnion([dukkanId])});
              if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Favorilere eklendi!"), backgroundColor: Colors.red));
            }
          },
        );
      },
    );
  }
}

// --- 2. AKILLI RESİM WIDGET'I ---
class AkilliResim extends StatelessWidget {
  final String url;
  final double height;
  final double width;

  const AkilliResim({super.key, required this.url, this.height = 150, this.width = double.infinity});

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return Container(height: height, width: width, color: Colors.grey.shade200, child: Icon(Icons.store, size: 50, color: Colors.grey.shade400));
    }
    if (url.startsWith('http')) {
      return Image.network(url, height: height, width: width, fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Container(height: height, width: width, color: Colors.grey.shade200, child: Icon(Icons.broken_image, size: 50, color: Colors.grey.shade400)));
    }
    return Image.asset(url, height: height, width: width, fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(height: height, width: width, color: Colors.grey.shade200, child: const Center(child: Text("Resim Yok", style: TextStyle(color: Colors.grey)))));
  }
}

// --- 3. ANA EKRAN ---
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

  void _yoneticiIslemleri(String docId, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(data['isim'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blue),
                title: const Text("Bilgileri & Resmi Düzenle"),
                onTap: () { Navigator.pop(ctx); _dukkanDuzenleDialog(docId, data); },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text("Dükkanı Sil"),
                onTap: () { Navigator.pop(ctx); _silmeOnayi(docId, data['isim']); },
              ),
            ],
          ),
        );
      },
    );
  }

  void _silmeOnayi(String docId, String isim) {
    showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text("Dükkanı Sil"), content: Text("$isim silinsin mi?"), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("İptal")), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), onPressed: () async { await FirebaseFirestore.instance.collection('magazalar').doc(docId).delete(); Navigator.pop(ctx); }, child: const Text("SİL"))]));
  }

  void _dukkanDuzenleDialog(String docId, Map<String, dynamic> data) {
    final isimC = TextEditingController(text: data['isim']);
    final adresC = TextEditingController(text: data['adres']);
    final resimC = TextEditingController(text: data['resimUrl']);
    String seciliKategori = data['kategori'] ?? kategoriler[1];
    if (!kategoriler.contains(seciliKategori)) seciliKategori = kategoriler[1];

    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (context, setState) {
      return AlertDialog(
        title: const Text("Dükkanı Düzenle"),
        content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: isimC, decoration: const InputDecoration(labelText: "Dükkan İsmi")),
          const SizedBox(height: 10),
          TextField(controller: adresC, decoration: const InputDecoration(labelText: "Adres")),
          const SizedBox(height: 10),
          TextField(controller: resimC, decoration: const InputDecoration(labelText: "Resim Yolu", hintText: "assets/images/... veya https://...")),
          const SizedBox(height: 10),
          DropdownButton<String>(isExpanded: true, value: seciliKategori, items: kategoriler.where((k) => k != "Tümü").map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) { setState(() { seciliKategori = v!; }); }),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("İptal")),
          ElevatedButton(onPressed: () async {
            await FirebaseFirestore.instance.collection('magazalar').doc(docId).update({'isim': isimC.text.trim(), 'adres': adresC.text.trim(), 'resimUrl': resimC.text.trim(), 'kategori': seciliKategori});
            Navigator.pop(ctx);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Güncellendi!")));
          }, child: const Text("KAYDET"))
        ],
      );
    }));
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Sanayi Rehberim'), actions: [ IconButton(icon: const Icon(Icons.notifications_active_outlined), onPressed: () { Navigator.push(context, MaterialPageRoute(builder: (context) => const BildirimlerEkrani())); }) ]),
      drawer: Drawer(
        child: Column(
          children: [
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
              builder: (context, snapshot) {
                String adSoyad = "Misafir";
                ImageProvider? profilImage;

                if (snapshot.hasData && snapshot.data!.exists) {
                  var data = snapshot.data!.data() as Map<String, dynamic>;
                  adSoyad = data['adSoyad'] ?? "Misafir";
                  String? base64String = data['profilResmi'];
                  if (base64String != null && base64String.isNotEmpty) {
                    try { profilImage = MemoryImage(base64Decode(base64String)); } catch (e) { debugPrint("Resim hatası: $e"); }
                  }
                }

                return UserAccountsDrawerHeader(
                  decoration: BoxDecoration(gradient: LinearGradient(colors: isDark ? [const Color(0xFF0F172A), const Color(0xFF334155)] : [const Color(0xFF0F172A), const Color(0xFF1E293B)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
                  accountName: Text(adSoyad, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                  accountEmail: Text(user?.email ?? ""),
                  currentAccountPicture: CircleAvatar(
                    backgroundColor: Colors.white,
                    backgroundImage: profilImage,
                    child: profilImage == null
                        ? Text(adSoyad.isNotEmpty ? adSoyad[0].toUpperCase() : "M", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)))
                        : null,
                  ),
                );
              },
            ),
            ListTile(leading: const Icon(Icons.home), title: const Text('Ana Sayfa'), onTap: () => Navigator.pop(context)),
            ListTile(leading: const Icon(Icons.favorite, color: Colors.red), title: const Text('Favori Dükkanlarım'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => const FavorilerimEkrani())); }),
            ListTile(leading: const Icon(Icons.notifications), title: const Text('Bildirimler'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => const BildirimlerEkrani())); }),
            ListTile(leading: const Icon(Icons.calendar_month), title: const Text('Randevularım'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => const RandevularimEkrani())); }),
            ListTile(leading: const Icon(Icons.settings), title: const Text('Profil Ayarları'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfilAyarlariEkrani())); }),
            const Divider(),

            // --- HAKKINDA BUTONU (YENİ EKLENDİ) ---
            ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Hakkında'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const HakkimizdaEkrani()));
                }
            ),
            const Divider(),
            // ----------------------------------------

            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || !snapshot.data!.exists) return const SizedBox();
                var userData = snapshot.data!.data() as Map<String, dynamic>;
                if (userData['rol'] == 'yonetici') {
                  return ListTile(leading: Icon(Icons.storefront, color: Colors.blue[700]), title: Text('Dükkan Sahibi Paneli', style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.bold)), onTap: () { Navigator.pop(context); if (userData['dukkanId'] != null) { Navigator.push(context, MaterialPageRoute(builder: (context) => DukkanYonetimPaneli(dukkanId: userData['dukkanId'], dukkanIsmi: "Dükkanım"))); } else { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Dükkan atanmamış!"))); } });
                } return const SizedBox();
              },
            ),
            ListTile(leading: const Icon(Icons.logout, color: Colors.red), title: const Text('Çıkış Yap', style: TextStyle(color: Colors.red)), onTap: () => FirebaseAuth.instance.signOut()),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(padding: const EdgeInsets.fromLTRB(16, 16, 16, 8), color: Theme.of(context).scaffoldBackgroundColor, child: TextField(controller: _searchController, onChanged: (value) => setState(() => aramaMetni = value.toLowerCase()), decoration: InputDecoration(hintText: 'Tamirci, usta veya dükkan ara...', prefixIcon: const Icon(Icons.search, color: Colors.grey), suffixIcon: aramaMetni.isNotEmpty ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchController.clear(); setState(() => aramaMetni = ""); }) : null, contentPadding: const EdgeInsets.symmetric(vertical: 0)))),
          Container(height: 50, margin: const EdgeInsets.only(bottom: 8), child: ListView.builder(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12), itemCount: kategoriler.length, itemBuilder: (context, index) { final k = kategoriler[index]; bool isSelected = secilenKategori == k; return Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: FilterChip(label: Text(k), selected: isSelected, onSelected: (s) => setState(() => secilenKategori = k), backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white, selectedColor: Theme.of(context).colorScheme.secondary, labelStyle: TextStyle(color: isSelected ? Colors.black : (isDark ? Colors.white : Colors.black87), fontWeight: isSelected ? FontWeight.bold : FontWeight.normal), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey.shade300)), showCheckmark: false)); })),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: secilenKategori == "Tümü" ? FirebaseFirestore.instance.collection('magazalar').snapshots() : FirebaseFirestore.instance.collection('magazalar').where('kategori', isEqualTo: secilenKategori).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text('Hata: ${snapshot.error}'));
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                var filtered = snapshot.data!.docs.where((doc) { return (doc.data() as Map<String, dynamic>)['isim'].toString().toLowerCase().contains(aramaMetni); }).toList();
                if (filtered.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.search_off, size: 64, color: Colors.grey.shade400), const SizedBox(height: 10), Text('Sonuç bulunamadı.', style: TextStyle(color: Colors.grey.shade600))]));
                return ListView.builder(
                  itemCount: filtered.length, padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    var data = filtered[index].data() as Map<String, dynamic>;
                    double puan = (data['puan'] ?? 0).toDouble();
                    String puanYazisi = puan == 0 ? "Yeni" : puan.toStringAsFixed(1);
                    String resimUrl = data['resimUrl'] ?? '';
                    return GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => DukkanDetayEkrani(docId: filtered[index].id, isim: data['isim'], kategori: data['kategori'], adres: data['adres'], puan: puan, resimUrl: resimUrl))),
                      onLongPress: () => _yoneticiIslemleri(filtered[index].id, data),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(color: isDark ? const Color(0xFF1E293B) : Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Stack(
                              children: [
                                ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                    child: AkilliResim(url: resimUrl, height: 150)),
                                Positioned(top: 10, right: 10, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(8)), child: Row(children: [const Icon(Icons.star, color: Colors.amber, size: 14), const SizedBox(width: 4), Text(puanYazisi, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))]))),
                              ],
                            ),
                            Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Expanded(child: Text(data['isim'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis)), FavoriButonu(dukkanId: filtered[index].id)]),
                              const SizedBox(height: 4),
                              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2), decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(4)), child: Text(data['kategori'], style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 11, fontWeight: FontWeight.bold))),
                              const SizedBox(height: 8),
                              Row(children: [const Icon(Icons.location_on, size: 14, color: Colors.grey), const SizedBox(width: 4), Expanded(child: Text(data['adres'], style: const TextStyle(color: Colors.grey, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis))]),
                            ])),
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
}

// --- 4. FAVORİLER EKRANI ---
class FavorilerimEkrani extends StatelessWidget {
  const FavorilerimEkrani({super.key});
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text("Favori Dükkanlarım")),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
        builder: (context, userSnapshot) {
          if (!userSnapshot.hasData) return const Center(child: CircularProgressIndicator());
          List favoriIdleri = (userSnapshot.data!.data() as Map<String, dynamic>)['favoriler'] ?? [];
          if (favoriIdleri.isEmpty) return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.favorite_border, size: 80, color: Colors.grey), SizedBox(height: 10), Text("Henüz favorin yok.")]));
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('magazalar').snapshots(),
            builder: (context, magazaSnapshot) {
              if (!magazaSnapshot.hasData) return const Center(child: CircularProgressIndicator());
              var favoriDukkanlar = magazaSnapshot.data!.docs.where((doc) => favoriIdleri.contains(doc.id)).toList();
              return ListView.builder(itemCount: favoriDukkanlar.length, padding: const EdgeInsets.all(10), itemBuilder: (context, index) {
                var data = favoriDukkanlar[index].data() as Map<String, dynamic>;
                return Card(child: ListTile(leading: const Icon(Icons.store, color: Colors.red), title: Text(data['isim']), subtitle: Text(data['kategori']), trailing: FavoriButonu(dukkanId: favoriDukkanlar[index].id), onTap: () { Navigator.push(context, MaterialPageRoute(builder: (context) => DukkanDetayEkrani(docId: favoriDukkanlar[index].id, isim: data['isim'], kategori: data['kategori'], adres: data['adres'], puan: (data['puan'] ?? 0).toDouble(), resimUrl: data['resimUrl'] ?? ''))); }));
              });
            },
          );
        },
      ),
    );
  }
}

// --- 5. BİLDİRİMLER EKRANI ---
class BildirimlerEkrani extends StatelessWidget {
  const BildirimlerEkrani({super.key});
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(appBar: AppBar(title: const Text("Bildirimler")), body: StreamBuilder<QuerySnapshot>(stream: FirebaseFirestore.instance.collection('bildirimler').where('userId', isEqualTo: user?.uid).orderBy('tarih', descending: true).snapshots(), builder: (context, snapshot) { if (snapshot.hasError) return Center(child: Text("Hata: ${snapshot.error}")); if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator()); if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.notifications_off, size: 80, color: Colors.grey), SizedBox(height: 10), Text("Henüz bildirim yok.")])); return ListView.builder(itemCount: snapshot.data!.docs.length, padding: const EdgeInsets.all(10), itemBuilder: (context, index) { var veri = snapshot.data!.docs[index].data() as Map<String, dynamic>; String baslik = veri['baslik'] ?? 'Bildirim'; String mesaj = veri['mesaj'] ?? ''; String tur = veri['tur'] ?? 'bilgi'; IconData ikon = Icons.info; Color renk = Colors.blue; if (tur == 'onay') { ikon = Icons.check_circle; renk = Colors.green; } if (tur == 'red') { ikon = Icons.cancel; renk = Colors.red; } if (tur == 'tamamlandi') { ikon = Icons.task_alt; renk = Colors.teal; } return Card(child: ListTile(leading: CircleAvatar(backgroundColor: renk.withOpacity(0.2), child: Icon(ikon, color: renk)), title: Text(baslik, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text(mesaj), trailing: IconButton(icon: const Icon(Icons.delete, size: 20), onPressed: () => FirebaseFirestore.instance.collection('bildirimler').doc(snapshot.data!.docs[index].id).delete()))); }); }));
  }
}

// --- 6. PROFİL AYARLARI EKRANI ---
class ProfilAyarlariEkrani extends StatefulWidget {
  const ProfilAyarlariEkrani({super.key});
  @override
  State<ProfilAyarlariEkrani> createState() => _ProfilAyarlariEkraniState();
}

class _ProfilAyarlariEkraniState extends State<ProfilAyarlariEkrani> {
  final _adController = TextEditingController();
  final _telController = TextEditingController();
  String? _profilResmiBase64;
  bool isLoading = false;
  bool isUploading = false;

  @override
  void initState() { super.initState(); _verileriGetir(); }

  Future<void> _verileriGetir() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          _adController.text = doc.data()?['adSoyad'] ?? '';
          _telController.text = doc.data()?['telefon'] ?? '';
          _profilResmiBase64 = doc.data()?['profilResmi'];
        });
      }
    }
  }

  Future<void> _resimSecVeYukle() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery, maxWidth: 512, imageQuality: 50);
    if (pickedFile != null) {
      setState(() => isUploading = true);
      try {
        File imageFile = File(pickedFile.path);
        final bytes = await imageFile.readAsBytes();
        String base64Image = base64Encode(bytes);
        await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'profilResmi': base64Image});
        setState(() { _profilResmiBase64 = base64Image; isUploading = false; });
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profil resmi kaydedildi!"), backgroundColor: Colors.green));
      } catch (e) {
        setState(() => isUploading = false);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e"), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _hesabiSil() async {
    setState(() => isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).delete();
        await user.delete();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Hesabınız başarıyla silindi. Hoşçakalın! 👋"), backgroundColor: Colors.green)
          );
          Navigator.of(context).pop();
        }
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Güvenlik gereği hesabınızı silmek için lütfen Çıkış Yapıp tekrar girin."), backgroundColor: Colors.orange));
      } else {
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: ${e.message}")));
      }
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e")));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _hesapSilOnayi() {
    showDialog(context: context, builder: (ctx) => AlertDialog(
        title: const Text("Hesabı Sil"),
        content: const Text("Hesabınızı ve tüm verilerinizi kalıcı olarak silmek istediğinize emin misiniz? Bu işlem geri alınamaz."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("İptal")),
          ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), onPressed: () { Navigator.pop(ctx); _hesabiSil(); }, child: const Text("SİL"))
        ]
    ));
  }

  Future<void> _kaydet() async { setState(() => isLoading = true); try { final user = FirebaseAuth.instance.currentUser; if (user != null) { await FirebaseFirestore.instance.collection('users').doc(user.uid).set({ 'adSoyad': _adController.text.trim(), 'telefon': _telController.text.trim(), 'email': user.email, }, SetOptions(merge: true)); if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil Güncellendi!'), backgroundColor: Colors.green)); Navigator.pop(context); } } } catch (e) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e'))); } finally { if (mounted) setState(() => isLoading = false); } }

  @override
  Widget build(BuildContext context) {
    bool isDark = Theme.of(context).brightness == Brightness.dark;
    ImageProvider? imageProvider;
    if (_profilResmiBase64 != null && _profilResmiBase64!.isNotEmpty) {
      try { imageProvider = MemoryImage(base64Decode(_profilResmiBase64!)); } catch (e) { debugPrint("Resim hatası: $e"); }
    }

    return Scaffold(
        appBar: AppBar(title: const Text("Profil Ayarları")),
        body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              GestureDetector(
                onTap: _resimSecVeYukle,
                child: Stack(
                  children: [
                    CircleAvatar(radius: 60, backgroundColor: Colors.blueGrey.shade100, backgroundImage: imageProvider, child: imageProvider == null ? const Icon(Icons.person, size: 60, color: Colors.blueGrey) : null),
                    Positioned(bottom: 0, right: 0, child: Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle), child: isUploading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.camera_alt, color: Colors.white, size: 20))),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Text("Fotoğrafı değiştirmek için dokun", style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 20),
              TextField(controller: _adController, decoration: const InputDecoration(labelText: "Ad Soyad", prefixIcon: Icon(Icons.person))),
              const SizedBox(height: 15),
              TextField(controller: _telController, decoration: const InputDecoration(labelText: "Telefon Numarası", prefixIcon: Icon(Icons.phone))),
              const SizedBox(height: 25),
              SwitchListTile(title: const Text("Karanlık Mod", style: TextStyle(fontWeight: FontWeight.bold)), subtitle: Text(isDark ? "Açık" : "Kapalı"), secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode), value: isDark, onChanged: (val) { }),
              const Divider(height: 30),
              SizedBox(width: double.infinity, height: 50, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey.shade800, foregroundColor: Colors.white), onPressed: isLoading ? null : _kaydet, child: isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("KAYDET"))),
              const SizedBox(height: 40),
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text("Hesabımı Sil", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                onTap: _hesapSilOnayi,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: Colors.red.withOpacity(0.3))),
              ),
            ])
        )
    );
  }
}

// --- 7. DETAY EKRANI ---
class DukkanDetayEkrani extends StatefulWidget {
  final String docId, isim, kategori, adres; final String resimUrl; final double puan;
  const DukkanDetayEkrani({super.key, required this.docId, required this.isim, required this.kategori, required this.adres, required this.puan, required this.resimUrl});
  @override
  State<DukkanDetayEkrani> createState() => _DukkanDetayEkraniState();
}

class _DukkanDetayEkraniState extends State<DukkanDetayEkrani> {
  DateTime? secilenTarih; TimeOfDay? secilenSaat; bool isSaving = false;
  Future<void> _randevuOlustur() async { if (secilenTarih == null || secilenSaat == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tarih/Saat seçiniz!'), backgroundColor: Colors.red)); return; } setState(() => isSaving = true); try { final user = FirebaseAuth.instance.currentUser; String musteriAd = "Belirtilmemiş", musteriTel = "Belirtilmemiş"; if (user != null) { final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get(); if (userDoc.exists) { musteriAd = userDoc.data()?['adSoyad'] ?? "Belirtilmemiş"; musteriTel = userDoc.data()?['telefon'] ?? "Belirtilmemiş"; } } await FirebaseFirestore.instance.collection('randevular').add({ 'dukkanId': widget.docId, 'dukkanIsim': widget.isim, 'userId': user?.uid, 'userEmail': user?.email, 'userAdSoyad': musteriAd, 'userTelefon': musteriTel, 'tarih': secilenTarih.toString().split(' ')[0], 'saat': secilenSaat!.format(context), 'olusturulmaZamani': FieldValue.serverTimestamp(), 'durum': 'bekliyor' }); if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Randevu alındı!'), backgroundColor: Colors.green)); Navigator.pop(context); } } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e'))); } finally { if (mounted) setState(() => isSaving = false); } }
  Future<void> _haritadaAc() async { final String query = Uri.encodeComponent(widget.adres); final Uri url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query'); try { if (!await launchUrl(url, mode: LaunchMode.externalApplication)) { throw 'Harita başlatılamadı'; } } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e"))); } }
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(length: 2, child: Scaffold(appBar: AppBar(title: Text(widget.isim), bottom: const TabBar(labelColor: Colors.amber, unselectedLabelColor: Colors.white70, indicatorColor: Colors.amber, indicatorWeight: 3, tabs: [Tab(text: "Bilgiler & Randevu", icon: Icon(Icons.info_outline)), Tab(text: "Yorumlar", icon: Icon(Icons.comment))]), actions: [ FavoriButonu(dukkanId: widget.docId), const SizedBox(width: 10) ]), body: TabBarView(children: [ SingleChildScrollView(child: Column(children: [
      AkilliResim(url: widget.resimUrl, height: 200),
      Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [ Text(widget.isim, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)), const SizedBox(height: 5), Text(widget.adres, style: const TextStyle(fontSize: 16)), const SizedBox(height: 10), SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: _haritadaAc, icon: const Icon(Icons.map, color: Colors.blue), label: const Text("YOL TARİFİ AL (Google Maps)", style: TextStyle(color: Colors.blue)), style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.blue)))), const Divider(height: 30), const Center(child: Text("Randevu Al", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))), const SizedBox(height: 10), Row(children: [ Expanded(child: OutlinedButton(onPressed: () async { final t = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 30))); if(t!=null) setState(()=>secilenTarih=t); }, child: Text(secilenTarih?.toString().split(' ')[0] ?? "Tarih Seç"))), const SizedBox(width: 10), Expanded(child: OutlinedButton(onPressed: () async { final s = await showTimePicker(context: context, initialTime: TimeOfDay.now()); if(s!=null) setState(()=>secilenSaat=s); }, child: Text(secilenSaat?.format(context) ?? "Saat Seç"))) ]), const SizedBox(height: 20), SizedBox(width: double.infinity, height: 50, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey.shade900, foregroundColor: Colors.white), onPressed: isSaving ? null : _randevuOlustur, child: isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text("RANDEVUYU ONAYLA"))) ])),])), StreamBuilder<QuerySnapshot>(stream: FirebaseFirestore.instance.collection('yorumlar').where('dukkanId', isEqualTo: widget.docId).snapshots(), builder: (context, snapshot) { if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("Henüz yorum yapılmamış.")); return ListView.builder(padding: const EdgeInsets.all(10), itemCount: snapshot.data!.docs.length, itemBuilder: (context, index) { var yorum = snapshot.data!.docs[index].data() as Map<String, dynamic>; return Card(child: ListTile(leading: CircleAvatar(backgroundColor: Colors.orange.shade100, child: Text(yorum['puan'].toString())), title: Text(yorum['userAdSoyad'] ?? 'Anonim'), subtitle: Text(yorum['yorum'] ?? ''), trailing: const Icon(Icons.star, color: Colors.amber, size: 16))); }); }) ])));
  }
}

// --- 8. RANDEVULARIM EKRANI ---
class RandevularimEkrani extends StatelessWidget {
  const RandevularimEkrani({super.key});
  void _yorumYapDialog(BuildContext context, String dukkanId, String dukkanIsmi) { final yorumController = TextEditingController(); double puan = 5; showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (context, setState) { return AlertDialog(title: Text("$dukkanIsmi Değerlendir"), content: Column(mainAxisSize: MainAxisSize.min, children: [ const Text("Hizmetten memnun kaldınız mı?"), TextField(controller: yorumController, decoration: const InputDecoration(labelText: "Yorumunuz")), const SizedBox(height: 10), const Text("Puanınız (1-5):"), DropdownButton<double>(value: puan, items: [1,2,3,4,5].map((e) => DropdownMenuItem(value: e.toDouble(), child: Text(e.toString()))).toList(), onChanged: (v) { setState(() { puan = v!; }); }) ]), actions: [ TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("İptal")), ElevatedButton(onPressed: () async { final user = FirebaseAuth.instance.currentUser; if (dukkanId.isEmpty) return; await FirebaseFirestore.instance.collection('yorumlar').add({ 'dukkanId': dukkanId, 'userId': user!.uid, 'userAdSoyad': user.email, 'yorum': yorumController.text, 'puan': puan, 'tarih': FieldValue.serverTimestamp() }); try { var yorumlarSnapshot = await FirebaseFirestore.instance.collection('yorumlar').where('dukkanId', isEqualTo: dukkanId).get(); if (yorumlarSnapshot.docs.isNotEmpty) { double toplamPuan = 0; for (var doc in yorumlarSnapshot.docs) { toplamPuan += (doc.data()['puan'] as num).toDouble(); } double yeniOrtalama = toplamPuan / yorumlarSnapshot.docs.length; await FirebaseFirestore.instance.collection('magazalar').doc(dukkanId).update({'puan': yeniOrtalama}); } } catch (e) { debugPrint("Hata: $e"); } Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Yorumunuz eklendi!"))); }, child: const Text("GÖNDER")) ]); })); }
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(appBar: AppBar(title: const Text("Randevularım")), body: StreamBuilder<QuerySnapshot>(stream: FirebaseFirestore.instance.collection('randevular').where('userId', isEqualTo: user?.uid).snapshots(), builder: (context, snapshot) { if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("Randevu yok.")); return ListView.builder(itemCount: snapshot.data!.docs.length, padding: const EdgeInsets.all(12), itemBuilder: (context, index) { var belge = snapshot.data!.docs[index]; var veri = belge.data() as Map<String, dynamic>; String dukkanIsmi = veri['dukkanIsim'] ?? 'Bilinmeyen Dükkan'; String tarih = veri['tarih'] ?? '?'; String saat = veri['saat'] ?? '?'; String durum = veri['durum'] ?? 'bekliyor'; String dukkanId = veri['dukkanId'] ?? ''; Color durumRenk = Colors.orange; if (durum == 'onaylandi') durumRenk = Colors.green; if (durum == 'reddedildi') durumRenk = Colors.red; if (durum == 'tamamlandi') durumRenk = Colors.blueGrey; return Card(elevation: 3, margin: const EdgeInsets.only(bottom: 12), child: Column(children: [ ListTile(leading: Icon(Icons.circle, color: durumRenk), title: Text(dukkanIsmi), subtitle: Text("$tarih - $saat\nDurum: ${durum.toUpperCase()}"), trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => FirebaseFirestore.instance.collection('randevular').doc(belge.id).delete())), if (durum == 'tamamlandi' && dukkanId.isNotEmpty) Padding(padding: const EdgeInsets.only(bottom: 8.0, right: 8.0), child: Align(alignment: Alignment.centerRight, child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black), icon: const Icon(Icons.star), label: const Text("YORUM YAP"), onPressed: () => _yorumYapDialog(context, dukkanId, dukkanIsmi)))) ])); }); }));
  }
}

// --- 9. DÜKKAN YÖNETİM PANELİ ---
class DukkanYonetimPaneli extends StatelessWidget {
  final String dukkanId; final String dukkanIsmi;
  const DukkanYonetimPaneli({super.key, required this.dukkanId, required this.dukkanIsmi});
  Future<void> _durumGuncelle(String docId, String yeniDurum, String userId, String randevuTarihi) async { await FirebaseFirestore.instance.collection('randevular').doc(docId).update({'durum': yeniDurum}); String mesaj = ""; String tur = ""; if (yeniDurum == 'onaylandi') { mesaj = "$dukkanIsmi, $randevuTarihi tarihindeki randevunuzu onayladı."; tur = "onay"; } else if (yeniDurum == 'reddedildi') { mesaj = "$dukkanIsmi, randevunuzu maalesef reddetti."; tur = "red"; } else if (yeniDurum == 'tamamlandi') { mesaj = "$dukkanIsmi ile işleminiz tamamlandı. Lütfen değerlendirin."; tur = "tamamlandi"; } if (mesaj.isNotEmpty) { await FirebaseFirestore.instance.collection('bildirimler').add({ 'userId': userId, 'baslik': 'Randevu Durumu', 'mesaj': mesaj, 'tur': tur, 'tarih': FieldValue.serverTimestamp(), }); } }
  void _dukkanDuzenleDialog(BuildContext context, String mevcutIsim, String mevcutAdres, String mevcutKategori, String mevcutResimUrl) { final isimController = TextEditingController(text: mevcutIsim); final adresController = TextEditingController(text: mevcutAdres); final resimController = TextEditingController(text: mevcutResimUrl); String kategori = mevcutKategori; final List<String> kategoriler = ["Kaporta", "Motor", "Elektrik", "Lastik & Jant", "Yedek Parça", "Boya", "Döşeme"]; showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (context, setState) { return AlertDialog(title: const Text("Dükkan Bilgilerini Düzenle"), content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [ TextField(controller: isimController, decoration: const InputDecoration(labelText: "Dükkan İsmi")), const SizedBox(height: 10), TextField(controller: adresController, decoration: const InputDecoration(labelText: "Adres")), const SizedBox(height: 10), TextField(controller: resimController, decoration: const InputDecoration(labelText: "Resim Yolu (assets/... veya https://...)")), const SizedBox(height: 10), const Text("Kategori:"), DropdownButton<String>(value: kategoriler.contains(kategori) ? kategori : kategoriler[0], isExpanded: true, items: kategoriler.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) { setState(() { kategori = v!; }); }), ])), actions: [ TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("İptal")), ElevatedButton(onPressed: () async { await FirebaseFirestore.instance.collection('magazalar').doc(dukkanId).update({ 'isim': isimController.text.trim(), 'adres': adresController.text.trim(), 'resimUrl': resimController.text.trim(), 'kategori': kategori }); Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bilgiler güncellendi!"))); }, child: const Text("KAYDET")) ]); })); }
  @override
  Widget build(BuildContext context) { return StreamBuilder<DocumentSnapshot>(stream: FirebaseFirestore.instance.collection('magazalar').doc(dukkanId).snapshots(), builder: (context, snapshot) { if (!snapshot.hasData) return const Scaffold(body: Center(child: CircularProgressIndicator())); var dukkanVerisi = snapshot.data!.data() as Map<String, dynamic>; String dukkanIsmi = dukkanVerisi['isim'] ?? 'Dükkanım'; String dukkanAdres = dukkanVerisi['adres'] ?? ''; String dukkanKategori = dukkanVerisi['kategori'] ?? 'Genel'; String resimUrl = dukkanVerisi['resimUrl'] ?? ''; return Scaffold(appBar: AppBar(title: Text("$dukkanIsmi Paneli"), backgroundColor: Colors.indigo, foregroundColor: Colors.white, actions: [ IconButton(icon: const Icon(Icons.edit), tooltip: "Dükkanı Düzenle", onPressed: () => _dukkanDuzenleDialog(context, dukkanIsmi, dukkanAdres, dukkanKategori, resimUrl)) ]), body: Column(children: [ Container(padding: const EdgeInsets.all(15), color: Colors.indigo.shade50, width: double.infinity, child: const Text("Aktif Randevular", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo), textAlign: TextAlign.center)), Expanded(child: StreamBuilder<QuerySnapshot>(stream: FirebaseFirestore.instance.collection('randevular').where('dukkanId', isEqualTo: dukkanId).snapshots(), builder: (context, snapshot) { if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("Randevu yok.")); var aktifIsler = snapshot.data!.docs.where((doc) { var veri = doc.data() as Map<String, dynamic>; String durum = veri['durum'] ?? ''; return durum == 'bekliyor' || durum == 'onaylandi'; }).toList(); if (aktifIsler.isEmpty) { return const Center(child: Text("Şu an bekleyen veya aktif bir işiniz yok. 🎉", style: TextStyle(color: Colors.grey, fontSize: 16))); } return ListView.builder(padding: const EdgeInsets.all(10), itemCount: aktifIsler.length, itemBuilder: (context, index) { var doc = aktifIsler[index]; var veri = doc.data() as Map<String, dynamic>; String durum = veri['durum'] ?? 'bekliyor'; String userId = veri['userId'] ?? ''; String tarih = veri['tarih'] ?? 'Bilinmiyor'; return Card(elevation: 3, margin: const EdgeInsets.only(bottom: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: durum == 'bekliyor' ? Colors.orange.withOpacity(0.5) : Colors.green.withOpacity(0.5), width: 1)), child: Padding(padding: const EdgeInsets.all(12.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [ Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [ Text("${veri['userAdSoyad']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: durum == 'bekliyor' ? Colors.orange.shade100 : Colors.green.shade100, borderRadius: BorderRadius.circular(8)), child: Text(durum.toUpperCase(), style: TextStyle(color: durum == 'bekliyor' ? Colors.orange.shade900 : Colors.green.shade900, fontWeight: FontWeight.bold, fontSize: 12))) ]), const SizedBox(height: 5), Row(children: [const Icon(Icons.phone, size: 16, color: Colors.grey), const SizedBox(width: 5), Text("${veri['userTelefon']}")],), const SizedBox(height: 5), Row(children: [const Icon(Icons.calendar_today, size: 16, color: Colors.grey), const SizedBox(width: 5), Text("$tarih - Saat: ${veri['saat']}")],), const Divider(), Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [ if (durum == 'bekliyor') ...[ ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.green), onPressed: () => _durumGuncelle(doc.id, 'onaylandi', userId, tarih), child: const Text("ONAYLA", style: TextStyle(color: Colors.white))), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () => _durumGuncelle(doc.id, 'reddedildi', userId, tarih), child: const Text("REDDET", style: TextStyle(color: Colors.white))), ], if (durum == 'onaylandi') Expanded(child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey, padding: const EdgeInsets.symmetric(vertical: 12)), onPressed: () => _durumGuncelle(doc.id, 'tamamlandi', userId, tarih), icon: const Icon(Icons.check_circle, color: Colors.white), label: const Text("İŞİ TAMAMLA & LİSTEDEN KALDIR", style: TextStyle(color: Colors.white)))), ]) ]))); }); })) ])); }); }
}

// --- 10. HAKKIMIZDA EKRANI (YENİ) ---
class HakkimizdaEkrani extends StatelessWidget {
  const HakkimizdaEkrani({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Hakkında")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.car_repair, size: 100, color: Color(0xFF0F172A)),
              const SizedBox(height: 20),
              const Text("SANAYİ REHBERİM", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A), letterSpacing: 1.5)),
              const Text("v1.0.0", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 40),
              const Divider(),
              const SizedBox(height: 40),
              const Text("Hazırlayan", style: TextStyle(fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 5),
              const Text("ARDA DURAN", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 20),
              const Text("Öğrenci Numarası", style: TextStyle(fontSize: 16, color: Colors.grey)),
              const SizedBox(height: 5),
              const Text("240053017", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 30),
              const Text("Alanya Üniversitesi", style: TextStyle(fontSize: 18, color: Colors.black54)),
              const Text("Bilgisayar Programcılığı", style: TextStyle(fontSize: 18, color: Colors.black54)),
              const SizedBox(height: 60),
              const Text("© 2026 Tüm Hakları Saklıdır", style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}