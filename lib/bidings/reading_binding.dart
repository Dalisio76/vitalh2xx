// ===== READING BINDING =====
// lib/app/bindings/reading_binding.dart

import 'package:get/get.dart';
import 'package:vitalh2x/controlers/auth_controller.dart';
import 'package:vitalh2x/controlers/client_controller.dart';
import 'package:vitalh2x/controlers/reading_controller.dart';

class ReadingBinding extends Bindings {
  @override
  void dependencies() {
    // Reading Controller
    Get.lazyPut<ReadingController>(() => ReadingController(), fenix: true);

    // Client Controller (needed for client search)
    Get.lazyPut<ClientController>(() => ClientController(), fenix: true);

    // Ensure Auth Controller is available
    if (!Get.isRegistered<AuthController>()) {
      Get.put<AuthController>(AuthController(), permanent: true);
    }
  }
}
