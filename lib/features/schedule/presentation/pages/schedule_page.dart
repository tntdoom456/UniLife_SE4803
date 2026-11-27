import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

import '../controllers/schedule_controller.dart';

class SchedulePage extends GetView<ScheduleController> {
  const SchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Cegah SfCalendar melakukan relayout puluhan kali saat keyboard muncul/tutup
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Jadwal Kegiatan'),
        actions: [
          Obx(
            () => IconButton(
              icon: Icon(
                controller.showFilterBar.value
                    ? Icons.filter_alt_outlined
                    : Icons.filter_alt_off_outlined,
              ),
              tooltip: controller.showFilterBar.value
                  ? 'Sembunyikan Filter Tag'
                  : 'Tampilkan Filter Tag',
              onPressed: controller.toggleFilterBar,
            ),
          ),
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
      body: Stack(
        children: [
          Column(
            children: [
              // BAR FILTER TAG / KATEGORI
              Obx(() {
                if (!controller.showFilterBar.value) {
                  return const SizedBox.shrink();
                }

                final filterList = ['Semua', ...controller.categories];
                return Container(
                  height: 50,
                  color: const Color(0xFF1A1A1A),
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    itemCount: filterList.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      if (index == filterList.length) {
                        return ActionChip(
                          avatar: const Icon(
                            Icons.add,
                            size: 16,
                            color: Colors.blueAccent,
                          ),
                          label: const Text(
                            'Tag Baru',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blueAccent,
                            ),
                          ),
                          backgroundColor: const Color(0xFF242424),
                          side: const BorderSide(color: Colors.blueAccent),
                          visualDensity: VisualDensity.compact,
                          onPressed: () => _tampilkanDialogTambahTag(context),
                        );
                      }

                      final cat = filterList[index];
                      final isSelected =
                          controller.selectedCategoryFilter.value == cat;
                      final color = cat == 'Semua'
                          ? Colors.blueAccent
                          : controller.getCategoryColor(cat);
                      final isCustom =
                          cat != 'Semua' && !controller.isDefaultCategory(cat);

                      return GestureDetector(
                        onLongPress: isCustom
                            ? () => _konfirmasiHapusTag(context, cat)
                            : null,
                        child: ChoiceChip(
                          label: Text(
                            cat,
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected ? Colors.white : Colors.white70,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: color,
                          backgroundColor: const Color(0xFF2A2A2A),
                          side: BorderSide(
                            color: isSelected ? color : Colors.white12,
                          ),
                          visualDensity: VisualDensity.compact,
                          onSelected: (_) => controller.setCategoryFilter(cat),
                        ),
                      );
                    },
                  ),
                );
              }),

              // KALENDER 24 JAM
              Expanded(
                child: _ScheduleCalendarBody(
                  controller: controller,
                  onTapAppointment: (appt) => _detailJadwal(context, appt),
                ),
              ),
            ],
          ),

          // PANEL KONTROL ZOOM DI POJOK KIRI BAWAH
          Positioned(
            left: 14,
            bottom: 16,
            child: Material(
              color: const Color(0xE6222222),
              elevation: 4,
              borderRadius: BorderRadius.circular(24),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove, size: 18),
                      tooltip: 'Perkecil Skala Waktu',
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      onPressed: controller.zoomOut,
                    ),
                    Obx(
                      () => InkWell(
                        onTap: controller.resetZoom,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 6,
                          ),
                          child: Text(
                            '${controller.zoomPercentage}%',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, size: 18),
                      tooltip: 'Perbesar Skala Waktu',
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      onPressed: controller.zoomIn,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Membuka dialog tambah tag berbasis StatefulWidget (aman saat Batal/Tambah)
  Future<String?> _tampilkanDialogTambahTag(BuildContext context) async {
    final hasil = await showDialog<_TagResult>(
      context: context,
      builder: (_) => const _TambahTagDialog(),
    );

    if (hasil != null) {
      await Future.delayed(const Duration(milliseconds: 220));
      final ok = await controller.tambahKategoriKustom(hasil.nama, hasil.warna);
      if (ok) {
        Get.snackbar(
          'Sukses',
          'Tag "${hasil.nama}" ditambahkan',
          snackPosition: SnackPosition.BOTTOM,
        );
        return hasil.nama;
      }
    }
    return null;
  }

  Future<void> _konfirmasiHapusTag(BuildContext context, String tag) async {
    final yakin = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Hapus Tag?'),
        content: Text('Hapus tag kustom "$tag" dari daftar filter?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (yakin == true) {
      await Future.delayed(const Duration(milliseconds: 220));
      await controller.hapusKategoriKustom(tag);
    }
  }

  Future<void> _tampilkanFormJadwal(
    BuildContext context, {
    Appointment? lama,
  }) async {
    final masterLama = lama != null
        ? controller.findMasterAppointment(lama)
        : null;

    final baru = await showModalBottomSheet<Appointment>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => _FormJadwalSheet(
        controller: controller,
        lama: masterLama,
        onRequestNewTag: () => _tampilkanDialogTambahTag(sheetCtx),
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
    final category = master.notes ?? 'Lainnya';
    final catColor = controller.getCategoryColor(category);
    final daftarBentrok = controller.getBentrokPadaSlot(tappedJadwal);

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: catColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: catColor),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          controller.getCategoryIcon(category),
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
                  if (daftarBentrok.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.redAccent),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            size: 14,
                            color: Colors.redAccent,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Jadwal Bentrok',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.redAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              Text(
                tappedJadwal.subject,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              if (daftarBentrok.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.redAccent.withValues(alpha: 0.6),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bertabrakan pada waktu ini dengan:',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.redAccent,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ...daftarBentrok.map(
                        (b) => Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Text(
                            '• ${b.subject} (${_format(b.startTime)} - ${_format(b.endTime)})',
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 18,
                    color: Colors.white60,
                  ),
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
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 18,
                    color: Colors.white60,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${ScheduleController.formatTanggalLengkap(tappedJadwal.startTime)} • ${_format(tappedJadwal.startTime)} - ${_format(tappedJadwal.endTime)}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.repeat_rounded,
                    size: 18,
                    color: Colors.white60,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ScheduleController.describeRecurrence(
                        master.recurrenceRule,
                        startTime: master.startTime,
                      ),
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        Navigator.pop(sheetContext);
                        await Future.delayed(const Duration(milliseconds: 220));
                        if (context.mounted) {
                          _tampilkanFormJadwal(context, lama: master);
                        }
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
        backgroundColor: const Color(0xFF1E1E1E),
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
      await Future.delayed(const Duration(milliseconds: 220));
      await controller.hapusJadwal(jadwal);
      Get.snackbar('Berhasil', 'Jadwal berhasil dihapus');
    }
  }

  String _format(DateTime waktu) =>
      '${waktu.hour.toString().padLeft(2, '0')}:'
      '${waktu.minute.toString().padLeft(2, '0')}';
}

// ============================================================================
// DIALOG TAMBAH TAG (STATEFULWIDGET — MENCEGAH FREEZE SAAT KLIK BATAL/TAMBAH)
// ============================================================================
class _TagResult {
  final String nama;
  final Color warna;

  const _TagResult(this.nama, this.warna);
}

class _TambahTagDialog extends StatefulWidget {
  const _TambahTagDialog();

  @override
  State<_TambahTagDialog> createState() => _TambahTagDialogState();
}

class _TambahTagDialogState extends State<_TambahTagDialog> {
  late final TextEditingController _tagCtrl;
  Color _selectedColor = ScheduleController.customColorPalette.first;

  @override
  void initState() {
    super.initState();
    _tagCtrl = TextEditingController();
  }

  @override
  void dispose() {
    // Aman: dipanggil Flutter hanya setelah animasi dialog benar-benar selesai
    _tagCtrl.dispose();
    super.dispose();
  }

  void _tutup([_TagResult? result]) {
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      title: const Text('Tambah Tag Baru'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _tagCtrl,
              decoration: const InputDecoration(
                labelText: 'Nama Tag (cth: Praktikum, UKM)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Pilih Warna Tag:',
              style: TextStyle(fontSize: 13, color: Colors.white70),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: ScheduleController.customColorPalette.map((color) {
                final active = _selectedColor == color;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = color),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: active
                          ? Border.all(color: Colors.white, width: 2.5)
                          : null,
                    ),
                    child: active
                        ? const Icon(Icons.check, size: 16, color: Colors.black)
                        : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => _tutup(), child: const Text('Batal')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            final clean = _tagCtrl.text.trim();
            if (clean.isEmpty) return;
            _tutup(_TagResult(clean, _selectedColor));
          },
          child: const Text('Tambah'),
        ),
      ],
    );
  }
}

// BODY KALENDER TERISOLASI: KELOLA CALENDARCONTROLLER + PINCH-TO-ZOOM
class _ScheduleCalendarBody extends StatefulWidget {
  final ScheduleController controller;
  final void Function(Appointment) onTapAppointment;

  const _ScheduleCalendarBody({
    required this.controller,
    required this.onTapAppointment,
  });

  @override
  State<_ScheduleCalendarBody> createState() => _ScheduleCalendarBodyState();
}

class _ScheduleCalendarBodyState extends State<_ScheduleCalendarBody> {
  late final CalendarController _calendarController;
  final Map<int, Offset> _pointers = {};
  double? _initialDistance;
  double _initialHeight = 60.0;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _calendarController = CalendarController()
      ..view = CalendarView.workWeek
      ..displayDate = DateTime(now.year, now.month, now.day, 7, 0);
  }

  @override
  void dispose() {
    _calendarController.dispose();
    super.dispose();
  }

  double _distanceBetweenTwoPointers() {
    final pts = _pointers.values.toList();
    return (pts[0] - pts[1]).distance;
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) {
        _pointers[event.pointer] = event.position;
        if (_pointers.length == 2) {
          _initialDistance = _distanceBetweenTwoPointers();
          _initialHeight = widget.controller.timeIntervalHeight.value;
        }
      },
      onPointerMove: (event) {
        if (!_pointers.containsKey(event.pointer)) return;
        _pointers[event.pointer] = event.position;

        if (_pointers.length == 2 &&
            _initialDistance != null &&
            _initialDistance! > 10) {
          final currentDistance = _distanceBetweenTwoPointers();
          final scale = currentDistance / _initialDistance!;
          widget.controller.setZoomHeight(_initialHeight * scale);
        }
      },
      onPointerUp: (event) {
        _pointers.remove(event.pointer);
        if (_pointers.length < 2) _initialDistance = null;
      },
      onPointerCancel: (event) {
        _pointers.remove(event.pointer);
        if (_pointers.length < 2) _initialDistance = null;
      },
      child: Obx(() {
        if (widget.controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        // Gunakan DataSource ter-cache agar zoom tidak mem-parsing ulang jadwal
        final dataSource = widget.controller.calendarDataSource.value;
        final intervalHeight = widget.controller.timeIntervalHeight.value;

        return SfCalendar(
          controller: _calendarController,
          view: _calendarController.view ?? CalendarView.workWeek,
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
            appointmentDisplayMode: MonthAppointmentDisplayMode.appointment,
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
          timeSlotViewSettings: TimeSlotViewSettings(
            startHour: 0,
            endHour: 24,
            timeFormat: 'HH:mm',
            timeIntervalHeight: intervalHeight,
            timeTextStyle: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          appointmentBuilder: (context, details) {
            if (details.appointments.isEmpty) return const SizedBox.shrink();
            final appt = details.appointments.first as Appointment;
            final bentrok = widget.controller.isSlotBentrokCepat(appt);

            return Container(
              width: details.bounds.width,
              height: details.bounds.height,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: appt.color.withValues(alpha: bentrok ? 0.85 : 0.95),
                borderRadius: BorderRadius.circular(5),
                border: bentrok
                    ? Border.all(color: Colors.redAccent, width: 2)
                    : null,
              ),
              child: Text(
                bentrok ? '⚠ ${appt.subject}' : appt.subject,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            );
          },
          dataSource: dataSource,
          onTap: (details) {
            if (details.appointments?.isNotEmpty == true) {
              widget.onTapAppointment(
                details.appointments!.first as Appointment,
              );
            }
          },
        );
      }),
    );
  }
}

// FORM TAMBAH / EDIT JADWAL
class _FormJadwalSheet extends StatefulWidget {
  final ScheduleController controller;
  final Appointment? lama;
  final Future<String?> Function() onRequestNewTag;

  const _FormJadwalSheet({
    required this.controller,
    this.lama,
    required this.onRequestNewTag,
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
  bool _userChangedTagManually = false;

  late String _recurrenceFreq;
  late int _recurrenceCount;

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

    if (lama != null) {
      _selectedCategory = lama.notes ?? 'Lainnya';
      _userChangedTagManually = true;
    } else {
      _selectedCategory = 'Lainnya';
    }

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
    return ScheduleController.buildRecurrenceRule(
      _recurrenceFreq,
      _tanggal,
      _recurrenceCount,
    );
  }

  Future<void> _pilihTanggal() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final hasil = await showDatePicker(
      context: context,
      initialDate: _tanggal,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (hasil != null && mounted) {
      setState(() => _tanggal = hasil);
    }
  }

  Future<void> _pilihWaktu(bool isMulai) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final hasil = await showTimePicker(
      context: context,
      initialTime: isMulai ? _mulai : _selesai,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (hasil != null && mounted) {
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
    FocusManager.instance.primaryFocus?.unfocus();

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

    String? error;
    if (_namaController.text.trim().isEmpty) {
      error = 'Nama kegiatan wajib diisi!';
    } else if (!akhir.isAfter(awal)) {
      error = 'Waktu selesai harus setelah waktu mulai!';
    }

    if (error != null) {
      await showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
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

    final rule = _buildRecurrenceRule();

    final conflicts = widget.controller.cariJadwalBentrok(
      awal,
      akhir,
      kecuali: widget.lama,
      recurrenceRuleBaru: rule,
    );

    if (conflicts.isNotEmpty) {
      final tetapSimpan = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent),
              SizedBox(width: 8),
              Expanded(child: Text('Jadwal Bentrok Terdeteksi')),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Jadwal ini bertabrakan dengan kegiatan berikut:',
                  style: TextStyle(fontSize: 13.5, color: Colors.white70),
                ),
                const SizedBox(height: 10),
                ...conflicts.map((c) {
                  final previewDates = c.conflictDates
                      .take(3)
                      .map((d) => ScheduleController.formatTanggalLengkap(d))
                      .join(', ');
                  final sisa = c.conflictDates.length - 3;
                  final sisaText = sisa > 0 ? ' (+$sisa tanggal lainnya)' : '';

                  return Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.redAccent.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.existingAppointment.subject,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Bentrok pada: $previewDates$sisaText',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 6),
                const Text(
                  'Apakah Anda tetap ingin menyimpan jadwal ini? Jadwal yang bentrok akan tetap ditandai di kalender.',
                  style: TextStyle(fontSize: 12.5, color: Colors.white60),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Ubah Waktu'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orangeAccent,
                foregroundColor: Colors.black,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(
                'Tetap Simpan',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );

      if (tetapSimpan != true) return;
    }

    final baru = Appointment(
      id: widget.lama?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      startTime: awal,
      endTime: akhir,
      subject: _namaController.text.trim(),
      location: _lokasiController.text.trim(),
      notes: _selectedCategory,
      color: widget.controller.getCategoryColor(_selectedCategory),
      recurrenceRule: rule,
    );

    if (mounted) {
      Navigator.pop(context, baru);
    }
  }

  @override
  Widget build(BuildContext context) {
    final endEstimate = ScheduleController.estimateEndDate(
      _tanggal,
      _recurrenceFreq,
      _recurrenceCount,
    );

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
            const Text(
              'Tag / Kategori Kegiatan',
              style: TextStyle(fontSize: 13, color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Obx(() {
              final allCats = widget.controller.categories;
              return Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  ...allCats.map((cat) {
                    final isSelected = _selectedCategory == cat;
                    final color = widget.controller.getCategoryColor(cat);
                    return ChoiceChip(
                      avatar: Icon(
                        widget.controller.getCategoryIcon(cat),
                        size: 16,
                        color: isSelected ? Colors.white : color,
                      ),
                      label: Text(
                        cat,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: isSelected ? Colors.white : Colors.white70,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: color,
                      backgroundColor: const Color(0xFF2A2A2A),
                      onSelected: (_) {
                        setState(() {
                          _selectedCategory = cat;
                          _userChangedTagManually = true;
                        });
                      },
                    );
                  }),
                  ActionChip(
                    avatar: const Icon(
                      Icons.add,
                      size: 16,
                      color: Colors.blueAccent,
                    ),
                    label: const Text(
                      'Tambah Tag',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.blueAccent,
                      ),
                    ),
                    backgroundColor: const Color(0xFF242424),
                    side: const BorderSide(color: Colors.blueAccent),
                    onPressed: () async {
                      FocusManager.instance.primaryFocus?.unfocus();
                      final newTag = await widget.onRequestNewTag();
                      if (newTag != null && mounted) {
                        setState(() {
                          _selectedCategory = newTag;
                          _userChangedTagManually = true;
                        });
                      }
                    },
                  ),
                ],
              );
            }),
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
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.calendar_month,
                color: Colors.blueAccent,
              ),
              title: Text(
                _recurrenceFreq == 'NONE'
                    ? 'Tanggal Kegiatan'
                    : 'Mulai Perulangan Dari',
              ),
              subtitle: Text(
                '${ScheduleController.formatTanggalLengkap(_tanggal)} (${ScheduleController.formatRelatifHariIni(_tanggal)})',
                style: const TextStyle(color: Colors.blueAccent),
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
                  setState(() {
                    _recurrenceFreq = val;
                    if (val != 'NONE' &&
                        !_userChangedTagManually &&
                        _selectedCategory == 'Lainnya') {
                      _selectedCategory = 'Kuliah';
                    } else if (val == 'NONE' &&
                        !_userChangedTagManually &&
                        _selectedCategory == 'Kuliah') {
                      _selectedCategory = 'Lainnya';
                    }
                  });
                }
              },
            ),
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
                  DropdownMenuItem(
                    value: 8,
                    child: Text('8 Kali (Setengah Semester)'),
                  ),
                  DropdownMenuItem(
                    value: 14,
                    child: Text('14 Kali (1 Semester Kuliah)'),
                  ),
                  DropdownMenuItem(
                    value: 16,
                    child: Text('16 Kali (Termasuk UTS/UAS)'),
                  ),
                  DropdownMenuItem(
                    value: 0,
                    child: Text('Terus-menerus (Tanpa Batas)'),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _recurrenceCount = val);
                  }
                },
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.blueAccent.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 18,
                      color: Colors.blueAccent,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${ScheduleController.describeRecurrence(_buildRecurrenceRule(), startTime: _tanggal)}'
                        ' (${ScheduleController.formatRelatifHariIni(_tanggal)})'
                        '${endEstimate != null ? ' hingga ${ScheduleController.formatTanggalLengkap(endEstimate)}.' : '.'}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),
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
