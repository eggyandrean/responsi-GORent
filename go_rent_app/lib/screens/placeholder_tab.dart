import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/rental_provider.dart';

// Isi tab sementara (Tahap 4): judul tab dan ringkasan data dari RentalProvider,
// supaya bisa dicek bahwa provider sudah memuat data. Diganti layar asli mulai Tahap 5.
class PlaceholderTab extends StatelessWidget {
  final String title;

  const PlaceholderTab({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final rental = context.watch<RentalProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              if (rental.isLoading)
                const CircularProgressIndicator()
              else if (rental.errorMessage != null) ...[
                Text(
                  rental.errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: rental.loadInitialData,
                  child: const Text('Coba lagi'),
                ),
              ] else
                Text(
                  '${rental.cars.length} mobil · ${rental.bookings.length} booking · '
                  '${rental.unreadCount} notifikasi belum dibaca',
                  textAlign: TextAlign.center,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
