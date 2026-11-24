// Seeder GO-RENT: mengosongkan semua tabel lalu mengisinya dari
// database/data_rental.json (hasil konversi docs/data_rental.txt) dan
// database/car_images.json (URL foto online per car_id).
// Jalankan setelah schema.sql di-import: npm run seed
import fs from 'node:fs';
import pool from '../config/db.js';

// Baca file JSON yang letaknya satu folder dengan seed.js
const bacaJson = (namaFile) =>
  JSON.parse(fs.readFileSync(new URL(`./${namaFile}`, import.meta.url), 'utf8'));

const dataRental = bacaJson('data_rental.json');
const carImages = bacaJson('car_images.json');

// Titik pusat Purwokerto, setiap provider digeser sedikit supaya marker di peta tidak menumpuk
const PUSAT_LAT = -7.4245;
const PUSAT_LNG = 109.234;

// Urutan tabel dari child ke master (dipakai untuk TRUNCATE)
const daftarTabel = [
  'favorites',
  'notifications',
  'bookings',
  'car_specs',
  'car_images',
  'cars',
  'payment_methods',
  'users',
  'providers',
];

// Ubah teks "2 hours ago" / "1 day ago" menjadi jumlah jam, untuk created_at notifikasi
function jamDariTeksWaktu(teks) {
  const cocok = /(\d+)\s*(hour|day)/i.exec(teks || '');
  if (!cocok) return 0;
  const angka = Number(cocok[1]);
  return cocok[2].toLowerCase() === 'day' ? angka * 24 : angka;
}

async function seed() {
  const conn = await pool.getConnection();
  try {
    // 1. Kosongkan tabel. TRUNCATE butuh foreign key check dimatikan sementara
    //    dan otomatis me-reset AUTO_INCREMENT, jadi id mobil kembali 1..20.
    await conn.query('SET FOREIGN_KEY_CHECKS = 0');
    for (const tabel of daftarTabel) {
      await conn.query(`TRUNCATE TABLE ${tabel}`);
    }
    await conn.query('SET FOREIGN_KEY_CHECKS = 1');

    // Semua insert di dalam satu transaksi: kalau satu gagal, semuanya dibatalkan
    await conn.beginTransaction();

    // 2. Providers: diambil dari nama provider unik di carList
    const namaProvider = [...new Set(dataRental.carList.map((car) => car.provider))];
    const providerId = {}; // nama provider -> id di database
    for (const [i, nama] of namaProvider.entries()) {
      // Geser titik secara melingkar kecil (sekitar 300-900 meter dari pusat)
      const sudut = (i / namaProvider.length) * 2 * Math.PI;
      const jarak = 0.003 + (i % 3) * 0.002;
      const lat = Number((PUSAT_LAT + jarak * Math.sin(sudut)).toFixed(7));
      const lng = Number((PUSAT_LNG + jarak * Math.cos(sudut)).toFixed(7));
      const [hasil] = await conn.execute(
        'INSERT INTO providers (name, address, latitude, longitude) VALUES (?, ?, ?, ?)',
        [nama, `Kantor ${nama}, Purwokerto, Banyumas`, lat, lng],
      );
      providerId[nama] = hasil.insertId;
    }

    // 3. Users: satu user dari userProfile (id = 1, dipakai sebagai currentUserId di Flutter)
    const profil = dataRental.userProfile;
    const [hasilUser] = await conn.execute(
      `INSERT INTO users (name, email, phone, is_verified, driving_license, avatar_url)
       VALUES (?, ?, ?, ?, ?, ?)`,
      [
        profil.name,
        profil.email,
        profil.phone,
        profil.is_verified ? 1 : 0,
        profil.driving_license,
        profil.avatar_url,
      ],
    );
    const userId = hasilUser.insertId;

    // 4. Payment methods: dari daftar payment_methods di userProfile
    const paymentId = {}; // nama metode -> id
    for (const nama of profil.payment_methods) {
      const [hasil] = await conn.execute('INSERT INTO payment_methods (name) VALUES (?)', [nama]);
      paymentId[nama] = hasil.insertId;
    }

    // 5. Cars + car_specs + car_images
    let jumlahFoto = 0;
    let jumlahSpec = 0;
    for (const car of dataRental.carList) {
      // id mobil ditulis eksplisit supaya cocok dengan key di car_images.json
      await conn.execute(
        `INSERT INTO cars (id, provider_id, name, type, rental_type, seats, transmission, rating, price_per_day)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        [
          car.id,
          providerId[car.provider],
          car.name,
          car.type,
          car.rental_type,
          car.seats,
          car.transmission,
          car.rating,
          car.price_per_day,
        ],
      );

      for (const spec of car.vehicle_specs) {
        await conn.execute('INSERT INTO car_specs (car_id, spec_name) VALUES (?, ?)', [car.id, spec]);
        jumlahSpec++;
      }

      // Foto diambil dari car_images.json (bukan URL picsum di data_rental),
      // maksimal 3. Mobil tanpa URL tetap aman: Flutter menampilkan gambar simulasi.
      const fotoMobil = (carImages[String(car.id)] || []).slice(0, 3);
      for (const [urutan, url] of fotoMobil.entries()) {
        await conn.execute(
          'INSERT INTO car_images (car_id, image_url, sort_order) VALUES (?, ?, ?)',
          [car.id, url, urutan + 1],
        );
        jumlahFoto++;
      }
    }

    // 6. Booking contoh GR20230426: Toyota Avanza 2023, 26-28 Apr 2023, sudah selesai
    const mobilContoh = dataRental.carList.find((car) => car.id === 1);
    const hariContoh = 2;
    const asuransiContoh = 80000;
    const [hasilBooking] = await conn.execute(
      `INSERT INTO bookings (booking_code, user_id, car_id, payment_method_id, renter_name,
         pickup_location, dropoff_location, pickup_date, dropoff_date, days, price_per_day,
         insurance_fee, total_price, sim_uploaded, status, created_at)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [
        'GR20230426',
        userId,
        mobilContoh.id,
        paymentId['OVO'],
        profil.name,
        'Purwokerto',
        'Purwokerto',
        '2023-04-26',
        '2023-04-28',
        hariContoh,
        mobilContoh.price_per_day,
        asuransiContoh,
        hariContoh * mobilContoh.price_per_day + asuransiContoh,
        1,
        'Completed',
        '2023-04-25 10:00:00',
      ],
    );
    const bookingContohId = hasilBooking.insertId;

    // 7. Notifications: created_at dihitung mundur dari sekarang sesuai teks "time".
    //    Notifikasi bertipe order dihubungkan ke booking contoh.
    for (const notif of dataRental.notifications) {
      await conn.execute(
        `INSERT INTO notifications (user_id, booking_id, title, description, type, is_read, created_at)
         VALUES (?, ?, ?, ?, ?, ?, DATE_SUB(NOW(), INTERVAL ? HOUR))`,
        [
          userId,
          notif.type === 'order' ? bookingContohId : null,
          notif.title,
          notif.description,
          notif.type,
          notif.is_read ? 1 : 0,
          jamDariTeksWaktu(notif.time),
        ],
      );
    }

    await conn.commit();

    console.log('Seeder selesai:');
    console.log(`  providers       : ${namaProvider.length}`);
    console.log('  users           : 1');
    console.log(`  payment_methods : ${profil.payment_methods.length}`);
    console.log(`  cars            : ${dataRental.carList.length}`);
    console.log(`  car_specs       : ${jumlahSpec}`);
    console.log(`  car_images      : ${jumlahFoto}`);
    console.log('  bookings        : 1 (GR20230426)');
    console.log(`  notifications   : ${dataRental.notifications.length}`);
  } catch (err) {
    // Batalkan semua insert kalau ada yang gagal, lalu tampilkan pesannya
    await conn.rollback().catch(() => {});
    console.error('Seeder gagal:', err.message);
    process.exitCode = 1;
  } finally {
    conn.release();
    await pool.end();
  }
}

// Tangkap error koneksi (misalnya MySQL XAMPP belum di-start)
seed().catch(async (err) => {
  console.error('Tidak bisa terhubung ke MySQL:', err.code || '', err.message);
  console.error('Pastikan MySQL di XAMPP sudah Start dan isi .env sudah benar.');
  await pool.end().catch(() => {});
  process.exitCode = 1;
});
