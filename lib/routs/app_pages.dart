// ===== APP PAGES =====
// lib/app/routes/app_pages.dart

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:vitalh2x/bidings/HomeBinding.dart';
import 'package:vitalh2x/bidings/InitialBinding.dart';
import 'package:vitalh2x/bidings/auth_binding.dart';
import 'package:vitalh2x/bidings/client_binding.dart';
import 'package:vitalh2x/bidings/dashboard_binding.dart';
import 'package:vitalh2x/bidings/payment_binding.dart';
import 'package:vitalh2x/bidings/reading_binding.dart';
import 'package:vitalh2x/bidings/report_binding.dart';
import 'package:vitalh2x/routs/midlewar.dart';
import 'package:vitalh2x/routs/rout.dart';
import 'package:vitalh2x/views/about_view.dart';
import 'package:vitalh2x/views/cliente_detail_view.dart';
import 'package:vitalh2x/views/cliente_form_view.dart';
import 'package:vitalh2x/views/cliente_list_view.dart';
import 'package:vitalh2x/views/dashboard_view.dart';
import 'package:vitalh2x/views/debt_report_view.dart';
import 'package:vitalh2x/views/help_view.dart';
import 'package:vitalh2x/views/home_view.dart';
import 'package:vitalh2x/views/login_view.dart';
import 'package:vitalh2x/views/monthly_readings_view.dart';
import 'package:vitalh2x/views/monthly_report_view.dart';
import 'package:vitalh2x/views/payment_form_view.dart';
import 'package:vitalh2x/views/payment_history_view.dart';
import 'package:vitalh2x/views/payment_list_view.dart';
import 'package:vitalh2x/views/reading_form_view.dart';
import 'package:vitalh2x/views/reading_list_view.dart';
import 'package:vitalh2x/views/reports_view.dart';
import 'package:vitalh2x/views/settings_view.dart';
import 'package:vitalh2x/views/splashscreen.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.SPLASH;

  static final routes = [
    // ===== AUTH ROUTES =====
    GetPage(
      name: Routes.SPLASH,
      page: () => SplashView(),
      binding: InitialBinding(),
    ),

    GetPage(
      name: Routes.LOGIN,
      page: () => const LoginView(),
      binding: AuthBinding(),
    ),

    // ===== MAIN ROUTES =====
    GetPage(
      name: Routes.HOME,
      page: () => const HomeView(),
      binding: HomeBinding(),
      middlewares: [AuthMiddleware()],
    ),

    GetPage(
      name: Routes.DASHBOARD,
      page: () => DashboardView(),
      binding: DashboardBinding(),
      middlewares: [AuthMiddleware(), AdminMiddleware()],
    ),

    // ===== CLIENT ROUTES =====
    GetPage(
      name: Routes.CLIENTS,
      page: () => ClientListView(),
      binding: ClientBinding(),
      middlewares: [AuthMiddleware(), ClientAccessMiddleware()],
    ),

    GetPage(
      name: Routes.CLIENT_FORM,
      page: () => ClientFormView(),
      binding: ClientBinding(),
      middlewares: [AuthMiddleware(), ClientManagementMiddleware()],
    ),

    GetPage(
      name: Routes.CLIENT_DETAIL,
      page: () => ClientDetailView(),
      binding: ClientBinding(),
      middlewares: [AuthMiddleware(), ClientAccessMiddleware()],
    ),

    // ===== READING ROUTES =====
    GetPage(
      name: Routes.READINGS,
      page: () => ReadingListView(),
      binding: ReadingBinding(),
      middlewares: [AuthMiddleware()], // Todos podem ver leituras
    ),

    GetPage(
      name: Routes.READING_FORM,
      page: () => ReadingFormView(),
      binding: ReadingBinding(),
      middlewares: [AuthMiddleware()], // Todos podem fazer leituras
    ),

    GetPage(
      name: Routes.MONTHLY_READINGS,
      page: () => MonthlyReadingsView(),
      binding: ReadingBinding(),
      middlewares: [AuthMiddleware()],
    ),

    // ===== PAYMENT ROUTES =====
    GetPage(
      name: Routes.PAYMENTS,
      page: () => PaymentListView(),
      binding: PaymentBinding(),
      middlewares: [AuthMiddleware(), PaymentAccessMiddleware()],
    ),

    GetPage(
      name: Routes.PAYMENT_FORM,
      page: () => PaymentFormView(),
      binding: PaymentBinding(),
      middlewares: [AuthMiddleware(), PaymentManagementMiddleware()],
    ),

    GetPage(
      name: Routes.PAYMENT_HISTORY,
      page: () => PaymentHistoryView(),
      binding: PaymentBinding(),
      middlewares: [AuthMiddleware(), PaymentAccessMiddleware()],
    ),

    // ===== REPORT ROUTES =====
    GetPage(
      name: Routes.REPORTS,
      page: () => ReportsView(),
      binding: ReportBinding(),
      middlewares: [AuthMiddleware(), ReportAccessMiddleware()],
    ),

    GetPage(
      name: Routes.MONTHLY_REPORT,
      page: () => MonthlyReportView(),
      binding: ReportBinding(),
      middlewares: [AuthMiddleware(), ReportAccessMiddleware()],
    ),

    GetPage(
      name: Routes.DEBT_REPORT,
      page: () => DebtReportView(),
      binding: ReportBinding(),
      middlewares: [AuthMiddleware(), AdminMiddleware()],
    ),

    // ===== SETTINGS ROUTES =====
    GetPage(
      name: Routes.SETTINGS,
      page: () => SettingsView(),
      binding: HomeBinding(),
      middlewares: [AuthMiddleware()],
    ),

    // ===== HELP ROUTES =====
    GetPage(
      name: Routes.HELP,
      page: () => HelpView(),
      binding: HomeBinding(),
      middlewares: [AuthMiddleware()],
    ),

    GetPage(
      name: Routes.ABOUT,
      page: () => AboutView(),
      binding: HomeBinding(),
    ),
  ];
}
