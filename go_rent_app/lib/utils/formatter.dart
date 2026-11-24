import 'package:intl/intl.dart';

// Format harga Rupiah, contoh 450000 -> "Rp 450.000"
final NumberFormat _rupiah = NumberFormat.currency(
  locale: 'id',
  symbol: 'Rp ',
  decimalDigits: 0,
);

String formatRupiah(num nilai) => _rupiah.format(nilai);

// Rentang tanggal untuk AppBar dan kartu booking:
// bulan sama  -> "24 - 26 Apr"
// beda bulan -> "30 Apr - 2 May"
String formatTanggalRange(DateTime mulai, DateTime selesai) {
  final bulanSama = mulai.year == selesai.year && mulai.month == selesai.month;
  if (bulanSama) {
    return '${mulai.day} - ${DateFormat('d MMM', 'en_US').format(selesai)}';
  }
  final format = DateFormat('d MMM', 'en_US');
  return '${format.format(mulai)} - ${format.format(selesai)}';
}

// Satu tanggal lengkap, contoh "26 Apr 2023"
String formatTanggal(DateTime tanggal) =>
    DateFormat('d MMM yyyy', 'en_US').format(tanggal);

// Format tanggal yang dikirim ke API: "YYYY-MM-DD"
String formatTanggalApi(DateTime tanggal) =>
    DateFormat('yyyy-MM-dd').format(tanggal);

// Jumlah hari sewa dihitung dari tanggal saja (jam diabaikan) supaya tidak meleset satu hari.
// Hasil minimal 1, sama dengan aturan di backend.
int hitungJumlahHari(DateTime mulai, DateTime selesai) {
  final a = DateTime.utc(mulai.year, mulai.month, mulai.day);
  final b = DateTime.utc(selesai.year, selesai.month, selesai.day);
  final selisih = b.difference(a).inDays;
  return selisih < 1 ? 1 : selisih;
}

// Waktu relatif untuk notifikasi, contoh "2 hours ago" atau "1 day ago".
// Parameter sekarang bisa diisi saat pengujian.
String formatWaktuRelatif(DateTime waktu, {DateTime? sekarang}) {
  final selisih = (sekarang ?? DateTime.now()).difference(waktu);
  String satuan(int n, String kata) => '$n $kata${n == 1 ? '' : 's'} ago';

  if (selisih.inMinutes < 1) return 'Just now';
  if (selisih.inHours < 1) return satuan(selisih.inMinutes, 'minute');
  if (selisih.inDays < 1) return satuan(selisih.inHours, 'hour');
  if (selisih.inDays < 30) return satuan(selisih.inDays, 'day');
  return formatTanggal(waktu);
}
