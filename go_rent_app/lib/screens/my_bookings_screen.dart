import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/rental_provider.dart';
import '../services/api_service.dart';
import '../widgets/booking_card.dart';
import '../widgets/list_state_view.dart';

// Tab My Bookings: daftar booking terbaru dulu, batalkan booking Confirmed, tarik untuk refresh
class MyBookingsScreen extends StatelessWidget {
  const MyBookingsScreen({super.key});

  void tampilkanPesan(BuildContext context, String pesan) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(pesan)));
  }

  // Konfirmasi dulu sebelum membatalkan, lalu PUT /bookings/{id}
  Future<void> _batalkan(
    BuildContext context,
    int bookingId,
    String kode,
  ) async {
    final setuju = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Batalkan booking?'),
        content: Text(
          'Booking #$kode akan dibatalkan dan tidak bisa dikembalikan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Tidak'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Ya, batalkan'),
          ),
        ],
      ),
    );
    if (setuju != true || !context.mounted) return;

    try {
      await context.read<RentalProvider>().cancelBooking(bookingId);
      if (context.mounted) tampilkanPesan(context, 'Booking #$kode dibatalkan');
    } on ApiException catch (e) {
      if (context.mounted) tampilkanPesan(context, e.detailMessage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rental = context.watch<RentalProvider>();
    final bookings = rental.bookings;

    Widget isi;
    if (rental.isLoading && bookings.isEmpty) {
      isi = const Center(child: CircularProgressIndicator());
    } else if (rental.errorMessage != null && bookings.isEmpty) {
      isi = ListStateView(
        icon: Icons.cloud_off,
        pesan: rental.errorMessage!,
        isError: true,
        onRetry: rental.loadBookings,
      );
    } else if (bookings.isEmpty) {
      isi = const ListStateView(
        icon: Icons.directions_car_outlined,
        pesan:
            'Belum ada booking.\nCari mobil di tab Home untuk mulai menyewa.',
      );
    } else {
      isi = ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          final booking = bookings[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: BookingCard(
              booking: booking,
              onCancel: () =>
                  _batalkan(context, booking.id, booking.bookingCode),
            ),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('My Bookings')),
      body: RefreshIndicator(onRefresh: rental.loadBookings, child: isi),
    );
  }
}
