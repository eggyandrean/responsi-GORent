import 'package:flutter/material.dart';

import '../config/constants.dart';
import '../models/car.dart';
import '../utils/formatter.dart';
import 'car_image.dart';

// Kartu kecil di daftar horizontal Popular Vehicles: foto, label tipe, nama, rating, dan harga
class PopularCarCard extends StatelessWidget {
  final Car car;
  final VoidCallback? onTap;

  const PopularCarCard({super.key, required this.car, this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CarImage(
                url: car.images.isEmpty ? null : car.images.first,
                car: car,
                height: 110,
                borderRadius: BorderRadius.zero,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Label tipe mobil
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.tint,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        car.type,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.navy,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      car.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 14, color: AppColors.star),
                        const SizedBox(width: 2),
                        Text(
                          car.rating.toStringAsFixed(1),
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${car.seats} kursi · ${car.transmission}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Harga di baris sendiri supaya tidak terpotong di kartu yang sempit
                    Text.rich(
                      TextSpan(
                        text: formatRupiah(car.pricePerDay),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.navy,
                        ),
                        children: const [
                          TextSpan(
                            text: '/day',
                            style: TextStyle(
                              fontWeight: FontWeight.normal,
                              color: Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
