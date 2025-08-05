// ===== REPORT CONTROLLER =====
// lib/app/controllers/report_controller.dart

// ===== REPORT CONTROLLER =====
// lib/app/controllers/report_controller.dart

import 'package:get/get.dart';
import 'package:vitalh2x/controlers/base_controler.dart';
import 'package:vitalh2x/models/cliente_model.dart';
import 'package:vitalh2x/models/metodo_pagamento_model.dart';
import 'package:vitalh2x/repository/cliente_repository.dart';
import 'package:vitalh2x/repository/payment_repository.dart';
import 'package:vitalh2x/repository/reading_repository.dart';
import 'package:vitalh2x/services/database_providers.dart';

class ReportController extends BaseController {
  final ClientRepository _clientRepository = ClientRepository(
    SQLiteDatabaseProvider(),
  );
  final ReadingRepository _readingRepository = ReadingRepository(
    SQLiteDatabaseProvider(),
  );
  final PaymentRepository _paymentRepository = PaymentRepository(
    SQLiteDatabaseProvider(),
  );

  // Report data
  final RxMap<String, dynamic> dashboardStats = <String, dynamic>{}.obs;
  final RxMap<String, dynamic> monthlyReport = <String, dynamic>{}.obs;
  final RxList<Map<String, dynamic>> debtReport = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> consumptionReport =
      <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> paymentMethodReport =
      <Map<String, dynamic>>[].obs;

  // Date filters
  final RxInt selectedMonth = DateTime.now().month.obs;
  final RxInt selectedYear = DateTime.now().year.obs;
  final Rx<DateTime> startDate =
      DateTime.now().subtract(Duration(days: 30)).obs;
  final Rx<DateTime> endDate = DateTime.now().obs;

  @override
  void onInit() {
    super.onInit();
    loadDashboardStats();
    loadMonthlyReport();
    loadDebtReport();
  }

  // Load dashboard statistics
  Future<void> loadDashboardStats() async {
    try {
      showLoading('Carregando estatísticas...');

      final clientStats = await _clientRepository.getClientStats();
      final readingStats = await _readingRepository.getReadingStats(
        month: selectedMonth.value,
        year: selectedYear.value,
      );
      final paymentStats = await _paymentRepository.getPaymentStats(
        startDate: DateTime(selectedYear.value, selectedMonth.value, 1),
        endDate: DateTime(selectedYear.value, selectedMonth.value + 1, 0),
      );

      dashboardStats.assignAll({
        ...clientStats,
        ...readingStats,
        ...paymentStats,
      });

      hideLoading();
    } catch (e) {
      handleException(e);
    }
  }

  // Load monthly report
  Future<void> loadMonthlyReport() async {
    try {
      showLoading('Gerando relatório mensal...');

      final readingStats = await _readingRepository.getReadingStats(
        month: selectedMonth.value,
        year: selectedYear.value,
      );

      final paymentStats = await _paymentRepository.getPaymentStats(
        startDate: DateTime(selectedYear.value, selectedMonth.value, 1),
        endDate: DateTime(selectedYear.value, selectedMonth.value + 1, 0),
      );

      // Get readings with client info
      final readingsWithClient = await _readingRepository
          .findReadingsWithClientInfo(
            month: selectedMonth.value,
            year: selectedYear.value,
          );

      monthlyReport.assignAll({
        'month': selectedMonth.value,
        'year': selectedYear.value,
        'readings': readingStats,
        'payments': paymentStats,
        'detailed_readings': readingsWithClient,
      });

      hideLoading();
    } catch (e) {
      handleException(e);
    }
  }

  // Load debt report
  Future<void> loadDebtReport() async {
    try {
      showLoading('Carregando relatório de dívidas...');

      final clientsWithDebt = await _clientRepository.findClientsWithDebt();
      final debtData = <Map<String, dynamic>>[];

      for (final client in clientsWithDebt) {
        final pendingReadings = await _readingRepository.findByClient(
          client.id!,
        );
        final pendingBills =
            pendingReadings
                .where(
                  (reading) =>
                      reading.paymentStatus == PaymentStatus.pending ||
                      reading.paymentStatus == PaymentStatus.overdue,
                )
                .toList();

        if (pendingBills.isNotEmpty) {
          debtData.add({
            'client': client,
            'total_debt': client.totalDebt,
            'pending_bills': pendingBills,
            'oldest_bill':
                pendingBills.isNotEmpty
                    ? pendingBills.reduce(
                      (a, b) => a.readingDate.isBefore(b.readingDate) ? a : b,
                    )
                    : null,
          });
        }
      }

      // Sort by total debt (highest first)
      debtData.sort(
        (a, b) =>
            (b['total_debt'] as double).compareTo(a['total_debt'] as double),
      );

      debtReport.assignAll(debtData);

      hideLoading();
    } catch (e) {
      handleException(e);
    }
  }

  // Load consumption report
  Future<void> loadConsumptionReport() async {
    try {
      showLoading('Gerando relatório de consumo...');

      final readingsWithClient = await _readingRepository
          .findReadingsWithClientInfo(
            month: selectedMonth.value,
            year: selectedYear.value,
          );

      // Sort by consumption (highest first)
      readingsWithClient.sort(
        (a, b) =>
            (b['consumption'] as double).compareTo(a['consumption'] as double),
      );

      consumptionReport.assignAll(readingsWithClient);

      hideLoading();
    } catch (e) {
      handleException(e);
    }
  }

  // Load payment method report
  Future<void> loadPaymentMethodReport() async {
    try {
      showLoading('Gerando relatório de formas de pagamento...');

      final paymentStats = await _paymentRepository.getPaymentStats(
        startDate: startDate.value,
        endDate: endDate.value,
      );

      final methodData = <Map<String, dynamic>>[];

      for (final method in PaymentMethod.values) {
        final count = paymentStats['${method.name}_count'] ?? 0;
        final amount = paymentStats['${method.name}_amount'] ?? 0.0;

        if (count > 0) {
          methodData.add({
            'method': method,
            'method_name': method.displayName,
            'count': count,
            'amount': amount,
            'percentage':
                paymentStats['total_amount'] > 0
                    ? (amount / paymentStats['total_amount'] * 100)
                    : 0.0,
          });
        }
      }

      // Sort by amount (highest first)
      methodData.sort(
        (a, b) => (b['amount'] as double).compareTo(a['amount'] as double),
      );

      paymentMethodReport.assignAll(methodData);

      hideLoading();
    } catch (e) {
      handleException(e);
    }
  }

  // Change month/year
  void changeMonth(int month, int year) {
    selectedMonth.value = month;
    selectedYear.value = year;
    loadDashboardStats();
    loadMonthlyReport();
    loadConsumptionReport();
  }

  // Change date range
  void changeDateRange(DateTime start, DateTime end) {
    startDate.value = start;
    endDate.value = end;
    loadPaymentMethodReport();
  }

  // Export monthly report
  Future<void> exportMonthlyReport() async {
    try {
      showLoading('Exportando relatório...');

      // TODO: Implement export functionality
      // This could export to PDF, Excel, etc.

      hideLoading();
      showSuccess('Relatório exportado com sucesso!');
    } catch (e) {
      handleException(e);
    }
  }

  // Print report
  Future<void> printReport(String reportType) async {
    try {
      showLoading('Preparando impressão...');

      // TODO: Implement printing functionality

      hideLoading();
      showSuccess('Relatório enviado para impressão');
    } catch (e) {
      handleException(e);
    }
  }

  // Refresh all reports
  Future<void> refreshAllReports() async {
    await loadDashboardStats();
    await loadMonthlyReport();
    await loadDebtReport();
    await loadConsumptionReport();
    await loadPaymentMethodReport();
  }

  // Get formatted values
  String formatCurrency(double value) {
    return '${value.toStringAsFixed(2)} MT';
  }

  String formatConsumption(double value) {
    return '${value.toStringAsFixed(1)} m³';
  }

  String formatPercentage(double value) {
    return '${value.toStringAsFixed(1)}%';
  }

  // Get month name
  String getMonthName(int month) {
    const months = [
      '',
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro',
    ];
    return months[month];
  }
}
