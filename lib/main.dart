import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:unilife/core/route/app_pages.dart';
import 'core/route/app_routes.dart';
import 'core/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const UniLifeApp());
}

class UniLifeApp extends StatelessWidget {
  const UniLifeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'UniLife',
      theme: AppTheme.darkTheme,
      initialRoute: AppPages.INITIAL,
      getPages: AppPages.routes,
      debugShowCheckedModeBanner: false,
    );
  }
}