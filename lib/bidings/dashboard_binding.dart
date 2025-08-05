// ===== DASHBOARD BINDING =====
// lib/app/bindings/dashboard_binding.dart

import 'package:get/get.dart';
import 'package:vitalh2x/controlers/auth_controller.dart';
import 'package:vitalh2x/controlers/client_controller.dart';
import 'package:vitalh2x/controlers/payment_controller.dart';
import 'package:vitalh2x/controlers/reading_controller.dart';
import 'package:vitalh2x/controlers/report_controller.dart';

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    // All main controllers for dashboard
    Get.lazyPut<ClientController>(() => ClientController(), fenix: true);

    Get.lazyPut<ReadingController>(() => ReadingController(), fenix: true);

    Get.lazyPut<PaymentController>(() => PaymentController(), fenix: true);

    Get.lazyPut<ReportController>(() => ReportController(), fenix: true);

    // Ensure Auth Controller is available
    if (!Get.isRegistered<AuthController>()) {
      Get.put<AuthController>(AuthController(), permanent: true);
    }
  }
}
