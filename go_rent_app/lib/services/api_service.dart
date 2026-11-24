import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/constants.dart';
import '../models/booking.dart';
import '../models/car.dart';
import '../models/notification_item.dart';
import '../models/payment_method.dart';
import '../models/user_profile.dart';
import '../utils/formatter.dart';

// Error dari API dengan pesan yang siap ditampilkan di SnackBar.
// errors berisi pesan per field dari validasi backend (status 400).
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, String> errors;

  const ApiException(this.message, {this.statusCode, this.errors = const {}});

  // Gabungkan pesan per field supaya pengguna tahu apa yang harus diperbaiki
  String get detailMessage =>
      errors.isEmpty ? message : errors.values.join('\n');

  @override
  String toString() => detailMessage;
}

// Semua panggilan HTTP ke REST API GO-RENT ada di sini (bukan di widget)
class ApiService {
  static const Duration _timeout = Duration(seconds: 10);

  // ngrok-skip-browser-warning supaya ngrok mengembalikan JSON, bukan halaman HTML (gotcha P11)
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'ngrok-skip-browser-warning': 'true',
  };

  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('$baseUrl$path').replace(queryParameters: query);

  // Kirim request, cek status, lalu kembalikan body JSON yang sudah di-decode.
  // Semua kegagalan diubah menjadi ApiException dengan pesan yang jelas.
  Future<dynamic> _request(String method, Uri uri, {Object? body}) async {
    try {
      final request = http.Request(method, uri)..headers.addAll(_headers);
      if (body != null) request.body = jsonEncode(body);

      final streamed = await _client.send(request).timeout(_timeout);
      final response = await http.Response.fromStream(streamed);
      final data = response.body.isEmpty ? null : jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return data;
      }

      // Ambil pesan dari backend: { message, errors }
      final pesan = data is Map && data['message'] is String
          ? data['message'] as String
          : 'Permintaan gagal (status ${response.statusCode})';
      final errors = <String, String>{};
      if (data is Map && data['errors'] is Map) {
        (data['errors'] as Map).forEach(
          (key, value) => errors['$key'] = '$value',
        );
      }
      throw ApiException(
        pesan,
        statusCode: response.statusCode,
        errors: errors,
      );
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException(
        'Server tidak merespons. Coba lagi beberapa saat.',
      );
    } on FormatException {
      throw const ApiException('Respons server tidak valid (bukan JSON).');
    } on http.ClientException {
      throw const ApiException(
        'Tidak bisa terhubung ke server. Pastikan backend sudah berjalan.',
      );
    } catch (e) {
      // Misalnya SocketException saat backend mati atau tidak ada internet
      throw const ApiException(
        'Tidak bisa terhubung ke server. Pastikan backend sudah berjalan.',
      );
    }
  }

  // ---------- Cars ----------

  // GET /cars dengan filter opsional; sort: rating, price_asc, price_desc
  Future<List<Car>> getCars({
    String? rentalType,
    String? type,
    String? transmission,
    int? minPrice,
    int? maxPrice,
    String? sort,
  }) async {
    final query = <String, String>{
      'user_id': '$currentUserId',
      // Tanda ? di depan nilai: key hanya dimasukkan jika nilainya tidak null
      'rental_type': ?rentalType,
      'type': ?type,
      'transmission': ?transmission,
      if (minPrice != null) 'min_price': '$minPrice',
      if (maxPrice != null) 'max_price': '$maxPrice',
      if (sort != null && sort != 'default') 'sort': sort,
    };
    final data = await _request('GET', _uri('/cars', query)) as List;
    return data.map((e) => Car.fromJson(e as Map<String, dynamic>)).toList();
  }

  // GET /cars/{id}
  Future<Car> getCar(int id) async {
    final data = await _request(
      'GET',
      _uri('/cars/$id', {'user_id': '$currentUserId'}),
    );
    return Car.fromJson(data as Map<String, dynamic>);
  }

  // ---------- Users ----------

  // GET /users/{id}
  Future<UserProfile> getUser([int id = currentUserId]) async {
    final data = await _request('GET', _uri('/users/$id'));
    return UserProfile.fromJson(data as Map<String, dynamic>);
  }

  // PUT /users/{id} untuk Account Settings
  Future<UserProfile> updateUser({
    required String name,
    required String phone,
    int id = currentUserId,
  }) async {
    final data = await _request(
      'PUT',
      _uri('/users/$id'),
      body: {'name': name, 'phone': phone},
    );
    return UserProfile.fromJson(data as Map<String, dynamic>);
  }

  // ---------- Payment methods ----------

  // GET /payment-methods
  Future<List<PaymentMethod>> getPaymentMethods() async {
    final data = await _request('GET', _uri('/payment-methods')) as List;
    return data
        .map((e) => PaymentMethod.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ---------- Bookings ----------

  // GET /bookings?user_id=1 (terbaru dulu)
  Future<List<Booking>> getBookings([int userId = currentUserId]) async {
    final data = await _request(
      'GET',
      _uri('/bookings', {'user_id': '$userId'}),
    ) as List;
    return data
        .map((e) => Booking.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // POST /bookings. Total harga dihitung ulang oleh server.
  Future<Booking> createBooking({
    required int carId,
    required int paymentMethodId,
    required String renterName,
    required String pickupLocation,
    required String dropoffLocation,
    required DateTime pickupDate,
    required DateTime dropoffDate,
    required bool withInsurance,
    required bool simUploaded,
    int userId = currentUserId,
  }) async {
    final data = await _request(
      'POST',
      _uri('/bookings'),
      body: {
        'user_id': userId,
        'car_id': carId,
        'payment_method_id': paymentMethodId,
        'renter_name': renterName,
        'pickup_location': pickupLocation,
        'dropoff_location': dropoffLocation,
        'pickup_date': formatTanggalApi(pickupDate),
        'dropoff_date': formatTanggalApi(dropoffDate),
        'with_insurance': withInsurance,
        'sim_uploaded': simUploaded,
      },
    );
    return Booking.fromJson(data as Map<String, dynamic>);
  }

  // PUT /bookings/{id} untuk membatalkan booking
  Future<Booking> cancelBooking(int id) async {
    final data = await _request(
      'PUT',
      _uri('/bookings/$id'),
      body: {'status': 'Cancelled'},
    );
    return Booking.fromJson(data as Map<String, dynamic>);
  }

  // ---------- Notifications ----------

  // GET /notifications?user_id=1 (terbaru dulu)
  Future<List<NotificationItem>> getNotifications([
    int userId = currentUserId,
  ]) async {
    final data = await _request(
      'GET',
      _uri('/notifications', {'user_id': '$userId'}),
    ) as List;
    return data
        .map((e) => NotificationItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // PUT /notifications/{id} untuk menandai dibaca/belum dibaca
  Future<NotificationItem> markNotificationRead(
    int id, {
    bool isRead = true,
  }) async {
    final data = await _request(
      'PUT',
      _uri('/notifications/$id'),
      body: {'is_read': isRead},
    );
    return NotificationItem.fromJson(data as Map<String, dynamic>);
  }

  // DELETE /notifications/{id}
  Future<void> deleteNotification(int id) async {
    await _request('DELETE', _uri('/notifications/$id'));
  }

  // ---------- Favorites ----------

  // POST /favorites
  Future<void> addFavorite(int carId, {int userId = currentUserId}) async {
    await _request(
      'POST',
      _uri('/favorites'),
      body: {'user_id': userId, 'car_id': carId},
    );
  }

  // DELETE /favorites/{car_id}?user_id=1
  Future<void> removeFavorite(int carId, {int userId = currentUserId}) async {
    await _request('DELETE', _uri('/favorites/$carId', {'user_id': '$userId'}));
  }
}
