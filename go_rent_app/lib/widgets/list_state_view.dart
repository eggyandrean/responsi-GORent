import 'package:flutter/material.dart';

import '../config/constants.dart';

// Tampilan kosong atau error yang tetap bisa ditarik untuk refresh (dipakai di dalam RefreshIndicator)
class ListStateView extends StatelessWidget {
  final IconData icon;
  final String pesan;
  final bool isError;
  final VoidCallback? onRetry;

  const ListStateView({
    super.key,
    required this.icon,
    required this.pesan,
    this.isError = false,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      // AlwaysScrollable supaya pull-to-refresh tetap bisa walau isinya pendek
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 60),
        Icon(icon, size: 64, color: isError ? AppColors.error : Colors.black26),
        const SizedBox(height: 12),
        Text(
          pesan,
          textAlign: TextAlign.center,
          style: TextStyle(color: isError ? AppColors.error : Colors.black54),
        ),
        if (onRetry != null) ...[
          const SizedBox(height: 12),
          Center(
            child: OutlinedButton(
              onPressed: onRetry,
              child: const Text('Coba lagi'),
            ),
          ),
        ],
      ],
    );
  }
}
