import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:unilife/features/auth/controllers/auth_controller.dart';

class LoginPage extends GetView<AuthController> {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Obx(
          () => controller.isLoading.value
              ? const CircularProgressIndicator()
              : ElevatedButton(
                  onPressed: () =>
                      controller.login("test@test.com", "password"),
                  child: const Text('Login Mock'),
                ),
        ),
      ),
    );
  }
}
