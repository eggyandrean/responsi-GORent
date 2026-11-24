import 'package:flutter/material.dart';

import '../config/constants.dart';
import '../utils/image_helper.dart';

// Avatar bulat dari avatar_url. Jika kosong atau gambar gagal dimuat
// (misalnya file asset belum ada), tampilkan inisial nama.
class UserAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String initials;
  final double radius;

  const UserAvatar({
    super.key,
    required this.avatarUrl,
    required this.initials,
    this.radius = 40,
  });

  @override
  Widget build(BuildContext context) {
    final inisial = Container(
      color: Colors.white,
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontSize: radius * 0.7,
          fontWeight: FontWeight.bold,
          color: AppColors.navy,
        ),
      ),
    );

    return SizedBox(
      width: radius * 2,
      height: radius * 2,
      child: ClipOval(
        child: (avatarUrl == null || avatarUrl!.isEmpty)
            ? inisial
            : Image(
                image: avatarImageProvider(avatarUrl!),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => inisial,
              ),
      ),
    );
  }
}
