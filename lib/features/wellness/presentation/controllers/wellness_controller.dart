import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/quote_model.dart';

class WellnessController extends GetxController {
  // Variabel Mood (tetap bernama selectedMood agar sinkron dengan HomePage)
  var selectedMood = ''.obs;

  // Pelacak Fisik Harian
  var waterGlasses = 0.obs;
  final int targetWaterGlasses = 8; // Setara ±2 Liter

  var sleepHours = 7.0.obs;
  var sleepReminderActive = true.obs;

  // Pola Makan (Sarapan, Makan Siang, Makan Malam)
  var hadBreakfast = false.obs;
  var hadLunch = false.obs;
  var hadDinner = false.obs;

  // Catatan Harian & Riwayat
  var dailyNote = ''.obs;
  var historyLogs = <WellnessLogModel>[].obs;

  // State untuk REST API Quote
  var currentQuote = QuoteModel(
    text: 'Jangan biarkan tugas menumpuk menghalangi kebahagiaanmu hari ini. Istirahat sejenak bukanlah sebuah kegagalan.',
    author: 'Afirmasi UniLife',
  ).obs;
  var isLoadingQuote = false.obs;

  // Daftar cadangan lokal jika perangkat sedang offline (Error Handling)
  final List<QuoteModel> _fallbackQuotes = [
    QuoteModel(
      text: 'Kesehatanmu jauh lebih berharga daripada nilai sempurna. Istirahatlah sejenak agar pikiranmu kembali jernih.',
      author: 'Tips Kesehatan Kampus',
    ),
    QuoteModel(
      text: 'Produktif bukan berarti bekerja tanpa henti, melainkan tahu kapan tubuh butuh jeda dan hidrasi.',
      author: 'Afirmasi Mahasiswa',
    ),
    QuoteModel(
      text: 'Satu tugas selesai lebih baik daripada sepuluh tugas yang hanya dipikirkan dalam kecemasan.',
      author: 'Motivasi Harian',
    ),
  ];

  @override
  void onInit() {
    super.onInit();
    loadWellnessData();
    fetchDailyQuote();
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
  }

  int get wellnessScore {
    // 1. Skor Mood (Maks 25 poin)
    int moodScore = 15;
    switch (selectedMood.value) {
      case 'Semangat':
        moodScore = 25;
        break;
      case 'Senang':
        moodScore = 22;
        break;
      case 'Biasa':
        moodScore = 16;
        break;
      case 'Lelah':
        moodScore = 10;
        break;
      case 'Stres':
        moodScore = 5;
        break;
      default:
        moodScore = 12;
    }

    // 2. Skor Air Putih (Maks 25 poin)
    final waterRatio = (waterGlasses.value / targetWaterGlasses).clamp(0.0, 1.0);
    final int waterScore = (waterRatio * 25).round();

    // 3. Skor Jam Tidur (Maks 25 poin, ideal 7-9 jam)
    int sleepScore;
    if (sleepHours.value >= 7 && sleepHours.value <= 9) {
      sleepScore = 25;
    } else if (sleepHours.value >= 5 && sleepHours.value < 7) {
      sleepScore = 15;
    } else if (sleepHours.value > 9) {
      sleepScore = 18;
    } else {
      sleepScore = (sleepHours.value * 2.5).round().clamp(0, 12);
    }

    // 4. Skor Pola Makan (Maks 25 poin)
    int meals = 0;
    if (hadBreakfast.value) meals++;
    if (hadLunch.value) meals++;
    if (hadDinner.value) meals++;
    final int mealScore = ((meals / 3) * 25).round();

    return (moodScore + waterScore + sleepScore + mealScore).clamp(0, 100);
  }

  String get burnoutStatus {
    final score = wellnessScore;
    if (score >= 80) return 'Kondisi Prima (Optimal)';
    if (score >= 60) return 'Cukup Baik (Tetap Jaga Pola)';
    if (score >= 40) return 'Waspada Kelelahan';
    return 'Risiko Burnout Tinggi!';
  }

  Color get burnoutColor {
    final score = wellnessScore;
    if (score >= 80) return Colors.greenAccent;
    if (score >= 60) return Colors.blueAccent;
    if (score >= 40) return Colors.orangeAccent;
    return Colors.redAccent;
  }

  String get healthRecommendation {
    if (selectedMood.value == 'Stres' || sleepHours.value < 5) {
      return 'Tubuhmu menunjukkan tanda kelelahan tinggi. Ambil jeda 15 menit dari layar laptop dan usahakan tidur lebih awal malam ini.';
    }
    if (waterGlasses.value < 4) {
      return 'Asupan air putihmu masih kurang dari setengah target. Minum 1 gelas air sekarang agar konsentrasimu saat kuliah tetap terjaga.';
    }
    if (!hadBreakfast.value && !hadLunch.value) {
      return 'Jangan lewatkan waktu makan di tengah padatnya tugas kuliah agar tidak memicu asam lambung atau kelelahan fisik.';
    }
    return 'Keseimbangan fisik dan mentalmu sangat baik hari ini! Pertahankan pola makan, hidrasi, dan istirahatmu.';
  }

  Future<void> fetchDailyQuote() async {
    isLoadingQuote.value = true;
    try {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 6);
      final request = await client.getUrl(Uri.parse('https://dummyjson.com/quotes/random'));
      final response = await request.close();

      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final data = jsonDecode(body) as Map<String, dynamic>;
        currentQuote.value = QuoteModel.fromJson(data);
      } else {
        _useFallbackQuote();
      }
      client.close();
    } catch (_) {
      _useFallbackQuote();
    } finally {
      isLoadingQuote.value = false;
    }
  }

  void _useFallbackQuote() {
    final index = DateTime.now().second % _fallbackQuotes.length;
    currentQuote.value = _fallbackQuotes[index];
  }

  void setMood(String mood) {
    selectedMood.value = mood;
    saveDailyState();
  }

  void addWater() {
    if (waterGlasses.value < 16) {
      waterGlasses.value++;
      saveDailyState();
    }
  }

  void removeWater() {
    if (waterGlasses.value > 0) {
      waterGlasses.value--;
      saveDailyState();
    }
  }

  void updateSleepHours(double hours) {
    sleepHours.value = hours;
    saveDailyState();
  }

  void toggleSleepReminder(bool val) {
    sleepReminderActive.value = val;
    saveDailyState();
  }

  void toggleMeal(int mealIndex, bool val) {
    if (mealIndex == 0) hadBreakfast.value = val;
    if (mealIndex == 1) hadLunch.value = val;
    if (mealIndex == 2) hadDinner.value = val;
    saveDailyState();
  }

  Future<void> saveDailyCheckInLog(String noteText) async {
    dailyNote.value = noteText.trim();
    int meals = 0;
    if (hadBreakfast.value) meals++;
    if (hadLunch.value) meals++;
    if (hadDinner.value) meals++;

    final today = _todayKey();
    final newLog = WellnessLogModel(
      date: today,
      mood: selectedMood.value.isEmpty ? 'Biasa' : selectedMood.value,
      waterGlasses: waterGlasses.value,
      sleepHours: sleepHours.value,
      mealsCount: meals,
      score: wellnessScore,
      note: dailyNote.value,
    );

    // Perbarui jika hari ini sudah pernah disimpan, atau tambahkan di urutan teratas
    final existingIndex = historyLogs.indexWhere((log) => log.date == today);
    if (existingIndex != -1) {
      historyLogs[existingIndex] = newLog;
    } else {
      historyLogs.insert(0, newLog);
    }

    await saveDailyState();
    Get.snackbar(
      'Tersimpan',
      'Catatan kesehatan hari ini ($today) berhasil direkam.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  Future<void> saveDailyState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('wellness_last_date', _todayKey());
    await prefs.setString('wellness_mood', selectedMood.value);
    await prefs.setInt('wellness_water', waterGlasses.value);
    await prefs.setDouble('wellness_sleep', sleepHours.value);
    await prefs.setBool('wellness_sleep_reminder', sleepReminderActive.value);
    await prefs.setBool('wellness_breakfast', hadBreakfast.value);
    await prefs.setBool('wellness_lunch', hadLunch.value);
    await prefs.setBool('wellness_dinner', hadDinner.value);
    await prefs.setString('wellness_note', dailyNote.value);

    final historyJson = jsonEncode(historyLogs.map((e) => e.toMap()).toList());
    await prefs.setString('wellness_history', historyJson);
  }

  Future<void> loadWellnessData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedDate = prefs.getString('wellness_last_date');
    final today = _todayKey();

    sleepReminderActive.value = prefs.getBool('wellness_sleep_reminder') ?? true;

    // Muat riwayat dari hari-hari sebelumnya
    final historyRaw = prefs.getString('wellness_history');
    if (historyRaw != null) {
      final decoded = jsonDecode(historyRaw) as List;
      historyLogs.value = decoded
          .map((item) => WellnessLogModel.fromMap(Map<String, dynamic>.from(item)))
          .toList();
    }

    // Jika masih di hari yang sama, pulihkan progres hari ini
    if (savedDate == today) {
      selectedMood.value = prefs.getString('wellness_mood') ?? '';
      waterGlasses.value = prefs.getInt('wellness_water') ?? 0;
      sleepHours.value = prefs.getDouble('wellness_sleep') ?? 7.0;
      hadBreakfast.value = prefs.getBool('wellness_breakfast') ?? false;
      hadLunch.value = prefs.getBool('wellness_lunch') ?? false;
      hadDinner.value = prefs.getBool('wellness_dinner') ?? false;
      dailyNote.value = prefs.getString('wellness_note') ?? '';
    } else {
      // Reset metrik harian jika sudah berganti hari
      await prefs.setString('wellness_last_date', today);
    }
  }
}