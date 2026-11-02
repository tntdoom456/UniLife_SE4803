import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:unilife/features/home/controllers/home_controller.dart';

class MainBottomNav extends GetView<HomeController> {
const MainBottomNav({super.key});
  @override
  Widget build(BuildContext context) {
    return Obx(() => BottomNavigationBar(
      currentIndex: controller.currentIndex.value,
      type: BottomNavigationBarType.fixed,
      onTap: controller.changePage, // Memanggil fungsi dari controller
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_month), label: 'Jadwal'),
        BottomNavigationBarItem(icon: Icon(Icons.folder), label: 'Materi'),
        BottomNavigationBarItem(icon: Icon(Icons.health_and_safety), label: 'Kesehatan'),
      ],
    ));
  }
}