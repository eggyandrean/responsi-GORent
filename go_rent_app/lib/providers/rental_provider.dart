import 'package:flutter/foundation.dart';

import '../models/booking.dart';
import '../models/car.dart';
import '../models/notification_item.dart';
import '../models/payment_method.dart';
import '../models/user_profile.dart';
import '../services/api_service.dart';
import '../utils/formatter.dart';

// State lintas layar GO-RENT: form pencarian, filter, data dari API, dan tab aktif.
//
// Pola error:
// - Method load...() tidak melempar error. Pesan kegagalan disimpan di errorMessage
//   supaya layar bisa menampilkan pesan dan tombol coba lagi.
// - Method aksi (toggleFavorite, createBooking, cancelBooking, dst.) melempar
//   ApiException supaya layar bisa menampilkan pesan backend lewat SnackBar.
class RentalProvider extends ChangeNotifier {
  RentalProvider({ApiService? apiService}) : _api = apiService ?? ApiService();

  final ApiService _api;

  // Batas filter harga chip "Rp 300k-500k"
  static const int minFilterPrice = 300000;
  static const int maxFilterPrice = 500000;

  // ---------- Form pencarian ----------
  String? pickupLocation;
  String? dropoffLocation;
  DateTime? pickupDate;
  DateTime? dropoffDate;
  String rentalType = 'Lepas Kunci';

  // ---------- Filter dan sort ----------
  bool filterSuv = false;
  bool filterAutomatic = false;
  bool filterPrice = false;
  String sortBy = 'default'; // default, rating, price_asc, price_desc

  // ---------- Data dari API ----------
  List<Car> cars = [];
  List<Booking> bookings = [];
  List<NotificationItem> notifications = [];
  UserProfile? user;
  List<PaymentMethod> paymentMethods = [];

  // Jumlah proses load yang sedang berjalan; isLoading true selama masih ada yang berjalan
  int _loadingCount = 0;
  bool get isLoading => _loadingCount > 0;
  String? errorMessage;

  // ---------- Navigasi ----------
  int currentTab = 0; // 0 Home, 1 My Bookings, 2 Notifications, 3 Profile

  // ================= Getter =================

  // Pesan validasi form pencarian, atau null jika form sudah lengkap dan benar
  String? get searchError {
    if (pickupLocation == null) return 'Pilih lokasi pick-up terlebih dahulu';
    if (dropoffLocation == null) return 'Pilih lokasi drop-off terlebih dahulu';
    if (pickupDate == null) return 'Pilih tanggal pick-up terlebih dahulu';
    if (dropoffDate == null) return 'Pilih tanggal drop-off terlebih dahulu';

    final hariIni = _tanggalSaja(DateTime.now());
    if (_tanggalSaja(pickupDate!).isBefore(hariIni)) {
      return 'Tanggal pick-up tidak boleh sebelum hari ini';
    }
    if (!_tanggalSaja(dropoffDate!).isAfter(_tanggalSaja(pickupDate!))) {
      return 'Tanggal drop-off harus setelah tanggal pick-up';
    }
    return null;
  }

  // Lama sewa dalam hari (minimal 1). Bernilai 0 jika tanggal belum lengkap.
  int get jumlahHari {
    if (pickupDate == null || dropoffDate == null) return 0;
    return hitungJumlahHari(pickupDate!, dropoffDate!);
  }

  // Label tanggal untuk AppBar Search Results, contoh "24 - 26 Apr"
  String get dateLabel {
    if (pickupDate == null || dropoffDate == null) return 'Pilih tanggal';
    return formatTanggalRange(pickupDate!, dropoffDate!);
  }

  // 6 mobil rating tertinggi sesuai jenis sewa yang dipilih (Popular Vehicles di Home)
  List<Car> get popularCars {
    final hasil = cars.where((car) => car.rentalType == rentalType).toList()
      ..sort((a, b) => b.rating.compareTo(a.rating));
    return hasil.take(6).toList();
  }

  // Daftar Search Results setelah jenis sewa, chip filter, dan sort diterapkan
  List<Car> get filteredCars {
    final hasil = cars.where((car) {
      if (car.rentalType != rentalType) return false;
      if (filterSuv && !car.type.toUpperCase().contains('SUV')) return false;
      if (filterAutomatic && car.transmission != 'Automatic') return false;
      if (filterPrice &&
          (car.pricePerDay < minFilterPrice ||
              car.pricePerDay > maxFilterPrice)) {
        return false;
      }
      return true;
    }).toList();

    switch (sortBy) {
      case 'rating':
        hasil.sort((a, b) => b.rating.compareTo(a.rating));
      case 'price_asc':
        hasil.sort((a, b) => a.pricePerDay.compareTo(b.pricePerDay));
      case 'price_desc':
        hasil.sort((a, b) => b.pricePerDay.compareTo(a.pricePerDay));
    }
    return hasil;
  }

  // Jumlah notifikasi belum dibaca untuk Badge di bottom navigation
  int get unreadCount => notifications.where((notif) => !notif.isRead).length;

  // ================= Setter form, filter, dan tab =================

  void setPickupLocation(String? value) {
    pickupLocation = value;
    notifyListeners();
  }

  void setDropoffLocation(String? value) {
    dropoffLocation = value;
    notifyListeners();
  }

  void setPickupDate(DateTime? value) {
    pickupDate = value;
    // Kosongkan drop-off jika sudah tidak setelah pick-up, supaya pengguna memilih ulang
    if (value != null && dropoffDate != null && !dropoffDate!.isAfter(value)) {
      dropoffDate = null;
    }
    notifyListeners();
  }

  void setDropoffDate(DateTime? value) {
    dropoffDate = value;
    notifyListeners();
  }

  void setRentalType(String value) {
    rentalType = value;
    notifyListeners();
  }

  void toggleFilterSuv() {
    filterSuv = !filterSuv;
    notifyListeners();
  }

  void toggleFilterAutomatic() {
    filterAutomatic = !filterAutomatic;
    notifyListeners();
  }

  void toggleFilterPrice() {
    filterPrice = !filterPrice;
    notifyListeners();
  }

  void setSortBy(String value) {
    sortBy = value;
    notifyListeners();
  }

  // Kembalikan semua chip filter dan sort ke awal (tombol Reset di Sort & Filter)
  void resetFilter() {
    filterSuv = false;
    filterAutomatic = false;
    filterPrice = false;
    sortBy = 'default';
    notifyListeners();
  }

  // Jumlah filter/sort yang sedang aktif, untuk badge tombol Sort & Filter
  int get activeFilterCount => [
    filterSuv,
    filterAutomatic,
    filterPrice,
    sortBy != 'default',
  ].where((aktif) => aktif).length;

  // Pindah tab bottom navigation dari layar mana pun (misalnya setelah Pay Now)
  void changeTab(int index) {
    if (index < 0 || index > 3 || index == currentTab) return;
    currentTab = index;
    notifyListeners();
  }

  // ================= Load data dari API =================

  // Dipanggil sekali saat aplikasi dibuka
  Future<void> loadInitialData() async {
    await Future.wait([
      loadCars(),
      loadUser(),
      loadBookings(),
      loadNotifications(),
      loadPaymentMethods(),
    ]);
  }

  Future<void> loadCars() => _load(() async => cars = await _api.getCars());

  Future<void> loadBookings() =>
      _load(() async => bookings = await _api.getBookings());

  Future<void> loadNotifications() =>
      _load(() async => notifications = await _api.getNotifications());

  Future<void> loadUser() => _load(() async => user = await _api.getUser());

  Future<void> loadPaymentMethods() =>
      _load(() async => paymentMethods = await _api.getPaymentMethods());

  // Kerangka bersama untuk semua load: atur isLoading, simpan pesan error, lalu beri tahu UI
  Future<void> _load(Future<void> Function() proses) async {
    _loadingCount++;
    errorMessage = null;
    notifyListeners();
    try {
      await proses();
    } on ApiException catch (e) {
      errorMessage = e.detailMessage;
    } finally {
      _loadingCount--;
      notifyListeners();
    }
  }

  // ================= Aksi pengguna =================

  // Tambah/hapus favorit. Tampilan langsung berubah, lalu dikembalikan jika request gagal.
  Future<void> toggleFavorite(Car car) async {
    final favoritBaru = !car.isFavorite;
    _gantiMobil(car.id, favoritBaru);
    try {
      if (favoritBaru) {
        await _api.addFavorite(car.id);
      } else {
        await _api.removeFavorite(car.id);
      }
    } on ApiException {
      _gantiMobil(car.id, !favoritBaru);
      rethrow;
    }
  }

  void _gantiMobil(int carId, bool isFavorite) {
    cars = [
      for (final c in cars)
        c.id == carId ? c.copyWith(isFavorite: isFavorite) : c,
    ];
    notifyListeners();
  }

  // Buat booking memakai lokasi dan tanggal dari form pencarian.
  // Setelah berhasil, daftar booking dan notifikasi dimuat ulang dari server.
  Future<Booking> createBooking({
    required Car car,
    required int paymentMethodId,
    required String renterName,
    required bool withInsurance,
    required bool simUploaded,
  }) async {
    final pesan = searchError;
    if (pesan != null) throw ApiException(pesan);

    final booking = await _api.createBooking(
      carId: car.id,
      paymentMethodId: paymentMethodId,
      renterName: renterName,
      pickupLocation: pickupLocation!,
      dropoffLocation: dropoffLocation!,
      pickupDate: pickupDate!,
      dropoffDate: dropoffDate!,
      withInsurance: withInsurance,
      simUploaded: simUploaded,
    );
    await Future.wait([loadBookings(), loadNotifications()]);
    return booking;
  }

  // Batalkan booking berstatus Confirmed
  Future<void> cancelBooking(int id) async {
    final hasil = await _api.cancelBooking(id);
    bookings = [for (final b in bookings) b.id == id ? hasil : b];
    notifyListeners();
  }

  // Tandai satu notifikasi sudah dibaca
  Future<void> markAsRead(int id) async {
    final hasil = await _api.markNotificationRead(id);
    notifications = [for (final n in notifications) n.id == id ? hasil : n];
    notifyListeners();
  }

  // Tombol "Tandai semua" di AppBar Notifications
  Future<void> markAllAsRead() async {
    final belumDibaca = notifications
        .where((n) => !n.isRead)
        .map((n) => n.id)
        .toList();
    for (final id in belumDibaca) {
      await markAsRead(id);
    }
  }

  // Hapus notifikasi dari server dan dari daftar
  Future<void> deleteNotification(int id) async {
    await _api.deleteNotification(id);
    notifications = notifications.where((n) => n.id != id).toList();
    notifyListeners();
  }

  // Simpan perubahan Account Settings
  Future<void> updateUser(String name, String phone) async {
    user = await _api.updateUser(name: name, phone: phone);
    notifyListeners();
  }

  // Ambil bagian tanggal saja (tanpa jam) untuk perbandingan hari
  static DateTime _tanggalSaja(DateTime d) => DateTime(d.year, d.month, d.day);
}
