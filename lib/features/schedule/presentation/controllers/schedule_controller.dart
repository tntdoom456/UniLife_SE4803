import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class ScheduleController extends GetxController {
  // Daftar jadwal utama (dipakai juga oleh HomePage & WellnessPage)
  var jadwal = <Appointment>[].obs;
  var isLoading = true.obs;

  // Filter kategori aktif di halaman Jadwal
  var selectedCategoryFilter = 'Semua'.obs;

  // Kontrol Zoom & Ukuran Tampilan Kalender
  var timeIntervalHeight = 60.0.obs; // Rentang: 30.0 (kecil) s/d 120.0 (besar)
  var isCompactMode = false.obs;

  // Controller bawaan Syncfusion agar posisi tanggal & view tidak reset saat zoom
  late final CalendarController calendarController;

  // Daftar kategori kegiatan beserta warna khasnya
  static const List<String> categories = [
    'Kuliah',
    'Rapat',
    'Organisasi',
    'Tugas',
    'Lainnya',
  ];

  @override
  void onInit() {
    super.onInit();
    final now = DateTime.now();
    calendarController = CalendarController()
      ..view = CalendarView.workWeek
      // Buka tampilan awal di sekitar jam 07:00 agar langsung fokus ke jam aktif,
      // namun tetap bisa di-scroll penuh dari 00:00 sampai 24:00
      ..displayDate = DateTime(now.year, now.month, now.day, 7, 0);
    muatJadwal();
  }

  @override
  void onClose() {
    calendarController.dispose();
    super.onClose();
  }

  // Warna otomatis berdasarkan kategori
  static Color getCategoryColor(String? category) {
    switch (category) {
      case 'Kuliah':
        return Colors.deepPurpleAccent;
      case 'Rapat':
        return Colors.blueAccent;
      case 'Organisasi':
        return Colors.teal;
      case 'Tugas':
        return Colors.orangeAccent;
      case 'Lainnya':
        return Colors.pinkAccent;
      default:
        return Colors.blueAccent;
    }
  }

  static IconData getCategoryIcon(String? category) {
    switch (category) {
      case 'Kuliah':
        return Icons.school_rounded;
      case 'Rapat':
        return Icons.groups_rounded;
      case 'Organisasi':
        return Icons.handshake_rounded;
      case 'Tugas':
        return Icons.assignment_rounded;
      default:
        return Icons.event_note_rounded;
    }
  }

  // Label ramah pengguna untuk aturan pengulangan (Recurrence Rule)
  static String describeRecurrence(String? rule) {
    if (rule == null || rule.isEmpty) return 'Tidak berulang (Sekali saja)';

    String freqText = 'Berulang';
    if (rule.contains('FREQ=DAILY')) {
      freqText = 'Setiap Hari';
    } else if (rule.contains('FREQ=WEEKLY')) {
      freqText = 'Setiap Minggu';
    } else if (rule.contains('FREQ=MONTHLY')) {
      freqText = 'Setiap Bulan';
    }

    final countMatch = RegExp(r'COUNT=(\d+)').firstMatch(rule);
    if (countMatch != null) {
      return '$freqText (${countMatch.group(1)}x)';
    }
    return '\$freqText (Terus-menerus)';
  }

  // Daftar jadwal yang sudah difilter sesuai chip kategori yang dipilih
  List<Appointment> get filteredJadwal {
    if (selectedCategoryFilter.value == 'Semua') {
      return jadwal.toList();
    }
    return jadwal
        .where((j) => (j.notes ?? 'Kuliah') == selectedCategoryFilter.value)
        .toList();
  }

  void zoomIn() {
    if (timeIntervalHeight.value < 120.0) {
      timeIntervalHeight.value = (timeIntervalHeight.value + 15.0).clamp(30.0, 120.0);
    }
  }

  void zoomOut() {
    if (timeIntervalHeight.value > 30.0) {
      timeIntervalHeight.value = (timeIntervalHeight.value - 15.0).clamp(30.0, 120.0);
    }
  }

  void resetZoom() {
    timeIntervalHeight.value = 60.0;
  }

  void toggleCompactMode() {
    isCompactMode.value = !isCompactMode.value;
  }

  int get zoomPercentage => ((timeIntervalHeight.value / 60.0) * 100).round();

  // PENYIMPANAN & PEMUATAN DATA (SHARED PREFERENCES)
  Future<void> muatJadwal() async {
    isLoading.value = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('daftar_jadwal');

      if (data != null) {
        final daftar = jsonDecode(data) as List;
        jadwal.value = daftar.asMap().entries.map((entry) {
          final item = Map<String, dynamic>.from(entry.value);
          final category = item['kategori'] ?? 'Kuliah';
          return Appointment(
            id: item['id']?.toString() ?? 'sch_${entry.key}_${item['mulai']}',
            startTime: DateTime.parse(item['mulai']),
            endTime: DateTime.parse(item['selesai']),
            subject: item['nama'] ?? '',
            location: item['lokasi'] ?? '',
            notes: category,
            color: getCategoryColor(category),
            recurrenceRule: item['recurrenceRule'],
          );
        }).toList();
      } else {
        // Data awal: 1 contoh jadwal kuliah berulang setiap minggu (16 pertemuan)
        final hariIni = DateTime.now();
        final mulai = DateTime(hariIni.year, hariIni.month, hariIni.day, 8, 0);
        jadwal.value = [
          Appointment(
            id: 'default_ppb',
            startTime: mulai,
            endTime: mulai.add(const Duration(hours: 2)),
            subject: 'Pemrograman Perangkat Bergerak',
            location: 'Gedung TULT 06.01',
            notes: 'Kuliah',
            color: getCategoryColor('Kuliah'),
            recurrenceRule: 'FREQ=WEEKLY;INTERVAL=1;COUNT=16',
          ),
        ];
        await simpanKeLokal();
      }
    } catch (e) {
      debugPrint('Gagal memuat jadwal: \$e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> simpanKeLokal() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jadwal.map((j) {
      return {
        'id': j.id?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
        'nama': j.subject,
        'lokasi': j.location ?? '',
        'kategori': j.notes ?? 'Kuliah',
        'mulai': j.startTime.toIso8601String(),
        'selesai': j.endTime.toIso8601String(),
        'recurrenceRule': j.recurrenceRule,
      };
    }).toList();
    await prefs.setString('daftar_jadwal', jsonEncode(data));
  }

  // Mencari jadwal induk (master) saat pengguna mengetuk kejadian berulang di minggu lain
  Appointment findMasterAppointment(Appointment tapped) {
    return jadwal.firstWhere(
      (j) =>
          (j.id != null && (j.id == tapped.id || j.id == tapped.recurrenceId)) ||
          (j.subject == tapped.subject &&
              j.location == tapped.location &&
              j.notes == tapped.notes &&
              j.recurrenceRule == tapped.recurrenceRule &&
              j.startTime.hour == tapped.startTime.hour &&
              j.startTime.minute == tapped.startTime.minute),
      orElse: () => tapped,
    );
  }

  // DETEKSI JADWAL BENTROK
  bool jadwalBentrok(
    DateTime mulai,
    DateTime selesai, {
    Appointment? kecuali,
    String? recurrenceRuleBaru,
  }) {
    final masterKecuali =
        kecuali != null ? findMasterAppointment(kecuali) : null;

    final startMinBaru = mulai.hour * 60 + mulai.minute;
    final endMinBaru = selesai.hour * 60 + selesai.minute;

    return jadwal.any((j) {
      if (masterKecuali != null &&
          (identical(j, masterKecuali) ||
              (j.id != null && j.id == masterKecuali.id))) {
        return false;
      }

      final startMinLama = j.startTime.hour * 60 + j.startTime.minute;
      final endMinLama = j.endTime.hour * 60 + j.endTime.minute;
      final jamBentrok = startMinBaru < endMinLama && endMinBaru > startMinLama;

      if (!jamBentrok) return false;

      // 1. Cek tanggal persis sama
      final tanggalSama = j.startTime.year == mulai.year &&
          j.startTime.month == mulai.month &&
          j.startTime.day == mulai.day;
      if (tanggalSama) return true;

      // 2. Cek bentrok dengan jadwal lama yang bersifat repetitif
      final ruleLama = j.recurrenceRule ?? '';
      final setelahMulaiLama = !DateTime(mulai.year, mulai.month, mulai.day)
          .isBefore(DateTime(j.startTime.year, j.startTime.month, j.startTime.day));

      if (ruleLama.isNotEmpty && setelahMulaiLama) {
        if (ruleLama.contains('FREQ=DAILY')) return true;
        if (ruleLama.contains('FREQ=WEEKLY') &&
            j.startTime.weekday == mulai.weekday) {
          return true;
        }
        if (ruleLama.contains('FREQ=MONTHLY') && j.startTime.day == mulai.day) {
          return true;
        }
      }

      // 3. Cek jika jadwal baru bersifat repetitif dan menabrak jadwal lama di hari yang sama
      final ruleBaru = recurrenceRuleBaru ?? '';
      final setelahMulaiBaru =
          !DateTime(j.startTime.year, j.startTime.month, j.startTime.day)
              .isBefore(DateTime(mulai.year, mulai.month, mulai.day));

      if (ruleBaru.isNotEmpty && setelahMulaiBaru) {
        if (ruleBaru.contains('FREQ=DAILY')) return true;
        if (ruleBaru.contains('FREQ=WEEKLY') &&
            j.startTime.weekday == mulai.weekday) {
          return true;
        }
        if (ruleBaru.contains('FREQ=MONTHLY') && j.startTime.day == mulai.day) {
          return true;
        }
      }

      return false;
    });
  }

  Future<void> tambahAtauEditJadwal(
    Appointment baru, {
    Appointment? lama,
  }) async {
    if (lama != null) {
      final master = findMasterAppointment(lama);
      final index = jadwal.indexOf(master);
      if (index != -1) {
        jadwal[index] = baru;
      } else {
        jadwal.add(baru);
      }
    } else {
      jadwal.add(baru);
    }

    jadwal.refresh();
    await simpanKeLokal();
  }

  Future<void> hapusJadwal(Appointment hapus) async {
    final master = findMasterAppointment(hapus);
    jadwal.remove(master);
    jadwal.refresh();
    await simpanKeLokal();
  }
}