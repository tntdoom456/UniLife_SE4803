import 'package:get/get.dart';
import '../../features/auth/presentation/controllers/auth_controller.dart';
import '../../features/home/presentation/controllers/home_controller.dart';
import '../../features/schedule/presentation/controllers/schedule_controller.dart';
import '../../features/materials/presentation/controllers/materials_controller.dart';
import '../../features/wellness/presentation/controllers/wellness_controller.dart';

class MainBinding extends Bindings {
  @override
  void dependencies() {
    // 1. Controller yang krusial/selalu dipakai diletakkan dengan Get.put (langsung masuk RAM)
    Get.put<HomeController>(HomeController(), permanent: true);
    Get.put<AuthController>(AuthController(), permanent: true);

    // 2. Controller halaman diletakkan dengan Get.lazyPut (baru masuk RAM saat halaman dipanggil)
    // fenix: true memastikan controller bisa diciptakan kembali setelah dihapus
    Get.lazyPut<ScheduleController>(() => ScheduleController(), fenix: true);
    Get.lazyPut<MaterialsController>(() => MaterialsController(), fenix: true);
    Get.lazyPut<WellnessController>(() => WellnessController(), fenix: true);
  }
}