// ===== INITIAL BINDING =====
// lib/app/bindings/initial_binding.dart

import 'package:get/get.dart';
import 'package:vitalh2x/controlers/auth_controller.dart';
import 'package:vitalh2x/services/database_providers.dart';
import 'package:vitalh2x/services/database_services.dart';

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // Database Service - Singleton
    Get.put<DatabaseService>(DatabaseService(), permanent: true);

    // Database Provider - Singleton
    Get.put<DatabaseProvider>(SQLiteDatabaseProvider(), permanent: true);

    // Auth Controller - Permanent (sempre disponível)
    Get.put<AuthController>(AuthController(), permanent: true);
  }
}
