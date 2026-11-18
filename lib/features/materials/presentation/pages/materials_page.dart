import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as path;

import '../controllers/materials_controller.dart';
import 'camera_page.dart';

class MaterialsPage extends GetView<MaterialsController> {
  const MaterialsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Materi & Tugas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.create_new_folder_outlined),
            tooltip: 'Buat Folder Baru',
            onPressed: () => _tampilkanDialogBuatFolder(context),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blueAccent,
        onPressed: () => _ambilFotoMateri(context),
        icon: const Icon(Icons.camera_alt, color: Colors.white),
        label: const Text('Scan Materi', style: TextStyle(color: Colors.white)),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER FOLDER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Folder Mata Kuliah',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    onPressed: () => _tampilkanDialogBuatFolder(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Folder Baru'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // GRID FOLDER
              if (controller.savedFolders.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text('Belum ada folder. Buat folder mata kuliah baru.'),
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 1.15,
                  ),
                  itemCount: controller.savedFolders.length,
                  itemBuilder: (context, index) {
                    final folderName = controller.savedFolders[index];
                    final count = controller.getPhotoCountInFolder(folderName);
                    return _buildFolderCard(context, folderName, count);
                  },
                ),

              const SizedBox(height: 28),

              // BAGIAN FOTO YANG BELUM MASUK FOLDER
              const Text(
                'Materi Belum Masuk Folder',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'Ketuk ikon folder pada foto untuk memindahkannya ke mata kuliah terkait.',
                style: TextStyle(fontSize: 12, color: Colors.white54),
              ),
              const SizedBox(height: 12),

              if (controller.unorganizedPhotos.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.check_circle_outline, color: Colors.green, size: 32),
                      SizedBox(height: 8),
                      Text(
                        'Semua materi sudah rapi di dalam folder.',
                        style: TextStyle(color: Colors.white60),
                      ),
                    ],
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: controller.unorganizedPhotos.length,
                  itemBuilder: (context, index) {
                    final photo = controller.unorganizedPhotos[index];
                    return _buildPhotoCard(context, photo);
                  },
                ),

              const SizedBox(height: 80), // Ruang untuk FAB
            ],
          ),
        );
      }),
    );
  }

  Widget _buildFolderCard(BuildContext context, String folderName, int count) {
    return Card(
      color: const Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          controller.loadPhotosInFolder(folderName);
          Get.to(() => FolderDetailPage(folderName: folderName));
        },
        onLongPress: () => _konfirmasiHapusFolder(context, folderName),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.folder_rounded, size: 52, color: Colors.amber),
              const SizedBox(height: 8),
              Text(
                folderName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                '$count File',
                style: const TextStyle(fontSize: 12, color: Colors.white54),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoCard(BuildContext context, File photo) {
    final fileName = path.basename(photo.path);
    return Card(
      color: const Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => Get.to(() => PhotoPreviewPage(photoFile: photo)),
              child: Image.file(photo, fit: BoxFit.cover),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    fileName,
                    style: const TextStyle(fontSize: 11, color: Colors.white70),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.drive_file_move_outline, size: 20, color: Colors.blueAccent),
                  tooltip: 'Pindahkan ke Folder',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => _tampilkanDialogPindahFolder(context, photo),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                  tooltip: 'Hapus',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => controller.deletePhoto(photo),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Ambil foto dari halaman utama dan tanyakan ingin disimpan ke folder mana
  Future<void> _ambilFotoMateri(BuildContext context) async {
    final savedPath = await Get.to<String>(() => const CameraPage());
    if (savedPath != null) {
      await controller.loadSavedFoldersAndPhotos();
      if (controller.savedFolders.isNotEmpty && context.mounted) {
        _tampilkanDialogPindahFolder(context, File(savedPath));
      } else {
        Get.snackbar('Sukses', 'Foto materi berhasil disimpan.');
      }
    }
  }

  void _tampilkanDialogBuatFolder(BuildContext context) {
    final folderController = TextEditingController();
    Get.defaultDialog(
      title: 'Buat Folder Mata Kuliah',
      content: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: TextField(
          controller: folderController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Contoh: Struktur Data',
            border: OutlineInputBorder(),
          ),
        ),
      ),
      textConfirm: 'Buat',
      textCancel: 'Batal',
      confirmTextColor: Colors.white,
      onConfirm: () {
        final name = folderController.text.trim();
        if (name.isNotEmpty) {
          controller.createNewFolder(name);
          Get.back();
        } else {
          Get.snackbar('Error', 'Nama folder tidak boleh kosong');
        }
      },
    );
  }

  void _tampilkanDialogPindahFolder(BuildContext context, File photoFile) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Simpan ke Folder Mata Kuliah',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...controller.savedFolders.map((folder) {
              return ListTile(
                leading: const Icon(Icons.folder, color: Colors.amber),
                title: Text(folder),
                onTap: () {
                  Navigator.pop(ctx);
                  controller.movePhotoToFolder(photoFile, folder);
                  Get.snackbar('Berhasil', 'Materi dipindahkan ke folder $folder');
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _konfirmasiHapusFolder(BuildContext context, String folderName) {
    Get.defaultDialog(
      title: 'Hapus Folder?',
      middleText: 'Seluruh foto di dalam folder "$folderName" juga akan terhapus.',
      textConfirm: 'Hapus',
      textCancel: 'Batal',
      confirmTextColor: Colors.white,
      buttonColor: Colors.redAccent,
      onConfirm: () {
        controller.deleteFolder(folderName);
        Get.back();
      },
    );
  }
}

class FolderDetailPage extends GetView<MaterialsController> {
  final String folderName;

  const FolderDetailPage({super.key, required this.folderName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(folderName),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blueAccent,
        onPressed: () async {
          // Ambil foto dan langsung masukkan ke dalam folder ini
          final savedPath = await Get.to<String>(() => const CameraPage());
          if (savedPath != null) {
            await controller.movePhotoToFolder(File(savedPath), folderName);
            Get.snackbar('Sukses', 'Materi ditambahkan ke folder $folderName');
          }
        },
        icon: const Icon(Icons.add_a_photo, color: Colors.white),
        label: const Text('Tambah Materi', style: TextStyle(color: Colors.white)),
      ),
      body: Obx(() {
        final photos = controller.currentFolderPhotos;

        if (photos.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.folder_open, size: 64, color: Colors.white38),
                SizedBox(height: 12),
                Text(
                  'Folder ini masih kosong.\nTekan tombol "Tambah Materi" untuk memotret catatan.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white60),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 0.8,
          ),
          itemCount: photos.length,
          itemBuilder: (context, index) {
            final photo = photos[index];
            final fileName = path.basename(photo.path);

            return Card(
              color: const Color(0xFF2A2A2A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Get.to(() => PhotoPreviewPage(photoFile: photo)),
                      child: Image.file(photo, fit: BoxFit.cover),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            fileName,
                            style: const TextStyle(fontSize: 11, color: Colors.white70),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                          visualDensity: VisualDensity.compact,
                          onPressed: () => controller.deletePhoto(
                            photo,
                            currentFolder: folderName,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      }),
    );
  }
}

class PhotoPreviewPage extends StatelessWidget {
  final File photoFile;

  const PhotoPreviewPage({super.key, required this.photoFile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(path.basename(photoFile.path)),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.8,
          maxScale: 4.0,
          child: Image.file(photoFile),
        ),
      ),
    );
  }
}