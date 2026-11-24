import 'package:flutter/material.dart';

import '../config/constants.dart';
import '../models/car.dart';
import '../utils/formatter.dart';
import 'car_image.dart';

// Kartu mobil di Search Results: foto, nama, rating, kursi, transmisi, harga/day, dan Book Now
class CarCard extends StatelessWidget {
  final Car car;
  final VoidCallback? onTap; // ketuk kartu
  final VoidCallback? onBookNow; // tombol Book Now

  const CarCard({super.key, required this.car, this.onTap, this.onBookNow});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CarImage(
              url: car.images.isEmpty ? null : car.images.first,
              car: car,
              height: 170,
              borderRadius: BorderRadius.zero,
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nama dan rating
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          car.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Icon(Icons.star, size: 16, color: AppColors.star),
                      const SizedBox(width: 2),
                      Text(
                        car.rating.toStringAsFixed(1),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Spesifikasi singkat: kursi, transmisi, tipe
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      _InfoKecil(
                        icon: Icons.event_seat_outlined,
                        teks: '${car.seats} kursi',
                      ),
                      _InfoKecil(
                        icon: Icons.settings_outlined,
                        teks: car.transmission,
                      ),
                      _InfoKecil(
                        icon: Icons.directions_car_outlined,
                        teks: car.type,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Harga dan tombol Book Now
                  Row(
                    children: [
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            text: formatRupiah(car.pricePerDay),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.navy,
                            ),
                            children: const [
                              TextSpan(
                                text: '/day',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.normal,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: onBookNow,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.green,
                          minimumSize: const Size(110, 40),
                        ),
                        child: const Text('Book Now'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoKecil extends StatelessWidget {
  final IconData icon;
  final String teks;

  const _InfoKecil({required this.icon, required this.teks});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.black54),
        const SizedBox(width: 4),
        Text(teks, style: const TextStyle(fontSize: 13, color: Colors.black87)),
      ],
    );
  }
}
