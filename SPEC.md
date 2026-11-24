# Spesifikasi Vibe Coding GO-RENT

Nov 24, 2026 · @Eggy Andrean

Dokumen ini adalah spesifikasi lengkap aplikasi rental mobil GO-RENT (Flutter + REST API Node.js Express). Tujuannya supaya AI agent di VS Code (Copilot, Gemini Code Assist, Cursor, atau Antigravity, sesuai modul P13) bisa membangun aplikasinya tahap demi tahap tanpa menebak.

## Cara pakai

1. Simpan dokumen ini sebagai `SPEC.md` di root repo (folder di atas `go_rent_app/` dan `go_rent_api/`).
2. Di setiap prompt, sebut file ini: "Ikuti @SPEC.md bagian X". Agent akan membaca aturan, nama file, dan bentuk data dari sini.
3. Kerjakan prompt di bagian **Urutan prompt** satu per satu. Jalankan dan cek hasil setiap tahap sebelum lanjut, lalu commit ke GitHub.
4. Kalau agent menyimpang dari spesifikasi (misalnya menambah package atau mengganti nama file), minta ia kembali ke `SPEC.md`.
5. Acuan visual: mockup gambar 1 sampai 3 dan kanvas [Flowchart, Desain & Prototipe](https://claude.ai/artifact/AJZv66swjoaEUx82hZCZ6u). Warna, ukuran, dan nama komponen di bagian Desain wajib diikuti.

## Ringkasan, scope, dan aturan

GO-RENT adalah aplikasi sewa mobil di area Purwokerto. User mencari mobil (lepas kunci atau dengan sopir), melihat detail dan titik pickup di peta, lalu booking dalam 3 langkah: Vehicle, Details, Payment. Data mobil awal diambil dari `data rental.txt` (20 mobil, 3 notifikasi, 1 profil) dan dipindah ke database MySQL lewat seeder.

**Keputusan yang sudah tetap**

- Frontend: Dart + Flutter. Backend: REST API Node.js + Express + MySQL (XAMPP). Soal membolehkan CI4, Node.js, atau framework lain, dan versi ini memakai Node.js. Pola REST, uji Postman, dan ngrok tetap mengikuti modul P10 dan P11.
- State management: `provider` (satu `ChangeNotifier` bernama `RentalProvider`).
- Peta titik pickup: `flutter_map` + OpenStreetMap, interaktif (bisa digeser dan di-zoom).
- Bottom navigation 4 tab: Home, My Bookings (ikon mobil), Notifications, Profile.
- **Tanpa halaman login.** Aplikasi selalu memakai user `id = 1` (Eggy Andrean), disimpan sebagai konstanta `currentUserId` di Flutter.
- Upload SIM/KTP berupa simulasi: tombol upload hanya menandai `sim_uploaded = true`, belum memakai kamera atau galeri.
- Total harga dihitung otomatis: `jumlah_hari × price_per_day + asuransi`. Asuransi Rp 80.000 bisa dimatikan. Server menghitung ulang total, angka dari aplikasi tidak dipercaya.

**Di luar scope versi ini:** login dan registrasi, pembayaran sungguhan, upload file sungguhan, push notification, dan halaman admin.

**Aturan untuk AI agent**

1. Gaya kode dekat dengan materi kuliah: class model dengan `fromJson`/`toJson`, `StatefulWidget` untuk form, `ListView.builder`/`GridView.builder`, extract widget, dan pesan error lewat `SnackBar` (pola `tampilkanPesan()` dari P6).
2. Jangan menambah package selain yang ada di bagian Tech stack. Tanyakan dulu kalau merasa perlu.
3. Beri komentar Bahasa Indonesia di setiap blok penting. Nama variabel dan class dalam English camelCase/PascalCase.
4. Setiap pemanggilan API dibungkus `try`/`catch`. Kalau gagal, tampilkan SnackBar berisi pesan dari backend, dan aplikasi tidak boleh crash.
5. Satu tahap = satu fitur yang bisa dijalankan, lalu berhenti untuk dicek.

## Tech stack dan struktur folder

Satu repo GitHub berisi dua folder: `go_rent_app` (Flutter) dan `go_rent_api` (Node.js + Express).

| Bagian | Pakai | Versi | Untuk |
| --- | --- | --- | --- |
| Flutter SDK | Flutter + Dart | 3.27 ke atas | Syarat minimum `flutter_map` 8 |
| State | `provider` | ^6.1.2 | `RentalProvider` lintas layar |
| HTTP | `http` | ^1.2.2 | Akses REST API (materi P11) |
| Peta | `flutter_map` + `latlong2` | ^8.1.0 + ^0.9.1 | Peta titik pickup |
| Format | `intl` | ^0.20.2 | Rupiah dan tanggal |
| Backend | Node.js + Express | Node.js 22 LTS ke atas, Express ^5.1.0, mysql2 ^3.11, cors ^2.8.5, dotenv ^16.4 | REST API |
| Database | MySQL lewat XAMPP | bawaan XAMPP | 9 tabel |
| Uji API | Postman, ngrok (opsional) | terbaru | Tes endpoint, akses dari HP |

**Struktur Flutter**

```
go_rent_app/lib/
  main.dart                  // MultiProvider + MaterialApp + theme
  config/constants.dart      // baseUrl, currentUserId, warna, biayaAsuransi, lokasiList
  models/                    // car.dart, booking.dart, notification_item.dart,
                             // user_profile.dart, payment_method.dart, provider_info.dart
  services/api_service.dart  // semua panggilan http (GET/POST/PUT/DELETE)
  providers/rental_provider.dart
  utils/formatter.dart       // formatRupiah(), formatTanggalRange()
  screens/                   // main_screen.dart (bottom nav), home_screen.dart,
                             // search_result_screen.dart, vehicle_detail_screen.dart,
                             // booking_screen.dart, my_bookings_screen.dart,
                             // notification_screen.dart, profile_screen.dart
  widgets/                   // car_card.dart, popular_car_card.dart, search_form.dart,
                             // rental_type_toggle.dart, car_carousel.dart,
                             // pickup_map.dart, booking_stepper.dart,
                             // notification_card.dart, go_rent_app_bar.dart
```

**Struktur Node.js (Express)**

```
go_rent_api/
  package.json               // "type": "module", script dev, start, seed
  .env.example               // PORT=8080, DB_HOST, DB_USER, DB_PASS, DB_NAME=go_rent
  .gitignore                 // node_modules/ dan .env
  server.js                  // express.json, cors, static public, routes, error handler
  config/db.js               // pool mysql2/promise (decimalNumbers, dateStrings)
  database/schema.sql        // CREATE TABLE 9 tabel, urut sesuai foreign key
  database/data_rental.json  // hasil konversi data rental.txt
  database/car_images.json   // URL foto online per car_id (boleh kosong)
  database/seed.js           // isi semua tabel (npm run seed)
  routes/                    // cars.js, users.js, paymentMethods.js, bookings.js,
                             // notifications.js, favorites.js
  controllers/               // carController.js, userController.js, dst. (satu per route)
  utils/imageUrl.js          // path relatif -> URL penuh sesuai host request
  public/images/cars/        // opsional nanti: foto lokal {car_id}_{n}.jpg
```

## Gambar dan aset

Gambar di aplikasi dibagi tiga jenis. Masing-masing punya sumber dan cara tampil yang berbeda.

| Jenis gambar | Contoh di mockup | Disimpan di | Ditampilkan dengan |
| --- | --- | --- | --- |
| Foto mobil (data) | Kartu mobil di Home, hasil Search, carousel Vehicle Detail, kartu My Bookings | URL online di car\_images.image\_url. Opsi nanti: `go_rent_api/public/images/cars/` | `Image.network(car.images[i])` lewat widget CarImage, placeholder simulasi jika kosong atau gagal |
| Gambar UI statis | Logo GO-RENT, avatar profil, placeholder mobil, ilustrasi daftar kosong | Flutter: `assets/images/` | `Image.asset(...)` |
| Ikon dan peta | Ikon nav bar, ikon specs, peta pickup | Material Icons dan tile OpenStreetMap | `Icon(Icons.xxx)` dan `flutter_map` TileLayer |

**Pilihan yang dipakai: foto online + simulasi.** Versi ini tidak menyimpan file foto sendiri. Tabel `car_images` berisi URL foto mobil asli dari internet. Kalau URL kosong atau gagal dimuat, aplikasi menampilkan gambar simulasi yang digambar Flutter sendiri. Nanti foto bisa diganti ke file lokal atau hasil AI cukup dengan mengubah isi `image_url`, tanpa mengubah kode Flutter.

| Opsi | Kelebihan | Kekurangan | Status |
| --- | --- | --- | --- |
| URL foto online (Pexels, Unsplash) | Foto mobil asli, tanpa upload file, pola sama dengan materi P5 (gambar dari URL) | Butuh internet, link bisa mati, model persis kadang tidak ada | Dipakai, utama |
| Simulasi (placeholder digambar Flutter) | Selalu jalan, offline, tanpa file | Bukan foto asli | Dipakai, cadangan |
| File di `public/images/cars/` (foto sendiri atau hasil AI) | Paling seragam dan rapi | Harus menyiapkan 20 sampai 60 file | Opsional, nanti |

### Foto mobil: URL online

**Sudah disiapkan:** file `car_images.json` berisi 20 foto mobil asli dari Wikimedia Commons, satu per mobil. Salin ke `go_rent_api/database/`. Setiap URL memakai bentuk `https://commons.wikimedia.org/wiki/Special:FilePath/<nama file>?width=960`, yang otomatis diarahkan ke gambar selebar 960 px. Foto Commons berlisensi Creative Commons (umumnya CC BY-SA) yang wajib atribusi, jadi salin tabel dari `sumber_foto_mobil.md` ke README. Pexels atau Unsplash tetap bisa dipakai untuk menambah foto ke-2 dan ke-3 dengan cara di bawah.

- Seeder membaca `database/car_images.json` berbentuk `{ "1": ["https://...", "https://..."], "2": [] }`. Satu mobil boleh berisi 0 sampai 3 URL. Mobil dengan daftar kosong tetap tampil dengan gambar simulasi.
- Cara mengambil URL: buka Pexels atau Unsplash, cari nama mobil (misalnya "Toyota Fortuner"), buka fotonya, klik kanan pada gambar, lalu pilih **Copy image address**. Hasilnya harus diawali `https://images.pexels.com/` atau `https://images.unsplash.com/`, bukan link halaman `pexels.com/photo/...`.
- Tambahkan parameter ukuran supaya ringan: Pexels `?auto=compress&cs=tinysrgb&w=800`, Unsplash `?w=800&q=80`.
- Kalau model persis tidak ada, pakai mobil dengan tipe dan warna yang mirip (misalnya MPV putih untuk Avanza).
- Pexels dan Unsplash gratis dipakai tanpa atribusi wajib. Tetap catat sumber tiap foto di README.
- `utils/imageUrl.js`: URL yang diawali `http` dikembalikan apa adanya. Path relatif (untuk opsi file lokal nanti) diubah menjadi URL penuh dengan `` `${req.protocol}://${req.get('host')}/${imageUrl}` ``.

### Gambar simulasi

Widget `CarImagePlaceholder` (di `widgets/car_image.dart`) menggambar placeholder tanpa file apa pun:

- Kotak rasio 4:3 dengan gradasi tint `0xFFEAF0F7` ke `0xFFD5E0EE` dan sudut membulat sesuai kartu.
- Ikon di tengah sesuai `type`: `Icons.airport_shuttle` untuk MPV, `Icons.electric_car` untuk Electric, dan `Icons.directions_car_filled` untuk lainnya. Ukuran 64, warna navy `0xFF1E3A5F` dengan opacity 0.6.
- Nama mobil kecil di bawah ikon, ditambah label "Simulasi foto".
- Di carousel Vehicle Detail, mobil tanpa foto tetap punya 3 slide simulasi berlabel "Tampak depan", "Tampak samping", dan "Interior" (ikon `Icons.event_seat`), supaya titik indikator dan `Timer` tetap bisa diuji.

Mobil yang baru punya 1 foto: slide pertama carousel memakai foto asli, slide kedua dan ketiga memakai simulasi ("Tampak samping" dan "Interior"), jadi carousel selalu berisi 3 slide.

### Aset Flutter

- Folder: `go_rent/assets/images/` berisi `logo.png`, `avatar.png` (sesuai `avatar_url` di `userProfile`), dan `empty_bookings.png` (ilustrasi saat My Bookings masih kosong).
- Daftarkan di `pubspec.yaml`, di bawah `flutter:` dengan indentasi 2 spasi:

```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/images/
```

- Avatar: kalau `avatar_url` diawali `http`, tampilkan dengan `NetworkImage`, kalau tidak, dengan `AssetImage`. Logika ini cukup satu helper di `utils/`.

### Widget gambar mobil

Buat satu widget `widgets/car_image.dart` yang dipakai di semua tempat, supaya penanganan loading dan error cukup ditulis sekali:

- Parameter: `url` (boleh null), `car` (untuk nama dan type di placeholder), `height`, `borderRadius`.
- `url` null atau kosong: langsung tampilkan `CarImagePlaceholder`, tanpa request jaringan.
- `loadingBuilder`: kotak tint dengan `CircularProgressIndicator` kecil.
- `errorBuilder`: tampilkan `CarImagePlaceholder` (misalnya saat offline atau link mati), jangan biarkan muncul ikon error merah.
- `fit: BoxFit.cover` dan `ClipRRect` untuk sudut membulat sesuai kartu di mockup.
- Hero animation opsional dengan tag `car-${car.id}` dari kartu ke Vehicle Detail.

`Image.network` diberi `headers: {'User-Agent': 'GoRentApp/1.0 (tugas kuliah)'}`, karena Wikimedia bisa menolak request yang User-Agent-nya terlalu umum. Kalau foto tetap gagal, `errorBuilder` menampilkan simulasi.

### Prompt AI untuk foto mobil (opsional, untuk nanti)

Setiap mobil butuh 3 foto: `_1` tampak 3/4 depan (untuk kartu dan slide pertama carousel), `_2` tampak samping, dan `_3` interior. Prompt ditulis dalam English karena model gambar seperti Nano Banana (Gemini, modul P13) lebih patuh pada prompt English. Ke-60 prompt siap tempel (20 mobil × 3 foto) ada di file `prompt_gambar_mobil.txt`. Di bawah ini template dan warna per mobil.

**Supaya 20 mobil terlihat seragam**

1. Generate `1_1.jpg` dulu sampai hasilnya pas, lalu jadikan gambar referensi.
2. Untuk mobil lain, lampirkan `1_1.jpg` (atau `1_3.jpg` untuk interior) dan tempel kalimat referensi di akhir prompt.
3. Crop ke 800×600, kompres di bawah 200 KB, lalu simpan di `go_rent_api/public/images/cars/` dengan nama sesuai tabel.
4. AI sering merusak logo, emblem, dan teks plat nomor, jadi prompt meminta plat kosong. Generate ulang jika bentuk mobil jelas tidak mirip aslinya.

**Template foto luar** (ganti `{WARNA}`, `{MOBIL}`, `{TIPE}`, dan `{SUDUT}`):

```text
Professional studio product photo of a {WARNA} {MOBIL} ({TIPE}), {SUDUT}. Car parked on a seamless light grey studio floor with a soft natural shadow, plain light grey background (#EEF1F5), soft diffused studio lighting, realistic, sharp focus, high detail, accurate real-world body shape of this exact model, blank license plate, no people, no text, no watermark. Landscape 4:3.
```

- `_1`: `front three-quarter view from the front left, camera at headlight height`
- `_2`: `full side profile facing left, the whole car visible`

**Template interior** (`_3`):

```text
Interior photo of a {MOBIL}, view of the dashboard and steering wheel from the middle of the rear seat, {WARNA INTERIOR} interior, soft daylight from the windows, realistic, sharp focus, no people, no text, no watermark. Landscape 4:3.
```

**Kalimat referensi** (ditempel di akhir prompt mulai mobil kedua):

```text
Match the background, lighting, camera height and framing of the attached reference image exactly. Only change the car.
```

| ID | Mobil | Warna body | Warna interior | File |
| --- | --- | --- | --- | --- |
| 1 | Toyota Avanza 2023 | silver metallic | black fabric | `1_1.jpg`, `1_2.jpg`, `1_3.jpg` |
| 2 | Hyundai Creta Prime | white | black and grey | `2_1.jpg`, `2_2.jpg`, `2_3.jpg` |
| 3 | Honda Brio RS | bright yellow | black with orange stitching | `3_1.jpg`, `3_2.jpg`, `3_3.jpg` |
| 4 | Mitsubishi Pajero Sport | black | black leather | `4_1.jpg`, `4_2.jpg`, `4_3.jpg` |
| 5 | Suzuki Ertiga Hybrid | maroon red metallic | beige and black | `5_1.jpg`, `5_2.jpg`, `5_3.jpg` |
| 6 | Toyota Fortuner VRZ | pearl white | dark brown leather | `6_1.jpg`, `6_2.jpg`, `6_3.jpg` |
| 7 | Daihatsu Rocky | turquoise blue | black | `7_1.jpg`, `7_2.jpg`, `7_3.jpg` |
| 8 | Honda HR-V SE | meteoroid grey metallic | black | `8_1.jpg`, `8_2.jpg`, `8_3.jpg` |
| 9 | Toyota Alphard | black | beige leather | `9_1.jpg`, `9_2.jpg`, `9_3.jpg` |
| 10 | Wuling Air EV | mint green with a white roof | light grey and white | `10_1.jpg`, `10_2.jpg`, `10_3.jpg` |
| 11 | Nissan Kicks e-Power | orange with a black roof | black and orange | `11_1.jpg`, `11_2.jpg`, `11_3.jpg` |
| 12 | Mazda CX-5 | deep crystal red | black leather | `12_1.jpg`, `12_2.jpg`, `12_3.jpg` |
| 13 | Toyota Innova Zenix | bronze metallic | black leather | `13_1.jpg`, `13_2.jpg`, `13_3.jpg` |
| 14 | Honda Civic RS | deep blue metallic | black with red stitching | `14_1.jpg`, `14_2.jpg`, `14_3.jpg` |
| 15 | Daihatsu Xenia 2023 | dark grey metallic | black fabric | `15_1.jpg`, `15_2.jpg`, `15_3.jpg` |
| 16 | BMW 320i Sport | alpine white | black leather | `16_1.jpg`, `16_2.jpg`, `16_3.jpg` |
| 17 | Toyota Raize Turbo | red with a black roof | black | `17_1.jpg`, `17_2.jpg`, `17_3.jpg` |
| 18 | Isuzu Mu-X | titanium silver | black leather | `18_1.jpg`, `18_2.jpg`, `18_3.jpg` |
| 19 | Mini Cooper S | British racing green with a white roof | black leather | `19_1.jpg`, `19_2.jpg`, `19_3.jpg` |
| 20 | Toyota Veloz 2024 | pearl white with a black roof | black and grey | `20_1.jpg`, `20_2.jpg`, `20_3.jpg` |

## Database dan REST API (Node.js)

Database `go_rent` punya 9 tabel: 3 tabel master (`providers`, `users`, `payment_methods`), 1 tabel inti (`cars`), dan 5 tabel child yang punya foreign key. Ini memenuhi syarat minimal 6 tabel berelasi.

| Tabel | Kolom (selain `id` PK auto increment) | Relasi |
| --- | --- | --- |
| `providers` | `name` varchar(100) unique, `address` varchar(255), `latitude` decimal(10,7), `longitude` decimal(10,7) | Master |
| `users` | `name`, `email` unique, `phone`, `is_verified` tinyint, `driving_license` varchar(100), `avatar_url` | Master |
| `payment_methods` | `name` varchar(50): OVO, GoPay, Bank Transfer | Master |
| `cars` | `provider_id`, `name`, `type`, `rental_type` enum('Lepas Kunci','Dengan Sopir'), `seats` tinyint, `transmission` varchar(20), `rating` decimal(2,1), `price_per_day` int | `provider_id` ke `providers` |
| `car_images` | `car_id`, `image_url`, `sort_order` tinyint | `car_id` ke `cars`, ON DELETE CASCADE |
| `car_specs` | `car_id`, `spec_name` varchar(100) | `car_id` ke `cars`, ON DELETE CASCADE |
| `bookings` | `booking_code` varchar(20) unique, `user_id`, `car_id`, `payment_method_id`, `renter_name`, `pickup_location`, `dropoff_location`, `pickup_date` date, `dropoff_date` date, `days` int, `price_per_day` int, `insurance_fee` int, `total_price` int, `sim_uploaded` tinyint, `status` enum('Confirmed','Completed','Cancelled'), `created_at`, `updated_at` | ke `users`, `cars`, `payment_methods` |
| `notifications` | `user_id`, `booking_id` nullable, `title`, `description`, `type` enum('order','promo','reminder'), `is_read` tinyint, `created_at` | ke `users`; `booking_id` ke `bookings`, ON DELETE SET NULL |
| `favorites` | `user_id`, `car_id`, unique(`user_id`, `car_id`) | ke `users` dan `cars` |

**Seeder (`database/seed.js`)** memindahkan isi `data rental.txt`: 20 mobil beserta specs dan gambar (URL foto online dari database/car\_images.json; mobil tanpa URL dikirim dengan images kosong), 11 provider unik dari field `provider`, user Ahmad Fauzi, 3 metode bayar, dan 3 notifikasi. Koordinat provider pakai titik contoh di sekitar pusat Purwokerto (-7.4245, 109.2340), digeser sedikit per provider. Tambahkan juga satu booking contoh `GR20230426` (Toyota Avanza 2023, 26 sampai 28 Apr 2023, status Completed) supaya notifikasi pertama punya data booking.

**Endpoint** (base URL `http://localhost:8080`, dari emulator Android `http://10.0.2.2:8080`)

| Method | Path | Fungsi |
| --- | --- | --- |
| GET | `/cars?rental_type=&type=&transmission=&min_price=&max_price=&sort=` | Daftar mobil + provider, `images`, `vehicle_specs`, `is_favorite`. `sort`: `rating`, `price_asc`, `price_desc` |
| GET | `/cars/{id}` | Detail satu mobil, bentuk sama |
| GET | `/users/1` | Profil user |
| PUT | `/users/1` | Ubah `name`, `phone` (Account Settings) |
| GET | `/payment-methods` | OVO, GoPay, Bank Transfer |
| GET | `/bookings?user_id=1` | My Bookings, terbaru dulu, ikut `car_name` dan `payment_method` |
| POST | `/bookings` | Buat booking + notifikasi "Booking Confirmed" |
| PUT | `/bookings/{id}` | Ubah `status` jadi `Cancelled` |
| GET | `/notifications?user_id=1` | Daftar notifikasi, terbaru dulu |
| PUT | `/notifications/{id}` | Ubah `is_read` |
| DELETE | `/notifications/{id}` | Hapus notifikasi |
| POST | `/favorites` | Tambah favorit `{user_id, car_id}` |
| DELETE | `/favorites/{car_id}?user_id=1` | Hapus favorit |

**Bentuk JSON mobil** (sukses memakai `res.json(data)`, gagal validasi memakai `res.status(400).json({ message, errors })`, data tidak ada memakai `res.status(404).json({ message })`):

```json
{
  "id": 2, "name": "Hyundai Creta Prime", "type": "SUV",
  "rental_type": "Lepas Kunci", "seats": 5, "transmission": "Automatic",
  "rating": 4.9, "price_per_day": 450000, "is_favorite": false,
  "provider": {"id": 1, "name": "Astra Rental", "latitude": -7.4245, "longitude": 109.234},
  "images": ["https://images.pexels.com/photos/123456/pexels-photo-123456.jpeg?auto=compress&cs=tinysrgb&w=800"],
  "vehicle_specs": ["Panoramic Sunroof", "Bose Speaker", "Airbag"]
}
```

**Aturan `POST /bookings`**

- Body: `user_id`, `car_id`, `payment_method_id`, `renter_name`, `pickup_location`, `dropoff_location`, `pickup_date`, `dropoff_date` (format `YYYY-MM-DD`), `with_insurance` (bool), `sim_uploaded` (bool).
- Validasi: semua wajib; `renter_name` minimal 3 huruf; `dropoff_date` harus setelah `pickup_date`; `sim_uploaded` harus true. Gagal = status 400 dengan pesan per field.
- Server menghitung `days = dropoff_date - pickup_date` (minimal 1), `insurance_fee = 80000` atau 0, dan `total_price = days × price_per_day + insurance_fee`.
- `booking_code` = `GR` + tanggal pickup `Ymd` + nomor urut 2 digit di hari itu, contoh `GR2026042401`.
- Setelah booking tersimpan, buat baris `notifications`: title "Booking Confirmed", description "Booking #{kode} for {nama mobil} is confirmed.", type `order`, `is_read` 0. Balas 201 dengan data booking.

## Aplikasi Flutter

**Theme** (`config/constants.dart`): navy `0xFF1E3A5F` untuk AppBar dan tombol utama, navy light `0xFF2B4C75` untuk kartu form Home, hijau `0xFF1F7A45` untuk Book Now, latar `0xFFF4F6FA`, tint `0xFFEAF0F7`, error `0xFFB42318`, bintang `0xFFF5A524`. Font bawaan (Roboto). Kartu radius 12, tombol radius 8 sampai 10, tinggi tombol utama 48.

**Konstanta:** `baseUrl`, `currentUserId = 1`, `biayaAsuransi = 80000`, `lokasiList = ['Purwokerto', 'Banyumas', 'Purbalingga', 'Cilacap']`.

**`RentalProvider`** (extends `ChangeNotifier`) menyimpan:

- Form pencarian: `pickupLocation`, `dropoffLocation`, `pickupDate`, `dropoffDate`, `rentalType` (default "Lepas Kunci").
- Filter dan sort: `filterSuv`, `filterAutomatic`, `filterPrice` (Rp 300.000 sampai 500.000), `sortBy` (`default`, `rating`, `price_asc`, `price_desc`).
- Data dari API: `cars`, `bookings`, `notifications`, `user`, `paymentMethods`, plus `isLoading` dan `errorMessage`.
- Navigasi: `currentTab` (0 sampai 3) supaya layar lain bisa pindah tab, misalnya setelah Pay Now.
- Getter: `searchError` (pesan validasi atau null), `jumlahHari`, `dateLabel` ("24 - 26 Apr"), `popularCars` (sesuai `rentalType`, urut rating, ambil 6), `filteredCars`, `unreadCount`.
- Method: `loadCars()`, `loadBookings()`, `loadNotifications()`, `loadUser()`, `toggleFavorite(car)`, `createBooking(...)`, `cancelBooking(id)`, `markAsRead(id)`, `deleteNotification(id)`, `updateUser(name, phone)`, `changeTab(i)`.

**Layar**

1. **MainScreen**: `Scaffold` + `IndexedStack` + `BottomNavigationBar` 4 tab. Label hanya tampil di tab aktif. Ikon lonceng memakai `Badge` berisi `unreadCount`.
2. **Home**: header navy berisi avatar inisial, judul GO-RENT, ikon My Bookings, dan lonceng bertitik merah jika ada notifikasi belum dibaca. Kartu "Where to, {lokasi}?" berisi 2 `DropdownButton` lokasi dan 2 field tanggal (`showDatePicker`, tanggal pertama = hari ini). Di bawahnya toggle Lepas Kunci/Dengan Sopir, tombol **Cari Mobil**, dan Popular Vehicles (`ListView.builder` horizontal, label tipe + nama). Cari Mobil menjalankan validasi `searchError`: gagal = SnackBar, sukses = ke Search Results. See All langsung ke Search Results tanpa validasi.
3. **Search Results**: AppBar "{lokasi} | {dateLabel}" (atau "Semua lokasi | Pilih tanggal"). Tombol Sort & Filter membuka `showModalBottomSheet` berisi pilihan sort. Chip `FilterChip`: SUV (tipe mengandung "SUV"), Automatic, Rp 300k-500k, Rating (sort rating). Daftar `CarCard`: foto, nama, kursi, transmisi, rating, harga/day, tombol Book Now. Jika kosong tampilkan "Tidak ada mobil yang cocok".
4. **Vehicle Detail**: `CarCarousel` = `PageView` + titik indikator + `Timer.periodic` 3,5 detik (materi P11), dengan tombol back dan favorit di atasnya. Lalu nama, rating, chip provider, Vehicle Specs (kursi, transmisi, lalu `vehicle_specs`), Rental Includes (Insurance, 24/7 Support, ditambah Sopir profesional jika Dengan Sopir), dan `PickupMap` (`FlutterMap` tinggi 170, `TileLayer` OSM, `MarkerLayer` di koordinat provider, zoom 15). Bar bawah berisi harga dan Continue to Booking. Jika `searchError` tidak null, buka bottom sheet `SearchForm` (widget yang sama dengan Home), baru lanjut ke Booking.
5. **Complete Booking**: `BookingStepper` 3 langkah (selesai hijau, aktif navy, belum abu) + `IndexedStack`. Langkah sebelumnya bisa diketuk untuk kembali.
   - Vehicle: foto, nama, rating, provider, Total Price, Driver Information (nama user dan SIM; jika Dengan Sopir tampil "Sopir dari {provider}").
   - Details: tanggal, lokasi pickup dan drop-off, rincian "{n} Days Rent", checkbox Insurance Add-on Rp 80.000, dan Total.
   - Payment: ringkasan, `TextFormField` Renter Name (validator min. 3 huruf), tombol upload SIM/KTP (simulasi), dan `RadioListTile` metode bayar dari API.
   - Pay Now: validasi gaya P6 (`sudahValid()` + SnackBar), lalu `AlertDialog` konfirmasi, lalu `POST /bookings`. Sukses = dialog "Booking Berhasil", muat ulang bookings dan notifikasi, kembali ke MainScreen tab My Bookings.
6. **My Bookings**: daftar booking (kode, mobil, tanggal, lokasi, jumlah hari, metode bayar, total, chip status). Status Confirmed punya tombol Batalkan dengan `AlertDialog`. Pull-to-refresh (`RefreshIndicator`).
7. **Notifications**: `NotificationCard` dengan titik dan label "Belum dibaca"/"Sudah dibaca", ikon sesuai `type`, judul, deskripsi, dan waktu relatif dari `created_at` ("2 hours ago"). Ketuk kartu = tandai dibaca, tombol × = hapus. Tombol "Tandai semua" di AppBar.
8. **Profile**: header navy melengkung, avatar (`Image.asset` dengan `errorBuilder` ke inisial), nama, chip Verified. Menu: Account Settings (bottom sheet form nama dan HP, `PUT /users/1`), Personal Information, Payment Methods, Driving License, Booking History (pindah ke tab My Bookings), Support & Help (`AlertDialog`), dan Log Out (`AlertDialog` konfirmasi saja, karena belum ada halaman login).

**Format:** harga `NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0)` menghasilkan "Rp 450.000". Tanggal satu bulan "24 - 26 Apr", beda bulan "30 Apr - 2 May".

## Urutan prompt vibe coding

Kerjakan 10 tahap ini berurutan. Setiap prompt memakai format goal-driven dari modul P13 (tujuan, spesifikasi, batasan, langkah pertama). Salin satu blok, jalankan, cek hasilnya, commit, lalu lanjut. Jika dikerjakan berkelompok, satu tahap bisa jadi satu issue GitHub untuk satu anggota.

**Tahap 1. Database (workspace `go_rent_api`)**

```text
[Tujuan] Siapkan project backend Node.js + Express dan database go_rent sesuai @SPEC.md bagian "Database dan REST API".
[Spesifikasi] npm init, pasang express, mysql2, cors, dotenv. Buat .env.example, .gitignore, config/db.js (pool mysql2/promise dengan decimalNumbers: true dan dateStrings: true), dan database/schema.sql berisi CREATE TABLE 9 tabel (urut: providers, users, payment_methods, cars, car_images, car_specs, bookings, notifications, favorites) lengkap dengan foreign key. Konversi @data_rental.txt (format Dart) menjadi database/data_rental.json, lalu buat database/seed.js yang mengosongkan tabel dan mengisi semua data, ditambah booking contoh GR20230426. car_images diisi dari database/car_images.json (URL foto online, boleh kosong untuk mobil yang belum punya foto).
[Batasan] Tanpa ORM (tanpa Sequelize atau Prisma), cukup query SQL dengan placeholder ? lewat mysql2. Beri komentar Bahasa Indonesia.
[Langkah pertama] Tunjukkan daftar kolom per tabel dulu, lalu buat file-nya. Saya akan import schema.sql di phpMyAdmin, lalu menjalankan npm run seed.
```

**Tahap 2. REST API**

```text
[Tujuan] Buat semua endpoint di tabel Endpoint pada @SPEC.md dengan Express.
[Spesifikasi] server.js memakai express.json(), cors(), express.static('public'), dan satu error handler terpusat. Satu file routes dan satu controller per resource (cars, users, paymentMethods, bookings, notifications, favorites). GET /cars mengembalikan provider, images (URL penuh lewat utils/imageUrl.js), vehicle_specs, dan is_favorite. POST /bookings mengikuti "Aturan POST /bookings" (hitung total di server, simpan booking dan notifikasi dalam satu transaksi). Script npm: "dev": "node --watch server.js", "start": "node server.js", "seed": "node database/seed.js".
[Batasan] Validasi ditulis manual di controller, tanpa library tambahan. Error validasi = status 400 { message, errors }, data tidak ada = 404 { message }. Semua query memakai placeholder ?, bukan string yang digabung.
[Langkah pertama] Buat endpoint cars dulu, beri saya contoh request Postman, baru lanjut ke resource lain.
```

**Tahap 3. Setup Flutter (workspace `go_rent_app`)**

```text
[Tujuan] Siapkan fondasi app Flutter GO-RENT sesuai @SPEC.md bagian "Tech stack" dan "Aplikasi Flutter".
[Spesifikasi] Tambahkan package provider, http, flutter_map, latlong2, intl. Buat config/constants.dart (warna, baseUrl, currentUserId, biayaAsuransi, lokasiList), ThemeData, semua model dengan fromJson/toJson, utils/formatter.dart, dan services/api_service.dart untuk semua endpoint.
[Batasan] Jangan buat UI dulu. Semua method api_service memakai try/catch dan melempar pesan error dari backend.
[Langkah pertama] Tampilkan isi pubspec.yaml dan daftar file yang akan dibuat.
```

**Tahap 4. Provider dan bottom navigation**

```text
[Tujuan] Buat RentalProvider dan MainScreen sesuai @SPEC.md.
[Spesifikasi] RentalProvider berisi state, getter, dan method yang tertulis di spesifikasi. MainScreen memakai IndexedStack + BottomNavigationBar 4 tab dengan Badge unreadCount. main.dart memakai ChangeNotifierProvider. Isi tiap tab sementara cukup Text judul.
[Batasan] Hanya provider, tanpa state management lain.
```

**Tahap 5. Home**

```text
[Tujuan] Buat HomeScreen seperti mockup gambar 1 (Home) dan prototipe.
[Spesifikasi] Extract widget: GoRentAppBar, SearchForm (DropdownButton lokasi + showDatePicker), RentalTypeToggle, PopularCarCard. Tombol Cari Mobil memvalidasi searchError lalu ke SearchResultScreen. See All tanpa validasi.
[Batasan] SearchForm harus bisa dipakai ulang di bottom sheet Vehicle Detail.
```

**Tahap 6. Search Results**

```text
[Tujuan] Buat SearchResultScreen dan CarCard seperti mockup.
[Spesifikasi] AppBar "{lokasi} | {dateLabel}", tombol Sort & Filter (showModalBottomSheet), FilterChip SUV/Automatic/Rp 300k-500k/Rating, ListView.builder CarCard dengan widget CarImage (foto online, placeholder simulasi jika kosong atau gagal), tampilan kosong, dan loading.
```

**Tahap 7. Vehicle Detail**

```text
[Tujuan] Buat VehicleDetailScreen seperti mockup.
[Spesifikasi] CarCarousel (PageView + titik + Timer.periodic 3,5 detik, timer di-cancel di dispose), tombol favorit (POST/DELETE /favorites), Vehicle Specs, Rental Includes, PickupMap (FlutterMap + TileLayer OSM dengan userAgentPackageName + MarkerLayer koordinat provider). Continue to Booking membuka bottom sheet SearchForm jika searchError tidak null.
```

**Tahap 8. Complete Booking**

```text
[Tujuan] Buat BookingScreen 3 langkah (Vehicle, Details, Payment) seperti gambar 3.
[Spesifikasi] BookingStepper + IndexedStack, total otomatis (hari x harga + asuransi opsional), TextFormField nama dengan validator, upload SIM simulasi, RadioListTile metode bayar dari API. Pay Now: validasi, AlertDialog konfirmasi, POST /bookings, dialog sukses, lalu changeTab(1) dan kembali ke MainScreen.
[Batasan] Tampilkan pesan error dari backend di SnackBar jika POST gagal.
```

**Tahap 9. My Bookings, Notifications, Profile**

```text
[Tujuan] Lengkapi tiga tab sisanya seperti gambar 2 dan prototipe.
[Spesifikasi] My Bookings dengan chip status, Batalkan (PUT status Cancelled), RefreshIndicator. Notifications dengan NotificationCard (tandai dibaca, hapus, tandai semua, waktu relatif). Profile dengan menu lengkap, Account Settings (PUT /users/1), Log Out berupa AlertDialog saja.
```

**Tahap 10. Rapikan dan uji**

```text
[Tujuan] Cek seluruh aplikasi terhadap @SPEC.md bagian "Checklist uji".
[Spesifikasi] Jalankan flutter analyze sampai bersih, perbaiki overflow di layar kecil, pastikan semua teks dan warna sesuai Desain. Buat README.md berisi cara menjalankan backend dan app.
```

## Checklist uji

Aplikasi dianggap selesai jika semua skenario ini lolos di emulator Android tanpa force close.

- [ ] Cari Mobil dengan form kosong memunculkan SnackBar, dan tanggal drop-off sebelum pick-up ditolak.
- [ ] Toggle Dengan Sopir mengganti isi Popular Vehicles dan Search Results.
- [ ] Setiap chip filter dan pilihan sort mengubah daftar, dan kombinasi tanpa hasil menampilkan teks kosong.
- [ ] Carousel bergeser sendiri, peta bisa digeser dan di-zoom, dan favorit tetap tersimpan setelah aplikasi dibuka ulang.
- [ ] Masuk ke Detail dari Popular Vehicles tanpa isi form memunculkan bottom sheet form.
- [ ] Total 2 hari Hyundai Creta = Rp 900.000 tanpa asuransi dan Rp 980.000 dengan asuransi, sama di aplikasi dan di database.
- [ ] Pay Now tanpa nama atau tanpa upload SIM ditolak dengan pesan yang jelas.
- [ ] Setelah Pay Now, booking baru muncul paling atas di My Bookings dan notifikasi baru muncul dengan badge bertambah.
- [ ] Batalkan booking, tandai notifikasi dibaca, hapus notifikasi, dan ubah nama di Account Settings tersimpan di MySQL.
- [ ] Backend dimatikan: aplikasi menampilkan pesan error, bukan layar merah.

## Gotcha yang sering muncul

- **localhost dari emulator:** di emulator Android pakai `http://10.0.2.2:8080`, bukan `localhost`. Dari HP asli pakai IP laptop atau URL ngrok (P11).
- **HTTP diblokir Android:** Android 9 ke atas menolak `http://` biasa. Tambahkan `android:usesCleartextTraffic="true"` di tag `<application>` pada `AndroidManifest.xml`, dan pastikan permission `INTERNET` ada di manifest `main`, bukan hanya `debug`.
- **ngrok:** tambahkan header `ngrok-skip-browser-warning: true` di setiap request, kalau tidak yang kembali halaman HTML, bukan JSON.
- **Angka dan tanggal dari mysql2:** kolom DECIMAL kembali sebagai string (`"4.9"`), dan kolom DATE kembali sebagai objek `Date` yang bisa bergeser satu hari karena timezone. Set `decimalNumbers: true` dan `dateStrings: true` di `createPool`. Di Dart tetap aman memakai `num.parse(json['rating'].toString())`.
- **CORS di Flutter web:** tanpa app.use(cors()) di Express, Chrome menolak request. Di emulator Android tidak masalah.
- **flutter\_map:** `TileLayer` wajib diberi `userAgentPackageName` (misalnya `com.example.go_rent_app`), kalau tidak tile OSM bisa diblokir. Peta di dalam `ListView` merebut gesture scroll, jadi beri tinggi tetap.
- **Timer carousel:** cancel `Timer` dan dispose `PageController` di `dispose()`, kalau tidak muncul error "setState() called after dispose()".
- **Foto online:** pakai URL gambar langsung (`images.pexels.com`, `images.unsplash.com`), bukan link halaman, karena link halaman mengembalikan HTML dan `Image.network` gagal. Di emulator tanpa internet semua foto berganti ke gambar simulasi, dan itu bukan bug.
- **Tanggal:** kirim tanggal ke API sebagai `YYYY-MM-DD` (`DateFormat('yyyy-MM-dd')`). Hitung jumlah hari dari tanggal tanpa jam supaya tidak meleset satu hari.
- **Error "unable to find git" saat `flutter pub get`:** jalankan `git config --global --add safe.directory C:/flutter` (catatan P09).
