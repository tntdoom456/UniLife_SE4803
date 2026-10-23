import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:unilife/core/theme/app_theme.dart';
import 'package:unilife/features/auth/presentation/pages/login_page.dart';
import 'package:unilife/features/schedule/presentation/pages/map_page.dart';
import 'package:unilife/features/home/presentation/pages/home_page.dart';
import 'package:unilife/features/schedule/presentation/pages/schedule_page.dart';
import 'package:unilife/features/materials/presentation/pages/materials_page.dart';
import 'package:unilife/features/wellness/presentation/pages/wellness_page.dart';

class AppRoutes {
  static final GoRouter router = GoRouter(
    initialLocation: '/', // Nanti bisa diubah ke '/login' jika auth sudah siap
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/map',
        builder: (context, state) => const MapPage(),
      ),
      GoRoute(
        path: '/schedule',
        builder: (context, state) => const SchedulePage(),
      ),
      GoRoute(
        path: '/materials',
        builder: (context, state) => const MaterialsPage(),
      ),
      GoRoute(
        path: '/wellness',
        builder: (context, state) => const WellnessPage(),
      ),
    ],
  );
}