import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/notification_item.dart';
import '../providers/rental_provider.dart';
import '../services/api_service.dart';
import '../widgets/list_state_view.dart';
import '../widgets/notification_card.dart';

// Tab Notifications: ketuk kartu = tandai dibaca, × = hapus, "Tandai semua" di AppBar
class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  void tampilkanPesan(BuildContext context, String pesan) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(pesan)));
  }

  // Jalankan aksi ke server; jika gagal tampilkan pesan backend
  Future<void> _jalankan(
    BuildContext context,
    Future<void> Function() aksi, [
    String? sukses,
  ]) async {
    try {
      await aksi();
      if (sukses != null && context.mounted) tampilkanPesan(context, sukses);
    } on ApiException catch (e) {
      if (context.mounted) tampilkanPesan(context, e.detailMessage);
    }
  }

  Future<void> _hapus(BuildContext context, NotificationItem notif) async {
    final setuju = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus notifikasi?'),
        content: Text('"${notif.title}" akan dihapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (setuju != true || !context.mounted) return;
    final rental = context.read<RentalProvider>();
    await _jalankan(
      context,
      () => rental.deleteNotification(notif.id),
      'Notifikasi dihapus',
    );
  }

  @override
  Widget build(BuildContext context) {
    final rental = context.watch<RentalProvider>();
    final notifs = rental.notifications;

    Widget isi;
    if (rental.isLoading && notifs.isEmpty) {
      isi = const Center(child: CircularProgressIndicator());
    } else if (rental.errorMessage != null && notifs.isEmpty) {
      isi = ListStateView(
        icon: Icons.cloud_off,
        pesan: rental.errorMessage!,
        isError: true,
        onRetry: rental.loadNotifications,
      );
    } else if (notifs.isEmpty) {
      isi = const ListStateView(
        icon: Icons.notifications_none,
        pesan: 'Belum ada notifikasi',
      );
    } else {
      isi = ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: notifs.length,
        itemBuilder: (context, index) {
          final notif = notifs[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: NotificationCard(
              notification: notif,
              onTap: () {
                if (!notif.isRead) {
                  _jalankan(context, () => rental.markAsRead(notif.id));
                }
              },
              onDelete: () => _hapus(context, notif),
            ),
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            // Nonaktif jika semua sudah dibaca
            onPressed: rental.unreadCount == 0
                ? null
                : () => _jalankan(
                    context,
                    rental.markAllAsRead,
                    'Semua notifikasi ditandai dibaca',
                  ),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              disabledForegroundColor: Colors.white54,
            ),
            child: const Text('Tandai semua'),
          ),
        ],
      ),
      body: RefreshIndicator(onRefresh: rental.loadNotifications, child: isi),
    );
  }
}
