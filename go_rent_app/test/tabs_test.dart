import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:go_rent_app/config/constants.dart';
import 'package:go_rent_app/providers/rental_provider.dart';
import 'package:go_rent_app/screens/my_bookings_screen.dart';
import 'package:go_rent_app/screens/notification_screen.dart';
import 'package:go_rent_app/screens/profile_screen.dart';
import 'package:go_rent_app/widgets/notification_card.dart';

import 'fake_api.dart';

void main() {
  late RentalProvider rental;

  Future<void> pasang(
    WidgetTester tester,
    Widget layar, {
    bool serverMati = false,
  }) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    rental = RentalProvider(apiService: buatFakeApi(serverMati: serverMati));
    await tester.runAsync(rental.loadInitialData);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: rental,
        child: MaterialApp(theme: buildAppTheme(), home: layar),
      ),
    );
    await tester.pump();
  }

  // Biarkan request ke API palsu selesai lalu perbarui layar
  Future<void> tunggu(WidgetTester tester) async {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
  }

  group('My Bookings', () {
    testWidgets('menampilkan kartu dan chip status', (tester) async {
      await pasang(tester, const MyBookingsScreen());

      expect(find.text('#GR2026120101'), findsOneWidget);
      expect(find.text('Confirmed'), findsOneWidget);
      expect(find.text('Toyota Avanza 2023'), findsWidgets);
      expect(find.text('Rp 780.000'), findsWidgets);
      expect(find.text('Batalkan'), findsOneWidget); // hanya booking Confirmed
    });

    testWidgets('Batalkan dengan konfirmasi mengubah status jadi Cancelled', (
      tester,
    ) async {
      await pasang(tester, const MyBookingsScreen());

      await tester.tap(find.text('Batalkan'));
      await tester.pumpAndSettle();
      expect(find.text('Batalkan booking?'), findsOneWidget);

      await tester.tap(find.text('Ya, batalkan'));
      await tunggu(tester);
      expect(rental.bookings.first.status, 'Cancelled');
      expect(find.text('Cancelled'), findsOneWidget);
      expect(find.text('Batalkan'), findsNothing);
    });

    testWidgets('server mati menampilkan error dan Coba lagi', (tester) async {
      await pasang(tester, const MyBookingsScreen(), serverMati: true);
      expect(find.textContaining('backend'), findsOneWidget);
      expect(find.text('Coba lagi'), findsOneWidget);
    });
  });

  group('Notifications', () {
    testWidgets('ketuk kartu menandai dibaca', (tester) async {
      await pasang(tester, const NotificationScreen());
      expect(find.text('Belum dibaca'), findsNWidgets(2));

      await tester.tap(find.text('Notif 1'));
      await tunggu(tester);
      expect(rental.unreadCount, 1);
      expect(find.text('Belum dibaca'), findsOneWidget);
    });

    testWidgets('Tandai semua lalu tombolnya nonaktif', (tester) async {
      await pasang(tester, const NotificationScreen());

      await tester.tap(find.text('Tandai semua'));
      await tunggu(tester);
      expect(rental.unreadCount, 0);
      final tombol = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Tandai semua'),
      );
      expect(tombol.onPressed, isNull);
    });

    testWidgets('tombol × menghapus setelah konfirmasi', (tester) async {
      await pasang(tester, const NotificationScreen());
      expect(find.byType(NotificationCard), findsNWidgets(3));

      await tester.tap(find.byTooltip('Hapus notifikasi').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hapus'));
      await tunggu(tester);
      expect(find.byType(NotificationCard), findsNWidgets(2));
      expect(rental.notifications.map((n) => n.id), [2, 3]);
    });
  });

  group('Profile', () {
    testWidgets('header menampilkan inisial, nama, dan Verified', (
      tester,
    ) async {
      await pasang(tester, const ProfileScreen());

      // assets/images/avatar.png belum ada, jadi avatar jatuh ke inisial
      await tester.pumpAndSettle();
      expect(find.text('EA'), findsOneWidget);
      expect(find.text('Eggy Andrean'), findsOneWidget);
      expect(find.text('Verified'), findsOneWidget);
    });

    testWidgets('Account Settings menyimpan nama dan HP baru', (tester) async {
      await pasang(tester, const ProfileScreen());

      await tester.tap(find.text('Account Settings'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextFormField, 'Nama'), 'Ed');
      await tester.tap(find.text('Simpan'));
      await tester.pump();
      expect(find.text('Nama minimal 3 huruf'), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nama'),
        'Eggy Andrean J',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'No. HP'),
        '0812-1234-5554',
      );
      await tester.tap(find.text('Simpan'));
      await tunggu(tester);
      expect(rental.user?.name, 'Eggy Andrean J');
      expect(find.text('Eggy Andrean J'), findsOneWidget);
    });

    testWidgets(
      'Booking History pindah ke tab My Bookings, Log Out hanya dialog',
      (tester) async {
        await pasang(tester, const ProfileScreen());

        // Menu bawah belum dibangun sebelum digulir
        await tester.scrollUntilVisible(find.text('Booking History'), 100);
        await tester.tap(find.text('Booking History'));
        expect(rental.currentTab, 1);

        await tester.scrollUntilVisible(find.text('Log Out'), 100);
        await tester.tap(find.text('Log Out'));
        await tester.pumpAndSettle();
        expect(find.text('Yakin ingin keluar dari akun ini?'), findsOneWidget);
      },
    );
  });
}
