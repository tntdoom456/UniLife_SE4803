import 'package:get/get.dart';
import '../controllers/home_controller.dart';
import '../../schedule/controllers/schedule_controller.dart';
import '../../materials/controllers/materials_controller.dart';
import '../../wellness/controllers/wellness_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HomeController>(() => HomeController());
    // Karena Home menampilkan halaman lain di dalam tabnya, 
    // kita juga perlu me-load controller mereka.
    Get.lazyPut<ScheduleController>(() => ScheduleController());
    Get.lazyPut<MaterialsController>(() => MaterialsController());
    Get.lazyPut<WellnessController>(() => WellnessController());
  }
}