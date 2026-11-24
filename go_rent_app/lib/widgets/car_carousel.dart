import 'dart:async';

import 'package:flutter/material.dart';

import '../config/constants.dart';
import '../models/car.dart';
import 'car_image.dart';

// Carousel foto Vehicle Detail: PageView + titik indikator + geser otomatis tiap 3,5 detik.
// Selalu 3 slide. Slide tanpa foto asli diisi gambar simulasi berlabel sudut pandang.
class CarCarousel extends StatefulWidget {
  final Car car;
  final double height;

  const CarCarousel({super.key, required this.car, this.height = 260});

  static const List<String> labelSlide = [
    'Tampak depan',
    'Tampak samping',
    'Interior',
  ];

  @override
  State<CarCarousel> createState() => _CarCarouselState();
}

class _CarCarouselState extends State<CarCarousel> {
  final PageController _pageController = PageController();
  Timer? _timer;
  int _halamanAktif = 0;

  @override
  void initState() {
    super.initState();
    // Geser otomatis seperti contoh carousel di materi P11
    _timer = Timer.periodic(
      const Duration(milliseconds: 3500),
      (_) => _geserBerikutnya(),
    );
  }

  void _geserBerikutnya() {
    if (!mounted || !_pageController.hasClients) return;
    final berikutnya = (_halamanAktif + 1) % CarCarousel.labelSlide.length;
    _pageController.animateToPage(
      berikutnya,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    // Wajib: hentikan timer dan lepas controller supaya tidak ada setState setelah dispose
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.car.images;

    return SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: CarCarousel.labelSlide.length,
            onPageChanged: (index) => setState(() => _halamanAktif = index),
            itemBuilder: (context, index) => CarImage(
              // Slide ke-i memakai foto ke-i jika ada; sisanya simulasi
              url: index < images.length ? images[index] : null,
              car: widget.car,
              height: widget.height,
              borderRadius: BorderRadius.zero,
              label: CarCarousel.labelSlide[index],
            ),
          ),
          // Titik indikator di bawah tengah
          Positioned(
            left: 0,
            right: 0,
            bottom: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < CarCarousel.labelSlide.length; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: i == _halamanAktif ? 18 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == _halamanAktif
                          ? AppColors.navy
                          : Colors.white70,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
