import 'dart:io';
import 'package:get/get.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class MaterialsController extends GetxController {
  var savedPhotos = <File>[].obs;
  var isLoading = false.obs;
  @override
  void onInit() {
    super.onInit();
    loadSavedPhotos();
  }
  Future<void> loadSavedPhotos() async {
    isLoading.value = true;
    try {
      final directory = await getApplicationDocumentsDirectory();
      final scanDir = Directory(path.join(directory.path, 'scanned_materials'));
      if (!await scanDir.exists()) await scanDir.create(recursive: true);

      savedPhotos.value = scanDir.listSync()
          .whereType<File>()
          .where((f) => f.path.toLowerCase().endsWith('.jpg'))
          .toList();
    } finally {
      isLoading.value = false;
    }
  }
  Future<void> deletePhoto(File photo) async {
    await photo.delete();
    savedPhotos.remove(photo);
  }
}