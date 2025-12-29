import 'package:flutter/material.dart';

void main() {
  runApp(const SanayiRehberiApp());
}

// --- 1. ANA UYGULAMA YAPISI ---
class SanayiRehberiApp extends StatelessWidget {
  const SanayiRehberiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sanayi Rehberi',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        useMaterial3: true,
      ),
      home: const MagazaListesiEkrani(),
    );
  }
}

// --- 2. VERİ MODELİ (DATABASE YERİNE GEÇEN YAPI) ---
class Dukkan {
  final String id;
  final String isim;
  final String kategori; // Örn: Kaporta, Motor, Elektrik
  final double puan;
  final String adres;
  final String imageUrl; // Gerçekte URL olacak, şimdilik placeholder

  Dukkan({
    required this.id,
    required this.isim,
    required this.kategori,
    required this.puan,
    required this.adres,
    required this.imageUrl,
  });
}

// --- 3. SAHTE VERİLER (FIREBASE YERİNE) ---
final List<Dukkan> ornekDukkanlar = [
  Dukkan(id: '1', isim: 'Yılmaz Oto Elektrik', kategori: 'Elektrik', puan: 4.5, adres: 'A Blok No:12', imageUrl: 'https://via.placeholder.com/150'),
  Dukkan(id: '2', isim: 'Şahin Motor Yenileme', kategori: 'Motor', puan: 4.8, adres: 'C Blok No:45', imageUrl: 'https://via.placeholder.com/150'),
  Dukkan(id: '3', isim: 'Demir Kaporta Boya', kategori: 'Kaporta', puan: 3.9, adres: 'B Blok No:22', imageUrl: 'https://via.placeholder.com/150'),
  Dukkan(id: '4', isim: 'Antalya Yedek Parça', kategori: 'Yedek Parça', puan: 5.0, adres: 'Giriş Kat No:1', imageUrl: 'https://via.placeholder.com/150'),
];

// --- 4. ANA EKRAN: DÜKKAN LİSTESİ ---
class MagazaListesiEkrani extends StatelessWidget {
  const MagazaListesiEkrani({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sanayi Rehberi'),
        centerTitle: true,
        backgroundColor: Colors.blueGrey.shade800,
        foregroundColor: Colors.white,
      ),
      body: ListView.builder(
        itemCount: ornekDukkanlar.length,
        padding: const EdgeInsets.all(10),
        itemBuilder: (context, index) {
          final dukkan = ornekDukkanlar[index];
          return Card(
            elevation: 4,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blueGrey.shade100,
                child: Icon(Icons.build, color: Colors.blueGrey.shade700),
              ),
              title: Text(dukkan.isim, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${dukkan.kategori} - Puan: ${dukkan.puan}'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // Detay sayfasına git
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DukkanDetayEkrani(dukkan: dukkan),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// --- 5. DETAY EKRANI: RANDEVU VE PUANLAMA ---
class DukkanDetayEkrani extends StatefulWidget {
  final Dukkan dukkan;

  const DukkanDetayEkrani({super.key, required this.dukkan});

  @override
  State<DukkanDetayEkrani> createState() => _DukkanDetayEkraniState();
}

class _DukkanDetayEkraniState extends State<DukkanDetayEkrani> {
  DateTime? secilenTarih;
  TimeOfDay? secilenSaat;
  double kullaniciPuani = 0;

  // Tarih Seçici
  Future<void> _tarihSec(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null && picked != secilenTarih) {
      setState(() {
        secilenTarih = picked;
      });
    }
  }

  // Saat Seçici
  Future<void> _saatSec(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null && picked != secilenSaat) {
      setState(() {
        secilenSaat = picked;
      });
    }
  }

  // Randevu Kaydetme Simülasyonu
  void _randevuOlustur() {
    if (secilenTarih != null && secilenSaat != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.dukkan.isim} için randevu oluşturuldu!\nTarih: ${secilenTarih.toString().split(' ')[0]} Saat: ${secilenSaat!.format(context)}'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen tarih ve saat seçiniz!'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.dukkan.isim)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Dükkan Görseli (Temsili Renkli Kutu)
            Container(
              height: 200,
              color: Colors.blueGrey.shade200,
              child: const Center(child: Icon(Icons.store, size: 80, color: Colors.white)),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.dukkan.isim, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text("Kategori: ${widget.dukkan.kategori}", style: const TextStyle(fontSize: 16, color: Colors.grey)),
                  Text("Adres: ${widget.dukkan.adres}", style: const TextStyle(fontSize: 16, color: Colors.grey)),

                  const Divider(height: 30),

                  // --- Puanlama Bölümü ---
                  const Text("Dükkanı Puanla", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Row(
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < kullaniciPuani ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                          size: 32,
                        ),
                        onPressed: () {
                          setState(() {
                            kullaniciPuani = index + 1.0;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text("Puanınız ($kullaniciPuani) kaydedildi!")),
                          );
                        },
                      );
                    }),
                  ),

                  const Divider(height: 30),

                  // --- Randevu Bölümü ---
                  const Text("Randevu Al", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _tarihSec(context),
                          icon: const Icon(Icons.calendar_today),
                          label: Text(secilenTarih == null ? 'Tarih Seç' : secilenTarih.toString().split(' ')[0]),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _saatSec(context),
                          icon: const Icon(Icons.access_time),
                          label: Text(secilenSaat == null ? 'Saat Seç' : secilenSaat!.format(context)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueGrey.shade800,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      onPressed: _randevuOlustur,
                      child: const Text("RANDEVUYU ONAYLA", style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}