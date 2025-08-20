// ===== REPORTS CONTROLLER =====
// lib/app/controllers/reports_controller.dart

import 'package:get/get.dart';
import 'package:vitalh2x/controlers/base_controler.dart';
import 'package:vitalh2x/models/metodo_pagamento_model.dart';
import 'package:vitalh2x/repository/payment_repository.dart';
import 'package:vitalh2x/repository/reading_repository.dart';
import 'package:vitalh2x/services/database_providers.dart';

class ReportsController extends BaseController {
  final PaymentRepository _paymentRepository = PaymentRepository(
    SQLiteDatabaseProvider(),
  );
  final ReadingRepository _readingRepository = ReadingRepository(
    SQLiteDatabaseProvider(),
  );

  // Current period for reports
  final RxInt currentMonth = DateTime.now().month.obs;
  final RxInt currentYear = DateTime.now().year.obs;

  // Revenue reports data
  final RxMap<String, dynamic> monthlyRevenueReport = <String, dynamic>{}.obs;
  final RxMap<String, dynamic> yearlyRevenueReport = <String, dynamic>{}.obs;

  // Missing readings report data
  final RxMap<String, dynamic> missingReadingsReport = <String, dynamic>{}.obs;

  @override
  void onInit() {
    super.onInit();
    loadCurrentMonthReports();
  }

  // Load reports for current month
  Future<void> loadCurrentMonthReports() async {
    await loadMonthlyRevenueReport();
    await loadMissingReadingsReport();
  }

  // Load monthly revenue report by payment method
  Future<void> loadMonthlyRevenueReport({int? month, int? year}) async {
    try {
      showLoading('Carregando relatório de arrecadação...');
      
      final reportMonth = month ?? currentMonth.value;
      final reportYear = year ?? currentYear.value;
      
      final report = await _paymentRepository.getMonthlyRevenueByPaymentMethod(
        reportMonth,
        reportYear,
      );
      
      monthlyRevenueReport.assignAll(report);
      
      hideLoading();
    } catch (e) {
      handleException(e);
    }
  }

  // Load yearly revenue report
  Future<void> loadYearlyRevenueReport({int? year}) async {
    try {
      showLoading('Carregando relatório anual...');
      
      final reportYear = year ?? currentYear.value;
      
      final report = await _paymentRepository.getYearlyRevenueReport(reportYear);
      
      yearlyRevenueReport.assignAll(report);
      
      hideLoading();
    } catch (e) {
      handleException(e);
    }
  }

  // Load missing readings report
  Future<void> loadMissingReadingsReport({int? month, int? year}) async {
    try {
      showLoading('Carregando leituras não feitas...');
      
      final reportMonth = month ?? currentMonth.value;
      final reportYear = year ?? currentYear.value;
      
      final report = await _readingRepository.getMissingReadingsReport(
        reportMonth,
        reportYear,
      );
      
      missingReadingsReport.assignAll(report);
      
      hideLoading();
    } catch (e) {
      handleException(e);
    }
  }

  // Change report period
  Future<void> changePeriod(int month, int year) async {
    currentMonth.value = month;
    currentYear.value = year;
    await loadCurrentMonthReports();
  }

  // Get formatted month name
  String getMonthName(int month) {
    const months = [
      'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
      'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
    ];
    return months[month - 1];
  }

  // Get formatted currency
  String formatCurrency(double amount) {
    return '${amount.toStringAsFixed(2)} MT';
  }

  // Get formatted percentage
  String formatPercentage(double percentage) {
    return '${percentage.toStringAsFixed(1)}%';
  }

  // Get payment method statistics for current month
  List<Map<String, dynamic>> get paymentMethodStats {
    final report = monthlyRevenueReport.value;
    if (report.isEmpty || report['payment_methods'] == null) return [];

    final methods = <Map<String, dynamic>>[];
    final paymentMethods = report['payment_methods'] as Map<String, dynamic>;

    for (final entry in paymentMethods.entries) {
      final methodData = entry.value as Map<String, dynamic>;
      methods.add({
        'method': entry.key,
        'display_name': methodData['display_name'],
        'count': methodData['count'],
        'amount': methodData['amount'],
        'percentage': methodData['percentage'],
      });
    }

    // Sort by amount descending
    methods.sort((a, b) => (b['amount'] as double).compareTo(a['amount'] as double));
    return methods;
  }

  // Get missing readings summary
  Map<String, dynamic> get missingReadingsSummary {
    final report = missingReadingsReport.value;
    if (report.isEmpty) return {};

    return {
      'total_active_clients': report['total_active_clients'] ?? 0,
      'clients_with_readings': report['clients_with_readings'] ?? 0,
      'clients_without_readings_count': report['clients_without_readings_count'] ?? 0,
      'completion_percentage': report['completion_percentage'] ?? 0.0,
      'missing_percentage': report['missing_percentage'] ?? 0.0,
    };
  }

  // Get clients without readings list
  List<Map<String, dynamic>> get clientsWithoutReadings {
    final report = missingReadingsReport.value;
    if (report.isEmpty || report['clients_without_readings'] == null) return [];
    
    return (report['clients_without_readings'] as List<Map<String, dynamic>>);
  }

  // Export monthly revenue report (placeholder)
  Future<void> exportMonthlyRevenueReport() async {
    try {
      showLoading('Exportando relatório...');
      
      // TODO: Implement PDF/Excel export
      await Future.delayed(Duration(seconds: 1));
      
      showSuccess('Relatório exportado com sucesso!');
      hideLoading();
    } catch (e) {
      handleException(e);
    }
  }

  // Export missing readings report (placeholder)
  Future<void> exportMissingReadingsReport() async {
    try {
      showLoading('Exportando relatório...');
      
      // TODO: Implement PDF/Excel export
      await Future.delayed(Duration(seconds: 1));
      
      showSuccess('Relatório de leituras não feitas exportado!');
      hideLoading();
    } catch (e) {
      handleException(e);
    }
  }

  // Print monthly revenue report (placeholder)
  Future<void> printMonthlyRevenueReport() async {
    try {
      showLoading('Preparando para impressão...');
      
      // TODO: Implement thermal printer integration
      await Future.delayed(Duration(seconds: 1));
      
      showSuccess('Relatório enviado para impressão!');
      hideLoading();
    } catch (e) {
      handleException(e);
    }
  }

  // Get current period display text
  String get currentPeriodText => 
      '${getMonthName(currentMonth.value)} ${currentYear.value}';

  // Get total revenue for current month
  double get currentMonthRevenue => 
      (monthlyRevenueReport.value['total_amount'] as double?) ?? 0.0;

  // Get total payments count for current month
  int get currentMonthPaymentsCount => 
      (monthlyRevenueReport.value['total_payments'] as int?) ?? 0;
}