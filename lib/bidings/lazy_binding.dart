// ===== LAZY BINDING UTILITY =====
// lib/app/bindings/lazy_binding.dart

import 'package:get/get.dart';

class LazyBinding {
  // Create lazy binding for a single controller
  static Bindings single<T>(T Function() create) {
    return BindingsBuilder(() {
      Get.lazyPut<T>(create, fenix: true);
    });
  }

  // Create lazy binding for multiple controllers
  static Bindings multiple(Map<Type, Function> controllers) {
    return BindingsBuilder(() {
      controllers.forEach((type, create) {
        //Get.lazyPut(create, fenix: true);
      });
    });
  }

  // Create permanent binding
  static Bindings permanent<T>(T Function() create) {
    return BindingsBuilder(() {
      Get.put<T>(create(), permanent: true);
    });
  }
}
