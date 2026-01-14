# BPR 251 – MOBİL UYGULAMA GELİŞTİRME DERSİ FİNAL SINAVI PROJE ÖDEVİ

**Hazırlayan:** Arda Duran  
**Öğrenci Numarası:** 240053017  
**Bölüm:** Bilgisayar Programcılığı - 2. Sınıf  
**Okul:** Alanya Üniversitesi Meslek Yüksekokulu  

---

# 🛠️ Sanayi Rehberim - Mobil Uygulaması

**Sanayi Rehberim**, araç sahiplerini sanayi sitesindeki ustalarla ve dükkanlarla en hızlı şekilde buluşturmayı amaçlayan, randevu ve değerlendirme sistemine sahip kapsamlı bir mobil uygulamadır.

---

## 📱 Proje Amacı ve Kapsamı

Bu proje, araç sahiplerinin sanayi sitelerinde dükkan ararken yaşadığı zaman kaybını önlemek ve ustaların dijital ortamda randevu yönetebilmesini sağlamak amacıyla geliştirilmiştir. 

Uygulama, Google Firebase altyapısını kullanarak gerçek zamanlı veri akışı ve güvenli kullanıcı yönetimi sağlar.

---

## ✨ Temel Özellikler

### 1. Kullanıcı ve Güvenlik İşlemleri
* **Firebase Authentication:** Güvenli E-Posta/Şifre ile giriş ve kayıt olma.
* **Hata Yönetimi:** Yanlış şifre, olmayan kullanıcı veya mükerrer kayıt durumlarında kullanıcı dostu uyarılar.
* **Profil Yönetimi:** Profil fotoğrafı yükleme (Galeri entegrasyonu), bilgi güncelleme.
* **Hesap Silme:** Kullanıcının tüm verilerini (Auth ve Firestore) kalıcı olarak silebilmesi (Güvenlik onaylı).

### 2. Dükkan ve Usta Arama
* **Kategorizasyon:** Kaporta, Motor, Elektrik, Lastik & Jant, Boya gibi alanlara göre filtreleme.
* **Akıllı Arama:** Dükkan ismine göre anlık filtreleme.
* **Dükkan Detayları:** Adres, puan, hizmet kategorisi ve kapak fotoğrafı görüntüleme.
* **Harita Entegrasyonu:** Google Haritalar üzerinden seçilen dükkana doğrudan yol tarifi alma.

### 3. Randevu Sistemi
* **Randevu Oluşturma:** İstenilen tarih ve saat için randevu talebi gönderme.
* **Durum Takibi:** Randevuların "Bekliyor", "Onaylandı" veya "Reddedildi" durumlarını takip etme.
* **Bildirimler:** Randevu durumu değiştiğinde uygulama içi bildirim alma.

### 4. Etkileşim ve Değerlendirme
* **Favoriler:** Beğenilen ustaları favori listesine ekleme ve çıkarma.
* **Puan ve Yorum:** Hizmet tamamlandığında dükkana puan verme ve yorum yapma. Puanlar dükkan ortalamasına anlık yansır.

### 5. Ekstra Özellikler
* **Karanlık Mod (Dark Mode):** Cihaz temasına veya kullanıcı tercihine uygun arayüz.
* **Hakkında Sayfası:** Uygulama geliştirici ve sürüm bilgileri.

---

## 🛠️ Kullanılan Teknolojiler ve Kütüphaneler

Bu proje **Flutter** framework'ü kullanılarak **Dart** dili ile geliştirilmiştir.

* **firebase_core & firebase_auth:** Kimlik doğrulama ve bağlantı.
* **cloud_firestore:** NoSQL veritabanı işlemleri.
* **image_picker:** Profil fotoğrafı seçimi için galeri erişimi.
* **url_launcher:** Harita ve dış bağlantı yönlendirmeleri.
* **intl:** Tarih ve saat formatlama işlemleri.

---

*© 2026 Arda Duran - Tüm Hakları Saklıdır.*