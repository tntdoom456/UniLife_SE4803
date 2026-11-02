import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key});

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  List<Appointment> _jadwal = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _muatJadwal();
  }

  // Membaca jadwal dari penyimpanan lokal.
  Future<void> _muatJadwal() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('daftar_jadwal');

      if (data != null) {
        final daftar = jsonDecode(data) as List;

        _jadwal = daftar.map((item) {
          return Appointment(
            startTime: DateTime.parse(item['mulai']),
            endTime: DateTime.parse(item['selesai']),
            subject: item['nama'],
            location: item['lokasi'],
            color: Colors.blueAccent,
          );
        }).toList();
      } else {
        final hariIni = DateTime.now();
        final mulai = DateTime(hariIni.year, hariIni.month, hariIni.day, 8, 0);

        _jadwal = [
          Appointment(
            startTime: mulai,
            endTime: mulai.add(const Duration(hours: 2)),
            subject: 'Pemrograman Perangkat Bergerak',
            location: 'Gedung TULT 06.01',
            color: Colors.deepPurple,
          ),
          Appointment(
            startTime: mulai.add(const Duration(hours: 3)),
            endTime: mulai.add(const Duration(hours: 4)),
            subject: 'Rapat Himpunan',
            location: 'Sekre Himpunan',
            color: Colors.blueAccent,
          ),
        ];

        await _simpanJadwal();
      }
    } catch (e) {
      debugPrint('Gagal memuat jadwal: $e');
    }

    if (mounted) {
      setState(() => _loading = false);
    }
  }

  // Menyimpan jadwal ke SharedPreferences.
  Future<void> _simpanJadwal() async {
    final prefs = await SharedPreferences.getInstance();

    final data = _jadwal.map((j) {
      return {
        'nama': j.subject,
        'lokasi': j.location ?? '',
        'mulai': j.startTime.toIso8601String(),
        'selesai': j.endTime.toIso8601String(),
      };
    }).toList();

    await prefs.setString('daftar_jadwal', jsonEncode(data));
  }

  // Memeriksa bentrok jadwal pada tanggal yang sama.
  bool _jadwalBentrok(
    DateTime mulai,
    DateTime selesai, {
    Appointment? kecuali,
  }) {
    return _jadwal.any((j) {
      if (identical(j, kecuali)) return false;

      final tanggalSama =
          j.startTime.year == mulai.year &&
          j.startTime.month == mulai.month &&
          j.startTime.day == mulai.day;

      return tanggalSama &&
          mulai.isBefore(j.endTime) &&
          selesai.isAfter(j.startTime);
    });
  }

  // Form tambah dan edit jadwal.
  Future<void> _formJadwal({Appointment? lama}) async {
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
                              error =
                                  'Waktu selesai harus setelah waktu mulai!';
                            } else if (_jadwalBentrok(
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
                                  title: const Text(
                                    'Tidak dapat menyimpan jadwal',
                                  ),
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

      if (hasil == true && mounted) {
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

        final daftarBaru = List<Appointment>.from(_jadwal);

        if (lama != null) {
          final index = daftarBaru.indexOf(lama);

          if (index != -1) {
            daftarBaru[index] = baru;
          }
        } else {
          daftarBaru.add(baru);
        }

        try {
          final prefs = await SharedPreferences.getInstance();

          final data = daftarBaru.map((j) {
            return {
              'nama': j.subject,
              'lokasi': j.location ?? '',
              'mulai': j.startTime.toIso8601String(),
              'selesai': j.endTime.toIso8601String(),
            };
          }).toList();

          await prefs.setString('daftar_jadwal', jsonEncode(data));

          if (!mounted) return;

          setState(() {
            _jadwal = daftarBaru;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                lama == null
                    ? 'Jadwal berhasil ditambahkan'
                    : 'Jadwal berhasil diperbarui',
              ),
            ),
          );
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Gagal menyimpan jadwal: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } finally {
      nama.dispose();
      lokasi.dispose();
    }
  }

  // Menghapus jadwal.
  Future<void> _hapusJadwal(Appointment jadwal) async {
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

    if (yakin == true && mounted) {
      final daftarBaru = List<Appointment>.from(_jadwal)..remove(jadwal);

      try {
        final prefs = await SharedPreferences.getInstance();

        final data = daftarBaru.map((j) {
          return {
            'nama': j.subject,
            'lokasi': j.location ?? '',
            'mulai': j.startTime.toIso8601String(),
            'selesai': j.endTime.toIso8601String(),
          };
        }).toList();

        await prefs.setString('daftar_jadwal', jsonEncode(data));

        if (!mounted) return;

        setState(() => _jadwal = daftarBaru);

        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Jadwal berhasil dihapus')),
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Gagal menghapus jadwal: $e')));
        }
      }
    }
  }

  // Menampilkan detail jadwal.
  void _detailJadwal(Appointment jadwal) {
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
                      _formJadwal(lama: jadwal);
                    },
                    child: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _hapusJadwal(jadwal),
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

  String _format(DateTime waktu) =>
      '${waktu.hour.toString().padLeft(2, '0')}:'
      '${waktu.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Jadwal Kegiatan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.map_outlined),
            onPressed: () => context.push('/map'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _formJadwal(),
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SfCalendar(
              view: CalendarView.workWeek,
              firstDayOfWeek: 1,
              timeSlotViewSettings: const TimeSlotViewSettings(
                startHour: 7,
                endHour: 22,
                timeFormat: 'HH:mm',
              ),
              dataSource: _ScheduleDataSource(_jadwal),
              onTap: (details) {
                if (details.appointments?.isNotEmpty == true) {
                  _detailJadwal(details.appointments!.first as Appointment);
                }
              },
            ),
    );
  }
}

class _ScheduleDataSource extends CalendarDataSource {
  _ScheduleDataSource(List<Appointment> jadwal) {
    appointments = jadwal;
  }
}
