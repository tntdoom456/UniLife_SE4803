import 'package:get/get.dart';
import 'app_routes.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/schedule/presentation/pages/map_page.dart';
import '../../features/schedule/presentation/pages/schedule_page.dart';
import '../../features/materials/presentation/pages/materials_page.dart';
import '../../features/wellness/presentation/pages/wellness_page.dart';

class AppPages {
  static const INITIAL = Routes.HOME; 
  
  static final routes = [
    GetPage(
      name: Routes.HOME,
      page: () => const HomePage(),
    ),
    GetPage(
      name: Routes.LOGIN,
      page: () => const LoginPage(),
    ),
    GetPage(
      name: Routes.MAP,
      page: () => const MapPage(),
    ), // Map mungkin tidak butuh controller khusus
    GetPage(
      name: Routes.SCHEDULE,
      page: () => const SchedulePage(),
    ),
    GetPage(
      name: Routes.MATERIALS,
      page: () => const MaterialsPage(),
    ),
    GetPage(
      name: Routes.WELLNESS,
      page: () => WellnessPage(),
    ),
  ];
}