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
import 'package:vitalh2x/utils/app_styles.dart';

class DashboardView extends StatelessWidget {
  const DashboardView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: AppStyles.primaryColor,
        foregroundColor: Colors.white,
        toolbarHeight: 48,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: _refreshData,
            tooltip: 'Atualizar dados',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with current month
              _buildHeader(),

              const SizedBox(height: 6),

              // Key metrics
              _buildKeyMetrics(),

              const SizedBox(height: 6),

              // Charts section
              _buildChartsSection(),

              const SizedBox(height: 6),

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
      height: 60,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppStyles.primaryColor,
            AppStyles.primaryColor.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dashboard - ${_getCurrentMonth()}',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Sistema VitalH2X',
            style: const TextStyle(fontSize: 9, color: Colors.white),
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
          crossAxisCount: 4,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
          childAspectRatio: 1.8,
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
          style: AppStyles.compactTitle.copyWith(color: Colors.grey[800]),
        ),
        const SizedBox(height: AppStyles.paddingLarge),

        // Payment Methods Chart
        GetBuilder<PaymentController>(
          init: DI.payment,
          builder: (controller) {
            return Container(
              padding: const EdgeInsets.all(AppStyles.paddingLarge),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Formas de Pagamento', style: AppStyles.compactSubtitle),
                  const SizedBox(height: AppStyles.paddingLarge),
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
          style: AppStyles.compactTitle.copyWith(color: Colors.grey[800]),
        ),
        const SizedBox(height: AppStyles.paddingLarge),

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

                    // Comentado - vai para mesma view de pagamentos
                    // _buildInsightTile(
                    //   'Contas Pendentes',
                    //   '${readingController.monthlyStats['pending'] ?? 0} contas',
                    //   Icons.pending_actions,
                    //   Colors.orange,
                    //   () => Get.toNamed('/payments'),
                    // ),
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
      margin: const EdgeInsets.only(bottom: AppStyles.paddingMedium),
      child: ListTile(
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color, size: 16),
        ),
        title: Text(
          title,
          style: AppStyles.compactBody.copyWith(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          value,
          style: AppStyles.compactSubtitle.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, size: 16),
        onTap: onTap,
        dense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppStyles.paddingLarge,
          vertical: AppStyles.paddingSmall,
        ),
      ),
    );
  }

  Future<void> _refreshData() async {
    try {
      // Mostrar feedback de carregamento
      Get.snackbar(
        'Atualizando',
        'Carregando dados mais recentes...',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.blue,
        colorText: Colors.white,
        duration: Duration(seconds: 2),
      );

      await DI.report.refreshAllReports();
      await DI.client.refreshData();
      await DI.reading.refreshData();
      await DI.payment.refreshData();

      // Mostrar feedback de sucesso
      Get.snackbar(
        'Atualizado',
        'Dados atualizados com sucesso!',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: Duration(seconds: 2),
      );
    } catch (e) {
      Get.snackbar(
        'Erro',
        'Erro ao atualizar dados: $e',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
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
