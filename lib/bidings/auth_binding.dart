// ===== AUTH BINDING =====
// lib/app/bindings/auth_binding.dart

import 'package:get/get.dart';
import 'package:vitalh2x/controlers/auth_controller.dart';

class AuthBinding extends Bindings {
  @override
  void dependencies() {
    // Auth Controller - Lazy loading
    Get.lazyPut<AuthController>(
      () => AuthController(),
      fenix: true, // Recria se for removido
    );
  }
}
