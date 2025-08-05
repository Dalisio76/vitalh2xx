// ===== HOME BINDING =====
// lib/app/bindings/home_binding.dart

import 'package:get/get.dart';
import 'package:vitalh2x/controlers/auth_controller.dart';
import 'package:vitalh2x/controlers/client_controller.dart';
import 'package:vitalh2x/controlers/payment_controller.dart';
import 'package:vitalh2x/controlers/reading_controller.dart';
import 'package:vitalh2x/controlers/report_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    // Auth Controller - Get existing instance
    if (!Get.isRegistered<AuthController>()) {
      Get.put<AuthController>(AuthController(), permanent: true);
    }

    // Main Controllers - Lazy loading
    Get.lazyPut<ClientController>(() => ClientController(), fenix: true);

    Get.lazyPut<ReadingController>(() => ReadingController(), fenix: true);

    Get.lazyPut<PaymentController>(() => PaymentController(), fenix: true);

    Get.lazyPut<ReportController>(() => ReportController(), fenix: true);
  }
}
