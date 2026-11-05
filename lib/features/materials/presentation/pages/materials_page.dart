import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as path;
import 'package:unilife/features/materials/controllers/materials_controller.dart';

import 'camera_page.dart'; // Import Camera Page

class MaterialsPage extends GetView<MaterialsController> {
  const MaterialsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('List Materi'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blueAccent,
        onPressed: () async {
          // Buka Kamera (CameraPage bisa tetap StatefulWidget karena akses hardware langsung)
          final result = await Get.to(() => const CameraPage());
          if (result != null) {
            controller.loadSavedPhotos(); // Muat ulang dari folder
            Get.snackbar('Sukses', 'Foto disimpan');
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
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value)
                  return const Center(child: CircularProgressIndicator());
                if (controller.savedPhotos.isEmpty)
                  return const Center(child: Text('Belum ada materi.'));

                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: controller.savedPhotos.length,
                  itemBuilder: (context, index) {
                    final photo = controller.savedPhotos[index];
                    return Card(
                      color: const Color(0xFF2A2A2A),
                      child: InkWell(
                        onLongPress: () {
                          controller.deletePhoto(photo);
                          Get.snackbar('Terhapus', 'File telah dihapus');
                        },
                        child: Column(
                          children: [
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
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Text(
                                path.basename(photo.path),
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
