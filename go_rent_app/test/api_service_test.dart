import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:go_rent_app/services/api_service.dart';

void main() {
  test('getCars mengirim query filter dan memetakan hasil', () async {
    late Uri dipanggil;
    final api = ApiService(
      client: MockClient((request) async {
        dipanggil = request.url;
        return http.Response(jsonEncode([]), 200);
      }),
    );

    final cars = await api.getCars(type: 'SUV', sort: 'price_asc');
    expect(cars, isEmpty);
    expect(dipanggil.path, '/cars');
    expect(dipanggil.queryParameters, {
      'user_id': '1',
      'type': 'SUV',
      'sort': 'price_asc',
    });
  });

  test(
    'error 400 dari backend menjadi ApiException berisi pesan per field',
    () async {
      final api = ApiService(
        client: MockClient((request) async {
          return http.Response(
            jsonEncode({
              'message': 'Validasi gagal',
              'errors': {'sim_uploaded': 'SIM/KTP wajib di-upload'},
            }),
            400,
          );
        }),
      );

      expect(
        () => api.createBooking(
          carId: 2,
          paymentMethodId: 1,
          renterName: 'Eggy Andrean',
          pickupLocation: 'Purwokerto',
          dropoffLocation: 'Purwokerto',
          pickupDate: DateTime(2026, 12, 1),
          dropoffDate: DateTime(2026, 12, 3),
          withInsurance: true,
          simUploaded: false,
        ),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', 400)
              .having(
                (e) => e.detailMessage,
                'detailMessage',
                'SIM/KTP wajib di-upload',
              ),
        ),
      );
    },
  );

  test('server mati menjadi pesan koneksi yang jelas', () async {
    final api = ApiService(
      client: MockClient(
        (request) async => throw http.ClientException('Connection refused'),
      ),
    );

    expect(
      api.getPaymentMethods,
      throwsA(
        isA<ApiException>().having(
          (e) => e.message,
          'message',
          contains('backend'),
        ),
      ),
    );
  });
}
