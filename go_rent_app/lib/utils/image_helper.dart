import 'package:flutter/material.dart';

// Pilih sumber gambar avatar: URL online -> NetworkImage, selain itu -> asset lokal
// (contoh avatar_url dari database: "assets/images/avatar.png")
ImageProvider avatarImageProvider(String url) {
  if (url.startsWith('http')) return NetworkImage(url);
  return AssetImage(url);
}
