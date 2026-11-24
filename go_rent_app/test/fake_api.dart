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

// ApiService palsu. gagalFavorit = true membuat POST/DELETE /favorites membalas 500.
ApiService buatFakeApi({bool gagalFavorit = false, bool serverMati = false}) {
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
      if (path == '/bookings') return _json([]);
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
