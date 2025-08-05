// ===== REPORT BINDING =====
// lib/app/bindings/report_binding.dart

import 'package:get/get.dart';
import 'package:vitalh2x/controlers/auth_controller.dart';
import 'package:vitalh2x/controlers/report_controller.dart';

class ReportBinding extends Bindings {
  @override
  void dependencies() {
    // Report Controller
    Get.lazyPut<ReportController>(() => ReportController(), fenix: true);

    // Ensure Auth Controller is available
    if (!Get.isRegistered<AuthController>()) {
      Get.put<AuthController>(AuthController(), permanent: true);
    }
  }
}
