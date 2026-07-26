# CampusMate Design System

## 1. Design Principles
- **Clarity**: Informasi akademik dan tugas harus mudah dibaca dan dipahami dalam sekali lihat.
- **Consistency**: Menggunakan komponen Material 3 standar agar pengguna familiar secara instan.
- **Hierarchy**: Penekanan visual yang kuat pada informasi paling kritis, seperti deadline terdekat dan tugas berprioritas tinggi.
- **Accessibility**: Mendukung ukuran teks besar, memiliki kontras warna yang memadai, serta area sentuh (touch target) yang luas.
- **Efficiency**: Meminimalkan jumlah tap untuk aksi utama (menambah tugas, melihat jadwal).
- **Feedback**: Selalu berikan respons visual (snackbar, loading state, dialog) setelah pengguna melakukan sebuah tindakan.
- **Simplicity**: Jangan membanjiri layar dengan informasi atau dekorasi yang tidak perlu.
- **Student-Friendly Experience**: Bahasa, bentuk, dan warna yang ramah; terorganisir namun tidak kaku.

## 2. Brand Personality
- **Personality**: Cerdas, suportif, dapat diandalkan, dan rapi.
- **Tone**: Jelas, langsung, menyemangati, ringkas.
- **Visual Direction**: Modern, bersih dengan whitespace yang lega, serta penggunaan warna fungsional sebagai pengelompokan mata kuliah atau penanda prioritas.
- **Emotional Impression**: Menurunkan tingkat stres (anxiety-reducing) dengan membuat seluruh kewajiban akademik tampak lebih terkendali.
- **Hal yang harus dihindari**: Elemen yang terlalu kekanak-kanakan (ilustrasi kartun berlebih) atau desain yang terlalu kaku dan korporat layaknya aplikasi enterprise.

## 3. Color System
Berdasarkan Material Design 3 Tonal Palette.

### Light Theme
| Token Name | HEX | Fungsi | Contoh Penggunaan |
|---|---|---|---|
| primary | `#006874` | Elemen aksi utama, komponen aktif | FAB, Primary Button, Active Tab |
| onPrimary | `#FFFFFF` | Teks/ikon di atas primary | Teks pada Primary Button |
| primaryContainer | `#97F0FF` | Latar belakang elemen yang di-highlight | Card highlight, Selected Item |
| onPrimaryContainer | `#001F24` | Teks di atas primaryContainer | Judul pada active card |
| secondary | `#4A6267` | Aksi sekunder, informasi pendukung | Secondary Button, Filter Chips |
| onSecondary | `#FFFFFF` | Teks di atas secondary | Teks pada Secondary Button |
| secondaryContainer | `#CDE7ED` | Area sekunder yang kurang menonjol | Inactive Filter Chip background |
| tertiary | `#525E7D` | Aksen warna ketiga (opsional) | Highlight kalender khusus |
| background | `#FAFDFF` | Warna dasar layar aplikasi | Latar belakang utama |
| surface | `#FAFDFF` | Latar belakang komponen seperti card | Card default |
| surfaceVariant | `#DBE4E6` | Latar dengan batas visual yang jelas | Divider, form field background |
| error | `#BA1A1A` | Indikasi kesalahan atau destruktif | Teks error, Delete Button |
| warning | `#FF9800` | Peringatan atau butuh perhatian | Overdue task badge, Conflict warning |
| success | `#4CAF50` | Indikasi berhasil atau selesai | Task completed icon, Snackbar sukses |
| info | `#2196F3` | Informasi umum | Tooltip, instruksi pendukung |
| outline | `#6F797A` | Batas antar komponen | Border text field, border button |
| disabled | `#1F1F1F` (38%) | Komponen yang tidak bisa diinteraksi | Disabled button background |

### Dark Theme
| Token Name | HEX | Fungsi | Contoh Penggunaan |
|---|---|---|---|
| primary | `#4FD8EB` | Elemen aksi utama | FAB, Primary Button |
| onPrimary | `#00363D` | Teks/ikon di atas primary | Teks FAB |
| primaryContainer | `#004F58` | Latar belakang elemen yang di-highlight | Selected Tab |
| onPrimaryContainer | `#97F0FF` | Teks di atas primaryContainer | Ikon pada selected tab |
| secondary | `#B1CBD0` | Aksi sekunder | Secondary Button |
| onSecondary | `#1C3438` | Teks di atas secondary | Teks Secondary Button |
| secondaryContainer | `#334B4F` | Area sekunder | Filter chip background |
| background | `#191C1D` | Warna dasar layar aplikasi | Latar belakang utama |
| surface | `#191C1D` | Latar belakang komponen | Card background |
| surfaceVariant | `#3F484A` | Divider, field background | Form input background |
| error | `#FFB4AB` | Indikasi kesalahan | Delete button text |
| warning | `#FFB74D` | Peringatan | Conflict badge |
| success | `#81C784` | Indikasi berhasil | Success text |
| info | `#64B5F6` | Informasi umum | Info card |
| outline | `#899294` | Batas komponen | Outline button border |

## 4. Course Color Palette
Digunakan untuk membedakan mata kuliah secara visual, harus tetap terbaca di mode terang dan gelap. Pada implementasi Flutter, warna akan disesuaikan saturasi dan lightness-nya berdasarkan tema perangkat menggunakan `Color.lerp()` atau dynamic generation.

| Nama Warna | HEX Background (Light) | HEX Foreground (Light) | Penggunaan |
|---|---|---|---|
| Blue | `#E3F2FD` | `#1565C0` | Mata Kuliah A |
| Red | `#FFEBEE` | `#C62828` | Mata Kuliah B |
| Green | `#E8F5E9` | `#2E7D32` | Mata Kuliah C |
| Orange | `#FFF3E0` | `#EF6C00` | Mata Kuliah D |
| Purple | `#F3E5F5` | `#6A1B9A` | Mata Kuliah E |
| Teal | `#E0F2F1` | `#00695C` | Mata Kuliah F |
| Pink | `#FCE4EC` | `#AD1457` | Mata Kuliah G |
| Indigo | `#E8EAF6` | `#283593` | Mata Kuliah H |
| Cyan | `#E0F7FA` | `#006064` | Mata Kuliah I |
| Amber | `#FFF8E1` | `#FF8F00` | Mata Kuliah J |
| Deep Orange| `#FBE9E7` | `#D84315` | Mata Kuliah K |
| Light Green| `#F1F8E9` | `#33691E` | Mata Kuliah L |

## 5. Typography
Keluarga Font: **Inter** (Dipilih karena keterbacaan yang sangat baik pada ukuran kecil dan tampilan bersih pada ukuran besar).

| Style | Font Size | Font Weight | Line Height | Letter Spacing | Contoh Penggunaan |
|---|---|---|---|---|---|
| displayLarge | 57 | Regular (400) | 64 | -0.25 | Angka besar di dashboard (opsional) |
| displayMedium | 45 | Regular (400) | 52 | 0 | - |
| headlineLarge | 32 | SemiBold (600)| 40 | 0 | Sapaan utama di Dashboard |
| headlineMedium | 28 | SemiBold (600)| 36 | 0 | Judul layar (AppBar opsional) |
| titleLarge | 22 | Medium (500) | 28 | 0 | Judul utama pada Card besar |
| titleMedium | 16 | Medium (500) | 24 | 0.15 | Judul List Tile, Nama Mata Kuliah |
| titleSmall | 14 | Medium (500) | 20 | 0.1 | Judul kecil, Teks tombol sekunder |
| bodyLarge | 16 | Regular (400) | 24 | 0.5 | Teks isi utama (deskripsi catatan) |
| bodyMedium | 14 | Regular (400) | 20 | 0.25 | Teks standar list, catatan ringkas |
| bodySmall | 12 | Regular (400) | 16 | 0.4 | Caption, penunjuk waktu di jadwal |
| labelLarge | 14 | Medium (500) | 20 | 0.1 | Teks tombol (Primary Button) |
| labelMedium | 12 | Medium (500) | 16 | 0.5 | Label badge, teks Filter Chips |
| labelSmall | 11 | Medium (500) | 16 | 0.5 | Teks label Bottom Navigation |

## 6. Spacing System
Menggunakan skala berbasis 8dp (dan 4dp untuk jarak sangat sempit).

| Token | Ukuran (dp) | Deskripsi & Penggunaan |
|---|---|---|
| xs | 4 | Jarak sangat dekat (ikon kecil dengan teks caption sebelahnya) |
| sm | 8 | Jarak antar item dalam komponen yang sama (antar field form, atau judul dengan tanggal di card) |
| md | 16 | Padding standar dalam card, jarak antar elemen UI terpisah |
| lg | 24 | Jarak antar section atau grup informasi utama |
| xl | 32 | Margin sebelum elemen bottom (tombol simpan utama) |
| xxl | 48 | Jarak kosong ekstra besar (empty state, padding bawah scroll) |
| section spacing | 24 | Jarak vertikal antar bagian (misal: antara Jadwal dan Deadline di Dashboard) |
| screen padding | 16 | Margin kiri dan kanan dari batas layar untuk semua screen |

## 7. Sizing System
| Properti | Ukuran Minimum (dp) |
|---|---|
| Minimum touch target | 48 x 48 (Sesuai standar aksesibilitas) |
| Icon size | 24 (Default), 20 (Small), 32 (Large) |
| Avatar size | 40 (List), 80 (Profile header) |
| Button height | 48 |
| Text field height | ~56 (Sesuai panduan Material 3) |
| Bottom navigation height| 80 |
| App bar height | 64 |
| Card minimum size | 64 (Untuk memastikan konten tidak terlalu sempit) |

## 8. Border Radius
| Token | Ukuran (dp) | Penggunaan |
|---|---|---|
| small | 4 | Checkbox, badge status kecil |
| medium | 8 | Thumbnail gambar, outline form field, filter chips |
| large | 16 | Komponen Card (Course, Schedule, Task, Note), Dialog |
| extra large | 24 | Ujung atas Bottom Sheet |
| full / circular | 999 | FAB, Avatar Profil, Rounded Buttons |

## 9. Elevation and Shadow
Terapkan bayangan minimalis, memanfaatkan warna tonal Elevation dari Material 3.
- **Card**: Level 1 (Flat, sangat tipis atau menggunakan border outline halus).
- **Floating Action Button**: Level 3 (Tampak melayang dengan shadow lebih tegas).
- **Bottom Sheet**: Level 1 (Elemen dibantu scrim hitam transparan di belakangnya).
- **Dialog**: Level 3.
- **App Bar**: Level 0 saat discroll di awal, Level 2 saat halaman di-scroll ke bawah (terselip di bawah).
- **Navigation Bar**: Level 2 (Memberi kesan sedikit menonjol dari background).

## 10. Iconography
- **Icon Library**: Material Symbols Rounded (via Google Fonts / paket Flutter).
- **Ukuran Icon**: Default 24dp.
- **Filled vs Outlined**: Icon Outlined digunakan untuk state default (tidak aktif). Icon Filled digunakan untuk state aktif/selected (seperti tab bar aktif atau tombol filter terpilih).
- **Warna Icon**: Icon aktif mengikuti warna teks primary. Icon pasif mengikuti warna `outline` atau `onSurfaceVariant`.
- **Icon pada Button**: Ikon ditempatkan di sisi kiri (leading) dari teks, dengan spacing `sm` (8dp).

## 11. Layout System
- **Screen Padding**: 16dp horizontal rata di seluruh tepi layar. Pengecualian hanya untuk elemen *full-width* seperti list divider atau scroll container murni.
- **Content Width**: Lebar maksimal 600dp (ditengahkan di layar, sebagai persiapan jika dijalankan di tablet).
- **Grid**: Kalender menggunakan grid 7 kolom.
- **List Spacing**: Jarak spasi antar elemen card pada ListView di set ke 8dp atau 12dp.
- **Safe Area**: Seluruh layar konten harus di dalam widget `SafeArea` untuk mencegah tertutup notch atau area navigasi OS.
- **Keyboard Handling**: Form layar diposisikan di atas keyboard ketika keyboard muncul (`resizeToAvoidBottomInset = true`).
- **Responsive Layout**: Menggunakan ListView dan layout fluida, membatasi elemen fix width agar fleksibel.
- **Handling Font Scaling**: Mendukung font scaling hingga 200%. Gunakan widget `Flexible` di baris dan properti `maxLines` pada Text agar layout tidak terpotong.

## 12. Navigation Components
- **AppBar**: Komponen M3 standar. Judul rata tengah atau kiri (titleLarge). Tanpa shadow (elevasi 0). Back button selalu menggunakan panah kiri standar di pojok kiri atas.
- **Bottom Navigation Bar**: Komponen utama navigasi dengan indikator aktif berbentuk "pill". Menggunakan icon Outlined (inaktif) dan Filled (aktif). Teks labelSmall dipertahankan.
  - 5 Destinasi: Dashboard (Home), Jadwal (Calendar), Tugas (Task_alt), Catatan (Notes), Profil (Person).
- **Navigation Drawer**: Tidak diperlukan. Segala menu ada di Bottom Navigation atau halaman Profil.
- **Tab Bar**: Digunakan sebagai pemisah halaman di internal menu (contoh: "List View" vs "Calendar View" di halaman Jadwal).

## 13. Button Components
- **Primary Button**: Warna latar `primary`, teks `onPrimary`, tinggi 48dp, radius bundar (full/rounded). Terdapat indikator putar (loading) kecil saat memuat data.
- **Secondary Button**: Outlined button. Border warna `outline`, warna teks `primary`, tinggi 48dp, radius bundar.
- **Text Button**: Tanpa border dan background transparan. Warna teks `primary`. Untuk fungsi tidak dominan seperti link "Lupa Password?".
- **Icon Button**: Area tekan minimal 48x48dp meskipun ikon hanya 24dp.
- **Floating Action Button (FAB)**: Container sewarna `primaryContainer`, ikon sewarna `onPrimaryContainer`. Digunakan khusus aksi penciptaan utama (Tambah Tugas/Jadwal) di kanan bawah.
- **Destructive Button**: Primary button yang menggunakan skema warna `error` (latar error, teks on-error).
- **Disabled State**: Tombol memiliki opacity 38%, warna berubah kusam, mengabaikan ketukan.

## 14. Form Components
- **Text Field**: M3 Outlined Text Field.
  - Default: Border `outline`.
  - Focused: Border menebal, warna `primary`.
  - Filled: Terdapat background warna `surfaceVariant` transparan tipis.
  - Error: Border dan text helper menjadi warna `error`.
- **Password Field**: Text field standar dengan trailing icon mata (`visibility` toggle).
- **Search Field**: Text field berbentuk rounded (pill) dengan leading icon kaca pembesar.
- **Dropdown**: Menggunakan dropdown button field dengan gaya outlined.
- **Date / Time Picker**: Memakai Material Design 3 bawaan OS/Flutter dialog picker.
- **Checkbox / Radio / Switch**: Warna tint menggunakan `primary` saat diaktifkan.
- **Validation message**: Teks kecil (`bodySmall`) di bawah kolom input, berwarna `error`.
- **Required indicator**: Dapat menggunakan lambang asterisk `*` berwarna merah atau bergantung pada validasi ketika submit.

## 15. Card Components
- **Course Card**: Title mata kuliah (titleMedium), informasi dosen/SKS. Sisi kiri diberikan garis aksen warna (atau background label kecil) yang sesuai warna Mata Kuliah tersebut.
- **Schedule Card**: Sama seperti Course Card ditambah ikon jam (start - end time) dan pin ruangan. Digunakan di widget jadwal harian.
- **Task Card**: Checkbox besar di kiri, judul teks di tengah (dicoret jika selesai), label deadline atau prioritas di kanan/bawah. Elevasi card 1dp.
- **Note Card**: Judul, preview isi (max 2 baris), chip kecil untuk nama mata kuliah terkait.
- **Dashboard Summary Card**: Kotak ukuran seimbang (square-ish) dengan angka besar (headlineMedium) dan label penjelasan (misal: "3 Overdue").
- **Empty State Card**: Border dashed/outline, ilustrasi sederhana di tengah, disertai Primary/Text Button "Tambah Data Baru".

## 16. Task Status Components
- **Low Priority**: Ikon panah biru bawah (`info`) atau teks label.
- **Medium Priority**: Netral.
- **High / Urgent Priority**: Ikon seru atau merah (`error/warning`). Font judul ditebalkan.
- **Active**: Checkbox lingkaran belum terisi.
- **Completed**: Checkbox tercentang, isi task meredup (abu-abu/opacity rendah), teks di-*strikethrough*.
- **Overdue**: Badge tegas warna merah muda dengan teks merah/putih berbunyi "Terlambat".
*(Accessibility Rule: Selain beda warna, terdapat perbedaan ikon agar dapat terbaca jelas oleh colorblind).*

## 17. Feedback Components
- **Snackbar**: Kotak toast di posisi bawah, mengambang di atas navigation bar. Action button (jika ada, e.g. "Undo") berwarna kontras.
- **Alert Dialog**: Pop-up tengah layar dengan judul, konten, dan dua tindakan tombol jelas.
- **Confirmation Dialog**: Dialog peringatan aksi sensitif (mis: Hapus akun, logout).
- **Bottom Sheet**: Memunculkan menu opsi atau pilihan sort/filter spesifik, berawal dari bawah layar.
- **Loading Indicator**: Animasi CircularProgressIndicator murni.
- **Skeleton Loading**: Balok abu-abu halus yang menyala-nyala (*shimmer*) saat data dimuat (opsional untuk memperhalus layout shift).
- **State Pages (Empty/Error/Offline)**: Komponen penuh berisi ilustrasi ikon sentral (seperti koneksi terputus) dengan pesan `titleMedium` dan `bodyMedium` instruksional.

## 18. Notification Style
- **Jadwal Kuliah**:
  - Title: "Kuliah [Nama MK] akan segera dimulai!"
  - Body: "Di ruang [Ruangan] pada pukul [Waktu]. Jangan terlambat!"
- **Deadline Tugas H-3**:
  - Title: "Pengingat: Tugas [Nama Tugas] hampir mendekati deadline."
  - Body: "Dikumpulkan 3 hari lagi untuk mata kuliah [Nama MK]."
- **Deadline Tugas H-1**:
  - Title: "BESOK Deadline: [Nama Tugas]!"
  - Body: "Pastikan tugas [Nama MK] Anda sudah selesai dikerjakan."

## 19. Authentication Screens
- **Splash Screen**: Background `primary`, Logo produk di sentral (animasi opsional).
- **Login Screen**: Minimalis dengan sapaan jelas. Form diisi oleh Email dan Password, TextButton "Lupa Password?", PrimaryButton "Login", SecondaryButton "Masuk dengan Google", serta tautan pendaftaran.
- **Register & Forgot Password**: Serupa secara layout agar tetap fokus pada konversi, padding besar di tengah.

## 20. Dashboard Screen
- **Greeting**: Sapaan ramah di paling atas: "Hai, [Nama] 👋".
- **Tanggal**: Menuliskan tanggal panjang "Senin, 26 Juli 2026" di bawah sapaan.
- **Jadwal Hari Ini**: List card horizontal, maksimal memuat jadwal aktif.
- **Deadline Terdekat**: Card vertikal yang di-sortir dari tenggat paling dekat.
- **Progress Tugas & Statistik**: Baris dua panel informasi cepat (total vs selesai).
- **Quick Actions**: Tombol melingkar sederhana di baris teratas untuk "Tambah Tugas" atau "Buat Jadwal" menghindari penumpukan aksi.

## 21. Schedule Screen
- **Weekly Timetable**: Layout terbagi hari (Senin, Selasa, dst.) dengan scroll vertikal. Tiap hari memiliki grup list card jadwalnya.
- **Course Blocks**: Card diberi label blok berwarna sisi kirinya berdasarkan pengaturan mata kuliah.
- **Highlight**: Jadwal yang jamnya sedang berjalan sekarang diberikan background surface yang lebih menonjol (seperti primaryContainer).
- **Conflict Warning**: Menampilkan badge atau card spesifik jika mendeteksi dua jadwal berjam sama.

## 22. Task Screens
- **Task List**: List vertikal semua tugas terurut berdasarkan filter default.
- **Filter Chips**: Tersusun rapi menyamping (scroll horizontal) di bagian atas list ("Semua", "Aktif", "Selesai", dll).
- **Task Card & Detail**: Task card cukup ditekan singkat untuk berganti checklist (check/uncheck), atau diklik lama/tap detail untuk membuka deskripsi panjang di layar berikutnya.

## 23. Notes Screens
- **Note List**: Card berjajar dengan tampilan judul dan preview kecil isi catatan serta date modified.
- **Editor**: Text form polosan dan clean tanpa border tebal di badan catatan, judul note diperbesar (headlineMedium). Di bagian bawah ada *toolbar* yang cukup berisi fungsi *Bold, Italic, List, Lampiran Link* (tidak kompleks).
*(Catatan: Sesuai panduan efisiensi solo dev MVP, Image Attachment ditunda/diganti form url minimal).*

## 24. Calendar Screen
- **Monthly View**: Tampilan widget bulan di paruh atas layar.
- **Event Indicators**: Lingkaran/dot kecil di kolom tanggal. Titik oranye/merah untuk menandai adanya batas akhir (deadline) di hari tersebut.
- **Day Detail**: Di paruh bawah layar atau melalui sentuhan meluncurkan Bottom Sheet, mencatatkan daftar event hari yang ditekan.

## 25. Profile and Settings Screens
- **Profile Header**: Foto Profil sirkular berpusat, diiringi Nama Pengguna dan info Institusi/Prodi (TitleLarge).
- **Settings List**: List tile berikutan (Icon - Title - Chevron right) untuk: Kelola Mata Kuliah, Edit Profil, Ubah Password.
- **Theme Toggle**: Tersedia sebagai aksi `Switch` langsung di list (Mode Gelap: Aktif/Nonaktif).
- **Logout / Delete**: Tombol di paling bawah dengan tone merah (Destructive button) atau Secondary Button kontras.

## 26. Light and Dark Mode Rules
- Tema gelap tidak memakai hitam murni `#000000` di warna latar, melainkan `#191C1D` (dark grey) agar elevasi Card masih terlihat.
- Kartu (Cards) di mode gelap memiliki elevasi tonal yang sedikit lebih cerah ketimbang background utama.
- Warna teks terinversi dengan rasio kontras ketat (putih pucat/abu di atas gelap).
- Warna status error/warning lebih dibuat redup (muted) sedikit agar tidak silau (mis. `#FFB4AB` ketimbang pure red).
- Mode light mempertahankan bayangan yang jelas dan card di atas background putih murni.

## 27. Accessibility Guidelines
- **Touch Target**: Segala bentuk tombol (TextButton, IconButton) berukuran luas minimum 48x48 dp.
- **WCAG AA Contrast**: Warna primary terhadap onPrimary memenuhi syarat rasio pencahayaan (misalnya teks putih di background cyan tua).
- **Semantic Labels**: Setiap tombol icon akan dibungkus atribut `Semantics` yang memiliki deskripsi suara untuk Screen Reader.
- **Font Scaling**: `Text` widget bebas scaling sistem (beberapa tulisan panjang menggunakan `maxLines: 2, overflow: TextOverflow.ellipsis` agar tidak tumpah berantakan).
- **Redundansi Informasi**: Status prioritas merah akan selalu dibarengi teks tulisan atau bentuk icon berbeda (tidak bergantung pada warna merah semata).

## 28. Motion and Animation
- Efek transisi harus dipertahankan minimal. Digunakan transisi bawaan `GoRouter` atau page navigasi standar OS.
- Loading data menggunakan komponen spinner mutar yang smooth, atau opacity fade.
- Menandai tugas 'Selesai' (checked) mengaktifkan mikro-animasi garis coret (strikethrough).
- Animasi Bottom Sheet bergeser dari bawah. Jangan ciptakan custom animasi mencolok agar tidak lambat/jank di smartphone lawas.

## 29. Flutter Design Token Mapping
Direktori yang mengelola UI rules aplikasi: `lib/core/theme/`

- `app_colors.dart`: Daftar spesifik statis atau ekstensi untuk warna course (seperti warna yang tak ada di Material Tonal biasa).
- `app_typography.dart`: Definisi TextTheme dengan `GoogleFonts.inter()`.
- `app_spacing.dart`: Definisi konstan gap: `static const double sm = 8.0;`.
- `app_sizes.dart`: Konstanta ukuran general semisal `iconSmall = 20.0`.
- `app_radius.dart`: Pembuatan `BorderRadius` e.g., `BorderRadius.circular(16.0)`.
- `light_theme.dart` & `dark_theme.dart`: File pembentuk instance `ThemeData`.
- `app_theme.dart`: Titik masuk yang mengemas getter `light` dan `dark`.

*Contoh Ringkas:*
```dart
class AppSpacing {
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: 16.0);
}
```

## 30. Shared Widget Mapping
Daftar komponen yang dibangun sekali untuk dipakai berkali-kali (`lib/core/widgets/`):

- **CampusMateAppBar**: AppBar terstandardisasi (tinggi, warna back button).
- **CampusMateBottomNavigation**: Konfigurasi index Tab M3.
- **PrimaryButton**: Wrapper `ElevatedButton`, properti `isLoading`, `onPressed`.
- **SecondaryButton**: Wrapper `OutlinedButton`.
- **AppTextField**: Form field dekorasi kustom, menerima properti validator, label, dsb.
- **PasswordTextField**: Inherit `AppTextField` tapi memiliki internal state bool `isObscured`.
- **CourseCard**: Kartu berisi data Entity Course, onTap aksi klik.
- **TaskCard**: Kartu spesifik Task Entity, dengan check mark event.
- **EmptyStateWidget**: Menampilkan vektor kosong dengan teks ("Wah belum ada apa-apa disini").
- **ErrorStateWidget**: Menampilkan logo peringatan error, isi pesan error API, tombol Retry.
- **LoadingWidget**: Centered `CircularProgressIndicator`.
- **ConfirmationDialog**: Menyatukan API pop-up dialog M3 untuk aksi hapus.
- **AppSnackbar**: Fungsi global pemanggil `ScaffoldMessenger` dengan varian `Success` & `Error`.

## 31. Do and Don't

**DO:**
- Gunakan token `AppSpacing.md` untuk padding dan margin (bukan hardcoded mis. `padding: EdgeInsets.all(16)` terus-terusan).
- Manfaatkan warna via ekstensi tema M3 (`Theme.of(context).colorScheme.primary`).
- Prioritaskan pemakaian `Shared Widget` di poin 30.
- Kembalikan `AppSnackbar` success apabila action post data CRUD ke Supabase membuahkan hasil positif.

**DON'T:**
- Melakukan kustomisasi warna di layar langsung (`color: Colors.red`).
- Mengatur ukuran Font dan tipe secara literal (`TextStyle(fontSize: 14)` tanpa lewat `TextTheme`).
- Meniadakan elemen feedback (seperti mengklik tombol tanpa interaksi animasi atau loading).
- Memecah hirarki dengan font yang terlalu banyak tipe berlainan.

## 32. Design System Acceptance Criteria
- [x] Variabel Light & Dark mode tersistem.
- [x] Warna khusus matakuliah didata secara logis dan *accessible*.
- [x] Pemetaan Design Tokens ke hierarki folder struktural Flutter didokumentasikan.
- [x] Spesifikasi Form, Button, Teks, List telah tergambar jelas sesuai M3.
- [x] Ketentuan aksesibilitas dasar dipenuhi.
- [x] Scope pengerjaan bersifat ringkas, efisien, sejalan untuk dipraktikkan oleh **Solo Developer**.
- [x] Berkelindan tepat dengan kebutuhan fungsi di dalam CampusMate SRS v1.0.0.
