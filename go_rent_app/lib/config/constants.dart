import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Alamat REST API GO-RENT (Node.js Express, port 8080).
// Emulator Android tidak bisa memakai localhost untuk laptop, jadi memakai 10.0.2.2.
// iOS Simulator dan Chrome (Flutter web) berjalan di laptop yang sama, jadi cukup localhost.
// Untuk HP asli, ganti dengan IP laptop atau URL ngrok (materi P11).
String get baseUrl {
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:8080';
  }
  return 'http://localhost:8080';
}

// Tanpa halaman login: aplikasi selalu memakai user id 1 (Eggy Andrean)
const int currentUserId = 1;

// Biaya asuransi opsional saat booking (server tetap menghitung ulang)
const int biayaAsuransi = 80000;

// Pilihan lokasi pickup dan drop-off
const List<String> lokasiList = [
  'Purwokerto',
  'Banyumas',
  'Purbalingga',
  'Cilacap',
];

// Header User-Agent untuk Image.network, karena Wikimedia bisa menolak User-Agent yang terlalu umum
const Map<String, String> imageHeaders = {
  'User-Agent': 'GoRentApp/1.0 (tugas kuliah)',
};

// Nama paket untuk TileLayer flutter_map, supaya tile OpenStreetMap tidak diblokir
const String userAgentPackageName = 'com.example.go_rent_app';

// Warna sesuai bagian Desain di SPEC.md
class AppColors {
  static const Color navy = Color(0xFF1E3A5F); // AppBar dan tombol utama
  static const Color navyLight = Color(0xFF2B4C75); // kartu form di Home
  static const Color green = Color(0xFF1F7A45); // tombol Book Now
  static const Color background = Color(0xFFF4F6FA); // latar layar
  static const Color tint = Color(0xFFEAF0F7); // latar chip dan placeholder
  static const Color tintDark = Color(
    0xFFD5E0EE,
  ); // ujung gradasi placeholder foto
  static const Color error = Color(0xFFB42318);
  static const Color star = Color(0xFFF5A524); // ikon rating
}

// Ukuran yang dipakai berulang
const double cardRadius = 12;
const double buttonRadius = 10;
const double buttonHeight = 48;

// Tema terpusat, dipakai di MaterialApp (main.dart)
ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.navy,
    primary: AppColors.navy,
    secondary: AppColors.green,
    error: AppColors.error,
    surface: Colors.white,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.navy,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cardRadius),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(buttonHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.navy,
        minimumSize: const Size.fromHeight(buttonHeight),
        side: const BorderSide(color: AppColors.navy),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(buttonRadius),
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(buttonRadius),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.tint,
      selectedColor: AppColors.navy,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: AppColors.navy,
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: false,
      type: BottomNavigationBarType.fixed,
    ),
  );
}
