// ===== SPLASH VIEW =====
// lib/app/modules/auth/views/splash_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vitalh2x/controlers/auth_controller.dart';
import 'package:vitalh2x/routs/router_helper.dart';

class SplashView extends GetView<AuthController> {
  const SplashView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Auto navigate after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (controller.isLoggedIn) {
        RouteHelper.navigateToHomeBasedOnRole();
      } else {
        Get.offAllNamed('/login');
      }
    });

    return Scaffold(
      backgroundColor: Get.theme.primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Icon(
                Icons.water_drop,
                size: 60,
                color: Get.theme.primaryColor,
              ),
            ),

            const SizedBox(height: 30),

            // App Name
            const Text(
              'Water Management',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Sistema de Gestão de Água',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withOpacity(0.8),
              ),
            ),

            const SizedBox(height: 50),

            // Loading indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 3,
            ),

            const SizedBox(height: 20),

            Text(
              'Carregando...',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
