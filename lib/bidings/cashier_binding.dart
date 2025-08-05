// ===== CASHIER BINDING =====
// lib/app/bindings/cashier_binding.dart

import 'package:get/get.dart';
import 'package:vitalh2x/controlers/auth_controller.dart';
import 'package:vitalh2x/controlers/client_controller.dart';
import 'package:vitalh2x/controlers/payment_controller.dart';
import 'package:vitalh2x/controlers/reading_controller.dart';

class CashierBinding extends Bindings {
  @override
  void dependencies() {
    // Controllers needed for cashier operations
    Get.lazyPut<PaymentController>(() => PaymentController(), fenix: true);

    Get.lazyPut<ClientController>(() => ClientController(), fenix: true);

    Get.lazyPut<ReadingController>(() => ReadingController(), fenix: true);

    // Ensure Auth Controller is available
    if (!Get.isRegistered<AuthController>()) {
      Get.put<AuthController>(AuthController(), permanent: true);
    }
  }
}
