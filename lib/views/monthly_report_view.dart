import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path/path.dart';
import 'package:vitalh2x/controlers/report_controller.dart';

class MonthlyReportView extends GetView<ReportController> {
  const MonthlyReportView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatório Mensal'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => controller.exportMonthlyReport(),
          ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () => controller.printReport('monthly'),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return RefreshIndicator(
          onRefresh: () => controller.loadMonthlyReport(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPeriodSelector(),
                const SizedBox(height: 20),
                _buildSummaryCards(),
                const SizedBox(height: 20),
                _buildConsumptionChart(),
                const SizedBox(height: 20),
                _buildPaymentStatusChart(),
                const SizedBox(height: 20),
                _buildDetailedList(),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildPeriodSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Período do Relatório',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectMonth(context as BuildContext),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Obx(
                            () => Text(
                              '${controller.getMonthName(controller.selectedMonth.value)}/${controller.selectedYear.value}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          const Icon(Icons.calendar_today),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () => controller.loadMonthlyReport(),
                  child: const Text('Gerar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Obx(() {
      final report = controller.monthlyReport.value;
      final readingStats = report['readings'] ?? {};
      final paymentStats = report['payments'] ?? {};

      return Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Leituras',
              '${readingStats['total_readings'] ?? 0}',
              Icons.speed,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Pagamentos',
              '${paymentStats['total_payments'] ?? 0}',
              Icons.payment,
              Colors.green,
            ),
          ),
        ],
      );
    });
  }

  Widget _buildStatCard(
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
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
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

  Widget _buildConsumptionChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Consumo de Água',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Obx(() {
              final report = controller.monthlyReport.value;
              final readingStats = report['readings'] ?? {};
              final totalConsumption =
                  (readingStats['total_consumption'] ?? 0.0).toDouble();
              final avgConsumption =
                  (readingStats['average_consumption'] ?? 0.0).toDouble();

              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(
                            controller.formatConsumption(totalConsumption),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          const Text('Total Consumido'),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            controller.formatConsumption(avgConsumption),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const Text('Média por Cliente'),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  LinearProgressIndicator(
                    value:
                        totalConsumption > 0
                            ? (totalConsumption / 1000).clamp(0.0, 1.0)
                            : 0,
                    backgroundColor: Colors.grey[300],
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.blue,
                    ),
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentStatusChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Status de Pagamentos',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Obx(() {
              final report = controller.monthlyReport.value;
              final paymentStats = report['payments'] ?? {};
              final paidCount = paymentStats['paid_count'] ?? 0;
              final pendingCount = paymentStats['pending_count'] ?? 0;
              final total = paidCount + pendingCount;

              return Column(
                children: [
                  if (total > 0) ...[
                    Row(
                      children: [
                        Expanded(
                          flex: paidCount > 0 ? paidCount : 1,
                          child: Container(
                            height: 20,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(10),
                                bottomLeft: Radius.circular(10),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: pendingCount > 0 ? pendingCount : 1,
                          child: Container(
                            height: 20,
                            decoration: const BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.only(
                                topRight: Radius.circular(10),
                                bottomRight: Radius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 8),
                              Text('Pagos: $paidCount'),
                            ],
                          ),
                          Text(
                            total > 0
                                ? controller.formatPercentage(
                                  paidCount * 100 / total,
                                )
                                : '0%',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 8),
                              Text('Pendentes: $pendingCount'),
                            ],
                          ),
                          Text(
                            total > 0
                                ? controller.formatPercentage(
                                  pendingCount * 100 / total,
                                )
                                : '0%',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedList() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detalhes por Cliente',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Obx(() {
              final report = controller.monthlyReport.value;
              final detailedReadings =
                  report['detailed_readings'] as List<Map<String, dynamic>>? ??
                  [];

              if (detailedReadings.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('Nenhum dado encontrado para este período'),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: detailedReadings.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final detail = detailedReadings[index];
                  final isPaid = detail['payment_status'] == 1; // 1 = paid

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isPaid ? Colors.green : Colors.orange,
                      child: Icon(
                        isPaid ? Icons.check : Icons.pending,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(detail['client_name'] ?? ''),
                    subtitle: Text(
                      'Consumo: ${controller.formatConsumption(detail['consumption'] ?? 0.0)} • ${controller.formatCurrency(detail['bill_amount'] ?? 0.0)}',
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          isPaid ? 'PAGO' : 'PENDENTE',
                          style: TextStyle(
                            color: isPaid ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        if (detail['payment_method'] != null)
                          Text(
                            detail['payment_method_name'] ?? '',
                            style: const TextStyle(fontSize: 10),
                          ),
                      ],
                    ),
                  );
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _selectMonth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(
        controller.selectedYear.value,
        controller.selectedMonth.value,
      ),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      controller.changeMonth(picked.month, picked.year);
    }
  }
}
