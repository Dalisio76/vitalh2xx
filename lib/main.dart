import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vitalh2x/bidings/InitialBinding.dart';
import 'package:vitalh2x/routs/app_pages.dart';
import 'package:vitalh2x/services/http_service.dart';
import 'package:vitalh2x/services/auth_service.dart';
import 'package:vitalh2x/services/sync_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {
  databaseFactory = databaseFactoryFfi;
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar serviços
  await HttpService.initialize();
  
  // Inicializar bindings
  InitialBinding().dependencies();
  
  // Inicializar serviços globais
  Get.put<AuthService>(AuthService(), permanent: true);
  Get.put<SyncService>(SyncService(), permanent: true);

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Water Management System',
      themeMode: ThemeMode.system,
      initialBinding: InitialBinding(),
      initialRoute: AppPages.INITIAL,
      getPages: AppPages.routes,
      debugShowCheckedModeBanner: false,
      defaultTransition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}
