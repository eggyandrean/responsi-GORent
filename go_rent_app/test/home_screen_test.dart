import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:go_rent_app/config/constants.dart';
import 'package:go_rent_app/providers/rental_provider.dart';
import 'package:go_rent_app/screens/home_screen.dart';
import 'package:go_rent_app/screens/search_result_screen.dart';
import 'package:go_rent_app/widgets/popular_car_card.dart';

import 'fake_api.dart';

void main() {
  late RentalProvider rental;

  // Pasang HomeScreen di layar HP kecil (360 x 640) supaya overflow ikut terdeteksi
  Future<void> pasangHome(WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    rental = RentalProvider(apiService: buatFakeApi());
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: rental,
        child: MaterialApp(theme: buildAppTheme(), home: const HomeScreen()),
      ),
    );
    await tester.runAsync(rental.loadInitialData);
    await tester.pump();
  }

  testWidgets('Home menampilkan header, form, dan Popular Vehicles', (
    tester,
  ) async {
    await pasangHome(tester);

    expect(find.text('GO-RENT'), findsOneWidget);
    expect(find.text('EA'), findsOneWidget); // inisial Eggy Andrean
    expect(find.text('Where to, Purwokerto?'), findsOneWidget);
    expect(find.text('Cari Mobil'), findsOneWidget);
    // Lepas Kunci: 4 mobil di data palsu, kartu pertama rating tertinggi (Creta)
    expect(find.byType(PopularCarCard), findsWidgets);
    expect(find.text('Hyundai Creta Prime'), findsWidgets);
  });

  testWidgets('Cari Mobil dengan form kosong memunculkan SnackBar', (
    tester,
  ) async {
    await pasangHome(tester);

    await tester.tap(find.text('Cari Mobil'));
    await tester.pump();
    expect(find.text('Pilih lokasi pick-up terlebih dahulu'), findsOneWidget);
    expect(find.byType(SearchResultScreen), findsNothing);
  });

  testWidgets('Cari Mobil dengan form lengkap membuka Search Results', (
    tester,
  ) async {
    await pasangHome(tester);
    final besok = DateTime.now().add(const Duration(days: 1));
    rental
      ..setPickupLocation('Banyumas')
      ..setDropoffLocation('Purwokerto')
      ..setPickupDate(besok)
      ..setDropoffDate(besok.add(const Duration(days: 2)));
    await tester.pump();

    expect(find.text('Where to, Banyumas?'), findsOneWidget);
    await tester.tap(find.text('Cari Mobil'));
    await tester.pumpAndSettle();
    expect(find.byType(SearchResultScreen), findsOneWidget);
    expect(find.textContaining('Banyumas | '), findsOneWidget);
  });

  testWidgets('See All membuka Search Results tanpa validasi', (tester) async {
    await pasangHome(tester);

    await tester.tap(find.text('See All'));
    await tester.pumpAndSettle();
    expect(find.text('Semua lokasi | Pilih tanggal'), findsOneWidget);
  });

  testWidgets('Toggle Dengan Sopir mengganti Popular Vehicles', (tester) async {
    await pasangHome(tester);

    await tester.tap(find.text('Dengan Sopir'));
    await tester.pump();
    expect(rental.rentalType, 'Dengan Sopir');
    expect(find.text('Mitsubishi Pajero Sport'), findsWidgets);
    expect(find.text('Hyundai Creta Prime'), findsNothing);
  });

  testWidgets('Ikon lonceng di header pindah ke tab Notifications', (
    tester,
  ) async {
    await pasangHome(tester);

    await tester.tap(find.byTooltip('Notifications'));
    expect(rental.currentTab, 2);
  });
}
