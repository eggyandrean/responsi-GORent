// Controller booking: GET /bookings, POST /bookings, PUT /bookings/:id
import pool from '../config/db.js';
import { toImageUrl } from '../utils/imageUrl.js';
import { toPositiveInt, isValidDate, diffDays, sendValidationError } from '../utils/validation.js';

// Biaya asuransi tetap, sama dengan biayaAsuransi di Flutter
const BIAYA_ASURANSI = 80000;

// Query booking + nama mobil + metode bayar + foto pertama mobil
const BOOKING_SELECT = `
  SELECT b.*, c.name AS car_name, c.type AS car_type, c.rental_type, pm.name AS payment_method,
         (SELECT ci.image_url FROM car_images ci WHERE ci.car_id = b.car_id
          ORDER BY ci.sort_order LIMIT 1) AS car_image
  FROM bookings b
  JOIN cars c ON c.id = b.car_id
  JOIN payment_methods pm ON pm.id = b.payment_method_id`;

// Rapikan satu baris booking untuk dikirim ke Flutter
function formatBooking(req, row) {
  return {
    ...row,
    sim_uploaded: row.sim_uploaded === 1,
    car_image: toImageUrl(req, row.car_image),
  };
}

async function cariBooking(req, id) {
  const [rows] = await pool.query(`${BOOKING_SELECT} WHERE b.id = ?`, [id]);
  return rows.length ? formatBooking(req, rows[0]) : null;
}

// GET /bookings?user_id=1  (terbaru dulu)
export async function getBookings(req, res) {
  const userId = toPositiveInt(req.query.user_id);
  if (!userId) return sendValidationError(res, { user_id: 'user_id wajib diisi dan berupa angka' });

  const [rows] = await pool.query(
    `${BOOKING_SELECT} WHERE b.user_id = ? ORDER BY b.created_at DESC, b.id DESC`,
    [userId],
  );
  res.json(rows.map((row) => formatBooking(req, row)));
}

// POST /bookings, mengikuti "Aturan POST /bookings" di SPEC.md
export async function createBooking(req, res) {
  const body = req.body ?? {};
  const errors = {};

  // 1. Validasi field wajib dan formatnya
  const userId = toPositiveInt(body.user_id);
  const carId = toPositiveInt(body.car_id);
  const paymentMethodId = toPositiveInt(body.payment_method_id);
  const renterName = typeof body.renter_name === 'string' ? body.renter_name.trim() : '';
  const pickupLocation = typeof body.pickup_location === 'string' ? body.pickup_location.trim() : '';
  const dropoffLocation = typeof body.dropoff_location === 'string' ? body.dropoff_location.trim() : '';
  const { pickup_date: pickupDate, dropoff_date: dropoffDate } = body;

  if (!userId) errors.user_id = 'user_id wajib diisi';
  if (!carId) errors.car_id = 'car_id wajib diisi';
  if (!paymentMethodId) errors.payment_method_id = 'Metode pembayaran wajib dipilih';
  if (!renterName) errors.renter_name = 'Nama penyewa wajib diisi';
  else if (renterName.length < 3) errors.renter_name = 'Nama penyewa minimal 3 huruf';
  if (!pickupLocation) errors.pickup_location = 'Lokasi pickup wajib diisi';
  if (!dropoffLocation) errors.dropoff_location = 'Lokasi drop-off wajib diisi';
  if (!isValidDate(pickupDate)) errors.pickup_date = 'Tanggal pickup wajib dengan format YYYY-MM-DD';
  if (!isValidDate(dropoffDate)) errors.dropoff_date = 'Tanggal drop-off wajib dengan format YYYY-MM-DD';
  else if (isValidDate(pickupDate) && diffDays(pickupDate, dropoffDate) < 1) {
    errors.dropoff_date = 'Tanggal drop-off harus setelah tanggal pickup';
  }
  if (typeof body.with_insurance !== 'boolean') errors.with_insurance = 'with_insurance wajib true atau false';
  if (body.sim_uploaded !== true) errors.sim_uploaded = 'SIM/KTP wajib di-upload';

  if (Object.keys(errors).length) return sendValidationError(res, errors);

  // 2. Pastikan user, mobil, dan metode bayar ada di database
  const [[user]] = await pool.query('SELECT id FROM users WHERE id = ?', [userId]);
  const [[car]] = await pool.query('SELECT id, name, price_per_day FROM cars WHERE id = ?', [carId]);
  const [[payment]] = await pool.query('SELECT id FROM payment_methods WHERE id = ?', [paymentMethodId]);
  if (!user) errors.user_id = 'User tidak ditemukan';
  if (!car) errors.car_id = 'Mobil tidak ditemukan';
  if (!payment) errors.payment_method_id = 'Metode pembayaran tidak ditemukan';
  if (Object.keys(errors).length) return sendValidationError(res, errors);

  // 3. Hitung harga di server, angka dari aplikasi tidak dipakai
  const days = Math.max(1, diffDays(pickupDate, dropoffDate));
  const insuranceFee = body.with_insurance ? BIAYA_ASURANSI : 0;
  const totalPrice = days * car.price_per_day + insuranceFee;

  // 4. Simpan booking + notifikasi dalam satu transaksi
  const conn = await pool.getConnection();
  try {
    await conn.beginTransaction();

    // booking_code = GR + Ymd tanggal pickup + nomor urut 2 digit di hari itu.
    // FOR UPDATE mengunci baris supaya dua request bersamaan tidak mendapat nomor yang sama.
    const prefix = `GR${pickupDate.replaceAll('-', '')}`;
    const [[last]] = await conn.query(
      'SELECT MAX(booking_code) AS kode FROM bookings WHERE booking_code LIKE ? FOR UPDATE',
      [`${prefix}__`],
    );
    const nomorUrut = last.kode ? Number(last.kode.slice(-2)) + 1 : 1;
    if (nomorUrut > 99) {
      await conn.rollback();
      return sendValidationError(res, { pickup_date: 'Kuota booking untuk tanggal ini sudah penuh' });
    }
    const bookingCode = `${prefix}${String(nomorUrut).padStart(2, '0')}`;

    const [hasil] = await conn.query(
      `INSERT INTO bookings (booking_code, user_id, car_id, payment_method_id, renter_name,
         pickup_location, dropoff_location, pickup_date, dropoff_date, days, price_per_day,
         insurance_fee, total_price, sim_uploaded, status)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1, 'Confirmed')`,
      [
        bookingCode, userId, carId, paymentMethodId, renterName, pickupLocation, dropoffLocation,
        pickupDate, dropoffDate, days, car.price_per_day, insuranceFee, totalPrice,
      ],
    );

    await conn.query(
      `INSERT INTO notifications (user_id, booking_id, title, description, type, is_read)
       VALUES (?, ?, 'Booking Confirmed', ?, 'order', 0)`,
      [userId, hasil.insertId, `Booking #${bookingCode} for ${car.name} is confirmed.`],
    );

    await conn.commit();
    res.status(201).json(await cariBooking(req, hasil.insertId));
  } catch (err) {
    await conn.rollback().catch(() => {});
    throw err; // diteruskan ke error handler terpusat
  } finally {
    conn.release();
  }
}

// PUT /bookings/:id  body: { status: "Cancelled" }
export async function updateBooking(req, res) {
  const id = toPositiveInt(req.params.id);
  const booking = id ? await cariBooking(req, id) : null;
  if (!booking) return res.status(404).json({ message: 'Booking tidak ditemukan' });

  // Versi ini hanya mendukung pembatalan, dan hanya untuk booking yang masih Confirmed
  if (req.body?.status !== 'Cancelled') {
    return sendValidationError(res, { status: 'status hanya boleh diubah menjadi Cancelled' });
  }
  if (booking.status !== 'Confirmed') {
    return sendValidationError(res, { status: `Booking berstatus ${booking.status} tidak bisa dibatalkan` });
  }

  await pool.query("UPDATE bookings SET status = 'Cancelled' WHERE id = ?", [id]);
  res.json(await cariBooking(req, id));
}
