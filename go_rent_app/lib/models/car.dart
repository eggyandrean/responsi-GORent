import 'provider_info.dart';

// Data mobil dari GET /cars dan GET /cars/{id}
class Car {
  final int id;
  final String name;
  final String type; // contoh: SUV, MPV, Electric
  final String rentalType; // 'Lepas Kunci' atau 'Dengan Sopir'
  final int seats;
  final String transmission;
  final double rating;
  final int pricePerDay;
  final bool isFavorite;
  final ProviderInfo provider;
  final List<String> images; // 0 sampai 3 URL; kosong = tampil gambar simulasi
  final List<String> vehicleSpecs;

  const Car({
    required this.id,
    required this.name,
    required this.type,
    required this.rentalType,
    required this.seats,
    required this.transmission,
    required this.rating,
    required this.pricePerDay,
    required this.isFavorite,
    required this.provider,
    required this.images,
    required this.vehicleSpecs,
  });

  // Pemetaan field backend (snake_case) ke field Dart (camelCase)
  factory Car.fromJson(Map<String, dynamic> json) {
    return Car(
      id: json['id'] as int,
      name: json['name'] as String,
      type: json['type'] as String,
      rentalType: json['rental_type'] as String,
      seats: json['seats'] as int,
      transmission: json['transmission'] as String,
      rating: num.parse(json['rating'].toString()).toDouble(),
      pricePerDay: num.parse(json['price_per_day'].toString()).toInt(),
      isFavorite: json['is_favorite'] == true,
      provider: ProviderInfo.fromJson(json['provider'] as Map<String, dynamic>),
      images: List<String>.from(json['images'] ?? const []),
      vehicleSpecs: List<String>.from(json['vehicle_specs'] ?? const []),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'type': type,
    'rental_type': rentalType,
    'seats': seats,
    'transmission': transmission,
    'rating': rating,
    'price_per_day': pricePerDay,
    'is_favorite': isFavorite,
    'provider': provider.toJson(),
    'images': images,
    'vehicle_specs': vehicleSpecs,
  };

  // Salinan mobil dengan status favorit baru (dipakai saat toggle favorit)
  Car copyWith({bool? isFavorite}) {
    return Car(
      id: id,
      name: name,
      type: type,
      rentalType: rentalType,
      seats: seats,
      transmission: transmission,
      rating: rating,
      pricePerDay: pricePerDay,
      isFavorite: isFavorite ?? this.isFavorite,
      provider: provider,
      images: images,
      vehicleSpecs: vehicleSpecs,
    );
  }

  bool get isDenganSopir => rentalType == 'Dengan Sopir';
}
