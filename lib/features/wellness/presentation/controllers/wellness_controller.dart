import 'package:get/get.dart';

class WellnessController extends GetxController {
  var selectedMood = ''.obs;
  void setMood(String mood){
    selectedMood.value = mood;
  }
}