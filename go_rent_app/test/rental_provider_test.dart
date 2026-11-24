import 'package:flutter_test/flutter_test.dart';
import 'package:go_rent_app/providers/rental_provider.dart';
import 'package:go_rent_app/services/api_service.dart';

import 'fake_api.dart';

void main() {
  late RentalProvider rental;
  final besok = DateTime.now().add(const Duration(days: 1));

  setUp(() => rental = RentalProvider(apiService: buatFakeApi()));

  group('searchError', () {
    test('menolak form kosong dan menerima form lengkap', () {
      expect(rental.searchError, isNotNull);

      rental
        ..setPickupLocation('Purwokerto')
        ..setDropoffLocation('Banyumas')
        ..setPickupDate(besok)
        ..setDropoffDate(besok.add(const Duration(days: 2)));
      expect(rental.searchError, isNull);
      expect(rental.jumlahHari, 2);
    });

    test('menolak drop-off yang tidak setelah pick-up', () {
      rental
        ..setPickupLocation('Purwokerto')
        ..setDropoffLocation('Purwokerto')
        ..setPickupDate(besok)
        ..setDropoffDate(besok);
      expect(
        rental.searchError,
        'Tanggal drop-off harus setelah tanggal pick-up',
      );
    });

    test('menolak tanggal pick-up kemarin', () {
      final kemarin = DateTime.now().subtract(const Duration(days: 1));
      rental
        ..setPickupLocation('Purwokerto')
        ..setDropoffLocation('Purwokerto')
        ..setPickupDate(kemarin)
        ..setDropoffDate(besok);
      expect(
        rental.searchError,
        'Tanggal pick-up tidak boleh sebelum hari ini',
      );
    });

    test('mengganti pick-up ke setelah drop-off mengosongkan drop-off', () {
      rental
        ..setDropoffDate(besok)
        ..setPickupDate(besok.add(const Duration(days: 3)));
      expect(rental.dropoffDate, isNull);
      expect(rental.dateLabel, 'Pilih tanggal');
    });
  });

  test('changeTab hanya menerima 0 sampai 3', () {
    rental.changeTab(1);
    expect(rental.currentTab, 1);
    rental.changeTab(9);
    expect(rental.currentTab, 1);
  });

  test('loadInitialData mengisi data dan unreadCount', () async {
    await rental.loadInitialData();
    expect(rental.isLoading, isFalse);
    expect(rental.errorMessage, isNull);
    expect(rental.cars, hasLength(5));
    expect(rental.user?.name, 'Eggy Andrean');
    expect(rental.paymentMethods.single.name, 'OVO');
    expect(rental.unreadCount, 2);

    await rental.markAllAsRead();
    expect(rental.unreadCount, 0);
  });

  test(
    'popularCars dan filteredCars mengikuti jenis sewa, filter, dan sort',
    () async {
      await rental.loadCars();

      // Lepas Kunci, urut rating: Creta 4.9, Avanza 4.8, Brio 4.7, Rocky 4.5
      expect(rental.popularCars.map((c) => c.id), [2, 1, 3, 7]);

      rental.toggleFilterSuv(); // SUV + Compact SUV
      expect(rental.filteredCars.map((c) => c.id), [2, 7]);

      rental.toggleFilterAutomatic(); // Rocky CVT tersaring
      expect(rental.filteredCars.map((c) => c.id), [2]);

      rental
        ..toggleFilterSuv()
        ..toggleFilterAutomatic()
        ..toggleFilterPrice() // 300k-500k: Avanza, Creta, Rocky
        ..setSortBy('price_desc');
      expect(rental.filteredCars.map((c) => c.id), [2, 1, 7]);

      rental.setRentalType('Dengan Sopir');
      expect(rental.popularCars.map((c) => c.id), [4]);
      expect(rental.filteredCars, isEmpty); // Pajero 850k di luar filter harga
    },
  );

  test('toggleFavorite dikembalikan jika request gagal', () async {
    rental = RentalProvider(apiService: buatFakeApi(gagalFavorit: true));
    await rental.loadCars();

    await expectLater(
      rental.toggleFavorite(rental.cars.first),
      throwsA(isA<ApiException>()),
    );
    expect(rental.cars.first.isFavorite, isFalse);
  });

  test('server mati: errorMessage terisi dan aplikasi tidak crash', () async {
    rental = RentalProvider(apiService: buatFakeApi(serverMati: true));
    await rental.loadInitialData();
    expect(rental.errorMessage, contains('backend'));
    expect(rental.cars, isEmpty);
  });

  test(
    'createBooking ditolak sebelum request jika form belum lengkap',
    () async {
      await rental.loadCars();
      await expectLater(
        rental.createBooking(
          car: rental.cars.first,
          paymentMethodId: 1,
          renterName: 'Eggy Andrean',
          withInsurance: false,
          simUploaded: true,
        ),
        throwsA(isA<ApiException>()),
      );
    },
  );
}
