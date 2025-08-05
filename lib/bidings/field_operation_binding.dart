// ===== FIELD OPERATION BINDING =====
// lib/app/bindings/field_operation_binding.dart

import 'package:get/get.dart';
import 'package:vitalh2x/controlers/auth_controller.dart';
import 'package:vitalh2x/controlers/client_controller.dart';
import 'package:vitalh2x/controlers/reading_controller.dart';

class FieldOperationBinding extends Bindings {
  @override
  void dependencies() {
    // Controllers needed for field operations (reading meters)
    Get.lazyPut<ReadingController>(() => ReadingController(), fenix: true);

    Get.lazyPut<ClientController>(() => ClientController(), fenix: true);

    // Ensure Auth Controller is available
    if (!Get.isRegistered<AuthController>()) {
      Get.put<AuthController>(AuthController(), permanent: true);
    }
  }
}
