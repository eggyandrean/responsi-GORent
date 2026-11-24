import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/rental_provider.dart';
import 'home_screen.dart';
import 'my_bookings_screen.dart';
import 'notification_screen.dart';
import 'profile_screen.dart';

// Kerangka utama aplikasi: 4 tab dengan BottomNavigationBar.
// IndexedStack menjaga state setiap tab (posisi scroll, isi form) saat berpindah tab,
// dan tidak menumpuk route baru setiap tab diketuk.
class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  static const List<Widget> _tabs = [
    HomeScreen(),
    MyBookingsScreen(),
    NotificationScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final rental = context.watch<RentalProvider>();
    final unread = rental.unreadCount;

    return Scaffold(
      body: IndexedStack(index: rental.currentTab, children: _tabs),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: rental.currentTab,
        onTap: rental.changeTab,
        // Label hanya tampil di tab aktif
        showSelectedLabels: true,
        showUnselectedLabels: false,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.directions_car_outlined),
            activeIcon: Icon(Icons.directions_car),
            label: 'My Bookings',
          ),
          BottomNavigationBarItem(
            // Badge berisi jumlah notifikasi belum dibaca, disembunyikan jika 0
            icon: Badge(
              isLabelVisible: unread > 0,
              label: Text('$unread'),
              child: const Icon(Icons.notifications_outlined),
            ),
            activeIcon: Badge(
              isLabelVisible: unread > 0,
              label: Text('$unread'),
              child: const Icon(Icons.notifications),
            ),
            label: 'Notifications',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
