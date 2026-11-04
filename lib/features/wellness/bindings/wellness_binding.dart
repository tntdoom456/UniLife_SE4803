import 'package:get/get.dart';
import 'package:unilife/features/wellness/controllers/wellness_controller.dart';

class WellnessBinding extends Bindings {
@override
void dependencies() {
  Get.lazyPut<WellnessController>(() => WellnessController());
  }
}