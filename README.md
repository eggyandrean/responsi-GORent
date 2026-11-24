# GO-RENT

Aplikasi rental mobil area Purwokerto untuk responsi Pemrograman Mobile Lanjut. User mencari mobil (Lepas Kunci atau Dengan Sopir), melihat detail dan titik pickup di peta, booking dalam 3 langkah (Vehicle, Details, Payment), lalu mengelola booking, notifikasi, dan profil.

Spesifikasi lengkap ada di [SPEC.md](SPEC.md).

| Bagian | Teknologi | Folder |
| --- | --- | --- |
| Frontend | Flutter 3.27+ / Dart, `provider`, `http`, `flutter_map` + `latlong2`, `intl` | [`go_rent_app/`](go_rent_app) |
| Backend | Node.js 22+ / Express 5, `mysql2`, `cors`, `dotenv` (tanpa ORM) | [`go_rent_api/`](go_rent_api) |
| Database | MySQL/MariaDB dari XAMPP, database `go_rent` (9 tabel berelasi) | [`go_rent_api/database/`](go_rent_api/database) |

## 1. Menjalankan backend

1. Buka XAMPP (macOS: `manager-osx`, tab **Manage Servers**), lalu **Start** MySQL Database (dan Apache jika ingin memakai phpMyAdmin).
2. Import skema. Pilih salah satu:
   - phpMyAdmin → tab **Import** → pilih `go_rent_api/database/schema.sql`.
   - Terminal (macOS): `/Applications/XAMPP/xamppfiles/bin/mysql -u root < go_rent_api/database/schema.sql`

   `schema.sql` membuat database `go_rent` dan **menghapus 9 tabel GO-RENT yang sudah ada** sebelum membuat ulang.
3. Siapkan konfigurasi dan isi data:

   ```bash
   cd go_rent_api
   cp .env.example .env      # sesuaikan DB_USER/DB_PASS jika root XAMPP memakai password
   npm install
   npm run seed              # mengosongkan tabel lalu mengisi 20 mobil, 11 provider, 1 user, dst.
   npm run dev               # server di http://localhost:8080 (auto-restart saat file berubah)
   ```

4. Cek di browser atau Postman: `http://localhost:8080/cars`.

### Endpoint

| Method | Path | Fungsi |
| --- | --- | --- |
| GET | `/cars?rental_type=&type=&transmission=&min_price=&max_price=&sort=` | Daftar mobil + provider, images, vehicle_specs, is_favorite |
| GET | `/cars/{id}` | Detail satu mobil |
| GET / PUT | `/users/1` | Profil user / ubah `name`, `phone` |
| GET | `/payment-methods` | OVO, GoPay, Bank Transfer |
| GET | `/bookings?user_id=1` | My Bookings, terbaru dulu |
| POST | `/bookings` | Buat booking + notifikasi (total dihitung server) |
| PUT | `/bookings/{id}` | Body `{"status":"Cancelled"}` |
| GET | `/notifications?user_id=1` | Daftar notifikasi |
| PUT / DELETE | `/notifications/{id}` | Ubah `is_read` / hapus |
| POST / DELETE | `/favorites`, `/favorites/{car_id}?user_id=1` | Tambah / hapus favorit |

Format error: validasi gagal `400 { message, errors }`, data tidak ada `404 { message }`, database mati `503 { message }`.

Contoh body Postman untuk `POST /bookings` (raw JSON). Hyundai Creta 2 hari + asuransi menghasilkan `total_price` 980000:

```json
{
  "user_id": 1, "car_id": 2, "payment_method_id": 1,
  "renter_name": "Eggy Andrean",
  "pickup_location": "Purwokerto", "dropoff_location": "Purwokerto",
  "pickup_date": "2026-12-01", "dropoff_date": "2026-12-03",
  "with_insurance": true, "sim_uploaded": true
}
```

## 2. Menjalankan aplikasi Flutter

```bash
cd go_rent_app
flutter pub get
flutter run            # pilih emulator/perangkat yang tersedia
```

Alamat backend diatur di `go_rent_app/lib/config/constants.dart` (`baseUrl`):

| Target | Alamat yang dipakai |
| --- | --- |
| Emulator Android | `http://10.0.2.2:8080` (otomatis) |
| iOS Simulator, Chrome (Flutter web) | `http://localhost:8080` (otomatis) |
| HP asli | Ganti `baseUrl` dengan IP laptop (misalnya `http://192.168.1.10:8080`) atau URL ngrok |

Catatan:

- Android sudah diberi izin `INTERNET` dan `usesCleartextTraffic="true"` supaya `http://` bisa dipakai.
- Aplikasi tidak punya halaman login dan selalu memakai user `id = 1`.
- Upload SIM/KTP masih simulasi (hanya menandai sudah upload).
- Foto mobil diambil dari Wikimedia Commons. Di **Flutter web** foto tersebut ditolak browser (redirect tanpa header CORS), jadi yang tampil gambar simulasi. Di Android/iOS foto dimuat langsung. Jika foto gagal (offline, link mati), aplikasi juga menampilkan gambar simulasi.
- Peta memakai tile OpenStreetMap publik; pemakaian tunduk pada [OSM Tile Usage Policy](https://operations.osmfoundation.org/policies/tiles/).

## 3. Pengujian

```bash
cd go_rent_app
flutter analyze
flutter test
```

Tes memakai API palsu (`test/fake_api.dart`), jadi tidak butuh backend. Yang diuji antara lain validasi form pencarian, filter dan sort, carousel, total booking 900.000 / 980.000, alur Pay Now, batal booking, notifikasi, Account Settings, dan tampilan saat backend mati. Tes widget memakai layar 360 × 640 supaya overflow ikut terdeteksi.

Status checklist uji dari SPEC.md ada di bagian berikut.

## 4. Status checklist uji (SPEC.md)

Diperiksa pada 24 November 2026. "Tes" = tes otomatis di `go_rent_app/test/`; "Backend asli" = dijalankan ke Express + MySQL XAMPP; "Chrome" = dijalankan sebagai Flutter web.

| Skenario | Status | Cara memeriksa |
| --- | --- | --- |
| Cari Mobil dengan form kosong memunculkan SnackBar; drop-off sebelum pick-up ditolak | Lolos | Tes (`home_screen_test`, `rental_provider_test`); date picker drop-off juga dibatasi minimal H+1 dari pick-up |
| Toggle Dengan Sopir mengganti Popular Vehicles dan Search Results | Lolos | Tes |
| Setiap chip filter dan sort mengubah daftar; kombinasi tanpa hasil menampilkan teks kosong | Lolos | Tes (`search_result_screen_test`) |
| Carousel bergeser sendiri, peta bisa digeser/di-zoom, favorit tetap tersimpan setelah aplikasi dibuka ulang | Lolos | Tes (carousel), Chrome (peta OSM tampil), backend asli (favorit tetap `true` setelah provider baru memuat ulang) |
| Masuk Detail dari Popular Vehicles tanpa isi form memunculkan bottom sheet form | Lolos | Tes (`vehicle_detail_screen_test`, `home_screen_test`) |
| Total 2 hari Hyundai Creta = Rp 900.000 / Rp 980.000 (asuransi), sama di aplikasi dan database | Lolos | Tes + backend asli (baris `bookings.total_price` = 900000 dan 980000) |
| Pay Now tanpa nama atau tanpa upload SIM ditolak dengan pesan jelas | Lolos | Tes (`booking_screen_test`) |
| Setelah Pay Now, booking baru paling atas di My Bookings dan badge notifikasi bertambah | Lolos | Backend asli |
| Batalkan booking, tandai dibaca, hapus notifikasi, ubah nama di Account Settings tersimpan di MySQL | Lolos | Tes + backend asli (dicek langsung di tabel) |
| Backend dimatikan: aplikasi menampilkan pesan error, bukan layar merah | Lolos | Tes + Chrome ("Tidak bisa terhubung ke server…" + tombol Coba lagi) |

**Belum diuji di emulator Android.** SPEC meminta semua skenario lolos di emulator Android. Emulator `Medium Phone API 37` di laptop pengembang tidak berhasil online (RAM 8 GB, AVD menyarankan 16 GB), jadi pengujian di atas dilakukan lewat tes otomatis, backend asli, dan Chrome. Jalankan `flutter run` di emulator Android (disarankan AVD API 34/35 yang lebih ringan) sebelum demo.

## 5. Struktur folder

```text
SPEC.md                  spesifikasi lengkap
docs/                    data sumber (data_rental.txt), URL dan sumber foto
go_rent_api/
  server.js              Express: cors, json, static, routes, error handler
  config/db.js           pool mysql2 (decimalNumbers, dateStrings)
  routes/ controllers/   satu file per resource
  utils/                 imageUrl.js, validation.js
  database/              schema.sql, seed.js, data_rental.json, car_images.json
go_rent_app/lib/
  main.dart              ChangeNotifierProvider + MaterialApp
  config/constants.dart  baseUrl, currentUserId, warna, tema
  models/                Car, ProviderInfo, Booking, NotificationItem, UserProfile, PaymentMethod
  services/api_service.dart
  providers/rental_provider.dart
  utils/                 formatter.dart, image_helper.dart
  screens/               main, home, search_result, vehicle_detail, booking, my_bookings, notification, profile
  widgets/               kartu, form, carousel, peta, stepper, avatar
```

## 6. Atribusi foto mobil

Foto mobil dari Wikimedia Commons (lisensi Creative Commons, umumnya CC BY-SA). Nama fotografer dan lisensi persis ada di halaman file masing-masing.

| ID | Mobil | Halaman file (lisensi dan penulis) |
| --- | --- | --- |
| 1 | Toyota Avanza 2023 | [File:2021 Toyota Avanza 1.5 G Toyota Safety Sense (Indonesia) front view 03.jpg](https://commons.wikimedia.org/wiki/File:2021_Toyota_Avanza_1.5_G_Toyota_Safety_Sense_%28Indonesia%29_front_view_03.jpg) |
| 2 | Hyundai Creta Prime | [File:2022 Hyundai Creta Prime (Indonesia) front view.jpg](https://commons.wikimedia.org/wiki/File:2022_Hyundai_Creta_Prime_%28Indonesia%29_front_view.jpg) |
| 3 | Honda Brio RS | [File:2023 Honda Brio RS (Indonesia) front view.jpg](https://commons.wikimedia.org/wiki/File:2023_Honda_Brio_RS_%28Indonesia%29_front_view.jpg) |
| 4 | Mitsubishi Pajero Sport | [File:2021 Mitsubishi Pajero Sport 2.4 Dakar 4x2 (Indonesia) front view 01.jpg](https://commons.wikimedia.org/wiki/File:2021_Mitsubishi_Pajero_Sport_2.4_Dakar_4x2_%28Indonesia%29_front_view_01.jpg) |
| 5 | Suzuki Ertiga Hybrid | [File:2019 Suzuki Ertiga GX (Indonesia) front view.jpg](https://commons.wikimedia.org/wiki/File:2019_Suzuki_Ertiga_GX_%28Indonesia%29_front_view.jpg) |
| 6 | Toyota Fortuner VRZ | [File:2020 Toyota Fortuner 2.4 VRZ TRD Sportivo 4x2 GUN165R (20220215).jpg](https://commons.wikimedia.org/wiki/File:2020_Toyota_Fortuner_2.4_VRZ_TRD_Sportivo_4x2_GUN165R_%2820220215%29.jpg) |
| 7 | Daihatsu Rocky | [File:Daihatsu Rocky Premium 2WD (5BA-A200S-GBVV) front.jpg](https://commons.wikimedia.org/wiki/File:Daihatsu_Rocky_Premium_2WD_%285BA-A200S-GBVV%29_front.jpg) |
| 8 | Honda HR-V SE | [File:2022 Honda HR-V 1.5 SE RV3 (20220807).jpg](https://commons.wikimedia.org/wiki/File:2022_Honda_HR-V_1.5_SE_RV3_%2820220807%29.jpg) |
| 9 | Toyota Alphard | [File:2019 Toyota Alphard (AH30 facelift) 2.5 G, Batu City.jpg](https://commons.wikimedia.org/wiki/File:2019_Toyota_Alphard_%28AH30_facelift%29_2.5_G%2C_Batu_City.jpg) |
| 10 | Wuling Air EV | [File:Wuling Air EV IMG005.jpg](https://commons.wikimedia.org/wiki/File:Wuling_Air_EV_IMG005.jpg) |
| 11 | Nissan Kicks e-Power | [File:2020 Nissan Kicks e-Power VL.jpg](https://commons.wikimedia.org/wiki/File:2020_Nissan_Kicks_e-Power_VL.jpg) |
| 12 | Mazda CX-5 | [File:Mazda CX-5 25S Silk Beige Selection (6BA-KF5P) front.jpg](https://commons.wikimedia.org/wiki/File:Mazda_CX-5_25S_Silk_Beige_Selection_%286BA-KF5P%29_front.jpg) |
| 13 | Toyota Innova Zenix | [File:2022 Toyota Kijang Innova Zenix V (Indonesia) front view.jpg](https://commons.wikimedia.org/wiki/File:2022_Toyota_Kijang_Innova_Zenix_V_%28Indonesia%29_front_view.jpg) |
| 14 | Honda Civic RS | [File:2022 Honda Civic RS 1.5 FE1 (20220317) 02.jpg](https://commons.wikimedia.org/wiki/File:2022_Honda_Civic_RS_1.5_FE1_%2820220317%29_02.jpg) |
| 15 | Daihatsu Xenia 2023 | [File:2022 Daihatsu Xenia 1.3 R W100RG (20220506).jpg](https://commons.wikimedia.org/wiki/File:2022_Daihatsu_Xenia_1.3_R_W100RG_%2820220506%29.jpg) |
| 16 | BMW 320i Sport | [File:BMW 320i M Sport (G20) front.jpg](https://commons.wikimedia.org/wiki/File:BMW_320i_M_Sport_%28G20%29_front.jpg) |
| 17 | Toyota Raize Turbo | [File:2021 Toyota Raize 1.0T G (Indonesia) front view.jpg](https://commons.wikimedia.org/wiki/File:2021_Toyota_Raize_1.0T_G_%28Indonesia%29_front_view.jpg) |
| 18 | Isuzu Mu-X | [File:2023 Isuzu MU-X 3.0 Ultimate 4WD Phantom Collection.jpg](https://commons.wikimedia.org/wiki/File:2023_Isuzu_MU-X_3.0_Ultimate_4WD_Phantom_Collection.jpg) |
| 19 | Mini Cooper S | [File:BMW MINI COOPER S 3DOOR (F56) front.jpg](https://commons.wikimedia.org/wiki/File:BMW_MINI_COOPER_S_3DOOR_%28F56%29_front.jpg) |
| 20 | Toyota Veloz 2024 | [File:2021 Toyota Veloz 1.5 Q (Indonesia) front view.jpg](https://commons.wikimedia.org/wiki/File:2021_Toyota_Veloz_1.5_Q_%28Indonesia%29_front_view.jpg) |

Peta: © [OpenStreetMap contributors](https://www.openstreetmap.org/copyright).
