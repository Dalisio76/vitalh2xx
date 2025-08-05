// ===== BINDING MANAGER =====
// lib/app/bindings/binding_manager.dart

import 'package:get/get.dart';
import 'package:vitalh2x/bidings/HomeBinding.dart';
import 'package:vitalh2x/bidings/InitialBinding.dart';
import 'package:vitalh2x/bidings/admin_binding.dart';
import 'package:vitalh2x/bidings/cashier_binding.dart';
import 'package:vitalh2x/bidings/field_operation_binding.dart';
import 'package:vitalh2x/controlers/auth_controller.dart';
import 'package:vitalh2x/controlers/client_controller.dart';
import 'package:vitalh2x/controlers/payment_controller.dart';
import 'package:vitalh2x/controlers/reading_controller.dart';
import 'package:vitalh2x/controlers/report_controller.dart';
import 'package:vitalh2x/models/cliente_model.dart';

class BindingManager {
  // Get appropriate binding based on user role
  static Bindings getBindingForUserRole(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return AdminBinding();
      case UserRole.cashier:
        return CashierBinding();
      case UserRole.fieldOperator:
        return FieldOperationBinding();
      default:
        return HomeBinding();
    }
  }

  // Setup bindings based on current user
  static void setupUserRoleBindings() {
    final authController = Get.find<AuthController>();
    final currentUser = authController.currentUser;

    if (currentUser != null) {
      final binding = getBindingForUserRole(currentUser.role);
      binding.dependencies();
    }
  }

  // Clean up controllers when user logs out
  static void cleanupOnLogout() {
    // Remove non-permanent controllers
    Get.delete<ClientController>();
    Get.delete<ReadingController>();
    Get.delete<PaymentController>();
    Get.delete<ReportController>();

    // Keep AuthController (permanent)
    // Keep DatabaseService (permanent)
    // Keep DatabaseProvider (permanent)
  }

  // Initialize app bindings
  static void initializeApp() {
    InitialBinding().dependencies();
  }

  // Check if controller is registered
  static bool isControllerRegistered<T>() {
    return Get.isRegistered<T>();
  }

  // Force put controller if needed
  static T putController<T>(T controller, {bool permanent = false}) {
    return Get.put<T>(controller, permanent: permanent);
  }

  // Get or create controller
  static T getOrCreateController<T>(T Function() create) {
    if (Get.isRegistered<T>()) {
      return Get.find<T>();
    } else {
      return Get.put<T>(create());
    }
  }
}
