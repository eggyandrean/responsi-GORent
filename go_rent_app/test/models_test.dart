import 'package:flutter_test/flutter_test.dart';
import 'package:go_rent_app/models/booking.dart';
import 'package:go_rent_app/models/car.dart';
import 'package:go_rent_app/models/notification_item.dart';
import 'package:go_rent_app/models/user_profile.dart';

// Contoh JSON diambil dari respons asli API lokal (GET /cars/2, /bookings, /notifications, /users/1)
void main() {
  test('Car.fromJson memetakan respons GET /cars/2', () {
    final car = Car.fromJson({
      'id': 2,
      'name': 'Hyundai Creta Prime',
      'type': 'SUV',
      'rental_type': 'Lepas Kunci',
      'seats': 5,
      'transmission': 'Automatic',
      'rating': 4.9,
      'price_per_day': 450000,
      'is_favorite': false,
      'provider': {
        'id': 1,
        'name': 'Astra Rental',
        'address': 'Kantor Astra Rental, Purwokerto, Banyumas',
        'latitude': -7.4245,
        'longitude': 109.237,
      },
      'images': [
        'https://commons.wikimedia.org/wiki/Special:FilePath/creta.jpg?width=960',
      ],
      'vehicle_specs': ['Panoramic Sunroof', 'Bose Speaker', 'Airbag'],
    });

    expect(car.name, 'Hyundai Creta Prime');
    expect(car.rentalType, 'Lepas Kunci');
    expect(car.rating, 4.9);
    expect(car.pricePerDay, 450000);
    expect(car.provider.latitude, -7.4245);
    expect(car.images, hasLength(1));
    expect(car.vehicleSpecs.first, 'Panoramic Sunroof');
    expect(car.copyWith(isFavorite: true).isFavorite, isTrue);
    expect(Car.fromJson(car.toJson()).toJson(), car.toJson());
  });

  test('Car.fromJson tetap aman jika rating/koordinat berupa string dan images kosong', () {
    final car = Car.fromJson({
      'id': 3,
      'name': 'Honda Brio RS',
      'type': 'City Car',
      'rental_type': 'Lepas Kunci',
      'seats': 5,
      'transmission': 'Manual',
      'rating': '4.7',
      'price_per_day': 250000,
      'is_favorite': true,
      'provider': {
        'id': 2,
        'name': 'Local Rent',
        'latitude': '-7.42',
        'longitude': '109.23',
      },
      'images': [],
      'vehicle_specs': [],
    });

    expect(car.rating, 4.7);
    expect(car.provider.longitude, 109.23);
    expect(car.provider.address, '');
    expect(car.images, isEmpty);
  });

  test('Booking.fromJson memetakan respons POST /bookings', () {
    final booking = Booking.fromJson({
      'id': 3,
      'booking_code': 'GR2026120102',
      'user_id': 1,
      'car_id': 2,
      'payment_method_id': 1,
      'renter_name': 'Eggy Andrean',
      'pickup_location': 'Purwokerto',
      'dropoff_location': 'Purwokerto',
      'pickup_date': '2026-12-01',
      'dropoff_date': '2026-12-03',
      'days': 2,
      'price_per_day': 450000,
      'insurance_fee': 80000,
      'total_price': 980000,
      'sim_uploaded': true,
      'status': 'Confirmed',
      'created_at': '2026-11-24 15:45:57',
      'updated_at': '2026-11-24 15:45:57',
      'car_name': 'Hyundai Creta Prime',
      'payment_method': 'OVO',
      'car_image': null,
    });

    expect(booking.pickupDate, DateTime(2026, 12, 1));
    expect(booking.totalPrice, 980000);
    expect(booking.hasInsurance, isTrue);
    expect(booking.isConfirmed, isTrue);
    expect(booking.carImage, isNull);
    expect(booking.toJson()['pickup_date'], '2026-12-01');
  });

  test(
    'NotificationItem dan UserProfile menerima tinyint 0/1 maupun boolean',
    () {
      final notif = NotificationItem.fromJson({
        'id': 1,
        'user_id': 1,
        'booking_id': null,
        'title': 'Special Offer',
        'description': 'Unlock 15% off your next SUV rental!',
        'type': 'promo',
        'is_read': 1,
        'created_at': '2026-11-23 15:45:23',
      });
      expect(notif.isRead, isTrue);
      expect(notif.bookingId, isNull);
      expect(notif.copyWith(isRead: false).isRead, isFalse);

      final user = UserProfile.fromJson({
        'id': 1,
        'name': 'Eggy Andrean',
        'email': 'eggy.andrean@example.com',
        'phone': '0812-XXXX-5554',
        'is_verified': true,
        'driving_license': 'SIM A - Uploaded & Verified',
        'avatar_url': 'assets/images/avatar.png',
      });
      expect(user.isVerified, isTrue);
      expect(user.initials, 'EA');
    },
  );
}
