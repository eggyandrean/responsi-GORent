-- =========================================================
-- Skema database GO-RENT (MySQL / MariaDB bawaan XAMPP)
-- Import file ini di phpMyAdmin (tab Import) atau lewat:
--   mysql -u root < database/schema.sql
-- Urutan tabel mengikuti foreign key: master dulu, lalu child.
-- =========================================================

CREATE DATABASE IF NOT EXISTS go_rent
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE go_rent;

-- Hapus tabel lama dari child ke master supaya foreign key tidak menghalangi
DROP TABLE IF EXISTS favorites;
DROP TABLE IF EXISTS notifications;
DROP TABLE IF EXISTS bookings;
DROP TABLE IF EXISTS car_specs;
DROP TABLE IF EXISTS car_images;
DROP TABLE IF EXISTS cars;
DROP TABLE IF EXISTS payment_methods;
DROP TABLE IF EXISTS users;
DROP TABLE IF EXISTS providers;

-- 1. Master: penyedia rental beserta titik pickup di peta
CREATE TABLE providers (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE,
  address VARCHAR(255) NOT NULL,
  latitude DECIMAL(10,7) NOT NULL,
  longitude DECIMAL(10,7) NOT NULL
) ENGINE=InnoDB;

-- 2. Master: user aplikasi (versi ini selalu memakai id = 1)
CREATE TABLE users (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  email VARCHAR(100) NOT NULL UNIQUE,
  phone VARCHAR(20) NOT NULL,
  is_verified TINYINT(1) NOT NULL DEFAULT 0,
  driving_license VARCHAR(100) NULL,
  avatar_url VARCHAR(255) NULL
) ENGINE=InnoDB;

-- 3. Master: metode pembayaran (OVO, GoPay, Bank Transfer)
CREATE TABLE payment_methods (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(50) NOT NULL UNIQUE
) ENGINE=InnoDB;

-- 4. Inti: data mobil, setiap mobil milik satu provider
CREATE TABLE cars (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  provider_id INT UNSIGNED NOT NULL,
  name VARCHAR(100) NOT NULL,
  type VARCHAR(50) NOT NULL,
  rental_type ENUM('Lepas Kunci','Dengan Sopir') NOT NULL,
  seats TINYINT UNSIGNED NOT NULL,
  transmission VARCHAR(20) NOT NULL,
  rating DECIMAL(2,1) NOT NULL DEFAULT 0.0,
  price_per_day INT UNSIGNED NOT NULL,
  CONSTRAINT fk_cars_provider FOREIGN KEY (provider_id)
    REFERENCES providers(id) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- 5. Child: foto mobil (0 sampai 3 per mobil), ikut terhapus jika mobil dihapus
CREATE TABLE car_images (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  car_id INT UNSIGNED NOT NULL,
  image_url VARCHAR(500) NOT NULL,
  sort_order TINYINT UNSIGNED NOT NULL DEFAULT 1,
  CONSTRAINT fk_car_images_car FOREIGN KEY (car_id)
    REFERENCES cars(id) ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

-- 6. Child: fitur/spesifikasi mobil (Airbag, Bluetooth, dst.)
CREATE TABLE car_specs (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  car_id INT UNSIGNED NOT NULL,
  spec_name VARCHAR(100) NOT NULL,
  CONSTRAINT fk_car_specs_car FOREIGN KEY (car_id)
    REFERENCES cars(id) ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;

-- 7. Child: transaksi booking. Harga disalin saat booking dibuat
--    supaya riwayat tidak berubah walau harga mobil diubah nanti.
CREATE TABLE bookings (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  booking_code VARCHAR(20) NOT NULL UNIQUE,
  user_id INT UNSIGNED NOT NULL,
  car_id INT UNSIGNED NOT NULL,
  payment_method_id INT UNSIGNED NOT NULL,
  renter_name VARCHAR(100) NOT NULL,
  pickup_location VARCHAR(100) NOT NULL,
  dropoff_location VARCHAR(100) NOT NULL,
  pickup_date DATE NOT NULL,
  dropoff_date DATE NOT NULL,
  days INT UNSIGNED NOT NULL,
  price_per_day INT UNSIGNED NOT NULL,
  insurance_fee INT UNSIGNED NOT NULL DEFAULT 0,
  total_price INT UNSIGNED NOT NULL,
  sim_uploaded TINYINT(1) NOT NULL DEFAULT 0,
  status ENUM('Confirmed','Completed','Cancelled') NOT NULL DEFAULT 'Confirmed',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_bookings_user FOREIGN KEY (user_id)
    REFERENCES users(id) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_bookings_car FOREIGN KEY (car_id)
    REFERENCES cars(id) ON UPDATE CASCADE ON DELETE RESTRICT,
  CONSTRAINT fk_bookings_payment FOREIGN KEY (payment_method_id)
    REFERENCES payment_methods(id) ON UPDATE CASCADE ON DELETE RESTRICT
) ENGINE=InnoDB;

-- 8. Child: notifikasi user. booking_id boleh kosong (misalnya notifikasi promo)
CREATE TABLE notifications (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id INT UNSIGNED NOT NULL,
  booking_id INT UNSIGNED NULL,
  title VARCHAR(100) NOT NULL,
  description VARCHAR(255) NOT NULL,
  type ENUM('order','promo','reminder') NOT NULL,
  is_read TINYINT(1) NOT NULL DEFAULT 0,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_notifications_user FOREIGN KEY (user_id)
    REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_notifications_booking FOREIGN KEY (booking_id)
    REFERENCES bookings(id) ON UPDATE CASCADE ON DELETE SET NULL
) ENGINE=InnoDB;

-- 9. Child: mobil favorit user, satu mobil hanya sekali per user
CREATE TABLE favorites (
  id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id INT UNSIGNED NOT NULL,
  car_id INT UNSIGNED NOT NULL,
  UNIQUE KEY uq_favorites_user_car (user_id, car_id),
  CONSTRAINT fk_favorites_user FOREIGN KEY (user_id)
    REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT fk_favorites_car FOREIGN KEY (car_id)
    REFERENCES cars(id) ON UPDATE CASCADE ON DELETE CASCADE
) ENGINE=InnoDB;
