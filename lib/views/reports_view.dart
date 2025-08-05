// ===== REPORTS VIEW =====
// lib/app/modules/reports/views/reports_view.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vitalh2x/bidings/dependency_injection.dart';
import 'package:vitalh2x/controlers/report_controller.dart';

class ReportsView extends StatelessWidget {
  const ReportsView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ReportController());

    return Scaffold(
      appBar: AppBar(title: Text('Relatórios')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple, Colors.purple.withOpacity(0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.analytics, color: Colors.white, size: 32),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Relatórios e Análises',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Insights sobre o negócio',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Quick Stats
          _buildQuickStats(controller),

          const SizedBox(height: 24),

          // Report Categories
          _buildReportCategories(),
        ],
      ),
    );
  }

  Widget _buildQuickStats(ReportController controller) {
    return Obx(
      () => GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
        children: [
          _buildStatCard(
            'Receita Mensal',
            '${(controller.dashboardStats['total_amount'] ?? 0.0).toStringAsFixed(0)} MT',
            Icons.monetization_on,
            Colors.green,
          ),
          _buildStatCard(
            'Clientes Ativos',
            '${controller.dashboardStats['active'] ?? 0}',
            Icons.people,
            Colors.blue,
          ),
          _buildStatCard(
            'Consumo Total',
            '${(controller.dashboardStats['total_consumption'] ?? 0.0).toStringAsFixed(0)} m³',
            Icons.water_drop,
            Colors.cyan,
          ),
          _buildStatCard(
            'Taxa Cobrança',
            '${_calculateCollectionRate(controller.dashboardStats)}%',
            Icons.assessment,
            Colors.orange,
          ),
        ],
      ),
    );
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
          mainAxisAlignment: MainAxisAlignment.center,
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

  Widget _buildReportCategories() {
    final reports = [
      {
        'title': 'Relatório Mensal',
        'subtitle': 'Leituras e pagamentos do mês',
        'icon': Icons.calendar_month,
        'color': Colors.blue,
        'route': '/reports/monthly',
      },
      {
        'title': 'Relatório de Dívidas',
        'subtitle': 'Clientes com contas em atraso',
        'icon': Icons.warning,
        'color': Colors.red,
        'route': '/reports/debt',
      },
      {
        'title': 'Consumo por Cliente',
        'subtitle': 'Maiores consumidores',
        'icon': Icons.trending_up,
        'color': Colors.green,
        'route': '/reports/consumption',
      },
      {
        'title': 'Formas de Pagamento',
        'subtitle': 'Análise de métodos de pagamento',
        'icon': Icons.payment,
        'color': Colors.purple,
        'route': '/reports/payment-methods',
      },
      {
        'title': 'Relatório Anual',
        'subtitle': 'Visão geral do ano',
        'icon': Icons.bar_chart,
        'color': Colors.indigo,
        'route': '/reports/annual',
      },
      {
        'title': 'Eficiência Operacional',
        'subtitle': 'KPIs e métricas',
        'icon': Icons.speed,
        'color': Colors.teal,
        'route': '/reports/efficiency',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tipos de Relatórios',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...reports
            .map(
              (report) => _buildReportCard(
                title: report['title'] as String,
                subtitle: report['subtitle'] as String,
                icon: report['icon'] as IconData,
                color: report['color'] as Color,
                onTap: () {
                  if (DI.isAdmin) {
                    Get.toNamed(report['route'] as String);
                  } else {
                    Get.snackbar(
                      'Acesso Restrito',
                      'Apenas administradores podem ver este relatório',
                    );
                  }
                },
              ),
            )
            .toList(),
      ],
    );
  }

  Widget _buildReportCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
        onTap: onTap,
      ),
    );
  }

  String _calculateCollectionRate(Map<String, dynamic> stats) {
    final paid = stats['paid'] ?? 0;
    final total = stats['total'] ?? 1;
    return (paid / total * 100).toStringAsFixed(1);
  }
}
