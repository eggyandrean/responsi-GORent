import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/constants.dart';
import '../providers/rental_provider.dart';
import '../utils/formatter.dart';

// Kartu form pencarian "Where to, {lokasi}?": 2 dropdown lokasi dan 2 field tanggal.
// Semua nilai disimpan langsung di RentalProvider, jadi widget yang sama bisa dipakai
// di Home dan di bottom sheet Vehicle Detail dengan isi yang selalu sama.
class SearchForm extends StatelessWidget {
  const SearchForm({super.key});

  @override
  Widget build(BuildContext context) {
    final rental = context.watch<RentalProvider>();
    final lokasi = rental.pickupLocation ?? lokasiList.first;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.navyLight,
        borderRadius: BorderRadius.circular(cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Where to, $lokasi?',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _DropdownLokasi(
            label: 'Pick-up',
            icon: Icons.location_on_outlined,
            value: rental.pickupLocation,
            onChanged: rental.setPickupLocation,
          ),
          const SizedBox(height: 10),
          _DropdownLokasi(
            label: 'Drop-off',
            icon: Icons.flag_outlined,
            value: rental.dropoffLocation,
            onChanged: rental.setDropoffLocation,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _FieldTanggal(
                  label: 'Pick-up date',
                  value: rental.pickupDate,
                  onTap: () => _pilihTanggalPickup(context, rental),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _FieldTanggal(
                  label: 'Drop-off date',
                  value: rental.dropoffDate,
                  onTap: () => _pilihTanggalDropoff(context, rental),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Tanggal pick-up paling awal hari ini, paling lambat setahun ke depan
  Future<void> _pilihTanggalPickup(
    BuildContext context,
    RentalProvider rental,
  ) async {
    final hariIni = _tanggalSaja(DateTime.now());
    final awal = rental.pickupDate;
    final dipilih = await showDatePicker(
      context: context,
      initialDate: awal != null && !awal.isBefore(hariIni) ? awal : hariIni,
      firstDate: hariIni,
      lastDate: hariIni.add(const Duration(days: 365)),
      helpText: 'Pilih tanggal pick-up',
    );
    if (dipilih != null) rental.setPickupDate(dipilih);
  }

  // Tanggal drop-off paling awal sehari setelah pick-up (atau besok jika pick-up belum dipilih)
  Future<void> _pilihTanggalDropoff(
    BuildContext context,
    RentalProvider rental,
  ) async {
    final dasar = rental.pickupDate ?? _tanggalSaja(DateTime.now());
    final pertama = dasar.add(const Duration(days: 1));
    final awal = rental.dropoffDate;
    final dipilih = await showDatePicker(
      context: context,
      initialDate: awal != null && !awal.isBefore(pertama) ? awal : pertama,
      firstDate: pertama,
      lastDate: pertama.add(const Duration(days: 365)),
      helpText: 'Pilih tanggal drop-off',
    );
    if (dipilih != null) rental.setDropoffDate(dipilih);
  }

  static DateTime _tanggalSaja(DateTime d) => DateTime(d.year, d.month, d.day);
}

// Dropdown lokasi berlatar putih di atas kartu navy
class _DropdownLokasi extends StatelessWidget {
  final String label;
  final IconData icon;
  final String? value;
  final ValueChanged<String?> onChanged;

  const _DropdownLokasi({
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(buttonRadius),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.navy, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                isExpanded: true,
                hint: Text('Lokasi $label'),
                items: [
                  for (final lokasi in lokasiList)
                    DropdownMenuItem(value: lokasi, child: Text(lokasi)),
                ],
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Field tanggal yang membuka showDatePicker saat diketuk
class _FieldTanggal extends StatelessWidget {
  final String label;
  final DateTime? value;
  final VoidCallback onTap;

  const _FieldTanggal({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(buttonRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(buttonRadius),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 18,
                color: AppColors.navy,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.black54,
                      ),
                    ),
                    Text(
                      value == null ? 'Pilih tanggal' : formatTanggal(value!),
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
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
