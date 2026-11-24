import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:go_rent_app/config/constants.dart';
import 'package:go_rent_app/providers/rental_provider.dart';
import 'package:go_rent_app/screens/main_screen.dart';

import 'fake_api.dart';

void main() {
  testWidgets('MainScreen: 4 tab, badge notifikasi, dan pindah tab', (
    tester,
  ) async {
    final rental = RentalProvider(apiService: buatFakeApi());

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: rental,
        child: MaterialApp(theme: buildAppTheme(), home: const MainScreen()),
      ),
    );
    // Muat data di luar fase build, lalu tunggu UI diperbarui
    await tester.runAsync(rental.loadInitialData);
    await tester.pump();

    expect(find.byType(BottomNavigationBar), findsOneWidget);
    expect(find.text('Home'), findsWidgets);
    expect(find.text('2'), findsOneWidget); // badge 2 notifikasi belum dibaca

    rental.changeTab(1);
    await tester.pump();
    expect(find.text('#GR2026120101'), findsOneWidget); // My Bookings terisi

    await tester.tap(find.byIcon(Icons.person_outline));
    await tester.pump();
    expect(rental.currentTab, 3);
    expect(find.text('Account Settings'), findsOneWidget);
  });
}
