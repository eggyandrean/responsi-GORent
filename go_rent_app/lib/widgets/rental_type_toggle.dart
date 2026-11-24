import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/constants.dart';
import '../providers/rental_provider.dart';

// Toggle jenis sewa: Lepas Kunci / Dengan Sopir.
// Mengubah rentalType di provider, sehingga Popular Vehicles dan Search Results ikut berubah.
class RentalTypeToggle extends StatelessWidget {
  const RentalTypeToggle({super.key});

  static const List<String> pilihan = ['Lepas Kunci', 'Dengan Sopir'];

  @override
  Widget build(BuildContext context) {
    final rental = context.watch<RentalProvider>();

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.tint,
        borderRadius: BorderRadius.circular(buttonRadius),
      ),
      child: Row(
        children: [
          for (final jenis in pilihan)
            Expanded(
              child: _TombolJenis(
                label: jenis,
                icon: jenis == 'Lepas Kunci'
                    ? Icons.vpn_key_outlined
                    : Icons.person_pin_outlined,
                aktif: rental.rentalType == jenis,
                onTap: () => rental.setRentalType(jenis),
              ),
            ),
        ],
      ),
    );
  }
}

class _TombolJenis extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool aktif;
  final VoidCallback onTap;

  const _TombolJenis({
    required this.label,
    required this.icon,
    required this.aktif,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final warna = aktif ? Colors.white : AppColors.navy;

    return Material(
      color: aktif ? AppColors.navy : Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: warna),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: warna, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
