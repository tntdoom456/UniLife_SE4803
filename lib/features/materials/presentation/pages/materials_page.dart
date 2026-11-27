import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:open_filex/open_filex.dart';
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
              // HEADER FOLDER & TOMBOL + UPLOAD MATERI
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Folder Mata Kuliah',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      final files = await controller.pickAndUploadFiles();
                      if (files.isNotEmpty) {
                        Get.snackbar(
                          'Sukses',
                          '${files.length} file materi berhasil diunggah.',
                        );
                      }
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Upload Materi'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // GRID FOLDER MATA KULIAH
              if (controller.savedFolders.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Text('Belum ada folder. Ketuk ikon folder di atas untuk membuat.'),
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
                    final count = controller.getFileCountInFolder(folderName);
                    return _buildFolderCard(context, folderName, count);
                  },
                ),

              // PEMISAH TANPA TEKS JUDUL UNTUK FILE YANG BELUM MASUK FOLDER
              if (controller.unorganizedFiles.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Divider(color: Colors.white24, thickness: 1),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.78,
                  ),
                  itemCount: controller.unorganizedFiles.length,
                  itemBuilder: (context, index) {
                    final file = controller.unorganizedFiles[index];
                    return _buildFileCard(
                      context,
                      file,
                      onMove: () => _tampilkanDialogPindahFolder(context, file),
                      onRename: () => _tampilkanDialogRenameFile(context, file),
                      onDelete: () => controller.deleteFile(file),
                    );
                  },
                ),
              ],

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
          controller.loadFilesInFolder(folderName);
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

  // Kartu untuk merender semua jenis file (Foto, PDF, Word, Excel, Video, Audio, dll.)
  static Widget _buildFileCard(
    BuildContext context,
    File file, {
    VoidCallback? onMove,
    required VoidCallback onRename,
    required VoidCallback onDelete,
  }) {
    final controller = Get.find<MaterialsController>();
    final fileName = path.basename(file.path);
    final isImage = controller.isImageFile(file.path);

    return Card(
      color: const Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: InkWell(
              onTap: () => _bukaFile(file, isImage),
              child: isImage
                  ? Image.file(file, fit: BoxFit.cover)
                  : _buildNonImagePreview(file.path),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 6, 4, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.amber),
                      tooltip: 'Ubah Nama',
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                      onPressed: onRename,
                    ),
                    if (onMove != null)
                      IconButton(
                        icon: const Icon(
                          Icons.drive_file_move_outline,
                          size: 18,
                          color: Colors.blueAccent,
                        ),
                        tooltip: 'Pindahkan ke Folder',
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                        onPressed: onMove,
                      ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                      tooltip: 'Hapus',
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                      onPressed: onDelete,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildNonImagePreview(String filePath) {
    final ext = path.extension(filePath).toLowerCase();
    IconData icon;
    Color color;
    String label = ext.replaceFirst('.', '').toUpperCase();

    if (ext == '.pdf') {
      icon = Icons.picture_as_pdf_rounded;
      color = Colors.redAccent;
    } else if (['.doc', '.docx'].contains(ext)) {
      icon = Icons.description_rounded;
      color = Colors.blueAccent;
    } else if (['.xls', '.xlsx', '.csv'].contains(ext)) {
      icon = Icons.table_chart_rounded;
      color = Colors.green;
    } else if (['.ppt', '.pptx'].contains(ext)) {
      icon = Icons.slideshow_rounded;
      color = Colors.orangeAccent;
    } else if (['.mp4', '.mov', '.avi', '.mkv'].contains(ext)) {
      icon = Icons.play_circle_fill_rounded;
      color = Colors.purpleAccent;
    } else if (['.mp3', '.wav', '.m4a', '.aac'].contains(ext)) {
      icon = Icons.audiotrack_rounded;
      color = Colors.tealAccent;
    } else {
      icon = Icons.insert_drive_file_rounded;
      color = Colors.grey;
      if (label.isEmpty) label = 'FILE';
    }

    return Container(
      color: const Color(0xFF1E1E1E),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: color),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> _bukaFile(File file, bool isImage) async {
    if (isImage) {
      Get.to(() => PhotoPreviewPage(photoFile: file));
    } else {
      final result = await OpenFilex.open(file.path);
      if (result.type != ResultType.done) {
        Get.snackbar('Info', 'Tidak dapat membuka file: ${result.message}');
      }
    }
  }

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

  static void _tampilkanDialogRenameFile(
    BuildContext context,
    File file, {
    String? currentFolder,
  }) {
    final controller = Get.find<MaterialsController>();
    final currentBaseName = path.basenameWithoutExtension(file.path);
    final ext = path.extension(file.path);
    final nameController = TextEditingController(text: currentBaseName);

    Get.defaultDialog(
      title: 'Ubah Nama File',
      content: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: TextField(
          controller: nameController,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Nama File',
            suffixText: ext,
            border: const OutlineInputBorder(),
          ),
        ),
      ),
      textConfirm: 'Simpan',
      textCancel: 'Batal',
      confirmTextColor: Colors.white,
      onConfirm: () {
        final newName = nameController.text.trim();
        if (newName.isNotEmpty) {
          controller.renameFile(file, newName, currentFolder: currentFolder);
          Get.back();
        } else {
          Get.snackbar('Error', 'Nama file tidak boleh kosong');
        }
      },
    );
  }

  void _tampilkanDialogPindahFolder(BuildContext context, File file) {
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
                  controller.moveFileToFolder(file, folder);
                  Get.snackbar('Berhasil', 'File dipindahkan ke folder $folder');
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
      middleText: 'Seluruh file di dalam folder "$folderName" juga akan terhapus.',
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
        actions: [
          TextButton.icon(
            onPressed: () async {
              final files = await controller.pickAndUploadFiles(
                targetFolder: folderName,
              );
              if (files.isNotEmpty) {
                Get.snackbar(
                  'Sukses',
                  '${files.length} file ditambahkan ke $folderName',
                );
              }
            },
            icon: const Icon(Icons.add, color: Colors.blueAccent, size: 18),
            label: const Text(
              'Upload Materi',
              style: TextStyle(color: Colors.blueAccent),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.blueAccent,
        onPressed: () async {
          final savedPath = await Get.to<String>(() => const CameraPage());
          if (savedPath != null) {
            await controller.moveFileToFolder(File(savedPath), folderName);
            Get.snackbar('Sukses', 'Foto ditambahkan ke folder $folderName');
          }
        },
        icon: const Icon(Icons.camera_alt, color: Colors.white),
        label: const Text('Scan Materi', style: TextStyle(color: Colors.white)),
      ),
      body: Obx(() {
        final files = controller.currentFolderFiles;

        if (files.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.folder_open, size: 64, color: Colors.white38),
                SizedBox(height: 12),
                Text(
                  'Folder ini masih kosong.\nKetuk "+ Upload Materi" di atas atau "Scan Materi" di bawah.',
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
            childAspectRatio: 0.78,
          ),
          itemCount: files.length,
          itemBuilder: (context, index) {
            final file = files[index];
            return MaterialsPage._buildFileCard(
              context,
              file,
              onRename: () => MaterialsPage._tampilkanDialogRenameFile(
                context,
                file,
                currentFolder: folderName,
              ),
              onDelete: () => controller.deleteFile(
                file,
                currentFolder: folderName,
              ),
            );
          },
        );
      }),
    );
  }
}

// ============================================================================
// HALAMAN PREVIEW FOTO FULL SCREEN
// ============================================================================
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