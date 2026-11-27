import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:unilife/features/wellness/presentation/controllers/wellness_controller.dart';
import 'package:unilife/features/schedule/presentation/controllers/schedule_controller.dart';

class WellnessPage extends GetView<WellnessController> {
  const WellnessPage({super.key});

  @override
  Widget build(BuildContext context) {
    final scheduleController = Get.find<ScheduleController>();
    final now = DateTime.now();

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Kesehatan & Kesejahteraan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: 'Riwayat Kesehatan',
            onPressed: () => _tampilkanRiwayatModal(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. KARTU SKOR KESEJAHTERAAN & ANALISIS BURNOUT
            Obx(() {
              final score = controller.wellnessScore;
              final status = controller.burnoutStatus;
              final statusColor = controller.burnoutColor;
              final todayClasses = scheduleController.jadwal.where((j) {
                return j.startTime.year == now.year &&
                    j.startTime.month == now.month &&
                    j.startTime.day == now.day;
              }).length;

              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF222222),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: statusColor.withOpacity(0.5),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 68,
                              height: 68,
                              child: CircularProgressIndicator(
                                value: score / 100,
                                strokeWidth: 7,
                                backgroundColor: Colors.white12,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  statusColor,
                                ),
                              ),
                            ),
                            Text(
                              '$score%',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Indeks Kesejahteraan Harian',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white60,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                status,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Beban jadwal hari ini: $todayClasses kegiatan',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.tips_and_updates_outlined,
                            color: statusColor,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              controller.healthRecommendation,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 20),

            // 2. KARTU AFIRMASI HARIAN (INTEGRASI REST API)
            Obx(() {
              final quote = controller.currentQuote.value;
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2962FF), Color(0xFF7C4DFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(
                              Icons.format_quote_rounded,
                              color: Colors.white70,
                              size: 24,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Afirmasi & Motivasi (REST API)',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: controller.isLoadingQuote.value
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.refresh,
                                  color: Colors.white,
                                  size: 20,
                                ),
                          tooltip: 'Muat Quote Baru dari API',
                          visualDensity: VisualDensity.compact,
                          onPressed: controller.isLoadingQuote.value
                              ? null
                              : controller.fetchDailyQuote,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '"${quote.text}"',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14.5,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '— ${quote.author}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 26),

            // 3. MOOD TRACKER (PEMANTAUAN MENTAL)
            const Text(
              'Bagaimana Kondisi Mentalmu Hari Ini?',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMoodIcon('🤩', 'Semangat', Colors.tealAccent),
                _buildMoodIcon('😊', 'Senang', Colors.green),
                _buildMoodIcon('😐', 'Biasa', Colors.amber),
                _buildMoodIcon('😴', 'Lelah', Colors.orangeAccent),
                _buildMoodIcon('😫', 'Stres', Colors.redAccent),
              ],
            ),

            const SizedBox(height: 26),

            // 4. PELACAK KESEHATAN FISIK (AIR, TIDUR, MAKAN)
            const Text(
              'Pemantauan Fisik Harian',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // A. Hidrasi / Minum Air Putih
            Obx(() {
              final glasses = controller.waterGlasses.value;
              final target = controller.targetWaterGlasses;
              final progress = (glasses / target).clamp(0.0, 1.0);
              final ml = glasses * 250;

              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.water_drop_rounded,
                          color: Colors.lightBlueAccent,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Asupan Air Putih',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                '$glasses / $target Gelas ($ml ml dari 2000 ml)',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white60,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: controller.removeWater,
                          icon: const Icon(
                            Icons.remove_circle_outline,
                            color: Colors.white70,
                          ),
                        ),
                        IconButton(
                          onPressed: controller.addWater,
                          icon: const Icon(
                            Icons.add_circle_rounded,
                            color: Colors.blueAccent,
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: Colors.white12,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Colors.lightBlueAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 12),

            // B. Pola Makan Harian (Sarapan, Siang, Malam)
            Obx(() {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A2A),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.restaurant_rounded,
                          color: Colors.orangeAccent,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Keteraturan Pola Makan',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _mealChip(
                            label: 'Sarapan',
                            checked: controller.hadBreakfast.value,
                            onTap: (v) => controller.toggleMeal(0, v),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _mealChip(
                            label: 'Makan Siang',
                            checked: controller.hadLunch.value,
                            onTap: (v) => controller.toggleMeal(1, v),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _mealChip(
                            label: 'Makan Malam',
                            checked: controller.hadDinner.value,
                            onTap: (v) => controller.toggleMeal(2, v),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 12),

            // C. Durasi Tidur & Pengingat Istirahat
            // C. Durasi Tidur & Pengingat Istirahat
            Obx(() {
              final hours = controller.sleepHours.value;
              return Material(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.bedtime_rounded,
                                color: Colors.deepPurpleAccent,
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Durasi Tidur Semalam',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${hours.toStringAsFixed(1)} Jam',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: (hours >= 7 && hours <= 9)
                                  ? Colors.greenAccent
                                  : Colors.orangeAccent,
                            ),
                          ),
                        ],
                      ),
                      Slider(
                        value: hours,
                        min: 2.0,
                        max: 12.0,
                        divisions: 20,
                        activeColor: Colors.deepPurpleAccent,
                        label: '${hours.toStringAsFixed(1)} Jam',
                        onChanged: controller.updateSleepHours,
                      ),
                      const Divider(color: Colors.white12),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text(
                          'Pengingat Tidur Sebelum 23:00',
                          style: TextStyle(fontSize: 14),
                        ),
                        subtitle: const Text(
                          'Mencegah begadang berlebihan saat ada kelas pagi',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Colors.white54,
                          ),
                        ),
                        value: controller.sleepReminderActive.value,
                        activeColor: Colors.deepPurpleAccent,
                        onChanged: controller.toggleSleepReminder,
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 24),

            // 5. TOMBOL SIMPAN REKAP HARIAN KE JURNAL RIWAYAT
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => _tampilkanDialogCatatJurnal(context),
                icon: const Icon(Icons.fact_check_outlined),
                label: const Text(
                  'Simpan Check-In Kesehatan Hari Ini',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildMoodIcon(String emoji, String label, Color color) {
    return Obx(() {
      final isSelected = controller.selectedMood.value == label;
      return GestureDetector(
        onTap: () => controller.setMood(label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withOpacity(0.2)
                : const Color(0xFF2A2A2A),
            border: Border.all(
              color: isSelected ? color : Colors.transparent,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 26)),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  color: isSelected ? color : Colors.white70,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _mealChip({
    required String label,
    required bool checked,
    required ValueChanged<bool> onTap,
  }) {
    return InkWell(
      onTap: () => onTap(!checked),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: checked
              ? Colors.orangeAccent.withOpacity(0.2)
              : Colors.black26,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: checked ? Colors.orangeAccent : Colors.white12,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              checked ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 16,
              color: checked ? Colors.orangeAccent : Colors.white54,
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: checked ? FontWeight.bold : FontWeight.normal,
                  color: checked ? Colors.orangeAccent : Colors.white70,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _tampilkanDialogCatatJurnal(BuildContext context) async {
    final hasil = await showDialog<String>(
      context: context,
      builder: (_) =>
          _CatatJurnalDialog(initialNote: controller.dailyNote.value),
    );

    if (hasil != null) {
      await Future.delayed(const Duration(milliseconds: 220));
      await controller.saveDailyCheckInLog(hasil);
    }
  }

  void _tampilkanRiwayatModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Riwayat Kesehatan Harian',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Obx(() {
                if (controller.historyLogs.isEmpty) {
                  return const Center(
                    child: Text(
                      'Belum ada riwayat check-in.\nTekan "Simpan Check-In Kesehatan Hari Ini" untuk merekam.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white54),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: controller.historyLogs.length,
                  itemBuilder: (context, index) {
                    final log = controller.historyLogs[index];
                    return Card(
                      color: const Color(0xFF2A2A2A),
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blueAccent.withOpacity(0.2),
                          child: Text(
                            '${log.score}%',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.blueAccent,
                            ),
                          ),
                        ),
                        title: Text(
                          '${log.date} • Mood: ${log.mood}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          'Air: ${log.waterGlasses} gelas | Tidur: ${log.sleepHours.toStringAsFixed(1)} jam | Makan: ${log.mealsCount}x'
                          '${log.note.isNotEmpty ? "\nCatatan: ${log.note}" : ""}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class _CatatJurnalDialog extends StatefulWidget {
  final String initialNote;

  const _CatatJurnalDialog({required this.initialNote});

  @override
  State<_CatatJurnalDialog> createState() => _CatatJurnalDialogState();
}

class _CatatJurnalDialogState extends State<_CatatJurnalDialog> {
  late final TextEditingController _noteCtrl;

  @override
  void initState() {
    super.initState();
    _noteCtrl = TextEditingController(text: widget.initialNote);
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  void _tutup([String? value]) {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      title: const Text('Check-In Harian'),
      content: TextField(
        controller: _noteCtrl,
        maxLines: 3,
        decoration: const InputDecoration(
          hintText: 'Tulis catatan kondisimu hari ini (misal: agak pusing karena tugas)...',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(onPressed: () => _tutup(), child: const Text('Batal')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
          ),
          onPressed: () => _tutup(_noteCtrl.text),
          child: const Text('Simpan Rekap'),
        ),
      ],
    );
  }
}
