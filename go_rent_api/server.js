// Entry point REST API GO-RENT (Express 5)
import express from 'express';
import cors from 'cors';
import 'dotenv/config';

import carRoutes from './routes/cars.js';
import userRoutes from './routes/users.js';
import paymentMethodRoutes from './routes/paymentMethods.js';
import bookingRoutes from './routes/bookings.js';
import notificationRoutes from './routes/notifications.js';
import favoriteRoutes from './routes/favorites.js';

const app = express();
const PORT = Number(process.env.PORT || 8080);

// Middleware: izinkan akses dari Flutter web (CORS), baca body JSON, sajikan folder public
app.use(cors());
app.use(express.json());
app.use(express.static('public'));

// Cek cepat bahwa server hidup
app.get('/', (req, res) => {
  res.json({ message: 'GO-RENT API berjalan' });
});

// Daftar resource sesuai tabel Endpoint di SPEC.md
app.use('/cars', carRoutes);
app.use('/users', userRoutes);
app.use('/payment-methods', paymentMethodRoutes);
app.use('/bookings', bookingRoutes);
app.use('/notifications', notificationRoutes);
app.use('/favorites', favoriteRoutes);

// Path yang tidak terdaftar
app.use((req, res) => {
  res.status(404).json({ message: `Endpoint ${req.method} ${req.path} tidak ditemukan` });
});

// Error handler terpusat. Express 5 otomatis meneruskan error dari fungsi async ke sini.
app.use((err, req, res, next) => {
  // Body JSON rusak dari client
  if (err.type === 'entity.parse.failed') {
    return res.status(400).json({ message: 'Body request bukan JSON yang valid' });
  }
  // MySQL mati atau tidak bisa dihubungi
  if (err.code === 'ECONNREFUSED' || err.code === 'ER_BAD_DB_ERROR' || err.code === 'ER_ACCESS_DENIED_ERROR') {
    console.error('Database error:', err.code, err.message);
    return res.status(503).json({ message: 'Database tidak bisa diakses. Pastikan MySQL XAMPP sudah berjalan.' });
  }
  console.error(err);
  res.status(500).json({ message: 'Terjadi kesalahan pada server' });
});

app.listen(PORT, () => {
  console.log(`GO-RENT API berjalan di http://localhost:${PORT}`);
});
