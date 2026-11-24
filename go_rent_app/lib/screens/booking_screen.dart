import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/constants.dart';
import '../models/car.dart';
import '../providers/rental_provider.dart';
import '../utils/formatter.dart';

// Complete Booking versi sementara (Tahap 7): ringkasan pilihan supaya alur dari
// Vehicle Detail bisa dicoba. Stepper 3 langkah dan Pay Now dibuat di Tahap 8.
class BookingScreen extends StatelessWidget {
  final Car car;

  const BookingScreen({super.key, required this.car});

  @override
  Widget build(BuildContext context) {
    final rental = context.watch<RentalProvider>();
    final subtotal = rental.jumlahHari * car.pricePerDay;

    return Scaffold(
      appBar: AppBar(title: const Text('Complete Booking')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            car.name,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text('${rental.pickupLocation} → ${rental.dropoffLocation}'),
          Text('${rental.dateLabel} (${rental.jumlahHari} Days Rent)'),
          const SizedBox(height: 8),
          Text(
            'Subtotal ${formatRupiah(subtotal)} (belum termasuk asuransi ${formatRupiah(biayaAsuransi)})',
          ),
        ],
      ),
    );
  }
}
