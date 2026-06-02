import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
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

// --- 3. ANA EKRAN (GELİŞMİŞ FİLTRE VE SIRALAMA EKLENDİ) ---
class MagazaListesiEkrani extends StatefulWidget {
  const MagazaListesiEkrani({super.key});
  @override
  State<MagazaListesiEkrani> createState() => _MagazaListesiEkraniState();
}

class _MagazaListesiEkraniState extends State<MagazaListesiEkrani> {
  String secilenKategori = "Tümü";
  String aramaMetni = "";

  bool filtreSadeceOnayli = false;
  String siralamaSecimi = 'varsayilan';

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
    final telC = TextEditingController(text: data['telefon'] ?? '');
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
          TextField(controller: telC, decoration: const InputDecoration(labelText: "Telefon Numarası", prefixIcon: Icon(Icons.phone))),
          const SizedBox(height: 10),
          TextField(controller: resimC, decoration: const InputDecoration(labelText: "Resim Yolu")),
          const SizedBox(height: 10),
          DropdownButton<String>(isExpanded: true, value: seciliKategori, items: kategoriler.where((k) => k != "Tümü").map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) { setState(() { seciliKategori = v!; }); }),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("İptal")),
          ElevatedButton(onPressed: () async {
            await FirebaseFirestore.instance.collection('magazalar').doc(docId).update({
              'isim': isimC.text.trim(),
              'adres': adresC.text.trim(),
              'telefon': telC.text.trim(),
              'resimUrl': resimC.text.trim(),
              'kategori': seciliKategori
            });
            Navigator.pop(ctx);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Güncellendi!")));
          }, child: const Text("KAYDET"))
        ],
      );
    }));
  }

  void _filtreMenusuAc() {
    showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (ctx) => StatefulBuilder(
            builder: (context, setModalState) {
              return Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Filtrele & Sırala", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              TextButton(
                                  onPressed: () {
                                    setModalState(() { filtreSadeceOnayli = false; siralamaSecimi = 'varsayilan'; });
                                    setState(() { filtreSadeceOnayli = false; siralamaSecimi = 'varsayilan'; });
                                  },
                                  child: const Text("Temizle", style: TextStyle(color: Colors.red))
                              )
                            ]
                        ),
                        const Divider(),
                        SwitchListTile(
                            title: const Text("Sadece Onaylı (Mavi Tikli)", style: TextStyle(fontWeight: FontWeight.w500)),
                            secondary: const Icon(Icons.verified, color: Colors.blue),
                            value: filtreSadeceOnayli,
                            activeColor: Colors.blue,
                            onChanged: (val) {
                              setModalState(() => filtreSadeceOnayli = val);
                              setState(() => filtreSadeceOnayli = val);
                            }
                        ),
                        const SizedBox(height: 10),
                        const Text("Sıralama Ölçütü", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                        const SizedBox(height: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(10)),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                                isExpanded: true,
                                value: siralamaSecimi,
                                items: const [
                                  DropdownMenuItem(value: 'varsayilan', child: Text("Varsayılan Sıralama")),
                                  DropdownMenuItem(value: 'puan', child: Text("En Yüksek Puanlılar")),
                                  DropdownMenuItem(value: 'yorum', child: Text("En Çok Değerlendirilenler")),
                                  DropdownMenuItem(value: 'az', child: Text("İsme Göre (A'dan Z'ye)")),
                                  DropdownMenuItem(value: 'za', child: Text("İsme Göre (Z'den A'ya)")),
                                ],
                                onChanged: (val) {
                                  if (val != null) {
                                    setModalState(() => siralamaSecimi = val);
                                    setState(() => siralamaSecimi = val);
                                  }
                                }
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                            width: double.infinity,
                            height: 45,
                            child: ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text("SONUÇLARI GÖSTER", style: TextStyle(fontWeight: FontWeight.bold))
                            )
                        )
                      ]
                  )
              );
            }
        )
    );
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
            ListTile(leading: const Icon(Icons.chat, color: Colors.blue), title: const Text('Mesajlarım'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => const KullaniciMesajlariEkrani())); }),
            ListTile(leading: const Icon(Icons.calendar_month), title: const Text('Randevularım'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => const RandevularimEkrani())); }),
            ListTile(leading: const Icon(Icons.notifications), title: const Text('Bildirimler'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => const BildirimlerEkrani())); }),
            ListTile(leading: const Icon(Icons.settings), title: const Text('Profil Ayarları'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfilAyarlariEkrani())); }),
            const Divider(),
            ListTile(leading: const Icon(Icons.info_outline), title: const Text('Hakkında'), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => const HakkimizdaEkrani())); }),
            const Divider(),
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || !snapshot.data!.exists) return const SizedBox();
                var userData = snapshot.data!.data() as Map<String, dynamic>;

                List<Widget> adminMenuler = [];

                if (userData['rol'] == 'yonetici' || userData['rol'] == 'superadmin') {
                  adminMenuler.add(
                      ListTile(leading: Icon(Icons.storefront, color: Colors.blue[700]), title: Text('Dükkan Sahibi Paneli', style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.bold)), onTap: () { Navigator.pop(context); if (userData['dukkanId'] != null) { Navigator.push(context, MaterialPageRoute(builder: (context) => DukkanYonetimPaneli(dukkanId: userData['dukkanId'], dukkanIsmi: "Dükkanım"))); } else { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Dükkan atanmamış!"))); } })
                  );
                }

                if (userData['rol'] == 'superadmin') {
                  adminMenuler.add(
                      ListTile(leading: const Icon(Icons.admin_panel_settings, color: Colors.deepPurple), title: const Text('Süper Admin Paneli', style: TextStyle(color: Colors.deepPurple, fontWeight: FontWeight.bold)), onTap: () { Navigator.pop(context); Navigator.push(context, MaterialPageRoute(builder: (context) => const SuperAdminPaneli())); })
                  );
                }

                return Column(children: adminMenuler);
              },
            ),
            ListTile(leading: const Icon(Icons.logout, color: Colors.red), title: const Text('Çıkış Yap', style: TextStyle(color: Colors.red)), onTap: () => FirebaseAuth.instance.signOut()),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Row(
                children: [
                  Expanded(
                      child: TextField(
                          controller: _searchController,
                          onChanged: (value) => setState(() => aramaMetni = value.toLowerCase()),
                          decoration: InputDecoration(
                            hintText: 'Tamirci, usta veya dükkan ara...',
                            prefixIcon: const Icon(Icons.search, color: Colors.grey),
                            suffixIcon: aramaMetni.isNotEmpty ? IconButton(icon: const Icon(Icons.clear), onPressed: () { _searchController.clear(); setState(() => aramaMetni = ""); }) : null,
                            contentPadding: const EdgeInsets.symmetric(vertical: 0),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            filled: true, fillColor: isDark ? Colors.grey.shade900 : Colors.grey.shade200,
                          )
                      )
                  ),
                  const SizedBox(width: 10),
                  Container(
                    decoration: BoxDecoration(
                        color: (filtreSadeceOnayli || siralamaSecimi != 'varsayilan') ? Colors.blue.shade100 : (isDark ? Colors.grey.shade800 : Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12)
                    ),
                    child: IconButton(
                      icon: Icon(Icons.filter_list, color: (filtreSadeceOnayli || siralamaSecimi != 'varsayilan') ? Colors.blue.shade800 : Colors.grey),
                      onPressed: _filtreMenusuAc,
                    ),
                  )
                ],
              )
          ),
          Container(height: 50, margin: const EdgeInsets.only(bottom: 8), child: ListView.builder(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12), itemCount: kategoriler.length, itemBuilder: (context, index) { final k = kategoriler[index]; bool isSelected = secilenKategori == k; return Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: FilterChip(label: Text(k), selected: isSelected, onSelected: (s) => setState(() => secilenKategori = k), backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white, selectedColor: Theme.of(context).colorScheme.secondary, labelStyle: TextStyle(color: isSelected ? Colors.black : (isDark ? Colors.white : Colors.black87), fontWeight: isSelected ? FontWeight.bold : FontWeight.normal), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey.shade300)), showCheckmark: false)); })),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: secilenKategori == "Tümü" ? FirebaseFirestore.instance.collection('magazalar').snapshots() : FirebaseFirestore.instance.collection('magazalar').where('kategori', isEqualTo: secilenKategori).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text('Hata: ${snapshot.error}'));
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                var filtered = snapshot.data!.docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  bool isimUyuyor = data['isim'].toString().toLowerCase().contains(aramaMetni);
                  bool onayUyuyor = filtreSadeceOnayli ? (data['onayliMi'] == true) : true;
                  return isimUyuyor && onayUyuyor;
                }).toList();

                if (siralamaSecimi == 'puan') {
                  filtered.sort((a, b) => (((b.data() as Map<String, dynamic>)['puan'] ?? 0).toDouble()).compareTo((((a.data() as Map<String, dynamic>)['puan'] ?? 0).toDouble())));
                } else if (siralamaSecimi == 'yorum') {
                  filtered.sort((a, b) => (((b.data() as Map<String, dynamic>)['yorumSayisi'] ?? 0) as int).compareTo((((a.data() as Map<String, dynamic>)['yorumSayisi'] ?? 0) as int)));
                } else if (siralamaSecimi == 'az') {
                  filtered.sort((a, b) => ((a.data() as Map<String, dynamic>)['isim'] ?? '').toString().toLowerCase().compareTo(((b.data() as Map<String, dynamic>)['isim'] ?? '').toString().toLowerCase()));
                } else if (siralamaSecimi == 'za') {
                  filtered.sort((a, b) => ((b.data() as Map<String, dynamic>)['isim'] ?? '').toString().toLowerCase().compareTo(((a.data() as Map<String, dynamic>)['isim'] ?? '').toString().toLowerCase()));
                }

                if (filtered.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.search_off, size: 64, color: Colors.grey.shade400), const SizedBox(height: 10), Text('Sonuç bulunamadı.', style: TextStyle(color: Colors.grey.shade600))]));

                return ListView.builder(
                  itemCount: filtered.length, padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    var data = filtered[index].data() as Map<String, dynamic>;
                    double puan = (data['puan'] ?? 0).toDouble();
                    int yorumSayisi = data['yorumSayisi'] ?? 0;
                    String puanYazisi = puan == 0 ? "Yeni" : "${puan.toStringAsFixed(1)} ($yorumSayisi)";
                    String resimUrl = data['resimUrl'] ?? '';
                    String telefon = data['telefon'] ?? 'Belirtilmemiş';
                    bool onayliMi = data['onayliMi'] ?? false;

                    return GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => DukkanDetayEkrani(docId: filtered[index].id, isim: data['isim'], kategori: data['kategori'], adres: data['adres'], telefon: telefon, puan: puan, resimUrl: resimUrl, onayliMi: onayliMi))),
                      onLongPress: () => _yoneticiIslemleri(filtered[index].id, data),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(color: isDark ? const Color(0xFF1E293B) : Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Stack(
                              children: [
                                ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(16)), child: AkilliResim(url: resimUrl, height: 150)),
                                Positioned(top: 10, right: 10, child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.black.withOpacity(0.7), borderRadius: BorderRadius.circular(8)), child: Row(children: [const Icon(Icons.star, color: Colors.amber, size: 14), const SizedBox(width: 4), Text(puanYazisi, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12))]))),
                              ],
                            ),
                            Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(child: Row(children: [ Flexible(child: Text(data['isim'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis)), if (onayliMi) const Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.verified, color: Colors.blue, size: 18)) ])),
                                    FavoriButonu(dukkanId: filtered[index].id)
                                  ]
                              ),
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
                String telefon = data['telefon'] ?? 'Belirtilmemiş';
                bool onayliMi = data['onayliMi'] ?? false;
                return Card(child: ListTile(
                    leading: const Icon(Icons.store, color: Colors.red),
                    title: Row(children: [Flexible(child: Text(data['isim'], overflow: TextOverflow.ellipsis)), if (onayliMi) const Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.verified, color: Colors.blue, size: 16))]),
                    subtitle: Text(data['kategori']),
                    trailing: FavoriButonu(dukkanId: favoriDukkanlar[index].id),
                    onTap: () { Navigator.push(context, MaterialPageRoute(builder: (context) => DukkanDetayEkrani(docId: favoriDukkanlar[index].id, isim: data['isim'], kategori: data['kategori'], adres: data['adres'], telefon: telefon, puan: (data['puan'] ?? 0).toDouble(), resimUrl: data['resimUrl'] ?? '', onayliMi: onayliMi))); }
                ));
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
  final String docId, isim, kategori, adres, telefon;
  final String resimUrl;
  final double puan;
  final bool onayliMi;

  const DukkanDetayEkrani({super.key, required this.docId, required this.isim, required this.kategori, required this.adres, required this.telefon, required this.puan, required this.resimUrl, required this.onayliMi});

  @override
  State<DukkanDetayEkrani> createState() => _DukkanDetayEkraniState();
}

class _DukkanDetayEkraniState extends State<DukkanDetayEkrani> {
  DateTime? secilenTarih;
  String? secilenSaat;
  bool isSaving = false;
  bool isFetchingHours = false;

  final List<String> tumSaatler = ["09:00", "09:30", "10:00", "10:30", "11:00", "11:30", "12:00", "13:30", "14:00", "14:30", "15:00", "15:30", "16:00", "16:30", "17:00", "17:30"];
  List<String> musaitSaatler = [];

  Future<void> _musaitSaatleriGetir(DateTime tarih) async {
    setState(() { isFetchingHours = true; secilenSaat = null; });
    try {
      String tarihFormat = tarih.toString().split(' ')[0];
      List<String> geciciListe = List.from(tumSaatler);
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('randevular').where('dukkanId', isEqualTo: widget.docId).where('tarih', isEqualTo: tarihFormat).get();
      List<String> doluSaatler = [];
      for (var doc in snapshot.docs) {
        String durum = doc['durum'] ?? '';
        if (durum != 'reddedildi' && durum != 'iptal') doluSaatler.add(doc['saat']);
      }
      geciciListe.removeWhere((saat) => doluSaatler.contains(saat));
      setState(() { musaitSaatler = geciciListe; });
    } catch (e) {
      debugPrint("Saatler çekilirken hata: $e");
    } finally {
      setState(() => isFetchingHours = false);
    }
  }

  Future<void> _randevuOlustur() async {
    if (secilenTarih == null || secilenSaat == null) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen tarih ve saat seçiniz!'), backgroundColor: Colors.red)); return; }
    setState(() => isSaving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      String musteriAd = "Belirtilmemiş", musteriTel = "Belirtilmemiş";
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (userDoc.exists) { musteriAd = userDoc.data()?['adSoyad'] ?? "Belirtilmemiş"; musteriTel = userDoc.data()?['telefon'] ?? "Belirtilmemiş"; }
      }
      await FirebaseFirestore.instance.collection('randevular').add({
        'dukkanId': widget.docId, 'dukkanIsim': widget.isim, 'userId': user?.uid, 'userEmail': user?.email, 'userAdSoyad': musteriAd, 'userTelefon': musteriTel, 'tarih': secilenTarih.toString().split(' ')[0], 'saat': secilenSaat, 'olusturulmaZamani': FieldValue.serverTimestamp(), 'durum': 'bekliyor'
      });
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Randevunuz başarıyla oluşturuldu!'), backgroundColor: Colors.green)); Navigator.pop(context); }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e')));
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  Future<void> _haritadaAc() async {
    final String query = Uri.encodeComponent(widget.adres);
    final Uri url = Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');
    try { if (!await launchUrl(url, mode: LaunchMode.externalApplication)) throw 'Harita başlatılamadı'; } catch (e) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e"))); }
  }

  Future<void> _telefonlaAra() async {
    if (widget.telefon == 'Belirtilmemiş' || widget.telefon.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bu dükkanın kayıtlı bir numarası yok.'))); return; }
    final Uri url = Uri.parse('tel:${widget.telefon}');
    try { if (await canLaunchUrl(url)) { await launchUrl(url); } else { if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Arama başlatılamadı.'))); } } catch (e) { if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Hata: $e'))); }
  }

  void _mesajaGit() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    String chatId = "${user.uid}_${widget.docId}";

    final chatDoc = await FirebaseFirestore.instance.collection('chats').doc(chatId).get();
    if (!chatDoc.exists) {
      String musteriAd = "Müşteri";
      final uDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (uDoc.exists) musteriAd = uDoc.data()?['adSoyad'] ?? "Müşteri";

      await FirebaseFirestore.instance.collection('chats').doc(chatId).set({
        'chatId': chatId,
        'userId': user.uid,
        'dukkanId': widget.docId,
        'kullaniciAd': musteriAd,
        'dukkanAd': widget.isim,
        'sonMesaj': 'Sohbet başlatıldı',
        'sonGuncelleme': FieldValue.serverTimestamp(),
      });
    }
    if (mounted) Navigator.push(context, MaterialPageRoute(builder: (context) => SohbetEkrani(chatId: chatId, karsiTarafIsim: widget.isim, currentUserId: user.uid)));
  }

  Future<void> _ustayaSorDialog() async {
    final aciklamaController = TextEditingController();
    File? secilenResim;
    bool isUploading = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(children: const [Icon(Icons.camera_alt, color: Colors.blue), SizedBox(width: 10), Text("Usta'ya Sor")]),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Aracınızdaki sorunu kısaca anlatın ve varsa fotoğrafını ekleyin. Usta inceleyip size dönüş yapacaktır.", style: TextStyle(fontSize: 13, color: Colors.grey)),
                    const SizedBox(height: 15),
                    TextField(
                      controller: aciklamaController,
                      maxLines: 3,
                      decoration: InputDecoration(labelText: "Sorun nedir? (Örn: Sağ kapıda göçük var)", border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
                    ),
                    const SizedBox(height: 15),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final picker = ImagePicker();
                          final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                          if(pickedFile != null) setState(() => secilenResim = File(pickedFile.path));
                        },
                        icon: Icon(secilenResim == null ? Icons.add_a_photo : Icons.check_circle, color: secilenResim == null ? Colors.blue : Colors.green),
                        label: Text(secilenResim == null ? "Arızanın Fotoğrafını Ekle" : "Fotoğraf Seçildi", style: TextStyle(color: secilenResim == null ? Colors.blue : Colors.green)),
                      ),
                    ),
                    if (secilenResim != null) ...[
                      const SizedBox(height: 10),
                      ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.file(secilenResim!, height: 120, width: double.infinity, fit: BoxFit.cover)),
                    ]
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("İptal")),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                  onPressed: isUploading ? null : () async {
                    if (aciklamaController.text.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen bir açıklama yazın."))); return; }
                    setState(() => isUploading = true);
                    try {
                      String? resimUrl;
                      final user = FirebaseAuth.instance.currentUser;

                      String musteriAd = "Belirtilmemiş";
                      if (user != null) {
                        final uDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
                        if (uDoc.exists) musteriAd = uDoc.data()?['adSoyad'] ?? "Belirtilmemiş";
                      }

                      if (secilenResim != null) {
                        final ref = FirebaseStorage.instance.ref().child('talepler').child('${DateTime.now().millisecondsSinceEpoch}.jpg');
                        await ref.putFile(secilenResim!);
                        resimUrl = await ref.getDownloadURL();
                      }

                      await FirebaseFirestore.instance.collection('talepler').add({
                        'dukkanId': widget.docId,
                        'dukkanIsim': widget.isim,
                        'userId': user?.uid,
                        'userAdSoyad': musteriAd,
                        'aciklama': aciklamaController.text.trim(),
                        'resimUrl': resimUrl,
                        'tarih': FieldValue.serverTimestamp(),
                        'durum': 'bekliyor',
                        'fiyatTeklifi': null,
                      });

                      if(context.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Talebiniz ustaya iletildi!"), backgroundColor: Colors.green));
                      }
                    } catch (e) {
                      if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e")));
                    } finally {
                      setState(() => isUploading = false);
                    }
                  },
                  child: isUploading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text("GÖNDER"),
                )
              ],
            );
          }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
        length: 2,
        child: Scaffold(
            appBar: AppBar(
                title: Row(
                    children: [
                      Flexible(child: Text(widget.isim, overflow: TextOverflow.ellipsis)),
                      if(widget.onayliMi) const Padding(padding: EdgeInsets.only(left: 5), child: Icon(Icons.verified, color: Colors.white, size: 20))
                    ]
                ),
                bottom: const TabBar(
                    labelColor: Colors.amber, unselectedLabelColor: Colors.white70, indicatorColor: Colors.amber, indicatorWeight: 3,
                    tabs: [Tab(text: "Bilgiler & Randevu", icon: Icon(Icons.info_outline)), Tab(text: "Yorumlar", icon: Icon(Icons.comment))]
                ),
                actions: [ FavoriButonu(dukkanId: widget.docId), const SizedBox(width: 10) ]
            ),
            body: TabBarView(
                children: [
                  SingleChildScrollView(
                      child: Column(
                          children: [
                            AkilliResim(url: widget.resimUrl, height: 200),
                            Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(child: Text(widget.isim, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
                                          if (widget.onayliMi) const Padding(padding: EdgeInsets.only(left: 6), child: Icon(Icons.verified, color: Colors.blue, size: 26))
                                        ],
                                      ),
                                      const SizedBox(height: 5),
                                      Text(widget.adres, style: const TextStyle(fontSize: 16)),
                                      const SizedBox(height: 15),

                                      Row(
                                        children: [
                                          Expanded(child: OutlinedButton.icon(onPressed: _haritadaAc, icon: const Icon(Icons.map, color: Colors.blue), label: const Text("YOL TARİFİ"), style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.blue)))),
                                          const SizedBox(width: 10),
                                          Expanded(child: ElevatedButton.icon(onPressed: _telefonlaAra, icon: const Icon(Icons.phone), label: Text(widget.telefon == 'Belirtilmemiş' ? "Numara Yok" : "ARA"), style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white))),
                                        ],
                                      ),

                                      const SizedBox(height: 10),
                                      SizedBox(
                                          width: double.infinity,
                                          child: ElevatedButton.icon(
                                              onPressed: _mesajaGit,
                                              icon: const Icon(Icons.chat),
                                              label: const Text("USTAYA MESAJ GÖNDER"),
                                              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white)
                                          )
                                      ),

                                      const SizedBox(height: 10),

                                      SizedBox(
                                        width: double.infinity,
                                        height: 50,
                                        child: ElevatedButton.icon(
                                          onPressed: _ustayaSorDialog,
                                          icon: const Icon(Icons.build_circle),
                                          label: const Text("USTA'YA SOR (Fotoğraflı Arıza Tespiti)", style: TextStyle(fontWeight: FontWeight.bold)),
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade700, foregroundColor: Colors.white, elevation: 2),
                                        ),
                                      ),

                                      const Divider(height: 30),

                                      const Center(child: Text("Randevu Al", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
                                      const SizedBox(height: 10),

                                      SizedBox(
                                        width: double.infinity,
                                        child: OutlinedButton.icon(
                                            icon: const Icon(Icons.calendar_month),
                                            onPressed: () async {
                                              final t = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 30)));
                                              if(t != null) { setState(() => secilenTarih = t); _musaitSaatleriGetir(t); }
                                            },
                                            label: Text(secilenTarih?.toString().split(' ')[0] ?? "Takvimden Tarih Seçiniz")
                                        ),
                                      ),

                                      const SizedBox(height: 15),

                                      if (secilenTarih != null)
                                        isFetchingHours
                                            ? const Center(child: CircularProgressIndicator())
                                            : musaitSaatler.isEmpty
                                            ? Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)), child: const Text("Bu tarihte alınabilecek müsait randevu saati kalmamıştır.", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold), textAlign: TextAlign.center))
                                            : GridView.builder(
                                          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, childAspectRatio: 2, crossAxisSpacing: 8, mainAxisSpacing: 8),
                                          itemCount: musaitSaatler.length,
                                          itemBuilder: (context, index) {
                                            String saat = musaitSaatler[index]; bool isSelected = secilenSaat == saat;
                                            return ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: isSelected ? Colors.blue : Colors.grey.shade200, foregroundColor: isSelected ? Colors.white : Colors.black87, padding: EdgeInsets.zero), onPressed: () { setState(() { secilenSaat = saat; }); }, child: Text(saat, style: const TextStyle(fontSize: 14)));
                                          },
                                        ),

                                      const SizedBox(height: 25),

                                      SizedBox(width: double.infinity, height: 50, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey.shade900, foregroundColor: Colors.white), onPressed: isSaving ? null : _randevuOlustur, child: isSaving ? const CircularProgressIndicator(color: Colors.white) : const Text("RANDEVUYU ONAYLA")))
                                    ]
                                )
                            ),
                          ]
                      )
                  ),

                  StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('yorumlar').where('dukkanId', isEqualTo: widget.docId).snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("Henüz yorum yapılmamış."));
                        return ListView.builder(
                            padding: const EdgeInsets.all(10), itemCount: snapshot.data!.docs.length,
                            itemBuilder: (context, index) {
                              var yorum = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                              return Card(child: ListTile(leading: CircleAvatar(backgroundColor: Colors.orange.shade100, child: Text(yorum['puan'].toString())), title: Text(yorum['userAdSoyad'] ?? 'Anonim'), subtitle: Text(yorum['yorum'] ?? ''), trailing: const Icon(Icons.star, color: Colors.amber, size: 16)));
                            }
                        );
                      }
                  )
                ]
            )
        )
    );
  }
}

// --- 8. RANDEVULARIM EKRANI ---
class RandevularimEkrani extends StatelessWidget {
  const RandevularimEkrani({super.key});

  void _yorumYapDialog(BuildContext context, String dukkanId, String dukkanIsmi) {
    final yorumController = TextEditingController();
    double puan = 5;
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (context, setState) {
      return AlertDialog(title: Text("$dukkanIsmi Değerlendir"), content: Column(mainAxisSize: MainAxisSize.min, children: [ const Text("Hizmetten memnun kaldınız mı?"), TextField(controller: yorumController, decoration: const InputDecoration(labelText: "Yorumunuz")), const SizedBox(height: 10), const Text("Puanınız (1-5):"), DropdownButton<double>(value: puan, items: [1,2,3,4,5].map((e) => DropdownMenuItem(value: e.toDouble(), child: Text(e.toString()))).toList(), onChanged: (v) { setState(() { puan = v!; }); }) ]), actions: [ TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("İptal")), ElevatedButton(onPressed: () async {
        final user = FirebaseAuth.instance.currentUser;
        if (dukkanId.isEmpty) return;
        await FirebaseFirestore.instance.collection('yorumlar').add({ 'dukkanId': dukkanId, 'userId': user!.uid, 'userAdSoyad': user.email, 'yorum': yorumController.text, 'puan': puan, 'tarih': FieldValue.serverTimestamp() });
        try {
          var yorumlarSnapshot = await FirebaseFirestore.instance.collection('yorumlar').where('dukkanId', isEqualTo: dukkanId).get();
          if (yorumlarSnapshot.docs.isNotEmpty) {
            double toplamPuan = 0;
            for (var doc in yorumlarSnapshot.docs) { toplamPuan += (doc.data()['puan'] as num).toDouble(); }
            double yeniOrtalama = toplamPuan / yorumlarSnapshot.docs.length;
            await FirebaseFirestore.instance.collection('magazalar').doc(dukkanId).update({
              'puan': yeniOrtalama,
              'yorumSayisi': yorumlarSnapshot.docs.length
            });
          }
        } catch (e) { debugPrint("Hata: $e"); }
        Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Yorumunuz eklendi!")));
      }, child: const Text("GÖNDER")) ]); }));
  }

  Future<void> _teklifCevapla(BuildContext context, String talepId, String yeniDurum) async {
    try {
      await FirebaseFirestore.instance.collection('talepler').doc(talepId).update({ 'durum': yeniDurum });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(yeniDurum == 'kabul_edildi' ? "Teklifi kabul ettiniz!" : "Teklifi reddettiniz."),
          backgroundColor: yeniDurum == 'kabul_edildi' ? Colors.green : Colors.red,
        ));
      }
    } catch (e) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return DefaultTabController(
        length: 2,
        child: Scaffold(
            appBar: AppBar(
                title: const Text("İşlemlerim"),
                bottom: const TabBar(
                    indicatorColor: Colors.white, labelColor: Colors.white, unselectedLabelColor: Colors.white70, indicatorWeight: 3,
                    tabs: [ Tab(text: "Randevular", icon: Icon(Icons.calendar_month)), Tab(text: "Arıza Talepleri", icon: Icon(Icons.build_circle)) ]
                )
            ),
            body: TabBarView(
                children: [
                  StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('randevular').where('userId', isEqualTo: user?.uid).snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("Randevu yok."));
                        return ListView.builder(
                            itemCount: snapshot.data!.docs.length, padding: const EdgeInsets.all(12),
                            itemBuilder: (context, index) {
                              var belge = snapshot.data!.docs[index]; var veri = belge.data() as Map<String, dynamic>;
                              String dukkanIsmi = veri['dukkanIsim'] ?? 'Bilinmeyen Dükkan'; String durum = veri['durum'] ?? 'bekliyor';
                              Color durumRenk = Colors.orange; if (durum == 'onaylandi') durumRenk = Colors.green; if (durum == 'reddedildi') durumRenk = Colors.red; if (durum == 'tamamlandi') durumRenk = Colors.blueGrey;
                              return Card(elevation: 3, margin: const EdgeInsets.only(bottom: 12), child: Column(children: [
                                ListTile(leading: Icon(Icons.circle, color: durumRenk), title: Text(dukkanIsmi), subtitle: Text("${veri['tarih']} - ${veri['saat']}\nDurum: ${durum.toUpperCase()}"), trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => FirebaseFirestore.instance.collection('randevular').doc(belge.id).delete())),
                                Padding(padding: const EdgeInsets.only(bottom: 8.0, right: 8.0), child: Wrap(spacing: 10, alignment: WrapAlignment.end, children: [
                                  if (veri['faturaUrl'] != null) OutlinedButton.icon(style: OutlinedButton.styleFrom(foregroundColor: Colors.blue), icon: const Icon(Icons.receipt), label: const Text("FATURAYI GÖR"), onPressed: () { showDialog(context: context, builder: (ctx) => Dialog(child: Column(mainAxisSize: MainAxisSize.min, children: [ AppBar(title: const Text("İşlem Faturası"), automaticallyImplyLeading: false, actions: [IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx))]), Flexible(child: Image.network(veri['faturaUrl'], fit: BoxFit.contain)) ]))); }),
                                  if (durum == 'tamamlandi') ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black), icon: const Icon(Icons.star), label: const Text("YORUM YAP"), onPressed: () => _yorumYapDialog(context, veri['dukkanId'], dukkanIsmi))
                                ]))
                              ]));
                            }
                        );
                      }
                  ),

                  StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance.collection('talepler').where('userId', isEqualTo: user?.uid).snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("Henüz bir talep göndermediniz."));
                        return ListView.builder(
                            itemCount: snapshot.data!.docs.length, padding: const EdgeInsets.all(12),
                            itemBuilder: (context, index) {
                              var doc = snapshot.data!.docs[index]; var veri = doc.data() as Map<String, dynamic>;
                              String durum = veri['durum'] ?? 'bekliyor';
                              Color borderColor = durum == 'cevaplandi' ? Colors.blue : (durum == 'kabul_edildi' ? Colors.green : Colors.orange);

                              return Card(
                                  elevation: 3, margin: const EdgeInsets.only(bottom: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: borderColor, width: 1)),
                                  child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                children: [
                                                  Text(veri['dukkanIsim'] ?? 'Dükkan', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                                  IconButton(
                                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                                    onPressed: () async {
                                                      await FirebaseFirestore.instance.collection('talepler').doc(doc.id).delete();
                                                      if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Talep geçmişinizden silindi.")));
                                                    },
                                                  )
                                                ]
                                            ),
                                            Text("Durum: ${durum.toUpperCase()}", style: TextStyle(color: borderColor, fontWeight: FontWeight.bold, fontSize: 12)),
                                            const Divider(),
                                            Text("Açıklamanız: ${veri['aciklama']}"),
                                            if (durum == 'cevaplandi') ...[
                                              const SizedBox(height: 10),
                                              Container(
                                                width: double.infinity, padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                                                child: Text("Ustanın Teklifi: ${veri['fiyatTeklifi']} TL\nSüre: ${veri['tahminiSure']}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                                              ),
                                              const SizedBox(height: 10),
                                              Row(children: [
                                                Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white), onPressed: () => _teklifCevapla(context, doc.id, 'kabul_edildi'), child: const Text("KABUL ET"))),
                                                const SizedBox(width: 10),
                                                Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), onPressed: () => _teklifCevapla(context, doc.id, 'reddedildi'), child: const Text("REDDET"))),
                                              ])
                                            ]
                                          ]
                                      )
                                  )
                              );
                            }
                        );
                      }
                  )
                ]
            )
        )
    );
  }
}

// --- 9. DÜKKAN YÖNETİM PANELİ ---
class DukkanYonetimPaneli extends StatelessWidget {
  final String dukkanId; final String dukkanIsmi;
  const DukkanYonetimPaneli({super.key, required this.dukkanId, required this.dukkanIsmi});

  Future<void> _durumGuncelle(String docId, String yeniDurum, String userId, String randevuTarihi) async {
    await FirebaseFirestore.instance.collection('randevular').doc(docId).update({'durum': yeniDurum});
    String mesaj = ""; String tur = "";
    if (yeniDurum == 'onaylandi') { mesaj = "$dukkanIsmi, $randevuTarihi tarihindeki randevunuzu onayladı."; tur = "onay"; }
    else if (yeniDurum == 'reddedildi') { mesaj = "$dukkanIsmi, randevunuzu maalesef reddetti."; tur = "red"; }
    else if (yeniDurum == 'tamamlandi') { mesaj = "$dukkanIsmi ile işleminiz tamamlandı. Lütfen değerlendirin."; tur = "tamamlandi"; }
    if (mesaj.isNotEmpty) { await FirebaseFirestore.instance.collection('bildirimler').add({ 'userId': userId, 'baslik': 'Randevu Durumu', 'mesaj': mesaj, 'tur': tur, 'tarih': FieldValue.serverTimestamp(), }); }
  }

  Future<void> _faturaYukleVeTamamla(BuildContext context, String docId, String userId, String randevuTarihi) async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      if(context.mounted) showDialog(context: context, barrierDismissible: false, builder: (ctx) => const Center(child: CircularProgressIndicator()));
      try {
        File imageFile = File(pickedFile.path);
        final storageRef = FirebaseStorage.instance.ref().child('faturalar').child('$docId.jpg');
        await storageRef.putFile(imageFile);
        String downloadUrl = await storageRef.getDownloadURL();
        await FirebaseFirestore.instance.collection('randevular').doc(docId).update({ 'durum': 'tamamlandi', 'faturaUrl': downloadUrl });
        await FirebaseFirestore.instance.collection('bildirimler').add({ 'userId': userId, 'baslik': 'İşlem Tamamlandı ve Fatura Yüklendi', 'mesaj': '$dukkanIsmi ile işleminiz tamamlandı. Faturanızı detaylardan görebilirsiniz.', 'tur': 'tamamlandi', 'tarih': FieldValue.serverTimestamp() });
        if(context.mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("İş tamamlandı ve fatura eklendi!"), backgroundColor: Colors.green)); }
      } catch (e) {
        if(context.mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e"))); }
      }
    }
  }

  void _isiTamamlaSecenekleri(BuildContext context, String docId, String userId, String randevuTarihi) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
        title: const Text("İşi Tamamla"),
        content: const Text("Bu işlemi tamamlamak üzeresiniz. Müşteriye bir fatura veya servis fişi fotoğrafı iletmek ister misiniz?"),
        actions: [
          TextButton(onPressed: () { Navigator.pop(ctx); _durumGuncelle(docId, 'tamamlandi', userId, randevuTarihi); }, child: const Text("Hayır, Sadece Tamamla", style: TextStyle(color: Colors.grey))),
          ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey, foregroundColor: Colors.white), onPressed: () { Navigator.pop(ctx); _faturaYukleVeTamamla(context, docId, userId, randevuTarihi); }, icon: const Icon(Icons.receipt_long), label: const Text("Fiş/Fatura Yükle"))
        ]
    ));
  }

  void _dukkanDuzenleDialog(BuildContext context, String mevcutIsim, String mevcutAdres, String mevcutTelefon, String mevcutKategori, String mevcutResimUrl) {
    final isimController = TextEditingController(text: mevcutIsim);
    final adresController = TextEditingController(text: mevcutAdres);
    final telController = TextEditingController(text: mevcutTelefon);
    final resimController = TextEditingController(text: mevcutResimUrl);
    String kategori = mevcutKategori;
    final List<String> kategoriler = ["Kaporta", "Motor", "Elektrik", "Lastik & Jant", "Yedek Parça", "Boya", "Döşeme"];
    showDialog(context: context, builder: (ctx) => StatefulBuilder(builder: (context, setState) {
      return AlertDialog(title: const Text("Dükkan Bilgilerini Düzenle"), content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: isimController, decoration: const InputDecoration(labelText: "Dükkan İsmi")), const SizedBox(height: 10),
        TextField(controller: adresController, decoration: const InputDecoration(labelText: "Adres")), const SizedBox(height: 10),
        TextField(controller: telController, decoration: const InputDecoration(labelText: "Telefon Numarası", prefixIcon: Icon(Icons.phone))), const SizedBox(height: 10),
        TextField(controller: resimController, decoration: const InputDecoration(labelText: "Resim Yolu (assets/... veya https://...)")), const SizedBox(height: 10),
        const Text("Kategori:"), DropdownButton<String>(value: kategoriler.contains(kategori) ? kategori : kategoriler[0], isExpanded: true, items: kategoriler.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(), onChanged: (v) { setState(() { kategori = v!; }); }), ])),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("İptal")),
            ElevatedButton(onPressed: () async {
              await FirebaseFirestore.instance.collection('magazalar').doc(dukkanId).update({ 'isim': isimController.text.trim(), 'adres': adresController.text.trim(), 'telefon': telController.text.trim(), 'resimUrl': resimController.text.trim(), 'kategori': kategori });
              Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bilgiler güncellendi!")));
            }, child: const Text("KAYDET"))
          ]);
    }));
  }

  void _teklifVerDialog(BuildContext context, String talepId, String userId, String musteriAd) {
    final fiyatController = TextEditingController();
    final sureController = TextEditingController();

    showDialog(context: context, builder: (ctx) => AlertDialog(
        title: const Text("Fiyat Teklifi Ver"),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: fiyatController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Fiyat (TL)", prefixIcon: Icon(Icons.attach_money))),
          const SizedBox(height: 10),
          TextField(controller: sureController, decoration: const InputDecoration(labelText: "Tahmini Süre (Örn: 2 Saat, 1 Gün)", prefixIcon: Icon(Icons.access_time))),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("İptal")),
          ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
              onPressed: () async {
                if(fiyatController.text.isEmpty || sureController.text.isEmpty) return;
                await FirebaseFirestore.instance.collection('talepler').doc(talepId).update({ 'fiyatTeklifi': fiyatController.text.trim(), 'tahminiSure': sureController.text.trim(), 'durum': 'cevaplandi' });
                await FirebaseFirestore.instance.collection('bildirimler').add({ 'userId': userId, 'baslik': 'Arıza Talebinize Teklif Geldi!', 'mesaj': '$dukkanIsmi, fotoğrafını gönderdiğiniz arıza için ${fiyatController.text} TL teklif verdi.', 'tur': 'bilgi', 'tarih': FieldValue.serverTimestamp(), });
                if(context.mounted) { Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Teklif gönderildi!"), backgroundColor: Colors.green)); }
              },
              child: const Text("GÖNDER")
          )
        ]
    ));
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
          String dukkanTelefon = dukkanVerisi['telefon'] ?? '';
          String resimUrl = dukkanVerisi['resimUrl'] ?? '';

          return DefaultTabController(
              length: 3,
              child: Scaffold(
                  appBar: AppBar(
                      title: Text("$dukkanIsmi Paneli"), backgroundColor: Colors.indigo, foregroundColor: Colors.white,
                      actions: [ IconButton(icon: const Icon(Icons.edit), tooltip: "Dükkanı Düzenle", onPressed: () => _dukkanDuzenleDialog(context, dukkanIsmi, dukkanAdres, dukkanTelefon, dukkanKategori, resimUrl)) ],
                      bottom: const TabBar(
                          indicatorColor: Colors.white, labelColor: Colors.white, unselectedLabelColor: Colors.white70, indicatorWeight: 3, labelPadding: EdgeInsets.zero,
                          tabs: [ Tab(text: "Randevular", icon: Icon(Icons.calendar_month)), Tab(text: "Talepler", icon: Icon(Icons.build_circle)), Tab(text: "Mesajlar", icon: Icon(Icons.chat)) ]
                      )
                  ),
                  body: TabBarView(
                      children: [
                        // --- 1. SEKME: RANDEVULAR ---
                        Column(children: [
                          Container(padding: const EdgeInsets.all(15), color: Colors.indigo.shade50, width: double.infinity, child: const Text("Aktif Randevular", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo), textAlign: TextAlign.center)),
                          Expanded(child: StreamBuilder<QuerySnapshot>(stream: FirebaseFirestore.instance.collection('randevular').where('dukkanId', isEqualTo: dukkanId).snapshots(), builder: (context, snapshot) {
                            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("Randevu yok."));
                            var aktifIsler = snapshot.data!.docs.where((doc) { var veri = doc.data() as Map<String, dynamic>; String durum = veri['durum'] ?? ''; return durum == 'bekliyor' || durum == 'onaylandi'; }).toList();
                            if (aktifIsler.isEmpty) { return const Center(child: Text("Şu an bekleyen veya aktif bir işiniz yok. 🎉", style: TextStyle(color: Colors.grey, fontSize: 16))); }
                            return ListView.builder(padding: const EdgeInsets.all(10), itemCount: aktifIsler.length, itemBuilder: (context, index) {
                              var doc = aktifIsler[index]; var veri = doc.data() as Map<String, dynamic>; String durum = veri['durum'] ?? 'bekliyor'; String userId = veri['userId'] ?? ''; String tarih = veri['tarih'] ?? 'Bilinmiyor';
                              return Card(elevation: 3, margin: const EdgeInsets.only(bottom: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: durum == 'bekliyor' ? Colors.orange.withOpacity(0.5) : Colors.green.withOpacity(0.5), width: 1)), child: Padding(padding: const EdgeInsets.all(12.0), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [ Text("${veri['userAdSoyad']}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)), Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: durum == 'bekliyor' ? Colors.orange.shade100 : Colors.green.shade100, borderRadius: BorderRadius.circular(8)), child: Text(durum.toUpperCase(), style: TextStyle(color: durum == 'bekliyor' ? Colors.orange.shade900 : Colors.green.shade900, fontWeight: FontWeight.bold, fontSize: 12))) ]),
                                const SizedBox(height: 5), Row(children: [const Icon(Icons.phone, size: 16, color: Colors.grey), const SizedBox(width: 5), Text("${veri['userTelefon']}")],),
                                const SizedBox(height: 5), Row(children: [const Icon(Icons.calendar_today, size: 16, color: Colors.grey), const SizedBox(width: 5), Text("$tarih - Saat: ${veri['saat']}")],),
                                const Divider(),
                                Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                                  if (durum == 'bekliyor') ...[ ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.green), onPressed: () => _durumGuncelle(doc.id, 'onaylandi', userId, tarih), child: const Text("ONAYLA", style: TextStyle(color: Colors.white))), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () => _durumGuncelle(doc.id, 'reddedildi', userId, tarih), child: const Text("REDDET", style: TextStyle(color: Colors.white))), ],
                                  if (durum == 'onaylandi') Expanded(child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey, padding: const EdgeInsets.symmetric(vertical: 12)), onPressed: () => _isiTamamlaSecenekleri(context, doc.id, userId, tarih), icon: const Icon(Icons.check_circle, color: Colors.white), label: const Text("İŞİ TAMAMLA & LİSTEDEN KALDIR", style: TextStyle(color: Colors.white)))),
                                ])
                              ])));
                            });
                          }))
                        ]),

                        // --- 2. SEKME: GELEN TALEPLER ---
                        StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance.collection('talepler')
                                .where('dukkanId', isEqualTo: dukkanId)
                                .where('durum', isEqualTo: 'bekliyor')
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.hasError) return const Center(child: Text("Bir hata oluştu."));
                              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("Cevap bekleyen yeni bir arıza talebi yok. 🎉", style: TextStyle(color: Colors.grey, fontSize: 16)));

                              return ListView.builder(
                                  padding: const EdgeInsets.all(10),
                                  itemCount: snapshot.data!.docs.length,
                                  itemBuilder: (context, index) {
                                    var doc = snapshot.data!.docs[index];
                                    var veri = doc.data() as Map<String, dynamic>;

                                    return Card(
                                        elevation: 3, margin: const EdgeInsets.only(bottom: 12),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.orange, width: 1)),
                                        child: Padding(
                                            padding: const EdgeInsets.all(16),
                                            child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Row(
                                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                      children: [
                                                        Expanded(child: Text(veri['userAdSoyad'] ?? 'Müşteri', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
                                                        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(8)), child: const Text("BEKLİYOR", style: TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold, fontSize: 12))),
                                                      ]
                                                  ),
                                                  const Divider(),
                                                  Text(veri['aciklama'] ?? 'Açıklama yok', style: const TextStyle(fontSize: 15)),
                                                  const SizedBox(height: 10),

                                                  if (veri['resimUrl'] != null)
                                                    OutlinedButton.icon(
                                                        onPressed: () { showDialog(context: context, builder: (ctx) => Dialog(child: Column(mainAxisSize: MainAxisSize.min, children: [ AppBar(title: const Text("Arıza Görseli"), automaticallyImplyLeading: false, actions: [IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx))]), Flexible(child: Image.network(veri['resimUrl'], fit: BoxFit.contain)) ]))); },
                                                        icon: const Icon(Icons.image, color: Colors.blue), label: const Text("Fotoğrafı İncele")
                                                    ),

                                                  const SizedBox(height: 10),
                                                  SizedBox(
                                                      width: double.infinity,
                                                      child: ElevatedButton.icon(
                                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                                                          onPressed: () => _teklifVerDialog(context, doc.id, veri['userId'], veri['userAdSoyad']),
                                                          icon: const Icon(Icons.local_offer), label: const Text("FİYAT TEKLİFİ VER")
                                                      )
                                                  )
                                                ]
                                            )
                                        )
                                    );
                                  }
                              );
                            }
                        ),

                        // --- 3. SEKME: DÜKKAN MESAJLARI ---
                        StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance.collection('chats').where('dukkanId', isEqualTo: dukkanId).orderBy('sonGuncelleme', descending: true).snapshots(),
                            builder: (context, snapshot) {
                              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("Henüz mesajınız yok."));
                              return ListView.builder(
                                  itemCount: snapshot.data!.docs.length,
                                  itemBuilder: (context, index) {
                                    var chatData = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                                    return ListTile(
                                      leading: const CircleAvatar(backgroundColor: Colors.indigo, child: Icon(Icons.person, color: Colors.white)),
                                      title: Text(chatData['kullaniciAd'] ?? 'Müşteri', style: const TextStyle(fontWeight: FontWeight.bold)),
                                      subtitle: Text(chatData['sonMesaj'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                                      trailing: IconButton(
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        onPressed: () {
                                          showDialog(
                                              context: context,
                                              builder: (ctx) => AlertDialog(
                                                  title: const Text("Sohbeti Sil"),
                                                  content: const Text("Bu sohbeti tamamen silmek istediğinize emin misiniz?"),
                                                  actions: [
                                                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("İptal")),
                                                    ElevatedButton(
                                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                                        onPressed: () async {
                                                          await FirebaseFirestore.instance.collection('chats').doc(chatData['chatId']).delete();
                                                          if(context.mounted) Navigator.pop(ctx);
                                                        },
                                                        child: const Text("SİL")
                                                    )
                                                  ]
                                              )
                                          );
                                        },
                                      ),
                                      onTap: () {
                                        final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                                        if(currentUserId != null) {
                                          Navigator.push(context, MaterialPageRoute(builder: (context) => SohbetEkrani(chatId: chatData['chatId'], karsiTarafIsim: chatData['kullaniciAd'], currentUserId: currentUserId)));
                                        }
                                      },
                                    );
                                  }
                              );
                            }
                        )
                      ]
                  )
              )
          );
        }
    );
  }
}

// --- 10. HAKKIMIZDA EKRANI ---
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

// --- 11. KULLANICI MESAJLARI EKRANI ---
class KullaniciMesajlariEkrani extends StatelessWidget {
  const KullaniciMesajlariEkrani({super.key});
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox();

    return Scaffold(
      appBar: AppBar(title: const Text("Mesajlarım")),
      body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('chats').where('userId', isEqualTo: user.uid).orderBy('sonGuncelleme', descending: true).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey), SizedBox(height: 10), Text("Henüz kimseyle mesajlaşmadınız.")]));

            return ListView.builder(
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  var chatData = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                  return Card(
                    elevation: 1, margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: ListTile(
                      leading: const CircleAvatar(backgroundColor: Colors.blue, child: Icon(Icons.store, color: Colors.white)),
                      title: Text(chatData['dukkanAd'] ?? 'Dükkan', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(chatData['sonMesaj'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                  title: const Text("Sohbeti Sil"),
                                  content: const Text("Bu sohbeti tamamen silmek istediğinize emin misiniz?"),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("İptal")),
                                    ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                        onPressed: () async {
                                          await FirebaseFirestore.instance.collection('chats').doc(chatData['chatId']).delete();
                                          if(context.mounted) Navigator.pop(ctx);
                                        },
                                        child: const Text("SİL")
                                    )
                                  ]
                              )
                          );
                        },
                      ),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => SohbetEkrani(chatId: chatData['chatId'], karsiTarafIsim: chatData['dukkanAd'], currentUserId: user.uid)));
                      },
                    ),
                  );
                }
            );
          }
      ),
    );
  }
}

// --- 12. AKTİF SOHBET EKRANI ---
class SohbetEkrani extends StatefulWidget {
  final String chatId;
  final String karsiTarafIsim;
  final String currentUserId;

  const SohbetEkrani({super.key, required this.chatId, required this.karsiTarafIsim, required this.currentUserId});
  @override
  State<SohbetEkrani> createState() => _SohbetEkraniState();
}

class _SohbetEkraniState extends State<SohbetEkrani> {
  final TextEditingController _mesajController = TextEditingController();

  void _mesajGonder() async {
    if (_mesajController.text.trim().isEmpty) return;
    String mesaj = _mesajController.text.trim();
    _mesajController.clear();

    await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).collection('mesajlar').add({
      'gonderenId': widget.currentUserId,
      'mesaj': mesaj,
      'zaman': FieldValue.serverTimestamp(),
    });

    await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).update({
      'sonMesaj': mesaj,
      'sonGuncelleme': FieldValue.serverTimestamp(),
    });
  }

  void _mesajSilOnayi(String mesajId) {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Mesajı Sil"),
          content: const Text("Bu mesajı silmek istediğinize emin misiniz? (Karşı taraftan da silinir)"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("İptal")),
            ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                onPressed: () async {
                  await FirebaseFirestore.instance.collection('chats').doc(widget.chatId).collection('mesajlar').doc(mesajId).delete();
                  if(context.mounted) Navigator.pop(ctx);
                },
                child: const Text("SİL")
            )
          ],
        )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.karsiTarafIsim)),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('chats').doc(widget.chatId).collection('mesajlar').orderBy('zaman', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                return ListView.builder(
                  reverse: true,
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var doc = snapshot.data!.docs[index];
                    bool isMe = doc['gonderenId'] == widget.currentUserId;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: GestureDetector(
                        onLongPress: () {
                          if (isMe) {
                            _mesajSilOnayi(doc.id);
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isMe ? Colors.blue : Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(16).copyWith(
                                bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(16),
                                bottomLeft: !isMe ? const Radius.circular(0) : const Radius.circular(16)
                            ),
                          ),
                          child: Text(doc['mesaj'], style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 15)),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, -2))]),
            child: Row(
              children: [
                Expanded(
                    child: TextField(
                      controller: _mesajController,
                      decoration: InputDecoration(
                          hintText: "Mesaj yazın...",
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                          filled: true, fillColor: Colors.grey.withOpacity(0.1),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)
                      ),
                    )
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: IconButton(icon: const Icon(Icons.send, color: Colors.white, size: 20), onPressed: _mesajGonder),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}

// --- 13. SÜPER ADMİN PANELİ ---
class SuperAdminPaneli extends StatefulWidget {
  const SuperAdminPaneli({super.key});

  @override
  State<SuperAdminPaneli> createState() => _SuperAdminPaneliState();
}

class _SuperAdminPaneliState extends State<SuperAdminPaneli> {

  Future<Map<String, int>> _istatistikleriGetir() async {
    final firestore = FirebaseFirestore.instance;
    final users = await firestore.collection('users').get();
    final dukkanlar = await firestore.collection('magazalar').get();
    final randevular = await firestore.collection('randevular').get();
    final talepler = await firestore.collection('talepler').get();
    return {'users': users.docs.length, 'magazalar': dukkanlar.docs.length, 'randevular': randevular.docs.length, 'talepler': talepler.docs.length};
  }

  void _topluDuyuruGonder(BuildContext context) {
    final baslikController = TextEditingController();
    final mesajController = TextEditingController();
    bool isSending = false;

    showDialog(
        context: context, barrierDismissible: false,
        builder: (ctx) => StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                  title: const Row(children: [Icon(Icons.campaign, color: Colors.deepPurple, size: 28), SizedBox(width: 10), Text("Toplu Duyuru Gönder", style: TextStyle(fontSize: 18))]),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text("Yazdığınız mesaj sistemdeki TÜM kullanıcılara bildirim olarak gidecektir.", style: TextStyle(fontSize: 13, color: Colors.grey)),
                      const SizedBox(height: 15),
                      TextField(controller: baslikController, decoration: InputDecoration(labelText: "Duyuru Başlığı", border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
                      const SizedBox(height: 10),
                      TextField(controller: mesajController, maxLines: 3, decoration: InputDecoration(labelText: "Mesajınız", border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
                    ],
                  ),
                  actions: [
                    if (!isSending) TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("İptal", style: TextStyle(color: Colors.grey))),
                    ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
                        onPressed: isSending ? null : () async {
                          if(baslikController.text.isEmpty || mesajController.text.isEmpty) return;
                          setState(() => isSending = true);
                          try {
                            final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();
                            List<Future> islemler = [];
                            for(var userDoc in usersSnapshot.docs) { islemler.add(FirebaseFirestore.instance.collection('bildirimler').add({'userId': userDoc.id, 'baslik': baslikController.text.trim(), 'mesaj': mesajController.text.trim(), 'tur': 'bilgi', 'tarih': FieldValue.serverTimestamp()})); }
                            await Future.wait(islemler);
                            if(ctx.mounted) { Navigator.pop(ctx); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Duyuru başarıyla ${usersSnapshot.docs.length} kullanıcıya gönderildi!"), backgroundColor: Colors.green)); }
                          } catch(e) { if(ctx.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e"))); } finally { setState(() => isSending = false); }
                        },
                        child: isSending ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text("HERKESE GÖNDER")
                    )
                  ]
              );
            }
        )
    );
  }

  Widget _istatistikKutusu(String baslik, String deger, IconData ikon, Color renk) {
    return Card(
      elevation: 5, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), gradient: LinearGradient(colors: [renk.withOpacity(0.7), renk], begin: Alignment.topLeft, end: Alignment.bottomRight)),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(ikon, color: Colors.white, size: 36), const SizedBox(height: 10),
            Text(deger, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)), const SizedBox(height: 5),
            Text(baslik, style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Future<void> _yorumSilVePuanGuncelle(String yorumId, String dukkanId) async {
    try {
      await FirebaseFirestore.instance.collection('yorumlar').doc(yorumId).delete();
      var yorumlarSnapshot = await FirebaseFirestore.instance.collection('yorumlar').where('dukkanId', isEqualTo: dukkanId).get();
      double yeniOrtalama = 0;
      if (yorumlarSnapshot.docs.isNotEmpty) {
        double toplamPuan = 0;
        for (var doc in yorumlarSnapshot.docs) { toplamPuan += (doc.data()['puan'] as num).toDouble(); }
        yeniOrtalama = toplamPuan / yorumlarSnapshot.docs.length;
      }
      if(dukkanId.isNotEmpty) { await FirebaseFirestore.instance.collection('magazalar').doc(dukkanId).update({
        'puan': yeniOrtalama,
        'yorumSayisi': yorumlarSnapshot.docs.length // Yorum silinince sayıyı da güncelle
      }); }
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Yorum başarıyla silindi ve dükkan puanı güncellendi."), backgroundColor: Colors.green));
    } catch(e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e")));
    }
  }

  void _yoneticiYapVeDukkanAta(BuildContext context, String userId, String kullaniciAdi) {
    showDialog(
        context: context,
        builder: (ctx) => FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance.collection('magazalar').get(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const AlertDialog(content: SizedBox(height: 100, child: Center(child: CircularProgressIndicator())));
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return AlertDialog(title: const Text("Hata"), content: const Text("Sistemde kayıtlı dükkan bulunamadı. Önce bir dükkan eklemelisiniz."), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Tamam"))]);

              String seciliDukkanId = snapshot.data!.docs.first.id;

              return StatefulBuilder(
                  builder: (context, setState) {
                    return AlertDialog(
                      title: const Text("Dükkan Ata", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("$kullaniciAdi isimli kişiyi hangi dükkanın yöneticisi yapmak istiyorsunuz?", style: const TextStyle(fontSize: 14)),
                          const SizedBox(height: 20),
                          DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: seciliDukkanId,
                            decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                            items: snapshot.data!.docs.map((doc) {
                              var data = doc.data() as Map<String, dynamic>;
                              return DropdownMenuItem<String>(
                                value: doc.id,
                                child: Text(data['isim'] ?? 'İsimsiz Dükkan', overflow: TextOverflow.ellipsis),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() { seciliDukkanId = val; });
                            },
                          )
                        ],
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("İptal", style: TextStyle(color: Colors.grey))),
                        ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                            onPressed: () async {
                              await FirebaseFirestore.instance.collection('users').doc(userId).update({
                                'rol': 'yonetici',
                                'dukkanId': seciliDukkanId,
                              });
                              if (context.mounted) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Kullanıcı başarıyla dükkan yöneticisi yapıldı!"), backgroundColor: Colors.green));
                              }
                            },
                            child: const Text("ONAYLA VE ATA")
                        )
                      ],
                    );
                  }
              );
            }
        )
    );
  }

  void _dukkanEkleDialog(BuildContext context) {
    final isimC = TextEditingController();
    final adresC = TextEditingController();
    final telC = TextEditingController();
    final resimC = TextEditingController();
    String seciliKategori = "Kaporta";
    final List<String> kategoriler = ["Kaporta", "Motor", "Elektrik", "Lastik & Jant", "Yedek Parça", "Boya", "Döşeme"];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (context, setState) {
        return AlertDialog(
          title: const Text("Yeni Dükkan Ekle", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: isimC, decoration: const InputDecoration(labelText: "Dükkan İsmi", prefixIcon: Icon(Icons.store))),
                const SizedBox(height: 10),
                TextField(controller: adresC, decoration: const InputDecoration(labelText: "Adres", prefixIcon: Icon(Icons.location_on))),
                const SizedBox(height: 10),
                TextField(controller: telC, decoration: const InputDecoration(labelText: "Telefon", prefixIcon: Icon(Icons.phone))),
                const SizedBox(height: 10),
                TextField(controller: resimC, decoration: const InputDecoration(labelText: "Resim Yolu (assets/... veya https://...)", prefixIcon: Icon(Icons.image))),
                const SizedBox(height: 15),
                const Text("Kategori Seçin:", style: TextStyle(fontSize: 12, color: Colors.grey)),
                DropdownButton<String>(
                  isExpanded: true,
                  value: seciliKategori,
                  items: kategoriler.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) => setState(() => seciliKategori = v!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("İptal")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white),
              onPressed: () async {
                if (isimC.text.isEmpty || adresC.text.isEmpty) return;

                await FirebaseFirestore.instance.collection('magazalar').add({
                  'isim': isimC.text.trim(),
                  'adres': adresC.text.trim(),
                  'telefon': telC.text.trim(),
                  'resimUrl': resimC.text.trim(),
                  'kategori': seciliKategori,
                  'puan': 0,
                  'yorumSayisi': 0, // YENİ DÜKKAN İÇİN SIFIRDAN BAŞLAR
                  'onayliMi': true,
                });

                if (context.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Yeni dükkan başarıyla eklendi!"), backgroundColor: Colors.green));
                }
              },
              child: const Text("KAYDET"),
            )
          ],
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
          appBar: AppBar(
              title: const Text("Süper Admin Paneli", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              backgroundColor: Colors.deepPurple, foregroundColor: Colors.white,
              bottom: const TabBar(
                  isScrollable: true, indicatorColor: Colors.white, labelColor: Colors.white, unselectedLabelColor: Colors.white70, indicatorWeight: 3, tabAlignment: TabAlignment.start,
                  tabs: [
                    Tab(text: "Dashboard", icon: Icon(Icons.dashboard)),
                    Tab(text: "Mavi Tik", icon: Icon(Icons.verified)),
                    Tab(text: "Kullanıcılar", icon: Icon(Icons.people)),
                    Tab(text: "Denetim", icon: Icon(Icons.admin_panel_settings)),
                  ]
              )
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _dukkanEkleDialog(context),
            backgroundColor: Colors.deepPurple,
            tooltip: "Yeni Dükkan Ekle",
            child: const Icon(Icons.add_business, color: Colors.white),
          ),
          body: TabBarView(
            children: [
              // --- 1. SEKME: DASHBOARD ---
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Sistem İstatistikleri", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.deepPurple)),
                    const SizedBox(height: 15),
                    FutureBuilder<Map<String, int>>(
                        future: _istatistikleriGetir(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator(color: Colors.deepPurple)));
                          if (snapshot.hasError) return Text("Hata: ${snapshot.error}");
                          final veriler = snapshot.data!;
                          return GridView.count(
                            crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisSpacing: 12, mainAxisSpacing: 12,
                            children: [
                              _istatistikKutusu("Kullanıcılar", veriler['users'].toString(), Icons.people, Colors.blue),
                              _istatistikKutusu("Dükkanlar", veriler['magazalar'].toString(), Icons.store, Colors.orange),
                              _istatistikKutusu("Randevular", veriler['randevular'].toString(), Icons.calendar_month, Colors.green),
                              _istatistikKutusu("Talepler", veriler['talepler'].toString(), Icons.build_circle, Colors.red),
                            ],
                          );
                        }
                    ),
                    const SizedBox(height: 30), const Divider(thickness: 2), const SizedBox(height: 20),
                    Container(
                      width: double.infinity, padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.deepPurple.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.deepPurple.shade200)),
                      child: Column(
                        children: [
                          const Icon(Icons.campaign, size: 50, color: Colors.deepPurple), const SizedBox(height: 10),
                          const Text("Toplu Bildirim Sistemi", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.deepPurple)), const SizedBox(height: 5),
                          const Text("Tüm kullanıcılara aynı anda anlık bildirim gönderin.", textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)), const SizedBox(height: 15),
                          SizedBox(width: double.infinity, height: 45, child: ElevatedButton.icon(style: ElevatedButton.styleFrom(backgroundColor: Colors.deepPurple, foregroundColor: Colors.white), onPressed: () => _topluDuyuruGonder(context), icon: const Icon(Icons.send), label: const Text("YENİ DUYURU OLUŞTUR", style: TextStyle(fontWeight: FontWeight.bold))))
                        ],
                      ),
                    )
                  ],
                ),
              ),

              // --- 2. SEKME: MAVİ TİK ---
              StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('magazalar').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("Kayıtlı dükkan yok."));
                    return ListView.builder(
                        padding: const EdgeInsets.all(12), itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          var doc = snapshot.data!.docs[index]; var data = doc.data() as Map<String, dynamic>; bool onayliMi = data['onayliMi'] ?? false;
                          return Card(
                            elevation: 2, margin: const EdgeInsets.only(bottom: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: onayliMi ? Colors.blue.shade300 : Colors.transparent, width: 2)),
                            child: ListTile(
                              leading: CircleAvatar(backgroundColor: onayliMi ? Colors.blue.shade100 : Colors.grey.shade200, child: Icon(Icons.store, color: onayliMi ? Colors.blue : Colors.grey)),
                              title: Row(children: [Flexible(child: Text(data['isim'], style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)), if(onayliMi) const Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.verified, color: Colors.blue, size: 18))]),
                              subtitle: Text("Kategori: ${data['kategori']}"),
                              trailing: Switch(
                                value: onayliMi, activeColor: Colors.blue,
                                onChanged: (val) async {
                                  await FirebaseFirestore.instance.collection('magazalar').doc(doc.id).update({'onayliMi': val});
                                  if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(val ? "${data['isim']} onaylandı ve Mavi Tik verildi!" : "${data['isim']} onayı kaldırıldı."), backgroundColor: val ? Colors.green : Colors.orange));
                                },
                              ),
                            ),
                          );
                        }
                    );
                  }
              ),

              // --- 3. SEKME: KULLANICI VE ROL YÖNETİMİ ---
              StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('users').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("Kayıtlı kullanıcı yok."));
                    return ListView.builder(
                        padding: const EdgeInsets.all(12), itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          var doc = snapshot.data!.docs[index]; var data = doc.data() as Map<String, dynamic>;
                          String rol = data['rol'] ?? 'kullanici';
                          bool isBanned = data['isBanned'] ?? false;
                          bool isMe = doc.id == currentUserId;
                          String kullaniciAd = data['adSoyad'] ?? data['email'] ?? 'İsimsiz Kullanıcı';

                          return Card(
                            color: isBanned ? Colors.red.shade50 : Colors.white,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: ListTile(
                                leading: CircleAvatar(backgroundColor: isBanned ? Colors.red : Colors.blueGrey, child: Icon(isBanned ? Icons.block : Icons.person, color: Colors.white)),
                                title: Text(kullaniciAd, style: TextStyle(fontWeight: FontWeight.bold, decoration: isBanned ? TextDecoration.lineThrough : null)),
                                subtitle: Text("Email: ${data['email']}\nRol: ${rol.toUpperCase()}"),
                                isThreeLine: true,
                                trailing: isMe ? const Text("SENSİN", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepPurple)) : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    PopupMenuButton<String>(
                                      icon: const Icon(Icons.manage_accounts, color: Colors.blue),
                                      onSelected: (yeniRol) async {
                                        if (yeniRol == 'yonetici') {
                                          _yoneticiYapVeDukkanAta(context, doc.id, kullaniciAd);
                                        } else {
                                          await FirebaseFirestore.instance.collection('users').doc(doc.id).update({
                                            'rol': yeniRol,
                                            'dukkanId': FieldValue.delete()
                                          });
                                          if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Rol başarıyla güncellendi.")));
                                        }
                                      },
                                      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                        const PopupMenuItem<String>(value: 'kullanici', child: Text('Normal Kullanıcı Yap')),
                                        const PopupMenuItem<String>(value: 'yonetici', child: Text('Dükkan Yöneticisi Yap')),
                                        const PopupMenuItem<String>(value: 'superadmin', child: Text('Süper Admin Yap')),
                                      ],
                                    ),
                                    IconButton(
                                      icon: Icon(isBanned ? Icons.check_circle : Icons.block, color: isBanned ? Colors.green : Colors.red),
                                      onPressed: () async {
                                        await FirebaseFirestore.instance.collection('users').doc(doc.id).update({'isBanned': !isBanned});
                                        if(context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(!isBanned ? "Kullanıcı banlandı!" : "Kullanıcının banı açıldı."), backgroundColor: !isBanned ? Colors.red : Colors.green));
                                      },
                                    )
                                  ],
                                ),
                              ),
                            ),
                          );
                        }
                    );
                  }
              ),

              // --- 4. SEKME: YORUM DENETİM MERKEZİ ---
              StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('yorumlar').orderBy('tarih', descending: true).snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("Sistemde hiç yorum yok."));
                    return ListView.builder(
                        padding: const EdgeInsets.all(12), itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          var doc = snapshot.data!.docs[index]; var data = doc.data() as Map<String, dynamic>;
                          String dukkanId = data['dukkanId'] ?? '';

                          return Card(
                            elevation: 2,
                            child: ListTile(
                              leading: CircleAvatar(backgroundColor: Colors.amber, child: Text(data['puan'].toString(), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
                              title: Text(data['userAdSoyad'] ?? 'Anonim', style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('"${data['yorum'] ?? 'Yorumsuz'}"', style: const TextStyle(fontStyle: FontStyle.italic)),
                              trailing: IconButton(
                                  icon: const Icon(Icons.delete_forever, color: Colors.red),
                                  onPressed: () {
                                    showDialog(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                            title: const Text("Yorumu Sil"),
                                            content: const Text("Bu yorumu sistemden silmek istediğinize emin misiniz? (Dükkanın puanı da otomatik olarak yeniden hesaplanacaktır)"),
                                            actions: [
                                              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("İptal")),
                                              ElevatedButton(
                                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                                  onPressed: () {
                                                    Navigator.pop(ctx);
                                                    _yorumSilVePuanGuncelle(doc.id, dukkanId);
                                                  },
                                                  child: const Text("SİL")
                                              )
                                            ]
                                        )
                                    );
                                  }
                              ),
                            ),
                          );
                        }
                    );
                  }
              )
            ],
          )
      ),
    );
  }
}