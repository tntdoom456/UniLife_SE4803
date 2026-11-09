import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class ScheduleController extends GetxController {
  // Variabel observable untuk state management GetX
  var jadwal = <Appointment>[].obs;
  var isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    muatJadwal();
  }

  // Memuat data dari SharedPreferences
  Future<void> muatJadwal() async {
    isLoading.value = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('daftar_jadwal');

      if (data != null) {
        final daftar = jsonDecode(data) as List;
        jadwal.value = daftar.map((item) {
          return Appointment(
            startTime: DateTime.parse(item['mulai']),
            endTime: DateTime.parse(item['selesai']),
            subject: item['nama'],
            location: item['lokasi'],
            color: Colors.blueAccent,
          );
        }).toList();
      } else {
        // Data default jika kosong
        final hariIni = DateTime.now();
        final mulai = DateTime(hariIni.year, hariIni.month, hariIni.day, 8, 0);
        jadwal.value = [
          Appointment(
            startTime: mulai,
            endTime: mulai.add(const Duration(hours: 2)),
            subject: 'Pemrograman Perangkat Bergerak',
            location: 'Gedung TULT 06.01',
            color: Colors.deepPurple,
          )
        ];
        await simpanKeLokal();
      }
    } catch (e) {
      debugPrint('Gagal memuat jadwal: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Menyimpan seluruh daftar jadwal ke SharedPreferences
  Future<void> simpanKeLokal() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jadwal.map((j) {
      return {
        'nama': j.subject,
        'lokasi': j.location ?? '',
        'mulai': j.startTime.toIso8601String(),
        'selesai': j.endTime.toIso8601String(),
      };
    }).toList();
    await prefs.setString('daftar_jadwal', jsonEncode(data));
  }

  // 1. Memeriksa apakah ada jadwal yang bertabrakan di jam yang sama
  bool jadwalBentrok(DateTime mulai, DateTime selesai, {Appointment? kecuali}) {
    return jadwal.any((j) {
      if (identical(j, kecuali)) return false; // Abaikan jadwal yang sedang diedit
      
      final tanggalSama = j.startTime.year == mulai.year &&
          j.startTime.month == mulai.month && 
          j.startTime.day == mulai.day;
          
      return tanggalSama && mulai.isBefore(j.endTime) && selesai.isAfter(j.startTime);
    });
  }

  // 2. Menambah jadwal baru atau menyimpan hasil editan jadwal lama
  Future<void> tambahAtauEditJadwal(Appointment baru, {Appointment? lama}) async {
    if (lama != null) {
      // Mode Edit
      final index = jadwal.indexOf(lama);
      if (index != -1) {
        jadwal[index] = baru;
      }
    } else {
      // Mode Tambah Baru
      jadwal.add(baru);
    }
    
    // Refresh agar Obx di antarmuka merender ulang daftar
    jadwal.refresh(); 
    await simpanKeLokal();
  }

  // Menghapus jadwal tertentu
  Future<void> hapusJadwal(Appointment hapus) async {
    jadwal.remove(hapus);
    await simpanKeLokal();
  }
}