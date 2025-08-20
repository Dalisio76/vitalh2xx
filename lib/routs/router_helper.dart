// ===== ROUTE HELPER =====
// lib/app/routes/route_helper.dart

import 'package:get/get.dart';
import 'package:vitalh2x/bidings/dependency_injection.dart';
import 'package:vitalh2x/models/usuario_model.dart';
import 'package:vitalh2x/routs/rout.dart';

class RouteHelper {
  // Navigate based on user role
  static void navigateToHomeBasedOnRole() {
    final user = DI.currentUser;
    if (user == null) {
      Get.offAllNamed(Routes.LOGIN);
      return;
    }

    switch (user.role) {
      case UserRole.admin:
        Get.offAllNamed(Routes.DASHBOARD);
        break;
      case UserRole.cashier:
        Get.offAllNamed(Routes.HOME);
        break;
      case UserRole.fieldOperator:
        Get.offAllNamed(Routes.READINGS);
        break;
    }
  }

  // Get available routes for current user
  static List<String> getAvailableRoutes() {
    final availableRoutes = <String>[Routes.HOME];

    if (DI.isLoggedIn) {
      // All users can access readings
      availableRoutes.add(Routes.READINGS);

      // Admin and Cashier can access clients and payments
      if (DI.canRegisterClients) {
        availableRoutes.add(Routes.CLIENTS);
      }

      if (DI.canRegisterPayments) {
        availableRoutes.add(Routes.PAYMENTS);
      }

      // Admin and Cashier can access reports
      if (!DI.canOnlyReadMeters) {
        availableRoutes.add(Routes.REPORTS);
      }

      // Only admin can access dashboard and settings
      if (DI.isAdmin) {
        availableRoutes.add(Routes.DASHBOARD);
        availableRoutes.add(Routes.SETTINGS);
      }
    }

    return availableRoutes;
  }

  // Check if user can access route
  static bool canAccessRoute(String route) {
    if (!DI.isLoggedIn) {
      return route == Routes.LOGIN || route == Routes.SPLASH;
    }

    return getAvailableRoutes().contains(route);
  }

  // Get home route for current user
  static String getHomeRoute() {
    if (!DI.isLoggedIn) return Routes.LOGIN;

    final user = DI.currentUser!;
    switch (user.role) {
      case UserRole.admin:
        return Routes.DASHBOARD;
      case UserRole.cashier:
        return Routes.HOME;
      case UserRole.fieldOperator:
        return Routes.READINGS;
    }
  }

  // Navigation methods with permission checks
  static void toClients() {
    if (DI.canRegisterClients || DI.isAdmin) {
      Get.toNamed(Routes.CLIENTS);
    } else {
      _showAccessDenied('Você não tem permissão para acessar clientes');
    }
  }

  static void toPayments() {
    if (DI.canRegisterPayments || DI.isAdmin) {
      Get.toNamed(Routes.PAYMENTS);
    } else {
      _showAccessDenied('Você não tem permissão para acessar pagamentos');
    }
  }

  static void toReports() {
    if (!DI.canOnlyReadMeters || DI.isAdmin) {
      Get.toNamed(Routes.REPORTS);
    } else {
      _showAccessDenied('Você não tem permissão para acessar relatórios');
    }
  }

  static void toDashboard() {
    if (DI.isAdmin) {
      Get.toNamed(Routes.DASHBOARD);
    } else {
      _showAccessDenied('Apenas administradores podem acessar o dashboard');
    }
  }

  static void _showAccessDenied(String message) {
    Get.snackbar('Acesso Negado', message, snackPosition: SnackPosition.TOP);
  }
}
