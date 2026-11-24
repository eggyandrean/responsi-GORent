import 'package:flutter/material.dart';

import '../config/constants.dart';
import '../models/notification_item.dart';
import '../utils/formatter.dart';

// Kartu notifikasi: ikon sesuai type, judul, deskripsi, waktu relatif,
// titik + label status baca, dan tombol × untuk menghapus.
class NotificationCard extends StatelessWidget {
  final NotificationItem notification;
  final VoidCallback onTap; // tandai dibaca
  final VoidCallback onDelete;

  const NotificationCard({
    super.key,
    required this.notification,
    required this.onTap,
    required this.onDelete,
  });

  IconData get _icon {
    switch (notification.type) {
      case 'order':
        return Icons.receipt_long_outlined;
      case 'promo':
        return Icons.local_offer_outlined;
      default:
        return Icons.alarm; // reminder
    }
  }

  @override
  Widget build(BuildContext context) {
    final belumDibaca = !notification.isRead;

    return Card(
      // Notifikasi belum dibaca diberi latar tint supaya menonjol
      color: belumDibaca ? AppColors.tint : Colors.white,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: AppColors.navy.withValues(alpha: 0.1),
                child: Icon(_icon, color: AppColors.navy),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: TextStyle(
                        fontWeight: belumDibaca
                            ? FontWeight.bold
                            : FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(notification.description),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.circle,
                          size: 8,
                          color: belumDibaca ? AppColors.error : Colors.black26,
                        ),
                        const SizedBox(width: 4),
                        // Expanded + ellipsis supaya tidak overflow di layar sempit
                        Expanded(
                          child: Text(
                            belumDibaca ? 'Belum dibaca' : 'Sudah dibaca',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          formatWaktuRelatif(notification.createdAt),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Hapus notifikasi',
                icon: const Icon(Icons.close, size: 20),
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
