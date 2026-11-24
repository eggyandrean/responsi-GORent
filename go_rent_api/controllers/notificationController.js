// Controller notifikasi: GET /notifications, PUT /notifications/:id, DELETE /notifications/:id
import pool from '../config/db.js';
import { toPositiveInt, sendValidationError } from '../utils/validation.js';

const formatNotif = (row) => ({ ...row, is_read: row.is_read === 1 });

async function cariNotif(id) {
  const [rows] = await pool.query('SELECT * FROM notifications WHERE id = ?', [id]);
  return rows.length ? formatNotif(rows[0]) : null;
}

// GET /notifications?user_id=1  (terbaru dulu)
export async function getNotifications(req, res) {
  const userId = toPositiveInt(req.query.user_id);
  if (!userId) return sendValidationError(res, { user_id: 'user_id wajib diisi dan berupa angka' });

  const [rows] = await pool.query(
    'SELECT * FROM notifications WHERE user_id = ? ORDER BY created_at DESC, id DESC',
    [userId],
  );
  res.json(rows.map(formatNotif));
}

// PUT /notifications/:id  body: { is_read: true }
export async function updateNotification(req, res) {
  const id = toPositiveInt(req.params.id);
  if (!id || !(await cariNotif(id))) return res.status(404).json({ message: 'Notifikasi tidak ditemukan' });
  if (typeof req.body?.is_read !== 'boolean') {
    return sendValidationError(res, { is_read: 'is_read wajib true atau false' });
  }

  await pool.query('UPDATE notifications SET is_read = ? WHERE id = ?', [req.body.is_read ? 1 : 0, id]);
  res.json(await cariNotif(id));
}

// DELETE /notifications/:id
export async function deleteNotification(req, res) {
  const id = toPositiveInt(req.params.id);
  if (!id) return res.status(404).json({ message: 'Notifikasi tidak ditemukan' });

  const [hasil] = await pool.query('DELETE FROM notifications WHERE id = ?', [id]);
  if (hasil.affectedRows === 0) return res.status(404).json({ message: 'Notifikasi tidak ditemukan' });
  res.json({ message: 'Notifikasi dihapus', id });
}
