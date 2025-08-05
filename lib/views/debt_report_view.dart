// ===== DEBT REPORT VIEW =====
// lib/app/modules/reports/views/debt_report_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vitalh2x/controlers/report_controller.dart';

class DebtReportView extends StatelessWidget {
  const DebtReportView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ReportController());

    return Scaffold(
      appBar: AppBar(
        title: Text('Relatório de Dívidas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () => controller.printReport('debt'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => controller.loadDebtReport(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Header with warning
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.red, size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Clientes com Dívidas',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Obx(
                          () => Text(
                            '${controller.debtReport.length} cliente${controller.debtReport.length != 1 ? 's' : ''} com contas em atraso',
                            style: TextStyle(
                              color: Colors.red.withOpacity(0.8),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Summary stats
            _buildDebtSummary(controller),

            const SizedBox(height: 16),

            // Debt list
            Obx(() {
              if (controller.isLoading) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (controller.debtReport.isEmpty) {
                return _buildEmptyState();
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Detalhes por Cliente',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ...controller.debtReport.map(
                    (debtData) => _buildDebtCard(debtData),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDebtSummary(ReportController controller) {
    return Obx(() {
      final totalDebt = controller.debtReport.fold<double>(
        0.0,
        (sum, item) => sum + (item['total_debt'] as double? ?? 0.0),
      );

      final oldestDebt =
          controller.debtReport.isNotEmpty
              ? controller.debtReport.reduce((a, b) {
                final aDate = a['oldest_bill']?['reading_date'];
                final bDate = b['oldest_bill']?['reading_date'];
                if (aDate == null) return b;
                if (bDate == null) return a;
                return DateTime.parse(aDate).isBefore(DateTime.parse(bDate))
                    ? a
                    : b;
              })
              : null;

      return Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              'Dívida Total',
              '${totalDebt.toStringAsFixed(2)} MT',
              Icons.monetization_on,
              Colors.red,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSummaryCard(
              'Clientes em Atraso',
              '${controller.debtReport.length}',
              Icons.people,
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
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDebtCard(Map<String, dynamic> debtData) {
    final client = debtData['client'];
    final totalDebt = debtData['total_debt'] as double;
    final pendingBills = debtData['pending_bills'] as List;
    final oldestBill = debtData['oldest_bill'];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Colors.red.withOpacity(0.1),
          child: Text(
            client?.name?.isNotEmpty == true
                ? client.name[0].toUpperCase()
                : 'C',
            style: const TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          client?.name ?? 'Cliente desconhecido',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ref: ${client?.reference ?? 'N/A'}'),
            Text(
              'Dívida: ${totalDebt.toStringAsFixed(2)} MT',
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (oldestBill != null)
              Text(
                'Mais antiga: ${_formatDate(DateTime.parse(oldestBill['reading_date']))}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${pendingBills.length} conta${pendingBills.length != 1 ? 's' : ''}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.red[700],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Contas Pendentes:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                ...pendingBills
                    .map(
                      (bill) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${bill.month}/${bill.year}',
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                            Text(
                              '${bill.billAmount.toStringAsFixed(2)} MT',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Get.toNamed('/payments/form', arguments: client);
                    },
                    icon: const Icon(Icons.payment, color: Colors.white),
                    label: const Text(
                      'Processar Pagamento',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 80,
              color: Colors.green[300],
            ),
            const SizedBox(height: 16),
            Text(
              'Parabéns!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Não há clientes com dívidas pendentes',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
