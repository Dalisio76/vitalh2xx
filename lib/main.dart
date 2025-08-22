import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:vitalh2x/bidings/InitialBinding.dart';
import 'package:vitalh2x/routs/app_pages.dart';
import 'package:vitalh2x/services/http_service.dart';
import 'package:vitalh2x/services/settings_service.dart';
import 'package:vitalh2x/utils/app_styles.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configurar SQLite apenas para desktop (Windows, Linux, macOS)
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  // No Android/iOS usa o SQLite nativo automaticamente

  // Inicializar serviços HTTP
  await HttpService.initialize();

  // Inicializar serviço de configurações
  await SettingsService.instance.init();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'VitalH2X - Sistema de Gestão de Água',
      theme: AppStyles.compactTheme,
      themeMode: ThemeMode.light,
      initialBinding: InitialBinding(),
      initialRoute: AppPages.INITIAL,
      getPages: AppPages.routes,
      debugShowCheckedModeBanner: false,
      defaultTransition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 300),
    );
  }
}
