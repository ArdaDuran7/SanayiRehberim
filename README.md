# 🛠️ Sanayi Rehberim

**Konum Tabanlı Sanayi Esnafı Rehber Uygulaması**

> BPR 216 – Yazılım Geliştirme Projesi | Final Raporu  
> **Hazırlayan:** Arda Duran | **Öğrenci No:** 240053017  
> **Danışman:** Öğr. Gör. Hüseyin Umut Yüksel  
> **Dönem:** 2025 – 2026 Bahar | **Tarih:** 03.06.2026  
> **Okul:** Alanya Üniversitesi Meslek Yüksekokulu – Bilgisayar Programcılığı

---

## 📖 Proje Tanımı

**Sanayi Rehberim**, Türkiye'deki sanayi sitelerinde usta bulmakta zorlanan vatandaşlara yönelik konum tabanlı bir mobil uygulamadır. Kullanıcılar siteleri fiziksel gezmeden kategori filtresi ve arama ile en yakın, en yüksek puanlı esnafı bulabilmektedir.

Uygulama; **randevu**, **mesajlaşma**, **fotoğraflı arıza tespiti**, **puan/yorum** ve **esnaf yönetim panelini** tek çatı altında sunarken **Süper Admin Paneli** ile platform yönetimini merkezi hale getirmektedir.

---

## 🚀 Özellikler

| Özellik | Açıklama |
|---------|----------|
| 🔐 **Rol Bazlı Kimlik Doğrulama** | Firebase Auth ile e-posta/şifre + Google Sign-In. Müşteri / Esnaf / Süper Admin rolleri |
| 🔍 **Kategori Filtresi & Arama** | Kaporta, Motor, Elektrik, Lastik, Boya — StreamBuilder ile gerçek zamanlı listeleme |
| 📅 **Randevu Sistemi** | Tarih/saat seçimi, durum takibi (Bekliyor / Onaylandı / Reddedildi / Tamamlandı) |
| ⭐ **Yorum & Puan** | 1–5 yıldız değerlendirme; ortalama puan Firestore'da anlık güncelleme |
| 💬 **Mesajlaşma** | Müşteri–esnaf arası doğrudan mesaj kanalı |
| 📸 **Fotoğraflı Arıza Tespiti** | "Ustaya Sor" butonu ile arızalı parçanın uzaktan ön değerlendirmesi |
| ✅ **Mavi Tik Sistemi** | Süper admin tarafından onaylanan dükkanlara mavi doğrulama rozeti |
| 🛡️ **Süper Admin Paneli** | Dashboard istatistikleri, mavi tik yönetimi, kullanıcı listesi, toplu bildirim |
| 🌗 **Karanlık / Aydınlık Tema** | Material 3 + google_fonts ile tam tema desteği |
| 🗺️ **Google Maps Entegrasyonu** | Seçilen dükkana doğrudan navigasyon yönlendirmesi |
| 👤 **Profil Fotoğrafı** | Firebase Storage ile galeri entegrasyonu ve fotoğraf yükleme |
| 🗑️ **Hesap Silme** | Auth + Firestore verilerinin güvenli şekilde kalıcı silinmesi |

---

## 🏗️ Teknik Mimari

```
Presentation Layer  ──►  Ekranlar & Widget'lar
       │
Data Layer          ──►  Firebase Firestore, Storage, Auth
       │
Service Layer       ──►  İş mantığı & veri erişim servisleri
       │
Theme Layer         ──►  Material 3, Light/Dark tema
```

### Teknoloji Yığını

| Katman | Teknoloji | Amaç |
|--------|-----------|------|
| Mobil Arayüz | Flutter (Dart) | Cross-platform Android & iOS |
| Veritabanı | Firebase Firestore | Gerçek zamanlı NoSQL senkronizasyon |
| Kimlik Doğrulama | Firebase Auth | E-posta/Şifre + Google Sign-In |
| Depolama | Firebase Storage | Profil & arıza fotoğrafı depolama |
| Harita | url_launcher + Google Maps | Navigasyon yönlendirme |
| Medya | image_picker | Galeri entegrasyonu |
| Tema | Material 3 + google_fonts | Light/Dark tema desteği |

---

## 🗄️ Veritabanı Yapısı

```
Firestore
├── users          → uid, email, adSoyad, rol, favoriler[], profilFoto
├── magazalar      → ad, kategori, adres, puan, lat, lng, sahipUid, maviTik
├── randevular     → dukkanId, userId, tarih, saat, durum
├── yorumlar       → dukkanId, userId, yorum, puan, tarih
├── bildirimler    → userId, mesaj, okundu, tarih
├── mesajlar       → dukkanId, userId, mesaj, tarih, gonderen
└── talepler       → dukkanId, userId, aciklama, foto, durum

Firebase Storage
├── profil_fotograflari/{uid}.jpg
├── magaza_fotograflari/{id}.jpg
└── talep_fotograflari/{id}.jpg
```

---

## ✅ Test Sonuçları

Gerçek verilerle test: **44 dükkan**, **5 kullanıcı**, **12 randevu**  
Test ortamı: Samsung Galaxy A52 (Android 12) + Android Studio AVD Pixel 6 Pro (API 33)

| # | Senaryo | Sonuç |
|---|---------|-------|
| 1 | E-posta/şifre kayıt & giriş | ✅ Başarılı |
| 2 | Google Sign-In | ✅ Başarılı |
| 3 | Kategori filtreleme & arama | ✅ Başarılı |
| 4 | Google Maps navigasyon | ✅ Başarılı |
| 5 | Randevu oluşturma & esnaf onaylama | ✅ Başarılı |
| 6 | Yorum & ortalama puan güncelleme | ✅ Başarılı |
| 7 | Mesaj gönderme (müşteri → esnaf) | ✅ Başarılı |
| 8 | Fotoğraflı arıza tespiti talebi | ✅ Başarılı |
| 9 | Profil fotoğrafı yükleme & hesap silme | ✅ Başarılı |
| 10 | Mavi tik gösterimi | ✅ Başarılı |
| 11 | Süper Admin – istatistik & toplu bildirim | ✅ Başarılı |
| 12 | Karanlık/Aydınlık tema geçişi | ✅ Başarılı |
| 13 | Çevrimdışı/zayıf bağlantı davranışı | ⚠️ Kısmi (gelecek sürüm) |

---

## 🔮 Gelecek Planlar

- [ ] FCM ile push notification desteği
- [ ] Provider / Riverpod ile state yönetimi
- [ ] flutter_map ile harita üzerinde dükkan listeleme
- [ ] App Store & Google Play yayını

---

## 📦 Kurulum

```bash
# Repoyu klonla
git clone https://github.com/ArdaDuran7/SanayiRehberim.git
cd SanayiRehberim

# Bağımlılıkları yükle
flutter pub get

# Uygulamayı çalıştır
flutter run
```

> **Not:** Firebase projesini bağlamak için `google-services.json` (Android) ve `GoogleService-Info.plist` (iOS) dosyalarınızı ilgili klasörlere eklemeniz gerekmektedir.

---

## 🔗 Bağlantılar

- 📄 [Final Raporu (PDF)](./MUG-FINAL-240053017.pdf)
- 🐦 [Flutter Dokümantasyonu](https://flutter.dev/docs)
- 🔥 [Firebase Dokümantasyonu](https://firebase.google.com/docs)
- 🎨 [Material 3](https://m3.material.io)

---

## 📄 Lisans

© 2026 Arda Duran (240053017) – Alanya Üniversitesi Meslek Yüksekokulu. Tüm hakları saklıdır.
