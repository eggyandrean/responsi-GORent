import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/constants.dart';
import 'providers/rental_provider.dart';
import 'screens/main_screen.dart';

void main() {
  runApp(
    // Satu RentalProvider untuk seluruh aplikasi; data awal langsung dimuat dari API
    ChangeNotifierProvider(
      create: (_) => RentalProvider()..loadInitialData(),
      child: const GoRentApp(),
    ),
  );
}

class GoRentApp extends StatelessWidget {
  const GoRentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GO-RENT',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const MainScreen(),
    );
  }
}
