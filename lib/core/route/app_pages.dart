import 'package:get/get.dart';
import 'app_routes.dart';

import '../../features/auth/bindings/auth_binding.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/home/bindings/home_binding.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/schedule/bindings/schedule_binding.dart';
import '../../features/schedule/presentation/pages/map_page.dart';
import '../../features/schedule/presentation/pages/schedule_page.dart';
import '../../features/materials/bindings/materials_binding.dart';
import '../../features/materials/presentation/pages/materials_page.dart';
import '../../features/wellness/bindings/wellness_binding.dart';
import '../../features/wellness/presentation/pages/wellness_page.dart';

class AppPages {
  static const INITIAL = Routes.LOGIN; 
  
  static final routes = [
    GetPage(
      name: Routes.HOME,
      page: () => const HomePage(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: Routes.LOGIN,
      page: () => const LoginPage(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: Routes.MAP,
      page: () => const MapPage(),
    ), // Map mungkin tidak butuh controller khusus
    GetPage(
      name: Routes.SCHEDULE,
      page: () => const SchedulePage(),
      binding: ScheduleBinding(),
    ),
    GetPage(
      name: Routes.MATERIALS,
      page: () => const MaterialsPage(),
      binding: MaterialsBinding(),
    ),
    GetPage(
      name: Routes.WELLNESS,
      page: () => WellnessPage(),
      binding: WellnessBinding(),
    ),
  ];
}