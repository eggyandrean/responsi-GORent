import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../config/constants.dart';
import '../models/provider_info.dart';

// Peta titik pickup (OpenStreetMap). Bisa digeser dan di-zoom.
// Tinggi tetap supaya peta tidak berebut gesture scroll dengan ListView di sekitarnya.
class PickupMap extends StatelessWidget {
  final ProviderInfo provider;
  final double height;

  const PickupMap({super.key, required this.provider, this.height = 170});

  @override
  Widget build(BuildContext context) {
    final titik = LatLng(provider.latitude, provider.longitude);

    return ClipRRect(
      borderRadius: BorderRadius.circular(cardRadius),
      child: SizedBox(
        height: height,
        child: FlutterMap(
          options: MapOptions(initialCenter: titik, initialZoom: 15),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              // Wajib diisi, kalau tidak tile OSM bisa diblokir
              userAgentPackageName: userAgentPackageName,
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: titik,
                  width: 40,
                  height: 40,
                  alignment: Alignment.topCenter, // ujung pin tepat di titik
                  child: const Icon(
                    Icons.location_pin,
                    color: AppColors.error,
                    size: 40,
                  ),
                ),
              ],
            ),
            // Atribusi wajib untuk data OpenStreetMap (dibuat sendiri dan diperkecil
            // dengan FittedBox supaya tidak overflow di peta yang sempit)
            Align(
              alignment: Alignment.bottomRight,
              child: Container(
                color: Colors.white70,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: const FittedBox(
                  child: Text(
                    '© OpenStreetMap contributors',
                    style: TextStyle(fontSize: 10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
