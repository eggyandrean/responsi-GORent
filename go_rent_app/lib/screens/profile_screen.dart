import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/constants.dart';
import '../models/user_profile.dart';
import '../providers/rental_provider.dart';
import '../services/api_service.dart';
import '../widgets/user_avatar.dart';

// Tab Profile: header navy melengkung, avatar, nama, chip Verified, dan menu akun
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void tampilkanPesan(BuildContext context, String pesan) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(pesan)));
  }

  // Bottom sheet info sederhana (Personal Information, Payment Methods, Driving License)
  void _bukaInfo(BuildContext context, String judul, List<Widget> isi) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                judul,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...isi,
            ],
          ),
        ),
      ),
    );
  }

  void _bukaAccountSettings(BuildContext context, UserProfile user) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      // Pesan sukses ditampilkan dari dalam sheet sebelum ditutup
      builder: (_) => _AccountSettingsSheet(user: user),
    );
  }

  void _bukaSupport(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Support & Help'),
        content: const Text(
          'Butuh bantuan? Hubungi tim GO-RENT setiap hari pukul 07.00-22.00 WIB '
          'lewat menu ini. Untuk kendala saat sewa, hubungi provider mobil yang tertera di booking.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  // Versi ini belum punya halaman login, jadi Log Out hanya konfirmasi
  Future<void> _logOut(BuildContext context) async {
    final setuju = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Yakin ingin keluar dari akun ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
    if (setuju == true && context.mounted) {
      tampilkanPesan(
        context,
        'Log out belum tersedia: aplikasi ini belum memiliki halaman login',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final rental = context.watch<RentalProvider>();
    final user = rental.user;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: Center(
          child: rental.isLoading
              ? const CircularProgressIndicator()
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      rental.errorMessage ?? 'Profil belum dimuat',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: rental.loadUser,
                      child: const Text('Coba lagi'),
                    ),
                  ],
                ),
        ),
      );
    }

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _HeaderProfil(user: user),
          const SizedBox(height: 12),
          _MenuItem(
            icon: Icons.manage_accounts_outlined,
            label: 'Account Settings',
            onTap: () => _bukaAccountSettings(context, user),
          ),
          _MenuItem(
            icon: Icons.person_outline,
            label: 'Personal Information',
            onTap: () => _bukaInfo(context, 'Personal Information', [
              _InfoBaris(label: 'Nama', nilai: user.name),
              _InfoBaris(label: 'Email', nilai: user.email),
              _InfoBaris(label: 'No. HP', nilai: user.phone),
            ]),
          ),
          _MenuItem(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Payment Methods',
            onTap: () => _bukaInfo(context, 'Payment Methods', [
              if (rental.paymentMethods.isEmpty)
                const Text('Belum ada metode pembayaran'),
              for (final m in rental.paymentMethods)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.check_circle_outline,
                    color: AppColors.green,
                  ),
                  title: Text(m.name),
                ),
            ]),
          ),
          _MenuItem(
            icon: Icons.badge_outlined,
            label: 'Driving License',
            onTap: () => _bukaInfo(context, 'Driving License', [
              _InfoBaris(
                label: 'SIM',
                nilai: user.drivingLicense ?? 'Belum diunggah',
              ),
              _InfoBaris(
                label: 'Status',
                nilai: user.isVerified ? 'Verified' : 'Belum diverifikasi',
              ),
            ]),
          ),
          _MenuItem(
            icon: Icons.history,
            label: 'Booking History',
            onTap: () => rental.changeTab(1),
          ),
          _MenuItem(
            icon: Icons.support_agent,
            label: 'Support & Help',
            onTap: () => _bukaSupport(context),
          ),
          _MenuItem(
            icon: Icons.logout,
            label: 'Log Out',
            warna: AppColors.error,
            onTap: () => _logOut(context),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// Header navy dengan sudut bawah melengkung
class _HeaderProfil extends StatelessWidget {
  final UserProfile user;

  const _HeaderProfil({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.paddingOf(context).top + 24,
        16,
        28,
      ),
      decoration: const BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: Column(
        children: [
          UserAvatar(
            avatarUrl: user.avatarUrl,
            initials: user.initials,
            radius: 44,
          ),
          const SizedBox(height: 12),
          Text(
            user.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(user.email, style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 10),
          if (user.isVerified)
            const Chip(
              avatar: Icon(Icons.verified, size: 18, color: AppColors.green),
              label: Text('Verified'),
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: AppColors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color warna;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.warna = AppColors.navy,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        child: ListTile(
          leading: Icon(icon, color: warna),
          title: Text(
            label,
            style: TextStyle(color: warna == AppColors.error ? warna : null),
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: onTap,
        ),
      ),
    );
  }
}

class _InfoBaris extends StatelessWidget {
  final String label;
  final String nilai;

  const _InfoBaris({required this.label, required this.nilai});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label, style: const TextStyle(color: Colors.black54)),
          ),
          Expanded(
            child: Text(
              nilai,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// Form Account Settings: ubah nama dan nomor HP lalu PUT /users/1
class _AccountSettingsSheet extends StatefulWidget {
  final UserProfile user;

  const _AccountSettingsSheet({required this.user});

  @override
  State<_AccountSettingsSheet> createState() => _AccountSettingsSheetState();
}

class _AccountSettingsSheetState extends State<_AccountSettingsSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController namaController = TextEditingController(
    text: widget.user.name,
  );
  late final TextEditingController noHpController = TextEditingController(
    text: widget.user.phone,
  );
  bool _isSaving = false;
  String? _pesanError; // pesan dari backend, ditampilkan di dalam sheet

  @override
  void dispose() {
    namaController.dispose();
    noHpController.dispose();
    super.dispose();
  }

  Future<void> _simpan() async {
    if (_isSaving || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _isSaving = true;
      _pesanError = null;
    });
    try {
      await context.read<RentalProvider>().updateUser(
        namaController.text.trim(),
        noHpController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profil berhasil disimpan')));
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (mounted) setState(() => _pesanError = e.detailMessage);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Naikkan form saat keyboard muncul
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Account Settings',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: namaController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nama',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().length < 3) {
                      return 'Nama minimal 3 huruf';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: noHpController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'No. HP',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  // Nomor HP disimpan sebagai teks; aturan sama dengan backend
                  validator: (value) {
                    final hp = value?.trim() ?? '';
                    if (hp.isEmpty) return 'Nomor HP wajib diisi';
                    if (!RegExp(r'^[0-9+\-\sXx]{8,20}$').hasMatch(hp)) {
                      return 'Nomor HP harus 8-20 karakter angka';
                    }
                    return null;
                  },
                ),
                if (_pesanError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _pesanError!,
                    style: const TextStyle(color: AppColors.error),
                  ),
                ],
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isSaving ? null : _simpan,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Simpan'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
