// ===== ROUTE OBSERVER =====
// lib/app/routes/route_observer.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vitalh2x/bidings/dependency_injection.dart';

class AppRouteObserver extends GetObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    print('Navegou para: ${route.settings.name}');
    _logNavigation(route.settings.name, 'PUSH');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    print('Voltou de: ${route.settings.name}');
    _logNavigation(route.settings.name, 'POP');
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    print(
      'Substituiu ${oldRoute?.settings.name} por ${newRoute?.settings.name}',
    );
    _logNavigation(newRoute?.settings.name, 'REPLACE');
  }

  void _logNavigation(String? routeName, String action) {
    if (DI.isLoggedIn && routeName != null) {
      // TODO: Log navigation for analytics
      // Could save to database or send to analytics service
      print('User ${DI.userName} - $action: $routeName');
    }
  }
}
