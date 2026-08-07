# CampusMate 🎓

Aplikasi manajemen akademik untuk mahasiswa: kelola mata kuliah, jadwal, tugas,
catatan, dan kalender dalam satu tempat — dengan bantuan AI untuk mengisi data
secara otomatis dari foto KRS maupun chat dosen.

Dibangun dengan **Flutter** + **Supabase** + **Gemini AI**.

## ✨ Fitur

| Fitur | Deskripsi |
|---|---|
| 🔐 **Autentikasi** | Daftar/masuk dengan email atau Google, reset password, sesi persisten |
| 📚 **Mata Kuliah** | CRUD mata kuliah (kode, SKS, dosen, warna) |
| 📸 **Impor KRS dari Foto** | Foto tabel KRS → AI mengisi mata kuliah + jadwal otomatis, dengan layar tinjauan & deteksi duplikat |
| 🗓️ **Jadwal Kuliah** | Jadwal mingguan per hari, deteksi bentrok, pengingat 30 menit sebelum kelas |
| ✅ **Tugas** | Deadline, prioritas, checklist sub-tugas (progres otomatis), filter & urutkan, pengingat H-3/H-1, hapus dengan undo |
| ✨ **Tangkap Cerdas** | Tempel chat WA dosen atau screenshot → AI menyimpulkan tugas & event, tinggal konfirmasi |
| 📝 **Catatan** | Editor rich text (Quill), terkait mata kuliah, pencarian full-text |
| 📅 **Kalender** | Kalender bulanan dengan penanda deadline tugas + event kustom |
| 🏠 **Dashboard** | Jadwal hari ini, deadline terdekat, event mendatang, statistik progres tugas |
| 🌙 **Mode Gelap** | Tema Material 3 terang/gelap, tersimpan antar sesi |

## 🛠️ Teknologi

- **Flutter** (Dart 3, Material 3) — UI lintas platform
- **Riverpod 3** — state management (pola `Notifier` + state immutable)
- **go_router** — navigasi deklaratif
- **Supabase** — autentikasi, database Postgres (dengan RLS), storage avatar
- **Google Gemini** — pembacaan foto KRS & penyimpulan chat (model `gemini-flash-latest`)
- **flutter_quill** — editor catatan rich text
- **flutter_local_notifications** — pengingat kelas & deadline
- **mocktail** — pengujian (238 tes unit/widget/alur)

## 📂 Struktur Proyek

Setiap fitur mengikuti clean architecture:

```
lib/
├── core/            # tema, router, konfigurasi env, klien AI & Supabase
├── features/
│   ├── auth/        # domain / data / presentation
│   ├── courses/     # termasuk impor KRS dari foto
│   ├── schedules/
│   ├── tasks/
│   ├── notes/
│   ├── calendar/
│   ├── dashboard/
│   └── smart_capture/  # tangkap cerdas (chat → tugas/event)
└── services/        # notifikasi, image picker
```

Dokumen perancangan ada di [docs/](docs/):
[SRS](docs/01_SRS.md) · [Rencana Implementasi](docs/02_IMPLEMENTATION_PLAN.md) ·
[Design System](docs/03_DESIGN_SYSTEM.md)

## 🚀 Menjalankan Proyek

### Prasyarat

- Flutter SDK (Dart ^3.11)
- Proyek [Supabase](https://supabase.com) (gratis)
- API key [Google AI Studio](https://aistudio.google.com) (gratis, untuk fitur AI)

### Langkah

1. **Clone & pasang dependensi**

   ```bash
   git clone https://github.com/Emil-02/Campus_Hub.git
   cd Campus_Hub
   flutter pub get
   ```

2. **Siapkan database** — jalankan berkas SQL di [supabase/migrations/](supabase/migrations/)
   secara berurutan lewat SQL Editor di dashboard Supabase.

3. **Buat file `.env`** di root proyek:

   ```env
   SUPABASE_URL=https://xxxx.supabase.co
   SUPABASE_ANON_KEY=kunci_anon_anda
   GEMINI_API_KEY=kunci_gemini_anda
   ```

   > `.env` ikut terbungkus sebagai aset — build ulang setelah mengubahnya.

4. **Jalankan**

   ```bash
   flutter run
   ```

### Build Release (Android)

Siapkan keystore sendiri (tidak disertakan di repo):

```properties
# android/key.properties
storeFile=../keystore/nama-keystore.jks
storePassword=...
keyAlias=...
keyPassword=...
```

```bash
flutter build apk --release --split-per-abi
```

APK release memakai R8 minify + resource shrinking (arm64 ± 22 MB).

## 🧪 Pengujian

```bash
flutter analyze   # statis, tanpa temuan
flutter test      # 238 tes: unit, widget, dan alur (auth/tugas/jadwal/impor)
```

## 📄 Lisensi

Proyek pribadi untuk keperluan akademik.

