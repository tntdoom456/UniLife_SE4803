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
          IconButton(
            icon: const Icon(Icons.map_outlined),
            onPressed: () => Get.toNamed('/map'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blueAccent,
        onPressed: () => _tampilkanFormJadwal(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return SfCalendar(
          view: CalendarView.workWeek,
          firstDayOfWeek: 1,
          backgroundColor: const Color(0xFF121212),
          todayHighlightColor: Colors.blueAccent,
          cellBorderColor: Colors.white12,
          headerStyle: const CalendarHeaderStyle(
            backgroundColor: Color(0xFF1E1E1E),
            textStyle: TextStyle(
              color: Colors.white,
              fontSize: 18,
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
          appointmentTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          timeSlotViewSettings: const TimeSlotViewSettings(
            startHour: 7,
            endHour: 22,
            timeFormat: 'HH:mm',
            timeTextStyle: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          dataSource: _ScheduleDataSource(controller.jadwal.toList()),
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
    );
  }

  Future<void> _tampilkanFormJadwal(
    BuildContext context, {
    Appointment? lama,
  }) async {
    final baru = await showModalBottomSheet<Appointment>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _FormJadwalSheet(
        controller: controller,
        lama: lama,
      ),
    );

    if (baru != null) {
      // Beri jeda singkat agar animasi bottom sheet selesai sebelum kalender di-refresh
      await Future.delayed(const Duration(milliseconds: 250));
      await controller.tambahAtauEditJadwal(baru, lama: lama);

      Get.snackbar(
        'Sukses',
        lama == null
            ? 'Jadwal berhasil ditambahkan'
            : 'Jadwal berhasil diperbarui',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void _detailJadwal(BuildContext context, Appointment jadwal) {
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
            Text(
              jadwal.subject,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text('Lokasi: ${jadwal.location ?? "-"}'),
            Text(
              'Tanggal: ${jadwal.startTime.day}/'
              '${jadwal.startTime.month}/${jadwal.startTime.year}',
            ),
            Text(
              'Waktu: ${_format(jadwal.startTime)} - '
              '${_format(jadwal.endTime)}',
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      _tampilkanFormJadwal(context, lama: jadwal);
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
                      _konfirmasiHapusJadwal(context, sheetContext, jadwal);
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
    final yakin = await showDialog<bool>(
      context: parentContext,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Jadwal?'),
        content: Text('Hapus "${jadwal.subject}"?'),
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

  @override
  void initState() {
    super.initState();
    final lama = widget.lama;
    _namaController = TextEditingController(text: lama?.subject ?? '');
    _lokasiController = TextEditingController(text: lama?.location ?? '');
    _tanggal = lama?.startTime ?? DateTime.now();
    _mulai = TimeOfDay.fromDateTime(
      lama?.startTime ?? DateTime(_tanggal.year, _tanggal.month, _tanggal.day, 8),
    );
    _selesai = TimeOfDay.fromDateTime(
      lama?.endTime ?? DateTime(_tanggal.year, _tanggal.month, _tanggal.day, 10),
    );
  }

  @override
  void dispose() {
    // Aman: Hanya dipanggil setelah animasi bottom sheet selesai ditutup
    _namaController.dispose();
    _lokasiController.dispose();
    super.dispose();
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

  Future<void> _simpan() async {
    // Tutup keyboard terlebih dahulu agar tidak bentrok dengan penutupan sheet
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

    String? error;

    if (_namaController.text.trim().isEmpty) {
      error = 'Nama kegiatan wajib diisi!';
    } else if (!akhir.isAfter(awal)) {
      error = 'Waktu selesai harus setelah waktu mulai!';
    } else if (widget.controller.jadwalBentrok(
      awal,
      akhir,
      kecuali: widget.lama,
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
      startTime: awal,
      endTime: akhir,
      subject: _namaController.text.trim(),
      location: _lokasiController.text.trim(),
      color: widget.lama?.color ?? Colors.blueAccent,
    );

    Navigator.pop(context, baru);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        24,
        16,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.lama == null ? 'Tambah Jadwal' : 'Edit Jadwal',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _namaController,
              decoration: const InputDecoration(
                labelText: 'Nama kegiatan',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _lokasiController,
              decoration: const InputDecoration(
                labelText: 'Lokasi',
                border: OutlineInputBorder(),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month),
              title: const Text('Tanggal'),
              subtitle: Text(
                '${_tanggal.day}/${_tanggal.month}/${_tanggal.year}',
              ),
              onTap: _pilihTanggal,
            ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pilihWaktu(true),
                    child: Text('Mulai ${_mulai.format(context)}'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pilihWaktu(false),
                    child: Text('Selesai ${_selesai.format(context)}'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                ),
                onPressed: _simpan,
                child: const Text('Simpan'),
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