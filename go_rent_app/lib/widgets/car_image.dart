import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../config/constants.dart';
import '../models/car.dart';

// Satu widget foto mobil untuk semua layar (kartu Home, Search Results, carousel, My Bookings).
// - url kosong/null  : langsung gambar simulasi, tanpa request jaringan
// - sedang dimuat    : kotak tint + loading kecil
// - gagal dimuat     : gambar simulasi (bukan ikon error merah)
class CarImage extends StatelessWidget {
  final String? url;
  final Car car;
  final double? height;
  final BorderRadius borderRadius;
  final String label; // label placeholder, misalnya "Tampak samping"

  const CarImage({
    super.key,
    required this.url,
    required this.car,
    this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(cardRadius)),
    this.label = 'Simulasi foto',
  });

  @override
  Widget build(BuildContext context) {
    final placeholder = CarImagePlaceholder(car: car, label: label);

    Widget isi;
    if (url == null || url!.isEmpty) {
      isi = placeholder;
    } else {
      isi = Image.network(
        url!,
        // Header User-Agent hanya untuk Android/iOS; browser tidak mengizinkan header ini
        headers: kIsWeb ? null : imageHeaders,
        fit: BoxFit.cover,
        width: double.infinity,
        height: height,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            color: AppColors.tint,
            alignment: Alignment.center,
            child: const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => placeholder,
      );
    }

    return ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(height: height, width: double.infinity, child: isi),
    );
  }
}

// Gambar simulasi yang digambar Flutter sendiri: gradasi tint, ikon sesuai tipe, dan nama mobil
class CarImagePlaceholder extends StatelessWidget {
  final Car car;
  final String label;

  const CarImagePlaceholder({
    super.key,
    required this.car,
    this.label = 'Simulasi foto',
  });

  // Ikon sesuai tipe mobil (aturan di SPEC bagian Gambar simulasi)
  IconData get _icon {
    if (label == 'Interior') return Icons.event_seat;
    final tipe = car.type.toUpperCase();
    if (tipe.contains('MPV')) return Icons.airport_shuttle;
    if (tipe.contains('ELECTRIC')) return Icons.electric_car;
    return Icons.directions_car_filled;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.tint, AppColors.tintDark],
        ),
      ),
      padding: const EdgeInsets.all(8),
      // FittedBox supaya isi mengecil di kotak kecil dan tidak overflow
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_icon, size: 64, color: AppColors.navy.withValues(alpha: 0.6)),
            const SizedBox(height: 4),
            Text(
              car.name,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.navy,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
