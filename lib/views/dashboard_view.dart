// ===== DASHBOARD VIEW =====
// lib/app/modules/home/views/dashboard_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vitalh2x/bidings/dependency_injection.dart';
import 'package:vitalh2x/controlers/client_controller.dart';
import 'package:vitalh2x/controlers/payment_controller.dart';
import 'package:vitalh2x/controlers/reading_controller.dart';
import 'package:vitalh2x/controlers/report_controller.dart';
import 'package:vitalh2x/routs/rout.dart';
import 'package:vitalh2x/widgets/dashboard_card.dart';
import 'package:vitalh2x/widgets/simple_bar_chart.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Dashboard')),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with current month
              _buildHeader(),

              const SizedBox(height: 24),

              // Key metrics
              _buildKeyMetrics(),

              const SizedBox(height: 24),

              // Charts section
              _buildChartsSection(),

              const SizedBox(height: 24),

              // Quick insights
              _buildQuickInsights(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo, Colors.indigo.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dashboard Administrativo',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Visão geral do sistema - ${_getCurrentMonth()}',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyMetrics() {
    return GetBuilder<ReportController>(
      init: DI.report,
      builder: (controller) {
        final stats = controller.dashboardStats;

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.3,
          children: [
            DashboardCard(
              title: 'Clientes Totais',
              value: '${stats['total'] ?? 0}',
              subtitle: '${stats['active'] ?? 0} ativos',
              icon: Icons.people,
              color: Colors.blue,
              trend: _calculateTrend(stats['active'], stats['total']),
            ),
            DashboardCard(
              title: 'Receita Mensal',
              value: '${(stats['total_amount'] ?? 0.0).toStringAsFixed(0)} MT',
              subtitle: '${stats['total_payments'] ?? 0} pagamentos',
              icon: Icons.monetization_on,
              color: Colors.green,
              trend: '+12%',
            ),
            DashboardCard(
              title: 'Consumo Total',
              value:
                  '${(stats['total_consumption'] ?? 0.0).toStringAsFixed(0)} m³',
              subtitle: 'Este mês',
              icon: Icons.water_drop,
              color: Colors.cyan,
              trend: '+5%',
            ),
            DashboardCard(
              title: 'Taxa Cobrança',
              value: '${_calculateCollectionRate(stats)}%',
              subtitle: '${stats['paid'] ?? 0}/${stats['total'] ?? 0} pagas',
              icon: Icons.assessment,
              color: Colors.orange,
              trend: '+8%',
            ),
          ],
        );
      },
    );
  }

  Widget _buildChartsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Análise Mensal',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 16),

        // Payment Methods Chart
        GetBuilder<PaymentController>(
          init: DI.payment,
          builder: (controller) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Formas de Pagamento',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  SimpleBarChart(
                    data: _getPaymentMethodData(controller.paymentStats),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuickInsights() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Insights Rápidos',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 16),

        GetBuilder<ClientController>(
          init: DI.client,
          builder: (clientController) {
            return GetBuilder<ReadingController>(
              init: DI.reading,
              builder: (readingController) {
                return Column(
                  children: [
                    _buildInsightTile(
                      'Clientes com Dívida',
                      '${clientController.stats['with_debt'] ?? 0} clientes',
                      Icons.warning,
                      Colors.red,
                      // () => Get.toNamed('/reports/debt'),
                      () => Get.toNamed(Routes.HOME),
                    ),

                    _buildInsightTile(
                      'Contas Pendentes',
                      '${readingController.monthlyStats['pending'] ?? 0} contas',
                      Icons.pending_actions,
                      Colors.orange,
                      () => Get.toNamed('/payments'),
                    ),

                    _buildInsightTile(
                      'Eficiência de Cobrança',
                      '${((readingController?.monthlyStats['paid'] ?? 0) / (readingController?.monthlyStats['total'] ?? 1) * 100).toStringAsFixed(1)}%',
                      Icons.trending_up,
                      Colors.green,
                      () => Get.toNamed('/reports/monthly'),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildInsightTile(
    String title,
    String value,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        ),
        subtitle: Text(
          value,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Future<void> _refreshData() async {
    try {
      await DI.report.refreshAllReports();
      await DI.client.refreshData();
      await DI.reading.refreshData();
      await DI.payment.refreshData();
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Erro ao atualizar dados: $e',
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  String _getCurrentMonth() {
    final months = [
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
    return months[DateTime.now().month];
  }

  String _calculateTrend(dynamic active, dynamic total) {
    if (active == null || total == null || total == 0) return '0%';
    final percentage = (active / total * 100).toStringAsFixed(1);
    return '$percentage%';
  }

  String _calculateCollectionRate(Map<String, dynamic> stats) {
    final paid = stats['paid'] ?? 0;
    final total = stats['total'] ?? 1;
    return (paid / total * 100).toStringAsFixed(1);
  }

  List<Map<String, dynamic>> _getPaymentMethodData(Map<String, dynamic> stats) {
    return [
      {
        'name': 'Dinheiro',
        'value': stats['cash_amount'] ?? 0.0,
        'color': Colors.green,
      },
      {
        'name': 'Transferência',
        'value': stats['bankTransfer_amount'] ?? 0.0,
        'color': Colors.blue,
      },
      {
        'name': 'Mobile Money',
        'value': stats['mobileMoney_amount'] ?? 0.0,
        'color': Colors.orange,
      },
      {
        'name': 'Outros',
        'value': stats['other_amount'] ?? 0.0,
        'color': Colors.purple,
      },
    ];
  }
}
