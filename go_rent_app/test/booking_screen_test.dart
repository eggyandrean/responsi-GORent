import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:go_rent_app/config/constants.dart';
import 'package:go_rent_app/providers/rental_provider.dart';
import 'package:go_rent_app/screens/booking_screen.dart';

import 'fake_api.dart';

void main() {
  late RentalProvider rental;

  // Buka BookingScreen untuk Hyundai Creta (450k/hari), sewa 2 hari mulai besok
  Future<void> pasang(WidgetTester tester, {bool gagalBooking = false}) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    bodyBookingTerakhir = null;

    rental = RentalProvider(
      apiService: buatFakeApi(gagalBooking: gagalBooking),
    );
    await tester.runAsync(rental.loadInitialData);
    final besok = DateTime.now().add(const Duration(days: 1));
    rental
      ..setPickupLocation('Purwokerto')
      ..setDropoffLocation('Banyumas')
      ..setPickupDate(besok)
      ..setDropoffDate(besok.add(const Duration(days: 2)));
    final creta = rental.cars.firstWhere((c) => c.id == 2);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: rental,
        child: MaterialApp(
          theme: buildAppTheme(),
          home: BookingScreen(car: creta),
        ),
      ),
    );
    await tester.pump();
  }

  // Gulir daftar langkah yang sedang tampil sampai widget terlihat.
  // Isi ListView dibangun bertahap, jadi widget di bawah belum ada sebelum digulir.
  Future<void> gulirKe(WidgetTester tester, Finder finder) async {
    if (finder.evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        finder,
        150,
        scrollable: find.byType(Scrollable).first,
      );
    }
    await tester.ensureVisible(finder);
  }

  Future<void> ketuk(WidgetTester tester, Finder finder) async {
    await gulirKe(tester, finder);
    await tester.pump();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  // Biarkan request ke API palsu selesai (butuh waktu nyata), lalu perbarui layar.
  // Tidak memakai pumpAndSettle karena indikator loading di tombol Pay Now tetap berputar
  // selama dialog sukses masih terbuka.
  Future<void> tungguRequest(WidgetTester tester) async {
    for (var i = 0; i < 20; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  // Maju ke langkah Payment
  Future<void> keLangkahPayment(WidgetTester tester) async {
    await ketuk(tester, find.text('Continue'));
    await ketuk(tester, find.text('Continue'));
    expect(find.text('Pay Now'), findsOneWidget);
  }

  testWidgets('langkah Vehicle menampilkan driver dan total', (tester) async {
    await pasang(tester);

    expect(find.text('Hyundai Creta Prime'), findsWidgets);
    expect(find.text('Driver Information'), findsOneWidget);
    await gulirKe(tester, find.text('Eggy Andrean'));
    expect(find.text('Eggy Andrean'), findsOneWidget);
    expect(find.text('SIM A'), findsOneWidget);
    expect(find.text('Rp 980.000'), findsWidgets);
  });

  testWidgets(
    'Details: total 980.000 dengan asuransi dan 900.000 tanpa asuransi',
    (tester) async {
      await pasang(tester);
      await ketuk(tester, find.text('Continue'));

      expect(find.text('2 Days Rent (Rp 450.000 x 2)'), findsOneWidget);
      expect(find.text('Rp 980.000'), findsWidgets);

      await ketuk(tester, find.text('Insurance Add-on'));
      expect(find.text('Rp 900.000'), findsWidgets);
      expect(find.text('Rp 980.000'), findsNothing);

      // Langkah sebelumnya bisa diketuk untuk kembali
      await ketuk(tester, find.text('Vehicle'));
      expect(find.text('Driver Information'), findsOneWidget);
    },
  );

  testWidgets('Pay Now ditolak tanpa upload SIM dan tanpa nama', (
    tester,
  ) async {
    await pasang(tester);
    await keLangkahPayment(tester);

    await ketuk(tester, find.text('Pay Now'));
    expect(find.text('Upload SIM/KTP terlebih dahulu'), findsOneWidget);

    await gulirKe(tester, find.byType(TextFormField));
    await tester.enterText(find.byType(TextFormField), 'Ed');
    await ketuk(tester, find.text('Pay Now'));
    expect(find.text('Nama penyewa minimal 3 huruf'), findsOneWidget);
    expect(bodyBookingTerakhir, isNull); // tidak ada request ke server
  });

  testWidgets(
    'alur lengkap: konfirmasi, POST /bookings, dialog sukses, pindah tab',
    (tester) async {
      await pasang(tester);
      await keLangkahPayment(tester);

      await ketuk(tester, find.text('Upload SIM/KTP'));
      // Tunggu SnackBar "berhasil diunggah" hilang supaya tidak menutupi pilihan bayar
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(find.text('SIM/KTP terunggah'), findsOneWidget);
      await ketuk(tester, find.text('OVO'));
      await ketuk(tester, find.text('Pay Now'));

      expect(find.text('Konfirmasi Pembayaran'), findsOneWidget);
      await tester.tap(find.text('Bayar'));
      await tungguRequest(tester);

      expect(find.text('Booking Berhasil'), findsOneWidget);
      expect(find.textContaining('GR2026120101'), findsOneWidget);
      expect(bodyBookingTerakhir?['car_id'], 2);
      expect(bodyBookingTerakhir?['renter_name'], 'Eggy Andrean');
      expect(bodyBookingTerakhir?['with_insurance'], isTrue);
      expect(bodyBookingTerakhir?['sim_uploaded'], isTrue);
      expect(bodyBookingTerakhir?['dropoff_location'], 'Banyumas');

      await tester.tap(find.text('Lihat My Bookings'));
      await tester.pumpAndSettle();
      expect(rental.currentTab, 1);
    },
  );

  testWidgets('error validasi dari backend tampil di SnackBar', (tester) async {
    await pasang(tester, gagalBooking: true);
    await keLangkahPayment(tester);

    await ketuk(tester, find.text('Upload SIM/KTP'));
    // Tunggu SnackBar "berhasil diunggah" hilang supaya tidak menutupi pilihan bayar
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await ketuk(
      tester,
      find.text('GoPay').evaluate().isEmpty
          ? find.text('OVO')
          : find.text('GoPay'),
    );
    await ketuk(tester, find.text('Pay Now'));
    await tester.tap(find.text('Bayar'));
    await tungguRequest(tester);

    expect(find.text('Booking Berhasil'), findsNothing);
    expect(find.text('Nama penyewa minimal 3 huruf'), findsOneWidget);
    expect(
      find.text('Pay Now'),
      findsOneWidget,
    ); // tetap di layar, input tidak hilang
  });
}
