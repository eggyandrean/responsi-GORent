import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/constants.dart';
import '../providers/rental_provider.dart';

// Header navy Home: avatar inisial, judul GO-RENT, ikon My Bookings, dan lonceng notifikasi.
// Ikon memakai changeTab supaya tetap di MainScreen (tidak menumpuk route baru).
class GoRentAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GoRentAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final rental = context.watch<RentalProvider>();
    final inisial = rental.user?.initials ?? '';

    return AppBar(
      backgroundColor: AppColors.navy,
      titleSpacing: 16,
      title: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white,
            child: inisial.isEmpty
                ? const Icon(Icons.person, color: AppColors.navy, size: 20)
                : Text(
                    inisial,
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          const Text(
            'GO-RENT',
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: 'My Bookings',
          icon: const Icon(Icons.directions_car_outlined),
          onPressed: () => rental.changeTab(1),
        ),
        IconButton(
          tooltip: 'Notifications',
          // Titik merah jika ada notifikasi belum dibaca
          icon: Badge(
            isLabelVisible: rental.unreadCount > 0,
            smallSize: 8,
            backgroundColor: AppColors.error,
            child: const Icon(Icons.notifications_outlined),
          ),
          onPressed: () => rental.changeTab(2),
        ),
        const SizedBox(width: 4),
      ],
    );
  }
}
