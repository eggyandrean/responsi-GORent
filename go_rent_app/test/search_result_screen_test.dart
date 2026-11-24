import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:go_rent_app/config/constants.dart';
import 'package:go_rent_app/providers/rental_provider.dart';
import 'package:go_rent_app/screens/search_result_screen.dart';
import 'package:go_rent_app/widgets/car_card.dart';

import 'fake_api.dart';

void main() {
  late RentalProvider rental;

  Future<void> pasang(WidgetTester tester, {bool serverMati = false}) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    rental = RentalProvider(apiService: buatFakeApi(serverMati: serverMati));
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: rental,
        child: MaterialApp(
          theme: buildAppTheme(),
          home: const SearchResultScreen(),
        ),
      ),
    );
    await tester.runAsync(rental.loadCars);
    await tester.pump();
  }

  // Chip di baris horizontal bisa berada di luar layar kecil, jadi digeser dulu sebelum diketuk
  Future<void> ketukChip(WidgetTester tester, String label) async {
    final chip = find.widgetWithText(FilterChip, label);
    await tester.ensureVisible(chip);
    await tester.pump();
    await tester.tap(chip);
    await tester.pump();
  }

  // Nama mobil sesuai urutan kartu di layar (termasuk yang belum terlihat)
  List<String> namaKartu(WidgetTester tester) =>
      rental.filteredCars.map((c) => c.name).toList();

  testWidgets('menampilkan AppBar default dan kartu Lepas Kunci', (
    tester,
  ) async {
    await pasang(tester);

    expect(find.text('Semua lokasi | Pilih tanggal'), findsOneWidget);
    expect(find.text('4 mobil Lepas Kunci'), findsOneWidget);
    expect(find.byType(CarCard), findsWidgets);
    expect(find.text('Book Now'), findsWidgets);
  });

  testWidgets('chip SUV dan Automatic menyaring daftar', (tester) async {
    await pasang(tester);

    await ketukChip(tester, 'SUV');
    expect(namaKartu(tester), ['Hyundai Creta Prime', 'Daihatsu Rocky']);

    await ketukChip(tester, 'Automatic');
    expect(find.text('1 mobil Lepas Kunci'), findsOneWidget);
  });

  testWidgets('kombinasi tanpa hasil menampilkan teks kosong', (tester) async {
    await pasang(tester);
    rental.setRentalType('Dengan Sopir'); // hanya Pajero 850k
    await tester.pump();

    await ketukChip(tester, 'Rp 300k-500k');
    expect(find.text('Tidak ada mobil yang cocok'), findsOneWidget);
  });

  testWidgets('Sort & Filter: pilih Harga termurah lalu Reset', (tester) async {
    await pasang(tester);

    await tester.ensureVisible(find.text('Sort & Filter'));
    await tester.tap(find.text('Sort & Filter'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Harga termurah'));
    await tester.pumpAndSettle();
    expect(rental.sortBy, 'price_asc');
    expect(namaKartu(tester).first, 'Honda Brio RS'); // 250k paling murah

    // Chip Rating = sort rating
    await ketukChip(tester, 'Rating');
    expect(rental.sortBy, 'rating');

    await tester.ensureVisible(find.text('Sort & Filter'));
    await tester.tap(find.text('Sort & Filter'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reset semua filter'));
    await tester.pumpAndSettle();
    expect(rental.sortBy, 'default');
    expect(rental.activeFilterCount, 0);
  });

  testWidgets('server mati menampilkan pesan error dan tombol Coba lagi', (
    tester,
  ) async {
    await pasang(tester, serverMati: true);

    expect(find.textContaining('backend'), findsOneWidget);
    expect(find.text('Coba lagi'), findsOneWidget);
  });
}
