// ===== NETWORK BINDING =====
// lib/app/bindings/network_binding.dart

import 'package:get/get.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class NetworkBinding extends Bindings {
  @override
  void dependencies() {
    // Connectivity
    Get.lazyPut<Connectivity>(() => Connectivity(), fenix: true);

    // Sync Service (for online/offline synchronization)
    // Get.lazyPut<SyncService>(() => SyncService(), fenix: true);
  }
}
