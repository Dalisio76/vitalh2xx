// ===== PAYMENT BINDING =====
// lib/app/bindings/payment_binding.dart

import 'package:get/get.dart';
import 'package:vitalh2x/controlers/auth_controller.dart';
import 'package:vitalh2x/controlers/client_controller.dart';
import 'package:vitalh2x/controlers/payment_controller.dart';
import 'package:vitalh2x/controlers/reading_controller.dart';

class PaymentBinding extends Bindings {
  @override
  void dependencies() {
    // Payment Controller
    Get.lazyPut<PaymentController>(() => PaymentController(), fenix: true);

    // Reading Controller (needed for pending bills)
    Get.lazyPut<ReadingController>(() => ReadingController(), fenix: true);

    // Client Controller (needed for client search)
    Get.lazyPut<ClientController>(() => ClientController(), fenix: true);

    // Ensure Auth Controller is available
    if (!Get.isRegistered<AuthController>()) {
      Get.put<AuthController>(AuthController(), permanent: true);
    }
  }
}
