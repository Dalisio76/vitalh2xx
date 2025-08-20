// ===== RELATÓRIO DE ARRECADAÇÃO =====
// Relatório de dinheiro arrecadado por forma de pagamento

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:vitalh2x/controlers/reports_controller.dart';

class RevenueReportView extends StatelessWidget {
  const RevenueReportView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ReportsController controller = Get.put(ReportsController());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatório de Arrecadação'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () => _selectPeriod(controller),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => controller.loadCurrentMonthReports(),
          ),
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(value, controller),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.download, size: 20),
                    SizedBox(width: 8),
                    Text('Exportar'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'print',
                child: Row(
                  children: [
                    Icon(Icons.print, size: 20),
                    SizedBox(width: 8),
                    Text('Imprimir'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'yearly',
                child: Row(
                  children: [
                    Icon(Icons.bar_chart, size: 20),
                    SizedBox(width: 8),
                    Text('Relatório Anual'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPeriodHeader(controller),
              const SizedBox(height: 20),
              _buildSummaryCards(controller),
              const SizedBox(height: 20),
              _buildPaymentMethodsChart(controller),
              const SizedBox(height: 20),
              _buildPaymentMethodsList(controller),
              const SizedBox(height: 20),
              _buildActionButtons(controller),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildPeriodHeader(ReportsController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Período do Relatório',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Obx(() => Text(
                  controller.currentPeriodText,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                )),
              ],
            ),
            ElevatedButton.icon(
              onPressed: () => _selectPeriod(controller),
              icon: const Icon(Icons.edit_calendar, size: 20),
              label: const Text('Alterar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[600],
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards(ReportsController controller) {
    return Obx(() {
      final totalRevenue = controller.currentMonthRevenue;
      final totalPayments = controller.currentMonthPaymentsCount;

      return Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              'Total Arrecadado',
              controller.formatCurrency(totalRevenue),
              Icons.attach_money,
              Colors.green,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildSummaryCard(
              'Total de Pagamentos',
              '$totalPayments',
              Icons.receipt_long,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildSummaryCard(
              'Ticket Médio',
              controller.formatCurrency(
                totalPayments > 0 ? totalRevenue / totalPayments : 0,
              ),
              Icons.trending_up,
              Colors.orange,
            ),
          ),
        ],
      );
    });
  }

  Widget _buildSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodsChart(ReportsController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.pie_chart, color: Colors.indigo),
                const SizedBox(width: 8),
                const Text(
                  'Distribuição por Forma de Pagamento',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Obx(() {
              final methods = controller.paymentMethodStats;
              
              if (methods.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(Icons.money_off, size: 48, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Nenhum pagamento registrado neste período',
                          style: TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: methods.map((method) {
                  final percentage = method['percentage'] as double;
                  final color = _getPaymentMethodColor(method['method']);
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              method['display_name'],
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            Text(
                              controller.formatPercentage(percentage),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: percentage / 100,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                          minHeight: 8,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodsList(ReportsController controller) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.list_alt, color: Colors.teal),
                const SizedBox(width: 8),
                const Text(
                  'Detalhes por Forma de Pagamento',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Obx(() {
              final methods = controller.paymentMethodStats;
              
              if (methods.isEmpty) {
                return const Center(
                  child: Text(
                    'Nenhum dado disponível',
                    style: TextStyle(color: Colors.grey),
                  ),
                );
              }

              return Column(
                children: methods.map((method) {
                  final color = _getPaymentMethodColor(method['method']);
                  
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: color.withOpacity(0.1),
                        child: Icon(
                          _getPaymentMethodIcon(method['method']),
                          color: color,
                          size: 20,
                        ),
                      ),
                      title: Text(method['display_name']),
                      subtitle: Text('${method['count']} pagamentos'),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            controller.formatCurrency(method['amount']),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: color,
                            ),
                          ),
                          Text(
                            controller.formatPercentage(method['percentage']),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(ReportsController controller) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => controller.exportMonthlyRevenueReport(),
            icon: const Icon(Icons.download, color: Colors.white),
            label: const Text('Exportar PDF', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => controller.printMonthlyRevenueReport(),
            icon: const Icon(Icons.print, color: Colors.white),
            label: const Text('Imprimir', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Color _getPaymentMethodColor(String method) {
    switch (method) {
      case 'cash':
        return Colors.green;
      case 'card':
        return Colors.blue;
      case 'mobileMoney':
        return Colors.orange;
      case 'bankTransfer':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getPaymentMethodIcon(String method) {
    switch (method) {
      case 'cash':
        return Icons.money;
      case 'card':
        return Icons.credit_card;
      case 'mobileMoney':
        return Icons.phone_android;
      case 'bankTransfer':
        return Icons.account_balance;
      default:
        return Icons.payment;
    }
  }

  void _handleMenuAction(String action, ReportsController controller) {
    switch (action) {
      case 'export':
        controller.exportMonthlyRevenueReport();
        break;
      case 'print':
        controller.printMonthlyRevenueReport();
        break;
      case 'yearly':
        _showYearlyReport(controller);
        break;
    }
  }

  void _selectPeriod(ReportsController controller) async {
    final DateTime? picked = await showDatePicker(
      context: Get.context!,
      initialDate: DateTime(
        controller.currentYear.value,
        controller.currentMonth.value,
      ),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      controller.changePeriod(picked.month, picked.year);
    }
  }

  void _showYearlyReport(ReportsController controller) {
    // TODO: Navigate to yearly report view
    Get.snackbar(
      'Relatório Anual',
      'Funcionalidade em desenvolvimento',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}