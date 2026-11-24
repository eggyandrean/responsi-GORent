import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/constants.dart';
import '../models/car.dart';
import '../providers/rental_provider.dart';
import '../services/api_service.dart';
import '../utils/formatter.dart';
import '../widgets/car_carousel.dart';
import '../widgets/pickup_map.dart';
import '../widgets/search_form.dart';
import 'booking_screen.dart';

// Vehicle Detail: carousel foto, info mobil, spesifikasi, fasilitas sewa, dan peta pickup
class VehicleDetailScreen extends StatelessWidget {
  final Car car;

  const VehicleDetailScreen({super.key, required this.car});

  void tampilkanPesan(BuildContext context, String pesan) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(pesan)));
  }

  Future<void> _toggleFavorit(BuildContext context, Car mobil) async {
    try {
      await context.read<RentalProvider>().toggleFavorite(mobil);
    } on ApiException catch (e) {
      if (context.mounted) tampilkanPesan(context, e.detailMessage);
    }
  }

  // Continue to Booking: jika form pencarian belum lengkap, minta diisi dulu lewat bottom sheet
  Future<void> _lanjutBooking(BuildContext context, Car mobil) async {
    final rental = context.read<RentalProvider>();
    if (rental.searchError != null) {
      final lanjut = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => const _SearchFormSheet(),
      );
      if (lanjut != true || !context.mounted) return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => BookingScreen(car: mobil)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rental = context.watch<RentalProvider>();
    // Ambil versi terbaru dari provider supaya status favorit ikut berubah
    final mobil = rental.cars.firstWhere(
      (c) => c.id == car.id,
      orElse: () => car,
    );

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Stack(
            children: [
              CarCarousel(car: mobil),
              // Tombol back dan favorit di atas carousel
              Positioned(
                top: MediaQuery.paddingOf(context).top + 8,
                left: 12,
                right: 12,
                child: Row(
                  children: [
                    _TombolBulat(
                      icon: Icons.arrow_back,
                      tooltip: 'Kembali',
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    _TombolBulat(
                      icon: mobil.isFavorite
                          ? Icons.favorite
                          : Icons.favorite_border,
                      warna: mobil.isFavorite
                          ? AppColors.error
                          : AppColors.navy,
                      tooltip: mobil.isFavorite
                          ? 'Hapus dari favorit'
                          : 'Tambah ke favorit',
                      onPressed: () => _toggleFavorit(context, mobil),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoUtama(car: mobil),
                const SizedBox(height: 20),
                const _Judul('Vehicle Specs'),
                _VehicleSpecs(car: mobil),
                const SizedBox(height: 20),
                const _Judul('Rental Includes'),
                _RentalIncludes(car: mobil),
                const SizedBox(height: 20),
                const _Judul('Pickup Location'),
                PickupMap(provider: mobil.provider),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.place_outlined,
                      size: 18,
                      color: Colors.black54,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        mobil.provider.address.isEmpty
                            ? mobil.provider.name
                            : mobil.provider.address,
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      // Bar bawah: harga per hari dan tombol Continue to Booking
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 8,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Price',
                      style: TextStyle(color: Colors.black54, fontSize: 12),
                    ),
                    Text.rich(
                      TextSpan(
                        text: formatRupiah(mobil.pricePerDay),
                        style: const TextStyle(
                          fontSize: 18,
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
                  ],
                ),
              ),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _lanjutBooking(context, mobil),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
                  ),
                  child: const FittedBox(child: Text('Continue to Booking')),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Tombol bulat putih di atas foto
class _TombolBulat extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color warna;

  const _TombolBulat({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.warna = AppColors.navy,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 2,
      child: IconButton(
        icon: Icon(icon, color: warna),
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }
}

class _Judul extends StatelessWidget {
  final String teks;

  const _Judul(this.teks);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        teks,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}

// Nama, rating, tipe, dan chip provider
class _InfoUtama extends StatelessWidget {
  final Car car;

  const _InfoUtama({required this.car});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          car.name,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            const Icon(Icons.star, size: 18, color: AppColors.star),
            const SizedBox(width: 4),
            Text(
              car.rating.toStringAsFixed(1),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                '· ${car.type} · ${car.rentalType}',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.black54),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Chip(
          avatar: const Icon(
            Icons.storefront_outlined,
            size: 18,
            color: AppColors.navy,
          ),
          label: Text(car.provider.name),
          labelStyle: const TextStyle(color: AppColors.navy),
        ),
      ],
    );
  }
}

// Kursi, transmisi, lalu daftar vehicle_specs
class _VehicleSpecs extends StatelessWidget {
  final Car car;

  const _VehicleSpecs({required this.car});

  @override
  Widget build(BuildContext context) {
    final items = <(IconData, String)>[
      (Icons.event_seat_outlined, '${car.seats} Seats'),
      (Icons.settings_outlined, car.transmission),
      for (final spec in car.vehicleSpecs) (Icons.check_circle_outline, spec),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (icon, teks) in items)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(buttonRadius),
              border: Border.all(color: AppColors.tintDark),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: AppColors.navy),
                const SizedBox(width: 6),
                Text(teks, style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
      ],
    );
  }
}

// Fasilitas sewa; Dengan Sopir mendapat tambahan sopir profesional
class _RentalIncludes extends StatelessWidget {
  final Car car;

  const _RentalIncludes({required this.car});

  @override
  Widget build(BuildContext context) {
    final items = <(IconData, String)>[
      (Icons.verified_user_outlined, 'Insurance'),
      (Icons.support_agent, '24/7 Support'),
      if (car.isDenganSopir) (Icons.person_pin_outlined, 'Sopir profesional'),
    ];

    return Column(
      children: [
        for (final (icon, teks) in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(icon, color: AppColors.green, size: 20),
                const SizedBox(width: 10),
                Text(teks),
              ],
            ),
          ),
      ],
    );
  }
}

// Bottom sheet saat form pencarian belum lengkap: SearchForm yang sama dengan Home
class _SearchFormSheet extends StatelessWidget {
  const _SearchFormSheet();

  @override
  Widget build(BuildContext context) {
    final pesan = context.watch<RentalProvider>().searchError;

    return Padding(
      // Geser ke atas saat keyboard/dialog muncul
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Lengkapi detail sewa dulu',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              const SearchForm(),
              const SizedBox(height: 12),
              if (pesan != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    pesan,
                    style: const TextStyle(color: AppColors.error),
                  ),
                ),
              ElevatedButton(
                // Tombol aktif hanya jika form sudah valid
                onPressed: pesan == null
                    ? () => Navigator.pop(context, true)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                ),
                child: const Text('Lanjut ke Booking'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
