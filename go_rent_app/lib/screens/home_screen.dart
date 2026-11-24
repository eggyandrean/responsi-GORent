import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/constants.dart';
import '../providers/rental_provider.dart';
import '../widgets/go_rent_app_bar.dart';
import '../widgets/popular_car_card.dart';
import '../widgets/rental_type_toggle.dart';
import '../widgets/search_form.dart';
import 'search_result_screen.dart';

// Tab Home: form pencarian, toggle jenis sewa, tombol Cari Mobil, dan Popular Vehicles
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Pola tampilkanPesan() dari materi P6: pesan singkat lewat SnackBar
  void tampilkanPesan(BuildContext context, String pesan) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(pesan)));
  }

  void _bukaHasilPencarian(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SearchResultScreen()),
    );
  }

  // Cari Mobil: validasi form dulu; gagal = SnackBar, sukses = ke Search Results
  void _cariMobil(BuildContext context) {
    final pesan = context.read<RentalProvider>().searchError;
    if (pesan != null) {
      tampilkanPesan(context, pesan);
      return;
    }
    _bukaHasilPencarian(context);
  }

  @override
  Widget build(BuildContext context) {
    final rental = context.read<RentalProvider>();

    return Scaffold(
      appBar: const GoRentAppBar(),
      body: RefreshIndicator(
        // Tarik ke bawah untuk memuat ulang data dari server
        onRefresh: rental.loadInitialData,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // Latar navy menyambung dari AppBar, kartu form di atasnya
            Container(
              color: AppColors.navy,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
              child: const SearchForm(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                children: [
                  const RentalTypeToggle(),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => _cariMobil(context),
                    icon: const Icon(Icons.search),
                    label: const Text('Cari Mobil'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Popular Vehicles',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // See All langsung ke Search Results tanpa validasi form
                  TextButton(
                    onPressed: () => _bukaHasilPencarian(context),
                    child: const Text('See All'),
                  ),
                ],
              ),
            ),
            const _PopularVehicles(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// Daftar horizontal Popular Vehicles beserta keadaan loading, error, dan kosong
class _PopularVehicles extends StatelessWidget {
  const _PopularVehicles();

  static const double _tinggi = 240;

  @override
  Widget build(BuildContext context) {
    final rental = context.watch<RentalProvider>();
    final cars = rental.popularCars;

    if (rental.isLoading && rental.cars.isEmpty) {
      return const SizedBox(
        height: _tinggi,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (rental.errorMessage != null && rental.cars.isEmpty) {
      return SizedBox(
        height: _tinggi,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  rental.errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.error),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: rental.loadInitialData,
                  child: const Text('Coba lagi'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (cars.isEmpty) {
      return const SizedBox(
        height: 80,
        child: Center(child: Text('Belum ada mobil untuk jenis sewa ini')),
      );
    }

    return SizedBox(
      height: _tinggi,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: cars.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          // Ketuk kartu untuk ke Vehicle Detail dibuat di Tahap 7
          child: PopularCarCard(car: cars[index]),
        ),
      ),
    );
  }
}
