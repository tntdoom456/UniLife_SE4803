
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

// StatefulWidget digunakan karena halaman kamera memiliki
// kondisi yang berubah, seperti proses loading dan kamera aktif.
class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  // Controller digunakan untuk mengatur dan mengakses kamera.
  CameraController? _controller;

  // Menampung daftar kamera yang tersedia pada perangkat.
  List<CameraDescription> _cameras = [];

  // Menandakan apakah kamera masih dalam proses persiapan.
  bool _isLoading = true;

  // Menyimpan pesan jika terjadi kesalahan saat membuka kamera.
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    // Menjalankan inisialisasi kamera saat halaman dibuka.
    _initializeCamera();
  }

  // Fungsi untuk mencari dan mengaktifkan kamera perangkat.
  Future<void> _initializeCamera() async {
    try {
      // Mengambil daftar kamera yang tersedia.
      _cameras = await availableCameras();

      // Memeriksa apakah perangkat memiliki kamera.
      if (_cameras.isEmpty) {
        throw Exception('Kamera tidak ditemukan');
      }

      // Memprioritaskan kamera belakang jika tersedia.
      // Jika tidak ada, gunakan kamera pertama yang ditemukan.
      final selectedCamera = _cameras.firstWhere(
        (camera) =>
            camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );

      // Membuat controller dengan kualitas gambar medium.
      _controller = CameraController(
        selectedCamera,
        ResolutionPreset.medium,
      );

      // Menunggu sampai kamera selesai diinisialisasi.
      await _controller!.initialize();

      // Memeriksa apakah halaman masih aktif.
      if (!mounted) return;

      // Mengubah status loading agar tampilan kamera muncul.
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      // Menyimpan pesan kesalahan jika kamera gagal dibuka.
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  // Fungsi untuk mengambil dan menyimpan foto.
  Future<void> _takePicture() async {
    // Memastikan kamera sudah siap digunakan.
    if (_controller == null ||
        !_controller!.value.isInitialized) {
      return;
    }

    try {
      // Mengambil foto menggunakan kamera.
      final XFile photo = await _controller!.takePicture();

      // Mendapatkan folder dokumen milik aplikasi.
      final directory = await getApplicationDocumentsDirectory();

      // Membuat folder khusus untuk menyimpan hasil scan.
      final scanDirectory = Directory(
        path.join(directory.path, 'scanned_materials'),
      );

      // Membuat folder jika belum tersedia.
      if (!await scanDirectory.exists()) {
        await scanDirectory.create(recursive: true);
      }

      // Membuat nama file berdasarkan waktu pengambilan foto.
      // Tujuannya agar nama setiap foto berbeda.
      final fileName =
          'materi_${DateTime.now().millisecondsSinceEpoch}.jpg';

      // Menentukan lokasi lengkap penyimpanan foto.
      final savedPath = path.join(
        scanDirectory.path,
        fileName,
      );

      // Menyalin hasil foto ke folder penyimpanan aplikasi.
      await photo.saveTo(savedPath);

      // Memastikan halaman masih aktif sebelum kembali.
      if (!mounted) return;

      // Mengembalikan lokasi foto ke halaman Materials.
      Navigator.pop(context, savedPath);
    } catch (e) {
      // Menampilkan pesan jika proses mengambil atau
      // menyimpan foto mengalami kegagalan.
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan foto: $e'),
        ),
      );
    }
  }

  @override
  void dispose() {
    // Melepaskan penggunaan kamera ketika halaman ditutup.
    // Hal ini penting agar kamera tidak terus berjalan.
    _controller?.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Materi'),
      ),

      // Menampilkan tampilan berdasarkan kondisi kamera.
      body: _isLoading
          // Tampilan loading saat kamera sedang disiapkan.
          ? const Center(
              child: CircularProgressIndicator(),
            )

          // Menampilkan pesan jika kamera mengalami kesalahan.
          : _errorMessage != null
              ? Center(
                  child: Text(_errorMessage!),
                )

              // Menampilkan kamera jika sudah siap digunakan.
              : Column(
                  children: [
                    Expanded(
                      child: CameraPreview(_controller!),
                    ),

                    // Tombol untuk mengambil foto.
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: FloatingActionButton(
                        onPressed: _takePicture,
                        child: const Icon(Icons.camera_alt),
                      ),
                    ),
                  ],
                ),
    );
  }
}
