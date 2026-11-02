import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:unilife/features/home/controllers/home_controller.dart';
import 'package:unilife/features/home/presentation/widgets/main_bottom_nav.dart';
import 'package:unilife/features/materials/presentation/pages/materials_page.dart';
import 'package:unilife/features/schedule/presentation/pages/schedule_page.dart';
import 'package:unilife/features/wellness/presentation/pages/wellness_page.dart';

class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const Center(child: Text('Beranda'),),
      const SchedulePage(),
      const MaterialsPage(),
      WellnessPage()
    ];
    return Scaffold(
    appBar: AppBar(title: Text('UniLife')),

    body: Obx(() => pages[controller.currentIndex.value]),
    bottomNavigationBar: const MainBottomNav(),
    );
  }
}