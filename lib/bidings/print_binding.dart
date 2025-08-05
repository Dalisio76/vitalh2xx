// ===== PRINT BINDING =====
// lib/app/bindings/print_binding.dart

import 'package:get/get.dart';
import 'package:vitalh2x/controlers/auth_controller.dart';
import 'package:vitalh2x/controlers/client_controller.dart';
import 'package:vitalh2x/controlers/payment_controller.dart';

class PrintBinding extends Bindings {
  @override
  void dependencies() {
    // TODO: Print Service será criado posteriormente
    // Get.lazyPut<PrintService>(
    //   () => PrintService(),
    //   fenix: true,
    // );

    // Controllers needed for printing
    Get.lazyPut<ClientController>(() => ClientController(), fenix: true);

    Get.lazyPut<PaymentController>(() => PaymentController(), fenix: true);

    // Ensure Auth Controller is available
    if (!Get.isRegistered<AuthController>()) {
      Get.put<AuthController>(AuthController(), permanent: true);
    }
  }
}
