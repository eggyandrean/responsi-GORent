import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:go_rent_app/config/constants.dart';
import 'package:go_rent_app/providers/rental_provider.dart';
import 'package:go_rent_app/screens/booking_screen.dart';
import 'package:go_rent_app/screens/vehicle_detail_screen.dart';
import 'package:go_rent_app/widgets/pickup_map.dart';

import 'fake_api.dart';

void main() {
  late RentalProvider rental;

  // Buka Vehicle Detail untuk mobil dengan id tertentu dari data palsu
  Future<void> pasang(WidgetTester tester, int carId) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    rental = RentalProvider(apiService: buatFakeApi());
    await tester.runAsync(rental.loadCars);
    final car = rental.cars.firstWhere((c) => c.id == carId);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: rental,
        child: MaterialApp(
          theme: buildAppTheme(),
          home: VehicleDetailScreen(car: car),
        ),
      ),
    );
    await tester.pump();
  }

  void isiFormLengkap() {
    final besok = DateTime.now().add(const Duration(days: 1));
    rental
      ..setPickupLocation('Purwokerto')
      ..setDropoffLocation('Purwokerto')
      ..setPickupDate(besok)
      ..setDropoffDate(besok.add(const Duration(days: 2)));
  }

  testWidgets('menampilkan info, specs, Rental Includes, dan peta', (
    tester,
  ) async {
    await pasang(tester, 2);

    expect(find.text('Hyundai Creta Prime'), findsWidgets);
    expect(
      find.text('Astra Rental'),
      findsWidgets,
    ); // chip provider (+ alamat cadangan)
    expect(find.text('5 Seats'), findsOneWidget);
    expect(find.text('Airbag'), findsOneWidget);
    expect(find.text('24/7 Support'), findsOneWidget);
    expect(find.text('Sopir profesional'), findsNothing);
    expect(find.byType(PickupMap), findsOneWidget);
    expect(find.text('Continue to Booking'), findsOneWidget);
  });

  testWidgets('mobil Dengan Sopir mendapat Sopir profesional', (tester) async {
    await pasang(tester, 4);
    expect(find.text('Sopir profesional'), findsOneWidget);
  });

  testWidgets('carousel bergeser sendiri setiap 3,5 detik', (tester) async {
    await pasang(tester, 2);
    expect(find.text('Tampak depan'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 3500));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Tampak samping'), findsOneWidget);
  });

  testWidgets('tombol favorit mengubah status di provider', (tester) async {
    await pasang(tester, 2);

    await tester.tap(find.byTooltip('Tambah ke favorit'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
    expect(rental.cars.firstWhere((c) => c.id == 2).isFavorite, isTrue);
    expect(find.byTooltip('Hapus dari favorit'), findsOneWidget);
  });

  testWidgets('form kosong: Continue membuka bottom sheet SearchForm dulu', (
    tester,
  ) async {
    await pasang(tester, 2);

    await tester.tap(find.text('Continue to Booking'));
    await tester.pumpAndSettle();
    expect(find.text('Lengkapi detail sewa dulu'), findsOneWidget);
    expect(find.text('Pilih lokasi pick-up terlebih dahulu'), findsOneWidget);

    // Tombol nonaktif selama form belum valid
    final tombol = find.widgetWithText(ElevatedButton, 'Lanjut ke Booking');
    expect(tester.widget<ElevatedButton>(tombol).onPressed, isNull);

    isiFormLengkap();
    await tester.pump();
    await tester.ensureVisible(tombol);
    await tester.tap(tombol);
    await tester.pumpAndSettle();
    expect(find.byType(BookingScreen), findsOneWidget);
  });

  testWidgets('form lengkap: Continue langsung ke Booking', (tester) async {
    await pasang(tester, 2);
    isiFormLengkap();
    await tester.pump();

    await tester.tap(find.text('Continue to Booking'));
    await tester.pumpAndSettle();
    expect(find.text('Lengkapi detail sewa dulu'), findsNothing);
    expect(find.byType(BookingScreen), findsOneWidget);
    expect(
      find.text('Subtotal Rp 900.000 (belum termasuk asuransi Rp 80.000)'),
      findsOneWidget,
    );
  });
}
