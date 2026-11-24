// Data profil user dari GET /users/1
class UserProfile {
  final int id;
  final String name;
  final String email;
  final String phone; // disimpan sebagai teks, bukan angka
  final bool isVerified;
  final String? drivingLicense;
  final String?
  avatarUrl; // URL online atau path asset, misalnya assets/images/avatar.png

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.isVerified,
    this.drivingLicense,
    this.avatarUrl,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      isVerified: json['is_verified'] == true || json['is_verified'] == 1,
      drivingLicense: json['driving_license'] as String?,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'phone': phone,
    'is_verified': isVerified,
    'driving_license': drivingLicense,
    'avatar_url': avatarUrl,
  };

  // Inisial nama untuk avatar cadangan, contoh "Eggy Andrean" -> "EA"
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }
}
