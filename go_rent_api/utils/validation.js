// Helper validasi manual (tanpa library tambahan)

// Ubah nilai menjadi bilangan bulat positif, atau null jika tidak valid
export function toPositiveInt(value) {
  const angka = Number(value);
  return Number.isInteger(angka) && angka > 0 ? angka : null;
}

// Cek format tanggal YYYY-MM-DD dan tanggalnya benar-benar ada (misalnya bukan 2026-02-30)
export function isValidDate(value) {
  if (typeof value !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(value)) return false;
  const [y, m, d] = value.split('-').map(Number);
  const tanggal = new Date(Date.UTC(y, m - 1, d));
  return tanggal.getUTCFullYear() === y && tanggal.getUTCMonth() === m - 1 && tanggal.getUTCDate() === d;
}

// Selisih hari antara dua tanggal YYYY-MM-DD, dihitung di UTC supaya tidak meleset karena timezone
export function diffDays(start, end) {
  const toUtc = (s) => {
    const [y, m, d] = s.split('-').map(Number);
    return Date.UTC(y, m - 1, d);
  };
  return Math.round((toUtc(end) - toUtc(start)) / 86400000);
}

// Kirim respons validasi gagal dengan bentuk yang seragam
export function sendValidationError(res, errors) {
  return res.status(400).json({ message: 'Validasi gagal', errors });
}
