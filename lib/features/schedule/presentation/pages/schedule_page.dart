import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import '../../controllers/schedule_controller.dart';

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
            // Navigasi diganti menggunakan GetX sesuai dengan rute baru
            onPressed: () => Get.toNamed('/map'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _tampilkanFormJadwal(context),
        child: const Icon(Icons.add),
      ),
      // Obx akan otomatis me-render ulang SfCalendar ketika nilai jadwal atau isLoading berubah
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        return SfCalendar(
          view: CalendarView.workWeek,
          firstDayOfWeek: 1,
          timeSlotViewSettings: const TimeSlotViewSettings(
            startHour: 7,
            endHour: 22,
            timeFormat: 'HH:mm',
            timeTextStyle: TextStyle(color: Colors.white),
          ),
          dataSource: _ScheduleDataSource(controller.jadwal.toList()),
          onTap: (details) {
            if (details.appointments?.isNotEmpty == true) {
              _detailJadwal(context, details.appointments!.first as Appointment);
            }
          },
        );
      }),
    );
  }

  // Fungsi untuk menampilkan form tambah atau edit jadwal
  Future<void> _tampilkanFormJadwal(BuildContext context, {Appointment? lama}) async {
    final nama = TextEditingController(text: lama?.subject ?? '');
    final lokasi = TextEditingController(text: lama?.location ?? '');

    DateTime tanggal = lama?.startTime ?? DateTime.now();

    TimeOfDay mulai = TimeOfDay.fromDateTime(
      lama?.startTime ?? DateTime(tanggal.year, tanggal.month, tanggal.day, 8),
    );

    TimeOfDay selesai = TimeOfDay.fromDateTime(
      lama?.endTime ?? DateTime(tanggal.year, tanggal.month, tanggal.day, 10),
    );

    try {
      final hasil = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        builder: (sheetContext) {
          return StatefulBuilder(
            builder: (contextSheet, ubah) {
              Future<void> pilihTanggal() async {
                final hasil = await showDatePicker(
                  context: contextSheet,
                  initialDate: tanggal,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );

                if (hasil != null) {
                  ubah(() => tanggal = hasil);
                }
              }

              Future<void> pilihWaktu(bool isMulai) async {
                final hasil = await showTimePicker(
                  context: contextSheet,
                  initialTime: isMulai ? mulai : selesai,
                );

                if (hasil != null) {
                  ubah(() {
                    if (isMulai) {
                      mulai = hasil;
                    } else {
                      selesai = hasil;
                    }
                  });
                }
              }

              return Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  24,
                  16,
                  MediaQuery.of(contextSheet).viewInsets.bottom + 24,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        lama == null ? 'Tambah Jadwal' : 'Edit Jadwal',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: nama,
                        decoration: const InputDecoration(
                          labelText: 'Nama kegiatan',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: lokasi,
                        decoration: const InputDecoration(
                          labelText: 'Lokasi',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.calendar_month),
                        title: const Text('Tanggal'),
                        subtitle: Text(
                          '${tanggal.day}/${tanggal.month}/${tanggal.year}',
                        ),
                        onTap: pilihTanggal,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => pilihWaktu(true),
                              child: Text(
                                'Mulai ${mulai.format(contextSheet)}',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => pilihWaktu(false),
                              child: Text(
                                'Selesai ${selesai.format(contextSheet)}',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            final awal = DateTime(
                              tanggal.year,
                              tanggal.month,
                              tanggal.day,
                              mulai.hour,
                              mulai.minute,
                            );

                            final akhir = DateTime(
                              tanggal.year,
                              tanggal.month,
                              tanggal.day,
                              selesai.hour,
                              selesai.minute,
                            );

                            String? error;

                            if (nama.text.trim().isEmpty) {
                              error = 'Nama kegiatan wajib diisi!';
                            } else if (!akhir.isAfter(awal)) {
                              error = 'Waktu selesai harus setelah waktu mulai!';
                            } else if (controller.jadwalBentrok(
                              awal,
                              akhir,
                              kecuali: lama,
                            )) {
                              error = 'Jadwal bentrok dengan kegiatan lain!';
                            }

                            if (error != null) {
                              await showDialog(
                                context: sheetContext,
                                builder: (dialogContext) => AlertDialog(
                                  title: const Text('Tidak dapat menyimpan jadwal'),
                                  content: Text(error!),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(dialogContext);
                                      },
                                      child: const Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                              return;
                            }

                            Navigator.pop(sheetContext, true);
                          },
                          child: const Text('Simpan'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );

      if (hasil == true) {
        final awal = DateTime(
          tanggal.year,
          tanggal.month,
          tanggal.day,
          mulai.hour,
          mulai.minute,
        );

        final akhir = DateTime(
          tanggal.year,
          tanggal.month,
          tanggal.day,
          selesai.hour,
          selesai.minute,
        );

        final baru = Appointment(
          startTime: awal,
          endTime: akhir,
          subject: nama.text.trim(),
          location: lokasi.text.trim(),
          color: lama?.color ?? Colors.blueAccent,
        );

        // Memanggil logika penyimpanan di dalam controller
        await controller.tambahAtauEditJadwal(baru, lama: lama);
        
        Get.snackbar(
          'Sukses', 
          lama == null ? 'Jadwal berhasil ditambahkan' : 'Jadwal berhasil diperbarui'
        );
      }
    } finally {
      nama.dispose();
      lokasi.dispose();
    }
  }

  // Fungsi untuk menampilkan detail jadwal yang di-tap
  void _detailJadwal(BuildContext context, Appointment jadwal) {
    showModalBottomSheet(
      context: context,
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
                    onPressed: () {
                      _konfirmasiHapusJadwal(context, jadwal);
                    },
                    child: const Text('Hapus'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _konfirmasiHapusJadwal(BuildContext context, Appointment jadwal) async {
    final yakin = await showDialog<bool>(
      context: context,
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
      // Memanggil fungsi hapus dari controller, state management GetX akan merender ulang kalender otomatis
      controller.hapusJadwal(jadwal);
      Navigator.pop(context); // Tutup bottom sheet
      Get.snackbar('Berhasil', 'Jadwal berhasil dihapus');
    }
  }

  String _format(DateTime waktu) =>
      '${waktu.hour.toString().padLeft(2, '0')}:'
      '${waktu.minute.toString().padLeft(2, '0')}';
}

class _ScheduleDataSource extends CalendarDataSource {
  _ScheduleDataSource(List<Appointment> data) {
    appointments = data;
  }
}