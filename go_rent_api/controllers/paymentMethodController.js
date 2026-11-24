// Controller metode pembayaran: GET /payment-methods
import pool from '../config/db.js';

export async function getPaymentMethods(req, res) {
  const [rows] = await pool.query('SELECT id, name FROM payment_methods ORDER BY id');
  res.json(rows);
}
