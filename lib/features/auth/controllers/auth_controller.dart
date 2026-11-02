import 'package:get/get.dart';

class AuthController extends GetxController {
  var isLoading = false.obs;

  Future<void> login(String email, String password) async{
    isLoading.value = true;
    try{
      // Simulasi delay API Login
      await Future.delayed(const Duration(seconds: 2));
      Get.offAllNamed('/'); // Pindah ke Home dan hapus histori rute
    } finally{
      isLoading.value = false;
    }
  }
}