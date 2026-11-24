import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/constants.dart';
import '../models/car.dart';
import '../providers/rental_provider.dart';
import '../widgets/car_card.dart';

// Search Results: daftar mobil sesuai jenis sewa, chip filter, dan pilihan sort
class SearchResultScreen extends StatelessWidget {
  const SearchResultScreen({super.key});

  // Pilihan sort: nilai di provider -> label di layar
  static const Map<String, String> pilihanSort = {
    'default': 'Rekomendasi',
    'rating': 'Rating tertinggi',
    'price_asc': 'Harga termurah',
    'price_desc': 'Harga termahal',
  };

  // Bottom sheet Sort & Filter
  void _bukaSortFilter(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      // Tinggi sheet mengikuti isi; isi bisa digulir di layar kecil
      isScrollControlled: true,
      builder: (_) => ChangeNotifierProvider.value(
        // Bottom sheet berada di route lain, jadi provider diteruskan secara eksplisit
        value: context.read<RentalProvider>(),
        child: const _SortFilterSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rental = context.watch<RentalProvider>();
    final cars = rental.filteredCars;
    final lokasi = rental.pickupLocation ?? 'Semua lokasi';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '$lokasi | ${rental.dateLabel}',
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Column(
        children: [
          // Baris tombol Sort & Filter + chip filter yang bisa digeser
          // Hanya 5 item, jadi cukup Row di dalam SingleChildScrollView horizontal
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Badge(
                  isLabelVisible: rental.activeFilterCount > 0,
                  label: Text('${rental.activeFilterCount}'),
                  child: ActionChip(
                    avatar: const Icon(Icons.tune, size: 18),
                    label: const Text('Sort & Filter'),
                    onPressed: () => _bukaSortFilter(context),
                  ),
                ),
                const SizedBox(width: 8),
                _Chip(
                  label: 'SUV',
                  selected: rental.filterSuv,
                  onTap: rental.toggleFilterSuv,
                ),
                _Chip(
                  label: 'Automatic',
                  selected: rental.filterAutomatic,
                  onTap: rental.toggleFilterAutomatic,
                ),
                _Chip(
                  label: 'Rp 300k-500k',
                  selected: rental.filterPrice,
                  onTap: rental.toggleFilterPrice,
                ),
                // Chip Rating = sort berdasarkan rating tertinggi
                _Chip(
                  label: 'Rating',
                  selected: rental.sortBy == 'rating',
                  onTap: () => rental.setSortBy(
                    rental.sortBy == 'rating' ? 'default' : 'rating',
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _DaftarHasil(rental: rental, cars: cars),
          ),
        ],
      ),
    );
  }
}

// Isi daftar: loading, error, kosong, atau kartu mobil
class _DaftarHasil extends StatelessWidget {
  final RentalProvider rental;
  final List<Car> cars;

  const _DaftarHasil({required this.rental, required this.cars});

  @override
  Widget build(BuildContext context) {
    if (rental.isLoading && rental.cars.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (rental.errorMessage != null && rental.cars.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
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
                onPressed: rental.loadCars,
                child: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: rental.loadCars,
      child: cars.isEmpty
          // ListView supaya tetap bisa ditarik untuk refresh walau kosong
          ? ListView(
              children: const [
                SizedBox(height: 120),
                Icon(Icons.search_off, size: 56, color: Colors.black38),
                SizedBox(height: 8),
                Center(child: Text('Tidak ada mobil yang cocok')),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              itemCount: cars.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      '${cars.length} mobil ${rental.rentalType}',
                      style: const TextStyle(color: Colors.black54),
                    ),
                  );
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  // Ketuk kartu / Book Now ke Vehicle Detail dibuat di Tahap 7
                  child: CarCard(car: cars[index - 1]),
                );
              },
            ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        labelStyle: TextStyle(color: selected ? Colors.white : AppColors.navy),
        checkmarkColor: Colors.white,
      ),
    );
  }
}

// Isi bottom sheet: pilihan sort dan tombol reset
class _SortFilterSheet extends StatelessWidget {
  const _SortFilterSheet();

  @override
  Widget build(BuildContext context) {
    final rental = context.watch<RentalProvider>();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Urutkan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            RadioGroup<String>(
              groupValue: rental.sortBy,
              onChanged: (value) {
                if (value == null) return;
                rental.setSortBy(value);
                Navigator.pop(context);
              },
              child: Column(
                children: [
                  for (final entry in SearchResultScreen.pilihanSort.entries)
                    RadioListTile<String>(
                      value: entry.key,
                      title: Text(entry.value),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: OutlinedButton(
                onPressed: () {
                  rental.resetFilter();
                  Navigator.pop(context);
                },
                child: const Text('Reset semua filter'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
