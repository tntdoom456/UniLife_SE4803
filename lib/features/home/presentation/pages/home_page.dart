import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:unilife/core/theme/app_theme.dart';
import 'package:unilife/features/auth/presentation/pages/login_page.dart';
import 'package:unilife/features/schedule/presentation/pages/map_page.dart';
import 'package:unilife/features/schedule/presentation/pages/schedule_page.dart';
import 'package:unilife/features/materials/presentation/pages/materials_page.dart';
import 'package:unilife/features/wellness/presentation/pages/wellness_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  // Daftar halaman yang akan ditampilkan di Bottom Navigation
  final List<Widget> _pages = [
    const Center(child: Text('Dashboard Beranda')), // Ganti dengan DashboardPage
    const Center(child: Text('Halaman Jadwal & Maps')), // Ganti dengan SchedulePage
    const Center(child: Text('Halaman Materi & Kamera')), // Ganti dengan MaterialsPage
    const Center(child: Text('Halaman Kesehatan')), // Ganti dengan WellnessPage
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('UniLife'),
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Jadwal'),
          BottomNavigationBarItem(icon: Icon(Icons.folder), label: 'Materi'),
          BottomNavigationBarItem(icon: Icon(Icons.health_and_safety), label: 'Kesehatan'),
        ],
      ),
    );
  }
}