// Controller favorit: POST /favorites dan DELETE /favorites/:car_id?user_id=1
import pool from '../config/db.js';
import { toPositiveInt, sendValidationError } from '../utils/validation.js';

// POST /favorites  body: { user_id, car_id }
export async function addFavorite(req, res) {
  const userId = toPositiveInt(req.body?.user_id);
  const carId = toPositiveInt(req.body?.car_id);
  const errors = {};
  if (!userId) errors.user_id = 'user_id wajib diisi';
  if (!carId) errors.car_id = 'car_id wajib diisi';
  if (Object.keys(errors).length) return sendValidationError(res, errors);

  const [[user]] = await pool.query('SELECT id FROM users WHERE id = ?', [userId]);
  const [[car]] = await pool.query('SELECT id FROM cars WHERE id = ?', [carId]);
  if (!user) return res.status(404).json({ message: 'User tidak ditemukan' });
  if (!car) return res.status(404).json({ message: 'Mobil tidak ditemukan' });

  // INSERT IGNORE: kalau sudah favorit (unique user_id + car_id), tidak dianggap error
  await pool.query('INSERT IGNORE INTO favorites (user_id, car_id) VALUES (?, ?)', [userId, carId]);
  res.status(201).json({ user_id: userId, car_id: carId, is_favorite: true });
}

// DELETE /favorites/:car_id?user_id=1
export async function removeFavorite(req, res) {
  const carId = toPositiveInt(req.params.car_id);
  const userId = toPositiveInt(req.query.user_id);
  const errors = {};
  if (!carId) errors.car_id = 'car_id tidak valid';
  if (!userId) errors.user_id = 'user_id wajib diisi';
  if (Object.keys(errors).length) return sendValidationError(res, errors);

  const [hasil] = await pool.query('DELETE FROM favorites WHERE user_id = ? AND car_id = ?', [userId, carId]);
  if (hasil.affectedRows === 0) return res.status(404).json({ message: 'Mobil ini tidak ada di favorit' });
  res.json({ user_id: userId, car_id: carId, is_favorite: false });
}
