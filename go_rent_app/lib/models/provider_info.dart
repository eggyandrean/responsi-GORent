// Data penyedia rental beserta titik pickup untuk peta (tabel providers)
class ProviderInfo {
  final int id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;

  const ProviderInfo({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  factory ProviderInfo.fromJson(Map<String, dynamic> json) {
    return ProviderInfo(
      id: json['id'] as int,
      name: json['name'] as String,
      // address boleh tidak dikirim, misalnya pada contoh JSON di SPEC
      address: (json['address'] ?? '') as String,
      // Koordinat diparse lewat toString supaya aman jika backend mengirim "-7.42" (string)
      latitude: double.parse(json['latitude'].toString()),
      longitude: double.parse(json['longitude'].toString()),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'address': address,
    'latitude': latitude,
    'longitude': longitude,
  };
}
