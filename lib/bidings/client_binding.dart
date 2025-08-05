// ===== CLIENT BINDING =====
// lib/app/bindings/client_binding.dart

import 'package:get/get.dart';
import 'package:vitalh2x/controlers/auth_controller.dart';
import 'package:vitalh2x/controlers/client_controller.dart';

class ClientBinding extends Bindings {
  @override
  void dependencies() {
    // Client Controller
    Get.lazyPut<ClientController>(() => ClientController(), fenix: true);

    // Ensure Auth Controller is available
    if (!Get.isRegistered<AuthController>()) {
      Get.put<AuthController>(AuthController(), permanent: true);
    }
  }
}
