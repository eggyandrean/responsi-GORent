// Controller mobil: GET /cars dan GET /cars/:id
import pool from '../config/db.js';
import { toImageUrl } from '../utils/imageUrl.js';
import { toPositiveInt } from '../utils/validation.js';

// Pilihan sort yang diizinkan, dipetakan ke ORDER BY yang aman (bukan dari input mentah)
const SORT_SQL = {
  rating: 'c.rating DESC, c.price_per_day ASC',
  price_asc: 'c.price_per_day ASC',
  price_desc: 'c.price_per_day DESC',
};

const BASE_SELECT = `
  SELECT c.id, c.name, c.type, c.rental_type, c.seats, c.transmission, c.rating, c.price_per_day,
         p.id AS provider_id, p.name AS provider_name, p.address AS provider_address,
         p.latitude AS provider_latitude, p.longitude AS provider_longitude
  FROM cars c
  JOIN providers p ON p.id = c.provider_id`;

// Lengkapi baris mobil dengan provider, images, vehicle_specs, dan is_favorite
// sesuai "Bentuk JSON mobil" di SPEC.md
async function lengkapiMobil(req, rows, userId) {
  if (rows.length === 0) return [];
  const ids = rows.map((row) => row.id);

  const [images] = await pool.query(
    'SELECT car_id, image_url FROM car_images WHERE car_id IN (?) ORDER BY car_id, sort_order',
    [ids],
  );
  const [specs] = await pool.query(
    'SELECT car_id, spec_name FROM car_specs WHERE car_id IN (?) ORDER BY id',
    [ids],
  );
  const [favorites] = await pool.query(
    'SELECT car_id FROM favorites WHERE user_id = ? AND car_id IN (?)',
    [userId, ids],
  );
  const favoriteIds = new Set(favorites.map((fav) => fav.car_id));

  return rows.map((row) => ({
    id: row.id,
    name: row.name,
    type: row.type,
    rental_type: row.rental_type,
    seats: row.seats,
    transmission: row.transmission,
    rating: row.rating,
    price_per_day: row.price_per_day,
    is_favorite: favoriteIds.has(row.id),
    provider: {
      id: row.provider_id,
      name: row.provider_name,
      address: row.provider_address,
      latitude: row.provider_latitude,
      longitude: row.provider_longitude,
    },
    images: images.filter((img) => img.car_id === row.id).map((img) => toImageUrl(req, img.image_url)),
    vehicle_specs: specs.filter((spec) => spec.car_id === row.id).map((spec) => spec.spec_name),
  }));
}

// GET /cars?rental_type=&type=&transmission=&min_price=&max_price=&sort=&user_id=
export async function getCars(req, res) {
  const { rental_type, type, transmission, min_price, max_price, sort } = req.query;
  const userId = toPositiveInt(req.query.user_id) ?? 1;

  // Susun WHERE secara dinamis, nilai tetap lewat placeholder ?
  const kondisi = [];
  const params = [];
  if (rental_type) {
    kondisi.push('c.rental_type = ?');
    params.push(rental_type);
  }
  if (type) {
    // "SUV" juga mencocokkan "Compact SUV", "Premium SUV", dst.
    kondisi.push('c.type LIKE ?');
    params.push(`%${type}%`);
  }
  if (transmission) {
    kondisi.push('c.transmission = ?');
    params.push(transmission);
  }
  if (min_price !== undefined && min_price !== '') {
    if (Number.isNaN(Number(min_price))) {
      return res.status(400).json({ message: 'Validasi gagal', errors: { min_price: 'min_price harus angka' } });
    }
    kondisi.push('c.price_per_day >= ?');
    params.push(Number(min_price));
  }
  if (max_price !== undefined && max_price !== '') {
    if (Number.isNaN(Number(max_price))) {
      return res.status(400).json({ message: 'Validasi gagal', errors: { max_price: 'max_price harus angka' } });
    }
    kondisi.push('c.price_per_day <= ?');
    params.push(Number(max_price));
  }
  if (sort && !SORT_SQL[sort] && sort !== 'default') {
    return res.status(400).json({
      message: 'Validasi gagal',
      errors: { sort: 'sort harus rating, price_asc, atau price_desc' },
    });
  }

  const where = kondisi.length ? `WHERE ${kondisi.join(' AND ')}` : '';
  const orderBy = SORT_SQL[sort] || 'c.id ASC';
  const [rows] = await pool.query(`${BASE_SELECT} ${where} ORDER BY ${orderBy}`, params);

  res.json(await lengkapiMobil(req, rows, userId));
}

// GET /cars/:id
export async function getCarById(req, res) {
  const id = toPositiveInt(req.params.id);
  if (!id) return res.status(404).json({ message: 'Mobil tidak ditemukan' });
  const userId = toPositiveInt(req.query.user_id) ?? 1;

  const [rows] = await pool.query(`${BASE_SELECT} WHERE c.id = ?`, [id]);
  if (rows.length === 0) return res.status(404).json({ message: 'Mobil tidak ditemukan' });

  const [car] = await lengkapiMobil(req, rows, userId);
  res.json(car);
}
