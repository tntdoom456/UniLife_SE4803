import 'dart:io';
import 'package:get/get.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class MaterialsController extends GetxController {
  // Daftar nama folder mata kuliah
  var savedFolders = <String>[].obs;

  // Semua foto (di luar maupun di dalam folder) untuk statistik di HomePage
  var savedPhotos = <File>[].obs;

  // Foto di direktori utama yang belum dimasukkan ke dalam folder
  var unorganizedPhotos = <File>[].obs;

  // Foto di dalam folder yang sedang dibuka
  var currentFolderPhotos = <File>[].obs;

  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadSavedFoldersAndPhotos();
  }

  Future<Directory> _getBaseMaterialsDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    final baseDir = Directory(path.join(directory.path, 'scanned_materials'));
    if (!await baseDir.exists()) {
      await baseDir.create(recursive: true);
    }
    return baseDir;
  }

  Future<void> loadSavedFoldersAndPhotos() async {
    isLoading.value = true;
    try {
      final baseDir = await _getBaseMaterialsDirectory();
      final entities = baseDir.listSync();

      // Buat folder default jika pertama kali dijalankan dan masih kosong sama sekali
      if (entities.isEmpty) {
        for (final defaultFolder in ['Pemrograman Bergerak', 'Basis Data', 'Jaringan Komputer']) {
          final dir = Directory(path.join(baseDir.path, defaultFolder));
          if (!await dir.exists()) await dir.create();
        }
      }

      final updatedEntities = baseDir.listSync();

      // 1. Ambil daftar folder
      final folders = updatedEntities
          .whereType<Directory>()
          .map((dir) => path.basename(dir.path))
          .toList();
      folders.sort();
      savedFolders.value = folders;

      // 2. Ambil foto yang masih di luar folder (unorganized)
      final rootFiles = updatedEntities
          .whereType<File>()
          .where((f) => _isImageFile(f.path))
          .toList();
      rootFiles.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      unorganizedPhotos.value = rootFiles;

      // 3. Hitung seluruh foto (termasuk di dalam sub-folder) untuk statistik HomePage
      final allFiles = baseDir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => _isImageFile(f.path))
          .toList();
      savedPhotos.value = allFiles;
    } finally {
      isLoading.value = false;
    }
  }

  bool _isImageFile(String filePath) {
    final lower = filePath.toLowerCase();
    return lower.endsWith('.jpg') || lower.endsWith('.jpeg') || lower.endsWith('.png');
  }

  // Memuat daftar foto khusus di dalam suatu folder
  Future<void> loadPhotosInFolder(String folderName) async {
    final baseDir = await _getBaseMaterialsDirectory();
    final folderDir = Directory(path.join(baseDir.path, folderName));
    if (!await folderDir.exists()) {
      currentFolderPhotos.clear();
      return;
    }

    final files = folderDir
        .listSync()
        .whereType<File>()
        .where((f) => _isImageFile(f.path))
        .toList();
    files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    currentFolderPhotos.value = files;
  }

  // Menghitung jumlah file di dalam suatu folder untuk ditampilkan di UI
  int getPhotoCountInFolder(String folderName) {
    return savedPhotos.where((file) {
      final parentFolder = path.basename(file.parent.path);
      return parentFolder == folderName;
    }).length;
  }

  // Membuat folder baru
  Future<void> createNewFolder(String folderName) async {
    try {
      final baseDir = await _getBaseMaterialsDirectory();
      final newDir = Directory(path.join(baseDir.path, folderName));

      if (!await newDir.exists()) {
        await newDir.create();
        await loadSavedFoldersAndPhotos();
        Get.snackbar('Sukses', 'Folder "$folderName" berhasil dibuat.');
      } else {
        Get.snackbar('Perhatian', 'Folder "$folderName" sudah ada.');
      }
    } catch (e) {
      Get.snackbar('Error', 'Gagal membuat folder: $e');
    }
  }

  // Menghapus folder beserta isinya
  Future<void> deleteFolder(String folderName) async {
    try {
      final baseDir = await _getBaseMaterialsDirectory();
      final dir = Directory(path.join(baseDir.path, folderName));
      if (await dir.exists()) {
        await dir.delete(recursive: true);
        await loadSavedFoldersAndPhotos();
        Get.snackbar('Terhapus', 'Folder "$folderName" berhasil dihapus.');
      }
    } catch (e) {
      Get.snackbar('Error', 'Gagal menghapus folder: $e');
    }
  }

  // Memindahkan foto (dari hasil kamera atau dari luar folder) ke dalam folder tujuan
  Future<void> movePhotoToFolder(File photoFile, String targetFolder) async {
    try {
      final baseDir = await _getBaseMaterialsDirectory();
      final folderDir = Directory(path.join(baseDir.path, targetFolder));
      if (!await folderDir.exists()) {
        await folderDir.create(recursive: true);
      }

      final newPath = path.join(folderDir.path, path.basename(photoFile.path));
      await photoFile.copy(newPath);
      await photoFile.delete();

      await loadSavedFoldersAndPhotos();
      await loadPhotosInFolder(targetFolder);
    } catch (e) {
      Get.snackbar('Error', 'Gagal memindahkan materi: $e');
    }
  }

  // Menghapus 1 foto materi
  Future<void> deletePhoto(File photoFile, {String? currentFolder}) async {
    try {
      if (await photoFile.exists()) {
        await photoFile.delete();
      }
      await loadSavedFoldersAndPhotos();
      if (currentFolder != null) {
        await loadPhotosInFolder(currentFolder);
      }
      Get.snackbar('Terhapus', 'File materi berhasil dihapus.');
    } catch (e) {
      Get.snackbar('Error', 'Gagal menghapus file: $e');
    }
  }
}