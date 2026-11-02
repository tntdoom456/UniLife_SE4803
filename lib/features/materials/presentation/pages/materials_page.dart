import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:unilife/features/materials/presentation/pages/camera_page.dart';

// StatefulWidget digunakan karena daftar foto bisa berubah
// ketika pengguna menambahkan atau menghapus materi.
class MaterialsPage extends StatefulWidget {
  const MaterialsPage({super.key});

  @override
  State<MaterialsPage> createState() => _MaterialsPageState();
}

class _MaterialsPageState extends State<MaterialsPage> {
  // Menyimpan daftar file foto yang berhasil ditemukan.
  List<File> _savedPhotos = [];

  @override
  void initState() {
    super.initState();

    // Memuat foto yang sudah tersimpan ketika halaman dibuka.
    _loadSavedPhotos();
  }

  // Fungsi untuk membaca foto dari penyimpanan lokal aplikasi.
  Future<void> _loadSavedPhotos() async {
    // Mengambil lokasi folder dokumen milik aplikasi.
    final directory = await getApplicationDocumentsDirectory();

    // Folder khusus untuk menyimpan hasil scan materi.
    final scanDirectory = Directory(
      path.join(directory.path, 'scanned_materials'),
    );

    // Membuat folder jika sebelumnya belum tersedia.
    if (!await scanDirectory.exists()) {
      await scanDirectory.create(recursive: true);
    }

    // Membaca semua file JPG yang ada di dalam folder.
    final files = scanDirectory
        .listSync()
        .whereType<File>()
        .where((file) => file.path.toLowerCase().endsWith('.jpg'))
        .toList();

    // Memastikan halaman masih aktif sebelum memperbarui tampilan.
    if (!mounted) return;

    // Memperbarui daftar foto agar tampil di halaman.
    setState(() {
      _savedPhotos = files;
    });
  }

  // Fungsi untuk menghapus foto dari penyimpanan lokal.
  Future<void> _deletePhoto(File photo) async {
    try {
      // Menghapus file foto secara permanen.
      await photo.delete();

      // Memuat ulang daftar foto setelah penghapusan.
      await _loadSavedPhotos();

      if (!mounted) return;

      // Memberikan informasi bahwa foto berhasil dihapus.
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Foto berhasil dihapus')));
    } catch (e) {
      if (!mounted) return;

      // Menampilkan pesan jika proses penghapusan gagal.
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal menghapus foto: $e')));
    }
  }

  // Fungsi untuk menampilkan konfirmasi sebelum menghapus foto.
  Future<void> _confirmDeletePhoto(File photo) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Hapus Foto?'),
          content: const Text('Apakah kamu yakin ingin menghapus foto ini?'),
          actions: [
            // Tombol untuk membatalkan penghapusan.
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Batal'),
            ),

            // Tombol untuk menyetujui penghapusan.
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Hapus', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    // Menghapus foto jika pengguna memilih Hapus.
    if (shouldDelete == true && mounted) {
      await _deletePhoto(photo);
    }
  }

  // Fungsi untuk menampilkan foto dalam ukuran lebih besar.
  void _showPhotoDetail(File photo) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Menampilkan foto yang dipilih.
              Image.file(photo, fit: BoxFit.contain),

              // Tombol tindakan pada tampilan detail foto.
              Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Tombol untuk menghapus foto.
                    TextButton(
                      onPressed: () async {
                        // Menutup dialog detail terlebih dahulu.
                        Navigator.pop(dialogContext);

                        // Menampilkan konfirmasi penghapusan.
                        await _confirmDeletePhoto(photo);
                      },
                      child: const Text(
                        'Hapus',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),

                    // Tombol untuk menutup tampilan foto.
                    TextButton(
                      onPressed: () {
                        Navigator.pop(dialogContext);
                      },
                      child: const Text('Tutup'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Materi & Tugas'),
        actions: [
          // Tombol pencarian materi.
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Cari Materi',
            onPressed: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Fitur Pencarian')));
            },
          ),
        ],
      ),

      // Tombol untuk membuka halaman kamera.
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blueAccent,
        onPressed: () async {
          // Membuka halaman kamera dan menunggu hasil foto.
          final savedPath = await Navigator.push<String>(
            context,
            MaterialPageRoute(builder: (context) => const CameraPage()),
          );

          // Memastikan halaman masih aktif.
          if (!context.mounted) return;

          // Memuat ulang daftar foto setelah kembali dari kamera.
          await _loadSavedPhotos();

          // Menampilkan notifikasi jika foto berhasil disimpan.
          if (savedPath != null && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Foto berhasil disimpan'),
                duration: Duration(seconds: 2),
              ),
            );
          }
        },
        icon: const Icon(Icons.camera_alt, color: Colors.white),
        label: const Text('Scan Materi', style: TextStyle(color: Colors.white)),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'File Tersimpan (Lokal)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            // Jika belum ada foto, tampilkan pesan.
            // Jika sudah ada foto, tampilkan dalam bentuk grid.
            Expanded(
              child: _savedPhotos.isEmpty
                  ? const Center(
                      child: Text(
                        'Belum ada materi tersimpan.\n'
                        'Tekan Scan Materi untuk mengambil foto.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70),
                      ),
                    )
                  : GridView.builder(
                      // Mengatur tampilan daftar foto menjadi dua kolom.
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.85,
                          ),

                      // Jumlah tampilan mengikuti jumlah foto tersimpan.
                      itemCount: _savedPhotos.length,

                      itemBuilder: (context, index) {
                        // Mengambil foto sesuai posisi pada daftar.
                        final photo = _savedPhotos[index];

                        return Card(
                          color: const Color(0xFF2A2A2A),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),

                            // Membuka tampilan detail ketika foto ditekan.
                            onTap: () {
                              _showPhotoDetail(photo);
                            },

                            child: Column(
                              children: [
                                // Menampilkan gambar dari penyimpanan lokal.
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(16),
                                    ),
                                    child: Image.file(
                                      photo,
                                      width: double.infinity,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),

                                // Menampilkan nama file foto.
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Text(
                                    path.basename(photo.path),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
