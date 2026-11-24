// Koneksi MySQL memakai pool dari mysql2/promise supaya bisa dipakai dengan async/await
import mysql from 'mysql2/promise';
import 'dotenv/config';

const pool = mysql.createPool({
  host: process.env.DB_HOST || 'localhost',
  port: Number(process.env.DB_PORT || 3306),
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASS || '',
  database: process.env.DB_NAME || 'go_rent',
  waitForConnections: true,
  connectionLimit: 10,
  // DECIMAL (rating, latitude) dikembalikan sebagai number, bukan string "4.9"
  decimalNumbers: true,
  // DATE/DATETIME dikembalikan sebagai string apa adanya supaya tidak bergeser karena timezone
  dateStrings: true,
});

export default pool;
