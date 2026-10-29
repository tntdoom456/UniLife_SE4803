import 'package:flutter/material.dart';

class MaterialsPage extends StatelessWidget {
  const MaterialsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Materi & Tugas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Cari Materi',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fitur Pencarian')),
              );
            },
          ),
        ],
      ),
      // Tombol FAB utama untuk membuka kamera eksternal nantinya
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blueAccent,
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Buka Kamera untuk Scan Tugas')),
          );
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
            Expanded(
              // GridView untuk menampilkan daftar file seperti galeri/folder
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // 2 kolom
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.85,
                ),
                itemCount: 4, // Data dummy statis
                itemBuilder: (context, index) {
                  // Membedakan UI antara file PDF dan Foto/JPG
                  final isPdf = index.isEven; 
                  return Card(
                    color: const Color(0xFF2A2A2A),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                    child: InkWell(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Membuka file materi $index...')),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isPdf ? Icons.picture_as_pdf : Icons.image,
                            size: 64,
                            color: isPdf ? Colors.redAccent : Colors.greenAccent,
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text(
                              isPdf ? 'Slide_Pertemuan_${index + 1}.pdf' : 'Catatan_Papan_${index + 1}.jpg',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 14, color: Colors.white70),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
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