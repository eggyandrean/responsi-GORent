// Controller user: GET /users/:id dan PUT /users/:id (Account Settings)
import pool from '../config/db.js';
import { toPositiveInt, sendValidationError } from '../utils/validation.js';

// Ambil satu user, tinyint is_verified diubah menjadi boolean
async function cariUser(id) {
  const [rows] = await pool.query(
    'SELECT id, name, email, phone, is_verified, driving_license, avatar_url FROM users WHERE id = ?',
    [id],
  );
  if (rows.length === 0) return null;
  return { ...rows[0], is_verified: rows[0].is_verified === 1 };
}

// GET /users/:id
export async function getUser(req, res) {
  const id = toPositiveInt(req.params.id);
  const user = id ? await cariUser(id) : null;
  if (!user) return res.status(404).json({ message: 'User tidak ditemukan' });
  res.json(user);
}

// PUT /users/:id  body: { name, phone }
export async function updateUser(req, res) {
  const id = toPositiveInt(req.params.id);
  if (!id || !(await cariUser(id))) return res.status(404).json({ message: 'User tidak ditemukan' });

  const name = typeof req.body?.name === 'string' ? req.body.name.trim() : '';
  const phone = typeof req.body?.phone === 'string' ? req.body.phone.trim() : '';

  const errors = {};
  if (name.length < 3) errors.name = 'Nama minimal 3 huruf';
  if (name.length > 100) errors.name = 'Nama maksimal 100 karakter';
  // Nomor HP disimpan sebagai teks: angka, spasi, +, -, dan X (untuk nomor tersamar)
  if (!phone) errors.phone = 'Nomor HP wajib diisi';
  else if (!/^[0-9+\-\sXx]{8,20}$/.test(phone)) errors.phone = 'Nomor HP harus 8-20 karakter angka';
  if (Object.keys(errors).length) return sendValidationError(res, errors);

  await pool.query('UPDATE users SET name = ?, phone = ? WHERE id = ?', [name, phone, id]);
  res.json(await cariUser(id));
}
