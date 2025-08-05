// ===== DEPENDENCY INJECTION HELPER =====
// lib/app/bindings/dependency_injection.dart

import 'package:get/get.dart';
import 'package:vitalh2x/controlers/auth_controller.dart';
import 'package:vitalh2x/controlers/client_controller.dart';
import 'package:vitalh2x/controlers/payment_controller.dart';
import 'package:vitalh2x/controlers/reading_controller.dart';
import 'package:vitalh2x/controlers/report_controller.dart';
import 'package:vitalh2x/models/cliente_model.dart';
import 'package:vitalh2x/models/usuario_model.dart';
import 'package:vitalh2x/services/database_providers.dart';
import 'package:vitalh2x/services/database_services.dart';

class DI {
  // Initialize core dependencies
  static void init() {
    // Core Services - Permanent
    Get.put<DatabaseService>(DatabaseService(), permanent: true);
    Get.put<DatabaseProvider>(SQLiteDatabaseProvider(), permanent: true);
    Get.put<AuthController>(AuthController(), permanent: true);
  }

  // Controllers - Lazy loading with getters
  static AuthController get auth => Get.find<AuthController>();

  static ClientController get client =>
      Get.isRegistered<ClientController>()
          ? Get.find<ClientController>()
          : Get.put<ClientController>(ClientController());

  static ReadingController get reading =>
      Get.isRegistered<ReadingController>()
          ? Get.find<ReadingController>()
          : Get.put<ReadingController>(ReadingController());

  static PaymentController get payment =>
      Get.isRegistered<PaymentController>()
          ? Get.find<PaymentController>()
          : Get.put<PaymentController>(PaymentController());

  static ReportController get report =>
      Get.isRegistered<ReportController>()
          ? Get.find<ReportController>()
          : Get.put<ReportController>(ReportController());

  // Services
  static DatabaseService get database => Get.find<DatabaseService>();
  static DatabaseProvider get databaseProvider => Get.find<DatabaseProvider>();

  // Check permissions using auth controller
  static bool get canRegisterClients => auth.canRegisterClients();
  static bool get canRegisterPayments => auth.canRegisterPayments();
  static bool get canOnlyReadMeters => auth.canOnlyReadMeters();
  static bool get isAdmin => auth.isAdmin();

  // Current user shortcuts
  static UserModel? get currentUser => auth.currentUser;
  static bool get isLoggedIn => auth.isLoggedIn;
  static String get userName => currentUser?.name ?? 'Usuário';
  static String get userRole => currentUser?.role.displayName ?? 'N/A';
}
