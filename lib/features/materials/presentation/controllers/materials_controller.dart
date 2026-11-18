import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class MaterialsController extends GetxController {
  // Daftar nama folder mata kuliah
  var savedFolders = <String>[].obs;

  // Semua file materi (tetap dinamai savedPhotos agar statistik di home_page.dart tidak error)
  var savedPhotos = <File>[].obs;

  // File materi di luar folder (belum dikelompokkan)
  var unorganizedFiles = <File>[].obs;

  // File materi di dalam folder yang sedang dibuka
  var currentFolderFiles = <File>[].obs;

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

      // Buat folder awal jika direktori masih benar-benar kosong
      if (entities.isEmpty) {
        for (final defaultFolder in ['Pemrograman Bergerak', 'Basis Data', 'Jaringan Komputer']) {
          final dir = Directory(path.join(baseDir.path, defaultFolder));
          if (!await dir.exists()) await dir.create();
        }
      }

      final updatedEntities = baseDir.listSync();

      // 1. Muat daftar folder
      final folders = updatedEntities
          .whereType<Directory>()
          .map((dir) => path.basename(dir.path))
          .toList();
      folders.sort();
      savedFolders.value = folders;

      // 2. Muat semua file yang masih berada di luar folder
      final rootFiles = updatedEntities.whereType<File>().toList();
      rootFiles.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
      unorganizedFiles.value = rootFiles;

      // 3. Hitung seluruh file (di luar & di dalam folder) untuk Beranda (HomePage)
      final allFiles = baseDir.listSync(recursive: true).whereType<File>().toList();
      savedPhotos.value = allFiles;
    } finally {
      isLoading.value = false;
    }
  }

  // Memuat semua jenis file di dalam folder tertentu
  Future<void> loadFilesInFolder(String folderName) async {
    final baseDir = await _getBaseMaterialsDirectory();
    final folderDir = Directory(path.join(baseDir.path, folderName));
    if (!await folderDir.exists()) {
      currentFolderFiles.clear();
      return;
    }

    final files = folderDir.listSync().whereType<File>().toList();
    files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    currentFolderFiles.value = files;
  }

  // Menghitung jumlah file di dalam suatu folder
  int getFileCountInFolder(String folderName) {
    return savedPhotos.where((file) {
      final parentFolder = path.basename(file.parent.path);
      return parentFolder == folderName;
    }).length;
  }
  // Upload berbagai jenis file (PDF, Word, Excel, Video, Foto, Audio, dll.)
  Future<List<File>> pickAndUploadFiles({String? targetFolder}) async {
    final List<File> uploadedFiles = [];
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.any,
      );

      if (result.isEmpty) return [];

      final baseDir = await _getBaseMaterialsDirectory();
      final destinationDir = targetFolder != null
          ? Directory(path.join(baseDir.path, targetFolder))
          : baseDir;

      if (!await destinationDir.exists()) {
        await destinationDir.create(recursive: true);
      }

      for (final picked in result) {
        if (picked.path == null) continue;
        final sourceFile = File(picked.path!);
        String fileName = picked.name;
        String destPath = path.join(destinationDir.path, fileName);

        // Jika nama file sudah ada, tambahkan timestamp agar tidak menimpa file lama
        if (await File(destPath).exists()) {
          final ext = path.extension(fileName);
          final nameWithoutExt = path.basenameWithoutExtension(fileName);
          fileName = '${nameWithoutExt}_${DateTime.now().millisecondsSinceEpoch}$ext';
          destPath = path.join(destinationDir.path, fileName);
        }

        final savedFile = await sourceFile.copy(destPath);
        uploadedFiles.add(savedFile);
      }

      await loadSavedFoldersAndPhotos();
      if (targetFolder != null) {
        await loadFilesInFolder(targetFolder);
      }
    } catch (e) {
      Get.snackbar('Error', 'Gagal mengunggah file: $e');
    }
    return uploadedFiles;
  }

  // Mengubah nama file (otomatis mempertahankan ekstensi asli seperti .pdf, .mp4, .jpg)
  Future<void> renameFile(File file, String newNameInput, {String? currentFolder}) async {
    try {
      final cleanInput = newNameInput.trim();
      if (cleanInput.isEmpty) return;

      final originalExt = path.extension(file.path);
      final finalFileName = cleanInput.toLowerCase().endsWith(originalExt.toLowerCase())
          ? cleanInput
          : '$cleanInput$originalExt';

      final newPath = path.join(file.parent.path, finalFileName);

      if (newPath == file.path) return;

      if (await File(newPath).exists()) {
        Get.snackbar('Perhatian', 'File dengan nama "$finalFileName" sudah ada.');
        return;
      }

      await file.rename(newPath);
      await loadSavedFoldersAndPhotos();
      if (currentFolder != null) {
        await loadFilesInFolder(currentFolder);
      }
      Get.snackbar('Sukses', 'Nama file diubah menjadi "$finalFileName"');
    } catch (e) {
      Get.snackbar('Error', 'Gagal mengubah nama file: $e');
    }
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

  // Memindahkan file ke dalam folder tertentu
  Future<void> moveFileToFolder(File file, String targetFolder) async {
    try {
      final baseDir = await _getBaseMaterialsDirectory();
      final folderDir = Directory(path.join(baseDir.path, targetFolder));
      if (!await folderDir.exists()) {
        await folderDir.create(recursive: true);
      }

      String fileName = path.basename(file.path);
      String newPath = path.join(folderDir.path, fileName);

      if (await File(newPath).exists()) {
        final ext = path.extension(fileName);
        final nameWithoutExt = path.basenameWithoutExtension(fileName);
        fileName = '${nameWithoutExt}_${DateTime.now().millisecondsSinceEpoch}$ext';
        newPath = path.join(folderDir.path, fileName);
      }

      await file.copy(newPath);
      await file.delete();

      await loadSavedFoldersAndPhotos();
      await loadFilesInFolder(targetFolder);
    } catch (e) {
      Get.snackbar('Error', 'Gagal memindahkan file: $e');
    }
  }

  // Menghapus 1 file materi
  Future<void> deleteFile(File file, {String? currentFolder}) async {
    try {
      if (await file.exists()) {
        await file.delete();
      }
      await loadSavedFoldersAndPhotos();
      if (currentFolder != null) {
        await loadFilesInFolder(currentFolder);
      }
      Get.snackbar('Terhapus', 'File materi berhasil dihapus.');
    } catch (e) {
      Get.snackbar('Error', 'Gagal menghapus file: $e');
    }
  }

  bool isImageFile(String filePath) {
    final ext = path.extension(filePath).toLowerCase();
    return ['.jpg', '.jpeg', '.png', '.webp', '.gif', '.bmp'].contains(ext);
  }
}