import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class ScheduleDataSource extends CalendarDataSource {
  ScheduleDataSource(List<Appointment> data) {
    appointments = data;
  }
}

class ConflictDetail {
  final Appointment existingAppointment;
  final List<DateTime> conflictDates;

  ConflictDetail({
    required this.existingAppointment,
    required this.conflictDates,
  });
}

class ScheduleController extends GetxController {
  // Daftar jadwal utama (dipakai juga oleh HomePage & WellnessPage)
  var jadwal = <Appointment>[].obs;
  var isLoading = true.obs;

  // DataSource ter-cache: hanya berubah saat jadwal/filter berubah, BUKAN saat zoom
  var calendarDataSource = ScheduleDataSource(const []).obs;

  static const List<String> defaultCategories = [
    'Kuliah',
    'Rapat',
    'Organisasi',
    'Tugas',
    'Lainnya',
  ];

  var categories = <String>[
    'Kuliah',
    'Rapat',
    'Organisasi',
    'Tugas',
    'Lainnya',
  ].obs;

  var customCategoryColors = <String, int>{}.obs;
  var selectedCategoryFilter = 'Semua'.obs;

  var timeIntervalHeight = 60.0.obs;
  var showFilterBar = true.obs;

  final Set<String> _conflictingSlotKeys = <String>{};

  static const List<Color> customColorPalette = [
    Colors.cyan,
    Colors.amber,
    Colors.indigoAccent,
    Colors.lightGreen,
    Colors.deepOrangeAccent,
    Colors.purpleAccent,
  ];

  @override
  void onInit() {
    super.onInit();
    _initData();
  }

  Future<void> _initData() async {
    await muatKategoriKustom();
    await muatJadwal();
  }

  // MANAJEMEN TAG / KATEGORI
  Color getCategoryColor(String? category) {
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
        return Colors.blueGrey;
      default:
        if (category != null && customCategoryColors.containsKey(category)) {
          return Color(customCategoryColors[category]!);
        }
        return Colors.pinkAccent;
    }
  }

  IconData getCategoryIcon(String? category) {
    switch (category) {
      case 'Kuliah':
        return Icons.school_rounded;
      case 'Rapat':
        return Icons.groups_rounded;
      case 'Organisasi':
        return Icons.handshake_rounded;
      case 'Tugas':
        return Icons.assignment_rounded;
      case 'Lainnya':
        return Icons.label_outline_rounded;
      default:
        return Icons.local_offer_rounded;
    }
  }

  bool isDefaultCategory(String cat) => defaultCategories.contains(cat);

  void setCategoryFilter(String cat) {
    if (selectedCategoryFilter.value == cat) return;
    selectedCategoryFilter.value = cat;
    _perbaruiDataSource();
  }

  void _perbaruiDataSource() {
    calendarDataSource.value = ScheduleDataSource(filteredJadwal);
  }

  Future<void> muatKategoriKustom() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedTags = prefs.getStringList('daftar_tag_kustom') ?? [];
      final savedColorsRaw = prefs.getString('warna_tag_kustom');

      if (savedColorsRaw != null) {
        final decoded = Map<String, dynamic>.from(jsonDecode(savedColorsRaw));
        customCategoryColors.value =
            decoded.map((k, v) => MapEntry(k, (v as num).toInt()));
      }

      final merged = <String>[...defaultCategories];
      for (final tag in savedTags) {
        if (!merged.contains(tag)) {
          merged.add(tag);
        }
      }
      categories.value = merged;
    } catch (e) {
      debugPrint('Gagal memuat tag kustom: $e');
    }
  }

  Future<bool> tambahKategoriKustom(String namaTag, Color warna) async {
    final clean = namaTag.trim();
    if (clean.isEmpty) return false;

    final sudahAda =
        categories.any((c) => c.toLowerCase() == clean.toLowerCase());
    if (sudahAda) {
      Get.snackbar('Perhatian', 'Tag "$clean" sudah ada.');
      return false;
    }

    categories.add(clean);
    customCategoryColors[clean] = warna.toARGB32();
    categories.refresh();
    customCategoryColors.refresh();

    final prefs = await SharedPreferences.getInstance();
    final customOnly =
        categories.where((c) => !defaultCategories.contains(c)).toList();
    await prefs.setStringList('daftar_tag_kustom', customOnly);
    await prefs.setString(
      'warna_tag_kustom',
      jsonEncode(customCategoryColors),
    );
    return true;
  }

  Future<void> hapusKategoriKustom(String namaTag) async {
    if (defaultCategories.contains(namaTag)) return;

    categories.remove(namaTag);
    customCategoryColors.remove(namaTag);
    if (selectedCategoryFilter.value == namaTag) {
      selectedCategoryFilter.value = 'Semua';
      _perbaruiDataSource();
    }
    categories.refresh();
    customCategoryColors.refresh();

    final prefs = await SharedPreferences.getInstance();
    final customOnly =
        categories.where((c) => !defaultCategories.contains(c)).toList();
    await prefs.setStringList('daftar_tag_kustom', customOnly);
    await prefs.setString(
      'warna_tag_kustom',
      jsonEncode(customCategoryColors),
    );
  }

  // FORMAT TANGGAL & ATURAN PERULANGAN VALID
  static const List<String> _namaHari = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  static const List<String> _namaBulanSingkat = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];

  static const List<String> _rruleWeekDays = [
    'MO',
    'TU',
    'WE',
    'TH',
    'FR',
    'SA',
    'SU',
  ];

  static String? buildRecurrenceRule(
    String freq,
    DateTime startTime,
    int count,
  ) {
    if (freq == 'NONE') return null;
    final countPart = count > 0 ? ';COUNT=$count' : '';
    switch (freq) {
      case 'DAILY':
        return 'FREQ=DAILY;INTERVAL=1$countPart';
      case 'WEEKLY':
        final dayCode = _rruleWeekDays[startTime.weekday - 1];
        return 'FREQ=WEEKLY;INTERVAL=1;BYDAY=$dayCode$countPart';
      case 'MONTHLY':
        return 'FREQ=MONTHLY;BYMONTHDAY=${startTime.day};INTERVAL=1$countPart';
      default:
        return null;
    }
  }

  static String? normalizeRecurrenceRule(String? rule, DateTime startTime) {
    if (rule == null || rule.trim().isEmpty) return null;
    String fixed = rule.trim();

    if (fixed.contains('FREQ=WEEKLY') && !fixed.contains('BYDAY=')) {
      final dayCode = _rruleWeekDays[startTime.weekday - 1];
      fixed = '$fixed;BYDAY=$dayCode';
    } else if (fixed.contains('FREQ=MONTHLY') &&
        !fixed.contains('BYMONTHDAY=') &&
        !fixed.contains('BYDAY=')) {
      fixed = '$fixed;BYMONTHDAY=${startTime.day}';
    }
    return fixed;
  }

  static String formatTanggalLengkap(DateTime dt) {
    final hari = _namaHari[dt.weekday - 1];
    final bulan = _namaBulanSingkat[dt.month - 1];
    return '$hari, ${dt.day} $bulan ${dt.year}';
  }

  static String formatRelatifHariIni(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(dt.year, dt.month, dt.day);
    final diff = target.difference(today).inDays;

    if (diff == 0) return 'Hari Ini';
    if (diff == 1) return 'Besok';
    if (diff == -1) return 'Kemarin';
    if (diff > 1) return '$diff hari lagi';
    return '${diff.abs()} hari lalu';
  }

  static String describeRecurrence(String? rule, {DateTime? startTime}) {
    if (rule == null || rule.isEmpty) return 'Tidak berulang (Sekali saja)';

    final hari = startTime != null ? _namaHari[startTime.weekday - 1] : '';
    String freqText = 'Berulang';
    if (rule.contains('FREQ=DAILY')) {
      freqText = 'Setiap Hari';
    } else if (rule.contains('FREQ=WEEKLY')) {
      freqText = hari.isNotEmpty ? 'Setiap hari $hari' : 'Setiap Minggu';
    } else if (rule.contains('FREQ=MONTHLY')) {
      freqText =
          startTime != null ? 'Setiap tgl ${startTime.day}' : 'Setiap Bulan';
    }

    final countMatch = RegExp(r'COUNT=(\d+)').firstMatch(rule);
    final countText =
        countMatch != null ? '${countMatch.group(1)}x' : 'Terus-menerus';

    if (startTime != null) {
      return '$freqText ($countText), mulai ${formatTanggalLengkap(startTime)}';
    }
    return '$freqText ($countText)';
  }

  static DateTime? estimateEndDate(DateTime start, String freq, int count) {
    if (freq == 'NONE' || count <= 0) return null;
    final steps = count - 1;
    switch (freq) {
      case 'DAILY':
        return DateTime(start.year, start.month, start.day + steps);
      case 'WEEKLY':
        return DateTime(start.year, start.month, start.day + (steps * 7));
      case 'MONTHLY':
        return DateTime(start.year, start.month + steps, start.day);
      default:
        return null;
    }
  }

  // FILTER & KONTROL ZOOM
  List<Appointment> get filteredJadwal {
    if (selectedCategoryFilter.value == 'Semua') {
      return jadwal.toList();
    }
    return jadwal
        .where((j) => (j.notes ?? 'Lainnya') == selectedCategoryFilter.value)
        .toList();
  }

  void zoomIn() {
    timeIntervalHeight.value =
        (timeIntervalHeight.value + 15.0).clamp(30.0, 140.0);
  }

  void zoomOut() {
    timeIntervalHeight.value =
        (timeIntervalHeight.value - 15.0).clamp(30.0, 140.0);
  }

  void setZoomHeight(double height) {
    final clamped = height.clamp(30.0, 140.0);
    if ((clamped - timeIntervalHeight.value).abs() >= 4.0) {
      timeIntervalHeight.value = clamped;
    }
  }

  void resetZoom() {
    timeIntervalHeight.value = 60.0;
  }

  void toggleFilterBar() {
    showFilterBar.value = !showFilterBar.value;
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
        bool perluSimpanUlang = false;

        jadwal.value = daftar.asMap().entries.map((entry) {
          final item = Map<String, dynamic>.from(entry.value);
          final category = item['kategori'] ?? 'Lainnya';
          final startTime = DateTime.parse(item['mulai']);
          var endTime = DateTime.parse(item['selesai']);
          if (!endTime.isAfter(startTime)) {
            endTime = startTime.add(const Duration(hours: 1));
            perluSimpanUlang = true;
          }

          final rawRule = item['recurrenceRule']?.toString();
          final cleanRule = normalizeRecurrenceRule(rawRule, startTime);
          if (cleanRule != rawRule) {
            perluSimpanUlang = true;
          }

          return Appointment(
            id: item['id']?.toString() ?? 'sch_${entry.key}_${item['mulai']}',
            startTime: startTime,
            endTime: endTime,
            subject: item['nama'] ?? '',
            location: item['lokasi'] ?? '',
            notes: category,
            color: getCategoryColor(category),
            recurrenceRule: cleanRule,
          );
        }).toList();

        if (perluSimpanUlang) {
          await simpanKeLokal();
        }
      } else {
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
            recurrenceRule: buildRecurrenceRule('WEEKLY', mulai, 16),
          ),
        ];
        await simpanKeLokal();
      }
      _perbaruiCacheBentrok();
      _perbaruiDataSource();
    } catch (e) {
      debugPrint('Gagal memuat jadwal: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> simpanKeLokal() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jadwal.map((j) {
      return {
        'id': j.id?.toString() ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        'nama': j.subject,
        'lokasi': j.location ?? '',
        'kategori': j.notes ?? 'Lainnya',
        'mulai': j.startTime.toIso8601String(),
        'selesai': j.endTime.toIso8601String(),
        'recurrenceRule':
            (j.recurrenceRule?.isEmpty ?? true) ? null : j.recurrenceRule,
      };
    }).toList();
    await prefs.setString('daftar_jadwal', jsonEncode(data));
  }

  Appointment findMasterAppointment(Appointment tapped) {
    return jadwal.firstWhere(
      (j) =>
          (j.id != null &&
              (j.id == tapped.id || j.id == tapped.recurrenceId)) ||
          (j.subject == tapped.subject &&
              j.location == tapped.location &&
              j.notes == tapped.notes &&
              j.recurrenceRule == tapped.recurrenceRule &&
              j.startTime.hour == tapped.startTime.hour &&
              j.startTime.minute == tapped.startTime.minute),
      orElse: () => tapped,
    );
  }

  // DETEKSI BENTROK
  String _makeSlotKey(Object? idOrSubject, DateTime startTime) {
    return '$idOrSubject|${startTime.year}-${startTime.month}-${startTime.day}-${startTime.hour}-${startTime.minute}';
  }

  int _dateKey(DateTime dt) => dt.year * 10000 + dt.month * 100 + dt.day;

  void _perbaruiCacheBentrok() {
    _conflictingSlotKeys.clear();
    if (jadwal.length < 2) return;

    final List<(Appointment, Map<int, List<(DateTime, DateTime)>>)> byDateList =
        [];

    for (final j in jadwal) {
      final occs = _generateOccurrences(
        j.startTime,
        j.endTime,
        j.recurrenceRule,
        maxUnlimited: 26,
      );
      final Map<int, List<(DateTime, DateTime)>> mapByDate = {};
      for (final occ in occs) {
        mapByDate.putIfAbsent(_dateKey(occ.$1), () => []).add(occ);
      }
      byDateList.add((j, mapByDate));
    }

    for (int i = 0; i < byDateList.length; i++) {
      final (a, mapA) = byDateList[i];
      final keyA = a.id ?? a.subject;

      for (int k = i + 1; k < byDateList.length; k++) {
        final (b, mapB) = byDateList[k];
        final keyB = b.id ?? b.subject;

        final aStartMin = a.startTime.hour * 60 + a.startTime.minute;
        final aEndMin = a.endTime.hour * 60 + a.endTime.minute;
        final bStartMin = b.startTime.hour * 60 + b.startTime.minute;
        final bEndMin = b.endTime.hour * 60 + b.endTime.minute;
        if (!(aStartMin < bEndMin && aEndMin > bStartMin)) continue;

        final smaller = mapA.length <= mapB.length ? mapA : mapB;
        final larger = mapA.length <= mapB.length ? mapB : mapA;

        for (final dateKey in smaller.keys) {
          if (!larger.containsKey(dateKey)) continue;
          final listA = mapA[dateKey]!;
          final listB = mapB[dateKey]!;

          for (final (sA, eA) in listA) {
            for (final (sB, eB) in listB) {
              if (sA.isBefore(eB) && eA.isAfter(sB)) {
                _conflictingSlotKeys.add(_makeSlotKey(keyA, sA));
                _conflictingSlotKeys.add(_makeSlotKey(a.subject, sA));
                _conflictingSlotKeys.add(_makeSlotKey(keyB, sB));
                _conflictingSlotKeys.add(_makeSlotKey(b.subject, sB));
              }
            }
          }
        }
      }
    }
  }

  bool isSlotBentrokCepat(Appointment rendered) {
    if (_conflictingSlotKeys.isEmpty) return false;
    final keyId = rendered.recurrenceId ?? rendered.id ?? rendered.subject;
    return _conflictingSlotKeys
            .contains(_makeSlotKey(keyId, rendered.startTime)) ||
        _conflictingSlotKeys
            .contains(_makeSlotKey(rendered.subject, rendered.startTime));
  }

  List<(DateTime, DateTime)> _generateOccurrences(
    DateTime start,
    DateTime end,
    String? rule, {
    int maxUnlimited = 52,
  }) {
    final duration = end.difference(start);
    if (rule == null || rule.isEmpty) {
      return [(start, end)];
    }

    String freq = 'NONE';
    if (rule.contains('FREQ=DAILY')) {
      freq = 'DAILY';
    } else if (rule.contains('FREQ=WEEKLY')) {
      freq = 'WEEKLY';
    } else if (rule.contains('FREQ=MONTHLY')) {
      freq = 'MONTHLY';
    } else {
      return [(start, end)];
    }

    final countMatch = RegExp(r'COUNT=(\d+)').firstMatch(rule);
    final limit = countMatch != null
        ? (int.tryParse(countMatch.group(1)!) ?? 1).clamp(1, 365)
        : (freq == 'DAILY' ? 90 : maxUnlimited);

    final result = <(DateTime, DateTime)>[];
    for (int i = 0; i < limit; i++) {
      DateTime occStart;
      if (freq == 'DAILY') {
        occStart = DateTime(
          start.year,
          start.month,
          start.day + i,
          start.hour,
          start.minute,
        );
      } else if (freq == 'WEEKLY') {
        occStart = DateTime(
          start.year,
          start.month,
          start.day + (i * 7),
          start.hour,
          start.minute,
        );
      } else {
        occStart = DateTime(
          start.year,
          start.month + i,
          start.day,
          start.hour,
          start.minute,
        );
      }
      result.add((occStart, occStart.add(duration)));
    }
    return result;
  }

  bool _jadwalHadirPadaSlot(
    Appointment j,
    DateTime slotStart,
    DateTime slotEnd,
  ) {
    final rule = j.recurrenceRule ?? '';

    if (rule.isEmpty) {
      return slotStart.isBefore(j.endTime) && slotEnd.isAfter(j.startTime);
    }

    final slotDate = DateTime(slotStart.year, slotStart.month, slotStart.day);
    final jDate = DateTime(j.startTime.year, j.startTime.month, j.startTime.day);
    if (slotDate.isBefore(jDate)) return false;

    int? occIndex;
    if (rule.contains('FREQ=DAILY')) {
      occIndex = slotDate.difference(jDate).inDays;
    } else if (rule.contains('FREQ=WEEKLY')) {
      final diffDays = slotDate.difference(jDate).inDays;
      if (diffDays % 7 != 0) return false;
      occIndex = diffDays ~/ 7;
    } else if (rule.contains('FREQ=MONTHLY')) {
      if (slotDate.day != jDate.day) return false;
      occIndex =
          (slotDate.year - jDate.year) * 12 + (slotDate.month - jDate.month);
    }

    if (occIndex == null || occIndex < 0) return false;

    final countMatch = RegExp(r'COUNT=(\d+)').firstMatch(rule);
    if (countMatch != null) {
      final maxCount = int.tryParse(countMatch.group(1)!) ?? 0;
      if (maxCount > 0 && occIndex >= maxCount) return false;
    }

    final duration = j.endTime.difference(j.startTime);
    final jOccStart = DateTime(
      slotDate.year,
      slotDate.month,
      slotDate.day,
      j.startTime.hour,
      j.startTime.minute,
    );
    final jOccEnd = jOccStart.add(duration);

    return slotStart.isBefore(jOccEnd) && slotEnd.isAfter(jOccStart);
  }

  List<ConflictDetail> cariJadwalBentrok(
    DateTime mulai,
    DateTime selesai, {
    Appointment? kecuali,
    String? recurrenceRuleBaru,
  }) {
    final masterKecuali =
        kecuali != null ? findMasterAppointment(kecuali) : null;

    final candidateOccs = _generateOccurrences(
      mulai,
      selesai,
      recurrenceRuleBaru,
    );

    final conflicts = <ConflictDetail>[];

    for (final existing in jadwal) {
      if (masterKecuali != null &&
          (identical(existing, masterKecuali) ||
              (existing.id != null && existing.id == masterKecuali.id))) {
        continue;
      }

      final matchedDates = <DateTime>[];
      for (final (cStart, cEnd) in candidateOccs) {
        if (_jadwalHadirPadaSlot(existing, cStart, cEnd)) {
          matchedDates.add(cStart);
        }
      }

      if (matchedDates.isNotEmpty) {
        conflicts.add(
          ConflictDetail(
            existingAppointment: existing,
            conflictDates: matchedDates,
          ),
        );
      }
    }

    return conflicts;
  }

  List<Appointment> getBentrokPadaSlot(Appointment rendered) {
    final master = findMasterAppointment(rendered);
    return jadwal.where((other) {
      if (identical(other, master) ||
          (other.id != null && other.id == master.id)) {
        return false;
      }
      return _jadwalHadirPadaSlot(other, rendered.startTime, rendered.endTime);
    }).toList();
  }

  Future<void> tambahAtauEditJadwal(
    Appointment baru, {
    Appointment? lama,
  }) async {
    final safeAppt = Appointment(
      id: baru.id,
      startTime: baru.startTime,
      endTime: baru.endTime,
      subject: baru.subject,
      location: baru.location,
      notes: baru.notes,
      color: baru.color,
      recurrenceRule:
          normalizeRecurrenceRule(baru.recurrenceRule, baru.startTime),
    );

    if (lama != null) {
      final master = findMasterAppointment(lama);
      final index = jadwal.indexOf(master);
      if (index != -1) {
        jadwal[index] = safeAppt;
      } else {
        jadwal.add(safeAppt);
      }
    } else {
      jadwal.add(safeAppt);
    }

    _perbaruiCacheBentrok();
    _perbaruiDataSource();
    jadwal.refresh();
    await simpanKeLokal();
  }

  Future<void> hapusJadwal(Appointment hapus) async {
    final master = findMasterAppointment(hapus);
    jadwal.remove(master);
    _perbaruiCacheBentrok();
    _perbaruiDataSource();
    jadwal.refresh();
    await simpanKeLokal();
  }
}