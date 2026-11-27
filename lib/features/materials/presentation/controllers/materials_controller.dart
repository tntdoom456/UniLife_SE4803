import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class MaterialsController extends GetxController {
  var savedFolders = <String>[].obs;
  var savedPhotos = <File>[].obs;
  var unorganizedFiles = <File>[].obs;
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

  Future<List<File>> _sortByLastModifiedDesc(List<File> files) async {
    final entries = <(File, DateTime)>[];
    for (final f in files) {
      try {
        final modified = await f.lastModified();
        entries.add((f, modified));
      } catch (_) {
        entries.add((f, DateTime.fromMillisecondsSinceEpoch(0)));
      }
    }
    entries.sort((a, b) => b.$2.compareTo(a.$2));
    return entries.map((e) => e.$1).toList();
  }

  Future<void> loadSavedFoldersAndPhotos() async {
    isLoading.value = true;
    try {
      final baseDir = await _getBaseMaterialsDirectory();
      var entities = await baseDir.list().toList();

      if (entities.isEmpty) {
        for (final defaultFolder in [
          'Pemrograman Bergerak',
          'Basis Data',
          'Jaringan Komputer',
        ]) {
          final dir = Directory(path.join(baseDir.path, defaultFolder));
          if (!await dir.exists()) await dir.create();
        }
        entities = await baseDir.list().toList();
      }

      // 1. Daftar folder
      final folders = entities
          .whereType<Directory>()
          .map((dir) => path.basename(dir.path))
          .toList()
        ..sort();
      savedFolders.value = folders;

      // 2. File di luar folder (asinkron)
      final rootFiles = entities.whereType<File>().toList();
      unorganizedFiles.value = await _sortByLastModifiedDesc(rootFiles);

      // 3. Seluruh file secara rekursif (asinkron) untuk Beranda
      final allEntities = await baseDir.list(recursive: true).toList();
      savedPhotos.value = allEntities.whereType<File>().toList();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadFilesInFolder(String folderName) async {
    final baseDir = await _getBaseMaterialsDirectory();
    final folderDir = Directory(path.join(baseDir.path, folderName));
    if (!await folderDir.exists()) {
      currentFolderFiles.clear();
      return;
    }

    final entities = await folderDir.list().toList();
    final files = entities.whereType<File>().toList();
    currentFolderFiles.value = await _sortByLastModifiedDesc(files);
  }

  int getFileCountInFolder(String folderName) {
    return savedPhotos.where((file) {
      final parentFolder = path.basename(file.parent.path);
      return parentFolder == folderName;
    }).length;
  }

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

        if (await File(destPath).exists()) {
          final ext = path.extension(fileName);
          final nameWithoutExt = path.basenameWithoutExtension(fileName);
          fileName =
              '${nameWithoutExt}_${DateTime.now().millisecondsSinceEpoch}$ext';
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

  Future<void> renameFile(
    File file,
    String newNameInput, {
    String? currentFolder,
  }) async {
    try {
      final cleanInput = newNameInput.trim();
      if (cleanInput.isEmpty) return;

      final originalExt = path.extension(file.path);
      final finalFileName =
          cleanInput.toLowerCase().endsWith(originalExt.toLowerCase())
              ? cleanInput
              : '$cleanInput$originalExt';

      final newPath = path.join(file.parent.path, finalFileName);
      if (newPath == file.path) return;

      if (await File(newPath).exists()) {
        Get.snackbar(
          'Perhatian',
          'File dengan nama "$finalFileName" sudah ada.',
        );
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
        fileName =
            '${nameWithoutExt}_${DateTime.now().millisecondsSinceEpoch}$ext';
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