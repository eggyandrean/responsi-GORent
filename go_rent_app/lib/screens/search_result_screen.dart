import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/rental_provider.dart';
import '../utils/formatter.dart';

// Search Results versi sementara (Tahap 5): AppBar sesuai SPEC dan daftar sederhana.
// Layar lengkap (CarCard, Sort & Filter, FilterChip) dibuat di Tahap 6.
class SearchResultScreen extends StatelessWidget {
  const SearchResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final rental = context.watch<RentalProvider>();
    final cars = rental.filteredCars;
    final lokasi = rental.pickupLocation ?? 'Semua lokasi';

    return Scaffold(
      appBar: AppBar(title: Text('$lokasi | ${rental.dateLabel}')),
      body: cars.isEmpty
          ? const Center(child: Text('Tidak ada mobil yang cocok'))
          : ListView.builder(
              itemCount: cars.length,
              itemBuilder: (context, index) {
                final car = cars[index];
                return ListTile(
                  title: Text(car.name),
                  subtitle: Text('${car.type} · ${car.transmission}'),
                  trailing: Text('${formatRupiah(car.pricePerDay)}/day'),
                );
              },
            ),
    );
  }
}
