<p align="center">
  <img src="https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter"/>
  <img src="https://img.shields.io/badge/Gemini_AI-8E75B2?style=for-the-badge&logo=google&logoColor=white" alt="Gemini AI"/>
  <img src="https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" alt="Firebase"/>
  <img src="https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart"/>
</p>

<h1 align="center">🛡️ DesCam AI</h1>

<p align="center">
  <strong>Detektor Hoaks, Penipuan Digital & Analisis Hukum Berbasis AI</strong>
</p>

<p align="center">
  <em>Dibuat untuk <strong>melawan para penipuan dan scammer</strong></em>
</p>

<p align="center">
  <a href="https://descamai.web.app">🌐 Live Demo</a> •
  <a href="#fitur-utama">✨ Fitur</a> •
  <a href="#tech-stack">🛠️ Tech Stack</a> •
  <a href="#cara-menjalankan">🚀 Quick Start</a>
</p>

---

## 🎯 Tentang Aplikasi

**DesCam AI** adalah tools berbasis kecerdasan buatan yang membantu masyarakat Indonesia mengenali **hoaks**, **penipuan digital**, dan memahami **dokumen hukum** dengan bahasa yang mudah dimengerti.

Di era informasi yang serba cepat, banyak orang tertipu oleh berita palsu, link berbahaya, dan surat hukum yang tidak dipahami. **DesCam AI** hadir sebagai _"teman cerdas"_ yang siap memverifikasi konten apapun secara instan — cukup tempel teks, link, atau unggah dokumen.

> 🌐 **Live Demo:** [https://descamai.web.app](https://descamai.web.app)

---

## ✨ Fitur Utama

| Fitur | Deskripsi |
|-------|-----------|
| 🔍 **Deteksi Hoaks** | Verifikasi berita & info viral menggunakan Gemini AI + Google Search Grounding |
| 🛡️ **Scan URL Berbahaya** | Cek link phishing & malware via VirusTotal + PhishTank sebelum mengklik |
| ⚖️ **Analisis Hukum** | Pahami isi surat hukum, dampak, hak, dan risiko — dalam bahasa yang mudah dimengerti |
| 📰 **Scam News** | Pantau penipuan terbaru dari Indonesia dan seluruh dunia secara real-time via RSS Feed |
| 🤖 **AI Powered** | Ditenagai Google Gemini 2.5 Flash dengan kemampuan grounding ke sumber terpercaya |
| 🔒 **Privasi Terjaga** | Tidak ada data pengguna yang disimpan di server — semua diproses lokal & API langsung |
| 🌐 **Bilingual** | Mendukung Bahasa Indonesia & English dengan toggle bahasa instan |
| 📎 **Multi-Input** | Terima teks, URL, gambar, dan dokumen file untuk dianalisis |

---

## 🛠️ Tech Stack

| Kategori | Teknologi |
|----------|-----------|
| **Framework** | Flutter (Material 3) — Web |
| **AI Engine** | Google Gemini 2.5 Flash |
| **Search Grounding** | Google Search Grounding API |
| **URL Security** | VirusTotal API + PhishTank |
| **State Management** | Provider |
| **Typography** | Google Fonts (Outfit, DM Sans, DM Mono) |
| **News Feed** | RSS Feed Parser |
| **Local Storage** | SharedPreferences |
| **Hosting** | Firebase Hosting |
| **File Handling** | Image Picker + File Picker |

---

## 📁 Struktur Proyek

```
lib/
├── main.dart                    # Entry point & provider setup
├── core/
│   ├── config/                  # App configuration
│   ├── constants/               # Colors, strings, constants
│   ├── models/                  # Data models
│   ├── services/                # AI services (Gemini, Mock, Analysis)
│   ├── theme/                   # App theme (dark mode)
│   └── utils/                   # Utilities & helpers
├── providers/                   # State management (Provider)
│   ├── analysis_provider.dart
│   ├── language_provider.dart
│   └── settings_provider.dart
└── ui/
    ├── screens/                 # App screens
    │   ├── home_screen.dart     # Main analysis screen
    │   ├── scam_news_screen.dart # Real-time scam news
    │   ├── about_screen.dart    # About page
    │   └── app_shell.dart       # Navigation shell
    └── widgets/                 # Reusable UI components
```

---

## 🚀 Cara Menjalankan

### Prasyarat
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (≥ 3.0.0)
- [Dart SDK](https://dart.dev/get-dart) (≥ 3.0.0)
- Google Gemini API Key ([dapatkan di sini](https://aistudio.google.com/app/apikey))

### Instalasi

```bash
# 1. Clone repository
git clone https://github.com/zeydan67/DesCam-Ai.git
cd DesCam-Ai

# 2. Install dependencies
flutter pub get

# 3. Jalankan di browser
flutter run -d chrome
```

### Konfigurasi API Key

Setelah aplikasi berjalan, klik ikon **⚙️ Settings** di halaman utama, lalu masukkan:
- **Gemini API Key** — untuk fitur deteksi hoaks & analisis hukum
- **VirusTotal API Key** *(opsional)* — untuk fitur scan URL berbahaya

### Build untuk Production

```bash
flutter build web --release
```

Hasil build akan tersedia di folder `build/web/`.

---

## 🌐 Deploy ke Firebase

```bash
# Install Firebase CLI (jika belum)
npm install -g firebase-tools

# Login ke Firebase
firebase login

# Inisialisasi project
firebase init hosting

# Deploy
firebase deploy
```

---

## 🎨 Desain & UI

- **Dark Mode Premium** — Tema gelap dengan aksen vermillion & gold
- **Glassmorphism** — Efek glass transparan pada kartu-kartu UI
- **Animated Background** — Video background + floating orbs
- **Micro-animations** — Pulse, fade, slide untuk pengalaman interaktif
- **Responsive Layout** — Tampilan optimal di desktop & mobile

---

## 📄 Lisensi

Proyek ini bersifat **open-source** dan dibuat untuk keperluan kompetisi **Google Juara Vibe Coding 2026**.

---

## 👨‍💻 Developer

<p align="center">
  <strong>zeydan67</strong><br/>
  <a href="https://github.com/zeydan67">GitHub Profile</a>
</p>

<p align="center">
  Dibuat dengan ❤️ untuk masyarakat Indonesia
</p>
