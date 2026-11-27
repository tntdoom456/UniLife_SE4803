import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

import '../controllers/schedule_controller.dart';

class SchedulePage extends GetView<ScheduleController> {
  const SchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jadwal Kegiatan'),
        actions: [
          // Tombol Perkecil Layar Kalender (Zoom Out)
          IconButton(
            icon: const Icon(Icons.zoom_out_rounded),
            tooltip: 'Perkecil Skala Waktu',
            onPressed: controller.zoomOut,
          ),
          // Indikator persentase zoom (ketuk untuk reset ke 100%)
          Obx(
            () => InkWell(
              onTap: controller.resetZoom,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Text(
                  '${controller.zoomPercentage}%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                  ),
                ),
              ),
            ),
          ),
          // Tombol Perbesar Layar Kalender (Zoom In)
          IconButton(
            icon: const Icon(Icons.zoom_in_rounded),
            tooltip: 'Perbesar Skala Waktu',
            onPressed: controller.zoomIn,
          ),
          // Mode Layar Penuh / Fokus (sembunyikan bar filter kategori)
          Obx(
            () => IconButton(
              icon: Icon(
                controller.isCompactMode.value
                    ? Icons.fullscreen_exit_rounded
                    : Icons.fullscreen_rounded,
              ),
              tooltip: controller.isCompactMode.value
                  ? 'Tampilkan Bar Filter'
                  : 'Perluas Area Kalender',
              onPressed: controller.toggleCompactMode,
            ),
          ),
          // Tombol Peta Kampus
          IconButton(
            icon: const Icon(Icons.map_outlined),
            tooltip: 'Peta Kampus',
            onPressed: () => Get.toNamed('/map'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueAccent,
        onPressed: () => _tampilkanFormJadwal(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          // BAR FILTER KATEGORI (bisa disembunyikan via tombol fullscreen)
          Obx(() {
            if (controller.isCompactMode.value) {
              return const SizedBox.shrink();
            }

            final filterList = ['Semua', ...ScheduleController.categories];
            return Container(
              height: 50,
              color: const Color(0xFF1A1A1A),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: filterList.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = filterList[index];
                  final isSelected =
                      controller.selectedCategoryFilter.value == cat;
                  final color = cat == 'Semua'
                      ? Colors.blueAccent
                      : ScheduleController.getCategoryColor(cat);

                  return ChoiceChip(
                    label: Text(
                      cat,
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? Colors.white : Colors.white70,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: color,
                    backgroundColor: const Color(0xFF2A2A2A),
                    side: BorderSide(
                      color: isSelected ? color : Colors.white12,
                    ),
                    visualDensity: VisualDensity.compact,
                    onSelected: (_) =>
                        controller.selectedCategoryFilter.value = cat,
                  );
                },
              ),
            );
          }),

          // KALENDER 24 JAM DENGAN NAVIGASI LENGKAP & ZOOM REAKTIF
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              final dataTampil = controller.filteredJadwal;
              final intervalHeight = controller.timeIntervalHeight.value;

              return SfCalendar(
                controller: controller.calendarController,
                view: controller.calendarController.view ??
                    CalendarView.workWeek,
                allowedViews: const [
                  CalendarView.day,
                  CalendarView.workWeek,
                  CalendarView.week,
                  CalendarView.month,
                  CalendarView.schedule,
                ],
                showDatePickerButton: true,
                showNavigationArrow: true,
                showTodayButton: true,
                firstDayOfWeek: 1,
                backgroundColor: const Color(0xFF121212),
                todayHighlightColor: Colors.blueAccent,
                cellBorderColor: Colors.white12,
                headerStyle: const CalendarHeaderStyle(
                  backgroundColor: Color(0xFF1E1E1E),
                  textStyle: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                viewHeaderStyle: const ViewHeaderStyle(
                  backgroundColor: Color(0xFF181818),
                  dayTextStyle: TextStyle(color: Colors.white70, fontSize: 12),
                  dateTextStyle: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                monthViewSettings: const MonthViewSettings(
                  showAgenda: true,
                  agendaViewHeight: 170,
                  appointmentDisplayMode:
                      MonthAppointmentDisplayMode.appointment,
                  agendaStyle: AgendaStyle(
                    backgroundColor: Color(0xFF181818),
                    appointmentTextStyle: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    dateTextStyle: TextStyle(color: Colors.white70),
                    dayTextStyle: TextStyle(color: Colors.white70),
                  ),
                ),
                scheduleViewSettings: const ScheduleViewSettings(
                  appointmentTextStyle: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                appointmentTextStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                timeSlotViewSettings: TimeSlotViewSettings(
                  startHour: 0, // 24 Jam Penuh
                  endHour: 24,
                  timeFormat: 'HH:mm',
                  timeIntervalHeight: intervalHeight,
                  timeTextStyle: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                dataSource: _ScheduleDataSource(dataTampil),
                onTap: (details) {
                  if (details.appointments?.isNotEmpty == true) {
                    _detailJadwal(
                      context,
                      details.appointments!.first as Appointment,
                    );
                  }
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Future<void> _tampilkanFormJadwal(
    BuildContext context, {
    Appointment? lama,
  }) async {
    final masterLama =
        lama != null ? controller.findMasterAppointment(lama) : null;

    final baru = await showModalBottomSheet<Appointment>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _FormJadwalSheet(
        controller: controller,
        lama: masterLama,
      ),
    );

    if (baru != null) {
      await Future.delayed(const Duration(milliseconds: 250));
      await controller.tambahAtauEditJadwal(baru, lama: masterLama);

      Get.snackbar(
        'Sukses',
        masterLama == null
            ? 'Jadwal berhasil ditambahkan'
            : 'Jadwal berhasil diperbarui',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _detailJadwal(BuildContext context, Appointment tappedJadwal) {
    final master = controller.findMasterAppointment(tappedJadwal);
    final category = master.notes ?? 'Kuliah';
    final catColor = ScheduleController.getCategoryColor(category);

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badge Kategori
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: catColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: catColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    ScheduleController.getCategoryIcon(category),
                    size: 15,
                    color: catColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    category,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: catColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              tappedJadwal.subject,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 18, color: Colors.white60),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    (tappedJadwal.location == null ||
                            tappedJadwal.location!.isEmpty)
                        ? '-'
                        : tappedJadwal.location!,
                    style: const TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined,
                    size: 18, color: Colors.white60),
                const SizedBox(width: 8),
                Text(
                  '${tappedJadwal.startTime.day}/${tappedJadwal.startTime.month}/${tappedJadwal.startTime.year} • ${_format(tappedJadwal.startTime)} - ${_format(tappedJadwal.endTime)}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.repeat_rounded,
                    size: 18, color: Colors.white60),
                const SizedBox(width: 8),
                Text(
                  ScheduleController.describeRecurrence(master.recurrenceRule),
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      _tampilkanFormJadwal(context, lama: master);
                    },
                    child: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                    ),
                    onPressed: () {
                      _konfirmasiHapusJadwal(context, sheetContext, master);
                    },
                    child: const Text(
                      'Hapus',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _konfirmasiHapusJadwal(
    BuildContext parentContext,
    BuildContext sheetContext,
    Appointment jadwal,
  ) async {
    final isRecurring =
        jadwal.recurrenceRule != null && jadwal.recurrenceRule!.isNotEmpty;

    final yakin = await showDialog<bool>(
      context: parentContext,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Jadwal?'),
        content: Text(
          isRecurring
              ? 'Hapus seluruh rangkaian jadwal berulang "${jadwal.subject}"?'
              : 'Hapus "${jadwal.subject}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (yakin == true) {
      if (sheetContext.mounted) Navigator.pop(sheetContext);
      await Future.delayed(const Duration(milliseconds: 200));
      await controller.hapusJadwal(jadwal);
      Get.snackbar('Berhasil', 'Jadwal berhasil dihapus');
    }
  }

  String _format(DateTime waktu) =>
      '${waktu.hour.toString().padLeft(2, '0')}:'
      '${waktu.minute.toString().padLeft(2, '0')}';
}

// FORM TAMBAH / EDIT JADWAL (KATEGORI + REPETITIF + 24 JAM)
class _FormJadwalSheet extends StatefulWidget {
  final ScheduleController controller;
  final Appointment? lama;

  const _FormJadwalSheet({
    required this.controller,
    this.lama,
  });

  @override
  State<_FormJadwalSheet> createState() => _FormJadwalSheetState();
}

class _FormJadwalSheetState extends State<_FormJadwalSheet> {
  late final TextEditingController _namaController;
  late final TextEditingController _lokasiController;
  late DateTime _tanggal;
  late TimeOfDay _mulai;
  late TimeOfDay _selesai;
  late String _selectedCategory;
  late String _recurrenceFreq; // 'NONE', 'DAILY', 'WEEKLY', 'MONTHLY'
  late int _recurrenceCount; // 0 = tanpa batas, >0 = jumlah pengulangan

  @override
  void initState() {
    super.initState();
    final lama = widget.lama;
    _namaController = TextEditingController(text: lama?.subject ?? '');
    _lokasiController = TextEditingController(text: lama?.location ?? '');
    _tanggal = lama?.startTime ?? DateTime.now();
    _mulai = TimeOfDay.fromDateTime(
      lama?.startTime ??
          DateTime(_tanggal.year, _tanggal.month, _tanggal.day, 8),
    );
    _selesai = TimeOfDay.fromDateTime(
      lama?.endTime ??
          DateTime(_tanggal.year, _tanggal.month, _tanggal.day, 10),
    );
    _selectedCategory = (lama?.notes != null &&
            ScheduleController.categories.contains(lama!.notes))
        ? lama.notes!
        : 'Kuliah';

    // Parsing aturan pengulangan jika sedang mode Edit
    final rule = lama?.recurrenceRule ?? '';
    if (rule.contains('FREQ=DAILY')) {
      _recurrenceFreq = 'DAILY';
    } else if (rule.contains('FREQ=WEEKLY')) {
      _recurrenceFreq = 'WEEKLY';
    } else if (rule.contains('FREQ=MONTHLY')) {
      _recurrenceFreq = 'MONTHLY';
    } else {
      _recurrenceFreq = 'NONE';
    }

    final countMatch = RegExp(r'COUNT=(\d+)').firstMatch(rule);
    _recurrenceCount = countMatch != null
        ? int.tryParse(countMatch.group(1)!) ?? 16
        : (_recurrenceFreq == 'NONE' ? 16 : 0);
  }

  @override
  void dispose() {
    _namaController.dispose();
    _lokasiController.dispose();
    super.dispose();
  }

  String? _buildRecurrenceRule() {
    if (_recurrenceFreq == 'NONE') return null;
    if (_recurrenceCount > 0) {
      return 'FREQ=$_recurrenceFreq;INTERVAL=1;COUNT=$_recurrenceCount';
    }
    return 'FREQ=$_recurrenceFreq;INTERVAL=1';
  }

  Future<void> _pilihTanggal() async {
    FocusScope.of(context).unfocus();
    final hasil = await showDatePicker(
      context: context,
      initialDate: _tanggal,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (hasil != null) {
      setState(() => _tanggal = hasil);
    }
  }

  Future<void> _pilihWaktu(bool isMulai) async {
    FocusScope.of(context).unfocus();
    final hasil = await showTimePicker(
      context: context,
      initialTime: isMulai ? _mulai : _selesai,
      builder: (context, child) {
        // Paksa format 24 jam pada TimePicker agar konsisten dengan kalender
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (hasil != null) {
      setState(() {
        if (isMulai) {
          _mulai = hasil;
        } else {
          _selesai = hasil;
        }
      });
    }
  }

  String _format24(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _simpan() async {
    FocusScope.of(context).unfocus();

    final awal = DateTime(
      _tanggal.year,
      _tanggal.month,
      _tanggal.day,
      _mulai.hour,
      _mulai.minute,
    );

    final akhir = DateTime(
      _tanggal.year,
      _tanggal.month,
      _tanggal.day,
      _selesai.hour,
      _selesai.minute,
    );

    final rule = _buildRecurrenceRule();
    String? error;

    if (_namaController.text.trim().isEmpty) {
      error = 'Nama kegiatan wajib diisi!';
    } else if (!akhir.isAfter(awal)) {
      error = 'Waktu selesai harus setelah waktu mulai!';
    } else if (widget.controller.jadwalBentrok(
      awal,
      akhir,
      kecuali: widget.lama,
      recurrenceRuleBaru: rule,
    )) {
      error = 'Jadwal bentrok dengan kegiatan lain!';
    }

    if (error != null) {
      await showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Tidak dapat menyimpan jadwal'),
          content: Text(error!),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    final baru = Appointment(
      id: widget.lama?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      startTime: awal,
      endTime: akhir,
      subject: _namaController.text.trim(),
      location: _lokasiController.text.trim(),
      notes: _selectedCategory,
      color: ScheduleController.getCategoryColor(_selectedCategory),
      recurrenceRule: rule,
    );

    Navigator.pop(context, baru);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        20,
        16,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Text(
                widget.lama == null ? 'Tambah Jadwal Baru' : 'Edit Jadwal',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // PILIHAN KATEGORI KEGIATAN
            const Text(
              'Kategori Kegiatan',
              style: TextStyle(fontSize: 13, color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: ScheduleController.categories.map((cat) {
                final isSelected = _selectedCategory == cat;
                final color = ScheduleController.getCategoryColor(cat);
                return ChoiceChip(
                  avatar: Icon(
                    ScheduleController.getCategoryIcon(cat),
                    size: 16,
                    color: isSelected ? Colors.white : color,
                  ),
                  label: Text(
                    cat,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: color,
                  backgroundColor: const Color(0xFF2A2A2A),
                  onSelected: (_) {
                    setState(() {
                      _selectedCategory = cat;
                      // Otomatis sarankan berulang mingguan jika memilih kategori Kuliah saat tambah baru
                      if (widget.lama == null &&
                          cat == 'Kuliah' &&
                          _recurrenceFreq == 'NONE') {
                        _recurrenceFreq = 'WEEKLY';
                        _recurrenceCount = 16;
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

            TextField(
              controller: _namaController,
              decoration: const InputDecoration(
                labelText: 'Nama Kegiatan / Mata Kuliah',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _lokasiController,
              decoration: const InputDecoration(
                labelText: 'Lokasi / Ruangan (Cth: TULT 06.01)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),

            // TANGGAL & WAKTU 24 JAM
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_month, color: Colors.blueAccent),
              title: const Text('Tanggal Mulai'),
              subtitle: Text(
                '${_tanggal.day}/${_tanggal.month}/${_tanggal.year}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: _pilihTanggal,
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pilihWaktu(true),
                    icon: const Icon(Icons.access_time, size: 18),
                    label: Text('Mulai ${_format24(_mulai)}'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pilihWaktu(false),
                    icon: const Icon(Icons.access_time_filled, size: 18),
                    label: Text('Selesai ${_format24(_selesai)}'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // PENGATURAN JADWAL REPETITIF / BERULANG
            DropdownButtonFormField<String>(
              value: _recurrenceFreq,
              decoration: const InputDecoration(
                labelText: 'Pengulangan Jadwal (Repetitif)',
                prefixIcon: Icon(Icons.repeat_rounded),
                border: OutlineInputBorder(),
              ),
              dropdownColor: const Color(0xFF2A2A2A),
              items: const [
                DropdownMenuItem(
                  value: 'NONE',
                  child: Text('Tidak Berulang (Sekali saja)'),
                ),
                DropdownMenuItem(
                  value: 'DAILY',
                  child: Text('Setiap Hari (Harian)'),
                ),
                DropdownMenuItem(
                  value: 'WEEKLY',
                  child: Text('Setiap Minggu (Jadwal Kuliah Rutin)'),
                ),
                DropdownMenuItem(
                  value: 'MONTHLY',
                  child: Text('Setiap Bulan (Bulanan)'),
                ),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() => _recurrenceFreq = val);
                }
              },
            ),

            // JUMLAH PENGULANGAN (Muncul hanya jika jadwal repetitif diaktifkan)
            if (_recurrenceFreq != 'NONE') ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: [4, 8, 14, 16, 0].contains(_recurrenceCount)
                    ? _recurrenceCount
                    : 16,
                decoration: const InputDecoration(
                  labelText: 'Durasi Pengulangan',
                  prefixIcon: Icon(Icons.timelapse_rounded),
                  border: OutlineInputBorder(),
                ),
                dropdownColor: const Color(0xFF2A2A2A),
                items: const [
                  DropdownMenuItem(value: 4, child: Text('4 Kali Pertemuan')),
                  DropdownMenuItem(value: 8, child: Text('8 Kali (Setengah Semester)')),
                  DropdownMenuItem(value: 14, child: Text('14 Kali (1 Semester Kuliah)')),
                  DropdownMenuItem(value: 16, child: Text('16 Kali (Termasuk UTS/UAS)')),
                  DropdownMenuItem(value: 0, child: Text('Terus-menerus (Tanpa Batas)')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _recurrenceCount = val);
                  }
                },
              ),
            ],

            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _simpan,
                child: const Text(
                  'Simpan Jadwal',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleDataSource extends CalendarDataSource {
  _ScheduleDataSource(List<Appointment> data) {
    appointments = data;
  }
}