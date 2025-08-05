// ===== ROUTE MIDDLEWARE =====
// lib/app/routes/route_middleware.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vitalh2x/bidings/dependency_injection.dart';
import 'package:vitalh2x/routs/rout.dart';

// Base Middleware
abstract class RouteMiddleware extends GetMiddleware {
  @override
  int? get priority => 1;
}

// ===== AUTH MIDDLEWARE =====
class AuthMiddleware extends RouteMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    // Check if user is logged in
    if (!DI.isLoggedIn) {
      return const RouteSettings(name: Routes.LOGIN);
    }
    return null;
  }
}

// ===== ADMIN MIDDLEWARE =====
class AdminMiddleware extends RouteMiddleware {
  @override
  int? get priority => 2;

  @override
  RouteSettings? redirect(String? route) {
    if (!DI.isLoggedIn) {
      return const RouteSettings(name: Routes.LOGIN);
    }

    if (!DI.isAdmin) {
      Get.snackbar(
        'Acesso Negado',
        'Apenas administradores podem acessar esta área',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return const RouteSettings(name: Routes.HOME);
    }

    return null;
  }
}

// ===== CLIENT ACCESS MIDDLEWARE =====
class ClientAccessMiddleware extends RouteMiddleware {
  @override
  int? get priority => 2;

  @override
  RouteSettings? redirect(String? route) {
    if (!DI.isLoggedIn) {
      return const RouteSettings(name: Routes.LOGIN);
    }

    // Field operators can only access readings
    if (DI.canOnlyReadMeters) {
      Get.snackbar(
        'Acesso Limitado',
        'Você só pode acessar a área de leituras',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return const RouteSettings(name: Routes.READINGS);
    }

    return null;
  }
}

// ===== CLIENT MANAGEMENT MIDDLEWARE =====
class ClientManagementMiddleware extends RouteMiddleware {
  @override
  int? get priority => 2;

  @override
  RouteSettings? redirect(String? route) {
    if (!DI.isLoggedIn) {
      return const RouteSettings(name: Routes.LOGIN);
    }

    if (!DI.canRegisterClients) {
      Get.snackbar(
        'Acesso Negado',
        'Você não tem permissão para gerenciar clientes',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return const RouteSettings(name: Routes.HOME);
    }

    return null;
  }
}

// ===== PAYMENT ACCESS MIDDLEWARE =====
class PaymentAccessMiddleware extends RouteMiddleware {
  @override
  int? get priority => 2;

  @override
  RouteSettings? redirect(String? route) {
    if (!DI.isLoggedIn) {
      return const RouteSettings(name: Routes.LOGIN);
    }

    // Field operators cannot access payments
    if (DI.canOnlyReadMeters) {
      Get.snackbar(
        'Acesso Negado',
        'Você não tem permissão para acessar pagamentos',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return const RouteSettings(name: Routes.READINGS);
    }

    return null;
  }
}

// ===== PAYMENT MANAGEMENT MIDDLEWARE =====
class PaymentManagementMiddleware extends RouteMiddleware {
  @override
  int? get priority => 2;

  @override
  RouteSettings? redirect(String? route) {
    if (!DI.isLoggedIn) {
      return const RouteSettings(name: Routes.LOGIN);
    }

    if (!DI.canRegisterPayments) {
      Get.snackbar(
        'Acesso Negado',
        'Você não tem permissão para processar pagamentos',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return const RouteSettings(name: Routes.HOME);
    }

    return null;
  }
}

// ===== REPORT ACCESS MIDDLEWARE =====
class ReportAccessMiddleware extends RouteMiddleware {
  @override
  int? get priority => 2;

  @override
  RouteSettings? redirect(String? route) {
    if (!DI.isLoggedIn) {
      return const RouteSettings(name: Routes.LOGIN);
    }

    // Field operators cannot access reports
    if (DI.canOnlyReadMeters) {
      Get.snackbar(
        'Acesso Negado',
        'Você não tem permissão para acessar relatórios',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return const RouteSettings(name: Routes.READINGS);
    }

    return null;
  }
}
