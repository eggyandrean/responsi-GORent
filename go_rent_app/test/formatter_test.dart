import 'package:flutter_test/flutter_test.dart';
import 'package:go_rent_app/utils/formatter.dart';

void main() {
  test('formatRupiah memakai titik ribuan', () {
    expect(formatRupiah(450000), 'Rp 450.000');
    expect(formatRupiah(2500000), 'Rp 2.500.000');
  });

  test('formatTanggalRange sesuai contoh SPEC', () {
    expect(
      formatTanggalRange(DateTime(2026, 4, 24), DateTime(2026, 4, 26)),
      '24 - 26 Apr',
    );
    expect(
      formatTanggalRange(DateTime(2026, 4, 30), DateTime(2026, 5, 2)),
      '30 Apr - 2 May',
    );
  });

  test('hitungJumlahHari mengabaikan jam dan minimal 1', () {
    expect(
      hitungJumlahHari(
        DateTime(2026, 12, 1, 23, 0),
        DateTime(2026, 12, 3, 1, 0),
      ),
      2,
    );
    expect(hitungJumlahHari(DateTime(2026, 12, 1), DateTime(2026, 12, 1)), 1);
    expect(formatTanggalApi(DateTime(2026, 4, 5)), '2026-04-05');
  });

  test('formatWaktuRelatif', () {
    final sekarang = DateTime(2026, 11, 24, 15, 0);
    expect(
      formatWaktuRelatif(DateTime(2026, 11, 24, 13, 0), sekarang: sekarang),
      '2 hours ago',
    );
    expect(
      formatWaktuRelatif(DateTime(2026, 11, 23, 15, 0), sekarang: sekarang),
      '1 day ago',
    );
    expect(
      formatWaktuRelatif(
        DateTime(2026, 11, 24, 14, 59, 30),
        sekarang: sekarang,
      ),
      'Just now',
    );
  });
}
