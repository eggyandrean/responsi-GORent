// Data booking dari GET /bookings dan respons POST /bookings
class Booking {
  final int id;
  final String bookingCode;
  final int userId;
  final int carId;
  final int paymentMethodId;
  final String renterName;
  final String pickupLocation;
  final String dropoffLocation;
  final DateTime pickupDate;
  final DateTime dropoffDate;
  final int days;
  final int pricePerDay;
  final int insuranceFee;
  final int totalPrice;
  final bool simUploaded;
  final String status; // Confirmed, Completed, Cancelled
  final DateTime createdAt;
  // Field tambahan hasil JOIN di backend
  final String carName;
  final String paymentMethod;
  final String? carImage; // null jika mobil belum punya foto

  const Booking({
    required this.id,
    required this.bookingCode,
    required this.userId,
    required this.carId,
    required this.paymentMethodId,
    required this.renterName,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.pickupDate,
    required this.dropoffDate,
    required this.days,
    required this.pricePerDay,
    required this.insuranceFee,
    required this.totalPrice,
    required this.simUploaded,
    required this.status,
    required this.createdAt,
    required this.carName,
    required this.paymentMethod,
    this.carImage,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] as int,
      bookingCode: json['booking_code'] as String,
      userId: json['user_id'] as int,
      carId: json['car_id'] as int,
      paymentMethodId: json['payment_method_id'] as int,
      renterName: json['renter_name'] as String,
      pickupLocation: json['pickup_location'] as String,
      dropoffLocation: json['dropoff_location'] as String,
      // Tanggal dikirim backend sebagai "YYYY-MM-DD"
      pickupDate: DateTime.parse(json['pickup_date'] as String),
      dropoffDate: DateTime.parse(json['dropoff_date'] as String),
      days: json['days'] as int,
      pricePerDay: json['price_per_day'] as int,
      insuranceFee: json['insurance_fee'] as int,
      totalPrice: json['total_price'] as int,
      // tinyint MySQL bisa terkirim sebagai true/false atau 1/0
      simUploaded: json['sim_uploaded'] == true || json['sim_uploaded'] == 1,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      carName: (json['car_name'] ?? '') as String,
      paymentMethod: (json['payment_method'] ?? '') as String,
      carImage: json['car_image'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'booking_code': bookingCode,
    'user_id': userId,
    'car_id': carId,
    'payment_method_id': paymentMethodId,
    'renter_name': renterName,
    'pickup_location': pickupLocation,
    'dropoff_location': dropoffLocation,
    'pickup_date': _tanggalApi(pickupDate),
    'dropoff_date': _tanggalApi(dropoffDate),
    'days': days,
    'price_per_day': pricePerDay,
    'insurance_fee': insuranceFee,
    'total_price': totalPrice,
    'sim_uploaded': simUploaded,
    'status': status,
    'created_at': createdAt.toIso8601String(),
    'car_name': carName,
    'payment_method': paymentMethod,
    'car_image': carImage,
  };

  bool get isConfirmed => status == 'Confirmed';
  bool get hasInsurance => insuranceFee > 0;

  static String _tanggalApi(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
