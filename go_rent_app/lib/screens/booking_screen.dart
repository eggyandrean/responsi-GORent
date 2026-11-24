import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../config/constants.dart';
import '../models/car.dart';
import '../models/payment_method.dart';
import '../providers/rental_provider.dart';
import '../services/api_service.dart';
import '../utils/formatter.dart';
import '../widgets/booking_stepper.dart';
import '../widgets/car_image.dart';

// Complete Booking: 3 langkah (Vehicle, Details, Payment) lalu Pay Now.
// Lokasi dan tanggal diambil dari form pencarian di RentalProvider.
class BookingScreen extends StatefulWidget {
  final Car car;

  const BookingScreen({super.key, required this.car});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController renterNameController = TextEditingController();

  int _step = 0; // 0 Vehicle, 1 Details, 2 Payment
  bool _withInsurance = true; // asuransi aktif secara default, bisa dimatikan
  bool _simUploaded = false;
  int? _paymentMethodId;
  bool _isSubmitting = false; // cegah Pay Now ditekan berkali-kali

  @override
  void initState() {
    super.initState();
    // Nama penyewa diisi awal dengan nama user, tetap bisa diubah
    renterNameController.text = context.read<RentalProvider>().user?.name ?? '';
  }

  @override
  void dispose() {
    renterNameController.dispose();
    super.dispose();
  }

  // Total di layar; server tetap menghitung ulang saat POST /bookings
  int _hitungTotal(RentalProvider rental) =>
      rental.jumlahHari * widget.car.pricePerDay +
      (_withInsurance ? biayaAsuransi : 0);

  // Pola tampilkanPesan() dari materi P6
  void tampilkanPesan(String pesan) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(pesan)));
  }

  // Pola sudahValid() dari materi P6: cek satu per satu, tampilkan pesan pertama yang gagal
  bool sudahValid() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      tampilkanPesan('Nama penyewa minimal 3 huruf');
      return false;
    }
    if (!_simUploaded) {
      tampilkanPesan('Upload SIM/KTP terlebih dahulu');
      return false;
    }
    if (_paymentMethodId == null) {
      tampilkanPesan('Pilih metode pembayaran');
      return false;
    }
    return true;
  }

  void _uploadSim() {
    // Simulasi: belum memakai kamera/galeri, hanya menandai sudah upload
    setState(() => _simUploaded = true);
    tampilkanPesan('SIM/KTP berhasil diunggah (simulasi)');
  }

  void _lanjut() => setState(() => _step++);

  Future<void> _payNow() async {
    if (_isSubmitting || !sudahValid()) return;
    final rental = context.read<RentalProvider>();
    final total = _hitungTotal(rental);

    // 1. Konfirmasi sebelum membuat booking
    final setuju = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Konfirmasi Pembayaran'),
        content: Text(
          'Bayar ${formatRupiah(total)} untuk ${widget.car.name} '
          '(${rental.jumlahHari} hari, ${rental.dateLabel})?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Bayar'),
          ),
        ],
      ),
    );
    if (setuju != true || !mounted) return;

    // 2. Kirim ke server
    setState(() => _isSubmitting = true);
    try {
      final booking = await rental.createBooking(
        car: widget.car,
        paymentMethodId: _paymentMethodId!,
        renterName: renterNameController.text.trim(),
        withInsurance: _withInsurance,
        simUploaded: _simUploaded,
      );
      if (!mounted) return;

      // 3. Sukses: tampilkan kode booking dan total dari server
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(
            Icons.check_circle,
            color: AppColors.green,
            size: 48,
          ),
          title: const Text('Booking Berhasil'),
          content: Text(
            'Kode booking ${booking.bookingCode}\n'
            'Total ${formatRupiah(booking.totalPrice)}',
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Lihat My Bookings'),
            ),
          ],
        ),
      );
      if (!mounted) return;

      // 4. Kembali ke MainScreen pada tab My Bookings
      rental.changeTab(1);
      Navigator.popUntil(context, (route) => route.isFirst);
    } on ApiException catch (e) {
      // Input tetap dipertahankan supaya pengguna cukup memperbaiki yang salah
      if (mounted) tampilkanPesan(e.detailMessage);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rental = context.watch<RentalProvider>();

    // Jaga-jaga: layar ini butuh lokasi dan tanggal dari form pencarian
    if (rental.searchError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Complete Booking')),
        body: Center(child: Text(rental.searchError!)),
      );
    }

    final total = _hitungTotal(rental);

    return Scaffold(
      appBar: AppBar(title: const Text('Complete Booking')),
      body: Column(
        children: [
          BookingStepper(
            currentStep: _step,
            onStepTapped: (index) => setState(() => _step = index),
          ),
          Expanded(
            // IndexedStack menjaga isi setiap langkah (nama, pilihan bayar) saat berpindah
            child: IndexedStack(
              index: _step,
              children: [
                _StepVehicle(car: widget.car, total: total),
                _StepDetails(
                  car: widget.car,
                  withInsurance: _withInsurance,
                  total: total,
                  onInsuranceChanged: (value) =>
                      setState(() => _withInsurance = value),
                ),
                Form(
                  key: _formKey,
                  child: _StepPayment(
                    car: widget.car,
                    total: total,
                    renterNameController: renterNameController,
                    simUploaded: _simUploaded,
                    onUploadSim: _uploadSim,
                    paymentMethodId: _paymentMethodId,
                    onPaymentChanged: (id) =>
                        setState(() => _paymentMethodId = id),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _BarBawah(
        total: total,
        labelTombol: _step < 2 ? 'Continue' : 'Pay Now',
        isLoading: _isSubmitting,
        onPressed: _step < 2 ? _lanjut : _payNow,
      ),
    );
  }
}

// ================= Langkah 1: Vehicle =================

class _StepVehicle extends StatelessWidget {
  final Car car;
  final int total;

  const _StepVehicle({required this.car, required this.total});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<RentalProvider>().user;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        CarImage(
          url: car.images.isEmpty ? null : car.images.first,
          car: car,
          height: 180,
        ),
        const SizedBox(height: 12),
        Text(
          car.name,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            const Icon(Icons.star, size: 16, color: AppColors.star),
            const SizedBox(width: 4),
            Text(car.rating.toStringAsFixed(1)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                '· ${car.provider.name}',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.black54),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _Kartu(
          children: [
            _BarisHarga(
              label: 'Total Price',
              nilai: formatRupiah(total),
              tebal: true,
            ),
          ],
        ),
        const SizedBox(height: 16),
        const _JudulBagian('Driver Information'),
        _Kartu(
          children: [
            if (car.isDenganSopir)
              _BarisInfo(
                icon: Icons.person_pin_outlined,
                label: 'Sopir',
                nilai: 'Sopir dari ${car.provider.name}',
              )
            else ...[
              _BarisInfo(
                icon: Icons.person_outline,
                label: 'Nama',
                nilai: user?.name ?? '-',
              ),
              _BarisInfo(
                icon: Icons.badge_outlined,
                label: 'SIM',
                nilai: user?.drivingLicense ?? 'Belum ada data SIM',
              ),
            ],
          ],
        ),
      ],
    );
  }
}

// ================= Langkah 2: Details =================

class _StepDetails extends StatelessWidget {
  final Car car;
  final bool withInsurance;
  final int total;
  final ValueChanged<bool> onInsuranceChanged;

  const _StepDetails({
    required this.car,
    required this.withInsurance,
    required this.total,
    required this.onInsuranceChanged,
  });

  @override
  Widget build(BuildContext context) {
    final rental = context.watch<RentalProvider>();
    final hari = rental.jumlahHari;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _JudulBagian('Rental Details'),
        _Kartu(
          children: [
            _BarisInfo(
              icon: Icons.calendar_today_outlined,
              label: 'Tanggal',
              nilai:
                  '${formatTanggal(rental.pickupDate!)} - ${formatTanggal(rental.dropoffDate!)}',
            ),
            _BarisInfo(
              icon: Icons.location_on_outlined,
              label: 'Pick-up',
              nilai: rental.pickupLocation!,
            ),
            _BarisInfo(
              icon: Icons.flag_outlined,
              label: 'Drop-off',
              nilai: rental.dropoffLocation!,
            ),
          ],
        ),
        const SizedBox(height: 16),
        const _JudulBagian('Price Details'),
        _Kartu(
          children: [
            _BarisHarga(
              label:
                  '$hari Days Rent (${formatRupiah(car.pricePerDay)} x $hari)',
              nilai: formatRupiah(hari * car.pricePerDay),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: withInsurance,
              onChanged: (value) => onInsuranceChanged(value ?? false),
              title: const Text('Insurance Add-on'),
              secondary: Text(formatRupiah(biayaAsuransi)),
            ),
            const Divider(),
            _BarisHarga(
              label: 'Total',
              nilai: formatRupiah(total),
              tebal: true,
            ),
          ],
        ),
      ],
    );
  }
}

// ================= Langkah 3: Payment =================

class _StepPayment extends StatelessWidget {
  final Car car;
  final int total;
  final TextEditingController renterNameController;
  final bool simUploaded;
  final VoidCallback onUploadSim;
  final int? paymentMethodId;
  final ValueChanged<int?> onPaymentChanged;

  const _StepPayment({
    required this.car,
    required this.total,
    required this.renterNameController,
    required this.simUploaded,
    required this.onUploadSim,
    required this.paymentMethodId,
    required this.onPaymentChanged,
  });

  @override
  Widget build(BuildContext context) {
    final rental = context.watch<RentalProvider>();
    final List<PaymentMethod> metode = rental.paymentMethods;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Ringkasan pesanan
        _Kartu(
          children: [
            Text(car.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              '${rental.pickupLocation} → ${rental.dropoffLocation} · ${rental.dateLabel} '
              '(${rental.jumlahHari} hari)',
              style: const TextStyle(color: Colors.black54),
            ),
            const Divider(),
            _BarisHarga(
              label: 'Total',
              nilai: formatRupiah(total),
              tebal: true,
            ),
          ],
        ),
        const SizedBox(height: 16),
        const _JudulBagian('Renter Name'),
        TextFormField(
          controller: renterNameController,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            hintText: 'Nama sesuai SIM/KTP',
            prefixIcon: Icon(Icons.person_outline),
          ),
          validator: (value) {
            if (value == null || value.trim().length < 3) {
              return 'Nama minimal 3 huruf';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        const _JudulBagian('SIM / KTP'),
        if (simUploaded)
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.check_circle, color: AppColors.green),
            title: Text('SIM/KTP terunggah'),
            subtitle: Text('Simulasi, belum memakai kamera/galeri'),
          )
        else
          OutlinedButton.icon(
            onPressed: onUploadSim,
            icon: const Icon(Icons.upload_file),
            label: const Text('Upload SIM/KTP'),
          ),
        const SizedBox(height: 16),
        const _JudulBagian('Payment Method'),
        if (metode.isEmpty)
          Row(
            children: [
              const Expanded(child: Text('Metode pembayaran belum dimuat')),
              TextButton(
                onPressed: rental.loadPaymentMethods,
                child: const Text('Muat ulang'),
              ),
            ],
          )
        else
          RadioGroup<int>(
            groupValue: paymentMethodId,
            onChanged: onPaymentChanged,
            child: Column(
              children: [
                for (final m in metode)
                  RadioListTile<int>(
                    contentPadding: EdgeInsets.zero,
                    value: m.id,
                    title: Text(m.name),
                    secondary: Icon(
                      m.name == 'Bank Transfer'
                          ? Icons.account_balance_outlined
                          : Icons.account_balance_wallet_outlined,
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

// ================= Widget kecil yang dipakai ulang =================

class _BarBawah extends StatelessWidget {
  final int total;
  final String labelTombol;
  final bool isLoading;
  final VoidCallback onPressed;

  const _BarBawah({
    required this.total,
    required this.labelTombol,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
                    'Total',
                    style: TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                  Text(
                    formatRupiah(total),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.navy,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ElevatedButton(
                onPressed: isLoading ? null : onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(labelTombol),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JudulBagian extends StatelessWidget {
  final String teks;

  const _JudulBagian(this.teks);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        teks,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _Kartu extends StatelessWidget {
  final List<Widget> children;

  const _Kartu({required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }
}

class _BarisInfo extends StatelessWidget {
  final IconData icon;
  final String label;
  final String nilai;

  const _BarisInfo({
    required this.icon,
    required this.label,
    required this.nilai,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.navy),
          const SizedBox(width: 8),
          SizedBox(
            width: 70,
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

class _BarisHarga extends StatelessWidget {
  final String label;
  final String nilai;
  final bool tebal;

  const _BarisHarga({
    required this.label,
    required this.nilai,
    this.tebal = false,
  });

  @override
  Widget build(BuildContext context) {
    final gaya = TextStyle(
      fontWeight: tebal ? FontWeight.bold : FontWeight.normal,
      fontSize: tebal ? 16 : 14,
      color: tebal ? AppColors.navy : null,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: gaya)),
          const SizedBox(width: 8),
          Text(nilai, style: gaya),
        ],
      ),
    );
  }
}
