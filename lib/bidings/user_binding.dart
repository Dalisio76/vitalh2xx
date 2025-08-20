// ===== USER BINDING =====
// lib/app/bindings/user_binding.dart

import 'package:get/get.dart';
import 'package:vitalh2x/controlers/user_controller.dart';

class UserBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<UserController>(() => UserController());
  }
}