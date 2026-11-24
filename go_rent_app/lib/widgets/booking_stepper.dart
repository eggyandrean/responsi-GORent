import 'package:flutter/material.dart';

import '../config/constants.dart';

// Indikator 3 langkah booking: selesai = hijau, aktif = navy, belum = abu-abu.
// Langkah yang sudah selesai bisa diketuk untuk kembali.
class BookingStepper extends StatelessWidget {
  final int currentStep;
  final ValueChanged<int> onStepTapped;

  const BookingStepper({
    super.key,
    required this.currentStep,
    required this.onStepTapped,
  });

  static const List<String> langkah = ['Vehicle', 'Details', 'Payment'];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          for (var i = 0; i < langkah.length; i++) ...[
            _Langkah(
              nomor: i + 1,
              label: langkah[i],
              selesai: i < currentStep,
              aktif: i == currentStep,
              onTap: i < currentStep ? () => onStepTapped(i) : null,
            ),
            // Garis penghubung antar langkah
            if (i < langkah.length - 1)
              Expanded(
                child: Container(
                  height: 2,
                  margin: const EdgeInsets.only(bottom: 18),
                  color: i < currentStep ? AppColors.green : Colors.black12,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _Langkah extends StatelessWidget {
  final int nomor;
  final String label;
  final bool selesai;
  final bool aktif;
  final VoidCallback? onTap;

  const _Langkah({
    required this.nomor,
    required this.label,
    required this.selesai,
    required this.aktif,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final warna = selesai
        ? AppColors.green
        : aktif
        ? AppColors.navy
        : Colors.grey;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: warna,
              child: selesai
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : Text(
                      '$nomor',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: warna,
                fontWeight: aktif ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
