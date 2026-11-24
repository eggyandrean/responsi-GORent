import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../config/constants.dart';
import '../models/booking.dart';
import '../utils/formatter.dart';

// Kartu satu booking di My Bookings: kode, mobil, tanggal, lokasi, hari, metode bayar,
// total, dan chip status. Tombol Batalkan hanya untuk status Confirmed.
class BookingCard extends StatelessWidget {
  final Booking booking;
  final VoidCallback? onCancel;

  const BookingCard({super.key, required this.booking, this.onCancel});

  // Warna chip sesuai status
  static Color warnaStatus(String status) {
    switch (status) {
      case 'Confirmed':
        return AppColors.navy;
      case 'Completed':
        return AppColors.green;
      default:
        return AppColors.error; // Cancelled
    }
  }

  @override
  Widget build(BuildContext context) {
    final warna = warnaStatus(booking.status);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '#${booking.bookingCode}',
                    style: const TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: warna.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    booking.status,
                    style: TextStyle(
                      color: warna,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _FotoKecil(url: booking.carImage),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    booking.carName,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _Baris(
              icon: Icons.calendar_today_outlined,
              teks:
                  '${formatTanggalRange(booking.pickupDate, booking.dropoffDate)} '
                  '${booking.dropoffDate.year} · ${booking.days} hari',
            ),
            _Baris(
              icon: Icons.location_on_outlined,
              teks: '${booking.pickupLocation} → ${booking.dropoffLocation}',
            ),
            _Baris(icon: Icons.payments_outlined, teks: booking.paymentMethod),
            const Divider(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(
                    formatRupiah(booking.totalPrice),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.navy,
                    ),
                  ),
                ),
                if (booking.isConfirmed && onCancel != null)
                  OutlinedButton(
                    onPressed: onCancel,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      minimumSize: const Size(100, 38),
                    ),
                    child: const Text('Batalkan'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Baris extends StatelessWidget {
  final IconData icon;
  final String teks;

  const _Baris({required this.icon, required this.teks});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.black54),
          const SizedBox(width: 6),
          Expanded(
            child: Text(teks, style: const TextStyle(color: Colors.black87)),
          ),
        ],
      ),
    );
  }
}

// Foto kecil mobil (foto pertama dari server); ikon mobil jika kosong atau gagal dimuat
class _FotoKecil extends StatelessWidget {
  final String? url;

  const _FotoKecil({required this.url});

  @override
  Widget build(BuildContext context) {
    final ikon = Container(
      color: AppColors.tint,
      alignment: Alignment.center,
      child: Icon(
        Icons.directions_car_filled,
        color: AppColors.navy.withValues(alpha: 0.6),
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 64,
        height: 48,
        child: (url == null || url!.isEmpty)
            ? ikon
            : Image.network(
                url!,
                fit: BoxFit.cover,
                headers: kIsWeb ? null : imageHeaders,
                errorBuilder: (context, error, stackTrace) => ikon,
              ),
      ),
    );
  }
}
