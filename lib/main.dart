import 'package:flutter/material.dart';
import 'core/route/app_routes.dart';
import 'core/theme/app_theme.dart';

void main() {
  // Inisialisasi Firebase nanti dilakukan di sini
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const UniLifeApp());
}

class UniLifeApp extends StatelessWidget {
  const UniLifeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'UniLife',
      theme: AppTheme.darkTheme,
      routerConfig: AppRoutes.router,
      debugShowCheckedModeBanner: false,
    );
  }
}