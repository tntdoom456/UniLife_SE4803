import 'package:get/get.dart';
import 'package:unilife/features/schedule/controllers/schedule_controller.dart';

class ScheduleBinding extends Bindings {
@override
void dependencies() {
  Get.lazyPut<ScheduleController>(() => ScheduleController());
  }
}