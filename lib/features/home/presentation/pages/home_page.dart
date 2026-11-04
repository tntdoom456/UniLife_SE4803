import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:unilife/features/home/controllers/home_controller.dart';
import 'package:unilife/features/home/presentation/widgets/main_bottom_nav.dart';
import 'package:unilife/features/schedule/controllers/schedule_controller.dart';
import 'package:unilife/features/materials/controllers/materials_controller.dart';
import 'package:unilife/features/wellness/controllers/wellness_controller.dart';
import 'package:unilife/features/schedule/presentation/pages/schedule_page.dart';
import 'package:unilife/features/materials/presentation/pages/materials_page.dart';
import 'package:unilife/features/wellness/presentation/pages/wellness_page.dart';

class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final index = controller.currentIndex.value;

      Widget page;

      switch (index) {
        case 1:
          page = const SchedulePage();
          break;
        case 2:
          page = const MaterialsPage();
          break;
        case 3:
          page = WellnessPage();
          break;
        default:
          page = DashboardContent(onNavigate: controller.changePage);
      }

      return Scaffold(
        appBar: index == 0
            ? AppBar(
                title: const Text(
                  'UniLife',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                actions: [
                  const Padding(
                    padding: EdgeInsets.only(right: 16),
                    child: Icon(Icons.school_outlined),
                  ),
                ],
              )
            : null,
        body: page,
        bottomNavigationBar: const MainBottomNav(),
      );
    });
  }
}

class DashboardContent extends StatelessWidget {
  final Function(int) onNavigate;

  DashboardContent({super.key, required this.onNavigate});

  final ScheduleController scheduleController = Get.find<ScheduleController>();

  final MaterialsController materialsController =
      Get.find<MaterialsController>();

  final WellnessController wellnessController = Get.find<WellnessController>();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();

    final days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];

    final months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Greeting
          const Text(
            'Halo, Mahasiswa! 👋',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 6),

          Text(
            '${days[now.weekday - 1]}, ${now.day} '
            '${months[now.month - 1]} ${now.year}',
            style: const TextStyle(color: Colors.white60),
          ),

          const SizedBox(height: 24),

          // Welcome card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.blueAccent, Color(0xFF3949AB)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.school, color: Colors.white, size: 36),
                SizedBox(height: 14),
                Text(
                  'Welcome to UniLife!',
                  style: TextStyle(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Kelola jadwal kuliah, materi, dan kesehatanmu '
                  'dalam satu aplikasi.',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),

          const SizedBox(height: 26),

          // Statistics
          const Text(
            'Ringkasan Aktivitas',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 14),

          Obx(() {
            final todaySchedules = scheduleController.jadwal.where((j) {
              return j.startTime.year == now.year &&
                  j.startTime.month == now.month &&
                  j.startTime.day == now.day;
            }).length;

            final totalMaterials = materialsController.savedPhotos.length;

            final mood = wellnessController.selectedMood.value;

            return GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.35,
              children: [
                _statCard(
                  icon: Icons.calendar_month,
                  title: 'Jadwal Hari Ini',
                  value: '$todaySchedules',
                  description: 'Kegiatan kuliah',
                  color: Colors.orange,
                ),
                _statCard(
                  icon: Icons.folder,
                  title: 'Materi Tersimpan',
                  value: '$totalMaterials',
                  description: 'File hasil scan',
                  color: Colors.blueAccent,
                ),
                _statCard(
                  icon: Icons.mood,
                  title: 'Mood Hari Ini',
                  value: mood.isEmpty ? '-' : mood,
                  description: 'Kondisi perasaan',
                  color: Colors.green,
                ),
                _statCard(
                  icon: Icons.favorite,
                  title: 'Wellness',
                  value: 'Aktif',
                  description: 'Fitur kesehatan',
                  color: Colors.pinkAccent,
                ),
              ],
            );
          }),

          const SizedBox(height: 26),

          // Today's schedule
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Jadwal Hari Ini',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () => onNavigate(1),
                child: const Text('Lihat Semua'),
              ),
            ],
          ),

          const SizedBox(height: 8),

          Obx(() {
            if (scheduleController.isLoading.value) {
              return const Center(child: CircularProgressIndicator());
            }

            final todaySchedules = scheduleController.jadwal.where((j) {
              return j.startTime.year == now.year &&
                  j.startTime.month == now.month &&
                  j.startTime.day == now.day;
            }).toList();

            todaySchedules.sort((a, b) => a.startTime.compareTo(b.startTime));

            if (todaySchedules.isEmpty) {
              return _emptyCard(
                Icons.event_available,
                'Tidak ada jadwal kuliah hari ini.',
              );
            }

            return Column(
              children: todaySchedules.map((schedule) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.blueAccent,
                      child: Icon(Icons.book, color: Colors.white),
                    ),
                    title: Text(
                      schedule.subject,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${_formatTime(schedule.startTime)} - '
                      '${_formatTime(schedule.endTime)}\n'
                      '${schedule.location ?? "-"}',
                    ),
                    isThreeLine: true,
                  ),
                );
              }).toList(),
            );
          }),

          const SizedBox(height: 26),

          // Quick access
          const Text(
            'Akses Cepat',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _quickButton(
                  Icons.calendar_month,
                  'Jadwal',
                  Colors.orange,
                  () => onNavigate(1),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _quickButton(
                  Icons.folder_open,
                  'Materi',
                  Colors.blueAccent,
                  () => onNavigate(2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _quickButton(
                  Icons.favorite,
                  'Wellness',
                  Colors.green,
                  () => onNavigate(3),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _statCard({
    required IconData icon,
    required String title,
    required String value,
    required String description,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 21),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            description,
            style: const TextStyle(fontSize: 11, color: Colors.white54),
          ),
        ],
      ),
    );
  }

  Widget _emptyCard(IconData icon, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: Colors.white54),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(color: Colors.white60),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _quickButton(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 27),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
