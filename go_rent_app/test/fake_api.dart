import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:go_rent_app/services/api_service.dart';

// Data contoh untuk tes, meniru respons REST API GO-RENT tanpa jaringan
Map<String, dynamic> contohMobil(
  int id,
  String name, {
  String type = 'SUV',
  String rentalType = 'Lepas Kunci',
  String transmission = 'Automatic',
  double rating = 4.5,
  int price = 400000,
  bool favorite = false,
}) => {
  'id': id,
  'name': name,
  'type': type,
  'rental_type': rentalType,
  'seats': 5,
  'transmission': transmission,
  'rating': rating,
  'price_per_day': price,
  'is_favorite': favorite,
  'provider': {
    'id': 1,
    'name': 'Astra Rental',
    'latitude': -7.4245,
    'longitude': 109.234,
  },
  'images': [],
  'vehicle_specs': ['Airbag'],
};

final List<Map<String, dynamic>> contohDaftarMobil = [
  contohMobil(1, 'Toyota Avanza 2023', type: 'MPV', rating: 4.8, price: 350000),
  contohMobil(2, 'Hyundai Creta Prime', rating: 4.9, price: 450000),
  contohMobil(
    3,
    'Honda Brio RS',
    type: 'City Car',
    transmission: 'Manual',
    rating: 4.7,
    price: 250000,
  ),
  contohMobil(
    7,
    'Daihatsu Rocky',
    type: 'Compact SUV',
    transmission: 'CVT',
    price: 320000,
  ),
  contohMobil(
    4,
    'Mitsubishi Pajero Sport',
    rentalType: 'Dengan Sopir',
    rating: 4.9,
    price: 850000,
  ),
];

Map<String, dynamic> contohNotif(int id, bool isRead) => {
  'id': id,
  'user_id': 1,
  'booking_id': null,
  'title': 'Notif $id',
  'description': 'Deskripsi $id',
  'type': 'promo',
  'is_read': isRead,
  'created_at': '2026-11-24 10:00:00',
};

Map<String, dynamic> contohBooking(int id, String kode, String status) => {
  'id': id,
  'booking_code': kode,
  'user_id': 1,
  'car_id': 1,
  'payment_method_id': 1,
  'renter_name': 'Eggy Andrean',
  'pickup_location': 'Purwokerto',
  'dropoff_location': 'Banyumas',
  'pickup_date': '2026-12-01',
  'dropoff_date': '2026-12-03',
  'days': 2,
  'price_per_day': 350000,
  'insurance_fee': 80000,
  'total_price': 780000,
  'sim_uploaded': true,
  'status': status,
  'created_at': '2026-11-24 10:00:00',
  'car_name': 'Toyota Avanza 2023',
  'payment_method': 'OVO',
  'car_image': null,
};

// Body POST /bookings terakhir yang diterima API palsu (untuk dicek di tes)
Map<String, dynamic>? bodyBookingTerakhir;

// ApiService palsu. gagalFavorit = true membuat POST/DELETE /favorites membalas 500,
// gagalBooking = true membuat POST /bookings membalas 400 seperti validasi backend.
ApiService buatFakeApi({
  bool gagalFavorit = false,
  bool serverMati = false,
  bool gagalBooking = false,
}) {
  return ApiService(
    client: MockClient((request) async {
      if (serverMati) throw http.ClientException('Connection refused');
      final path = request.url.path;
      final notifs = [
        contohNotif(1, false),
        contohNotif(2, false),
        contohNotif(3, true),
      ];

      if (path == '/cars') return _json(contohDaftarMobil);
      if (path == '/bookings' && request.method == 'POST') {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        bodyBookingTerakhir = body;
        if (gagalBooking) {
          return _json({
            'message': 'Validasi gagal',
            'errors': {'renter_name': 'Nama penyewa minimal 3 huruf'},
          }, 400);
        }
        return _json({
          'id': 9,
          'booking_code': 'GR2026120101',
          'user_id': 1,
          'car_id': body['car_id'],
          'payment_method_id': body['payment_method_id'],
          'renter_name': body['renter_name'],
          'pickup_location': body['pickup_location'],
          'dropoff_location': body['dropoff_location'],
          'pickup_date': body['pickup_date'],
          'dropoff_date': body['dropoff_date'],
          'days': 2,
          'price_per_day': 450000,
          'insurance_fee': body['with_insurance'] == true ? 80000 : 0,
          'total_price': body['with_insurance'] == true ? 980000 : 900000,
          'sim_uploaded': true,
          'status': 'Confirmed',
          'created_at': '2026-11-24 10:00:00',
          'car_name': 'Hyundai Creta Prime',
          'payment_method': 'OVO',
          'car_image': null,
        }, 201);
      }
      if (path == '/bookings') {
        return _json([
          contohBooking(2, 'GR2026120101', 'Confirmed'),
          contohBooking(1, 'GR20230426', 'Completed'),
        ]);
      }
      if (path.startsWith('/bookings/') && request.method == 'PUT') {
        final id = int.parse(path.split('/').last);
        return _json(contohBooking(id, 'GR2026120101', 'Cancelled'));
      }
      if (path.startsWith('/notifications/') && request.method == 'DELETE') {
        return _json({'message': 'Notifikasi dihapus'});
      }
      if (path == '/users/1' && request.method == 'PUT') {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        return _json({
          'id': 1,
          'name': body['name'],
          'email': 'eggy.andrean@example.com',
          'phone': body['phone'],
          'is_verified': true,
          'driving_license': 'SIM A',
          'avatar_url': 'assets/images/avatar.png',
        });
      }
      if (path == '/notifications') return _json(notifs);
      if (path.startsWith('/notifications/') && request.method == 'PUT') {
        final id = int.parse(path.split('/').last);
        return _json(contohNotif(id, true));
      }
      if (path == '/payment-methods') {
        return _json([
          {'id': 1, 'name': 'OVO'},
        ]);
      }
      if (path == '/users/1') {
        return _json({
          'id': 1,
          'name': 'Eggy Andrean',
          'email': 'eggy.andrean@example.com',
          'phone': '0812-XXXX-5554',
          'is_verified': true,
          'driving_license': 'SIM A',
          'avatar_url': 'assets/images/avatar.png',
        });
      }
      if (path.startsWith('/favorites')) {
        return gagalFavorit
            ? _json({'message': 'Terjadi kesalahan pada server'}, 500)
            : _json({
                'is_favorite': request.method == 'POST',
              }, request.method == 'POST' ? 201 : 200);
      }
      return _json({'message': 'tidak ditemukan'}, 404);
    }),
  );
}

http.Response _json(Object data, [int status = 200]) => http.Response(
  jsonEncode(data),
  status,
  headers: {'content-type': 'application/json'},
);
